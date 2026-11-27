extends TestCase

const MANIFEST := "res://assets/third_party/manifest.json"


func _entries() -> Array:
	return JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))


func test_manifest_entries_have_license_and_credit() -> void:
	var ids := []
	for e in _entries():
		ids.append(e["id"])
		assert_true(e["license"] in ["CC0", "Public domain", "Public domain; tiles Apache-2.0"], e["id"])
		assert_false(str(e["credit"]).is_empty(), e["id"])
		assert_true(e["source"] in ["polyhaven", "nasa", "naturalearth"], e["id"])
		assert_false((e["files"] as Array).is_empty(), e["id"])
	for id in ["studio_small_09", "kloofendal_48d_partly_cloudy_puresky", "wood_table_001", "aerial_beach_01", "sand_01"]:
		assert_true(id in ids, id)
	var credits := FileAccess.get_file_as_string("res://assets/third_party/CREDITS.md")
	for id in ids:
		assert_true(credits.contains(id), "CREDITS.md names " + id)


func test_manifest_files_verify() -> void:
	for e in _entries():
		for f in e["files"]:
			var path := "res://" + str(f["path"])
			assert_true(FileAccess.file_exists(path), path)
			if f.has("md5"):
				assert_eq(FileAccess.get_md5(path), f["md5"], path)
			elif f.has("sha256"):
				assert_eq(FileAccess.get_sha256(path), f["sha256"], path)
			else:
				fail("no checksum for " + path)


## The globe's tiles came through @cesium/engine, which is Apache-2.0: the
## manifest says so and the license ships beside the file (Apache-2.0 §4).
func test_apache_licensed_files_ship_the_license() -> void:
	var found := false
	for e in _entries():
		if not str(e["license"]).contains("Apache-2.0"):
			continue
		found = true
		for f in e["files"]:
			var dir := ("res://" + str(f["path"])).get_base_dir()
			assert_true(FileAccess.file_exists(dir.path_join("LICENSE-Apache-2.0.md")), dir)
	assert_true(found, "natural_earth_ii lists the Apache-2.0 tiles")
