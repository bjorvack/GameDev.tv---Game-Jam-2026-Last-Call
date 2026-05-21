## Drives the scripted sequence of calls + the per-call state machine.
##
## Per-call flow:
##   OPENING       — caller's opening lines play
##   AWAITING      — waiting for the player to plug a socket; timer counts down
##   WRONG_RESP    — wrong-routing exchange playing
##   CONNECTED     — correct routing; connected_dialogue playing
##   FINISHED      — call wrapped, ready to advance
extends Node

signal call_started(call_data: CallData)
signal call_resolved(success: bool, call_data: CallData)
signal all_calls_finished()

enum CallPhase { IDLE, OPENING, AWAITING, WRONG_RESP, CONNECTED, FINISHED }

@export var calls: Array[CallData] = []

@export var caller_card: CallerCard
@export var post_box: PostConnectBox  # legacy slot; unused but kept to avoid breaking older scenes
@export var patience_container: HBoxContainer
@export var call_timer: CallTimer

const DEFAULT_LIT: Array[StringName] = [
	&"hayes", &"doc", &"sheriff", &"reverend", &"patty", &"cole"
]

## Quiet beat after a call ends, before the next one rings in.
const INTER_CALL_PAUSE := 1.5
## How long the "incoming / *ring*" indicator shows before the next call's
## opening lines begin.
const RING_DURATION := 1.2

var _current: CallData
var _phase: int = CallPhase.IDLE

func _ready() -> void:
	GameState.reset()
	GameState.patience_changed.connect(_on_patience_changed)
	GameState.game_ended.connect(_on_game_ended)
	if call_timer:
		call_timer.expired.connect(_on_timer_expired)
	for socket in get_tree().get_nodes_in_group("sockets"):
		socket.cable_plugged.connect(_on_socket_plugged)
	AudioManager.play_music()
	# We may have been loaded mid-fade by SceneTransition.change_scene —
	# fade the black overlay back in before the first ring lands.
	if SceneTransition:
		SceneTransition.fade_in()
	_start_next()

func _start_next() -> void:
	var idx := GameState.current_call_index
	if idx >= calls.size():
		all_calls_finished.emit()
		GameState.end_game(true)
		return
	# Between calls: let the previous one settle, dip to black so the
	# screen visibly resets, then ring in the next.
	if idx > 0:
		_phase = CallPhase.IDLE
		caller_card.show_idle()
		await get_tree().create_timer(INTER_CALL_PAUSE).timeout
		if SceneTransition:
			await SceneTransition.dip()
		caller_card.show_ringing()
		AudioManager.play_ring()
		await get_tree().create_timer(RING_DURATION).timeout
		AudioManager.stop_ring()
	else:
		# First call still gets a single ring as the operator picks up.
		AudioManager.play_ring()
	_current = calls[idx]
	_apply_lit_state(_current)
	caller_card.show_call(_current)
	call_started.emit(_current)
	_phase = CallPhase.OPENING
	await _play_lines(_current.opening)
	_enter_awaiting()

func _enter_awaiting() -> void:
	_phase = CallPhase.AWAITING
	caller_card.show_waiting()
	if _current.time_limit > 0.0 and call_timer:
		call_timer.start(_current.time_limit)

func _apply_lit_state(c: CallData) -> void:
	var lit_keys: Array = c.sockets_lit if not c.sockets_lit.is_empty() else DEFAULT_LIT
	for socket in get_tree().get_nodes_in_group("sockets"):
		socket.lit = socket.socket_key in lit_keys

func _on_socket_plugged(socket_key: StringName) -> void:
	if _phase != CallPhase.AWAITING or _current == null:
		return
	AudioManager.play_plug()
	var success := socket_key == _current.correct_socket
	if success:
		_resolve_correct()
	else:
		_resolve_wrong(socket_key)

func _resolve_correct() -> void:
	if call_timer:
		call_timer.stop()
	_phase = CallPhase.CONNECTED
	call_resolved.emit(true, _current)
	await _play_lines(_current.connected_dialogue)
	AudioManager.play_hangup()
	_phase = CallPhase.FINISHED
	GameState.advance_call()
	_start_next()

func _resolve_wrong(socket_key: StringName) -> void:
	_phase = CallPhase.WRONG_RESP
	call_resolved.emit(false, _current)
	var lines: Array = _current.wrong_responses.get(socket_key, _current.generic_wrong_response)
	await _play_lines(lines)
	if _current.pivotal:
		GameState.end_game(false)
		return
	GameState.lose_patience()
	# GameState.lose_patience() emits game_ended(false) when patience hits 0,
	# which routes us to the bad ending via _on_game_ended. Otherwise, retry.
	if GameState.patience > 0:
		_enter_awaiting()

func _on_timer_expired() -> void:
	if _phase != CallPhase.AWAITING:
		return
	_phase = CallPhase.WRONG_RESP
	await _play_lines(_current.timer_expired)
	AudioManager.play_hangup()
	if _current.pivotal:
		GameState.end_game(false)
		return
	GameState.lose_patience()
	# Timer expiry ends the call regardless of remaining patience.
	if GameState.patience > 0:
		GameState.advance_call()
		_start_next()

func _play_lines(lines: Array) -> void:
	if lines == null or lines.is_empty():
		return
	for line in lines:
		if line is DialogueLine:
			caller_card.show_line(line)
			await get_tree().create_timer(line.duration).timeout

func _on_patience_changed(value: int) -> void:
	for i in patience_container.get_child_count():
		patience_container.get_child(i).visible = i < value

func _on_game_ended(good: bool) -> void:
	if call_timer:
		call_timer.stop()
	var path := "res://scenes/ending_good.tscn" if good else "res://scenes/ending_bad.tscn"
	if SceneTransition:
		SceneTransition.change_scene(path)
	else:
		get_tree().change_scene_to_file(path)
