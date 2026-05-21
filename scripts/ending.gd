## Tiny script attached to ending_good / ending_bad root.
## Fades the SceneTransition overlay back in (in case we arrived mid-fade)
## and routes any input back to the title screen so the player can replay.
extends Control

const TITLE := "res://scenes/title.tscn"

var _returning := false

func _ready() -> void:
	if SceneTransition:
		SceneTransition.fade_in()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_return_to_title()
	elif event is InputEventMouseButton and event.pressed:
		_return_to_title()

func _return_to_title() -> void:
	if _returning:
		return
	_returning = true
	if SceneTransition:
		SceneTransition.change_scene(TITLE)
	else:
		get_tree().change_scene_to_file(TITLE)
