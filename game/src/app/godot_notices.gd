class_name GodotNotices
extends RefCounted
## Godot Engine's license, and the copyright notices and licenses of the
## libraries built into it, which their licenses ask every copy of the game
## to carry: written beside the desktop downloads (tools/write_licenses.gd)
## and shown in the game (Settings → Licenses).


static func license() -> String:
	return Engine.get_license_text()


## Each library with its copyright lines and license, then every license's
## full text.
static func third_party() -> String:
	var text := "Third-party components built into Godot Engine %s\n\n" % Engine.get_version_info()["string"]
	for c in Engine.get_copyright_info():
		text += "## %s\n" % c["name"]
		for part in c["parts"]:
			for line in part["copyright"]:
				text += "Copyright: %s\n" % line
			text += "License: %s\n\n" % part["license"]
	text += "\n# License texts\n\n"
	var info := Engine.get_license_info()
	for license_name in info:
		text += "## %s\n\n%s\n\n" % [license_name, info[license_name]]
	return text
