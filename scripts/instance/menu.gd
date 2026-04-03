class_name MenuInstance
extends Control
## The base class for all menus.

signal on_opened_start() ## Emitted at the start of the menu's open animation.
signal on_opened_end() ## Emitted at the end of the menu's open animation.

signal on_closed_start() ## Emitted at the start of the menu's close animation.
signal on_closed_end() ## Emitted at the end of the menu's close animation.

@export var open_duration: float = 1.0
@export var close_duration: float = 1.0

## Whether clocking the background closes the menu.
@export var background_click_closes_menu: bool = false

## Whether the menu deletes itself upon being closed.
@export var queue_free_on_close: bool = true

@export var focus_control: Control

var closing = false

func _enter_tree() -> void:
	if background_click_closes_menu:
		gui_input.connect(_on_gui_event)

func open(_params: Array[Variant] = [])-> void:
	visible = true
	
	on_opened_start.emit()
	MenuManager.on_any_menu_opened_start.emit()
	
	InputManager.disable_inputs(open_duration)
	
	await get_tree().create_timer(open_duration).timeout
	
	on_opened_end.emit()
	MenuManager.on_any_menu_opened_end.emit()

func close() -> void:
	closing = true
	MenuManager.foremost_menu_index = MenuManager.foremost_menu_index - 1
	
	on_closed_start.emit()
	MenuManager.on_any_menu_closed_start.emit()
	
	InputManager.disable_inputs(close_duration)
	
	await get_tree().create_timer(close_duration).timeout
	
	on_closed_end.emit()
	MenuManager.on_any_menu_closed_end.emit()
	
	if queue_free_on_close:
		queue_free()
	else:
		visible = false
	
func _on_gui_event(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() and !InputManager.inputs_disabled:
			close()
