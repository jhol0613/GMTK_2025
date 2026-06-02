extends Resource

class_name TreadmillAntennaPositionData

##Define all antenna positions here
@export var position_data: Array[Vector2]
##Optionally associate positions with directions
@export var direction_to_position: Dictionary[Enums.Direction, int]
