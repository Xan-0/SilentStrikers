extends Node

# Referencias a nodos UI
var main_container: VBoxContainer
var result_container: VBoxContainer

# Referencia al chat existente
var chat_system: Node

# Variables para el resultado
var defeat_data: Dictionary = {}

func _ready():
	print("💀 Pantalla de derrota cargada")
	
	# Conectar señales del WebSocketManager si existe
	if WebSocketManager:
		WebSocketManager.connect("rematch_requested", _on_rematch_requested)
		WebSocketManager.connect("match_quit", _on_match_quit)
		WebSocketManager.set_game_state("POST_GAME")
	
	create_ui()

func create_ui():
	print("🎨 Creando UI de derrota...")
	
	# Fondo principal
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.8)  # Fondo oscuro semi-transparente
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Contenedor principal centrado
	main_container = VBoxContainer.new()
	main_container.set_anchors_preset(Control.PRESET_CENTER)
	main_container.position = Vector2(0, -150)
	main_container.add_theme_constant_override("separation", 20)
	add_child(main_container)
	
	# === SECCIÓN DE RESULTADO ===
	result_container = VBoxContainer.new()
	result_container.add_theme_constant_override("separation", 15)
	main_container.add_child(result_container)
	
	# Título de derrota
	var defeat_title = Label.new()
	defeat_title.text = "💀 DERROTA"
	defeat_title.add_theme_font_size_override("font_size", 36)
	defeat_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	defeat_title.modulate = Color.RED
	result_container.add_child(defeat_title)
	
	# Subtítulo
	var subtitle = Label.new()
	subtitle.text = "Has perdido la partida"
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color.LIGHT_GRAY
	result_container.add_child(subtitle)
	
	# Información adicional (aquí agregas tus botones)
	var info_container = VBoxContainer.new()
	info_container.add_theme_constant_override("separation", 10)
	result_container.add_child(info_container)
	
	# Crear botones de acción
	create_action_buttons(info_container)
	
	print("✅ UI de derrota creada")

func create_action_buttons(container: VBoxContainer):
	# Contenedor horizontal para botones
	var button_container = HBoxContainer.new()
	button_container.add_theme_constant_override("separation", 15)
	container.add_child(button_container)
	
	# Botón de revancha
	var rematch_button = Button.new()
	rematch_button.text = "🔄 REVANCHA"
	rematch_button.custom_minimum_size = Vector2(150, 50)
	rematch_button.add_theme_font_size_override("font_size", 14)
	
	var rematch_style = StyleBoxFlat.new()
	rematch_style.bg_color = Color(0.2, 0.6, 0.2, 0.8)  # Verde
	rematch_style.corner_radius_top_left = 8
	rematch_style.corner_radius_top_right = 8
	rematch_style.corner_radius_bottom_left = 8
	rematch_style.corner_radius_bottom_right = 8
	rematch_button.add_theme_stylebox_override("normal", rematch_style)
	
	rematch_button.pressed.connect(_on_rematch_button_pressed)
	button_container.add_child(rematch_button)
	
	# Botón salir
	var quit_button = Button.new()
	quit_button.text = "🚪 SALIR"
	quit_button.custom_minimum_size = Vector2(150, 50)
	quit_button.add_theme_font_size_override("font_size", 14)
	
	var quit_style = StyleBoxFlat.new()
	quit_style.bg_color = Color(0.6, 0.2, 0.2, 0.8)  # Rojo
	quit_style.corner_radius_top_left = 8
	quit_style.corner_radius_top_right = 8
	quit_style.corner_radius_bottom_left = 8
	quit_style.corner_radius_bottom_right = 8
	quit_button.add_theme_stylebox_override("normal", quit_style)
	
	quit_button.pressed.connect(_on_quit_button_pressed)
	button_container.add_child(quit_button)
	
	# Espacio
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 20
	container.add_child(spacer)
	
	# Label de estado
	var status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "¿Qué quieres hacer?"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.modulate = Color.YELLOW
	container.add_child(status_label)

# === FUNCIONES DE EVENTOS ===


func _on_rematch_button_pressed():
	print("🔄 Solicitando revancha...")
	
	if WebSocketManager:
		WebSocketManager.send_rematch_request()
	
	# Actualizar UI
	var status_label = get_node_or_null("VBoxContainer/VBoxContainer/VBoxContainer/StatusLabel")
	if status_label:
		status_label.text = "⏳ Esperando respuesta de revancha..."
		status_label.modulate = Color.ORANGE
	
	# Notificar en el chat
	if chat_system and chat_system.has_method("add_chat_message"):
		chat_system.add_chat_message("Sistema", "🔄 Solicitaste una revancha")

func _on_quit_button_pressed():
	print("🚪 Saliendo de la partida...")
	
	if WebSocketManager:
		WebSocketManager.quit_match()
	
	if chat_system and chat_system.has_method("add_chat_message"):
		chat_system.add_chat_message("Sistema", "🚪 Saliendo de la partida...")

func _on_rematch_requested(data: Dictionary):
	print("🔄 El otro jugador solicita revancha")
	
	var status_label = get_node_or_null("VBoxContainer/VBoxContainer/VBoxContainer/StatusLabel")
	if status_label:
		status_label.text = "🔄 ¡El otro jugador quiere revancha!"
		status_label.modulate = Color.GREEN
	
	# Notificar en el chat
	if chat_system and chat_system.has_method("add_chat_message"):
		chat_system.add_chat_message("Sistema", "🔄 El otro jugador solicita revancha")


func _on_match_quit(data: Dictionary):
	print("🚪 Volviendo al lobby")
	
	if chat_system and chat_system.has_method("add_chat_message"):
		chat_system.add_chat_message("Sistema", "🚪 Volviendo al lobby...")
	
	await get_tree().create_timer(1.5).timeout
	
	var lobby = load("res://Escenas/main_menu.tscn")
	if lobby:
		get_tree().change_scene_to_packed(lobby)
	else:
		print("⚠️ No se encontró main_menu.tscn")

func set_defeat_data(data: Dictionary):
	defeat_data = data
	
	# Actualizar información de derrota si es necesaria
	var subtitle = get_node_or_null("VBoxContainer/VBoxContainer/Label")
	if subtitle:
		var reason = data.get("reason", "Motivo desconocido")
		subtitle.text = "Razón: " + reason

func _input(event):
	# Atajos de teclado
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				_on_quit_button_pressed()
			KEY_R:
				if event.ctrl_pressed:  # Ctrl+R para revancha
					_on_rematch_button_pressed()

func _exit_tree():
	print("🧹 Limpiando pantalla de derrota...")
	
