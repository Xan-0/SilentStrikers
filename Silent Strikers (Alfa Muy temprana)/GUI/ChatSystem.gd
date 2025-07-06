extends Node

# Referencias a nodos UI
var chat_ui: Control
var chat_messages: VBoxContainer
var message_input: LineEdit
var send_button: Button
var chat_toggle: Button


# Configuración del chat
var max_messages = 50
var chat_visible = true

func _ready():
	print("=== Iniciando sistema de chat ===")
	# Usar call_deferred para evitar el error de nodo ocupado
	call_deferred("create_chat_ui")

func create_chat_ui():
	print("Creando UI del chat...")
	
	# Obtener la escena actual para agregar UI
	var main_scene = get_tree().current_scene
	
	# Crear CanvasLayer para UI usando call_deferred
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "ChatLayer"
	main_scene.call_deferred("add_child", canvas_layer)
	
	# Esperar un frame para que el CanvasLayer se agregue
	await get_tree().process_frame
	
	# Ahora crear el resto de la UI
	setup_chat_interface(canvas_layer)

func setup_chat_interface(canvas_layer: CanvasLayer):
	print("Configurando interfaz del chat...")
	
	# === CONTENEDOR PRINCIPAL DEL CHAT ===
	chat_ui = Control.new()
	chat_ui.name = "ChatUI"
	# Posición fija en la esquina inferior izquierda
	chat_ui.position = Vector2(25, 120)  # Posición visible
	chat_ui.size = Vector2(400, 500)
	canvas_layer.add_child(chat_ui)
	
	# Fondo del chat
	var bg_panel = Panel.new()
	bg_panel.position = Vector2.ZERO
	bg_panel.size = chat_ui.size
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0, 0, 0, 0.8)  # Fondo negro semi-transparente
	style_box.corner_radius_top_left = 5
	style_box.corner_radius_top_right = 5
	bg_panel.add_theme_stylebox_override("panel", style_box)
	chat_ui.add_child(bg_panel)
	
	# === ÁREA DE MENSAJES ===
	var scroll_container = ScrollContainer.new()
	scroll_container.position = Vector2(5, 5)
	scroll_container.size = Vector2(390, 445)
	chat_ui.add_child(scroll_container)
	
	chat_messages = VBoxContainer.new()
	chat_messages.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_container.add_child(chat_messages)
	
	# === ÁREA DE INPUT (OCUPA TODA LA PARTE INFERIOR) ===
	var input_container = HBoxContainer.new()
	input_container.position = Vector2(5, 445)  # Posición en la parte inferior
	input_container.size = Vector2(390, 50)  # Altura aumentada y ancho completo
	chat_ui.add_child(input_container)
	
	# Input de texto (ocupa la mayoría del ancho)
	message_input = LineEdit.new()
	message_input.placeholder_text = "Escribe tu mensaje..."
	message_input.size = Vector2(300, 50)  # Más ancho y alto
	message_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # Se expande para llenar el espacio
	input_container.add_child(message_input)
	
	# Botón enviar
	send_button = Button.new()
	send_button.text = "Enviar"
	send_button.size = Vector2(80, 40)
	input_container.add_child(send_button)
	
	print("UI del chat creada en posición: ", chat_ui.position)
	
	# Conectar señales después de crear la UI
	connect_signals()
	
	# Agregar mensaje de bienvenida
	add_system_message("Chat iniciado. ¡Bienvenido!")
	print("=== Chat listo ===")

func get_safe_timestamp() -> String:
	var datetime_dict = Time.get_datetime_dict_from_system()
	var hour = str(datetime_dict.hour).pad_zeros(2)
	var minute = str(datetime_dict.minute).pad_zeros(2)
	return hour + ":" + minute

func connect_signals():
	print("Conectando señales...")
	
	if message_input:
		message_input.text_submitted.connect(_on_message_submitted)
		print("✓ Signal text_submitted conectada")
	
	if send_button:
		send_button.pressed.connect(_on_send_button_pressed)
		print("✓ Signal send_button conectada")
	
	if chat_toggle:
		chat_toggle.pressed.connect(_on_chat_toggle_pressed)
		print("✓ Signal chat_toggle conectada")

func _on_message_submitted(text: String):
	print("Mensaje enviado por Enter: ", text)
	send_chat_message("Yo", text)

func _on_send_button_pressed():
	print("Botón enviar presionado")
	send_chat_message("Yo",message_input.text)

func _on_chat_toggle_pressed():
	print("Toggle chat presionado")
	toggle_chat_visibility()

func send_chat_message(sender: String, text: String):
	if text.strip_edges() == "":
		print("Mensaje vacío, ignorando")
		return
	
	print("Procesando mensaje: ", text)
	
	# Verificar si es un comando
	if text.begins_with("/"):
		handle_chat_command(text)
	else:
		if sender == "Yo":
			add_chat_message("Tú", text)
		else:
			add_chat_message(sender, text)
		
		# Enviar al servidor si está conectado
		WebSocketManager.send_public_message(text)
		print("Mensaje enviado al servidor")
	# Limpiar input
	message_input.text = ""

func handle_chat_command(command: String):
	var parts = command.split(" ", false, 1)
	var cmd = parts[0].to_lower()
	
	print("Ejecutando comando: ", cmd)
	
	match cmd:
		"/help":
			add_system_message("=== Comandos disponibles ===")
			add_system_message("/help - Mostrar ayuda")
			add_system_message("/clear - Limpiar chat")
			add_system_message("/test - Mensaje de prueba")
			add_system_message("/toggle - Mostrar/ocultar chat")
		"/clear":
			clear_chat()
		"/players", "/refresh":
			if WebSocketManager and WebSocketManager.has_method("request_online_players"):
				WebSocketManager.request_online_players()
				add_chat_message("Sistema", "🔄 Actualizando lista de jugadores...")
		"/test":
			add_chat_message("Sistema", "¡Este es un mensaje de prueba!")
		"/toggle":
			toggle_chat_visibility()
		_:
			add_system_message("Comando desconocido: " + cmd)

func clear_chat():
	print("Limpiando chat...")
	if chat_messages:
		for child in chat_messages.get_children():
			child.queue_free()
	add_system_message("Chat limpiado")

func toggle_chat_visibility():
	chat_visible = !chat_visible
	
	if chat_ui:
		chat_ui.visible = chat_visible
		print("Chat visible: ", chat_visible)
	
	if chat_toggle:
		chat_toggle.text = "Mostrar" if not chat_visible else "Ocultar"

func add_chat_message(sender: String, message: String):
	if not chat_messages:
		print("Error: chat_messages no existe aún")
		return
	
	var timestamp = get_safe_timestamp()
	var label = Label.new()
	label.text = "[" + timestamp + "] " + sender + ": " + message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size.y = 20
	if sender == "Sistema":
		label.modulate = Color.DARK_ORCHID
	elif sender == "Tú":
		label.modulate = Color.CADET_BLUE
	else:
		label.modulate = Color.WHITE
	
	chat_messages.add_child(label)
	if chat_messages.get_child_count() > 30:
		chat_messages.get_child(0).queue_free()
	print("Mensaje agregado: ", label.text)

	# Limitar mensajes
	if chat_messages.get_child_count() > max_messages:
		chat_messages.get_child(0).queue_free()
	
	# Scroll al final
	call_deferred("scroll_to_bottom")

func add_system_message(message: String):
	add_chat_message("Sistema", message)

func scroll_to_bottom():
	if not chat_messages:
		return
		
	# Buscar el ScrollContainer padre de chat_messages
	var scroll_container = chat_messages.get_parent()
	if scroll_container is ScrollContainer:
		await get_tree().process_frame
		var scrollbar = scroll_container.get_v_scroll_bar()
		if scrollbar:
			scroll_container.scroll_vertical = int(scrollbar.max_value)

# Funciones para el WebSocketManager

func on_player_joined_chat(player_name: String):
	add_system_message(player_name + " se unió al juego")

func on_player_left_chat(player_name: String):
	add_system_message(player_name + " dejó el juego")
	
func on_message_received(sender: String, message: String):
	add_chat_message(sender, message)

func _input(event):
	# Atajo de teclado para mostrar/ocultar chat (opcional)
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F1:  # F1 para toggle chat
			toggle_chat_visibility()
		elif event.keycode == KEY_ENTER and message_input and not message_input.has_focus():
			# Enter para enfocar el chat
			if chat_visible and message_input:
				message_input.grab_focus()

func _exit_tree():
	print("Limpiando chat system...")
	if chat_ui and chat_ui.get_parent():
		chat_ui.get_parent().queue_free()  # Eliminar todo el CanvasLayer
