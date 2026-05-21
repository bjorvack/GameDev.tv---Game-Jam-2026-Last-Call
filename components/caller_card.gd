## Cinematic dialogue display: shows the active speaker silhouette, name,
## and the active line, with no surrounding card. The CallDirector drives
## this by calling `show_call()` when a call begins (to seed the portrait +
## caller name) and `show_line()` for every spoken DialogueLine.
class_name CallerCard
extends Control

const FADE_DURATION := 0.2

@onready var portrait: TextureRect = $Portrait
@onready var caller_name: Label = $CallerName
@onready var request_text: Label = $RequestText

var _current_call: CallData
var _fade_tween: Tween

func _ready() -> void:
	modulate.a = 0.0
	hide()

## Called when a new call begins. Seeds the caller's name + portrait and
## clears the dialogue area.
func show_call(c: CallData) -> void:
	_current_call = c
	caller_name.text = c.caller_name
	request_text.text = ""
	if c.caller_portrait:
		portrait.texture = c.caller_portrait

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
	_fade_to(0.0)

## Hidden between calls — the line is clear.
func show_idle() -> void:
	_current_call = null
	portrait.texture = null
	_fade_to(0.0)

## Hidden during the ring — visual cue handled elsewhere (or by audio later).
func show_ringing() -> void:
	_fade_to(0.0)

func _fade_to(target_alpha: float) -> void:
	if _fade_tween:
		_fade_tween.kill()
	if target_alpha > 0.0:
		show()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", target_alpha, FADE_DURATION)
	if target_alpha <= 0.0:
		_fade_tween.tween_callback(hide)
