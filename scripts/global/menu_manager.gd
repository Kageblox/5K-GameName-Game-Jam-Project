class_name MenuManagerGlobal
extends Node
## Global script that manages Menus.

signal on_any_menu_opened_start()
signal on_any_menu_opened_end()
signal on_any_menu_closed_start()
signal on_any_menu_closed_end()

var question_menu_resource = preload("res://assets/resources/ui/menus/question_menu.tscn") as Resource
var settings_menu_resource = preload("res://assets/resources/ui/menus/settings_menu.tscn") as Resource
var save_slots_menu_resource = preload("res://assets/resources/ui/menus/save_slots_menu.tscn") as Resource
var pause_menu_resource = preload("res://assets/resources/ui/menus/pause_menu.tscn") as Resource
var costume_room_menu_resource = preload("res://assets/resources/ui/menus/costume_room_menu.tscn") as Resource


## The foremost menu's child index. -1 if there are no open menus.
@export var foremost_menu_index = -1

func get_foremost_menu() -> MenuInstance:
	if foremost_menu_index < 0:
		return null
	else:
		return get_child(MenuManager.foremost_menu_index) as MenuInstance

## Opens a Question Menu.[br]
## Parameters:[br]
## question: The question being asked.[br]
## answers: A Dictionary matching the text to be put in each answer button to their callback.[br]
func open_question_menu(question: String, answers: Dictionary[String, Callable]) -> void:
	var question_menu = question_menu_resource.instantiate() as QuestionMenu
	_open_menu(question_menu, [question, answers])

## Opens a Settings Menu.
func open_settings_menu() -> void:
	var settings_menu = settings_menu_resource.instantiate() as SettingsMenu
	_open_menu(settings_menu)

## Opens a Save Slots Menu.[br]
## Parameters:[br]
## save_slot_menu_variant: The type of Save Slot Menu to open.[br]
## [br]
## Types of Save Slot Variants:[br]
## - New Game[br]
## - Load Game[br]
## - Save Game[br]
func open_save_slots_menu(save_slot_menu_variant: SaveSlotsMenu.SaveSlotMenuVariant) -> void:
	var save_slots_menu = save_slots_menu_resource.instantiate() as SaveSlotsMenu
	_open_menu(save_slots_menu, [save_slot_menu_variant])

## Opens a Pause Menu.
func open_pause_menu() -> void:
	var pause_menu = pause_menu_resource.instantiate() as PauseMenu
	_open_menu(pause_menu)
	
## Opens a Costume Room Menu.
func open_costume_room_menu() -> void:
	var costume_room_menu = costume_room_menu_resource.instantiate() as CostumeRoomMenu
	_open_menu(costume_room_menu)

## Closes all Menus.[br]
## Parameters:[br]
## instant: Whether to do so instantly by deleting them, or by closing them normally.
func close_all_menus(instant: bool) -> void:
	for child in get_children():
		if instant:
			child.queue_free()
		else:
			child.close()
	foremost_menu_index = -1

func _open_menu(menu: MenuInstance, _params: Array[Variant] = []) -> void:
	# Adds and opens the given menu under this node, and updates the foremost_menu_index.
	get_parent().move_child(self, -1)
	add_child(menu)
	menu.open(_params)
	foremost_menu_index = foremost_menu_index + 1
