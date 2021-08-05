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

export(bool) var isPlaying = false
export(bool) var autoplay = false

var event
var tween

func _ready():
	tween = Tween.new()
	self.add_child(tween)
	
	_on_ready()

func _on_ready():
	
	_get_audio_child()
	
	if(autoplay):
		play()

func _get_audio_child():
	for child in get_children():
		if is_audio_node(child):
			event = child
			return

# Lancer l'event
func play():
	
	var mods = apply_modifier()
	if mods is GDScriptFunctionState:
		yield(mods, "completed")
	
	if(fade_in_active):
		if is_audio_stream(event):
			fade_in()
		else:
			event.fade_in(event.get_volume_db(), fade_in_time, fade_in_type)
	else:
		event.play()
		
	isPlaying = true

func stop():
	#if !isPlaying: return
	
	if(fade_out_active):
		if is_audio_stream(event):
			fade_out()
		else:
			event.fade_out(fade_out_time, fade_in_type)
	else: event.stop()
		
	isPlaying = false

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

func fade_in(apply_mods:bool = false, target_volume:float = get_volume_db(), fade_time:float = fade_in_time, fade_type:int = fade_in_type):
	isPlaying = true
	
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
	

func fade_out(fade_time:float = fade_out_time, fade_type:int = fade_out_type):
	#if !isPlaying: return
	
	if is_audio_stream(event):
		tween.interpolate_property(event, "volume_db", event.volume_db, -80, fade_time, fade_type, Tween.EASE_OUT, 0)
		tween.start()
		yield(get_tree().create_timer(fade_time), "timeout")
		event.stop()
		emit_signal("fade_out_completed")
	else:
		event.fade_out(fade_out_time, fade_in_type)
	

func get_volume_db():
	return event.volume_db
	
func set_volume_db(volume: float):
	event.volume_db = volume
	print_debug("-80 baby")
	
# Afficher les avertissements de config dans l'éditeur
func _get_configuration_warning():
	if !is_audio_node(self) && !is_audio_node(get_child(0)):
		return "Ce noeud ou son premier enfant doit être un noeud AudioStreamPlayer"
	return ""

func get_class(): return "AudioEvent"
