class_name SaveSlotsMenu
extends MenuInstance

enum SaveSlotMenuVariant {NEW_GAME, LOAD_GAME, SAVE_GAME, SAVE_AUTOSAVE_BEFORE_RETURNING}

@export var save_slots_header_label: Label
@export var autosave_container: Container

@export_group("Save Slots")
@export var save_slots: Array[SaveSlotInstance]

var save_slot_menu_variant: SaveSlotMenuVariant

func open(_params: Array[Variant] = [])-> void:
	save_slot_menu_variant = _params[0]
	
	match(save_slot_menu_variant):
		SaveSlotMenuVariant.NEW_GAME:
			save_slots_header_label.text = "New Game"
			autosave_container.visible = false
			
		SaveSlotMenuVariant.LOAD_GAME:
			save_slots_header_label.text = "Load Game"
			autosave_container.visible = true
			
		SaveSlotMenuVariant.SAVE_GAME:
			save_slots_header_label.text = "Save Game"
			autosave_container.visible = false
		
		_:
			pass
	
	for i in range(save_slots.size()):
		var save_slot = save_slots[i]
		save_slot.load_slot(i)
		save_slot.save_slot_button.pressed.connect(_on_save_slot_button_pressed.bind(i))
		save_slot.delete_button.pressed.connect(_on_save_slot_delete_button_pressed.bind(i))
	super()

func _on_save_slot_button_pressed(index: int) -> void:
	match(save_slot_menu_variant):
		SaveSlotMenuVariant.NEW_GAME:
			if save_slots[index].loaded.visible:
				MenuManager.open_question_menu(
					"Overwrite Save Slot " + str(index + 1) + "?",
					{
						"Yes":
							func():
								SaveManager.save_game_data(SaveManager.current_game_data, index)
								SceneManager.goto_scene("res://scenes/another_scene.tscn")
								close(),
						"No":
							func():
								pass,
					}
				)
			else:
				MenuManager.open_question_menu(
					"Start New Game on Save Slot " + str(index + 1) + "?",
					{
						"Yes":
							func():
								SaveManager.current_game_data = GameDataResource.new(index)
								SaveManager.save_game_data(SaveManager.current_game_data, index)
								SceneManager.goto_scene("res://scenes/another_scene.tscn"),
						"No":
							func():
								pass,
					}
				)
		SaveSlotMenuVariant.LOAD_GAME:
			if save_slots[index].loaded.visible:
				if index == 5:
					MenuManager.open_question_menu(
						"Load Autosave?",
						{
							"Yes":
								func():
									SaveManager.current_game_data = SaveManager.load_game_data(index)
									SceneManager.goto_scene("res://scenes/another_scene.tscn"),
							"No":
								func():
									pass,
						}
					)
				else:
					MenuManager.open_question_menu(
						"Load Save Slot " + str(index + 1) + "?",
						{
							"Yes":
								func():
									SaveManager.current_game_data = SaveManager.load_game_data(index)
									SceneManager.goto_scene("res://scenes/another_scene.tscn"),
							"No":
								func():
									pass,
						}
					)
		SaveSlotMenuVariant.SAVE_GAME:
			if save_slots[index].loaded.visible:
				MenuManager.open_question_menu(
					"Overwrite Save Slot " + str(index + 1) + "?",
					{
						"Yes":
							func():
								SaveManager.save_game_data(SaveManager.current_game_data, index)
								save_slots[index].load_slot(index)
								close(),
						"No":
							func():
								pass,
					}
				)
			else:
				MenuManager.open_question_menu(
					"Save to Save Slot " + str(index + 1) + "?",
					{
						"Yes":
							func():
								SaveManager.save_game_data(SaveManager.current_game_data, index)
								save_slots[index].load_slot(index)
								close(),
						"No":
							func():
								pass,
					}
				)
		SaveSlotMenuVariant.SAVE_AUTOSAVE_BEFORE_RETURNING:
			if save_slots[index].loaded.visible:
				MenuManager.open_question_menu(
					"Overwrite Save Slot " + str(index + 1) + "?",
					{
						"Yes":
							func():
								SaveManager.save_game_data(SaveManager.current_game_data, index)
								save_slots[index].load_slot(index)
								SceneManager.goto_scene("res://scenes/main_menu_scene.tscn"),
						"No":
							func():
								pass,
					}
				)
			else:
				MenuManager.open_question_menu(
					"Save to Save Slot " + str(index + 1) + "?",
					{
						"Yes":
							func():
								SaveManager.save_game_data(SaveManager.current_game_data, index)
								save_slots[index].load_slot(index)
								SceneManager.goto_scene("res://scenes/main_menu_scene.tscn"),
						"No":
							func():
								pass,
					}
				)
		_:
			pass

func _on_save_slot_delete_button_pressed(index: int) -> void:
	MenuManager.open_question_menu(
		"Delete Save Slot " + str(index + 1) + "?",
		{
			"Yes":
				func():
					SaveManager.delete_game_data(index)
					save_slots[index].load_slot(index),
			"No":
				func():
					pass,
		}
	)

func _on_return_button_pressed() -> void:
	close()
