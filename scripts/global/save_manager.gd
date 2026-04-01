class_name SaveManagerGlobal
extends Node
## Global script that manages Saving and Loading of data.[br]
## Also stores the settings' data and the currently loaded game data.

signal on_settings_changed(new_settings: SettingsDataResource)

var default_settings: SettingsDataResource = preload("res://assets/resources/data/default_settings.tres") as SettingsDataResource

var current_settings: SettingsDataResource = null
var current_game_data: GameDataResource = GameDataResource.new()

func _enter_tree() -> void:
	current_settings = load_settings()
	if current_settings == null:
		current_settings = default_settings

## Returns the game data of the specified save slot index. Returns null if it does not exist.[br]
## Parameters:[br]
## index: The specified save slot index.[br]
func load_game_data(index: int) -> GameDataResource:
	return load_resource(str(index), "GameDataResource")

## Saves the specified game data to the specified save slot index.[br]
## Parameters:[br]
## game_data: The game data to save.[br]
## index: The specified save slot index.[br]
func save_game_data(game_data: GameDataResource, index:int) -> void:
	game_data.save_slot = index
	game_data.last_saved = Time.get_datetime_dict_from_system()
	save_resource(game_data, str(index))

## Deletes the game data of the specified save slot index.[br]
## Parameters:[br]
## index: The specified save slot index.[br]
func delete_game_data(index:int) -> void:
	delete_resource(str(index))

## Returns the saved settings data. Returns null if it does not exist.[br]
func load_settings() -> SettingsDataResource:
	return load_resource("settings", "SettingsDataResource")

## Saves and applies the specified settings data.
## Parameters:[br]
## new_settings: The new settings to apply.[br]
func apply_new_settings(new_settings: SettingsDataResource) -> void:
	save_resource(new_settings, "settings")
	current_settings = new_settings
	on_settings_changed.emit(new_settings)

## Restores the default settings. Also deletes the saved settings data if it exists.
func restore_default_settings() -> void:
	delete_resource("settings")
	current_settings = default_settings
	on_settings_changed.emit(default_settings)

## Saves the specified resource to the specified location.
## Parameters:[br]
## resource: The resource to save.[br]
## location: The location to save the resource to.[br]
func save_resource(resource: Resource, location: String) -> void:
	var path = "user://" + location + ".tres"
	var error = ResourceSaver.save(resource, path)
	if error != OK:
		print("Error saving resource: ", error)
	else:
		print("Resource saved successfully to ", path)

## Loads the resource stored at the specified location.
## Parameters:[br]
## location: The location where the resource is saved at.[br]
## type_hint: The specific class name of the resource.[br]
func load_resource(location: String, type_hint: String = "") -> Resource:
	var path = "user://" + location + ".tres"
	if FileAccess.file_exists(path):
		var loaded_resource = ResourceLoader.load(path, type_hint, ResourceLoader.CACHE_MODE_IGNORE)
		if loaded_resource:
			print("Resource loaded successfully.")
			return loaded_resource
		else:
			print("Error loading Resource.")
	return null

## Deletes the resource stored at the specified location.
## Parameters:[br]
## location: The location where the resource is saved at.[br]
func delete_resource(location: String) -> void:
	var path = "user://" + location + ".tres"
	if FileAccess.file_exists(path):
		var error = DirAccess.remove_absolute(path)
		if error == OK:
			print("Deleted Resource:" + location)
		else:
			print("Error deleting Resource: " + location + " Error code: " + str(error))
	else:
		print("Resource not found: " + location)
