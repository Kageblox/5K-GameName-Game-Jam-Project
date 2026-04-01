class_name MenuModulate
extends Control
## Tweens the modulate color from being invisible to the specified color upon its connected menu being opened.

@export var invisible_color: Color = Color(1,1,1,0)
@export var visible_color: Color = Color(1,1,1,1)

@export var entry_transition : Tween.TransitionType = Tween.TransitionType.TRANS_SINE
@export var entry_ease : Tween.EaseType = Tween.EaseType.EASE_OUT

@export var exit_transition : Tween.TransitionType = Tween.TransitionType.TRANS_SINE
@export var exit_ease : Tween.EaseType = Tween.EaseType.EASE_IN

var connected_menu: MenuInstance

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _enter_tree() -> void:
	connected_menu = MenuFunctions.get_connected_menu(self)
	connected_menu.on_opened_start.connect(
		func():
			_tween_modulate_color(
				invisible_color, 
				visible_color, 
				connected_menu.open_duration, 
				entry_ease, 
				entry_transition)
			pass)
	connected_menu.on_closed_start.connect(
		func():
			_tween_modulate_color(
				visible_color, 
				invisible_color, 
				connected_menu.close_duration, 
				exit_ease, 
				exit_transition)
			pass)

func _tween_modulate_color(_from: Color, _to: Color, _duration: float, _ease: Tween.EaseType, _transition: Tween.TransitionType) -> void:
	modulate = _from
	
	var tween = create_tween().set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate", _to, _duration).set_ease(_ease).set_trans(_transition)
