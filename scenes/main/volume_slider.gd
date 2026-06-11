extends HSlider

@onready var master_bus := AudioServer.get_bus_index("Master")

func _ready():
	value_changed.connect(_on_value_changed)

	# IMPORTANT: sync with global value
	value = AudioSettings.master_volume
	_apply(value)

func _on_value_changed(value: float):
	AudioSettings.master_volume = value
	_apply(value)

func _apply(value: float):
	if value <= 0.001:
		AudioServer.set_bus_mute(master_bus, true)
	else:
		AudioServer.set_bus_mute(master_bus, false)
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(value))
