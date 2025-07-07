extends Node

# Referencias a nodos UI
var main_container: VBoxContainer
var result_container: VBoxContainer

# Referencia al chat existente
var chat_system: Node

# Variables para el resultado
var victory_data: Dictionary = {}

func _ready():
	print("🏆 Pantalla de victoria cargada")
	
	# Conectar señales del WebSocketManager si existe
	if WebSocketManager:
		WebSocketManager.connect("rematch_requested", _on_rematch_requested)
		WebSocketManager.connect("match_quit", _on_match_quit)
		WebSocketManager.connect("match_ready", _on_players_ready_rematch)
		WebSocketManager.set_game_state("POST_GAME")
	
	create_ui()

func create_ui():
	print("🎨 Creando UI de victoria...")
	
	# Fondo principal
	var bg = ColorRect.new()
	bg.color = Color(0, 0.1, 0, 0.8)  # Fondo verde oscuro semi-transparente
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
	
	# Título de victoria
	var victory_title = Label.new()
	victory_title.text = "🏆 ¡VICTORIA!"
	victory_title.add_theme_font_size_override("font_size", 36)
	victory_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_title.modulate = Color.GOLD
	result_container.add_child(victory_title)
	
	# Subtítulo
	var subtitle = Label.new()
	subtitle.name = "SubtitleLabel"
	subtitle.text = "¡Has ganado la partida!"
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color.LIGHT_GREEN
	result_container.add_child(subtitle)
	
	# Información adicional (aquí agregas tus botones)
	var info_container = VBoxContainer.new()
	info_container.add_theme_constant_override("separation", 10)
	result_container.add_child(info_container)
	
	# Crear botones de acción
	create_action_buttons(info_container)
	
	print("✅ UI de victoria creada")

func create_action_buttons(container: VBoxContainer):
	# Contenedor horizontal para botones
	var button_container = HBoxContainer.new()
	button_container.name = "ButtonContainer"
	button_container.add_theme_constant_override("separation", 15)
	container.add_child(button_container)
	
	# Botón de revancha
	var rematch_button = Button.new()
	rematch_button.name = "RematchButton"
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
	quit_button.name = "QuitButton"
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

# === FUNCIONES DE EVENTOS DE REVANCHA ===

func _on_rematch_button_pressed():
	print("🔄 Enviando solicitud de revancha...")
	
	if WebSocketManager:
		# Enviar send-rematch-request según la documentación
		WebSocketManager.send_rematch_request()
	
	# Actualizar UI
	update_status("⏳ Solicitud de revancha enviada. Esperando respuesta...", Color.ORANGE)
	disable_rematch_button()
	
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
	# El oponente solicita revancha (evento rematch-request recibido)
	print("🔄 El oponente solicita revancha")
	
	update_status("🔄 ¡El oponente quiere revancha! Presiona 'REVANCHA' para aceptar", Color.GREEN)
	enable_rematch_button()
	
	# Cambiar texto del botón para indicar que es para aceptar
	var rematch_button = get_node_or_null("VBoxContainer/VBoxContainer/VBoxContainer/ButtonContainer/RematchButton")
	if rematch_button:
		rematch_button.text = "✅ ACEPTAR REVANCHA"
	
	# Notificar en el chat
	if chat_system and chat_system.has_method("add_chat_message"):
		chat_system.add_chat_message("Sistema", "🔄 El otro jugador solicita revancha")

func _on_players_ready_rematch(data: Dictionary):
	# Ambos jugadores aceptaron la revancha (evento players-ready recibido)
	print("🎯 Ambos jugadores listos para revancha")
	
	update_status("🎯 ¡Revancha aceptada! Preparando partida...", Color.CYAN)
	disable_all_buttons()
	
	# Según la documentación, ahora debemos enviar ping-match
	if WebSocketManager:
		WebSocketManager.ping_match()

func _on_match_quit(data: Dictionary):
	# El oponente salió (evento close-match recibido)
	print("🚪 El oponente abandonó la partida")
	
	update_status("🚪 El oponente abandonó. No es posible la revancha", Color.RED)
	disable_rematch_button()
	
	if chat_system and chat_system.has_method("add_chat_message"):
		chat_system.add_chat_message("Sistema", "🚪 El oponente abandonó la partida")
	
	await get_tree().create_timer(3.0).timeout
	
	# Volver al menú principal
	var main_menu = load("res://Escenas/main_menu.tscn")
	if main_menu:
		get_tree().change_scene_to_packed(main_menu)
	else:
		print("⚠️ No se encontró main_menu.tscn")

# === FUNCIONES DE UTILIDAD ===

func update_status(text: String, color: Color):
	var status_label = get_node_or_null("VBoxContainer/VBoxContainer/VBoxContainer/StatusLabel")
	if status_label:
		status_label.text = text
		status_label.modulate = color

func disable_rematch_button():
	var rematch_button = get_node_or_null("VBoxContainer/VBoxContainer/VBoxContainer/ButtonContainer/RematchButton")
	if rematch_button:
		rematch_button.disabled = true

func enable_rematch_button():
	var rematch_button = get_node_or_null("VBoxContainer/VBoxContainer/VBoxContainer/ButtonContainer/RematchButton")
	if rematch_button:
		rematch_button.disabled = false

func disable_all_buttons():
	var rematch_button = get_node_or_null("VBoxContainer/VBoxContainer/VBoxContainer/ButtonContainer/RematchButton")
	var quit_button = get_node_or_null("VBoxContainer/VBoxContainer/VBoxContainer/ButtonContainer/QuitButton")
	
	if rematch_button:
		rematch_button.disabled = true
	if quit_button:
		quit_button.disabled = true

func set_victory_data(data: Dictionary):
	victory_data = data
	
	# Actualizar información de victoria si es necesaria
	var subtitle = get_node_or_null("VBoxContainer/VBoxContainer/SubtitleLabel")
	if subtitle:
		var score = data.get("final_score", 0)
		var reason = data.get("reason", "")
		
		if score > 0:
			subtitle.text = "¡Ganaste con " + str(score) + " puntos!"
		elif reason != "":
			subtitle.text = "Ganaste: " + reason
		else:
			subtitle.text = "¡Has ganado la partida!"

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
	print("🧹 Limpiando pantalla de victoria...")
	
