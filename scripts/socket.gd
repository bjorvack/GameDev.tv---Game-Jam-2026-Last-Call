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

const RingGlyphScript := preload("res://scripts/ring_glyph.gd")

signal cable_plugged(socket_key: StringName)
signal socket_pressed(socket: Socket)

enum State { UNLIT, REACHABLE, RINGING, PLUGGED }

@export var socket_key: StringName = &""

@export var label_text: String = "":
	set(value):
		label_text = value
		if is_node_ready():
			$LabelCard/NameLabel.text = label_text

var state: int = State.REACHABLE:
	set(value):
		state = value
		if is_node_ready():
			_apply_state()

var _pulse_tween: Tween

func _ready() -> void:
	$LabelCard/NameLabel.text = label_text
	_apply_state()
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			socket_pressed.emit(self)
			get_viewport().set_input_as_handled()

const GLOW_AMBER := Color(1.0, 0.78, 0.4, 1.0)
## "This line is dead" red glow. Pushed warmer + more saturated than the
## cord's aged red because the Light2D's ADD blend mode tints the bronze
## panel beneath, so a muted red ends up reading as orange.
const GLOW_RED := Color(1.0, 0.18, 0.18, 1.0)

func _apply_state() -> void:
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null
	modulate = Color(1, 1, 1, 1)
	var glow := get_node_or_null("Glow") as Light2D
	if glow:
		glow.energy = 0.0
		glow.color = GLOW_AMBER
	# Default: hide the ringing arcs. Only RINGING turns them on.
	# This gives colour-blind players a shape + motion cue independent
	# of the amber lamp pulse.
	var ring_glyph := get_node_or_null("RingGlyph") as RingGlyphScript
	if ring_glyph:
		ring_glyph.stop()
	# Default: the dimmer filter is ON, so an idle lit socket reads as
	# "available but quiet". States that need the player's attention
	# (RINGING) or that already carry their own clear signal — UNLIT's
	# red halo, PLUGGED's visible cable — switch it OFF below so the
	# underlying glow comes through at full strength.
	var light_filter := get_node_or_null("LightFilter") as Node2D
	if light_filter:
		light_filter.visible = true
	match state:
		State.UNLIT:
			# Don't darken the socket — paint a small red halo instead so
			# the player reads "line is dead, don't bother" rather than
			# "this socket is just dim".
			if glow:
				glow.color = GLOW_RED
				glow.energy = 0.45
			if light_filter:
				light_filter.visible = false
		State.REACHABLE:
			pass
		State.RINGING:
			_start_pulse(glow)
			if ring_glyph:
				ring_glyph.play()
			if light_filter:
				light_filter.visible = false
		State.PLUGGED:
			if glow:
				glow.energy = 0.6
			if light_filter:
				light_filter.visible = false

func _start_pulse(glow: Light2D) -> void:
	if glow == null:
		return
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(glow, "energy", 0.8, 0.55)
	_pulse_tween.tween_property(glow, "energy", 0.2, 0.55)

## Centre of this socket in viewport coords — cable.gd snaps the jack here.
## Uses the `Visual/Center` Marker2D when present, so the alignment point
## tracks the painted socket hole rather than the bounding rect's centre.
func plug_target() -> Vector2:
	var marker := get_node_or_null("Visual/Center") as Marker2D
	if marker:
		return marker.global_position
	return get_global_rect().get_center()

## Called by cable.gd when a cable end is dropped here.
func plug() -> void:
	cable_plugged.emit(socket_key)
