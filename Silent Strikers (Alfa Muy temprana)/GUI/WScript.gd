extends Node

# WebSocket peer
var websocket: WebSocketPeer
var server_url = "ws://localhost:4010/?gameId=B&playerName=Teto"  # Cambia según tu servidor
# Estado de conexión
var is_connected = false
var connection_attempts = 0
var max_reconnect_attempts = 5
@onready var ChatSystem = get_node("../ChatSystem")

# Datos del jugador
var player_data = {}

func _ready():
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
		"player-connected":
			handle_player_connected(data.data)
		"player-disconnected":
			handle_player_disconnected(data.data)
		"error":
			handle_error(data.data)
			print("Tipo de mensaje desconocido: ", data.type)
			
func handle_connection_accepted(data: Dictionary):
	player_data = data
	print("Conexión aceptada. ID asignado: ", data.get("id", ""))

func handle_public_message(data: Dictionary):
	var player_name = data.get("playerName", "")
	var message = data.get("playerMsg", "")
	ChatSystem.on_message_received(player_name, message)
	print(player_name, ": ", message)

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

func _exit_tree():
	disconnect_from_server()

func _on_back_menu_button_pressed() -> void:
	var mapa_scene = load("res://Escenas/main_menu.tscn")
	get_tree().change_scene_to_packed(mapa_scene)
