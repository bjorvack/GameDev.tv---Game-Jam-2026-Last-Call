## UI card showing the current caller's portrait, name, and request text.
## Attach to the root of components/caller_card.tscn.
class_name CallerCard
extends PanelContainer

@onready var portrait: TextureRect = $HBoxContainer/Portrait
@onready var caller_name: Label = $HBoxContainer/VBoxContainer/CallerName
@onready var request_text: Label = $HBoxContainer/VBoxContainer/RequestText

func show_call(c: CallData) -> void:
	caller_name.text = c.caller_name
	request_text.text = c.request_text
	portrait.texture = c.caller_portrait
