class_name Version
extends RefCounted
## The game's version, and where new versions are published. The game never
## looks for them itself: it makes no network connections (spec §9 and §13),
## so "Check for updates" opens the Releases page in the player's browser.

const RELEASES_URL := "https://github.com/DaniDollarBills/circuit-game/releases/latest"


static func text() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "0.0.0"))
