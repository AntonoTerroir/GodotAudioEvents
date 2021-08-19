extends AudioEvent
class_name BlendAudioEvent, "res://GAT/Icons/BlendAudioEvent.png"

func _on_ready():
	
	_set_is_fading(false)
	_set_is_paused(false)
	_set_is_playing(false)
	
	if autoplay:
		play()

func play():
	
	if fading:
		_tweens_stop_and_reset()
		_set_is_fading(false)
	
	if paused:
		resume()
	
	for child in _audio_children:
		_event = child
		if(fade_in_active):
			if _is_audio_stream(_event):
				_fade_in()
			else:
				_event._fade_in(true, 0, fade_in_time, fade_in_type)
		else: _event.play()
		
	_set_is_playing(true)

func stop():
	if !playing: return
	
	var _wasPaused = false
	
	if paused:
		_wasPaused = true
		resume()
		
	for child in _audio_children:
		_event = child
		if(!fade_out_active || _wasPaused):
			_event.stop()
			playing = false
		else:
			if _is_audio_stream(_event):
				_fade_out()
			else:
				_event._fade_out(fade_out_time, fade_in_type)

func pause():
	if !playing: return
	
	_set_is_paused(true)
	for child in _audio_children:
		if _is_audio_stream(child):
			child._set_stream_paused(true)
		else:
			if child.fading:
				child._tween.stop_all()
			child.pause()

func resume():
	if !playing: return
	
	_set_is_paused(false)
	for child in _audio_children:
		if _is_audio_stream(child):
			child._set_stream_paused(false)
		else:
			if child.fading:
				child._tween.resume_all()
			child.resume()

func _fade_in(apply_mods:bool = false, target_volume:float = 0, fade_time:float = fade_in_time, fade_type:int = fade_in_type):
	if playing: return
	
	for child in _audio_children:
		_event = child
		if _is_audio_stream(_event):
			var _start_volume = _event.volume_db
			set_volume_db(-80)
			_event.play()
			_tween.interpolate_property(_event, "volume_db", -80, _start_volume, fade_time, fade_type, Tween.EASE_OUT, 0)
			_tween.start()
			_set_is_fading(true)
			yield(_tween, "tween_all_completed")
			emit_signal("fade_in_completed")
			_set_is_fading(false)
		else:
			_event._fade_in(true, 0, fade_in_time, fade_in_type)
	if apply_mods:
		_set_is_playing(true)

func _fade_out(fade_time:float = fade_out_time, fade_type:int = fade_out_type):
	if !playing: return
	
	_set_is_fading(true)
	
	for child in _audio_children:
		_event = child
		if _is_audio_stream(_event):
			var _start_volume = _event.volume_db
			_tween.interpolate_property(_event, "volume_db", _start_volume, -80, fade_time, fade_type, Tween.EASE_OUT, 0)
			_tween.start()
			yield(_tween, "tween_all_completed")
			_event.stop()
			emit_signal("fade_out_completed")
			_set_is_fading(false)
			set_volume_db(_start_volume)
		else:
			_event._fade_out(fade_out_time, fade_in_type)
	
	_set_is_playing(false)


func get_class(): return "BlendAudioEvent"
