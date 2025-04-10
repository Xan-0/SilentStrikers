extends CharacterBody2D

# --- Variables de Movimiento ---
var speed = 200
var acel = 7

@onready var nav: NavigationAgent2D = $NavigationAgent2D
@export var objetivo: Marker2D # El objetivo actual para la navegación

# --- Variables de Visión ---
@export var player: CharacterBody2D = null # Asigna el nodo del jugador aquí desde el editor
@export var vision_range: float = 1000 # Distancia máxima de visión
@export var vision_angle_degrees: float = 45.0 # Ángulo del cono de visión (total, 45° a cada lado del centro)
@export var wall_collision_mask: int = 1 # Ajusta esto al número de la capa de colisión de tus paredes

@onready var vision_raycast: RayCast2D = $VisionRayCast # Necesitas añadir un nodo RayCast2D hijo

var player_detected: bool = false # Para saber si el jugador está siendo detectado

func _ready():
	# Asegúrate de que el RayCast ignore al propio guardia
	if vision_raycast:
		vision_raycast.add_exception(self)
		# Configura la máscara de colisión del RayCast para que detecte
		# tanto las paredes como al jugador.
		# Asumiendo que el jugador está en la capa 1 (ajusta si es necesario)
		# y las paredes en la capa definida por 'wall_collision_mask'.
		# Cambia los números de capa según tu configuración de proyecto.
		# Ejemplo: Si jugador está en capa 2 y paredes en capa 1:
		# vision_raycast.collision_mask = wall_collision_mask | (1 << 1) # El bit 0 es capa 1, bit 1 es capa 2
		# Si solo quieres detectar paredes y el jugador (asumiendo capa 2 para jugador):
		vision_raycast.collision_mask = wall_collision_mask | player.collision_layer # O la capa específica del jugador


func _physics_process(delta):
	# --- Lógica de Movimiento ---
	var current_agent_position: Vector2 = global_position
	var next_path_position: Vector2 = nav.get_next_path_position()

	nav.target_position = objetivo.global_position

	# Calcula la dirección de movimiento solo si la navegación está activa y hay un camino
	var target_direction: Vector2 = Vector2.ZERO
	if not nav.is_navigation_finished():
		target_direction = (next_path_position - current_agent_position).normalized()

	# Aplica movimiento usando lerp para suavizar
	velocity = velocity.lerp(target_direction * speed, acel * delta)

	# Mueve al personaje
	move_and_slide()

	# --- Lógica de Visión ---
	if player: # Solo busca si hay una referencia al jugador
		check_vision()
	else:
		if player_detected: # Si ya no hay jugador, deja de detectarlo
			_on_player_lost()
		player_detected = false


# --- Funciones de Visión ---

func check_vision():
	var current_detection_status = false # Estado de detección en este frame
	var direction_to_player = player.global_position - global_position
	var distance_to_player = direction_to_player.length()

	# 1. Comprobación de Rango
	if distance_to_player <= vision_range:

		# 2. Comprobación de Ángulo
		# Necesitamos la dirección hacia donde mira el guardia.
		# Usaremos la dirección de la velocidad si se está moviendo,
		# o la dirección 'hacia adelante' local (transform.x) si está quieto.
		var forward_direction: Vector2
		if velocity.length_squared() > 0.1: # Un pequeño umbral para considerar que se mueve
			forward_direction = velocity.normalized()
		else:
			# Asume que el sprite mira hacia la derecha por defecto, ajusta si es diferente
			# Por ejemplo, usa -transform.y si mira hacia arriba
			forward_direction = Vector2.RIGHT.rotated(global_rotation) # Considera la rotación del guardia

		# Normaliza la dirección al jugador para el cálculo del ángulo
		var normalized_direction_to_player = direction_to_player.normalized()

		# Calcula el ángulo usando el producto punto (más eficiente que acos)
		var dot_product = forward_direction.dot(normalized_direction_to_player)
		# El ángulo de visión es la mitad del total a cada lado
		var vision_angle_radians = deg_to_rad(vision_angle_degrees / 2.0)
		var limit_dot = cos(vision_angle_radians)

		if dot_product > limit_dot: # Está dentro del cono de visión angular

			# 3. Comprobación de Línea de Visión (RayCast)
			if vision_raycast:
				vision_raycast.target_position = direction_to_player # Apunta el rayo hacia el jugador
				vision_raycast.force_raycast_update() # Actualiza la colisión del rayo inmediatamente

				if vision_raycast.is_colliding():
					var collider = vision_raycast.get_collider()
					# ¡Importante! Comprueba si lo que golpeó el rayo es realmente el jugador
					if collider == player:
						# ¡Jugador detectado! Está en rango, en ángulo y sin obstrucciones
						current_detection_status = true

	# --- Actualizar Estado y Ejecutar Acciones ---
	if current_detection_status and not player_detected:
		# Se acaba de detectar al jugador
		_on_player_detected()
		player_detected = true
	elif not current_detection_status and player_detected:
		# Se acaba de perder al jugador
		_on_player_lost()
		player_detected = false
	# Si current_detection_status y player_detected son ambos true, no hacemos nada (ya estaba detectado)
	# Si ambos son false, no hacemos nada (sigue sin detectarse)


func _on_player_detected():
	print("¡Jugador detectado!")
	# Aquí puedes poner tu lógica:
	# - Cambiar a un estado de "perseguir"
	# - Reproducir una animación de alerta
	# - Cambiar la variable 'objetivo' para que sea la posición del jugador
	#   (quizás necesites actualizar 'objetivo' continuamente mientras lo detectas)
	# Ejemplo: nav.target_position = player.global_position # Ojo: esto haría que vaya directo, no usa pathfinding

func _on_player_lost():
	print("Jugador perdido.")
	# Aquí puedes poner tu lógica:
	# - Volver al estado de "patrullar"
	# - Quizás ir a la última posición conocida del jugador
	# - Restablecer el 'objetivo' a su valor original si es necesario
