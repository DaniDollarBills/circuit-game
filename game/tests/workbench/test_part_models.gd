extends TestCase


## The combined bounds of every mesh under `n`, in `root`'s space, in mm.
func _aabb_mm(n: Node, root: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for m in n.find_children("*", "MeshInstance3D", true, false) + ([n] if n is MeshInstance3D else []):
		var mi := m as MeshInstance3D
		var b := _xform(mi, root) * mi.mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return AABB(box.position * 10.0, box.size * 10.0)


## `n`'s transform relative to `root` (an ancestor, or null for the top).
func _xform(n: Node3D, root: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var cur: Node = n
	while cur != null and cur != root:
		if cur is Node3D:
			t = (cur as Node3D).transform * t
		cur = cur.get_parent()
	return t


func _free(n: Node) -> void:
	n.free()


func test_resistor_body_dims() -> void:
	var quarter := PartModels.build(Part.make("R1", "resistor", 0, 0))
	var size := _aabb_mm(quarter.get_node("body"), quarter).size
	assert_near(size.x, 6.3, 0.05)
	assert_near(size.y, 2.4, 0.05)
	assert_near(size.z, 2.4, 0.05)
	var one := PartModels.build(Part.make("R2", "resistor", 0, 0, 0, {"watts": 1.0}))
	var big := _aabb_mm(one.get_node("body"), one).size
	assert_near(big.x, 11.0, 0.05)
	assert_near(big.y, 4.5, 0.05)
	assert_near(big.z, 4.5, 0.05)
	_free(quarter)
	_free(one)


func test_resistor_has_four_bands_from_the_code() -> void:
	var r := PartModels.build(Part.make("R1", "resistor", 0, 0, 0, {"ohms": 220.0}))
	var bands := r.get_node("body").find_children("band*", "MeshInstance3D", true, false)
	assert_eq(bands.size(), 4)
	var expect := ResistorBands.colors(220.0)
	for i in 4:
		var mat := (r.get_node("body/band%d" % i) as MeshInstance3D).material_override as StandardMaterial3D
		assert_eq(mat.albedo_color, expect[i])
	_free(r)


func test_led_dims() -> void:
	var led := PartModels.build(Part.make("L1", "led", 0, 0))
	assert_near(_aabb_mm(led.get_node("epoxy/dome"), led).size.x, 5.0, 0.05)
	assert_near(_aabb_mm(led.get_node("epoxy/flange"), led).size.z, 5.8, 0.05, "measured across the flat")
	assert_true(_aabb_mm(led.get_node("epoxy/flange"), led).size.x < 5.75, "the flange has a flat on the cathode side")
	assert_near(_aabb_mm(led.get_node("epoxy"), led).size.y, 8.6, 0.05)
	assert_true(led.get_node("epoxy").find_child("die", true, false) != null)
	_free(led)


## Every lead ends in the hole at its pin, for every kind and every rotation.
func test_leads_end_at_pin_holes() -> void:
	for kind in Catalog.PARTS:
		for props in [{}, {"watts": 1.0}] if kind == "resistor" else [{}]:
			for rot in [0, 90, 180, 270]:
				var p := Part.make("X1", kind, 3, -2, rot, props)
				var node := PartModels.build(p)
				for pin in Catalog.pin_names(kind):
					var tip := node.get_node_or_null("tip_" + pin) as Node3D
					assert_true(tip != null, "%s has tip_%s" % [kind, pin])
					if tip == null:
						continue
					var world := _xform(tip, null) * Vector3.ZERO
					var grid := PartDims.world_to_grid(world)
					var want := Vector2(CircuitGeometry.pin_position(p, pin))
					assert_true(grid.distance_to(want) < 0.01, "%s %s rot %d: %s vs %s" % [kind, pin, rot, grid, want])
					assert_true(world.y < 0.0, "%s %s goes into the hole" % [kind, pin])
				_free(node)


func test_apply_state_lights_and_burns() -> void:
	var led := PartModels.build(Part.make("L1", "led", 0, 0))
	PartModels.apply_state(led, {"brightness": 0.8, "burnt": false, "color": "red"})
	var light := led.find_child("glow", true, false) as OmniLight3D
	assert_true(light != null and light.visible and light.light_energy > 0.0)
	assert_eq(light.light_color, Color("#FF2A1A"))
	assert_near(light.omni_range, 3.0, 1e-6)
	PartModels.apply_state(led, {"brightness": 0.0, "burnt": true, "color": "red"})
	assert_false(light.visible)
	assert_true(led.find_child("smoke", true, false) != null)
	_free(led)
	var meter := PartModels.build_multimeter("ammeter")
	PartModels.apply_meter(meter, "13.8 mA", false)
	assert_eq((meter.find_child("lcd_text", true, false) as Label3D).text, "13.8 mA")
	PartModels.apply_meter(meter, "13.8 mA", true)
	assert_eq((meter.find_child("lcd_text", true, false) as Label3D).text, "FUSE")
	_free(meter)
