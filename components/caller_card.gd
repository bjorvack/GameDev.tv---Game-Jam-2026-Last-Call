## Cinematic dialogue display: shows the active speaker silhouette, name,
## and the active line, with no surrounding card. The CallDirector drives
## this by calling `show_call()` when a call begins (to seed the portrait +
## caller name) and `show_line()` for every spoken DialogueLine.
class_name CallerCard
extends Control

## Emitted when the active line should advance — either because the
## player dismissed it (manual mode) or the auto-advance timer expired
## (auto mode). The CallDirector awaits this once per line.
signal line_dismissed

const FADE_DURATION := 0.2
## Minimum time a manual-advance line must stay on screen before input is
## accepted, so a held key / double-click can't blast through consecutive
## clue lines.
const MIN_VISIBLE_TIME := 0.3

@onready var portrait: TextureRect = $Portrait
@onready var caller_name: Label = $CallerName
@onready var request_text: Label = $RequestText
@onready var _halo: CanvasItem = get_node_or_null("Halo")
@onready var _shadow: CanvasItem = get_node_or_null("GroundShadow")
@onready var _continue_hint: CanvasItem = get_node_or_null("ContinueHint")

var _current_call: CallData
var _fade_tween: Tween
## True between play_line() and the corresponding line_dismissed emit.
## All mode switches and timer callbacks gate on this so we never
## advance the same line twice or fire after the call director moved on.
var _line_active: bool = false
## True while a voice clip is playing for the current line. Lets
## _finish_line know whether to call VoicePlayer.stop() and skips
## the natural-finish auto-advance once we've already advanced.
var _voice_active: bool = false
var _current_duration: float = 0.0
## When true, _unhandled_input accepts Space/Enter/LMB as a dismiss.
## Toggled on/off as the manual-dialogue setting flips, even mid-line.
var _awaiting_dismiss: bool = false
var _line_shown_at_msec: int = 0
## Monotonically incremented every time we (re)start an auto-advance
## timer or cancel one. Stale SceneTreeTimer callbacks compare their
## captured token against this to know whether they're still relevant.
var _timer_token: int = 0

func _ready() -> void:
	modulate.a = 0.0
	hide()
	if _continue_hint:
		_continue_hint.visible = false
	if SettingsState:
		SettingsState.manual_dialogue_changed.connect(_on_manual_dialogue_changed)

## Begin playback of a single line. Decides between auto-timer and
## manual-dismiss based on the current SettingsState, and reacts to
## mid-line toggle changes via _on_manual_dialogue_changed. Awaiters
## listen for the `line_dismissed` signal.
##
## `voice` is the optional AI-generated voice clip for this line.
## When provided, it plays immediately via VoicePlayer; the
## auto-timer is replaced by VoicePlayer.finished so auto-advance
## fires exactly when the speech ends. Manual-dismiss interrupts
## the voice (see _finish_line). Pass null for silent lines —
## auto-advance falls back to `line.duration`.
func play_line(line: DialogueLine, voice: AudioStream = null) -> void:
	show_line(line)
	var voice_duration := VoicePlayer.play(voice) if voice else 0.0
	_voice_active = voice_duration > 0.0
	if _voice_active:
		# Auto-advance now hangs off VoicePlayer.finished, not a
		# duration-based SceneTreeTimer — line advances precisely when
		# speech ends. The auto-timer path stays in place anyway as a
		# belt-and-suspenders fallback in case VoicePlayer.finished
		# doesn't fire (e.g. corrupted stream); the stream's reported
		# length plus a small safety margin caps the wait.
		VoicePlayer.finished.connect(_on_voice_finished, CONNECT_ONE_SHOT)
		_current_duration = voice_duration + 0.5
	else:
		_current_duration = line.duration
	_line_active = true
	_apply_dialogue_mode()

func _is_manual() -> bool:
	return SettingsState != null and SettingsState.manual_dialogue

func _on_manual_dialogue_changed(_value: bool) -> void:
	# Player flipped the toggle (likely via the in-game pause overlay).
	# If we're mid-line, swap the active mechanism without losing the line.
	if _line_active:
		_apply_dialogue_mode()

func _apply_dialogue_mode() -> void:
	if not _line_active:
		return
	# Cancel any in-flight auto timer; any stale callback that still fires
	# will see a mismatched token and bail.
	_timer_token += 1
	if _is_manual():
		_arm_dismiss()
	else:
		_disarm_dismiss()
		_start_auto_timer(_current_duration)

func _start_auto_timer(duration: float) -> void:
	var token := _timer_token
	var t := get_tree().create_timer(maxf(duration, 0.0))
	t.timeout.connect(func(): _on_auto_timeout(token))

func _on_auto_timeout(token: int) -> void:
	if not _line_active or token != _timer_token:
		return
	_finish_line()

const HINT_FADE_TIME := 0.15

var _hint_fade_tween: Tween

func _arm_dismiss() -> void:
	_awaiting_dismiss = true
	_line_shown_at_msec = Time.get_ticks_msec()
	if _continue_hint:
		_set_hint_alpha(0.0)
		_continue_hint.visible = false
		# Defer showing the hint until the line has been visible long enough
		# to be safely dismissable, so it doesn't flicker on for one frame.
		var t := get_tree().create_timer(MIN_VISIBLE_TIME)
		t.timeout.connect(_show_continue_hint_if_armed)

func _show_continue_hint_if_armed() -> void:
	if _awaiting_dismiss and _continue_hint:
		_continue_hint.visible = true
		_fade_hint_to(1.0)

func _disarm_dismiss() -> void:
	_awaiting_dismiss = false
	if _continue_hint:
		# Snap the hint off rather than fading — the line itself is about
		# to fade out, so a hint fade-out on top would feel redundant.
		_continue_hint.visible = false
		_set_hint_alpha(1.0)

func _set_hint_alpha(a: float) -> void:
	if _continue_hint and _continue_hint is CanvasItem:
		_continue_hint.modulate.a = a

func _fade_hint_to(target: float) -> void:
	if _continue_hint == null:
		return
	if _hint_fade_tween:
		_hint_fade_tween.kill()
	_hint_fade_tween = create_tween()
	_hint_fade_tween.tween_property(_continue_hint, "modulate:a", target, HINT_FADE_TIME)

func _finish_line() -> void:
	_line_active = false
	_timer_token += 1
	_disarm_dismiss()
	if _voice_active:
		# Player manually advanced (or some other early-finish path)
		# while the voice clip was still talking. Cut it off cleanly
		# so the next line doesn't overlap the tail.
		_voice_active = false
		VoicePlayer.stop()
	line_dismissed.emit()

## Voice finished naturally. In auto mode this is the canonical
## advance trigger; in manual mode we let the player decide when to
## dismiss, so we just clear the active flag and stop watching the
## signal.
func _on_voice_finished() -> void:
	_voice_active = false
	if not _line_active:
		return
	if _is_manual():
		return
	_finish_line()

func _unhandled_input(event: InputEvent) -> void:
	if not _awaiting_dismiss or not _line_active:
		return
	var is_dismiss := false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			is_dismiss = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		is_dismiss = true
	if not is_dismiss:
		return
	if Time.get_ticks_msec() - _line_shown_at_msec < int(MIN_VISIBLE_TIME * 1000.0):
		return
	get_viewport().set_input_as_handled()
	_finish_line()

## Called when a new call begins. Seeds the caller's name + portrait and
## clears the dialogue area. Also makes sure the portrait/halo/shadow are
## visible in case the previous beat was an operator monologue.
func show_call(c: CallData) -> void:
	_current_call = c
	caller_name.text = c.caller_name
	request_text.text = ""
	if c.caller_portrait:
		portrait.texture = c.caller_portrait
	portrait.visible = true
	if _halo:
		_halo.visible = true
	if _shadow:
		_shadow.visible = true

## Shows a single DialogueLine. If the line has its own speaker/portrait,
## those override the call defaults for this line only.
func show_line(line: DialogueLine) -> void:
	if line.speaker != "":
		caller_name.text = line.speaker
	if line.portrait:
		portrait.texture = line.portrait
	elif _current_call and _current_call.caller_portrait:
		portrait.texture = _current_call.caller_portrait
	request_text.text = line.text
	_fade_to(1.0)

## Hidden between dialogue lines — the player is routing.
func show_waiting() -> void:
	_cancel_active_line()
	_fade_to(0.0)

## Hidden between calls — the line is clear.
func show_idle() -> void:
	_cancel_active_line()
	_current_call = null
	portrait.texture = null
	_fade_to(0.0)

## Hidden during the ring — visual cue handled elsewhere (or by audio later).
func show_ringing() -> void:
	_cancel_active_line()
	_fade_to(0.0)

## Drop any in-flight line state without firing line_dismissed. Used when
## the call director changes phase (waiting / idle / ringing) and any
## outstanding line should simply be abandoned.
func _cancel_active_line() -> void:
	_line_active = false
	_timer_token += 1
	_disarm_dismiss()
	if _voice_active:
		# Phase change (show_idle / show_waiting / show_ringing) means
		# the voice should go with the line — otherwise the next call's
		# audio overlaps the abandoned tail.
		_voice_active = false
		VoicePlayer.stop()

func _fade_to(target_alpha: float) -> void:
	if _fade_tween:
		_fade_tween.kill()
	if target_alpha > 0.0:
		show()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", target_alpha, FADE_DURATION)
	if target_alpha <= 0.0:
		_fade_tween.tween_callback(hide)
