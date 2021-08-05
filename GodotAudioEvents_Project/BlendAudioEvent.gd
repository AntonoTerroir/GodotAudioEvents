extends AudioEvent
class_name BlendAudioEvent, "res://AudioEvent/Icons/BlendAudioEvent.png"

var audioChildren = []

func _on_ready():
	for child in get_children():
		if is_audio_node(child):
			audioChildren.append(child)
	
	if autoplay:
		play()

func play():
	for child in audioChildren:
		event = child
		if(fade_in_active):
			if is_audio_stream(event):
				fade_in()
			else:
				event.fade_in(true, event.get_volume_db(), fade_in_time, fade_in_type)
		else: event.play()

func stop():
	for child in audioChildren:
		event = child
		if(fade_out_active):
			if is_audio_stream(event):
				fade_out()
			else:
				event.fade_out(fade_out_time, fade_in_type)
		else: event.stop()

func fade_in(apply_mods:bool = false, target_volume:float = get_volume_db(), fade_time:float = fade_in_time, fade_type:int = fade_in_type):
	for child in audioChildren:
		event = child
		if is_audio_stream(event):
			set_volume_db(-80)
			event.play()
			tween.interpolate_property(event, "volume_db", -80, target_volume, fade_time, fade_type, Tween.EASE_OUT, 0)
			tween.start()
			yield(get_tree().create_timer(fade_time), "timeout")
			emit_signal("fade_in_completed")
		else:
			event.fade_in(true, event.get_volume_db(), fade_in_time, fade_in_type)

func fade_out(fade_time:float = fade_out_time, fade_type:int = fade_out_type):
	for child in audioChildren:
		event = child
		if is_audio_stream(event):
			tween.interpolate_property(event, "volume_db", event.volume_db, -80, fade_time, fade_type, Tween.EASE_OUT, 0)
			tween.start()
			yield(get_tree().create_timer(fade_time), "timeout")
			event.stop()
			emit_signal("fade_out_completed")
		else:
			event.fade_out(fade_out_time, fade_in_type)

func get_class(): return "BlendAudioEvent"
