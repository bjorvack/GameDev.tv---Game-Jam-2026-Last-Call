## Displays the post-connect dialogue lines for a successful call, then hides.
## Emits `finished` when all lines have played.
class_name PostConnectBox
extends PanelContainer

signal finished

@export var line_duration: float = 2.5

@onready var label: Label = $Text

func _ready() -> void:
	hide()

func play(lines: Array[String]) -> void:
	show()
	for line in lines:
		label.text = line
		await get_tree().create_timer(line_duration).timeout
	hide()
	finished.emit()
