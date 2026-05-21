## Two-ended patch cord. Click-to-plug: clicks on Socket nodes drive plug /
## unplug. Visual is a Line2D that arcs between two Jack instances; each
## Jack handles its own idle/socketed sprite swap and exposes a
## Connection Marker2D as the cable's attach point.
##
## Lifecycle, driven by the CallDirector's RINGING / ANSWERED / AWAITING_ROUTING
## phases:
##   - At RINGING: both ends rest on the shelf. Clicking the ringing socket
##     "answers" — emits `answered(socket_key)`, end A snaps to that socket.
##   - During ANSWERED + AWAITING_ROUTING: end A stays plugged in the caller
##     socket. Clicking any reachable socket plugs end B and emits
##     `routed(socket_key)`. Clicking the routed socket again unplugs it.
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

## How many segments the cable curve is sampled at. Higher = smoother.
const CURVE_SUBDIVISIONS := 24
## How much the cable droops under gravity, in pixels at a 600-px-long span.
## Shorter spans droop proportionally less, longer spans more.
const SAG_PER_600PX := 180.0
## Minimum sag regardless of span — keeps an idle cable looking like a slack
## cord rather than a tight string when the two jacks rest side by side.
const MIN_SAG := 60.0

## The CallDirector flips these as it walks through the per-call phases.
## Sockets ignore clicks when both are false — so between calls (and during
## the caller's opening) nothing is pluggable.
var accepting_answer: bool = false
var accepting_routing: bool = false

var _jack_a: Jack
var _jack_b: Jack

var _socket_a: Socket = null
var _socket_b: Socket = null

func _ready() -> void:
	_jack_a = get_node_or_null("JackA")
	_jack_b = get_node_or_null("JackB")

	clear_points()
	# Reserve the points for the curve subdivisions; they'll be repositioned
	# by _apply_endpoints. We only need to allocate once.
	for i in CURVE_SUBDIVISIONS + 1:
		add_point(Vector2.ZERO)
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
	var p0 := _place_jack(_jack_a, _endpoint_for(_socket_a, _rest_position_a()), _socket_a)
	var p1 := _place_jack(_jack_b, _endpoint_for(_socket_b, _rest_position_b()), _socket_b)
	# Quadratic Bezier control point: midpoint pulled DOWN under gravity.
	# Sag scales with the horizontal span so short spans droop a little,
	# long spans droop a lot.
	var mid := (p0 + p1) * 0.5
	var span := p0.distance_to(p1)
	var sag := maxf(MIN_SAG, SAG_PER_600PX * (span / 600.0))
	var ctrl := mid + Vector2(0, sag)
	for i in CURVE_SUBDIVISIONS + 1:
		var t := float(i) / float(CURVE_SUBDIVISIONS)
		var omt := 1.0 - t
		var pt := omt * omt * p0 + 2.0 * omt * t * ctrl + t * t * p1
		set_point_position(i, pt)

## Swap the jack's visual to match the plug state, ask it to align its
## active anchor with `anchor`, then return the actual cable attach point.
## For the idle pose the cable end coincides with `anchor`; for the
## socketed pose the cable attaches slightly below the socket hole,
## wherever the Jack's `Connection` marker lands.
func _place_jack(jack: Jack, anchor: Vector2, plugged_socket: Socket) -> Vector2:
	if jack == null:
		return anchor
	jack.set_plugged(plugged_socket != null)
	jack.place_at(anchor)
	return jack.connection_point()

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
