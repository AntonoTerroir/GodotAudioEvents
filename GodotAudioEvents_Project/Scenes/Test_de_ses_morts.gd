extends Node

var switch_event

func _ready():
	switch_event = $SwitchAudioEvent

func set_switch(id: int):
	switch_event.set_switch(id)
	
func play_switch_event():
	switch_event.play()


func _on_Button4_pressed():
	set_switch(1)


func _on_Button5_pressed():
	play_switch_event()
