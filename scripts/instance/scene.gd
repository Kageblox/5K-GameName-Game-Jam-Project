class_name SceneInstance
extends Node
## The base class for all Scenes. Managed by the Scene Manager.

signal on_scene_entry()
signal on_scene_exit()

const PAUSE_BUTTON_RESOURCE: Resource = preload("res://assets/resources/ui/buttons/pause_button.tscn")

@export var pausable = false

var pause_button = null

func _scene_entry() -> void: 
	if pausable:
		pause_button = PAUSE_BUTTON_RESOURCE.instantiate()
		add_child(pause_button)
	on_scene_entry.emit()
	
func _scene_exit() -> void:
	if pausable:
		pause_button.queue_free()
	on_scene_exit.emit()
