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

enum Direction {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

## FMOD event runs in quad time. TimeMultiplier is "FMOD bars per sequencer step"
enum TimeMultiplier {
	## 8
	HALF = 8,
	## 4
	SINGLE = 4,
	## 2
	DOUBLE = 2,
	## 1
	QUADRUPLE = 1
}

enum MusicMode {
	MENU,
	THINKING,
	RUNNING
}

enum CollisionLayer {
	PLAYER = 1,
	TRIGGERS = 2,
	ENEMIES = 4,
}

enum Scenes {
	TITLE,
	INTRO_CUTSCENE,
	LEVEL_MANAGER,
	PAUSE
}

enum TransitionStyle {
	NONE,
	FADEINOUT
}

enum CollectibleType {
	## Collectibles that only persist in the level where they're collected
	IN_LEVEL,
	## Collectibles that should be noted in the save-game file
	SAVED
}

enum SaveDataItem {
	COLLECTIBLES_ACQUIRED,
	FARTHEST_LEVEL_REACHED
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
