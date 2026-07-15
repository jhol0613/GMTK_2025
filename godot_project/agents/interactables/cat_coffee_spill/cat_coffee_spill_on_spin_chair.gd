extends CatCoffeeSpill


##This class is an abomination. It only exists to override and remove a single line from agent.reset()
func reset() -> void:
	#grid_position = grid_origin
	#position = _grid_to_local(grid_position)
	if default_animation != "":
		sprite.play_with_signals(default_animation)
	_reset_timer(_action_timer)
	_reset_timer(_sound_timer)
	_reset_timer(_animation_timer)
	if currently_playing_emitter:
		currently_playing_emitter.stop()

	_interacted = false
	for highlight_sprite in highlight_sprites:
		highlight_sprite.visible = can_interact()
	sprite.play_with_signals(default_animation)
	#updated_position.emit(self, self.global_position)
