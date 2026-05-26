## Procedurally drawn "ringing" indicator: two sets of concentric arcs that
## bow outward to the left and right of the origin, expanding and fading like
## sound waves radiating from a phone.
##
## Colour-blind accessibility: the ring state on a socket is otherwise
## communicated only by an amber lamp pulse, which a colour-blind player can
## struggle to distinguish from the other amber-lit (REACHABLE / PLUGGED)
## sockets. These arcs add a *shape + motion* cue that survives full
## desaturation.
##
## Sized to sit just outside the socket plate's left/right edges so the arcs
## don't overlap the bronze panel or the label card, and stay within the
## socket Control's 130 px bounds.
##
## Runs as a @tool so the arcs render live in the editor while you position
## the node. Toggle `show_dev_guides` in the inspector to also draw the
## origin crosshair, inner/outer animation radii, and arc-span wedges — none
## of that ships in the running game.
@tool
class_name RingGlyph
extends Node2D

## Number of concentric arcs drawn on each side. Two reads as a clean
## "ringing" glyph without getting busy.
@export var arc_count: int = 2

## Inner arc radius, in pixels. Should clear the socket plate edge.
@export var base_radius: float = 34.0

## Spacing between successive arcs.
@export var radius_step: float = 8.0

## Half-angle (in degrees) of each arc's opening. ~25° each side gives a
## short curved tick rather than a full ring.
@export var arc_half_span_deg: float = 25.0

## Stroke width in pixels.
@export var line_width: float = 2.0

## Arc tint. Warm cream matches the lamp glow and the label card paper.
@export var color: Color = Color(1.0, 0.88, 0.62, 0.95)

## Seconds per full radiate cycle. Matches the lamp pulse in socket.gd
## (0.55 s up + 0.55 s down) so the two cues feel like one event.
@export var period: float = 1.1

@export_group("Dev Guides")
## Draw editor-only overlays showing the origin crosshair, the inner radius
## where each arc spawns, the outer radius where it fades out, and the
## angular extent of the arc opening on each side. Has no effect at runtime
## unless `show_guides_at_runtime` is also enabled.
@export var show_dev_guides: bool = false:
	set(value):
		show_dev_guides = value
		queue_redraw()

## Force guides to draw in the running game too (e.g. for in-engine
## screenshots). Off by default so guides never ship to players.
@export var show_guides_at_runtime: bool = false:
	set(value):
		show_guides_at_runtime = value
		queue_redraw()

## Colour used for the origin crosshair + outer ring (the "end" of the
## animation envelope).
@export var guide_color: Color = Color(0.25, 0.95, 1.0, 0.85)

## Colour used for the inner ring (the "start" of the animation envelope).
@export var guide_color_inner: Color = Color(1.0, 0.45, 0.85, 0.85)

var _phase: float = 0.0
var _playing: bool = false

func _ready() -> void:
	if Engine.is_editor_hint():
		# In the editor we always show the glyph so the artist can see and
		# position it. The animation ticks via _process below.
		visible = true
		set_process(true)
		return
	visible = _playing
	set_process(_playing)

func play() -> void:
	if _playing:
		return
	_playing = true
	_phase = 0.0
	visible = true
	set_process(true)
	queue_redraw()

func stop() -> void:
	if not _playing:
		return
	_playing = false
	# In the editor we keep drawing the static preview even when "stopped"
	# so the node stays visible for positioning.
	if Engine.is_editor_hint():
		queue_redraw()
		return
	visible = false
	set_process(false)
	queue_redraw()

func _process(delta: float) -> void:
	_phase = fmod(_phase + delta / period, 1.0)
	queue_redraw()

func _draw() -> void:
	# In the editor the arcs always render (so you can see what you're
	# positioning). At runtime they only render while playing.
	var draw_arcs := _playing or Engine.is_editor_hint()
	if draw_arcs:
		_draw_arcs()
	if show_dev_guides and (Engine.is_editor_hint() or show_guides_at_runtime):
		_draw_guides()

func _draw_arcs() -> void:
	var half_span := deg_to_rad(arc_half_span_deg)
	for i in arc_count:
		# Stagger each arc's phase so they form a continuous outward wave.
		var t: float = fmod(_phase + float(i) / float(arc_count), 1.0)
		var r: float = base_radius + t * radius_step * float(arc_count)
		# Ease-out fade: fully visible at birth, gone at end of cycle.
		var alpha: float = (1.0 - t) * color.a
		var c := Color(color.r, color.g, color.b, alpha)
		# Right arc — bows outward at angle 0 (+X).
		draw_arc(Vector2.ZERO, r, -half_span, half_span, 16, c, line_width, true)
		# Left arc — bows outward at angle PI (-X).
		draw_arc(Vector2.ZERO, r, PI - half_span, PI + half_span, 16, c, line_width, true)

## Draws positioning aids: origin crosshair + inner/outer animation radii +
## arc-span wedges. Mirrors the same geometry _draw_arcs() uses, so what you
## see here is exactly the envelope the live arcs sweep through.
func _draw_guides() -> void:
	var half_span := deg_to_rad(arc_half_span_deg)
	var inner_r := base_radius
	var outer_r := base_radius + radius_step * float(arc_count)

	# Origin crosshair — marks the node's position (typically the socket
	# lamp centre). Small so it doesn't clutter; cyan to match guide_color.
	var cross := 5.0
	draw_line(Vector2(-cross, 0), Vector2(cross, 0), guide_color, 1.0, true)
	draw_line(Vector2(0, -cross), Vector2(0, cross), guide_color, 1.0, true)

	# Inner radius — where each arc spawns. Magenta full ring so it's
	# obvious which one is the "start".
	draw_arc(Vector2.ZERO, inner_r, 0.0, TAU, 48, guide_color_inner, 1.0, true)

	# Outer radius — where each arc fades to zero. Cyan full ring marks
	# the "end" of the animation envelope.
	draw_arc(Vector2.ZERO, outer_r, 0.0, TAU, 48, guide_color, 1.0, true)

	# Arc-span wedges — short radial lines from inner to outer at the four
	# endpoints (±half_span on each side). Shows the angular slot the arcs
	# actually occupy, so you can tell whether they'll clear the plate /
	# label / neighbour socket.
	var span_color := Color(guide_color.r, guide_color.g, guide_color.b, 0.55)
	for side in [-1.0, 1.0]:
		var base_angle: float = 0.0 if side > 0.0 else PI
		for sign in [-1.0, 1.0]:
			var a: float = base_angle + sign * half_span
			var dir := Vector2(cos(a), sin(a))
			draw_line(dir * inner_r, dir * outer_r, span_color, 1.0, true)
