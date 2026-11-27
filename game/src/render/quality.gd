class_name Quality
extends RefCounted
## Graphics presets. "auto" picks one by renderer: Forward+ (desktop GPUs) gets
## High, Mobile gets Medium, and Compatibility (older GPUs, the web) gets Low.

const PRESETS := {
	"low": {"sdfgi": false, "ssao": false, "ssil": false, "ssr": false, "glow": true, "dof": false, "shadow_size": 1024, "msaa_3d": 2},
	"medium": {"sdfgi": false, "ssao": false, "ssil": false, "ssr": false, "glow": true, "dof": true, "shadow_size": 2048, "msaa_3d": 2},
	"high": {"sdfgi": false, "ssao": true, "ssil": true, "ssr": true, "glow": true, "dof": true, "shadow_size": 2048, "msaa_3d": 4},
	"ultra": {"sdfgi": true, "ssao": true, "ssil": true, "ssr": true, "glow": true, "dof": true, "shadow_size": 4096, "msaa_3d": 4},
}


static func auto(rendering_method: String) -> String:
	match rendering_method:
		"forward_plus":
			return "high"
		"mobile":
			return "medium"
	return "low"


## The preset to use: an explicit one wins; "auto" or anything unknown is
## decided by the renderer.
static func resolve(setting: String, rendering_method: String) -> String:
	return setting if PRESETS.has(setting) else auto(rendering_method)


## The renderer this run actually uses (a fallback from Vulkan included).
static func current_method() -> String:
	return RenderingServer.get_current_rendering_method()


## The most screen pixels per layout pixel worth rendering at this preset.
static func max_resolution_scale(preset: String) -> float:
	return {"low": 1.0, "medium": 1.5, "high": 2.0, "ultra": 3.0}.get(preset, 1.0)


static func msaa(preset: String) -> Viewport.MSAA:
	return Viewport.MSAA_4X if int(PRESETS[preset]["msaa_3d"]) >= 4 else Viewport.MSAA_2X
