## Per-call urgency timer. Visible only when a CallData specifies time_limit > 0.
## Renders as a small brass clock face on the switchboard panel — the brass
## bezel is a textured prop, with a code-drawn red pie wedge filling the dial
## and shrinking counter-clockwise toward 12 as time runs out. Emits
## `expired` when the wedge disappears.
class_name CallTimer
extends Control

signal expired

const FACE_BG := Color(0.06, 0.16, 0.20, 1.0)
const WEDGE_COLOR := Color(0.76, 0.29, 0.29, 1.0)
const WEDGE_TIP := Color(0.91, 0.72, 0.42, 1.0)
## Fraction of the Control's width that the dial face fills, measured from
## the centre. The brass texture's inner-collar radius lands at this point;
## we draw the wedge to match so it doesn't bleed under the bezel.
const FACE_RADIUS_RATIO := 0.27
## Number of polygon segments per wedge slice — higher is smoother.
const WEDGE_SEGMENTS := 24

@export var bezel_texture: Texture2D = preload("res://art/props/timer_face.png")

var _remaining: float = 0.0
var _total: float = 0.0
var _running: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(128, 128)
	hide()
	set_process(false)

func start(seconds: float) -> void:
	_total = seconds
	_remaining = seconds
	_running = true
	show()
	set_process(true)
	queue_redraw()

func stop() -> void:
	_running = false
	set_process(false)
	hide()

func _process(delta: float) -> void:
	if not _running:
		return
	_remaining = maxf(0.0, _remaining - delta)
	queue_redraw()
	if _remaining <= 0.0:
		_running = false
		set_process(false)
		expired.emit()

func _draw() -> void:
	var center := size * 0.5
	var face_radius: float = minf(size.x, size.y) * FACE_RADIUS_RATIO
	# Dark dial face inside the brass collar.
	draw_circle(center, face_radius, FACE_BG)
	# Red wedge — full at start, shrinks counter-clockwise. Drawn before the
	# bezel so its outer edge tucks neatly under the brass ring.
	if _total > 0.0 and _remaining > 0.0:
		var fraction: float = clampf(_remaining / _total, 0.0, 1.0)
		var start_angle := -PI * 0.5  # 12 o'clock
		var end_angle: float = start_angle + TAU * fraction
		# Slice into thin sub-wedges to keep each polygon strictly convex
		# (Godot's filled-polygon renderer mis-tessellates concave shapes).
		var sub_step := PI * 0.25
		var a := start_angle
		while a < end_angle:
			var b: float = minf(a + sub_step, end_angle)
			_draw_wedge(center, face_radius, a, b)
			a = b
		# Subtle amber sweep-hand on the trailing edge.
		var tip_angle: float = end_angle
		draw_line(
			center,
			center + Vector2(cos(tip_angle), sin(tip_angle)) * face_radius,
			WEDGE_TIP,
			1.5,
			true,
		)
	# Brass bezel on top, framing the wedge.
	if bezel_texture:
		draw_texture_rect(bezel_texture, Rect2(Vector2.ZERO, size), false)

func _draw_wedge(center: Vector2, radius: float, a0: float, a1: float) -> void:
	if is_equal_approx(a0, a1):
		return
	var points := PackedVector2Array()
	points.append(center)
	for i in WEDGE_SEGMENTS + 1:
		var t: float = float(i) / float(WEDGE_SEGMENTS)
		var angle: float = lerp(a0, a1, t)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, WEDGE_COLOR)
