class_name BackgroundMusicPlayerInstance
extends AudioStreamPlayer
## An AudioStreamPlayer that plays a background track.

var _audio_data: AudioDataResource
var audio_data: AudioDataResource: 
	get:
		return _audio_data
	set(value):
		_audio_data = value
		stream = audio_data.stream
		pitch_scale = audio_data.pitch_scale
		bus = audio_data.bus

var _from_vol = null
var _to_vol = null
var _playing = false
var _timer: Timer

func _init() -> void:
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.autostart = false
	_timer.ignore_time_scale = true
	_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)

func _process(_delta: float) -> void:
	if _timer.time_left > 0:
		volume_db = lerp(_to_vol, _from_vol, (_timer.time_left/ _timer.wait_time))

func play_with_fade(
	fade_duration : float = 1.0, 
	_active_vol: float = audio_data.active_volume_db, 
	_inactive_vol: float = audio_data.inactive_volume_db) -> void:
	_playing = true
	
	_from_vol = _inactive_vol
	_to_vol = _active_vol
	
	play()
	
	_timer.start(fade_duration)

func stop_with_fade(
	fade_duration : float = 1.0, 
	_active_vol: float = audio_data.active_volume_db, 
	_inactive_vol: float = audio_data.inactive_volume_db) -> void:
	_playing = false
	
	_from_vol = _active_vol
	_to_vol = _inactive_vol
	
	_timer.start(fade_duration)

func _on_timer_timeout() -> void:
	if _playing:
		volume_db =  audio_data.active_volume_db
	else:
		queue_free()
