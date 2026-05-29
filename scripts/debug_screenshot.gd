## Debug helper. Captures the viewport to user://debug_screenshot.png
## - automatically once, ~1s after the game starts
## - whenever F12 is pressed
## Used so an external agent (MCP / shell) can read the file and inspect the
## current visual state without needing macOS Screen Recording permission.
extends Node

const SCREENSHOT_PATH := "user://debug_screenshot.png"

func _ready() -> void:
	# Keep the screenshot autoload running through paused trees — opening
	# the in-game pause overlay calls get_tree().paused = true, which would
	# otherwise freeze our own process_frame waits and the eventual capture.
	process_mode = Node.PROCESS_MODE_ALWAYS
	var delay := 1.0
	# Override via OS env so the shoot_screenshots.sh tool can wait long
	# enough for scene fade-ins and the first ringing socket to appear.
	var env_delay := OS.get_environment("SCREENSHOT_DELAY")
	if env_delay != "":
		delay = float(env_delay)
	get_tree().create_timer(delay).timeout.connect(_prepare_and_capture)

## Optional hooks for the shoot_screenshots.sh tool: open in-game overlays
## (pause menu, settings panel) before the screenshot fires so we can
## document UI surfaces that are normally invisible.
func _prepare_and_capture() -> void:
	if OS.get_environment("OPEN_PAUSE") == "1":
		_call_first_node_with_method("open", ["PauseOverlay"])
		await get_tree().process_frame
	if OS.get_environment("OPEN_SETTINGS") == "1":
		# Wait one frame after opening pause (if requested) so the nested
		# settings panel resolves its layout before snapping.
		await get_tree().process_frame
		_call_first_node_with_method("open", ["SettingsOverlay"])
		await get_tree().process_frame
		# Optional SETTINGS_TAB env var lets the shoot tool snap any tab
		# (0 = Accessibility, 1 = Audio) without code edits.
		var tab_env := OS.get_environment("SETTINGS_TAB")
		if tab_env != "":
			var overlay := get_tree().root.find_child("SettingsOverlay", true, false)
			if overlay:
				var tabs := overlay.find_child("Tabs", true, false)
				if tabs and "current_tab" in tabs:
					tabs.current_tab = int(tab_env)
					await get_tree().process_frame
		# Optional SETTINGS_RESET_AUDIO=1 fires the audio reset button so
		# the captured frame shows the post-reset slider state.
		if OS.get_environment("SETTINGS_RESET_AUDIO") == "1":
			var overlay2 := get_tree().root.find_child("SettingsOverlay", true, false)
			if overlay2:
				var reset := overlay2.find_child("ResetButton", true, false)
				if reset and reset.has_signal("pressed"):
					reset.emit_signal("pressed")
					await get_tree().process_frame
	# Extra frame so the visible-flag change actually paints into the
	# viewport texture before we read it back.
	await get_tree().process_frame
	_capture()

func _call_first_node_with_method(method: String, name_hints: Array) -> void:
	for name_hint in name_hints:
		var node := get_tree().root.find_child(name_hint, true, false)
		if node and node.has_method(method):
			node.call(method)
			return

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F12:
		_capture()

func _capture() -> void:
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(SCREENSHOT_PATH)
	if err == OK:
		print("[debug] screenshot saved → ", ProjectSettings.globalize_path(SCREENSHOT_PATH))
	else:
		push_error("Failed to save screenshot: %d" % err)
