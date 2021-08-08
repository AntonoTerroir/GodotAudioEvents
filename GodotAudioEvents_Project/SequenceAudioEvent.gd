extends AudioEvent
class_name SequenceAudioEvent, "res://AudioEvent/Icons/SequenceAudioEvent.png"

var cur_index = 0

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
var playingChildren = []

enum VoicePriority {
	STEAL_OLDEST,
	STEAL_NEWEST
}

export(VoicePriority) var voice_priority = VoicePriority.STEAL_OLDEST


func _on_ready():
	if(autoplay):
		play()
	
func play(id = -1):
	
	if _playlist_finished: return
	
	
	if(id > -1 && id < (audioChildren.size() - 1)):
		event = audioChildren[id]
	else: 
		event = audioChildren[cur_index]
	
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
	
	cur_index += 1 if !_reverse else -1
	
	set_is_playing(true)
	
	if _reverse:
		if cur_index == -1:
			_reverse = false
			if(audioChildren.size() > 1):
				cur_index = 1
			else:
				cur_index = 0
			return 
	else:
		if cur_index < audioChildren.size(): return
	
	match on_sequence_end:
		SequenceEnd.STOP:
			_playlist_finished = true
		SequenceEnd.LOOP:
			reset()
		SequenceEnd.REVERSE:
			_reverse = true
			cur_index -= 1
		SequenceEnd.REPEAT_LAST:
			cur_index -= 1
	

func stop(id = -1):
	if !isPlaying: return
	
	if(id < 0 || id > (audioChildren.size() - 1)):
		for child in playingChildren:
			event = child
			if(fade_out_active):
				if is_audio_stream(event):
					fade_out()
				else:
					event.fade_out(fade_out_time, fade_in_type)
			else: event.stop()
	else:
		if(fade_out_active):
			if is_audio_stream(audioChildren[id]):
				fade_out()
			else:
				event.fade_out(fade_out_time, fade_in_type)
		else: audioChildren[id].stop()
	
	set_is_playing(false)

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
			event.fade_out(fade_out_time, fade_in_type)
	set_is_playing(false)

func _get_configuration_warning():
	var cond = false
	for child in get_children():
		if is_audio_node(child):
			cond = true
			break
	return "" if cond else "Au moins un des enfants de ce noeud doit être de type AudioStreamPlayer"

func reset():
	cur_index = 0
	_playlist_finished = false


func get_class(): return "SequenceAudioEvent"
