## Global fade-to-black overlay. Autoload as "SceneTransition".
##
## Lives on its own top-most CanvasLayer so it sits above HUDs, BGs, and
## the cable. Two roles:
##
## - Hard scene swap: await SceneTransition.change_scene(path) — fades out,
##   loads the new scene, fades back in.
## - Soft inter-call beat: await SceneTransition.dip(duration) — quick fade
##   to black and back without changing scenes.
extends CanvasLayer

const DEFAULT_FADE := 0.45
const DEFAULT_DIP := 0.55

var _rect: ColorRect

func _ready() -> void:
	layer = 100
	_rect = ColorRect.new()
	_rect.color = Color(0, 0, 0, 0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)
	# Make sure the overlay always covers the viewport, even after window
	# resizes — anchors handle that for free.

func fade_out(duration: float = DEFAULT_FADE) -> void:
	await _tween_alpha(1.0, duration)

func fade_in(duration: float = DEFAULT_FADE) -> void:
	await _tween_alpha(0.0, duration)

## Awaitable. Fades to black, swaps scene, fades back in.
func change_scene(path: String, fade: float = DEFAULT_FADE) -> void:
	await fade_out(fade)
	get_tree().change_scene_to_file(path)
	# Let the new scene's _ready run before we start fading back in.
	await get_tree().process_frame
	await fade_in(fade)

## Awaitable. Quick black dip used as a beat between calls.
func dip(duration: float = DEFAULT_DIP) -> void:
	var half := duration * 0.5
	await fade_out(half)
	await fade_in(half)

func _tween_alpha(target: float, duration: float) -> void:
	if duration <= 0.0:
		_rect.color.a = target
		return
	var tween := create_tween()
	tween.tween_property(_rect, "color:a", target, duration)
	await tween.finished
