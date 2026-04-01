class_name InputManagerGlobal
extends Node
## Global script that manages Player Inputs.

## Whether the Player's Inputs have been disabled.
@export var inputs_disabled: bool = false

var _timer: Timer = null

func _enter_tree() -> void:
	# Creates, configures, and adds a new timer under this node.
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.autostart = false
	_timer.ignore_time_scale = true
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)

## Disables the Player's Inputs for a certain duration.[br]
## If the Player's Inputs are already disabled, adds to the duration if it's longer than the time left.
func disable_inputs(duration: float) -> void:
	if duration >  _timer.time_left:
		inputs_disabled = true
		_timer.start(duration)

func _on_timer_timeout() -> void:
	inputs_disabled = false
	
