tool

extends AudioModifier

class_name PitchModulation

enum pitch_modes {RANDOM_PITCH, PITCH_STEPS}
export(pitch_modes) var pitchMode

export(float, 0.01, 4) var minPitch = 1.00 setget set_min_pitch, get_min_pitch
export(float, 0.01, 4) var maxPitch = 1.00 setget set_max_pitch, get_max_pitch

func apply(event: AudioEvent):
	var randomPitch = get_random_pitch()
	event.pitch_scale = event.pitch_scale * randomPitch
	return

# RANDOM PITCH MODE
func get_min_pitch():
	return minPitch
	
func set_min_pitch(value):
	minPitch = value

func get_max_pitch():
	return maxPitch
	
func set_max_pitch(value):
	maxPitch = value

# PITCH STEPS MODE
export(Array, float, 0.01, 4) var pitch_steps = []

func get_random_pitch():
	var randomPitch
	if (pitchMode == 0):
		randomPitch = rand_range(minPitch, maxPitch)
	elif (pitchMode == 1):
		var randomPitchStep
		randomPitchStep = randi()%pitch_steps.size
		randomPitch = pitch_steps[randomPitchStep]
	
	return randomPitch

func _get_configuration_warning():
	if maxPitch < minPitch:
		return "Max Pitch must be greater than or equal to Min Pitch"
	return ""
