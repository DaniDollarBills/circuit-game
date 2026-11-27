extends TestCase

const ORDER := ["low", "medium", "high", "ultra"]


func test_quality_auto_per_renderer() -> void:
	assert_eq(Quality.auto("forward_plus"), "high")
	assert_eq(Quality.auto("mobile"), "medium")
	assert_eq(Quality.auto("gl_compatibility"), "low")


func test_quality_resolve_explicit_wins() -> void:
	assert_eq(Quality.resolve("auto", "forward_plus"), "high")
	assert_eq(Quality.resolve("ultra", "gl_compatibility"), "ultra")
	assert_eq(Quality.resolve("nonsense", "mobile"), "medium", "an unknown setting falls back to auto")


func test_presets_exact() -> void:
	assert_eq(Quality.PRESETS["low"], {"sdfgi": false, "ssao": false, "ssil": false, "ssr": false, "glow": true, "dof": false, "shadow_size": 1024, "msaa_3d": 2})
	assert_eq(Quality.PRESETS["ultra"], {"sdfgi": true, "ssao": true, "ssil": true, "ssr": true, "glow": true, "dof": true, "shadow_size": 4096, "msaa_3d": 4})


## Every effect on in a lower preset is also on in every higher one, and sizes never shrink.
func test_presets_monotonic() -> void:
	for i in range(1, ORDER.size()):
		var lower: Dictionary = Quality.PRESETS[ORDER[i - 1]]
		var higher: Dictionary = Quality.PRESETS[ORDER[i]]
		for key in lower:
			if lower[key] is bool:
				assert_true(not lower[key] or higher[key], "%s → %s: %s" % [ORDER[i - 1], ORDER[i], key])
			else:
				assert_true(higher[key] >= lower[key], "%s → %s: %s" % [ORDER[i - 1], ORDER[i], key])


func test_studio_environment_follows_preset() -> void:
	var hdri := "res://assets/third_party/polyhaven/hdri/studio_small_09_2k.hdr"
	var env := StudioEnvironment.build(hdri, "high")
	assert_eq(env.background_mode, Environment.BG_SKY)
	assert_true(env.sky.sky_material is PanoramaSkyMaterial)
	assert_eq(env.tonemap_mode, Environment.TONE_MAPPER_ACES)
	assert_eq(env.tonemap_exposure, 1.0)
	assert_true(env.glow_enabled)
	assert_eq(env.glow_hdr_threshold, 1.0)
	assert_true(env.ssao_enabled and env.ssil_enabled and env.ssr_enabled)
	assert_false(env.sdfgi_enabled)
	assert_eq(env.ambient_light_source, Environment.AMBIENT_SOURCE_SKY)
	assert_eq(env.reflected_light_source, Environment.REFLECTION_SOURCE_SKY)
	assert_false(StudioEnvironment.build(hdri, "low").ssao_enabled)


func test_camera_attributes_dof_by_preset() -> void:
	var med := StudioEnvironment.camera_attributes("medium", 30.0)
	assert_true(med.dof_blur_far_enabled and med.dof_blur_near_enabled)
	assert_true(med.dof_blur_far_distance > 30.0 and med.dof_blur_near_distance < 30.0)
	var low := StudioEnvironment.camera_attributes("low", 30.0)
	assert_false(low.dof_blur_far_enabled or low.dof_blur_near_enabled)
