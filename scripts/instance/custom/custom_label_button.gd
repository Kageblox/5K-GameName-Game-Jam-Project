@tool @icon("res://assets/textures/ui/Button.svg")
class_name CustomLabelButton
extends Control
## A customized version of the normal Button, that uses Label Settings for the text.[br]
## Also made to be compatible with the menu system.

signal pressed()
signal toggled(toggled_on: bool)
var connected_menu: MenuInstance

@export_category("BaseButton")
var _button: Button
var button: Button:
	get:
		if _button == null:
			_button = get_node("Button") as Button
		return _button

@export var disabled: bool:
	get:
		return button.disabled
	set(value):
		button.disabled = value

@export var toggle_mode: bool:
	get:
		return button.toggle_mode
	set(value):
		button.toggle_mode = value

@export var button_pressed: bool:
	get:
		return button.button_pressed
	set(value):
		button.button_pressed = value

@export_category("Label")

var _label: Label
var label : Label:
	get:
		if _label == null:
			_label = get_node("Margins/Label") as Label
		return _label
		
@export var text: String:
	get:
		return label.text
	set(value):
		label.text = value
	
@export var label_settings: LabelSettings:
	get:
		return label.label_settings
	set(value):
		label.label_settings = value 

@export var horizontal_alignment: HorizontalAlignment:
	get:
		return label.horizontal_alignment
	set(value):
		label.horizontal_alignment = value 

@export var autowrap_mode: TextServer.AutowrapMode:
	get:
		return label.autowrap_mode
	set(value):
		label.autowrap_mode = value 

@export var clip_text: bool:
	get:
		return label.clip_text
	set(value):
		label.clip_text = value 

@export var text_overrun_behavior: TextServer.OverrunBehavior:
	get:
		return label.text_overrun_behavior
	set(value):
		label.text_overrun_behavior = value 

func _enter_tree() -> void:
	connected_menu = MenuFunctions.get_connected_menu(self)
	button.pressed.connect(
		func():
			pressed.emit()
			)
	button.toggled.connect(
		func(toggled_on: bool):
			toggled.emit(toggled_on)
			)
			
	focus_entered.connect(button.grab_focus)
	
	# When any menu starts opening, disable the button.
	MenuManager.on_any_menu_opened_start.connect(
		func():
			disabled = true
			)
	
	# When any menu finishes opening, re-enable the button if its part of the foremost menu.
	MenuManager.on_any_menu_opened_end.connect(
		func():
			if connected_menu != null:
				if connected_menu.get_index() == MenuManager.foremost_menu_index:
					disabled = false
			else:
				if MenuManager.foremost_menu_index == -1:
					disabled = false
			)
	
	# When any menu starts closing, disable the button.
	MenuManager.on_any_menu_closed_start.connect(
		func():
			disabled = true
			)
	
	# When any menu finishes closing, re-enable the button if its part of the foremost menu.
	MenuManager.on_any_menu_closed_end.connect(
		func():
			if connected_menu != null:
				if connected_menu.get_index() == MenuManager.foremost_menu_index:
					disabled = false
			else:
				if MenuManager.foremost_menu_index == -1:
					disabled = false
			)
