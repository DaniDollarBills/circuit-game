class_name Palette
extends RefCounted
## The pastel interface palette, in light and night variants. Hex values are exact.
## The 3D world uses real materials instead (see res://src/render/materials.gd).

const NAMES: PackedStringArray = [
	"cream", "paper", "ink", "ink_soft", "line", "lavender", "lilac", "mint", "sky",
	"peach", "butter", "rose", "coral", "signal_low", "signal_high", "spark", "metal",
]

const LIGHT := {
	"cream": "#FFF8EF", "paper": "#FFFFFF", "ink": "#3D3A4B", "ink_soft": "#6E6A80",
	"line": "#E7E1F0", "lavender": "#CDB8F0", "lilac": "#E6DAFB", "mint": "#BDEBD7",
	"sky": "#BFDDF8", "peach": "#FFD3B8", "butter": "#FFF0A6", "rose": "#F8C3D6",
	"coral": "#FF9F8A", "signal_low": "#B9B3D1", "signal_high": "#FF8FAB",
	"spark": "#FFE58A", "metal": "#D9D6E6",
}

## Night overrides. Tokens not listed here keep their light value.
const NIGHT := {
	"cream": "#24212F", "paper": "#2F2B3D", "ink": "#F3EEFF", "ink_soft": "#BDB6D6",
	"line": "#3B3650",
}

const LED_TINTS := {"red": "#FF8F9A", "yellow": "#FFE27A", "green": "#8FE3B0", "blue": "#8FC2FF"}


static func color(token: String, night := false) -> Color:
	if night and NIGHT.has(token):
		return Color(NIGHT[token])
	if LIGHT.has(token):
		return Color(LIGHT[token])
	push_error("Unknown palette color: " + token)
	return Color(0, 0, 0, 0)


static func led_tint(led_color: String) -> Color:
	return Color(LED_TINTS.get(led_color, LED_TINTS["red"]))


## WCAG 2.x contrast ratio between two colors (1 to 21).
static func contrast_ratio(a: Color, b: Color) -> float:
	var la := _luminance(a)
	var lb := _luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


static func _luminance(c: Color) -> float:
	return 0.2126 * _linear(c.r) + 0.7152 * _linear(c.g) + 0.0722 * _linear(c.b)


static func _linear(v: float) -> float:
	return v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)
