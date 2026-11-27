extends TestCase

var ctl: EditorController


func before_each() -> void:
	ctl = EditorController.new()


func _ctx(c: Circuit, tray := [], used: Array[int] = []) -> Dictionary:
	return {"circuit": c, "tray": tray, "tray_used": used, "pin_r": 0.35, "wire_r": 0.3}


func _pin(c: Circuit, part: String, pin: String) -> Vector2:
	return Vector2(CircuitGeometry.pin_position(c.find_part(part), pin))


func _g(type: String, at := Vector2.ZERO, extra := {}) -> Dictionary:
	var g := {"type": type, "at": at, "screen": at * 32.0}
	g.merge(extra, true)
	return g


func _commits(effects: Array[Dictionary]) -> Array:
	return effects.filter(func(e: Dictionary) -> bool: return e["type"] == "commit")


func _bare_loop() -> Circuit:
	var c := TestCircuits.compact_loop()
	c.wires.clear()
	return c


func test_tap_place_from_tray_commits_part_with_tray_index() -> void:
	var c := TestCircuits.battery_only()
	var tray := [{"kind": "resistor", "props": {"ohms": 47.0}, "count": 1}, {"kind": "resistor", "props": {"ohms": 150.0}, "count": 1}]
	ctl.begin_placing(1)
	var fx := ctl.handle(_g("tap", Vector2(3.4, -2.6)), _ctx(c, tray, [0, 0]))
	var commits := _commits(fx)
	assert_eq(commits.size(), 1)
	var placed: Part = (commits[0]["circuit"] as Circuit).parts[1]
	assert_eq(placed.kind, "resistor")
	assert_eq(placed.tray, 1)
	assert_eq(placed.props["ohms"], 150.0)
	assert_eq(Vector2i(placed.x, placed.y), Vector2i(3, -3))
	assert_eq(placed.id, "R1")
	assert_eq(ctl.mode["kind"], "idle")


func test_tap_tap_wiring() -> void:
	var c := _bare_loop()
	assert_eq(ctl.handle(_g("tap", _pin(c, "B1", "pos")), _ctx(c)).size(), 0)
	assert_eq(ctl.mode["kind"], "pin_selected")
	var fx := ctl.handle(_g("tap", _pin(c, "R1", "a")), _ctx(c))
	var commits := _commits(fx)
	assert_eq(commits.size(), 1)
	var w: Wire = (commits[0]["circuit"] as Circuit).wires[0]
	assert_eq([w.a_part, w.a_pin, w.b_part, w.b_pin], ["B1", "pos", "R1", "a"])
	assert_eq(ctl.mode["kind"], "idle")


func test_drag_wiring_snaps_and_commits() -> void:
	var c := _bare_loop()
	ctl.handle(_g("drag_start", _pin(c, "R1", "b")), _ctx(c))
	assert_eq(ctl.mode["kind"], "wiring")
	ctl.handle(_g("drag_move", _pin(c, "L1", "anode") + Vector2(0.3, 0.2)), _ctx(c))
	assert_eq(ctl.mode["snap_part"], "L1")
	var commits := _commits(ctl.handle(_g("drag_end", _pin(c, "L1", "anode") + Vector2(0.3, 0.2)), _ctx(c)))
	assert_eq(commits.size(), 1)
	var w: Wire = (commits[0]["circuit"] as Circuit).wires[0]
	assert_eq([w.a_part, w.a_pin, w.b_part, w.b_pin], ["R1", "b", "L1", "anode"])


func test_drop_on_nothing_toasts() -> void:
	var c := _bare_loop()
	ctl.handle(_g("drag_start", _pin(c, "R1", "b")), _ctx(c))
	ctl.handle(_g("drag_move", Vector2(20, 20)), _ctx(c))
	var fx := ctl.handle(_g("drag_end", Vector2(20, 20)), _ctx(c))
	assert_eq(fx, [{"type": "toast", "text": "Drop the wire on a metal dot."}] as Array[Dictionary])
	assert_eq(ctl.mode["kind"], "idle")


func test_duplicate_wire_toasts() -> void:
	var c := TestCircuits.compact_loop()
	ctl.handle(_g("drag_start", _pin(c, "B1", "pos")), _ctx(c))
	ctl.handle(_g("drag_move", _pin(c, "R1", "a")), _ctx(c))
	var fx := ctl.handle(_g("drag_end", _pin(c, "R1", "a")), _ctx(c))
	assert_eq(fx, [{"type": "toast", "text": "Those are already connected."}] as Array[Dictionary])


func test_move_snaps_to_grid() -> void:
	var c := TestCircuits.battery_only()
	var r := Part.make("R1", "resistor", 2, 2)
	c.parts.append(r)
	ctl.handle(_g("drag_start", Vector2(2.3, 2.1)), _ctx(c))
	assert_eq(ctl.mode["kind"], "moving")
	ctl.handle(_g("drag_move", Vector2(5.1, 6.4)), _ctx(c))
	var commits := _commits(ctl.handle(_g("drag_end", Vector2(5.1, 6.4)), _ctx(c)))
	assert_eq(commits.size(), 1)
	var moved := (commits[0]["circuit"] as Circuit).find_part("R1")
	assert_eq(Vector2i(moved.x, moved.y), Vector2i(5, 6))


func test_locked_part_drag_pans() -> void:
	var c := Circuit.new()
	c.parts.append(Part.make("R1", "resistor", 0, 0, 0, {}, true))
	ctl.handle(_g("drag_start", Vector2(0.2, 0.1)), _ctx(c))
	assert_eq(ctl.mode["kind"], "panning")
	var fx := ctl.handle(_g("drag_move", Vector2(1.2, 0.1)), _ctx(c))
	assert_eq(fx, [{"type": "camera_pan", "delta": Vector2(32, 0)}] as Array[Dictionary])
	assert_eq(_commits(ctl.handle(_g("drag_end", Vector2(1.2, 0.1)), _ctx(c))).size(), 0)


func test_tap_switch_toggles() -> void:
	var c := TestCircuits.battery_only()
	c.parts.append(Part.make("S1", "switch", 4, 4, 0, {}, true))
	var commits := _commits(ctl.handle(_g("tap", Vector2(4.5, 4.1)), _ctx(c)))
	assert_eq(commits.size(), 1)
	assert_true((commits[0]["circuit"] as Circuit).find_part("S1").props["closed"])


func test_tap_adjustable_resistor_opens_value() -> void:
	var c := TestCircuits.meter_loop(1000.0)
	var fx := ctl.handle(_g("tap", Vector2(-2.5, -4.1)), _ctx(c))
	assert_eq(fx, [{"type": "value", "part": "R1"}] as Array[Dictionary])


func test_tap_plain_part_opens_datasheet() -> void:
	var c := TestCircuits.compact_loop()
	var fx := ctl.handle(_g("tap", Vector2(6.2, 0.3)), _ctx(c))
	assert_eq(fx, [{"type": "datasheet", "part": "L1"}] as Array[Dictionary])
	assert_eq(ctl.selection, "L1")


func test_tap_wire_emits_selected() -> void:
	var c := TestCircuits.compact_loop()
	var path := CircuitGeometry.wire_path(c, c.find_wire("w3"))
	var mid := (path[path.size() - 2] + path[path.size() - 1]) / 2.0
	var fx := ctl.handle(_g("tap", mid), _ctx(c))
	assert_eq(fx, [{"type": "selected", "id": "w3"}] as Array[Dictionary])
	assert_eq(ctl.selection, "w3")


func test_long_press_opens_menu() -> void:
	var c := TestCircuits.compact_loop()
	var fx := ctl.handle(_g("long_press", Vector2(6.2, 0.3)), _ctx(c))
	assert_eq(fx.size(), 1)
	assert_eq(fx[0]["type"], "menu")
	assert_eq(fx[0]["part"], "L1")
	assert_eq(ctl.handle(_g("secondary_tap", Vector2(6.2, 0.3)), _ctx(c))[0]["type"], "menu")


func test_drag_cancel_while_wiring_commits_nothing() -> void:
	var c := _bare_loop()
	ctl.handle(_g("drag_start", _pin(c, "B1", "pos")), _ctx(c))
	assert_eq(ctl.handle(_g("drag_cancel"), _ctx(c)).size(), 0)
	assert_eq(ctl.mode["kind"], "idle")
	assert_eq(ctl.handle(_g("drag_end", _pin(c, "R1", "a")), _ctx(c)).size(), 0, "a stray release after a cancel does nothing")


func test_rotate_and_delete_keys_on_selection() -> void:
	var c := TestCircuits.battery_only()
	c.parts.append(Part.make("R1", "resistor", 2, 2))
	ctl.handle(_g("tap", Vector2(2.2, 2.1)), _ctx(c))
	var turned := _commits(ctl.handle({"type": "key", "key": "rotate"}, _ctx(c)))
	assert_eq((turned[0]["circuit"] as Circuit).find_part("R1").rot, 90)
	var gone := _commits(ctl.handle({"type": "key", "key": "delete"}, _ctx(c)))
	assert_true((gone[0]["circuit"] as Circuit).find_part("R1") == null)
	assert_eq(ctl.selection, "")


func test_zoom_and_pan_become_camera_effects() -> void:
	var c := TestCircuits.compact_loop()
	assert_eq(ctl.handle({"type": "zoom", "at": Vector2(1, 2), "factor": 1.15}, _ctx(c)), [{"type": "camera_zoom", "factor": 1.15, "at": Vector2(1, 2)}] as Array[Dictionary])
	assert_eq(ctl.handle({"type": "pan", "delta": Vector2(5, 0)}, _ctx(c)), [{"type": "camera_pan", "delta": Vector2(5, 0)}] as Array[Dictionary])
