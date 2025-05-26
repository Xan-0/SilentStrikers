extends SubViewport

@onready var minimap_camera: Camera2D = $Camera2D
@onready var player: Node2D = get_node("/root/Mapa de Prueba/Ladron")  # Ajustá si el path es otro
@onready var mapa: TileMapLayer = $TileMapLayer  # Tu copia visual del mapa

func _process(_delta):
	if player and minimap_camera:
		# Hace que la cámara del minimapa siga al jugador
		minimap_camera.global_position = player.global_position
