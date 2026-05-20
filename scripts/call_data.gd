## Pure data for one scripted call.
## Calls are designed in the editor as .tres resources and loaded by CallDirector.
class_name CallData
extends Resource

@export var caller_name: String = ""
@export_multiline var request_text: String = ""

## Key of the socket that completes this call correctly (e.g. "hayes", "doc", "i40", "hospital").
@export var correct_socket: StringName = &""

## Lines played after a correct connection. One per line, shown sequentially.
@export var post_connect_lines: Array[String] = []

## Optional portrait shown next to the caller text. Path relative to res://.
@export var caller_portrait: Texture2D

## Sockets that should become *available* (lit) when this call starts.
## Empty array means "use the default 6". Used to reveal I-40 and Hospital late.
@export var sockets_lit: Array[StringName] = []

## If true, mis-routing this call instantly triggers the bad ending
## (independent of patience tokens). Used for call 9.
@export var pivotal: bool = false
