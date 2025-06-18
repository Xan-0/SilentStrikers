extends Node2D

@export var vision_range: float = 400.0
@export var vision_angle_degrees: float = 90.0
@export var wall_collision_mask: int = 1
@export var draw_vision_cone: bool = true
@export var vision_cone_color: Color = Color(1, 0, 0, 0.3)

@onready var player: CharacterBody2D = get_node("../Ladron")
@onready var raycast: RayCast2D = $RayCast2D
@onready var vision_polygon := $Polygon2D # Mantenemos el Polygon2D para el cono visual

var player_detected: bool = false
var last_known_position: Vector2 = Vector2.ZERO
var rotation2 := rotation  # dirección visual de la cámara

func _ready():
	# Aseguramos que la máscara de colisión se configure correctamente
	if player:
		raycast.collision_mask = wall_collision_mask | player.get_collision_layer()
	else:
		print_rich("[color=red]Cámara no pudo encontrar al Ladrón en _ready().[/color]")


func _process(delta):
	check_vision()

	# Suaviza la rotación de la cámara para apuntar a la última posición conocida
	if player_detected or last_known_position != Vector2.ZERO:
		var target_dir = (last_known_position - global_position).angle()
		rotation2 = lerp_angle(rotation2, target_dir, delta * 2.5)

	# Actualizamos el cono visual del Polygon2D
	_update_vision_cone()
	
	# Si se elige el dibujado por líneas, se activa
	if draw_vision_cone:
		queue_redraw()

func check_vision():
	if not player: return

	var dir_to_player = player.global_position - global_position
	var distance = dir_to_player.length()

	if distance > vision_range:
		if player_detected:
			_on_player_lost()
		player_detected = false
		return

	var dir_norm = dir_to_player.normalized()
	# Usamos Vector2.RIGHT.rotated(rotation2) como la dirección "hacia adelante"
	var angle_to_player = Vector2.RIGHT.rotated(rotation2).angle_to(dir_norm)
	var limit_angle = deg_to_rad(vision_angle_degrees / 2.0)

	# Mantenemos el ángulo de visión más generoso de la rama 'main'
	if abs(angle_to_player) <= limit_angle + deg_to_rad(20):
		raycast.target_position = dir_to_player
		raycast.force_raycast_update()
		
		if raycast.is_colliding() and raycast.get_collider() == player:
			last_known_position = player.global_position
			if not player_detected:
				_on_player_detected()
			player_detected = true
			return

	# Si ninguna condición de visión se cumple, se considera perdido
	if player_detected:
		_on_player_lost()
	player_detected = false

func get_closest_guardia() -> Node:
	var closest_guard = null
	var closest_dist = INF

	for guardia in get_tree().get_nodes_in_group("Guardias"):
		if not is_instance_valid(guardia):
			continue
		var dist = global_position.distance_to(guardia.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest_guard = guardia
	return closest_guard

func _on_player_detected():
	print("📷 Cámara detectó al ladrón.")
	var guardia = get_closest_guardia()
	if guardia:
		# Llama a la función del guardia para que reaccione
		guardia.hear_noise(last_known_position)

func _on_player_lost():
	print("📷 Cámara perdió de vista al ladrón.")
	# Opcional: Podrías querer resetear last_known_position aquí si lo deseas
	# last_known_position = Vector2.ZERO

func _draw():
	if not draw_vision_cone: return
	
	var half_angle = deg_to_rad(vision_angle_degrees / 2.0)
	var segments = 20
	var points = PackedVector2Array()

	for i in range(segments + 1):
		var angle = -half_angle + (i / float(segments)) * (2 * half_angle)
		# Corregido: El cono dibujado ahora coincide con el vision_range real
		points.append(Vector2.RIGHT.rotated(angle + rotation2) * vision_range)

	if points.size() > 0:
		draw_line(Vector2.ZERO, points[0], vision_cone_color, 1.0)
		draw_polyline(points, vision_cone_color, 1.0)
		draw_line(Vector2.ZERO, points[-1], vision_cone_color, 1.0)
		
func _update_vision_cone():
	# Esta función actualiza el Polygon2D para que muestre el cono de visión
	if not is_instance_valid(vision_polygon): return

	var half_angle = deg_to_rad(vision_angle_degrees / 2.0)
	var segments = 20
	var points = PackedVector2Array()
	points.append(Vector2.ZERO) # Centro del cono

	for i in range(segments + 1):
		var angle = -half_angle + ((half_angle) * 2.0 * i / segments)
		points.append(Vector2.RIGHT.rotated(angle + rotation2) * vision_range)

	vision_polygon.polygon = points
	vision_polygon.color = vision_cone_color