# Guardia.gd
extends CharacterBody2D

## --- Variables de Movimiento y Navegación ---
@export var speed: float = 200.0
@export var acceleration: float = 7.0 # Renombrada de 'acel' para claridad
@export var navigation_target: Marker2D = null # El objetivo para el NavigationAgent2D

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D

## --- Variables de Visión y Detección ---
@export var player: CharacterBody2D = null # ¡Asigna el nodo del jugador aquí!
@export var vision_range: float = 300.0
@export var vision_angle_degrees: float = 90.0 # Ángulo TOTAL del cono (45° a cada lado)
@export var wall_collision_mask: int = 1 # Asegúrate que coincida con la capa de tus paredes

@onready var vision_raycast: RayCast2D = $VisionRayCast

var player_detected: bool = false
var last_known_player_position: Vector2 = Vector2.ZERO

## --- Variables para Dibujo del Cono ---
@export var draw_vision_cone: bool = true
@export var vision_cone_color: Color = Color(1, 1, 0, 0.3) # Amarillo semi-transparente

#=============================================================================
# FUNCIONES INTEGRADAS DE GODOT
#=============================================================================

func _ready():
	# Asegúrate de que el nodo del jugador esté asignado
	if not player:
		printerr("¡ERROR en Guardia! La variable 'Player' no está asignada en el Inspector.")

	# Configura el RayCast
	if vision_raycast:
		vision_raycast.add_exception(self) # El rayo ignora al propio guardia
		# Configura la máscara de colisión del RayCast
		# Necesita detectar las paredes Y al jugador
		if player:
			# Asume que 'player.collision_layer' contiene la capa correcta del jugador
			vision_raycast.collision_mask = wall_collision_mask | player.collision_layer
		else:
			# Si no hay jugador, solo detecta paredes (o lo que esté en wall_collision_mask)
			vision_raycast.collision_mask = wall_collision_mask
			printerr("Advertencia en Guardia: RayCast podría no detectar al jugador por falta de asignación.")
	else:
		printerr("¡ERROR en Guardia! No se encontró el nodo hijo 'VisionRayCast'.")

	# Configuración inicial del agente de navegación (opcional, si quieres que empiece a moverse)
	# if navigation_target:
	#	 navigation_agent.target_position = navigation_target.global_position


func _physics_process(delta):
	if not is_instance_valid(navigation_agent):
		printerr("Guardia: NavigationAgent2D no es válido.")
		return

	# --- 1. Lógica de Navegación y Movimiento ---
	var move_direction = Vector2.ZERO
	if navigation_target:
		navigation_agent.target_position = navigation_target.global_position

		if not navigation_agent.is_navigation_finished():
			var next_path_pos = navigation_agent.get_next_path_position()
			# Calcula la dirección hacia el siguiente punto del camino
			move_direction = (next_path_pos - global_position).normalized()
			# Actualiza la velocidad usando lerp para suavizar
			velocity = velocity.lerp(move_direction * speed, acceleration * delta)
		else:
			# Llegó al destino, desacelera
			velocity = velocity.lerp(Vector2.ZERO, acceleration * delta)
	else:
		# No hay objetivo, desacelera
		velocity = velocity.lerp(Vector2.ZERO, acceleration * delta)

	# --- 2. Rotación del Guardia ---
	# Rota el guardia para que mire en la dirección del movimiento deseado (move_direction)
	# Solo rota si hay una dirección de movimiento clara.
	if move_direction != Vector2.ZERO:
		rotation = move_direction.angle()
	# Si no hay dirección de movimiento (p.ej., llegó al destino),
	# mantiene la última rotación.

	# Aplica el movimiento
	move_and_slide()

	# --- 3. Lógica de Visión ---
	if player: # Solo intenta detectar si el jugador existe y está asignado
		# Calcula la dirección actual REAL que mira el guardia basado en su rotación
		# Esto asegura que la detección y el dibujo estén sincronizados.
		var current_forward_vector = Vector2.RIGHT.rotated(rotation)
		check_vision(current_forward_vector)
	else:
		# Si el jugador desaparece o no está asignado, asegúrate de que no esté detectado
		if player_detected:
			_on_player_lost()
		player_detected = false


	# --- 4. Solicitar Redibujo del Cono ---
	if draw_vision_cone:
		queue_redraw()


#=============================================================================
# FUNCIONES PERSONALIZADAS
#=============================================================================

## Revisa si el jugador está dentro del cono de visión y línea de mira.
func check_vision(guard_forward_direction: Vector2):
	if not is_instance_valid(player): # Doble check por si el jugador fue eliminado
		if player_detected: _on_player_lost()
		player_detected = false
		return

	var was_detected = player_detected # Guarda el estado anterior
	var currently_detected = false # Asume no detectado para este frame

	var direction_to_player = player.global_position - global_position
	var distance_to_player = direction_to_player.length()

	# 1. Comprobación de Rango
	if distance_to_player <= vision_range:

		# 2. Comprobación de Ángulo
		var normalized_direction_to_player = direction_to_player.normalized()
		# Producto punto entre la dirección del guardia y la dirección al jugador
		var dot_product = guard_forward_direction.dot(normalized_direction_to_player)
		# Coseno del semi-ángulo de visión (convertido a radianes)
		var limit_dot = cos(deg_to_rad(vision_angle_degrees / 2.0))

		if dot_product > limit_dot: # ¿Está dentro del ángulo?

			# 3. Comprobación de Línea de Visión (RayCast)
			if vision_raycast:
				vision_raycast.target_position = direction_to_player # Apunta al jugador
				vision_raycast.force_raycast_update() # Realiza el cast AHORA

				if vision_raycast.is_colliding():
					var collider = vision_raycast.get_collider()
					if collider == player:
						# ¡Detectado! En rango, en ángulo y línea de visión directa.
						currently_detected = true
						last_known_player_position = player.global_position
					# else: El rayo golpeó una pared u otro objeto antes que al jugador
				# else: El rayo no golpeó nada en el camino (improbable si el jugador está en rango/ángulo)
			else:
				printerr("Guardia: Intentando usar VisionRayCast pero no es válido.")

	# Actualizar estado de detección y llamar a las funciones correspondientes SÓLO si cambia
	player_detected = currently_detected
	if player_detected and not was_detected:
		_on_player_detected()
	elif not player_detected and was_detected:
		_on_player_lost()

## Llamada cuando el jugador es detectado por primera vez.
func _on_player_detected():
	print("¡Jugador DETECTADO en ", Time.get_ticks_msec(), "!")
	# --- PON AQUÍ TU LÓGICA DE DETECCIÓN ---
	# Ejemplo: Cambiar a estado de persecución, alertar a otros, etc.
	# Ejemplo: Podrías hacer que el objetivo de navegación sea ahora el jugador
	# self.navigation_target = player # ¡CUIDADO! Esto haría que deje de seguir la ruta original.

## Llamada cuando se pierde la visión del jugador.
func _on_player_lost():
	print("Jugador PERDIDO.")
	# --- PON AQUÍ TU LÓGICA AL PERDERLO ---
	# Ejemplo: Volver a patrullar, ir a la última posición conocida, etc.
	# Ejemplo: Podrías querer que vaya a 'last_known_player_position'
	# if navigation_target: # Si tenías un objetivo de patrulla...
	#     navigation_agent.target_position = last_known_player_position # Ir a investigar
	#     # Necesitarías lógica adicional para volver a patrullar después


#=============================================================================
# FUNCIÓN DE DIBUJO
#=============================================================================

## Dibuja el cono de visión en el editor o en el juego.
func _draw():
	if not draw_vision_cone:
		return

	# Dibuja en coordenadas locales. La rotación del nodo orientará el cono.
	var half_angle_rad = deg_to_rad(vision_angle_degrees / 2.0)
	var num_arc_segments = 20 # Puntos para dibujar el arco exterior
	var arc_points = PackedVector2Array()

	# Calcula los puntos para el arco exterior del cono
	for i in range(num_arc_segments + 1):
		var angle = -half_angle_rad + (half_angle_rad * 2.0 * i / num_arc_segments)
		arc_points.append(Vector2.RIGHT.rotated(angle) * vision_range)

	# Dibuja el contorno del cono: línea, arco, línea
	if arc_points.size() > 0:
		draw_line(Vector2.ZERO, arc_points[0], vision_cone_color, 1.0) # Línea inicial
		draw_polyline(arc_points, vision_cone_color, 1.0) # Arco exterior
		draw_line(Vector2.ZERO, arc_points[-1], vision_cone_color, 1.0) # Línea final

	# --- Alternativa: Cono Relleno (descomenta si lo prefieres) ---
	# var polygon_points = PackedVector2Array([Vector2.ZERO]) # Origen
	# polygon_points.append_array(arc_points) # Añade puntos del arco
	# draw_colored_polygon(polygon_points, vision_cone_color)s
