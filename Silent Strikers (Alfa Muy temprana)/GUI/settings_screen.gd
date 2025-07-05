extends Control
	
func _on_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, value)


func _on_resolution_selected(index: int) -> void:
	var resolutions = [
		Vector2i(1152, 768),
		Vector2i(1280, 720),
		Vector2i(1920, 1080)
	]

	if index >= 0 and index < resolutions.size():
		DisplayServer.window_set_size(resolutions[index])
