extends CharacterBody2D

var speed = 200
var acel = 7

@onready var nav: NavigationAgent2D = $NavigationAgent2D
@export var objetivo: Marker2D

func _physics_process(delta):
	var direccion = Vector3()
	nav.target_position = objetivo.global_position
	
	direccion = nav.get_next_path_position() - global_position
	direccion = direccion.normalized()
	
	velocity = velocity.lerp(direccion * speed, acel * delta)
	
	move_and_slide()
	
