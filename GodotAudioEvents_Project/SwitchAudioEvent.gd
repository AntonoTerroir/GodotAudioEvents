extends AudioEvent
class_name SwitchAudioEvent, "res://AudioEvent/Icons/SwitchAudioEvent.png"

var audioChildren = []

export(int, 1, 50) var max_voices = 1
var playingChildren = []

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
	for child in get_children():
		if is_audio_node(child):
			audioChildren.append(child)
	
	if(autoplay):
		play()
	
func play():
	
	event = audioChildren[current_switch]
	
	if(modifiers.size() > 0):
		modifiers.sort_custom(self, "_sort_custom_mod_priority")
		print_debug(modifiers.size())
		for mod in modifiers:
			var obj = mod.apply(event)
			if obj is GDScriptFunctionState:
				yield(obj, "completed")
	
	if(fade_in_active):
		if is_audio_stream(event):
			fade_in(false)
		else:
			event.fade_in(true,event.get_volume_db(), fade_in_time, fade_in_type)
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

func stop(id = -1):
	
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

func set_switch(soundID: int):
	current_switch = soundID
	match switch_mode:
		SwitchMode.CROSSFADE:
			event.fade_out(crossfade_time)
			event = audioChildren[current_switch]
			fade_in(true, event.get_volume_db(), crossfade_time)
		SwitchMode.IMMEDIATE:
			event.stop()
			play()
		SwitchMode.NEXT_PLAY:
			return

func fade_in(apply_mods:bool = false, target_volume:float = get_volume_db(), fade_time:float = fade_in_time, fade_type:int = fade_in_type):
	
	if apply_mods:
		var mods = apply_modifier()
		if mods is GDScriptFunctionState:
			yield(mods, "completed")
	
	if is_audio_stream(event):
		set_volume_db(-80)
		event.play()
		tween.interpolate_property(event, "volume_db", -80, target_volume, fade_time, fade_type, Tween.EASE_OUT, 0)
		tween.start()
		yield(get_tree().create_timer(fade_time), "timeout")
		emit_signal("fade_in_completed")
	else:
		event.fade_in(true, event.get_volume_db(), fade_in_time, fade_in_type)

func _get_configuration_warning():
	var cond = false
	for child in get_children():
		if is_audio_node(child):
			cond = true
			break

  return "" if cond else "Au moins un des enfants de ce noeud doit être de type AudioStreamPlayer"


func get_class(): return "SwitchAudioEvent"
