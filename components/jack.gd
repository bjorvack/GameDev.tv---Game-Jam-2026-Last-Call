## A single patch-cord jack. Owns two sprites — `Idle` (in-hand, tip up)
## and `Socketed` (viewed from behind) — plus two Marker2D children that
## describe its layout:
##
##   - `Connection`  (child of Jack)         — where the cable attaches.
##   - `Socketed/Center` (child of Socketed) — where the bakelite-back
##     centre lands; this point should align with the socket hole when
##     plugged.
##
## Cable usage:
##   `set_plugged(true/false)` toggles the visible sprite.
##   `place_at(anchor)`         positions the jack so that the correct
##                              marker for the current state lands at
##                              `anchor` (Connection when idle, Center
##                              when socketed).
##   `connection_point()`       returns the cable attach point in the
##                              parent's local frame.
class_name Jack
extends Node2D

@onready var _idle: Sprite2D = $Idle
@onready var _socketed: Sprite2D = $Socketed
@onready var _connection: Marker2D = $Connection

var _plugged: bool = false

func _ready() -> void:
	set_plugged(false)

func set_plugged(plugged: bool) -> void:
	if not is_node_ready():
		await ready
	_plugged = plugged
	_idle.visible = not plugged
	_socketed.visible = plugged

## Move the jack so the *active* anchor for the current state lands at
## `anchor`. For the socketed pose that's the `Socketed/Center` marker
## (so the bakelite covers the socket hole); for the idle pose it's the
## `Connection` marker (the cable-entry point at the brass tip).
func place_at(anchor: Vector2) -> void:
	if not is_node_ready():
		await ready
	position = anchor - _active_marker_offset()

## Returns the cable attach point in this jack's parent local frame.
func connection_point() -> Vector2:
	if not is_node_ready():
		return position
	return position + _connection.position

# Offset, in this jack's local frame, of the marker currently being used
# as the alignment anchor.
func _active_marker_offset() -> Vector2:
	if _plugged:
		var center := _socketed.get_node_or_null("Center") as Marker2D
		if center:
			# Center is a child of Socketed, so combine Socketed's
			# transform with the marker's local position.
			return _socketed.position + _socketed.transform.basis_xform(center.position)
	return _connection.position
