class_name Materials
extends RefCounted
## Physically based materials for the real-looking parts, cached by name and
## arguments so every resistor body shares one material.

const WOOD := "res://assets/third_party/polyhaven/textures/wood_table_001/wood_table_001_%s_2k.jpg"

static var _cache := {}


static func plastic_matte(c: Color) -> StandardMaterial3D:
	return _make("plastic_matte", [c], func(m: StandardMaterial3D) -> void:
		m.albedo_color = c
		m.roughness = 0.6)


static func plastic_gloss(c: Color) -> StandardMaterial3D:
	return _make("plastic_gloss", [c], func(m: StandardMaterial3D) -> void:
		m.albedo_color = c
		m.roughness = 0.25
		m.clearcoat_enabled = true
		m.clearcoat = 0.3)


## Clear LED epoxy: mostly see-through, glassy, with a soft rim.
static func epoxy_clear(tint: Color) -> StandardMaterial3D:
	return _make("epoxy_clear", [tint], func(m: StandardMaterial3D) -> void:
		m.albedo_color = Color(tint, 0.35)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 0.05
		m.rim_enabled = true
		m.rim = 0.2
		if Quality.current_method() != "gl_compatibility":
			m.refraction_enabled = true
			m.refraction_scale = 0.05)


static func copper() -> StandardMaterial3D:
	return _metal("copper", Color("#B87333"), 0.35)


## Tinned leads and pads.
static func tin() -> StandardMaterial3D:
	return _metal("tin", Color("#C8CDD2"), 0.4)


static func steel() -> StandardMaterial3D:
	return _metal("steel", Color("#9EA4AA"), 0.45)


## Perfboard.
static func fr4() -> StandardMaterial3D:
	return _dielectric("fr4", Color("#C9B48A"), 0.7)


## Carbon film bodies are #D8C39A; 1 W metal film bodies #6E9FCB.
static func resistor_paint(c: Color) -> StandardMaterial3D:
	return _make("resistor_paint", [c], func(m: StandardMaterial3D) -> void:
		m.albedo_color = c
		m.roughness = 0.55)


## Wire insulation.
static func pvc(c: Color) -> StandardMaterial3D:
	return _make("pvc", [c], func(m: StandardMaterial3D) -> void:
		m.albedo_color = c
		m.roughness = 0.45)


static func rubber() -> StandardMaterial3D:
	return _dielectric("rubber", Color("#2A2A2E"), 0.85)


## A meter's display.
static func lcd() -> StandardMaterial3D:
	return _dielectric("lcd", Color("#9FB3A6"), 0.1)


static func wood_desk() -> StandardMaterial3D:
	return _make("wood_desk", [], func(m: StandardMaterial3D) -> void:
		m.albedo_texture = load(WOOD % "diff")
		m.normal_enabled = true
		m.normal_texture = load(WOOD % "nor_gl")
		m.roughness_texture = load(WOOD % "rough")
		m.roughness = 1.0
		m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3.ONE / 60.0)


## A mint self-healing cutting mat with its grid: fine lines every millimeter,
## bold ones every centimeter. Laid out in world space (1 unit = 1 cm), so the
## grid is true to size on any mesh.
static func cutting_mat() -> StandardMaterial3D:
	return _make("cutting_mat", [], func(m: StandardMaterial3D) -> void:
		m.albedo_color = Color("#BDEBD7")
		m.albedo_texture = _grid_texture()
		m.roughness = 0.8
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3.ONE / 10.0)


static func _metal(name: String, c: Color, roughness: float) -> StandardMaterial3D:
	return _make(name, [], func(m: StandardMaterial3D) -> void:
		m.albedo_color = c
		m.metallic = 1.0
		m.roughness = roughness)


static func _dielectric(name: String, c: Color, roughness: float) -> StandardMaterial3D:
	return _make(name, [], func(m: StandardMaterial3D) -> void:
		m.albedo_color = c
		m.roughness = roughness)


static func _make(name: String, args: Array, setup: Callable) -> StandardMaterial3D:
	var key := name + var_to_str(args)
	if not _cache.has(key):
		var m := StandardMaterial3D.new()
		m.resource_name = name
		m.metallic = 0.0
		setup.call(m)
		_cache[key] = m
	return _cache[key]


## 10 cm × 10 cm at 100 pixels per centimeter, white so it multiplies the mint.
static func _grid_texture() -> ImageTexture:
	var size := 1000
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var fine := Color(0.86, 0.93, 0.9)
	var bold := Color(0.62, 0.78, 0.71)
	for i in size:
		if i % 10 == 0:
			for k in size:
				img.set_pixel(i, k, fine)
				img.set_pixel(k, i, fine)
	for i in size:
		if i % 100 < 3:
			for k in size:
				img.set_pixel(i, k, bold)
				img.set_pixel(k, i, bold)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)
