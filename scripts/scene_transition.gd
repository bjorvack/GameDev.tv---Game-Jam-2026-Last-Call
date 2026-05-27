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

## Minimum time a manual-advance monologue line must stay on screen before
## input is accepted. Matches CallerCard.MIN_VISIBLE_TIME so the feel is
## consistent between in-call dialogue and inter-call monologues.
const MONOLOGUE_MIN_VISIBLE := 0.3

signal monologue_dismissed

var _monologue_active: bool = false
var _monologue_duration: float = 0.0
var _awaiting_monologue_dismiss: bool = false
var _monologue_shown_at_msec: int = 0
var _monologue_timer_token: int = 0

## Awaitable. Assumes the screen is already faded out; fades a line of text
## in at the centre of the viewport, holds it for `hold_duration` seconds
## in auto mode, or until the player presses Space / Enter / clicks in
## manual mode. Reacts to mid-monologue toggle changes the same way the
## caller card does.
func show_monologue(text: String, hold_duration: float) -> void:
	_monologue_label.text = text
	var tw_in := create_tween()
	tw_in.tween_property(_monologue_label, "modulate:a", 1.0, MONOLOGUE_FADE)
	await tw_in.finished
	_monologue_active = true
	_monologue_duration = maxf(hold_duration, 0.0)
	if SettingsState and not SettingsState.manual_dialogue_changed.is_connected(_on_manual_dialogue_changed):
		SettingsState.manual_dialogue_changed.connect(_on_manual_dialogue_changed)
	_apply_monologue_mode()
	await monologue_dismissed
	var tw_out := create_tween()
	tw_out.tween_property(_monologue_label, "modulate:a", 0.0, MONOLOGUE_FADE)
	await tw_out.finished
	_monologue_label.text = ""

func _on_manual_dialogue_changed(_value: bool) -> void:
	if _monologue_active:
		_apply_monologue_mode()

func _apply_monologue_mode() -> void:
	if not _monologue_active:
		return
	_monologue_timer_token += 1
	if SettingsState and SettingsState.manual_dialogue:
		_awaiting_monologue_dismiss = true
		_monologue_shown_at_msec = Time.get_ticks_msec()
	else:
		_awaiting_monologue_dismiss = false
		var token := _monologue_timer_token
		var t := get_tree().create_timer(_monologue_duration)
		t.timeout.connect(func(): _on_monologue_timeout(token))

func _on_monologue_timeout(token: int) -> void:
	if not _monologue_active or token != _monologue_timer_token:
		return
	_finish_monologue()

func _finish_monologue() -> void:
	_monologue_active = false
	_awaiting_monologue_dismiss = false
	_monologue_timer_token += 1
	monologue_dismissed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not _awaiting_monologue_dismiss or not _monologue_active:
		return
	var is_dismiss := false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			is_dismiss = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		is_dismiss = true
	if not is_dismiss:
		return
	if Time.get_ticks_msec() - _monologue_shown_at_msec < int(MONOLOGUE_MIN_VISIBLE * 1000.0):
		return
	get_viewport().set_input_as_handled()
	_finish_monologue()
