class_name MenuPosition
extends Control
## Tweens from the entry location to the center upon its connected menu being opened.

enum Position {CENTER, UP, DOWN, LEFT, RIGHT}

@export var entry_position: Position
@export var entry_transition : Tween.TransitionType = Tween.TransitionType.TRANS_SINE
@export var entry_ease : Tween.EaseType = Tween.EaseType.EASE_OUT

@export var exit_position: Position
@export var exit_transition : Tween.TransitionType = Tween.TransitionType.TRANS_SINE
@export var exit_ease : Tween.EaseType = Tween.EaseType.EASE_IN

var connected_menu: MenuInstance

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
func _enter_tree() -> void:
	connected_menu = MenuFunctions.get_connected_menu(self)
	connected_menu.on_opened_start.connect(
		func():
			_tween_position(
				entry_position, 
				Position.CENTER, 
				connected_menu.open_duration, 
				entry_ease, 
				entry_transition)
			pass)
	connected_menu.on_closed_start.connect(
		func():
			_tween_position(
				Position.CENTER, 
				exit_position, 
				connected_menu.close_duration, 
				exit_ease, 
				exit_transition)
			pass)

func _tween_position(_from: Position, _to: Position, _duration: float, _ease: Tween.EaseType, _transition: Tween.TransitionType) -> void:
	position = _get_true_position(_from)
	
	var tween = create_tween().set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "position",_get_true_position(_to), _duration).set_ease(_ease).set_trans(_transition)

func _get_true_position(_position_enum: Position) -> Vector2:
	var viewport_size = get_viewport_rect().size
	match _position_enum:
		Position.CENTER:
			return Vector2(0,0)
		Position.UP:
			return Vector2(0,-viewport_size.x)
		Position.DOWN:
			return Vector2(0,viewport_size.x)
		Position.LEFT:
			return Vector2(-viewport_size.y,0)
		Position.RIGHT:
			return Vector2(viewport_size.y,0)
		_:
			return Vector2(0,0)
			
