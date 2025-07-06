extends Node

# WebSocket peer
var websocket: WebSocketPeer
var server_url = "ws://localhost:4010/?gameId=B&playerName=Teto"  # Cambia según tu servidor
# Estado de conexión
var is_connected = false
var connection_attempts = 0
var max_reconnect_attempts = 5
@onready var ChatSystem = get_node("../ChatSystem")
var player: CharacterBody2D
# Datos del jugador
var player_data = {}

func _ready():
	player = Singleton.devolver_player()
	websocket = WebSocketPeer.new()
	connect_to_server()

func connect_to_server():
	print("Conectando al servidor WebSocket...")
	var error = websocket.connect_to_url(server_url)
	
	if error != OK:
		print("Error al conectar: ", error)
		attempt_reconnection()
	else:
		print("Conexión iniciada a la ip ", server_url)

func _process(_delta):
	websocket.poll()
	var state = websocket.get_ready_state()
	
	match state:
		WebSocketPeer.STATE_CONNECTING:
			pass
			
		WebSocketPeer.STATE_OPEN:
			if not is_connected:
				is_connected = true
				connection_attempts = 0
				print("Conectado al servidor WebSocket!")
				on_connection_established()
			
			while websocket.get_available_packet_count():
				var packet = websocket.get_packet()
				var message = packet.get_string_from_utf8()
				handle_message(message)
				
		WebSocketPeer.STATE_CLOSING:
			print("Cerrando conexión...")
			
		WebSocketPeer.STATE_CLOSED:
			if is_connected:
				print("Conexión perdida")
				is_connected = false
				attempt_reconnection()

func on_connection_established():
	var login = {
		"event": "login",
		"data": {
			"gameKey": "ED6XK9"
		}
	}
	send_message(login)

func generate_player_id() -> String:
	return "player_" + str(Time.get_unix_time_from_system()) + "_" + str(randi() % 1000)

func send_message(data: Dictionary):
	if not is_connected:
		print("No conectado. No se puede enviar mensaje.")
		return

	var json_string = JSON.stringify(data)
	var error = websocket.send_text(json_string)
	
	if error != OK:
		print("Error al enviar mensaje: ", error)

func handle_message(message: String):
	var json = JSON.new()
	var parse_result = json.parse(message)
	
	if parse_result != OK:
		print("Error al parsear mensaje JSON")
		return
	
	var data = json.data
	
	if not data.has("event"):
		print("Mensaje sin tipo")
		return
	
	var event = data.get("event", "")
	var status = data.get("status", "")
	var msg = data.get("msg", "")
	print("Evento: ", event, " | Estado: ", status, " | Mensaje: ", msg)
	
	match event:
		"login":
			handle_connection_accepted(data.data)
		"public-message":
			handle_public_message(data.data)
		"online-players":
			handle_online_players(data.data)
		"player-connected":
			handle_player_connected(data.data)
		"player-disconnected":
			handle_player_disconnected(data.data)
		"match-request-received":
			handle_match_request_received(data.get("data", {}), data.get("msg", ""))
		"match-accepted":
			handle_match_accepted(data.data)
		"players-ready":
			handle_match_ready(data.data)
		"match-start":
			handle_match_start(data.data)
		"error":
			handle_error(data.data)
			print("Tipo de mensaje desconocido: ", data.type)
			
func handle_connection_accepted(data: Dictionary):
	player_data = data
	print("✅ Conexión aceptada. ID asignado: ", data.get("id", ""))
	print("✅ Nombre del jugador: ", data.get("name", ""))
	if ChatSystem and ChatSystem.has_method("set_player_name"):
		ChatSystem.set_player_name(data.get("name", ""))
	var player_list = get_node_or_null("../PlayerListSystem")
	if player_list and player_list.has_method("set_my_player_data"):
		player_list.set_my_player_data(data)

func handle_match_start(data: Dictionary):
	pass

func handle_match_accepted(data: Dictionary):
	var player_list = get_node_or_null("../PlayerListSystem")
	player_list.connect_match()
	
func handle_match_ready(data: Dictionary):
	var player_list = get_node_or_null("../PlayerListSystem")
	player_list.ping_match()

func handle_public_message(data: Dictionary):
	var player_name = data.get("playerName", "")
	var message = data.get("playerMsg", "")
	ChatSystem.on_message_received(player_name, message)
	print(player_name, ": ", message)
	
func handle_online_players(players_data: Array):
	var player_list = get_node_or_null("../PlayerListSystem")
	if player_list and player_list.has_method("update_player_list"):
		player_list.update_player_list(players_data)
	else:
		print("⚠️ PlayerListSystem no encontrado")

func handle_player_connected(data: Dictionary):
	var player_name = data.get("name", "")
	ChatSystem.on_player_joined_chat(player_name)

func handle_player_disconnected(data: Dictionary):
	var player_name = data.get("name", "")
	ChatSystem.on_player_left_chat(player_name)

func handle_error(data: Dictionary):
	print("Error del servidor: ", data.get("message", ""))

func attempt_reconnection():
	if connection_attempts >= max_reconnect_attempts:
		print("Máximo de intentos de reconexión alcanzado")
		return
	
	connection_attempts += 1
	print("Intento de reconexión ", connection_attempts, "/", max_reconnect_attempts)
	
	# Esperar antes de reconectar
	await get_tree().create_timer(2.0).timeout
	connect_to_server()

func send_public_message(text: String):
	var message = {
		"event": "send-public-message",
		"data": {
			"message": text
			}
		}
	send_message(message)

func disconnect_from_server():
	if is_connected:
		var message = {
			"type": "player_disconnect",
			"data": {
				"player_id": player_data.get("player_id", "")
			}
		}
		send_message(message)
		
		websocket.close()
		is_connected = false

func request_online_players():
	if not is_connected:
		print("⚠️ No conectado, no se puede solicitar lista de jugadores")
		return
	
	var request = {
		"event": "online-players"
	}
	send_message(request)

func handle_match_request_received(data: Dictionary, message: String):
	var player_id = data.get("playerId", "")
	var match_id = data.get("matchId", "")
	
	print("⚔️ Solicitud de partida recibida:")
	print("  - Player ID: ", player_id)
	print("  - Match ID: ", match_id)
	print("  - Mensaje: ", message)
	
	# Extraer nombre del jugador del mensaje
	var player_name = extract_player_name_from_message(message)
	
	# Actualizar lista de jugadores PRIMERO
	var player_list = get_node_or_null("../PlayerListSystem")
	if player_list:
		if player_list.has_method("request_online_players"):
			player_list.request_online_players()
		# Esperar un momento para que se actualice la lista, luego mostrar la solicitud
		await get_tree().create_timer(0.5).timeout
		
		if player_list.has_method("show_match_request"):
			player_list.show_match_request(player_name, player_id, match_id)
	else:
		print("⚠️ PlayerListUI no encontrado")

func extract_player_name_from_message(message: String) -> String:
	# El mensaje viene como: "Match request received from player 'Teto'"
	var parts = message.split("'")
	if parts.size() >= 2:
		return parts[1]  # El nombre está entre las comillas simples
	else:
		return "Jugador desconocido"

func _exit_tree():
	disconnect_from_server()

func _on_back_menu_button_pressed() -> void:
	var mapa_scene = load("res://Escenas/main_menu.tscn")
	get_tree().change_scene_to_packed(mapa_scene)
