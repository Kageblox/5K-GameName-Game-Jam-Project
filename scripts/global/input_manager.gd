class_name InputManagerGlobal
extends Node
## Global script that manages Player Inputs.

## Whether the Player's Inputs have been disabled.
@export var inputs_disabled: bool = false

var _timer: Timer = null

func _enter_tree() -> void:
	# Creates, configures, and adds a new timer under this node.
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.autostart = false
	_timer.ignore_time_scale = true
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)
	
func _ready() -> void:
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	
	MenuManager.on_any_menu_opened_start.connect(clear_focus)
	MenuManager.on_any_menu_opened_end.connect(grab_current_focus)
	MenuManager.on_any_menu_closed_start.connect(clear_focus)
	MenuManager.on_any_menu_closed_end.connect(grab_current_focus)
	
	grab_current_focus()

func _input(event):
	if event.is_action_pressed("ui_cancel") and not inputs_disabled:
		var foremost_menu = MenuManager.get_foremost_menu()
		if foremost_menu != null:
			if foremost_menu.background_click_closes_menu:
				foremost_menu.close()
		elif SceneManager.current_scene.pausable:
			MenuManager.open_pause_menu()

## Disables the Player's Inputs for a certain duration.[br]
## If the Player's Inputs are already disabled, adds to the duration if it's longer than the time left.
func disable_inputs(duration: float) -> void:
	get_viewport().gui_release_focus()
	if duration >  _timer.time_left:
		inputs_disabled = true
		_timer.start(duration)

func _on_timer_timeout() -> void:
	inputs_disabled = false

func _on_joy_connection_changed(_device_id: int, connected: bool):
	if connected:
		grab_current_focus()
	else:
		clear_focus()

func clear_focus() -> void:
	get_viewport().gui_release_focus()

func grab_current_focus() -> void:
	if Input.get_connected_joypads().size() > 0:
		if MenuManager.foremost_menu_index < 0:
			SceneManager.current_scene.focus_control.grab_focus()
		else:
			MenuManager.get_foremost_menu().focus_control.grab_focus()
			
