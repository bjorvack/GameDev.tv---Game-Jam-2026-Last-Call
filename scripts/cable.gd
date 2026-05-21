## Two-ended patch cord. Click-to-plug: clicks on Socket nodes drive plug /
## unplug. Visual is a Line2D whose two endpoints sit at the shelf when idle
## and snap to the plugged-in sockets' centres otherwise.
##
## Lifecycle, driven by the CallDirector's RINGING / ANSWERED / AWAITING_ROUTING
## phases:
##   - At RINGING: both ends rest on the shelf. Clicking the ringing socket
##     "answers" — emits `answered(socket_key)`, end A snaps to that socket.
##   - During ANSWERED + AWAITING_ROUTING: end A stays plugged in the caller
##     socket. Clicking any reachable socket plugs end B and emits
##     `routed(socket_key)`. Clicking either plugged socket again unplugs that
##     end and returns it to the shelf.
##
## CallDirector decides whether `routed` is correct/wrong; the cable itself
## doesn't care.
extends Line2D

signal answered(socket_key: StringName)
signal routed(socket_key: StringName)
signal end_unplugged(socket_key: StringName)

@export var jack_position: Vector2 = Vector2.ZERO
@export var sockets_group: StringName = &"sockets"
## Horizontal offset between the two jack rest positions on the shelf.
@export var jack_spacing: float = 40.0
## Vertical offset of the jacks relative to `jack_position`.
@export var jack_height_offset: float = 0.0

## The CallDirector flips these as it walks through the per-call phases.
## Sockets ignore clicks when both are false — so between calls (and during
## the caller's opening) nothing is pluggable.
var accepting_answer: bool = false
var accepting_routing: bool = false

var _jack_a: Sprite2D
var _jack_b: Sprite2D

var _socket_a: Socket = null
var _socket_b: Socket = null

func _ready() -> void:
	_jack_a = get_node_or_null("JackA")
	_jack_b = get_node_or_null("JackB")
	# Backwards compat: older scenes only have one Jack — use it for A and
	# spawn a clone for B at runtime.
	if _jack_a == null:
		var legacy := get_node_or_null("Jack")
		if legacy is Sprite2D:
			legacy.name = "JackA"
			_jack_a = legacy
	if _jack_b == null and _jack_a:
		_jack_b = _jack_a.duplicate()
		_jack_b.name = "JackB"
		add_child(_jack_b)

	clear_points()
	add_point(_rest_position_a())
	add_point(_rest_position_b())
	_apply_endpoints()

	# Subscribe to socket clicks across the scene tree.
	for node in get_tree().get_nodes_in_group(sockets_group):
		if node is Socket:
			node.socket_pressed.connect(_on_socket_pressed)

func _rest_position_a() -> Vector2:
	return to_local(Vector2(jack_position.x - jack_spacing * 0.5, jack_position.y + jack_height_offset))

func _rest_position_b() -> Vector2:
	return to_local(Vector2(jack_position.x + jack_spacing * 0.5, jack_position.y + jack_height_offset))

func _apply_endpoints() -> void:
	set_point_position(0, _endpoint_for(_socket_a, _rest_position_a()))
	set_point_position(1, _endpoint_for(_socket_b, _rest_position_b()))
	if _jack_a:
		_jack_a.position = get_point_position(0)
	if _jack_b:
		_jack_b.position = get_point_position(1)

func _endpoint_for(socket: Socket, fallback: Vector2) -> Vector2:
	if socket == null:
		return fallback
	return to_local(socket.plug_target())

func _on_socket_pressed(socket: Socket) -> void:
	# Unplug only the routing end — and only while routing is accepted.
	# End A (the caller side) is locked in once the call is answered; the
	# director controls when it releases.
	if socket == _socket_b:
		if not accepting_routing:
			return
		_socket_b = null
		socket.state = Socket.State.REACHABLE
		_apply_endpoints()
		end_unplugged.emit(socket.socket_key)
		return

	# Plug end A (answer) — only allowed when we're armed for an answer
	# and the socket is the actively ringing one.
	if _socket_a == null:
		if not accepting_answer:
			return
		if socket.state != Socket.State.RINGING:
			return
		_socket_a = socket
		socket.state = Socket.State.PLUGGED
		_apply_endpoints()
		answered.emit(socket.socket_key)
		return

	# Plug end B (route) — only allowed when we're armed for routing and
	# the socket is reachable (lit but not unlit / not already plugged).
	if _socket_b == null:
		if not accepting_routing:
			return
		if socket.state != Socket.State.REACHABLE:
			return
		_socket_b = socket
		socket.state = Socket.State.PLUGGED
		_apply_endpoints()
		routed.emit(socket.socket_key)
		return

## Pop both ends back to the shelf — used by the director when a call ends
## or a wrong-routing attempt has been resolved.
func release_routing_end() -> void:
	if _socket_b:
		_socket_b.state = Socket.State.REACHABLE
		_socket_b = null
	_apply_endpoints()

func release_all() -> void:
	if _socket_a:
		_socket_a.state = Socket.State.REACHABLE
		_socket_a = null
	if _socket_b:
		_socket_b.state = Socket.State.REACHABLE
		_socket_b = null
	_apply_endpoints()
