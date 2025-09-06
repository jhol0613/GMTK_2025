extends Control

@onready var pause       : Control      = $pause_menu
@onready var bg          : TextureRect  = $pause_menu/pause_menu_bg
@onready var confirm     : Control      = $pause_menu/quit_confirm
@onready var confirm_bg  : TextureRect  = $pause_menu/quit_confirm/confirm_menu_bg
@onready var shade       : ColorRect    = $shade
@onready var pause_btn_hover_emitter = $pause_btn_hover
@onready var pause_btn_click_emitter = $pause_btn_click

const T_PAUSE        := preload("res://menus/pause_menu/pausemenu_visuals/pause.png")
const T_RESUME_HI    := preload("res://menus/pause_menu/pausemenu_visuals/pauseresume.png")
const T_OPTIONS_HI   := preload("res://menus/pause_menu/pausemenu_visuals/pauseoptions.png")
const T_EXIT_HI      := preload("res://menus/pause_menu/pausemenu_visuals/pausexit.png")

const T_YESNO        := preload("res://menus/pause_menu/pausemenu_visuals/yesno.png")
const T_YES_HI       := preload("res://menus/pause_menu/pausemenu_visuals/yes.png")
const T_NO_HI        := preload("res://menus/pause_menu/pausemenu_visuals/no.png")

var _is_open := false

func _ready() -> void:
	visible = true
	pause.visible = true
	confirm.visible = false
	shade.visible = false
  
	#$pause_menu/resume_btn.mouse_entered.connect(_on_resume_btn_mouse_entered)
	#$pause_menu/options_btn.mouse_entered.connect(_on_options_btn_mouse_entered)
	#$pause_menu/quit_btn.mouse_entered.connect(_on_quit_btn_mouse_entered)
#
	#$pause_menu/resume_btn.mouse_exited.connect(_on_main_exit_hover_clear)
	#$pause_menu/options_btn.mouse_exited.connect(_on_main_exit_hover_clear)
	#$pause_menu/quit_btn.mouse_exited.connect(_on_main_exit_hover_clear)
#
	#$pause_menu/resume_btn.pressed.connect(_on_resume_btn_pressed)
	#$pause_menu/options_btn.pressed.connect(_on_options_btn_pressed)
	#$pause_menu/quit_btn.pressed.connect(_on_quit_btn_pressed)

	$pause_menu/quit_confirm/quit_yes.mouse_entered.connect(func(): pause_btn_hover_emitter.play(); confirm_bg.texture = T_YES_HI)
	$pause_menu/quit_confirm/quit_no.mouse_entered.connect(func(): pause_btn_hover_emitter.play(); confirm_bg.texture = T_NO_HI)
	$pause_menu/quit_confirm/quit_yes.mouse_exited.connect(func(): confirm_bg.texture = T_YESNO)
	$pause_menu/quit_confirm/quit_no.mouse_exited.connect(func(): confirm_bg.texture = T_YESNO)

	#$pause_menu/quit_confirm/quit_yes.pressed.connect(_on_quit_yes_pressed)
	#$pause_menu/quit_confirm/quit_no.pressed.connect(_on_quit_no_pressed)

func toggle_pause() -> void:
	_is_open = !_is_open
	get_tree().paused = _is_open
	visible = _is_open
	pause.visible = _is_open
	shade.visible = _is_open
	confirm.visible = false
	if _is_open:
		bg.texture = T_PAUSE
	else:
		bg.texture = T_PAUSE
		
#func _unhandled_input(event: InputEvent) -> void:
	#if event.is_action_pressed("escape"):
		#toggle_pause()
		#get_viewport().set_input_as_handled()
		
func _on_resume_btn_mouse_entered() -> void:
	pause_btn_hover_emitter.play()
	if not confirm.visible:
		bg.texture = T_RESUME_HI


func _on_options_btn_mouse_entered() -> void:
	pause_btn_hover_emitter.play()
	if not confirm.visible:
		bg.texture = T_OPTIONS_HI


func _on_quit_btn_mouse_entered() -> void:
	pause_btn_hover_emitter.play()
	if not confirm.visible:
		bg.texture = T_EXIT_HI

func _on_main_exit_hover_clear() -> void:
	if not confirm.visible:
		bg.texture = T_PAUSE

func _on_resume_btn_pressed() -> void:
	pause_btn_click_emitter.play()
	GameManager.unpause_game()


func _on_options_btn_pressed() -> void:
	pause_btn_click_emitter.play()
	bg.texture = T_PAUSE
	get_tree().change_scene_to_file("res://level_system/level_selection_menu/primary_level_selection_menu.tscn")
	GameManager.unpause_game()

func _on_quit_btn_pressed() -> void:
	pause_btn_click_emitter.play()
	confirm.visible = true
	confirm_bg.texture = T_YESNO


func _on_quit_yes_pressed() -> void:
	pause_btn_click_emitter.play()
	get_tree().quit()


func _on_quit_no_pressed() -> void:
	pause_btn_click_emitter.play()
	confirm.visible = false
	bg.texture = T_PAUSE
