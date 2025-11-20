extends CharacterBody2D

signal coletar_moedas(moedas_id)

var moedas: int = 0

@export var speed: float = 300.0
@export var gravity: float = 980.0

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	var direction = Input.get_axis("ui_left", "ui_right")
	velocity.x = direction * speed
	
	move_and_slide()

func add_moeda(moedas_id: String):
	moedas += 1
	coletar_moedas.emit(moedas_id)
