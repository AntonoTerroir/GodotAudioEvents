extends AudioEvent
class_name RandomAudioEvent, "res://AudioEvent/Icons/RandomAudioEvent.png"

export(int, 1, 50) var max_voices = 1
var playingChildren = []

enum VoicePriority {
	STEAL_OLDEST,
	STEAL_NEWEST
}

export(VoicePriority) var voice_priority = VoicePriority.STEAL_OLDEST

func _on_ready():
	
	if(autoplay):
		play()
	
func play():
	var randomChild = _get_random_child()
	event = randomChild
	
	if(modifiers.size() > 0):
		modifiers.sort_custom(self, "_sort_custom_mod_priority")
		print_debug(modifiers.size())
		for mod in modifiers:
			var obj = mod.apply(event)
			if obj is GDScriptFunctionState:
				yield(obj, "completed")
	
	if(fade_in_active):
		if is_audio_stream(event):
			fade_in()
		else:
			event.fade_in(true, event.get_volume_db(), fade_in_time, fade_in_type)
			print_debug("Fade in event started")
	else:
		event.play()
	
	if(playingChildren.size() == max_voices):
		match voice_priority:
			VoicePriority.STEAL_OLDEST:
				playingChildren[0].stop()
				playingChildren.remove(0)
			VoicePriority.STEAL_NEWEST:
				playingChildren[max_voices - 1].stop()
				playingChildren.remove(max_voices - 1)
	playingChildren.append(event)
	
	set_is_playing(true)

func stop(id = -1):
	if !isPlaying: return
	
	if(id < 0 || id > (audioChildren.size() - 1)):
		for child in playingChildren:
			event = child
			if(fade_out_active):
				if is_audio_stream(event):
					fade_out()
				else:
					event.fade_out(fade_out_time, fade_out_type)
			else: event.stop()
	else:
		if(fade_out_active):
			if is_audio_stream(audioChildren[id]):
				fade_out()
			else:
				event.fade_out(fade_out_time, fade_out_type)
		else: audioChildren[id].stop()
	
	set_is_playing(false)

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

func fade_out(fade_time:float = fade_out_time, fade_type:int = fade_out_type):
	if !isPlaying: return
	
	for child in playingChildren:
		event = child
		if is_audio_stream(event):
			tween.interpolate_property(event, "volume_db", event.volume_db, -80, fade_time, fade_type, Tween.EASE_OUT, 0)
			tween.start()
			yield(get_tree().create_timer(fade_time), "timeout")
			event.stop()
			emit_signal("fade_out_completed")
		else:
			event.fade_out(fade_out_time, fade_out_type)
	
	set_is_playing(false)

var lastRandomSound

func _get_random_child():
	randomize()
	var soundID = randi()%audioChildren.size()
	while(soundID == lastRandomSound):
		soundID = randi()%audioChildren.size()
	lastRandomSound = soundID
	var randomSound = audioChildren[soundID]
	return randomSound

func _get_configuration_warning():
	var cond = false
	for child in get_children():
		if is_audio_node(child):
			cond = true
			break

  return "" if cond else "Au moins un des enfants de ce noeud doit être de type AudioStreamPlayer"


func get_class(): return "RandomAudioEvent"
