## Drives the scripted sequence of calls + glues the UI together.
## Attach to the Switchboard root.
extends Node

signal call_started(call_data: CallData)
signal call_resolved(success: bool, call_data: CallData)
signal all_calls_finished()

## Ordered list of CallData resources. Drag the .tres files in via the Inspector.
@export var calls: Array[CallData] = []

## Wire these in the Inspector to the corresponding instances in the scene.
@export var caller_card: CallerCard
@export var post_box: PostConnectBox
@export var patience_container: HBoxContainer

const DEFAULT_LIT: Array[StringName] = [
	&"hayes", &"doc", &"sheriff", &"reverend", &"patty", &"cole"
]

var _current: CallData

func _ready() -> void:
	GameState.reset()
	GameState.patience_changed.connect(_on_patience_changed)
	GameState.game_ended.connect(_on_game_ended)
	post_box.finished.connect(_start_next)
	for socket in get_tree().get_nodes_in_group("sockets"):
		socket.cable_plugged.connect(_on_socket_plugged)
	_start_next()

func _start_next() -> void:
	var idx := GameState.current_call_index
	if idx >= calls.size():
		all_calls_finished.emit()
		GameState.end_game(true)
		return
	_current = calls[idx]
	_apply_lit_state(_current)
	caller_card.show_call(_current)
	call_started.emit(_current)

func _apply_lit_state(c: CallData) -> void:
	var lit_keys: Array = c.sockets_lit if not c.sockets_lit.is_empty() else DEFAULT_LIT
	for socket in get_tree().get_nodes_in_group("sockets"):
		socket.lit = socket.socket_key in lit_keys

func _on_socket_plugged(socket_key: StringName) -> void:
	if _current == null:
		return
	var success := socket_key == _current.correct_socket
	call_resolved.emit(success, _current)
	if success:
		GameState.advance_call()
		post_box.play(_current.post_connect_lines)
		# _start_next() is triggered by post_box.finished
	else:
		if _current.pivotal:
			GameState.end_game(false)
		else:
			GameState.lose_patience()

func _on_patience_changed(value: int) -> void:
	for i in patience_container.get_child_count():
		patience_container.get_child(i).visible = i < value

func _on_game_ended(good: bool) -> void:
	var path := "res://scenes/ending_good.tscn" if good else "res://scenes/ending_bad.tscn"
	get_tree().change_scene_to_file(path)
