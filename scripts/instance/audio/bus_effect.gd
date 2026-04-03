class_name BusEffectInstance
extends Timer
## A node representing and controlling a bus effect.

@export var active_effect_params: AudioEffect 
@export var inactive_effect_params: AudioEffect

var _property_names: Array[String]
var _property_from: Array[Variant]
var _property_to: Array[Variant]

var _playing = true

func _init() -> void:
	one_shot = true
	autostart = false
	ignore_time_scale = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	timeout.connect(_on_timer_timout)

func _process(_delta: float) -> void:
	if time_left > 0:
		var weight = time_left/wait_time
		var effect = AudioServer.get_bus_effect(get_parent().get_index(), get_index())
		if effect != null:
			for i in _property_names.size():
				effect.set(_property_names[i], lerp(_property_to[i], _property_from[i], weight))

## Activate the Bus Effect.
func activate(fade_in_duration: float = 1.0) -> void:
	_generate_interpolation_variables(inactive_effect_params, active_effect_params)
	_playing = true
	AudioServer.add_bus_effect(get_parent().get_index(), inactive_effect_params.duplicate())
	start(fade_in_duration)

## Deactivates the Bus Effect.
func deactivate(fade_out_duration: float = 1.0) -> void:
	_generate_interpolation_variables(active_effect_params, inactive_effect_params)
	_playing = false
	start(fade_out_duration)
	
func _on_timer_timout() -> void:
	if _playing:
		var effect = AudioServer.get_bus_effect(get_parent().get_index(), get_index())
		for i in _property_names.size():
			effect.set(_property_names[i], _property_to[i])
	else:
		AudioServer.remove_bus_effect(get_parent().get_index(), get_index())
		queue_free()
	
## Generates the required arrays to properly interpolate between 2 Audio Effects.
func _generate_interpolation_variables(from: AudioEffect, to: AudioEffect) -> void:
	if from.get_class() != to.get_class():
		return push_error("From and To Audio Effects are different Audio Effects.")
	else:
		_property_names.clear()
		_property_from.clear()
		_property_to.clear()
	
		var audio_effect_properties = from.get_property_list()
		for property in audio_effect_properties:
			match property.type:
				TYPE_FLOAT:
					_property_names.append(property.name)
					_property_from.append(from.get(property.name))
					_property_to.append(to.get(property.name))
				_:
					pass
