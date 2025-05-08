extends RayCast2D

var angle_cone_of_vision = 30.0
var angle_between_rays = 5

func _physics_process(delta: float) -> void:
	if is_colliding():
		if get_collider().name == "Ladron":
			print("PLayer detetcted")
