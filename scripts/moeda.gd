extends Area2D

@export var moedas_id: String = ""

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.add_moeda(moedas_id)
		queue_free()
