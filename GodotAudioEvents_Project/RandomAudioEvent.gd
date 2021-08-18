extends AudioEvent
class_name RandomAudioEvent, "res://AudioEvent/Icons/RandomAudioEvent.png"

export(int, 1, 50) var max_voices = 1
var _playingChildren = []

enum VoicePriority {
	STEAL_OLDEST,
	STEAL_NEWEST
}

export(VoicePriority) var voice_priority = VoicePriority.STEAL_OLDEST

func _on_ready():
	
	var _randomChild = _get_random_child()
	_event = _randomChild
	
	_set_is_fading(false)
	_set_is_paused(false)
	_set_is_playing(false)
	
	if(autoplay):
		play()
	
func play():
	var _randomChild = _get_random_child()
	_event = _randomChild
	
	if _isFading:
		_tweens_stop_and_reset()
		_set_is_fading(false)
	
	if _isPaused:
		resume()
	
	var mods = _apply_modifier()
	if mods is GDScriptFunctionState:
		yield(mods, "completed")
	
	if(fade_in_active):
		if _is_audio_stream(_event):
			_fade_in()
		else:
			_event._fade_in(true, _event.get_volume_db(), fade_in_time, fade_in_type)
	else:
		_event.play()
	
	_check_max_voices()
	
	_set_is_playing(true)

func stop(id = -1):
	if !_isPlaying: return
	
	var _wasPaused = false
	
	if _isPaused:
		_wasPaused = true
		resume()
	
	if(id < 0 || id > (_audioChildren.size() - 1)):
		for child in _playingChildren:
			_event = child
			if(!fade_out_active || _wasPaused):
				_event.stop()
			else: 
				if _is_audio_stream(_event):
					_fade_out()
				else:
					_event._fade_out(fade_out_time, fade_out_type)
			
		if(fade_out_active):
			yield(get_tree().create_timer(fade_out_time), "timeout")
			_playingChildren.clear()
		else: _playingChildren.clear()
	else:
		if(fade_out_active):
			if _is_audio_stream(_audioChildren[id]):
				_fade_out()
				yield(get_tree().create_timer(fade_out_time), "timeout")
				_playingChildren.remove(id)
			else:
				_event._fade_out(fade_out_time, fade_out_type)
		else: 
			_audioChildren[id].stop()
			_audioChildren.remove(id)
	
	_set_is_playing(false)
	print_debug(_playingChildren.size())

func pause():
	if !_isPlaying: return
	
	_set_is_paused(true)
	for child in _playingChildren:
		if _is_audio_stream(child):
			child.set_stream_paused(true)
		else:
			if child._isFading:
				child._tween.stop_all()
			child.pause()

func resume():
	if !_isPlaying: return
	
	_set_is_paused(false)
	for child in _playingChildren:
		if _is_audio_stream(child):
			child.set_stream_paused(false)
		else:
			if child._isFading:
				child._tween.resume_all()
			child.resume()

func _fade_out(fade_time:float = fade_out_time, fade_type:int = fade_out_type):
	if !_isPlaying: return
	for child in _playingChildren:
		_event = child
		_set_is_fading(true)
		if _is_audio_stream(_event):
			_tween.interpolate_property(_event, "volume_db", _event.volume_db, -80, fade_time, fade_type, Tween.EASE_OUT, 0)
			_tween.start()
			yield(_tween, "tween_all_completed")
			_event.stop()
			_set_is_fading(false)
			emit_signal("fade_out_completed")
		else:
			_event._fade_out(fade_out_time, fade_out_type)
	
	_set_is_playing(false)

var _lastRandomSound

func _check_max_voices():
	if(_playingChildren.size() == max_voices):
		match voice_priority:
			VoicePriority.STEAL_OLDEST:
				_playingChildren[0].stop()
				_playingChildren.remove(0)
			VoicePriority.STEAL_NEWEST:
				_playingChildren[max_voices - 1].stop()
				_playingChildren.remove(max_voices - 1)
	_playingChildren.append(_event)
	print_debug(_playingChildren.size())

func _get_random_child():
	randomize()
	var _soundID = randi()%_audioChildren.size()
	while(_soundID == _lastRandomSound):
		_soundID = randi()%_audioChildren.size()
	_lastRandomSound = _soundID
	var _randomSound = _audioChildren[_soundID]
	return _randomSound

func _set_is_playing(value: bool):
	
	_isPlaying = value
	for child in _playingChildren:
		if child.has_method("_set_is_playing"):
			child._set_is_playing(value)

func _set_is_paused(value: bool):
	
	_isPaused = value
	for child in _playingChildren:
		if child.has_method("_set_is_paused"):
			child._set_is_paused(value)

func _set_is_fading(value: bool):
	
	_isFading = value
	for child in _playingChildren:
		if child.has_method("_set_is_fading"):
			child._set_is_fading(value)

func _get_configuration_warning():
	var cond = false
	for child in get_children():
		if is_audio_node(child):
			cond = true
			break

  return "" if cond else "Au moins un des enfants de ce noeud doit être de type AudioStreamPlayer"


func get_class(): return "RandomAudioEvent"
