extends AudioEvent
class_name SwitchAudioEvent, "res://AudioEvent/Icons/SwitchAudioEvent.png"

export(int, 1, 50) var max_voices = 1
var _playingChildren = []

enum VoicePriority {
	STEAL_OLDEST,
	STEAL_NEWEST
}

export(VoicePriority) var voice_priority = VoicePriority.STEAL_OLDEST

enum SwitchMode {
	IMMEDIATE,
	NEXT_PLAY,
	CROSSFADE
}

export(SwitchMode) var switch_mode = SwitchMode.NEXT_PLAY

export(float) var crossfade_time = 0

export var current_switch = 0

func _on_ready():
	_event = _audioChildren[current_switch]
	
	if(autoplay):
		play()
	
func play():
	
	_event = _audioChildren[current_switch]
	
	if(modifiers.size() > 0):
		modifiers.sort_custom(self, "_sort_custom_mod_priority")
		print_debug(modifiers.size())
		for mod in modifiers:
			var obj = mod.apply(_event)
			if obj is GDScriptFunctionState:
				yield(obj, "completed")
	
	if(fade_in_active):
		if _is_audio_stream(_event):
			_fade_in(false)
		else:
			_event._fade_in(true, _event.get_volume_db(), fade_in_time, fade_in_type)
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
	
	_set_is_playing(true)

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

func set_switch(soundID: int):
	current_switch = soundID
	
	if !_isPlaying: return
	
	match switch_mode:
		SwitchMode.CROSSFADE:
			_crossfade_out(crossfade_time)
			_event = _audioChildren[current_switch]
			_fade_in(true, _event.get_volume_db(), crossfade_time)
		SwitchMode.IMMEDIATE:
			_event.stop()
			play()
		SwitchMode.NEXT_PLAY:
			return

func _crossfade_out(fade_time:float = fade_out_time, fade_type:int = fade_out_type):
	
	if _is_audio_stream(_event):
		_tween.interpolate_property(_event, "volume_db", _event.volume_db, -80, fade_time, fade_type, Tween.EASE_OUT, 0)
		_tween.start()
		_set_is_fading(true)
		yield(_tween, "tween_all_completed")
		emit_signal("fade_out_completed")
		_set_is_fading(false)
		
	else:
		_event._fade_out(fade_time, fade_type)

func _crossfade_in(apply_mods:bool = false, target_volume:float = get_volume_db(), fade_time:float = fade_in_time, fade_type:int = fade_in_type):
	if apply_mods:
		var mods = _apply_modifier()
		if mods is GDScriptFunctionState:
			yield(mods, "completed")
	
	if _is_audio_stream(_event):
		set_volume_db(-80)
		if(!_event._isPlaying):
			_event.play()
		_tween.interpolate_property(_event, "volume_db", -80, target_volume, fade_time, fade_type, Tween.EASE_OUT, 0)
		_tween.start()
		yield(get_tree().create_timer(fade_time), "timeout")
		emit_signal("fade_in_completed")
	else:
		_event._fade_in(true, _event.get_volume_db(), fade_in_time, fade_in_type)
	
	if apply_mods:
		_set_is_playing(true)

func _fade_in(apply_mods:bool = false, target_volume:float = get_volume_db(), fade_time:float = fade_in_time, fade_type:int = fade_in_type):
	if _isPlaying: return
	
	if apply_mods:
		var mods = _apply_modifier()
		if mods is GDScriptFunctionState:
			yield(mods, "completed")
	
	if _is_audio_stream(_event):
		set_volume_db(-80)
		_event.play()
		_tween.interpolate_property(_event, "volume_db", -80, target_volume, fade_time, fade_type, Tween.EASE_OUT, 0)
		_tween.start()
		yield(get_tree().create_timer(fade_time), "timeout")
		emit_signal("fade_in_completed")
	else:
		_event._fade_in(true, _event.get_volume_db(), fade_in_time, fade_in_type)
	
	if apply_mods:
		_set_is_playing(true)

func get_volume_db():
	
	if _is_audio_stream(_event):
		return _event.volume_db
	else:
		_event.get_volume_db()

func _get_configuration_warning():
	var cond = false
	for child in get_children():
		if is_audio_node(child):
			cond = true
			break

  return "" if cond else "Au moins un des enfants de ce noeud doit être de type AudioStreamPlayer"


func get_class(): return "SwitchAudioEvent"
