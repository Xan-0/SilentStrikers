extends SubViewport

@onready var minimap_camera: Camera2D = $Camera2D
@onready var player: CharacterBody2D
@onready var mapa: TileMapLayer = $TileMapLayer

func _ready():
	player = Singleton.devolver_player()


func _process(_delta):
		
	if player and minimap_camera:
		# Hace que la cámara del minimapa siga al jugador
		minimap_camera.global_position = player.global_position
