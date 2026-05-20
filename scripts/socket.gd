## A single socket on the switchboard. Control-based so it can live inside
## containers like GridContainer for auto-layout.
##
## Add to the "sockets" group (already done in the .tscn) so cable.gd and
## call_director.gd can find every socket via groups.
class_name Socket
extends Control

signal cable_plugged(socket_key: StringName)

@export var socket_key: StringName = &""

@export var label_text: String = "":
	set(value):
		label_text = value
		if is_node_ready():
			$NameLabel.text = label_text

@export var lit: bool = true:
	set(value):
		lit = value
		modulate.a = 1.0 if lit else 0.3

func _ready() -> void:
	$NameLabel.text = label_text

## Called by cable.gd when the cable is released over this socket's rect.
func plug() -> void:
	if lit:
		cable_plugged.emit(socket_key)
