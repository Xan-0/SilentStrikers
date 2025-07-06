extends Node

# Referencias a nodos UI
var player_list_ui: Control
var player_list_container: VBoxContainer
var refresh_button: Button
var title_label: Label

# Referencia al WebSocket manager
@onready var websocket_manager = get_node("../Node")

# Datos
var my_player_data = {}
var current_players = []
var player_items = {}
var pending_requests = {}

# Configuración
var status_colors = {
	"AVAILABLE": Color.GREEN,
	"BUSY": Color.YELLOW,
	"IN_MATCH": Color.RED
}

var status_icons = {
	"AVAILABLE": "●",
	"BUSY": "◐",
	"IN_MATCH": "◆"
}

func _ready():
	await get_tree().process_frame
	await get_tree().process_frame
	create_player_list_ui()
	_ready_auto_refresh()  # Llamar aquí para iniciar el auto-refresh

func create_player_list_ui():
	print("👥 Creando UI de lista de jugadores...")
	
	# Buscar o crear CanvasLayer
	var ui_layer = get_tree().current_scene.get_node_or_null("UI")
	if not ui_layer:
		ui_layer = CanvasLayer.new()
		ui_layer.name = "UI"
		get_tree().current_scene.add_child(ui_layer)
		await get_tree().process_frame
	
	# Contenedor principal (lado derecho de la pantalla)
	player_list_ui = Control.new()
	player_list_ui.name = "PlayerListUI"
	player_list_ui.size = Vector2(300, 400)
	player_list_ui.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	player_list_ui.position = Vector2(-450, 120)
	ui_layer.add_child(player_list_ui)
	
	# Fondo
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	bg.size = player_list_ui.size
	bg.z_index = -1
	player_list_ui.add_child(bg)
	
	# Título
	title_label = Label.new()
	title_label.text = "👥 Jugadores Online (0)"
	title_label.position = Vector2(10, 5)
	title_label.size = Vector2(280, 25)
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.modulate = Color.CYAN
	player_list_ui.add_child(title_label)
	
	# Botón refresh
	refresh_button = Button.new()
	refresh_button.text = "🔄"
	refresh_button.position = Vector2(260, 5)
	refresh_button.size = Vector2(30, 25)
	refresh_button.pressed.connect(_on_refresh_pressed)
	player_list_ui.add_child(refresh_button)
	
	# Área de scroll para la lista
	var scroll_container = ScrollContainer.new()
	scroll_container.position = Vector2(5, 35)
	scroll_container.size = Vector2(290, 360)
	player_list_ui.add_child(scroll_container)
	
	# Contenedor de jugadores
	player_list_container = VBoxContainer.new()
	player_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_list_container.add_theme_constant_override("separation", 5)
	scroll_container.add_child(player_list_container)
	
	print("✅ UI de lista de jugadores creada")

func _on_refresh_pressed():
	print("🔄 Actualizando lista de jugadores manualmente...")
	request_online_players()

# NUEVA FUNCIÓN: Función centralizada para solicitar jugadores
func request_online_players():
	if websocket_manager and websocket_manager.has_method("request_online_players"):
		websocket_manager.request_online_players()
	else:
		print("⚠️ No se puede actualizar: WebSocket no disponible")

func set_my_player_data(data: Dictionary):
	my_player_data = data
	print("🆔 Datos del jugador establecidos: ", data.get("name", ""))

func update_player_list(players_data: Array):
	
	current_players = players_data
	
	# Guardar solicitudes pendientes antes de limpiar
	var temp_pending = pending_requests.duplicate()
	
	# Limpiar lista actual
	for child in player_list_container.get_children():
		child.queue_free()
	
	player_items.clear()
	
	# Actualizar título
	title_label.text = "👥 Jugadores Online (" + str(players_data.size()) + ")"
	
	# Agregar cada jugador
	for player_data in players_data:
		create_player_item(player_data)
	
	# Restaurar solicitudes pendientes si aún existen
	for player_id in temp_pending.keys():
		if player_items.has(player_id):
			var request_data = temp_pending[player_id]
			show_match_request_internal(request_data.player_name, player_id, request_data.match_id, false)

func create_player_item(player_data: Dictionary):
	var player_id = player_data.get("id", "")
	var player_name = player_data.get("name", "Desconocido")
	var player_status = player_data.get("status", "AVAILABLE")
	var game_data = player_data.get("game", {})
	var game_name = game_data.get("name", "Sin juego")
	
	# Contenedor del jugador
	var player_item = Control.new()
	player_item.custom_minimum_size.y = 70
	player_item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_item.name = "PlayerItem_" + player_id
	
	# Guardar referencia
	player_items[player_id] = player_item
	
	# Fondo del item
	var item_bg = ColorRect.new()
	item_bg.size = Vector2(280, 65)
	item_bg.color = Color(0.2, 0.2, 0.2, 0.5)
	item_bg.name = "ItemBg"
	
	# Destacar si soy yo
	if player_id == my_player_data.get("id", ""):
		item_bg.color = Color(0.2, 0.4, 0.6, 0.7)  # Azul para el jugador actual
	
	player_item.add_child(item_bg)
	
	# Icono de estado
	var status_icon = Label.new()
	status_icon.text = status_icons.get(player_status, "●")
	status_icon.position = Vector2(10, 5)
	status_icon.size = Vector2(20, 20)
	status_icon.modulate = status_colors.get(player_status, Color.WHITE)
	status_icon.add_theme_font_size_override("font_size", 16)
	status_icon.name = "StatusIcon"
	player_item.add_child(status_icon)
	
	# Nombre del jugador
	var name_label = Label.new()
	name_label.text = player_name
	if player_id == my_player_data.get("id", ""):
		name_label.text += " (Tú)"
	name_label.position = Vector2(35, 5)
	name_label.size = Vector2(200, 20)
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.modulate = Color.WHITE
	name_label.name = "NameLabel"
	player_item.add_child(name_label)
	
	# Estado del jugador
	var status_label = Label.new()
	status_label.text = get_status_text(player_status)
	status_label.position = Vector2(35, 20)
	status_label.size = Vector2(150, 15)
	status_label.add_theme_font_size_override("font_size", 10)
	status_label.modulate = status_colors.get(player_status, Color.GRAY)
	status_label.name = "StatusLabel"
	player_item.add_child(status_label)
	
	# Juego actual
	var game_label = Label.new()
	game_label.text = "🎮 " + game_name
	game_label.position = Vector2(35, 35)
	game_label.size = Vector2(200, 15)
	game_label.add_theme_font_size_override("font_size", 9)
	game_label.modulate = Color.LIGHT_GRAY
	game_label.name = "GameLabel"
	player_item.add_child(game_label)
	
	# Contenedor de botones de aceptar/declinar (oculto por defecto)
	var button_container = HBoxContainer.new()
	button_container.position = Vector2(200, 25)
	button_container.size = Vector2(70, 30)
	button_container.add_theme_constant_override("separation", 5)
	button_container.visible = false
	button_container.name = "ButtonContainer"
	player_item.add_child(button_container)
	
	# Botón aceptar (✅)
	var accept_button = Button.new()
	accept_button.text = "✅"
	accept_button.custom_minimum_size = Vector2(30, 30)
	accept_button.add_theme_font_size_override("font_size", 14)
	var accept_style = StyleBoxFlat.new()
	accept_style.bg_color = Color.GREEN
	accept_style.corner_radius_top_left = 5
	accept_style.corner_radius_top_right = 5
	accept_style.corner_radius_bottom_left = 5
	accept_style.corner_radius_bottom_right = 5
	accept_button.add_theme_stylebox_override("normal", accept_style)
	accept_button.pressed.connect(_on_accept_match_request.bind(player_id))
	accept_button.name = "AcceptButton"
	button_container.add_child(accept_button)
	
	# Botón declinar (❌)
	var decline_button = Button.new()
	decline_button.text = "❌"
	decline_button.custom_minimum_size = Vector2(30, 30)
	decline_button.add_theme_font_size_override("font_size", 14)
	var decline_style = StyleBoxFlat.new()
	decline_style.bg_color = Color.RED
	decline_style.corner_radius_top_left = 5
	decline_style.corner_radius_top_right = 5
	decline_style.corner_radius_bottom_left = 5
	decline_style.corner_radius_bottom_right = 5
	decline_button.add_theme_stylebox_override("normal", decline_style)
	decline_button.pressed.connect(_on_decline_match_request.bind(player_id))
	decline_button.name = "DeclineButton"
	button_container.add_child(decline_button)
	
	# Botón de desafío (solo para otros jugadores disponibles)
	if player_id != my_player_data.get("id", "") and player_status == "AVAILABLE":
		var action_button = Button.new()
		action_button.text = "⚔️"
		action_button.position = Vector2(245, 25)
		action_button.size = Vector2(25, 25)
		action_button.pressed.connect(_on_challenge_player.bind(player_data))
		action_button.name = "ChallengeButton"
		player_item.add_child(action_button)
	
	player_list_container.add_child(player_item)

func get_status_text(status: String) -> String:
	match status:
		"AVAILABLE":
			return "Disponible"
		"BUSY":
			return "Ocupado"
		"IN_MATCH":
			return "En partida"
		_:
			return "Desconocido"

func _on_challenge_player(player_data: Dictionary):
	var player_name = player_data.get("name", "")
	print("⚔️ Desafiando a jugador: ", player_name)
	
	# Enviar desafío
	var body_challenge = {
		"event": "send-match-request",
		"data": {
			"playerId": player_data.get("id"),
		}
	}
	websocket_manager.send_message(body_challenge)
	
	# Notificar en chat
	var chat_system = get_node_or_null("../ChatSystem")
	if chat_system:
		chat_system.add_chat_message("Sistema", "🎯 Desafiando a " + player_name + "...")
	
	# ACTUALIZAR LA LISTA inmediatamente después de enviar el desafío
	print("🔄 Actualizando lista después de enviar desafío...")
	call_deferred("request_online_players")

func _ready_auto_refresh():
	var timer = Timer.new()
	timer.wait_time = 2.0  # Cada 5 segundos en lugar de 1
	timer.timeout.connect(_on_auto_refresh)
	timer.autostart = true
	add_child(timer)
	print("⏰ Auto-refresh configurado cada 5 segundos")

func show_match_request(player_name: String, player_id: String, match_id: String):
	show_match_request_internal(player_name, player_id, match_id, true)

# FUNCIÓN INTERNA: Mostrar solicitud con opción de notificar
func show_match_request_internal(player_name: String, player_id: String, match_id: String, notify_chat: bool = true):
	print("🎯 Mostrando solicitud de partida de: ", player_name, " (ID: ", player_id, ")")
	
	# Guardar datos de la solicitud
	pending_requests[player_id] = {
		"player_name": player_name,
		"match_id": match_id,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	# Buscar el item del jugador en la lista
	var player_item = player_items.get(player_id)
	if not player_item:
		print("⚠️ No se encontró el item del jugador en la lista")
		return
	
	# Obtener el contenedor de botones
	var button_container = player_item.get_node_or_null("ButtonContainer")
	if not button_container:
		print("⚠️ No se encontró el contenedor de botones")
		return
	
	# Mostrar los botones de aceptar/declinar
	button_container.visible = true
	
	# Ocultar el botón de desafío si existe
	var challenge_button = player_item.get_node_or_null("ChallengeButton")
	if challenge_button:
		challenge_button.visible = false
	
	# Cambiar el fondo para destacar la solicitud
	var item_bg = player_item.get_node_or_null("ItemBg")
	if item_bg:
		item_bg.color = Color(0.6, 0.3, 0.1, 0.8)  # Naranja para solicitud pendiente
	
	# Actualizar el estado en el label
	var status_label = player_item.get_node_or_null("StatusLabel")
	if status_label:
		status_label.text = "¡Te ha desafiado!"
		status_label.modulate = Color.YELLOW
	
	# Notificar en el chat solo si se especifica
	if notify_chat:
		var chat_system = get_node_or_null("../ChatSystem")
		if chat_system:
			chat_system.add_chat_message("Sistema", "⚔️ " + player_name + " te ha desafiado a una partida!")
		
		# Agregar timer automático solo para nuevas solicitudes
		setup_auto_decline_timer(player_id, 30.0)

func _on_accept_match_request(player_id: String):
	print("✅ Aceptando solicitud de partida del jugador: ", player_id)
	
	var request_data = pending_requests.get(player_id, {})
	var player_name = request_data.get("player_name", "")
	var match_id = request_data.get("match_id", "")
	
	# Enviar respuesta de aceptación al servidor
	var accept_response = {
		"event": "accept-match"
	}
	websocket_manager.send_message(accept_response)
	
	# Notificar en el chat
	var chat_system = get_node_or_null("../ChatSystem")
	if chat_system:
		chat_system.add_chat_message("Sistema", "✅ Has aceptado el desafío de " + player_name)
	
	var connect_match = {
		"event": "connect-match"
		}
	
	websocket_manager.send_message(connect_match)
	
	# Ocultar solicitud
	hide_match_request(player_id)
	
	# Actualizar lista
	call_deferred("request_online_players")

func connect_match():
	var connect_match = {
		"event" : "connect-match"
	}
	websocket_manager.send_message(connect_match)

func ping_match():
	var ping_match = {
		"event" : "ping-match"
	}
	websocket_manager.send_message(ping_match)

func _on_decline_match_request(player_id: String):
	print("❌ Declinando solicitud de partida del jugador: ", player_id)
	
	var request_data = pending_requests.get(player_id, {})
	var player_name = request_data.get("player_name", "")
	var match_id = request_data.get("match_id", "")
	
	# Enviar respuesta de rechazo al servidor
	var decline_response = {
		"event": "reject-match"
	}
	websocket_manager.send_message(decline_response)
	
	# Notificar en el chat
	var chat_system = get_node_or_null("../ChatSystem")
	if chat_system:
		chat_system.add_chat_message("Sistema", "❌ Has declinado el desafío de " + player_name)
	
	# Ocultar solicitud
	hide_match_request(player_id)
	
	# Actualizar lista
	call_deferred("request_online_players")

func setup_auto_decline_timer(player_id: String, timeout_seconds: float):
	# Crear timer para auto-declinar
	var timer = Timer.new()
	timer.wait_time = timeout_seconds
	timer.one_shot = true
	timer.timeout.connect(_on_auto_decline_timeout.bind(player_id, timer))
	add_child(timer)
	timer.start()
	
	print("⏰ Timer de auto-decline configurado para ", timeout_seconds, " segundos")

func _on_auto_decline_timeout(player_id: String, timer: Timer):
	print("⏰ Tiempo agotado para solicitud de: ", player_id)
	
	# Solo auto-declinar si la solicitud aún está pendiente
	if pending_requests.has(player_id):
		# Enviar rechazo automático
		var decline_response = {
			"event": "reject-match"
		}
		websocket_manager.send_message(decline_response)
		
		# Notificar en el chat
		var chat_system = get_node_or_null("../ChatSystem")
		if chat_system:
			chat_system.add_chat_message("Sistema", "⏰ Solicitud de partida expirada automáticamente")
		
		# Ocultar solicitud
		hide_match_request(player_id)
		
		# Actualizar lista
		call_deferred("request_online_players")
	
	# Limpiar timer
	timer.queue_free()

func hide_match_request(player_id: String):
	print("🚫 Ocultando solicitud de partida del jugador: ", player_id)
	
	# Remover de solicitudes pendientes
	pending_requests.erase(player_id)
	
	# Buscar el item del jugador
	var player_item = player_items.get(player_id)
	if not player_item:
		return
	
	# Ocultar botones
	var button_container = player_item.get_node_or_null("ButtonContainer")
	if button_container:
		button_container.visible = false
	
	# Mostrar botón de desafío nuevamente si aplica
	var challenge_button = player_item.get_node_or_null("ChallengeButton")
	if challenge_button:
		challenge_button.visible = true
	
	# Restaurar color de fondo normal
	var item_bg = player_item.get_node_or_null("ItemBg")
	if item_bg:
		if player_id == my_player_data.get("id", ""):
			item_bg.color = Color(0.2, 0.4, 0.6, 0.7)  # Azul para jugador actual
		else:
			item_bg.color = Color(0.2, 0.2, 0.2, 0.5)  # Gris normal
	
	# Restaurar estado normal
	var status_label = player_item.get_node_or_null("StatusLabel")
	if status_label:
		# Buscar los datos del jugador para restaurar su estado
		for player_data in current_players:
			if player_data.get("id") == player_id:
				status_label.text = get_status_text(player_data.get("status", "AVAILABLE"))
				status_label.modulate = status_colors.get(player_data.get("status", "AVAILABLE"), Color.GRAY)
				break

func _on_auto_refresh():
	if websocket_manager and websocket_manager.has_method("request_online_players"):
		websocket_manager.request_online_players()
