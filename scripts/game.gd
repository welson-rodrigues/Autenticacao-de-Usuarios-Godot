extends Control

@onready var moedas_label: Label = $VBoxContainer/MoedasLabel
@onready var nivel_label: Label = $VBoxContainer/NivelLabel
@onready var add_moeda_button: Button = $VBoxContainer/AddMoedaButton
@onready var add_nivel_button: Button = $VBoxContainer/AddNivelButton
@onready var save_button: Button = $VBoxContainer/SaveButton
@onready var feedback_label: Label = $VBoxContainer/FeedbackLabel
@onready var logout_button: Button = $VBoxContainer/LogoutButton

var current_coins: int = 0
var current_level: int = 1

func _ready():
	# Conectar os botões
	add_moeda_button.pressed.connect(_on_add_moeda_button_pressed)
	add_nivel_button.pressed.connect(_on_add_nivel_button_pressed)
	save_button.pressed.connect(_on_save_button_pressed)
	logout_button.pressed.connect(_on_logout_button_pressed)
	
	SaveSystem.save_succeeded.connect(_on_save_succeeded)
	SaveSystem.save_failed.connect(_on_save_failed)
	
	current_coins = Auth.player_data.get("moedas", 0)
	current_level = Auth.player_data.get("nivel", 1) 
	
	update_ui()
	feedback_label.text = "Dados carregados. Bem-vindo!"

func _on_add_moeda_button_pressed():
	current_coins += 1
	update_ui()

func _on_add_nivel_button_pressed():
	current_level += 1
	update_ui()

func _on_save_button_pressed():
	feedback_label.text = "Salvando na nuvem..."
	
	var data_to_save = {
		"moedas": current_coins,
		"nivel": current_level,
		"ultimo_login": Time.get_unix_time_from_system() 
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
	moedas_label.text = "Moedas: " + str(current_coins)
	nivel_label.text = "Nível: " + str(current_level)
