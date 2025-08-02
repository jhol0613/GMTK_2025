extends Node

enum PlayerAction {
	NONE,
	UP,
	DOWN,
	LEFT, 
	RIGHT,
	JUMP,
	DUCK,
	HIDE,
	LEFT_BONK,
	RIGHT_BONK,
	UP_BONK,
	DOWN_BONK
}

enum MusicMode {
	MENU,
	THINKING,
	RUNNING
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

func vector_to_player_action(vector: Vector2i) -> PlayerAction:
	match vector:
		Vector2i.UP:
			return PlayerAction.UP
		Vector2i.DOWN:
			return PlayerAction.DOWN
		Vector2i.LEFT:
			return PlayerAction.LEFT
		Vector2i.RIGHT:
			return PlayerAction.RIGHT
		_:
			return PlayerAction.NONE
