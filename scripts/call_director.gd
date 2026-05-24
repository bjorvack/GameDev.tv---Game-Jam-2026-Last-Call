## Drives the scripted sequence of calls + the per-call state machine.
##
## Per-call flow:
##   RINGING       — caller_socket lamp pulses, waiting for the player to
##                   plug end A into the caller's socket (= answer).
##   OPENING       — end A plugged. Caller's opening lines play.
##   AWAITING      — opening done. Waiting for the player to plug end B into
##                   a recipient socket.
##   WRONG_RESP    — end B plugged into the wrong socket. Lines play, then
##                   end B pops back to the shelf so the player can retry.
##   CONNECTED     — end B plugged correctly. connected_dialogue plays.
##   FINISHED      — call wrapped, ready to advance.
extends Node

signal call_started(call_data: CallData)
signal call_resolved(success: bool, call_data: CallData)
signal all_calls_finished()

enum CallPhase { IDLE, RINGING, OPENING, AWAITING, WRONG_RESP, DIALING, CONNECTED, FINISHED }

@export var calls: Array[CallData] = []

@export var caller_card: CallerCard
@export var patience_container: HBoxContainer
@export var call_timer: CallTimer
@export var cable_path: NodePath

const DEFAULT_LIT: Array[StringName] = [
	&"hayes", &"doc", &"sheriff", &"reverend", &"patty", &"cole",
	&"henley", &"bray",
	# Red herrings — always reachable, never correct.
	&"fire", &"phone_vine", &"town_hall", &"lounge",
	&"sentinel", &"funeral", &"bus", &"esso",
	&"phone_west", &"phone_east",
]

## Quiet beat after a call ends, before the next one rings in.
const INTER_CALL_PAUSE := 1.5
## How long the "incoming / *ring*" indicator shows before the caller socket
## starts pulsing.
const RING_DURATION := 1.2
## How long the SceneTransition fade lasts on each side of the operator
## monologue beat. Longer than a normal dip so the voice-over has air.
const MONOLOGUE_FADE := 0.8

var _current: CallData
var _phase: int = CallPhase.IDLE
var _cable: Node
## Tracks whether the current call's first-leg routing (if any) has been
## resolved. Reset on every new call.
var _first_leg_completed: bool = false
## Set when the previous call ended on a timer expiry so the inter-call
## monologue can use that call's `timer_expired_thought` instead of its
## `operator_thought` (which assumes the player heard the connect dialogue).
var _last_call_timed_out: bool = false

func _ready() -> void:
	GameState.reset()
	# Reorder the socket grid before anyone sees the board, so each run has
	# a different layout and players can't memorise positions.
	_shuffle_sockets()
	GameState.patience_changed.connect(_on_patience_changed)
	GameState.game_ended.connect(_on_game_ended)
	if call_timer:
		call_timer.expired.connect(_on_timer_expired)
	if cable_path != NodePath():
		_cable = get_node_or_null(cable_path)
	if _cable == null:
		# Fallback: find first node with a `routed` signal.
		for node in get_tree().get_nodes_in_group("cable"):
			_cable = node
			break
	if _cable:
		_cable.answered.connect(_on_cable_answered)
		_cable.routed.connect(_on_cable_routed)
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
	# Between calls: let the previous one settle, fade to black, optionally
	# play the previous call's operator inner monologue, then fade back in
	# and ring the next caller.
	if idx > 0:
		_phase = CallPhase.IDLE
		caller_card.show_idle()
		await get_tree().create_timer(INTER_CALL_PAUSE).timeout
		await _play_operator_thought(calls[idx - 1])
	_current = calls[idx]
	_first_leg_completed = false
	# The next call's _on_timer_expired (if any) will set this true again.
	_last_call_timed_out = false
	_apply_lit_state(_current)
	_enter_ringing()

func _play_operator_thought(prev: CallData) -> void:
	if prev == null:
		if SceneTransition:
			await SceneTransition.dip()
		return
	# Pick the monologue source based on how the call ended.
	var lines: Array[DialogueLine] = prev.timer_expired_thought if _last_call_timed_out else prev.operator_thought
	if lines.is_empty():
		# No monologue authored for this outcome — just a quick visual reset.
		if SceneTransition:
			await SceneTransition.dip()
		return
	if SceneTransition:
		await SceneTransition.fade_out(MONOLOGUE_FADE)
	# Show each monologue line centred on top of the black overlay,
	# bypassing the caller card entirely. The board is hidden — only the
	# operator's words exist for these few seconds.
	for line in lines:
		if line is DialogueLine and SceneTransition:
			await SceneTransition.show_monologue(line.text, line.duration)
	caller_card.show_idle()
	if SceneTransition:
		await SceneTransition.fade_in(MONOLOGUE_FADE)

func _enter_ringing() -> void:
	_phase = CallPhase.RINGING
	caller_card.show_ringing()
	AudioManager.play_ring()
	# Light the caller's socket so the player can see where the call is
	# coming in.
	for socket in get_tree().get_nodes_in_group("sockets"):
		if socket.socket_key == _current.caller_socket:
			socket.state = Socket.State.RINGING
	_arm_cable(true, false)

func _on_cable_answered(socket_key: StringName) -> void:
	if _phase != CallPhase.RINGING or _current == null:
		return
	if socket_key != _current.caller_socket:
		return
	AudioManager.stop_ring()
	AudioManager.play_plug()
	caller_card.show_call(_current)
	call_started.emit(_current)
	_phase = CallPhase.OPENING
	# Lock everything while the caller speaks — no plug / unplug.
	_arm_cable(false, false)
	await _play_lines(_current.opening)
	_enter_awaiting()

func _enter_awaiting() -> void:
	_phase = CallPhase.AWAITING
	caller_card.show_waiting()
	if _current.time_limit > 0.0 and call_timer:
		call_timer.start(_current.time_limit)
	_arm_cable(false, true)

func _apply_lit_state(c: CallData) -> void:
	var lit_keys: Array = c.sockets_lit if not c.sockets_lit.is_empty() else DEFAULT_LIT
	# Make sure the caller_socket is always reachable too.
	if c.caller_socket != &"" and not (c.caller_socket in lit_keys):
		lit_keys = lit_keys.duplicate()
		lit_keys.append(c.caller_socket)
	for socket in get_tree().get_nodes_in_group("sockets"):
		if socket.socket_key in lit_keys:
			socket.state = Socket.State.REACHABLE
		else:
			socket.state = Socket.State.UNLIT

func _on_cable_routed(socket_key: StringName) -> void:
	if _phase != CallPhase.AWAITING or _current == null:
		return
	AudioManager.play_plug()
	# Lock the cable while we play the result so the player can't unplug
	# mid-line.
	_arm_cable(false, false)
	# First-leg routing: caller wants the operator to try a number that
	# won't pick up, before being redirected. Until that's done, the
	# real `correct_socket` is not yet accepted.
	if _current.first_leg_socket != &"" and not _first_leg_completed:
		if socket_key == _current.first_leg_socket:
			_resolve_first_leg()
			return
		_resolve_wrong(socket_key)
		return
	var success := socket_key == _current.correct_socket
	if success:
		_resolve_correct()
	else:
		_resolve_wrong(socket_key)

func _arm_cable(answer: bool, routing: bool) -> void:
	if _cable:
		_cable.accepting_answer = answer
		_cable.accepting_routing = routing

## Reorder the SocketsGrid's children at random. GridContainer lays sockets
## out by child index, so reordering reshuffles the visual layout. Called
## once on _ready before the fade-in completes, so the player only ever
## sees the shuffled board.
func _shuffle_sockets() -> void:
	var sockets := get_tree().get_nodes_in_group("sockets")
	if sockets.size() < 2:
		return
	var grid := sockets[0].get_parent()
	if grid == null:
		return
	sockets.shuffle()
	for i in sockets.size():
		grid.move_child(sockets[i], i)

## First-leg routing: the caller asked us to try a number that won't pick
## up. Play the ringback, then the dialogue (typically "no answer" + the
## caller asking us to try someone else), then auto-release the routing
## end so the player can re-route to `correct_socket`.
func _resolve_first_leg() -> void:
	# Pause the patience timer while the no-answer beat plays — the player
	# isn't doing anything wrong, the line just isn't picking up.
	if call_timer:
		call_timer.stop()
	_phase = CallPhase.DIALING
	caller_card.show_waiting()
	# One ringback sample, played to completion, then the recipient line
	# fails to answer — segues straight into the first_leg dialogue.
	await AudioManager.play_ring_once()
	_phase = CallPhase.CONNECTED
	await _play_lines(_current.first_leg_dialogue)
	_first_leg_completed = true
	# Pop the routing end back to the shelf and re-enable plugging.
	if _cable:
		_cable.release_routing_end()
	_enter_awaiting()

func _resolve_correct() -> void:
	if call_timer:
		call_timer.stop()
	# DIALING: the destination phone rings once as a ringback, then the
	# recipient picks up. Caller card is hidden so the player just hears
	# the single ring over a quiet board.
	_phase = CallPhase.DIALING
	call_resolved.emit(true, _current)
	caller_card.show_waiting()
	await AudioManager.play_ring_once()

	_phase = CallPhase.CONNECTED
	await _play_lines(_current.connected_dialogue)
	AudioManager.play_hangup()
	if _cable:
		_cable.release_all()
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
	# Pop the routing end back so the player can try again.
	if _cable:
		_cable.release_routing_end()
	if GameState.patience > 0:
		_enter_awaiting()

func _on_timer_expired() -> void:
	if _phase != CallPhase.AWAITING:
		return
	_phase = CallPhase.WRONG_RESP
	await _play_lines(_current.timer_expired)
	AudioManager.play_hangup()
	if _cable:
		_cable.release_all()
	if _current.pivotal:
		GameState.end_game(false)
		return
	GameState.lose_patience()
	# Timer expiry ends the call regardless of remaining patience.
	if GameState.patience > 0:
		# Mark the previous call as a timer failure so the inter-call
		# monologue picks the right thought source.
		_last_call_timed_out = true
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
