class_name StudioEnvironment
extends RefCounted
## Real-world lighting from a photographed HDRI: it is the sky, the ambient
## light and the reflections, so metals mirror a real studio. ACES tone mapping
## keeps highlights from blowing out, and the glow threshold of 1.0 lets only
## truly bright (emissive) things bloom, like a lit LED die.


static func build(hdri_path: String, quality: String) -> Environment:
	var preset: Dictionary = Quality.PRESETS.get(quality, Quality.PRESETS["low"])
	var sky_material := PanoramaSkyMaterial.new()
	sky_material.panorama = load(hdri_path)
	var sky := Sky.new()
	sky.sky_material = sky_material
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.0
	env.glow_enabled = preset["glow"]
	env.glow_hdr_threshold = 1.0
	env.glow_intensity = 0.8
	env.glow_bloom = 0.05
	env.ssao_enabled = preset["ssao"]
	env.ssil_enabled = preset["ssil"]
	env.ssr_enabled = preset["ssr"]
	env.sdfgi_enabled = preset["sdfgi"]
	return env


## Depth of field like a macro lens: things nearer and farther than the focus
## go soft when the preset allows it.
static func camera_attributes(quality: String, focus_distance: float) -> CameraAttributesPractical:
	var preset: Dictionary = Quality.PRESETS.get(quality, Quality.PRESETS["low"])
	var attrs := CameraAttributesPractical.new()
	attrs.dof_blur_far_enabled = preset["dof"]
	attrs.dof_blur_near_enabled = preset["dof"]
	attrs.dof_blur_far_distance = focus_distance * 1.6
	attrs.dof_blur_far_transition = focus_distance * 0.8
	attrs.dof_blur_near_distance = focus_distance * 0.5
	attrs.dof_blur_near_transition = focus_distance * 0.3
	attrs.dof_blur_amount = 0.06
	return attrs
