class_name AudioManagerGlobal
extends Node
## Global script that manages audio.

const MIN_BUS_VOL: float = -80.0
const MAX_BUS_VOL: float = 6.0

@export var all_audio: AudioDataCollectionResource = preload("res://assets/resources/audio/audio_collection.tres")

@export var background_music_volume: float = 0.5
@export var sound_effects_volume: float = 0.5

func _enter_tree() -> void:
	# Whenever the settings change, update the sound settings to match.
	SaveManager.on_settings_changed.connect(update_bus_volumes)
	
	# Set the current sound settings to mathc the current settings.
	update_bus_volumes()
	
	var player_holder = Node.new()
	player_holder.name = "Players"
	add_child(player_holder)
	
	var effect_holder = Node.new()
	effect_holder.name = "Effects"
	add_child(effect_holder)
	
	for i in AudioServer.bus_count:
		var bus_player_holder = Node.new()
		bus_player_holder.name = AudioServer.get_bus_name(i)
		player_holder.add_child(bus_player_holder)
		
		var bus_effect_holder = Node.new()
		bus_effect_holder.name = AudioServer.get_bus_name(i)
		effect_holder.add_child(bus_effect_holder)
		
## Updates the volume of all buses, based on the specified settings.
func update_bus_volumes(
		new_settings: SettingsDataResource = SaveManager.current_settings
		) -> void:
	background_music_volume = new_settings.background_music_volume
	sound_effects_volume = new_settings.sound_effects_volume
	
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Background Music"), linear_to_db(background_music_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("UI Sound Effects"), linear_to_db(sound_effects_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Game Sound Effects"), linear_to_db(sound_effects_volume))

## Plays the specified audio track.[br]
## Parameters:[br]
## audio_name: The key needed to access the Audio Stream within all_audio.[br]
## fade_in_duration: How long the audio track takes to fade in fully.[br]
## player: The AudioStreamPlayer that will play the track. If unspecified, defaults to the background music players.[br]
func play_audio(
		audio_name: String, 
		fade_in_duration: float = 1.0, 
		player: AudioStreamPlayer = null
		) -> void:
	var audio_data = all_audio.audio_data_collection[audio_name] as AudioDataResource
	if player != null:
		player.stream = audio_data.stream
		player.volume_db = audio_data.active_volume_db
		player.pitch_scale = audio_data.pitch_scale
		player.bus = audio_data.bus
		player.play()
	else:
		match(audio_data.bus):
			"Master": 
				pass
			"Background Music":
				var background_music_players = get_node("Players/Background Music")
				var new_background_music_player_instance = BackgroundMusicPlayerInstance.new()
				new_background_music_player_instance.audio_data = audio_data
				background_music_players.add_child(new_background_music_player_instance)
				
				new_background_music_player_instance.play_with_fade(fade_in_duration)
			"UI Sound Effects":
				pass
			"Game Sound Effects":
				pass
			_:
				pass
				
## Stops all background music players belonging to the specified bus.[br]
## Parameters:[br]
## bus: The specified bus.[br]
## fade_out_duration: How long the audio track takes to fade out fully.[br]
func stop_bus_players(
		bus: String, 
		fade_out_duration: float = 1.0
		) -> void:
	var bus_player_holder = get_node("Players/" + bus)
	for child in bus_player_holder.get_children():
		if child is BackgroundMusicPlayerInstance:
			child.stop_with_fade(fade_out_duration)

## Adds an AudioEffect to the specified bus.[br]
## Parameters:[br]
## bus: The specified bus.[br]
## fade_in_duration: How long the audio track takes to fade in fully.[br]
func add_bus_effect(
		bus: String, 
		active_effect_params: AudioEffect, 
		inactive_effect_params: AudioEffect, 
		fade_in_duration: float = 1.0,
		effect_name: String = active_effect_params.get_class(),
		) -> void:
	var bus_effect_holder = get_node("Effects/" + bus)
	
	var bus_effect = BusEffectInstance.new()
	bus_effect.name = effect_name
	bus_effect.active_effect_params = active_effect_params
	bus_effect.inactive_effect_params = inactive_effect_params
	
	bus_effect_holder.add_child(bus_effect)
	
	bus_effect.activate(fade_in_duration)

## Removes an AudioEffect from the specified bus.[br]
## Parameters:[br]
## bus: The specified bus.[br]
## effect_name: The name of the node controlling the effect.
## fade_out_duration: How long the audio track takes to fade out fully.[br]
func remove_bus_effect_from_name(
		bus: String, 
		effect_name: String, 
		fade_out_duration: float = 1.0
		) -> void:
	var bus_effect_holder = get_node("Effects/" + bus)
	var bus_effect = bus_effect_holder.get_node(effect_name) as BusEffectInstance
	bus_effect.deactivate(fade_out_duration)
