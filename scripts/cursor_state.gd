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
## cursor.png is shipped pre-resized to 64x64 on disk. We still rebuild
## the texture as an uncompressed ImageTexture at load time because
## the editor imports PNGs as CompressedTexture2D, and macOS's
## Input.set_custom_mouse_cursor implementation can't extract an
## NSBitmapImageRep from a GPU-compressed pixel format — it logs the
## misleading "Parameter 'imgrep' is null" and renders nothing.
const HOTSPOT := Vector2(20, 5)

var _cursor_tex: Texture2D

func _ready() -> void:
	_cursor_tex = _load_uncompressed_cursor(DEFAULT_PATH)
	if SettingsState:
		SettingsState.use_system_cursor_changed.connect(_on_use_system_cursor_changed)
	# Re-push the *custom* cursor every time the main window regains
	# focus. Working around the embedded-game-window cursor drop on
	# macOS — https://github.com/godotengine/godot/issues/110800 — but
	# only when we actually have a custom texture to push: calling
	# Input.set_custom_mouse_cursor(null) on every focus event makes
	# the platform layer log a spurious "imgrep is null" twice per
	# refresh, so the system-cursor opt-out stays a single set-and-
	# forget instead.
	var win := get_window()
	if win:
		win.focus_entered.connect(_on_focus_entered)
	_apply()

## Load cursor.png, decompress + normalise its image to RGBA8 so the
## macOS DisplayServer can extract an NSBitmapImageRep from it when
## handing the cursor to the OS. Without the FORMAT_RGBA8 convert the
## platform layer logs `Parameter "imgrep" is null` and silently
## reverts to the system cursor.
func _load_uncompressed_cursor(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var src := load(path) as Texture2D
	if src == null:
		return null
	var img := src.get_image()
	if img == null:
		return null
	if img.is_compressed():
		img.decompress()
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	return ImageTexture.create_from_image(img)

func _on_use_system_cursor_changed(_value: bool) -> void:
	_apply()

func _on_focus_entered() -> void:
	# Only re-push the custom texture; nulling on focus would re-trigger
	# the macOS imgrep-null platform error every refocus.
	if _wants_custom_cursor():
		_push_custom_cursor()

func _wants_custom_cursor() -> bool:
	return _cursor_tex != null and not (SettingsState and SettingsState.use_system_cursor)

func _push_custom_cursor() -> void:
	# Same texture for both shapes — the pointing-hand variant on hover
	# is reserved as a visual signal of intent only, not as a separate
	# cursor state.
	Input.set_custom_mouse_cursor(_cursor_tex, Input.CURSOR_ARROW, HOTSPOT)
	Input.set_custom_mouse_cursor(_cursor_tex, Input.CURSOR_POINTING_HAND, HOTSPOT)

func _apply() -> void:
	if _wants_custom_cursor():
		_push_custom_cursor()
	else:
		# Fall back to the OS cursor. We only do this once per toggle —
		# repeating it on focus events makes macOS log "imgrep is null".
		Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
		Input.set_custom_mouse_cursor(null, Input.CURSOR_POINTING_HAND)
