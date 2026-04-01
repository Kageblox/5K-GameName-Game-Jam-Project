class_name MenuFunctions
extends Node


## Looks for the menu instance this node is attached to. Returns null if there is none.
static func get_connected_menu(menu_component: Control) -> MenuInstance:
	var connected_menu = null
	var current_node = menu_component
	while connected_menu == null:
		var parent = current_node.get_parent()
		if parent is MenuInstance: # If the parent is a MenuInstance
			return parent
		elif parent == null: # If the current_node is the root
			return null
		else:
			current_node = parent
	return null
