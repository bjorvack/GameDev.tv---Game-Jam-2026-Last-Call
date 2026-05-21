## A single scripted phone call.
##
## Lifecycle the director walks through:
##   1. RINGING — `caller_socket` lamp pulses. Player plugs one cable end into
##      it to answer.
##   2. `opening` plays — the caller speaks their request.
##   3. AWAITING_ROUTING — player plugs the other end into a destination.
##      - Correct → `connected_dialogue` plays → next call.
##      - Wrong → `wrong_responses[socket]` (or `generic_wrong_response`) plays.
##        Caller stays on the line, patience decrements. Player can retry.
##   4. If `time_limit > 0` a countdown runs while AWAITING_ROUTING.
##      On expiry, `timer_expired` plays, patience drops, call ends.
##
## Pivotal calls short-circuit retry: any mis-route or timer expiry triggers
## the bad ending instantly.
class_name CallData
extends Resource

## Display name of the caller, shown above the dialogue text.
@export var caller_name: String = ""

## Default portrait for the caller. Individual DialogueLines may override.
@export var caller_portrait: Texture2D

## Lines spoken by the caller when the call comes in.
@export var opening: Array[DialogueLine] = []

## Socket_key of the line the call is coming in on. Lamp pulses during
## RINGING. The player must plug the first cable end here to answer.
@export var caller_socket: StringName = &""

## Socket_key of the recipient the caller is trying to reach.
@export var correct_socket: StringName = &""

## Dialogue played after a correct routing — the recipient picks up and a
## short exchange happens.
@export var connected_dialogue: Array[DialogueLine] = []

## Bespoke wrong-routing exchanges, keyed by socket_key. When the player
## plugs a wrong socket and there's a matching entry here, these lines play
## instead of `generic_wrong_response`.
##
## Dictionary contract: StringName -> Array[DialogueLine].
@export var wrong_responses: Dictionary = {}

## Fallback played when the player plugs a wrong socket that has no entry
## in `wrong_responses`.
@export var generic_wrong_response: Array[DialogueLine] = []

## Seconds the player has to route correctly. 0 = no timer.
@export var time_limit: float = 0.0

## Lines played when the timer runs out before correct routing.
@export var timer_expired: Array[DialogueLine] = []

## Which sockets are lit during this call (empty = the six default townspeople).
@export var sockets_lit: Array[StringName] = []

## If true, a wrong routing or timer expiry triggers the bad ending instead
## of just consuming a patience token.
@export var pivotal: bool = false
