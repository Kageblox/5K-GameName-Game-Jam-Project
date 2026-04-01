class_name AudioManagerGlobal
extends Node
## Global script that manages audio.

@export var all_audio: AudioDataCollectionResource = preload("res://assets/resources/audio/audio_collection.tres")

@export var background_music_volume: float = 0.5
@export var sound_effects_volume: float = 0.5

var _background_music_player_1: AudioStreamPlayer
var _background_music_player_2: AudioStreamPlayer
var _menu_sound_effects_player: AudioStreamPlayer

var _active_background_music_player: AudioStreamPlayer
var _active_volume_from: float
var _active_volume_to: float

var _inactive_background_music_player: AudioStreamPlayer
var _inactive_volume_from: float
var _inactive_volume_to: float

var _timer: Timer = null

func _enter_tree() -> void:
	_background_music_player_1 = AudioStreamPlayer.new()
	_background_music_player_1.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_background_music_player_1)
	
	_background_music_player_2 = AudioStreamPlayer.new()
	_background_music_player_2.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_background_music_player_2)
	
	_menu_sound_effects_player = AudioStreamPlayer.new()
	_menu_sound_effects_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_menu_sound_effects_player)
	
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.autostart = false
	_timer.ignore_time_scale = true
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)
	
	
	# Whenever the settings change, update the sound settings to match.
	SaveManager.on_settings_changed.connect(
		func(new_settings: SettingsDataResource):
			background_music_volume = new_settings.background_music_volume
			sound_effects_volume = new_settings.sound_effects_volume
			)
			
	# Set the current sound settings to mathc the current settings.
	background_music_volume = SaveManager.current_settings.background_music_volume
	sound_effects_volume = SaveManager.current_settings.sound_effects_volume

func _process(_delta: float) -> void:
	if _timer.time_left > 0:
		var weight = _timer.time_left / _timer.wait_time
		_active_background_music_player.volume_db = lerp(_active_volume_from, _active_volume_to, 1 - weight)
		_inactive_background_music_player.volume_db = lerp(_inactive_volume_from, _inactive_volume_to, 1 - weight)


## Plays the specified audio track.[br]
## Parameters:[br]
## audio_name: The key needed to access the Audio Stream within all_audio.[br]
## fade_in_duration: How long the audio track takes to fade in fully.
## player: The AudioStreamPlayer that will play the track. If unspecified, defaults to the background music players.
func play_audio(audio_name: String, fade_in_duration: float = 1.0, player: AudioStreamPlayer = null) -> void:
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
				
				# If the current music player is 1
				if _active_background_music_player == _background_music_player_1:
					# Set the new music player to 2
					_active_background_music_player = _background_music_player_2
					_inactive_background_music_player = _background_music_player_1
				else:
					# Else, set it to 1
					_active_background_music_player = _background_music_player_1
					_inactive_background_music_player = _background_music_player_2
			
				# If a track was playing previously
				if _inactive_background_music_player.playing:
					_inactive_volume_from = _active_volume_to
					_inactive_volume_to = _active_volume_from
				else:
					_inactive_volume_from = 0
					_inactive_volume_to = 0
					
				# The active music player will need to face from inactive to active
				_active_background_music_player.stream = audio_data.stream
				_active_background_music_player.volume_db = audio_data.active_volume_db
				_active_background_music_player.pitch_scale = audio_data.pitch_scale
		
				_active_volume_from = audio_data.inactive_volume_db
				_active_volume_to = audio_data.active_volume_db
				
				_active_background_music_player.play()
				
				_timer.start(fade_in_duration)
				
				pass
			"Sound Effects":
				pass
			_:
				pass

func _on_timer_timeout() -> void:
	_active_background_music_player.volume_db = _active_volume_to
	_inactive_background_music_player.playing = false
