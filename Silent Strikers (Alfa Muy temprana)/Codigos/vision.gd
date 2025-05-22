extends Area2D

var guardia = get_parent()
var player_in_range = false
signal ladron_entro
signal ladron_salio

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

#Detecta si el Ladrón entro al rango
func _on_body_entered(body):
	if body.name == "Ladron":
		emit_signal("ladron_entro")

#Detecta si el Ladrón salió del rango
func _on_body_exited(body):
	if body.name == "Ladron":
		emit_signal("ladron_salio")

#Si el jugador esta en rango
func _process(delta):
	return
