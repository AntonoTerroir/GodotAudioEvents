extends AudioEvent
class_name BlendAudioEvent, "res://AudioEvent/Icons/BlendAudioEvent.png"

func _on_ready():
		
	if autoplay:
		play()

func play():
	
	if isFading:
		tweens_stop_and_reset()
		set_is_fading(false)
	
	if isPaused:
		resume()
	
	for child in audioChildren:
		event = child
		if(fade_in_active):
			if is_audio_stream(event):
				fade_in()
			else:
				event.fade_in(true, event.get_volume_db(), fade_in_time, fade_in_type)
		else: event.play()
		
	set_is_playing(true)

func stop():
	if !isPlaying: return
	
	var _wasPaused = false
	
	if isPaused:
		_wasPaused = true
		resume()
		
	for child in audioChildren:
		event = child
		if(!fade_out_active || _wasPaused):
			event.stop()
			set_is_playing(false)
		else:
			if is_audio_stream(event):
				fade_out()
			else:
				event.fade_out(fade_out_time, fade_in_type)

func pause():
	if !isPlaying: return
	
	set_is_paused(true)
	for child in audioChildren:
		if is_audio_stream(child):
			child.set_stream_paused(true)
		else:
			if child.isFading:
				child.tween.stop_all()
			child.pause()

func resume():
	if !isPlaying: return
	
	set_is_paused(false)
	for child in audioChildren:
		if is_audio_stream(child):
			child.set_stream_paused(false)
		else:
			if child.isFading:
				child.tween.resume_all()
			child.resume()

func fade_in(apply_mods:bool = false, target_volume:float = get_volume_db(), fade_time:float = fade_in_time, fade_type:int = fade_in_type):
	if isPlaying: return
	
	for child in audioChildren:
		event = child
		if is_audio_stream(event):
			set_volume_db(-80)
			event.play()
			tween.interpolate_property(event, "volume_db", -80, target_volume, fade_time, fade_type, Tween.EASE_OUT, 0)
			tween.start()
			set_is_fading(true)
			yield(tween, "tween_all_completed")
			emit_signal("fade_in_completed")
			set_is_fading(false)
		else:
			event.fade_in(true, event.get_volume_db(), fade_in_time, fade_in_type)
	if apply_mods:
		set_is_playing(true)

func fade_out(fade_time:float = fade_out_time, fade_type:int = fade_out_type):
	if !isPlaying: return
	
	set_is_fading(true)
	
	for child in audioChildren:
		event = child
		if is_audio_stream(event):
			var start_volume = event.volume_db
			tween.interpolate_property(event, "volume_db", start_volume, -80, fade_time, fade_type, Tween.EASE_OUT, 0)
			tween.start()
			yield(tween, "tween_all_completed")
			event.stop()
			emit_signal("fade_out_completed")
			set_is_fading(false)
			set_volume_db(start_volume)
		else:
			event.fade_out(fade_out_time, fade_in_type)
	
	set_is_playing(false)

func get_class(): return "BlendAudioEvent"
