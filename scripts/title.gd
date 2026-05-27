## Title screen. Two-button main menu: Start Call (begins a fresh run),
## Settings (opens the shared settings overlay). Buttons replace the older
## "press any key" affordance so the title now has a unified look with the
## in-game pause menu.
extends Control

const SWITCHBOARD := "res://scenes/switchboard.tscn"

@onready var _main_menu: Control = $MainMenu
@onready var _start_button: Button = $MainMenu/VBox/StartButton
@onready var _settings_button: Button = $MainMenu/VBox/SettingsButton
@onready var _settings_overlay: Control = $SettingsOverlay

var _starting := false

func _ready() -> void:
	# In case we come back here from an ending, scrub the run state.
	if GameState:
		GameState.reset()
	# We may have been loaded by a SceneTransition fade-out — make sure
	# the overlay fades back in.
	if SceneTransition:
		SceneTransition.fade_in()
	# Start the two-layer score from the very first frame the player sees.
	# AudioManager is an autoload so both tracks keep playing through every
	# subsequent scene change until an ending stops them.
	if AudioManager:
		AudioManager.play_music_bed()
	_start_button.pressed.connect(_start)
	_settings_button.pressed.connect(_settings_overlay.open)
	_settings_overlay.opened.connect(_on_settings_opened)
	_settings_overlay.closed.connect(_on_settings_closed)
	_start_button.grab_focus()

func _on_settings_opened() -> void:
	_main_menu.visible = false

func _on_settings_closed() -> void:
	_main_menu.visible = true
	_start_button.grab_focus()

func _start() -> void:
	if _starting:
		return
	_starting = true
	SceneTransition.change_scene(SWITCHBOARD)
