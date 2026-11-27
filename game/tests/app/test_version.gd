extends TestCase
## The game's version, the way to updates, and the promise that the game
## itself never goes online (spec §9 and §13).


func test_version_reads_the_project_setting() -> void:
	assert_eq(Version.text(), "0.3.0")


func test_updates_button_opens_the_releases_page() -> void:
	var game := Game.new()
	add_to_tree(game)
	game.boot("user://test_version_%d.json" % randi())
	var sheet := SettingsSheet.new()
	sheet.game = game
	add_to_tree(sheet)
	var opened := []
	sheet.opener = func(url: String) -> Error:
		opened.append(url)
		return OK
	sheet.open()
	sheet.updates_button().pressed.emit()
	assert_eq(opened, [Version.RELEASES_URL])
	assert_true(sheet.about_text().contains("0.3.0"), sheet.about_text())


## No class that can open a connection appears anywhere in the game's code.
func test_game_never_opens_a_connection() -> void:
	var banned := ["HTTPRequest", "HTTPClient", "StreamPeerTCP", "StreamPeerTLS", "PacketPeerUDP",
			"WebSocketPeer", "TCPServer", "UDPServer", "JavaScriptBridge", "ENetConnection", "WebRTCPeerConnection"]
	var found := PackedStringArray()
	_scan("res://src", banned, found)
	assert_eq(", ".join(found), "")


func _scan(dir: String, banned: Array, found: PackedStringArray) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			var text := FileAccess.get_file_as_string(dir.path_join(f))
			for word in banned:
				if text.contains(word):
					found.append("%s in %s" % [word, f])
	for d in DirAccess.get_directories_at(dir):
		_scan(dir.path_join(d), banned, found)
