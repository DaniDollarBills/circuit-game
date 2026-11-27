class_name Fonts
extends RefCounted
## The game's fonts. Nunito has no Greek, superscripts or symbols (Ω ⁻⁹ ✓ ✗ ★),
## so DejaVu Sans fills in just those characters: the web build has no system
## fonts to fall back on.

const SYMBOLS := "res://assets/fonts/dejavu-sans.ttf"
const SYMBOLS_BOLD := "res://assets/fonts/dejavu-sans-bold.ttf"


## Loads a font with DejaVu Sans (Bold, for `bold` weights) as its fallback.
static func with_symbols(path: String, bold := false) -> Font:
	var f: Font = load(path)
	var fallback: Font = load(SYMBOLS_BOLD if bold else SYMBOLS)
	if not f.fallbacks.has(fallback):
		var list := f.fallbacks.duplicate()
		list.append(fallback)
		f.fallbacks = list
	return f
