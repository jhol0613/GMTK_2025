extends FmodEventEmitter2D


## FMOD emitter with a data field for a specified time offset.
class_name FmodEventEmitter2DOffset

## (This offset should be the difference between the audio start time and the 
## defining beat for the action to which it's associated)
@export var offset_seconds: float = 0.0
