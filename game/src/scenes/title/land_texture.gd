class_name LandTexture
extends RefCounted
## A flat world map drawn from land outlines (Natural Earth 1:110m), used when
## no photographic texture is available: sky-blue ocean, mint land, lavender
## coastlines, equirectangular. Add the returned texture's "viewport" meta
## (a SubViewport) to the scene so it renders.

const OCEAN := "#BFDDF8"
const LAND := "#BDEBD7"
const COAST := "#CDB8F0"


static func build(polygons: Array, size := Vector2i(2048, 1024)) -> ViewportTexture:
	var vp := SubViewport.new()
	vp.size = size
	vp.disable_3d = true
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var bg := ColorRect.new()
	bg.color = Color(OCEAN)
	bg.size = Vector2(size)
	vp.add_child(bg)
	for poly in polygons:
		var pts := PackedVector2Array()
		for p in poly:
			pts.append(Vector2((float(p[0]) + 180.0) / 360.0 * size.x, (90.0 - float(p[1])) / 180.0 * size.y))
		var fill := Polygon2D.new()
		fill.polygon = pts
		fill.color = Color(LAND)
		vp.add_child(fill)
		var line := Line2D.new()
		line.points = pts
		line.closed = true
		line.width = maxf(1.0, size.x / 1024.0)
		line.default_color = Color(COAST)
		vp.add_child(line)
	var tex := vp.get_texture()
	tex.set_meta("viewport", vp)
	return tex


static func load_polygons(path := "res://data/land_110m.json") -> Array:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return (data as Dictionary).get("polygons", []) if data is Dictionary else []
