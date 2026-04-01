class_name PauseButton
extends CustomTextureButton

func _ready() -> void:
	pressed.connect(
		func():
			MenuManager.open_pause_menu()
			)
