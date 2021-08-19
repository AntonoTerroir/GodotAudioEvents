tool

extends AudioModifier
class_name StartDelay

enum delay_modes {FIRST_TIME_ONLY, EVERYTIME}
export(delay_modes) var delay_mode

export var duration = 0.0

func apply(event: AudioEvent):
	yield(event.get_tree().create_timer(duration), "timeout")
	return

func get_duration():
	return duration

func set_duration(time:float):
	duration = time



func _get_configuration_warning():
	if duration < 0:
		return "Delay duration must be greater than or equal to 0"
	return ""
