extends Control

# Referencias a los controles
@onready var volume_slider: HSlider
@onready var resolution_option: OptionButton
@onready var back_button: Button
@onready var fullscreen_check: CheckBox

func _ready():
	setup_volume_slider()
	setup_resolution_options()
	setup_fullscreen_option()
	setup_back_button()

func setup_volume_slider():
	if volume_slider:
		volume_slider.min_value = -30.0
		volume_slider.max_value = 6.0
		volume_slider.step = 0.1
		var current_volume = AudioServer.get_bus_volume_db(0)
		volume_slider.value = current_volume

func setup_resolution_options():
	if resolution_option:
		resolution_option.clear()
		resolution_option.add_item("1152 x 768")
		resolution_option.add_item("1280 x 720 (HD)")
		resolution_option.add_item("1920 x 1080 (Full HD)")
		
		var current_size = DisplayServer.window_get_size()
		match current_size:
			Vector2i(1152, 768):
				resolution_option.selected = 0
			Vector2i(1280, 720):
				resolution_option.selected = 1
			Vector2i(1920, 1080):
				resolution_option.selected = 2

func setup_fullscreen_option():
	if fullscreen_check:
		fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

func setup_back_button():
	if back_button:
		back_button.pressed.connect(_on_back_button_pressed)

func _on_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, value)

func _on_resolution_selected(index: int) -> void:
	var resolutions = [
		Vector2i(1152, 768),
		Vector2i(1280, 720),
		Vector2i(1920, 1080)
	]

	if index >= 0 and index < resolutions.size():
		var new_resolution = resolutions[index]
		DisplayServer.window_set_size(new_resolution)
		
		# Centrar ventana
		var screen_size = DisplayServer.screen_get_size()
		var window_pos = (screen_size - new_resolution) / 2
		DisplayServer.window_set_position(window_pos)

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_back_button_pressed() -> void:
	var main_menu = load("res://Escenas/main_menu.tscn")
	get_tree().change_scene_to_packed(main_menu)
