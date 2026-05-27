## Applies the project's custom cursor texture globally and offers an
## accessibility opt-out. Autoload as "CursorState".
##
## A single themed cursor texture is bound to both CURSOR_ARROW and
## CURSOR_POINTING_HAND, so menu buttons and actionable sockets keep
## using mouse_default_cursor_shape = CURSOR_POINTING_HAND without any
## visual surprise — they just keep the same custom cursor. Interact
## feedback comes from button styleboxes and socket scale tweens, not
## from a cursor-state swap.
##
## Players who rely on OS cursor scaling / contrast can flip
## SettingsState.use_system_cursor and the engine reverts to the
## platform default.
extends Node

const DEFAULT_PATH := "res://art/cursors/cursor.png"
## Hotspot in cursor.png coordinates — the pixel the OS treats as the
## actual click point. Tuned for the brass tip position in the 64x64
## cursor: roughly 30% from the left, 6% from the top.
##
## cursor.png is shipped pre-resized to 64x64 on disk so we can hand
## the loaded Texture2D straight to Input.set_custom_mouse_cursor
## without an intermediate Image / ImageTexture roundtrip — matches
## the official Godot custom-cursor pattern. Re-author the PNG (or
## update its on-disk dimensions) if a different on-screen size is
## ever wanted.
const HOTSPOT := Vector2(20, 5)

var _cursor_tex: Texture2D

func _ready() -> void:
	if ResourceLoader.exists(DEFAULT_PATH):
		_cursor_tex = load(DEFAULT_PATH)
	if SettingsState:
		SettingsState.use_system_cursor_changed.connect(_on_use_system_cursor_changed)
	_apply()

func _on_use_system_cursor_changed(_value: bool) -> void:
	_apply()

func _apply() -> void:
	if _cursor_tex == null or (SettingsState and SettingsState.use_system_cursor):
		# Fall back to the OS cursor when the texture is missing or the
		# accessibility opt-out is on. Pass null to clear each shape we
		# might previously have overridden.
		Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
		Input.set_custom_mouse_cursor(null, Input.CURSOR_POINTING_HAND)
		return
	# Same texture for both shapes — the pointing-hand variant on hover
	# is reserved as a visual signal of intent only, not as a separate
	# cursor state.
	Input.set_custom_mouse_cursor(_cursor_tex, Input.CURSOR_ARROW, HOTSPOT)
	Input.set_custom_mouse_cursor(_cursor_tex, Input.CURSOR_POINTING_HAND, HOTSPOT)
