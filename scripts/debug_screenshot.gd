## Debug helper. Captures the viewport to user://debug_screenshot.png
## - automatically once, ~1s after the game starts
## - whenever F12 is pressed
## Used so an external agent (MCP / shell) can read the file and inspect the
## current visual state without needing macOS Screen Recording permission.
extends Node

const SCREENSHOT_PATH := "user://debug_screenshot.png"

func _ready() -> void:
	var delay := 1.0
	# Override via OS env so the shoot_screenshots.sh tool can wait long
	# enough for scene fade-ins and the first ringing socket to appear.
	var env_delay := OS.get_environment("SCREENSHOT_DELAY")
	if env_delay != "":
		delay = float(env_delay)
	get_tree().create_timer(delay).timeout.connect(_capture)

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
