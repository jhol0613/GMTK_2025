extends Resource

class_name MovableActionData

## Should be normalized with domain (time) from 0.0 to 1.0, and range representing starting to ending
## position (0.0 is old grid space, 1.0 is new grid space)
@export var direct_movement_curve: Curve
## The y value the movable should add to their movement as they move to another tile (to add a 
## "jumping" component instead of just linear motion). Should end on 0.0 to return to original altitude
@export var y_movement_curve: Curve
@export var y_movement_magnitude := 16.0
## Amount of time for movement animation
@export var move_duration := .3
## Time to offset the initiation of this curve from the defining beat of the action (e.g. a jump might
## start by moving player lower befor the beat so the beat lines up with leaving the ground)
@export var timing_offset := 0.0
