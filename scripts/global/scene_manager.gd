class_name SceneManagerGlobal
extends Node
## Global script that manages Scenes.[br]
## Also manages Scene Transitions via the Loading Screen.

const LOADING_SCREEN_RESOURCE: Resource = preload("res://assets/resources/ui/menus/loading_screen.tscn")

var current_scene: SceneInstance
var _loading_screen : MenuInstance

## The currently loading scene's resource path.
var _loading_path = null

func _enter_tree() -> void:
	## Instantiates and adds the loading screen under this node.
	_loading_screen = LOADING_SCREEN_RESOURCE.instantiate()
	add_child(_loading_screen)
	_loading_screen.visible = false

func _ready() -> void:
	current_scene = get_tree().root.get_child(-1) as SceneInstance
	get_tree().current_scene = current_scene
	current_scene._scene_entry()

func _process(_delta: float) -> void:
	if _loading_path != null:
		var loading_status = ResourceLoader.load_threaded_get_status(_loading_path)
		match loading_status:
			# Once the next scene has been loaded,
			ResourceLoader.THREAD_LOAD_LOADED:
				
				current_scene._scene_exit()
				
				# Close the loading screen.
				_loading_screen.close()
				
				# In case some menus have yet to close, delete them instantly.
				MenuManager.close_all_menus(true)
				
				# Retrieve the fully loaded next scene.
				var loaded_scene_resource = ResourceLoader.load_threaded_get(_loading_path) as Resource
				_loading_path = null
				
				# Delete the previous scene.
				current_scene.queue_free()
				
				# Replaces the deleted scene with the new one.
				current_scene = loaded_scene_resource.instantiate() as SceneInstance
				get_tree().root.add_child(current_scene)
				get_tree().current_scene = current_scene
				
				current_scene._scene_entry()
				
				#await get_tree().create_timer(_loading_screen.close_duration).timeout
				#get_parent().move_child(self, 0)
				
			ResourceLoader.THREAD_LOAD_FAILED:
				push_error("Failed to load: " + _loading_path)

			ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				push_error(_loading_path + " is invalid")

func goto_scene(_path: String) -> void:
	get_parent().move_child(self, -1)
	_loading_screen.open()
	MenuManager.close_all_menus(false)
	
	await get_tree().create_timer(_loading_screen.open_duration).timeout
	
	_loading_path = _path
	ResourceLoader.load_threaded_request(_loading_path)
