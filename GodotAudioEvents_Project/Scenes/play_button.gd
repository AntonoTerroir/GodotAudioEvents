extends Button

signal play_button_pressed

func _ready():
	connect("pressed", self, "_on_button_pressed")
	
func _on_button_pressed():
	emit_signal("play_button_pressed")
