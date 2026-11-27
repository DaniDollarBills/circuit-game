extends Node3D
## A sphere and a cube of every material, plus a glowing LED die, lit by the
## studio HDRI, for checking the look by eye. --quality=<preset> overrides auto.

const HDRI := "res://assets/third_party/polyhaven/hdri/studio_small_09_2k.hdr"


func _ready() -> void:
	var quality := Quality.resolve("auto", Quality.current_method())
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--quality="):
			quality = Quality.resolve(arg.substr(10), Quality.current_method())
	var world := WorldEnvironment.new()
	world.environment = StudioEnvironment.build(HDRI, quality)
	world.camera_attributes = StudioEnvironment.camera_attributes(quality, 44.0)
	add_child(world)
	get_viewport().msaa_3d = Quality.msaa(quality)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.light_energy = 0.6
	sun.shadow_enabled = true
	add_child(sun)
	RenderingServer.directional_shadow_atlas_set_size(int(Quality.PRESETS[quality]["shadow_size"]), true)
	var cam := Camera3D.new()
	cam.fov = 30.0
	cam.position = Vector3(0, 24, 38)
	add_child(cam)
	cam.look_at(Vector3(0, -1, 1))
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(60, 30)
	floor_mesh.mesh = plane
	floor_mesh.material_override = Materials.cutting_mat()
	floor_mesh.position = Vector3(0, -1.0, 0)
	add_child(floor_mesh)
	var mats := [
		["matte plastic", Materials.plastic_matte(Palette.color("lavender"))],
		["gloss plastic", Materials.plastic_gloss(Palette.color("peach"))],
		["clear epoxy", Materials.epoxy_clear(Palette.led_tint("red"))],
		["copper", Materials.copper()],
		["tin", Materials.tin()],
		["steel", Materials.steel()],
		["FR4 board", Materials.fr4()],
		["carbon film", Materials.resistor_paint(Color("#D8C39A"))],
		["metal film", Materials.resistor_paint(Color("#6E9FCB"))],
		["PVC", Materials.pvc(Color("#E0605E"))],
		["rubber", Materials.rubber()],
		["LCD", Materials.lcd()],
		["wood desk", Materials.wood_desk()],
	]
	for i in mats.size():
		var col := i % 7
		var row := i / 7
		var x := -13.8 + col * 4.6
		var z := -4.0 + row * 7.0
		_add_mesh(SphereMesh.new(), mats[i][1], Vector3(x - 1.1, 0.0, z))
		var box := BoxMesh.new()
		box.size = Vector3.ONE * 1.6
		_add_mesh(box, mats[i][1], Vector3(x + 1.1, -0.2, z))
		var label := Label3D.new()
		label.text = mats[i][0]
		label.font_size = 48
		label.pixel_size = 0.01
		label.modulate = Palette.color("ink")
		label.outline_size = 0
		label.position = Vector3(x, -0.9, z + 1.8)
		label.rotation_degrees = Vector3(-70, 0, 0)
		add_child(label)
	# An LED die: a tiny chip glowing far brighter than anything else in the
	# scene, so it is the only thing that blooms.
	var die := StandardMaterial3D.new()
	die.albedo_color = Color("#FF5A6A")
	die.emission_enabled = true
	die.emission = Color("#FF5A6A")
	die.emission_energy_multiplier = 6.0
	var chip := BoxMesh.new()
	chip.size = Vector3(0.6, 0.3, 0.6)
	_add_mesh(chip, die, Vector3(13.8, -0.6, 3.0))
	_add_mesh(SphereMesh.new(), Materials.epoxy_clear(Palette.led_tint("red")), Vector3(13.8, 0.0, 3.0))


func _add_mesh(mesh: Mesh, mat: Material, at: Vector3) -> void:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = mat
	m.position = at
	add_child(m)
