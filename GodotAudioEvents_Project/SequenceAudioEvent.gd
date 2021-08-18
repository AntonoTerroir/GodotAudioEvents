extends AudioEvent
class_name SequenceAudioEvent, "res://AudioEvent/Icons/SequenceAudioEvent.png"

var _cur_index = 0

var _reverse = false
var _playlist_finished = false

enum SequenceEnd {
	STOP,
	LOOP,
	REVERSE,
	REPEAT_LAST
}

export(SequenceEnd) var on_sequence_end = SequenceEnd.STOP

export(int, 1, 50) var max_voices = 1
var _playingChildren = []

enum VoicePriority {
	STEAL_OLDEST,
	STEAL_NEWEST
}

export(VoicePriority) var voice_priority = VoicePriority.STEAL_OLDEST


func _on_ready():
	_event = _audioChildren[_cur_index]
	
	if(autoplay):
		play()
	
func play(id = -1):
	
	if _playlist_finished: return
	
	
	if(id > -1 && id < (_audioChildren.size() - 1)):
		_event = _audioChildren[id]
	else: 
		_event = _audioChildren[_cur_index]
	
	if(modifiers.size() > 0):
		modifiers.sort_custom(self, "_sort_custom_mod_priority")
		print_debug(modifiers.size())
		for mod in modifiers:
			var obj = mod.apply(_event)
			if obj is GDScriptFunctionState:
				yield(obj, "completed")
	
	if(fade_in_active):
		if _is_audio_stream(_event):
			_fade_in()
		else:
			_event.fade_in(true, _event.get_volume_db(), fade_in_time, fade_in_type)
	else:
		_event.play()
	
	if(_playingChildren.size() == max_voices):
		match voice_priority:
			VoicePriority.STEAL_OLDEST:
				_playingChildren[0].stop()
				_playingChildren.remove(0)
			VoicePriority.STEAL_NEWEST:
				_playingChildren[max_voices - 1].stop()
				_playingChildren.remove(max_voices - 1)
	_playingChildren.append(_event)
	
	_cur_index += 1 if !_reverse else -1
	
	_set_is_playing(true)
	
	if _reverse:
		if _cur_index == -1:
			_reverse = false
			if(_audioChildren.size() > 1):
				_cur_index = 1
			else:
				_cur_index = 0
			return 
	else:
		if _cur_index < _audioChildren.size(): return
	
	match on_sequence_end:
		SequenceEnd.STOP:
			_playlist_finished = true
		SequenceEnd.LOOP:
			reset()
		SequenceEnd.REVERSE:
			_reverse = true
			_cur_index -= 1
		SequenceEnd.REPEAT_LAST:
			_cur_index -= 1
	

func stop(id = -1):
	if !_isPlaying: return
	
	if(id < 0 || id > (_audioChildren.size() - 1)):
		for child in _playingChildren:
			_event = child
			if(fade_out_active):
				if _is_audio_stream(_event):
					_fade_out()
				else:
					_event._fade_out(fade_out_time, fade_in_type)
			else: _event.stop()
	else:
		if(fade_out_active):
			if _is_audio_stream(_audioChildren[id]):
				_fade_out()
			else:
				_event._fade_out(fade_out_time, fade_in_type)
		else: _audioChildren[id].stop()
	
	_set_is_playing(false)

func _fade_out(fade_time:float = fade_out_time, fade_type:int = fade_out_type):
	if !_isPlaying: return
	
	for child in _playingChildren:
		_event = child
		if _is_audio_stream(_event):
			_tween.interpolate_property(_event, "volume_db", _event.volume_db, -80, fade_time, fade_type, Tween.EASE_OUT, 0)
			_tween.start()
			yield(get_tree().create_timer(fade_time), "timeout")
			_event.stop()
			emit_signal("fade_out_completed")
		else:
			_event._fade_out(fade_out_time, fade_in_type)
	_set_is_playing(false)

func _get_configuration_warning():
	var cond = false
	for child in get_children():
		if is_audio_node(child):
			cond = true
			break
	return "" if cond else "Au moins un des enfants de ce noeud doit être de type AudioStreamPlayer"

func reset():
	_cur_index = 0
	_playlist_finished = false


func get_class(): return "SequenceAudioEvent"
