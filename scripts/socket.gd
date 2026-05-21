## A single socket on the switchboard. Control-based so it can live inside
## containers like GridContainer for auto-layout.
##
## Add to the "sockets" group (already done in the .tscn) so cable.gd and
## call_director.gd can find every socket via groups.
##
## States drive the visuals:
##   UNLIT     — line is dark, can't be plugged into.
##   REACHABLE — line is live, can be plugged into. Lamp drawn but quiet.
##   RINGING   — an active call is on this line; lamp pulses amber. Plugging
##               in here answers the call.
##   PLUGGED   — a cable end is currently in this socket.
class_name Socket
extends Control

signal cable_plugged(socket_key: StringName)
signal socket_pressed(socket: Socket)

enum State { UNLIT, REACHABLE, RINGING, PLUGGED }

@export var socket_key: StringName = &""

@export var label_text: String = "":
	set(value):
		label_text = value
		if is_node_ready():
			$NameLabel.text = label_text

var state: int = State.REACHABLE:
	set(value):
		state = value
		if is_node_ready():
			_apply_state()

var _pulse_tween: Tween

func _ready() -> void:
	$NameLabel.text = label_text
	_apply_state()
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			socket_pressed.emit(self)
			get_viewport().set_input_as_handled()

func _apply_state() -> void:
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null
	var glow := get_node_or_null("Glow") as Light2D
	if glow:
		glow.energy = 0.0
	match state:
		State.UNLIT:
			modulate = Color(0.45, 0.5, 0.55, 1.0)
		State.REACHABLE:
			modulate = Color(1, 1, 1, 1)
		State.RINGING:
			modulate = Color(1, 1, 1, 1)
			_start_pulse(glow)
		State.PLUGGED:
			modulate = Color(1, 1, 1, 1)
			if glow:
				glow.energy = 0.6

func _start_pulse(glow: Light2D) -> void:
	if glow == null:
		return
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(glow, "energy", 0.8, 0.55)
	_pulse_tween.tween_property(glow, "energy", 0.2, 0.55)

## Center of this socket in viewport coords — cable.gd snaps the jack here.
func plug_target() -> Vector2:
	return get_global_rect().get_center()

## Called by cable.gd when a cable end is dropped here.
func plug() -> void:
	cable_plugged.emit(socket_key)
