# Représente un évènement audio basique. Toutes les classes events audio héritent
class_name AudioEvent, "res://AudioEvent/Icons/AudioEvent.png"
extends Node

#export(float, -80, 24) var volume_db = 0.0

#export(float, 0.01, 4) var pitch_scale = 1.00

export(bool) var fade_in_active
export(float) var fade_in_time
export(int) var fade_in_type

export(bool) var fade_out_active
export(float) var fade_out_time
export(int) var fade_out_type

signal fade_in_completed
signal fade_completed
signal fade_out_completed

var isFading = false
var isPaused = false
export(bool) var isPlaying = false
export(bool) var autoplay = false

var event
var tween

var audioChildren = []

func _ready():
	tween = Tween.new()
	self.add_child(tween)
	
	for child in get_children():
		if is_audio_node(child):
			audioChildren.append(child)
	
	_on_ready()

func _on_ready():
	
	event = audioChildren[0]
	
	if(autoplay):
		play()

# Lancer l'event
func play():
	
	### PROBLEME
	# lorsque un audio event n'est pas le seul enfant d'un blend event
	# il ne se relance pas lorsque play - stop - play
	
	
	var mods = apply_modifier()
	if mods is GDScriptFunctionState:
		yield(mods, "completed")
	
	set_is_paused(false)
	
	if isFading:
		tweens_stop_and_reset()
		set_is_fading(false)
	
	if isPaused:
		resume()
	
	if(fade_in_active):
		if is_audio_stream(event):
			fade_in()
		else:
			event.fade_in(event.get_volume_db(), fade_in_time, fade_in_type)
	else:
		event.play()
		
	set_is_playing(true)

func tweens_stop_and_reset():
	tween.stop_all()
	tween.reset_all()
	tween.remove_all()

func stop():
	
	if !isPlaying: return
	
	if(fade_out_active):
		if is_audio_stream(event):
			fade_out()
		else:
			event.fade_out(fade_out_time, fade_in_type)
	else: event.stop()
		
	set_is_playing(false)
	set_is_paused(false)

func pause():
	if !isPlaying:return
	
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

# Helper : Est-ce que le node donné est un node audio
# return bool
func is_audio_node(node : Node):
	
	if (node is AudioStreamPlayer or \
	node is AudioStreamPlayer2D or \
	node is AudioStreamPlayer3D or \
	node.get_class() == "AudioEvent" or \
	node.get_class() == "RandomAudioEvent" or \
	node.get_class() == "SequenceAudioEvent" or \
	node.get_class() == "BlendAudioEvent"):
		return true

func is_audio_stream(node : Node):
	
	if (node is AudioStreamPlayer or \
	node is AudioStreamPlayer2D or \
	node is AudioStreamPlayer3D):
		return true

export(Array, Resource) var modifiers = []

func apply_modifier():
	
	if (modifiers.size() > 0):
		modifiers.sort_custom(self, "_sort_custom_mod_priority")
		for mod in modifiers:
			var obj = mod.apply(self)
			if obj is GDScriptFunctionState:
				yield(obj, "completed")

func _sort_custom_mod_priority(a, b):
	
	if a.priority < b.priority:
		return true
	return false

func _get_hierarchy_volume():
	
	var current_volume = get_child(0).volume_db
	print_debug(current_volume)
	return current_volume
	
func _set_hierarchy_volume(stream_player):
	
	var current_volume = get_child(0).volume_db
	stream_player.set_volume_db(current_volume)
	print_debug(stream_player.get_volume_db())

func fade_to_volume(target_volume:float, fade_time:float, fade_type:int = 1):
	
	tween.interpolate_property(event, "volume_db", get_volume_db(), target_volume, fade_time, fade_type, Tween.EASE_OUT, 0)
	tween.start()
	set_is_fading(true)
	yield(tween, "tween_all_completed")
	set_is_fading(false)
	

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
	
	if is_audio_stream(event):
		var start_volume = event.volume_db
		tween.interpolate_property(event, "volume_db", event.volume_db, -80, fade_time, fade_type, Tween.EASE_OUT, 0)
		tween.start()
		set_is_fading(true)
		yield(tween, "tween_all_completed")
		event.stop()
		emit_signal("fade_out_completed")
		set_is_fading(false)
		set_volume_db(start_volume)
		
	else:
		event.fade_out(fade_out_time, fade_in_type)
		
	set_is_playing(false)
	

func get_volume_db():
	
	return event.volume_db
	
func set_volume_db(volume: float):
	
	event.volume_db = volume

func set_is_playing(value: bool):
	
	isPlaying = value
	for child in audioChildren:
		if child.has_method("set_is_playing"):
			child.set_is_playing(value)

func set_is_paused(value: bool):
	
	isPaused = value
	for child in audioChildren:
		if child.has_method("set_is_paused"):
			child.set_is_paused(value)

func set_is_fading(value: bool):
	
	isFading = value
	for child in audioChildren:
		if child.has_method("set_is_fading"):
			child.set_is_fading(value)

# Afficher les avertissements de config dans l'éditeur
func _get_configuration_warning():
	
	if !is_audio_node(self) && !is_audio_node(get_child(0)):
		return "Ce noeud ou son premier enfant doit être un noeud AudioStreamPlayer"
	return ""

func get_class(): return "AudioEvent"
