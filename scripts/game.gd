extends Node2D

@onready var moedas_label: Label = $CanvasLayer/VBoxContainer/MoedasLabel
@onready var save_button: Button = $CanvasLayer/VBoxContainer/SaveButton
@onready var feedback_label: Label = $CanvasLayer/VBoxContainer/FeedbackLabel
@onready var logout_button: Button = $CanvasLayer/VBoxContainer/LogoutButton
@onready var player: CharacterBody2D = $Player

var coletar_moedas_ids: Array = []

func _ready():
	save_button.pressed.connect(_on_save_button_pressed)
	logout_button.pressed.connect(_on_logout_button_pressed)
	SaveSystem.save_succeeded.connect(_on_save_succeeded)
	SaveSystem.save_failed.connect(_on_save_failed)
	
	player.coletar_moedas.connect(_on_moeda_coletada)

	player.moedas = Auth.player_data.get("moedas", 0)
	var pos_x = Auth.player_data.get("pos_x", player.global_position.x)
	var pos_y = Auth.player_data.get("pos_y", player.global_position.y)
	player.global_position = Vector2(pos_x, pos_y)
	
	coletar_moedas_ids = Auth.player_data.get("moedas_coletadas", [])
	
	_destruir_moedas_coletadas()
	
	update_ui()
	feedback_label.text = "Dados carregados. Bem-vindo!"

func _on_moeda_coletada(moedas_id: String):
	if not coletar_moedas_ids.has(moedas_id):
		coletar_moedas_ids.append(moedas_id)

	update_ui()

func _destruir_moedas_coletadas():
	for moeda in get_tree().get_nodes_in_group("moedas"):
		if moeda.moedas_id in coletar_moedas_ids:
			moeda.queue_free()

func _on_save_button_pressed():
	feedback_label.text = "Salvando na nuvem..."
	
	var data_to_save = {
		"moedas": player.moedas,
		"pos_x": player.global_position.x,
		"pos_y": player.global_position.y,
		
		"moedas_coletadas": coletar_moedas_ids
	}
	
	SaveSystem.save_data(data_to_save)

func _on_logout_button_pressed():
	Auth.logout()
	get_tree().change_scene_to_file("res://cenas/login_screen.tscn")

func _on_save_succeeded():
	feedback_label.text = "Progresso Salvo na Nuvem!"

func _on_save_failed():
	feedback_label.text = "Erro ao Salvar."

func update_ui():
	moedas_label.text = "Moedas: " + str(player.moedas)
