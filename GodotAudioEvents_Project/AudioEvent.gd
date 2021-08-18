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

var _isFading = false
var _isPaused = false
var _isPlaying = false
export(bool) var autoplay = false

var _event
var _tween

var _audioChildren = []

func _ready():
	_tween = Tween.new()
	self.add_child(_tween)
	
	for child in get_children():
		if is_audio_node(child):
			_audioChildren.append(child)
	
	_on_ready()

func _on_ready():
	
	_event = _audioChildren[0]
	
	if(autoplay):
		play()

# Lancer l'event
func play():
	
	### PROBLEME
	# lorsque un audio event n'est pas le seul enfant d'un blend event
	# il ne se relance pas lorsque play - stop - play
	
	
	var mods = _apply_modifier()
	if mods is GDScriptFunctionState:
		yield(mods, "completed")
	
	_set_is_paused(false)
	
	if _isFading:
		_tweens_stop_and_reset()
		_set_is_fading(false)
	
	if _isPaused:
		resume()
	
	if(fade_in_active):
		if _is_audio_stream(_event):
			_fade_in()
		else:
			_event._fade_in(_event.get_volume_db(), fade_in_time, fade_in_type)
	else:
		_event.play()
		
	_set_is_playing(true)

func _tweens_stop_and_reset():
	_tween.stop_all()
	_tween.reset_all()
	_tween.remove_all()

func stop():
	
	if !_isPlaying: return
	
	if(!fade_out_active):
		_event.stop()
	else:
		if _is_audio_stream(_event):
			_fade_out()
		else:
			_event.fade_out(fade_out_time, fade_in_type)
		
	_set_is_playing(false)
	_set_is_paused(false)

func pause():
	if !_isPlaying:return
	
	_set_is_paused(true)
	for child in _audioChildren:
		if _is_audio_stream(child):
			child.set_stream_paused(true)
		else:
			if child._isFading:
				child._tween.stop_all()
			child.pause()
			

func resume():
	if !_isPlaying: return
	
	_set_is_paused(false)
	for child in _audioChildren:
		if _is_audio_stream(child):
			child.set_stream_paused(false)
		else:
			if child._isFading:
				child._tween.resume_all()
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
	node.get_class() == "SwitchAudioEvent" or \
	node.get_class() == "BlendAudioEvent"):
		return true

func _is_audio_stream(node : Node):
	
	if (node is AudioStreamPlayer or \
	node is AudioStreamPlayer2D or \
	node is AudioStreamPlayer3D):
		return true

export(Array, Resource) var modifiers = []

func _apply_modifier():
	
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

func _fade_to_volume(target_volume:float, fade_time:float, fade_type:int = 1):
	
	_tween.interpolate_property(_event, "volume_db", get_volume_db(), target_volume, fade_time, fade_type, Tween.EASE_OUT, 0)
	_tween.start()
	_set_is_fading(true)
	yield(_tween, "tween_all_completed")
	_set_is_fading(false)
	

func _fade_in(apply_mods:bool = false, target_volume:float = 0, fade_time:float = fade_in_time, fade_type:int = fade_in_type):
	
	if apply_mods:
		var mods = _apply_modifier()
		if mods is GDScriptFunctionState:
			yield(mods, "completed")
	
	if _is_audio_stream(_event):
		set_volume_db(-80)
		_event.play()
		_tween.interpolate_property(_event, "volume_db", -80, target_volume, fade_time, fade_type, Tween.EASE_OUT, 0)
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
	
	if !_isPlaying: return
	
	if _is_audio_stream(_event):
		var start_volume = _event.volume_db
		_tween.interpolate_property(_event, "volume_db", _event.volume_db, -80, fade_time, fade_type, Tween.EASE_OUT, 0)
		_tween.start()
		_set_is_fading(true)
		yield(_tween, "tween_all_completed")
		_event.stop()
		emit_signal("fade_out_completed")
		_set_is_fading(false)
		set_volume_db(start_volume)
		
	else:
		_event._fade_out(fade_time, fade_type)
		
	_set_is_playing(false)
	

func get_volume_db():
	
	if _is_audio_stream(_event):
		return _event.volume_db
	else:
		_event.get_volume_db()
	
func set_volume_db(volume: float):
	
	_event.volume_db = volume

func _set_is_playing(value: bool):
	
	_isPlaying = value
	for child in _audioChildren:
		if child.has_method("_set_is_playing"):
			child._set_is_playing(value)

func _set_is_paused(value: bool):
	
	_isPaused = value
	for child in _audioChildren:
		if child.has_method("_set_is_paused"):
			child._set_is_paused(value)

func _set_is_fading(value: bool):
	
	_isFading = value
	for child in _audioChildren:
		if child.has_method("_set_is_fading"):
			child._set_is_fading(value)

# Afficher les avertissements de config dans l'éditeur
func _get_configuration_warning():
	
	if !is_audio_node(self) && !is_audio_node(get_child(0)):
		return "Ce noeud ou son premier enfant doit être un noeud AudioStreamPlayer"
	return ""

func get_class(): return "AudioEvent"
