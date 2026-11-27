extends TestCase
## The downloads' export settings: the Android app asks for nothing (the game
## makes no network connections and needs no permissions, spec §9 and §13).

const PRESETS := "res://export_presets.cfg"


func _preset(name: String) -> String:
	var cfg := ConfigFile.new()
	assert_eq(cfg.load(PRESETS), OK)
	for section in cfg.get_sections():
		if section.ends_with(".options"):
			continue
		if str(cfg.get_value(section, "name", "")) == name:
			return section
	return ""


func test_android_preset_asks_for_nothing() -> void:
	var cfg := ConfigFile.new()
	cfg.load(PRESETS)
	var section := _preset("Android")
	assert_true(section != "", "there is an Android preset")
	if section == "":
		return
	assert_eq(cfg.get_value(section, "platform"), "Android")
	var options := section + ".options"
	assert_eq(cfg.get_value(options, "package/unique_name"), "io.github.circuitgame.circuit")
	assert_eq(cfg.get_value(options, "version/name"), Version.text())
	# Each Android release needs a higher code than the last (v0.2.0 was 2).
	assert_eq(cfg.get_value(options, "version/code"), 3)
	assert_eq(cfg.get_value(options, "gradle_build/use_gradle_build"), false)
	assert_eq(cfg.get_value(options, "architectures/arm64-v8a"), true)
	assert_eq(cfg.get_value(options, "architectures/armeabi-v7a"), true)
	var asked := PackedStringArray()
	for key in cfg.get_section_keys(options):
		if key.begins_with("permissions/") and key != "permissions/custom_permissions" and cfg.get_value(options, key) == true:
			asked.append(key)
	assert_eq(", ".join(asked), "", "no permissions")
	assert_eq((cfg.get_value(options, "permissions/custom_permissions", PackedStringArray()) as PackedStringArray).size(), 0)
	assert_eq(cfg.get_value(options, "permissions/internet", false), false)


## The phone version turns with the device, like the desktop window resizes.
func test_phones_follow_the_device_orientation() -> void:
	assert_eq(int(ProjectSettings.get_setting("display/window/handheld/orientation", 0)), DisplayServer.SCREEN_SENSOR)
