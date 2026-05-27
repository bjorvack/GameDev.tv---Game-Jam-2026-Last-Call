## Title screen menu.
##
## When a checkpoint exists (player completed at least one call in a prior
## session), the menu is Continue + New Game + Settings, with Continue
## taking focus. Otherwise it's a single Start Call + Settings layout.
##
## Continue resumes from the saved call index with full patience.
## New Game / Start Call both clear the checkpoint and start at call 0.
extends Control

const SWITCHBOARD := "res://scenes/switchboard.tscn"

@onready var _main_menu: Control = $MainMenu
@onready var _continue_button: Button = $MainMenu/VBox/ContinueButton
@onready var _start_button: Button = $MainMenu/VBox/StartButton
@onready var _settings_button: Button = $MainMenu/VBox/SettingsButton
@onready var _settings_overlay: Control = $SettingsOverlay

var _starting := false

func _ready() -> void:
	# In case we come back here from an ending, scrub the runtime state.
	# This does NOT clear the persisted checkpoint, so the Continue button
	# still surfaces after a bad ending.
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
	_continue_button.pressed.connect(_continue)
	_start_button.pressed.connect(_start_new_game)
	_settings_button.pressed.connect(_settings_overlay.open)
	_settings_overlay.opened.connect(_on_settings_opened)
	_settings_overlay.closed.connect(_on_settings_closed)
	_refresh_continue_visibility()

func _refresh_continue_visibility() -> void:
	var has_save := GameState != null and GameState.has_checkpoint()
	_continue_button.visible = has_save
	# Relabel the secondary start button so it's unambiguous when paired
	# with Continue — "New Game" wipes progress on click, "Start Call"
	# is the only entry on a fresh install.
	_start_button.text = "New Game" if has_save else "Start Call"
	if has_save:
		_continue_button.grab_focus()
	else:
		_start_button.grab_focus()

func _on_settings_opened() -> void:
	_main_menu.visible = false

func _on_settings_closed() -> void:
	_main_menu.visible = true
	# Toggling the manual-dialogue setting can't change the checkpoint,
	# but recompute anyway so focus is correct when returning.
	_refresh_continue_visibility()

func _continue() -> void:
	if _starting:
		return
	_starting = true
	# Seed the runtime state so the CallDirector picks up where we left
	# off. Patience is always full on resume.
	GameState.patience = GameState.MAX_PATIENCE
	GameState.current_call_index = GameState.checkpoint_call_index()
	SceneTransition.change_scene(SWITCHBOARD)

func _start_new_game() -> void:
	if _starting:
		return
	_starting = true
	GameState.clear_checkpoint()
	GameState.reset()
	SceneTransition.change_scene(SWITCHBOARD)
