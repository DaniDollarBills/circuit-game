extends TestCase


func test_materials_pbr_values() -> void:
	var cu := Materials.copper()
	assert_eq(cu.albedo_color, Color("#B87333"))
	assert_eq(cu.metallic, 1.0)
	assert_near(cu.roughness, 0.35, 1e-6)
	var epoxy := Materials.epoxy_clear(Color("#FF8F9A"))
	assert_eq(epoxy.transparency, BaseMaterial3D.TRANSPARENCY_ALPHA)
	assert_near(epoxy.albedo_color.a, 0.35, 1e-6)
	assert_near(epoxy.roughness, 0.05, 1e-6)
	assert_true(epoxy.rim_enabled)
	var gloss := Materials.plastic_gloss(Color.WHITE)
	assert_true(gloss.clearcoat_enabled)
	assert_near(gloss.clearcoat, 0.3, 1e-6)
	assert_near(Materials.plastic_matte(Color.WHITE).roughness, 0.6, 1e-6)
	assert_eq(Materials.tin().metallic, 1.0)
	assert_near(Materials.rubber().roughness, 0.85, 1e-6)
	assert_eq(Materials.resistor_paint(Color("#6E9FCB")).albedo_color, Color("#6E9FCB"))


func test_materials_cached_by_name_and_args() -> void:
	assert_true(Materials.copper() == Materials.copper())
	assert_true(Materials.pvc(Color.RED) == Materials.pvc(Color.RED))
	assert_false(Materials.pvc(Color.RED) == Materials.pvc(Color.BLUE))


func test_textured_materials() -> void:
	var desk := Materials.wood_desk()
	assert_true(desk.albedo_texture != null and desk.normal_enabled and desk.normal_texture != null)
	assert_true(desk.roughness_texture != null)
	var mat := Materials.cutting_mat()
	assert_eq(mat.albedo_color, Color("#BDEBD7"))
	assert_true(mat.albedo_texture != null, "grid lines")
	assert_true(mat.uv1_world_triplanar, "the grid is laid out in real centimeters")
