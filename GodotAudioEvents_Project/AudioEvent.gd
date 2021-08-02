tool

# Représente un évènement audio basique. Toutes les classes events audio héritent
class_name AudioEvent
extends Node

export(float, -80, 24) var volume_db = 0.0

export(float, 0.01, 4) var pitch_scale = 1.00

export var override_parent_pitch = false

export var override_parent_volume = false

export(bool) var fade_in_active
export(float) var fade_in_time
export(int) var fade_in_type

signal fade_in_completed
signal fade_completed
signal fade_out_completed

export(bool) var is_playing = false

var event

var tween

func _ready():
	randomize()
	event = self if is_audio_node(self) else get_child(0)
	
	tween = Tween.new()
	self.add_child(tween)
	
	play_modifier()


# Lancer l'event
func post_event():
	# Randomiser le pitch
	#if random_pitch != Vector2.ZERO:
		#var random = rand_range(random_pitch.x, random_pitch.y)
		#event.pitch_scale += random

	# Randomiser le volume
	#if random_pitch != Vector2.ZERO:
		#var random = rand_range(random_volume.x, random_volume.y)
		#event.volume_db += random

		event.play()



# Helper : Est-ce que le node donné est un node audio
# return bool
func is_audio_node(node : Node):
	return node is AudioStreamPlayer or \
	node is AudioStreamPlayer2D or \
	node is AudioStreamPlayer3D or \
	node.get_class() == "AudioEvent"


export(Array, Resource) var modifiers = []

func play_modifier():
  #C'est pas ça la syntaxe mais t'as l'idée
	modifiers.sort_custom(self, "_sort_custom_mod_priority")
	print_debug(modifiers.size())
	for mod in modifiers:
		var obj = mod.apply(self)
		if obj is GDScriptFunctionState:
			yield(obj, "completed")
		
	print_debug("play_function_completed")

func _sort_custom_mod_priority(a, b):
	if a.priority < b.priority:
		return true
	return false

func _get_hierarchy_volume():
	var current_volume = volume_db + get_child(0).volume_db
	print_debug(current_volume)
	return current_volume
	
func _set_hierarchy_volume(stream_player):
	var current_volume = volume_db + get_child(0).volume_db
	stream_player.set_volume_db(current_volume)
	print_debug(stream_player.get_volume_db())

func fade_to_volume(target_volume:float, fade_time:float, fade_type:int = 1):
	tween.interpolate_property(self, "volume_db", get_volume_db(), target_volume, fade_time, fade_type, Tween.EASE_IN, 0)
	tween.start()

func fade_in(target_volume:float = get_volume_db(), fade_time:float = fade_in_time, fade_type:int = fade_in_type):
	if is_playing: return
	set_volume_db(-80)
	post_event()
	tween.interpolate_property(self, "volume_db", -80, target_volume, fade_time, fade_type, Tween.EASE_IN, 0)
	tween.start()
	yield(get_tree().create_timer(fade_time), "timeout")
	emit_signal("fade_in_completed")
	
func get_volume_db():
	return volume_db
	
func set_volume_db(volume: float):
	volume_db = volume
	
# Afficher les avertissements de config dans l'éditeur
func _get_configuration_warning():
	if !is_audio_node(self) && !is_audio_node(get_child(0)):
		return "Ce noeud ou son premier enfant doit être un noeud AudioStreamPlayer"
	return ""

func get_class(): return "AudioEvent"
