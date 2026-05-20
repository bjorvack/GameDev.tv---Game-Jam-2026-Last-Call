## Generic dialogue display: shows the active speaker, the active line, and
## the active portrait. The CallDirector drives this by calling `show_call()`
## when a call begins (to seed the portrait + caller name) and `show_line()`
## for every spoken DialogueLine.
class_name CallerCard
extends PanelContainer

@onready var portrait: TextureRect = $HBoxContainer/Portrait
@onready var caller_name: Label = $HBoxContainer/VBoxContainer/CallerName
@onready var request_text: Label = $HBoxContainer/VBoxContainer/RequestText

var _current_call: CallData

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

## Shown between lines while we wait for the player to route.
func show_waiting() -> void:
	request_text.text = "[the caller waits on the line]"

## Shown briefly between calls — the previous caller has hung up.
func show_idle() -> void:
	_current_call = null
	caller_name.text = ""
	request_text.text = "[the line is clear]"
	portrait.texture = null

## Shown briefly before a new call's opening lines — a ring on the board.
func show_ringing() -> void:
	caller_name.text = "Incoming"
	request_text.text = "[a light flickers on the board — *ring*]"
