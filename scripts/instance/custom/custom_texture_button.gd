class_name CustomTextureButton
extends TextureButton
## A customized version of the normal TextureButton, made to be compatible with the menu system.

var connected_menu: MenuInstance

func _enter_tree() -> void:
	connected_menu = MenuFunctions.get_connected_menu(self)
	
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
