extends Node
enum PlayerAction {
	NONE,
	UP,
	DOWN,
	LEFT,
	RIGHT,
	JUMP,
	DUCK,
	INTERACT,
	LEFT_BONK,
	RIGHT_BONK,
	UP_BONK,
	DOWN_BONK,
	UP_FALL,
	DOWN_FALL,
	LEFT_FALL,
	RIGHT_FALL,
	UP_SLIDE,
	DOWN_SLIDE,
	LEFT_SLIDE,
	RIGHT_SLIDE,
	UP_SLIDE_BONK,
	DOWN_SLIDE_BONK,
	LEFT_SLIDE_BONK,
	RIGHT_SLIDE_BONK,
	UP_LEFT,
	UP_RIGHT,
	DOWN_RIGHT,
	DOWN_LEFT
}

enum Direction {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

enum FailureCause {
	CAUGHT,
	LASER,
	SQUISHED
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
	CONDUCTOR = 3,
	COLLECTIBLES = 4,
	PUSHERS = 5,
	JUMPABLE = 6,
	ENEMIES = 7,
	DUCKABLE = 9,
	LASER_BLOCKER = 10,
	SELF_DETECT = 11 #turn this layer on then instantly off when you need it
}

enum Scenes {
	TITLE,
	INTRO_CUTSCENE,
	LEVEL_MANAGER,
	PAUSE,
	WORLD_1_LEVEL_SELECT,
	WORLD_2_LEVEL_SELECT,
	WORLD_3_LEVEL_SELECT
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

enum PushMode {
	##If push on beat, pusher will only perform a check for overlaps on specified beat
	ON_BEAT,
	##In instant mode, a pusher will send signal the moment an overlap is detected
	INSTANT
}

enum ConductorState {
	PURSUE,
	UNAWARE,
	FOUND, # transitional, goes directly to pursue
	ANGRY, # goes here from pursue, when conductor sees the player hide
	UNREACHABLE_START, # transitional, can't reach the player
	UNREACHABLE # can't reach the player
}

#region Action and Vector conversions
var NORTHEAST = Vector2i.UP + Vector2i.RIGHT
var NORTHWEST = Vector2i.UP + Vector2i.LEFT
var SOUTHEAST = Vector2i.DOWN + Vector2i.RIGHT
var SOUTHWEST = Vector2i.DOWN + Vector2i.LEFT

func player_action_to_vector(action: PlayerAction) -> Vector2i:
	match action:
		PlayerAction.UP, PlayerAction.UP_FALL, PlayerAction.UP_SLIDE:
			return Vector2i.UP
		PlayerAction.DOWN, PlayerAction.DOWN_FALL, PlayerAction.DOWN_SLIDE:
			return Vector2i.DOWN
		PlayerAction.LEFT, PlayerAction.LEFT_FALL, PlayerAction.LEFT_SLIDE:
			return Vector2i.LEFT
		PlayerAction.RIGHT, PlayerAction.RIGHT_FALL, PlayerAction.RIGHT_SLIDE:
			return Vector2i.RIGHT
		PlayerAction.UP_LEFT:
			return NORTHWEST
		PlayerAction.UP_RIGHT:
			return NORTHEAST
		PlayerAction.DOWN_LEFT:
			return SOUTHWEST
		PlayerAction.DOWN_RIGHT:
			return SOUTHEAST
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
		NORTHEAST:
			return PlayerAction.UP_RIGHT
		NORTHWEST:
			return PlayerAction.UP_LEFT
		SOUTHEAST:
			return PlayerAction.DOWN_RIGHT
		SOUTHWEST:
			return PlayerAction.DOWN_LEFT
		_:
			return PlayerAction.NONE

func direction_to_vector(direction: Direction) -> Vector2i:
	match direction:
		Direction.UP:
			return Vector2i.UP
		Direction.DOWN:
			return Vector2i.DOWN
		Direction.LEFT:
			return Vector2i.LEFT
		Direction.RIGHT:
			return Vector2i.RIGHT
		_:
			return Vector2i.ZERO
			
func action_to_bonk(action: PlayerAction) -> PlayerAction:
	match action:
		PlayerAction.RIGHT, PlayerAction.RIGHT_BONK, PlayerAction.RIGHT_FALL:
			return PlayerAction.RIGHT_BONK
		PlayerAction.RIGHT_SLIDE, PlayerAction.RIGHT_SLIDE_BONK:
			return PlayerAction.RIGHT_SLIDE_BONK
		PlayerAction.LEFT, PlayerAction.LEFT_BONK, PlayerAction.LEFT_FALL:
			return PlayerAction.LEFT_BONK
		PlayerAction.LEFT_SLIDE, PlayerAction.LEFT_SLIDE_BONK:
			return PlayerAction.LEFT_SLIDE_BONK
		PlayerAction.UP, PlayerAction.UP_BONK, PlayerAction.UP_FALL:
			return PlayerAction.UP_BONK
		PlayerAction.UP_SLIDE, PlayerAction.UP_SLIDE_BONK:
			return PlayerAction.UP_SLIDE_BONK
		PlayerAction.DOWN, PlayerAction.DOWN_BONK, PlayerAction.DOWN_FALL:
			return PlayerAction.DOWN_BONK
		PlayerAction.DOWN_SLIDE, PlayerAction.DOWN_SLIDE_BONK:
			return PlayerAction.DOWN_SLIDE_BONK
		_:
			return action
		
func is_action_fall(action: PlayerAction) -> bool:
	return (
		action == PlayerAction.UP_FALL or
		action == PlayerAction.DOWN_FALL or
		action == PlayerAction.LEFT_FALL or
		action == PlayerAction.RIGHT_FALL
	)

func is_action_slide(action: PlayerAction) -> bool:
	return (
		action == PlayerAction.UP_SLIDE or
		action == PlayerAction.DOWN_SLIDE or
		action == PlayerAction.LEFT_SLIDE or
		action == PlayerAction.RIGHT_SLIDE
	)

func is_action_bonk(action: PlayerAction) -> bool:
	return (
		action == PlayerAction.UP_BONK or
		action == PlayerAction.DOWN_BONK or
		action == PlayerAction.LEFT_BONK or
		action == PlayerAction.RIGHT_BONK
	)

func is_action_slide_bonk(action: PlayerAction) -> bool:
	return (
		action == PlayerAction.UP_SLIDE_BONK or
		action == PlayerAction.DOWN_SLIDE_BONK or
		action == PlayerAction.LEFT_SLIDE_BONK or 
		action == PlayerAction.RIGHT_SLIDE_BONK
	)

func is_action_move(action: PlayerAction) -> bool:
	return (
		action == PlayerAction.UP or
		action == PlayerAction.DOWN or
		action == PlayerAction.LEFT or
		action == PlayerAction.RIGHT or
		action == PlayerAction.UP_RIGHT or
		action == PlayerAction.UP_LEFT or
		action == PlayerAction.DOWN_RIGHT or
		action == PlayerAction.DOWN_LEFT
	)

#Throw more interact actions in here if they end up getting subdivided
func is_action_interact(action: PlayerAction) -> bool:
	return (
		action == PlayerAction.INTERACT
	)
	
func get_reverse_action(action: PlayerAction) -> PlayerAction:
	match action:
		PlayerAction.RIGHT:
			return PlayerAction.LEFT
		PlayerAction.LEFT:
			return PlayerAction.RIGHT
		PlayerAction.UP:
			return PlayerAction.DOWN
		PlayerAction.DOWN:
			return PlayerAction.UP
		_:
			return PlayerAction.NONE

func get_reverse_fall(action: PlayerAction) -> PlayerAction:
	match action:
		PlayerAction.RIGHT_FALL:
			return PlayerAction.LEFT_FALL
		PlayerAction.LEFT_FALL:
			return PlayerAction.RIGHT_FALL
		PlayerAction.UP_FALL:
			return PlayerAction.DOWN_FALL
		PlayerAction.DOWN_FALL:
			return PlayerAction.UP_FALL
		_:
			return PlayerAction.NONE

#endregion
