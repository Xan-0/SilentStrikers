extends Node2D

@export var vision_range: float = 400.0
@export var vision_angle_degrees: float = 90.0
@export var wall_collision_mask: int = 1
@export var draw_vision_cone: bool = true
@export var vision_cone_color: Color = Color(1, 0, 0, 0.3)

@export var player: CharacterBody2D
@onready var raycast: RayCast2D = $RayCast2D

var player_detected: bool = false
var last_known_position: Vector2 = Vector2.ZERO
var rotation2 := rotation  # Dirección visual de la cámara

func _ready():
	raycast.collision_mask = wall_collision_mask | player.collision_layer

func _process(delta):
	check_vision()

	if player_detected or last_known_position != Vector2.ZERO:
		var target_dir = (last_known_position - global_position).angle()
		rotation2 = lerp_angle(rotation2, target_dir, delta * 2.5)

	if draw_vision_cone:
		queue_redraw()

func check_vision():
	var dir_to_player = player.global_position - global_position
	var distance = dir_to_player.length()

	if distance > vision_range:
		if player_detected:
			_on_player_lost()
		player_detected = false
		return

	var dir_norm = dir_to_player.normalized()
	var angle_to_player = Vector2.RIGHT.rotated(rotation2).angle_to(dir_norm)
	var limit_angle = deg_to_rad(vision_angle_degrees / 2.0)

	if abs(angle_to_player) <= limit_angle + deg_to_rad(20):
		raycast.target_position = to_local(player.global_position)
		raycast.force_raycast_update()
		if raycast.is_colliding() and raycast.get_collider() == player:
			last_known_position = player.global_position
			if not player_detected:
				_on_player_detected()
			player_detected = true
			return

	if player_detected:
		_on_player_lost()
	player_detected = false

func _on_player_detected():
	var guardia = get_closest_guardia()
	if guardia:
		guardia.last_known_player_position = last_known_position
		guardia.current_state = guardia.State.CHASING
		guardia.chasing_timer = guardia.chase_duration

		if guardia.has_node("NavigationAgent2D") and guardia.navigation_region:
			var nav: NavigationAgent2D = guardia.get_node("NavigationAgent2D")
			var nav_map = guardia.navigation_region.get_navigation_map()
			var closest = NavigationServer2D.map_get_closest_point(nav_map, last_known_position)
			nav.target_position = closest

func _on_player_lost():
	var guardia = get_closest_guardia()
	if guardia and guardia.current_state == guardia.State.CHASING:
		guardia.current_state = guardia.State.SEARCHING
		guardia.search_timer = guardia.search_duration

func get_closest_guardia() -> Node:
	var closest = null
	var closest_dist = INF

	for guardia in get_tree().get_nodes_in_group("GuardiasM1"):
		if not guardia.is_inside_tree():
			continue
		var dist = global_position.distance_to(guardia.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = guardia
	return closest

func _draw():
	if not draw_vision_cone:
		return

	var half_angle = deg_to_rad(vision_angle_degrees / 2.0)
	var segments = 20
	var points = PackedVector2Array()
	points.append(Vector2.ZERO)  # Centro de la cámara

	for i in range(segments + 1):
		var angle = -half_angle + (i / float(segments)) * (2 * half_angle)
		var dir = Vector2.RIGHT.rotated(angle + rotation2)
		points.append(dir * vision_range)

	draw_colored_polygon(points, vision_cone_color)
