## Draggable cable. The Line2D origin is the cable jack; the other end follows
## the mouse while the user holds the left button starting on the jack. On
## release, the nearest lit Socket whose rect contains the cursor receives a
## plug() call.
extends Line2D

@export var jack_position: Vector2 = Vector2.ZERO
@export var sockets_group: StringName = &"sockets"
@export var grab_radius: float = 48.0

var _dragging: bool = false

func _ready() -> void:
	clear_points()
	add_point(jack_position)
	add_point(jack_position)
	# Keep the Jack sprite aligned with the cable's grab point.
	var jack := get_node_or_null("Jack")
	if jack and jack is Node2D:
		jack.position = jack_position

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_global := get_global_mouse_position()
		if event.pressed:
			if mouse_global.distance_to(to_global(jack_position)) <= grab_radius:
				_dragging = true
		elif _dragging:
			_dragging = false
			_try_plug(mouse_global)
			_reset()
	elif event is InputEventMouseMotion and _dragging:
		set_point_position(1, to_local(get_global_mouse_position()))

func _try_plug(mouse_global: Vector2) -> void:
	for node in get_tree().get_nodes_in_group(sockets_group):
		if node is Socket and node.lit:
			if node.get_global_rect().has_point(mouse_global):
				node.plug()
				return

func _reset() -> void:
	set_point_position(1, jack_position)
