## Global fade-to-black overlay. Autoload as "SceneTransition".
##
## Lives on its own top-most CanvasLayer so it sits above HUDs, BGs, and
## the cable. Three roles:
##
## - Hard scene swap: await SceneTransition.change_scene(path) — fades out,
##   loads the new scene, fades back in.
## - Soft inter-call beat: await SceneTransition.dip(duration) — quick fade
##   to black and back without changing scenes.
## - Operator inner monologue: await SceneTransition.show_monologue(text,
##   duration) — fades a center-of-screen line of italicised text in over
##   the black overlay, holds, fades out. The caller must have already
##   faded the screen out.
extends CanvasLayer

const DEFAULT_FADE := 0.45
const DEFAULT_DIP := 0.55
## How long the monologue label fades in / out around the hold period.
const MONOLOGUE_FADE := 0.35
## Path to the period typewriter font used by the dialogue UI; reusing it
## keeps the monologue visually consistent with the caller card lines.
const MONOLOGUE_FONT_PATH := "res://art/fonts/SpecialElite-Regular.ttf"
const MONOLOGUE_FONT_SIZE := 26
## Warm cream matching the caller card text colour.
const MONOLOGUE_COLOR := Color(0.95, 0.89, 0.78, 1.0)
## Dark teal outline to lift the text off the black overlay.
const MONOLOGUE_OUTLINE := Color(0.06, 0.16, 0.2, 1.0)
const MONOLOGUE_OUTLINE_SIZE := 4

var _rect: ColorRect
var _monologue_label: Label

func _ready() -> void:
	layer = 100
	_rect = ColorRect.new()
	_rect.color = Color(0, 0, 0, 0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)
	# Make sure the overlay always covers the viewport, even after window
	# resizes — anchors handle that for free.
	_monologue_label = Label.new()
	_monologue_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_monologue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_monologue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_monologue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_monologue_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_monologue_label.add_theme_color_override("font_color", MONOLOGUE_COLOR)
	_monologue_label.add_theme_color_override("font_outline_color", MONOLOGUE_OUTLINE)
	_monologue_label.add_theme_constant_override("outline_size", MONOLOGUE_OUTLINE_SIZE)
	_monologue_label.add_theme_font_size_override("font_size", MONOLOGUE_FONT_SIZE)
	var font := load(MONOLOGUE_FONT_PATH) as Font
	if font:
		_monologue_label.add_theme_font_override("font", font)
	# Generous side margins so long lines don't reach the viewport edge.
	_monologue_label.offset_left = 80
	_monologue_label.offset_right = -80
	_monologue_label.modulate.a = 0.0
	_monologue_label.text = ""
	add_child(_monologue_label)

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

## Awaitable. Assumes the screen is already faded out; fades a line of text
## in at the centre of the viewport, holds it for `hold_duration` seconds,
## then fades it back out so the caller can resume the normal fade-in.
func show_monologue(text: String, hold_duration: float) -> void:
	_monologue_label.text = text
	var tw_in := create_tween()
	tw_in.tween_property(_monologue_label, "modulate:a", 1.0, MONOLOGUE_FADE)
	await tw_in.finished
	await get_tree().create_timer(maxf(hold_duration, 0.0)).timeout
	var tw_out := create_tween()
	tw_out.tween_property(_monologue_label, "modulate:a", 0.0, MONOLOGUE_FADE)
	await tw_out.finished
	_monologue_label.text = ""
