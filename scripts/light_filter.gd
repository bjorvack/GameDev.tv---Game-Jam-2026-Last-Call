## A circular dimmer drawn on top of the socket lamp halo. Reduces the
## apparent brightness of the Light2D glow underneath by painting a soft-
## edged dark disc above it.
##
## Two radii control the shape:
##   inner_radius — solid "fully dimmed" plateau in the centre.
##   outer_radius — where the dim fades to fully transparent.
## The ring between the two is a smooth alpha gradient, so the filter
## blends into the surrounding panel instead of cutting a hard circle.
##
## Runs as a @tool so the disc renders live in the editor while you
## position the node. Toggle `show_dev_guides` to also draw the origin
## crosshair, the inner/outer radii rings, and the four cardinal radial
## ticks — same overlay style as RingGlyph for consistency. None of the
## guide overlays ship in the running game unless `show_guides_at_runtime`
## is explicitly enabled.
@tool
class_name LightFilter
extends Node2D

## Radius (px) of the solid "fully dimmed" centre. Inside this, every
## pixel uses `dim_color`'s full alpha.
@export var inner_radius: float = 8.0:
	set(value):
		inner_radius = max(0.0, value)
		queue_redraw()

## Radius (px) at which the dim fades to fully transparent. Between
## `inner_radius` and `outer_radius` the alpha lerps from full to zero.
@export var outer_radius: float = 28.0:
	set(value):
		outer_radius = max(inner_radius, value)
		queue_redraw()

## Tint and peak alpha of the filter. Default is near-black with ~55 %
## alpha — enough to noticeably dim the lamp without killing it. Drop the
## alpha for a subtler effect, or shift the RGB warm/cool to colour-grade
## the lit area.
@export var dim_color: Color = Color(0.0, 0.0, 0.0, 0.55):
	set(value):
		dim_color = value
		queue_redraw()

## Number of angular segments in the falloff ring. 24 is smooth enough
## for a small on-screen disc; bump it up for very large filters.
@export_range(6, 96, 1) var segments: int = 24:
	set(value):
		segments = max(6, value)
		queue_redraw()

@export_group("Dev Guides")
## Draw editor-only overlays showing the origin crosshair plus the inner
## (fully-dim plateau) and outer (fade-to-transparent) radii. Has no
## effect at runtime unless `show_guides_at_runtime` is also enabled.
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

## Colour used for the origin crosshair + outer ring (the "edge" of the
## filter where it fades to nothing).
@export var guide_color: Color = Color(0.25, 0.95, 1.0, 0.85)

## Colour used for the inner ring (the plateau where the dim is at full
## strength).
@export var guide_color_inner: Color = Color(1.0, 0.45, 0.85, 0.85)

func _draw() -> void:
	_draw_filter()
	if show_dev_guides and (Engine.is_editor_hint() or show_guides_at_runtime):
		_draw_guides()

func _draw_filter() -> void:
	if outer_radius <= 0.0 or dim_color.a <= 0.0:
		return
	# Solid inner plateau — everything inside inner_radius is fully dimmed.
	if inner_radius > 0.0:
		draw_circle(Vector2.ZERO, inner_radius, dim_color)
	# Falloff ring — a triangle strip from inner_radius (full alpha) to
	# outer_radius (zero alpha) around the full 360°. Per-vertex colours
	# give a real radial gradient instead of stacked discs that would
	# double-blend incorrectly.
	if outer_radius <= inner_radius:
		return
	var transparent := Color(dim_color.r, dim_color.g, dim_color.b, 0.0)
	var verts := PackedVector2Array()
	var cols := PackedColorArray()
	for i in segments:
		var a0: float = TAU * float(i) / float(segments)
		var a1: float = TAU * float(i + 1) / float(segments)
		var d0 := Vector2(cos(a0), sin(a0))
		var d1 := Vector2(cos(a1), sin(a1))
		var p_in_0: Vector2 = d0 * inner_radius
		var p_in_1: Vector2 = d1 * inner_radius
		var p_out_0: Vector2 = d0 * outer_radius
		var p_out_1: Vector2 = d1 * outer_radius
		# Two triangles per segment to form a quad of the annulus.
		verts.append(p_in_0); cols.append(dim_color)
		verts.append(p_out_0); cols.append(transparent)
		verts.append(p_out_1); cols.append(transparent)

		verts.append(p_in_0); cols.append(dim_color)
		verts.append(p_out_1); cols.append(transparent)
		verts.append(p_in_1); cols.append(dim_color)
	draw_polygon(verts, cols)

## Draws positioning aids: origin crosshair + inner/outer radii rings +
## cardinal radial ticks. Mirrors the geometry _draw_filter() uses, so
## what you see here is exactly the envelope of the filter underneath.
func _draw_guides() -> void:
	# Origin crosshair — marks the node's position (typically the socket
	# lamp centre).
	var cross := 5.0
	draw_line(Vector2(-cross, 0), Vector2(cross, 0), guide_color, 1.0, true)
	draw_line(Vector2(0, -cross), Vector2(0, cross), guide_color, 1.0, true)

	# Inner radius — the fully-dimmed plateau edge.
	if inner_radius > 0.0:
		draw_arc(Vector2.ZERO, inner_radius, 0.0, TAU, 48, guide_color_inner, 1.0, true)

	# Outer radius — where the dim fades to nothing.
	draw_arc(Vector2.ZERO, outer_radius, 0.0, TAU, 48, guide_color, 1.0, true)

	# Cardinal ticks — short radial lines from inner to outer at 0°, 90°,
	# 180°, 270° so you can quickly eyeball the falloff band's width.
	var tick_color := Color(guide_color.r, guide_color.g, guide_color.b, 0.55)
	for a in [0.0, PI * 0.5, PI, PI * 1.5]:
		var dir := Vector2(cos(a), sin(a))
		draw_line(dir * inner_radius, dir * outer_radius, tick_color, 1.0, true)
