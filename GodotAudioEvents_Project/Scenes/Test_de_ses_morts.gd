extends Node

var switch_event
var blend_event
var random_event
var sequence_event

func _ready():
	switch_event = $SwitchAudioEvent
	blend_event = $FootStep
	random_event = $RandomAudioEvent
	sequence_event = $SequenceAudioEvent

func set_switch(id: int):
	switch_event.set_switch(id)
	$FootStep/Surface_Type_Switch.set_switch(id)
	
func play_switch_event():
	switch_event.play()
	
func stop_switch_event():
	switch_event.stop()
	
func play_blend_event():
	blend_event.play()
	
func stop_blend_event():
	blend_event.stop()
	
func play_random_event():
	random_event.play()

func stop_random_event():
	random_event.stop()

func play_sequence_event():
	sequence_event.play()
	
func stop_sequence_event():
	sequence_event.stop()

func _on_HSlider_value_changed(value):
	$UI/SwitchUI/HSlider/SwitchText.set_text(String(value))
	set_switch(value)

func _on_SwitchPlayButton_pressed():
	play_switch_event()

func _on_SequencePlayButton_pressed():
	play_sequence_event()

func _on_SequenceStopButton_pressed():
	stop_sequence_event()


func _on_RandomPlayButton_pressed():
	play_random_event()

func _on_RandomPlayButton2_pressed():
	stop_random_event()

func _on_BlendPlayButton_pressed():
	play_blend_event()

func _on_BlendStopButton_pressed():
	stop_blend_event()

func _on_SwitchStopButton_pressed():
	stop_switch_event()

func _on_VolumeSlider_value_changed(value):
	$UI/VolumeControlUI/VolumeSlider/VolText.set_text(String(value))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), value)


func _on_BlendPauseButton_pressed():
	blend_event.pause()
	


func _on_BlendResumeButton_pressed():
	blend_event.resume()


func _on_RandomPauseButton_pressed():
	random_event.pause()


func _on_RandomResumeButton_pressed():
	random_event.resume()
