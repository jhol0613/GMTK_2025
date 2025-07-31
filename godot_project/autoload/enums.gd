extends Node

enum PlayerAction {
	NONE,
	UP,
	DOWN,
	LEFT, 
	RIGHT,
	JUMP,
	DUCK,
	HIDE
}

func player_action_to_vector(action: PlayerAction) -> Vector2i:
	match action:
		PlayerAction.UP:
			return Vector2i.UP
		PlayerAction.DOWN:
			return Vector2i.DOWN
		PlayerAction.LEFT:
			return Vector2i.LEFT
		PlayerAction.RIGHT:
			return Vector2i.RIGHT
		_:
			return Vector2i.ZERO
