extends Control

# Responsabilidade: Apenas autenticar e mudar de cena.
@onready var email_input: LineEdit = $VBoxContainer/EmailInput
@onready var password_input: LineEdit = $VBoxContainer/PasswordInput
@onready var register_button: Button = $VBoxContainer/HBoxContainer/RegisterButton
@onready var login_button: Button = $VBoxContainer/HBoxContainer/LoginButton
@onready var feedback_label: Label = $VBoxContainer/FeedbackLabel

func _ready():
	# Conectar botões de Login/Auth
	register_button.pressed.connect(_on_register_button_pressed)
	login_button.pressed.connect(_on_login_button_pressed)
	
	# Conectar Sinais (respostas) do Autoload 'Auth'
	Auth.registration_succeeded.connect(_on_registration_succeeded)
	Auth.registration_failed.connect(_on_registration_failed)
	Auth.login_succeeded.connect(_on_login_succeeded)
	Auth.login_failed.connect(_on_login_failed)

	# Conectar Sinais (respostas) do Autoload 'SaveSystem'
	SaveSystem.load_succeeded.connect(_on_load_succeeded)
	SaveSystem.load_failed.connect(_on_load_failed)

func _on_register_button_pressed():
	var email = email_input.text
	var password = password_input.text
	if email.is_empty() or password.is_empty():
		feedback_label.text = "Por favor, preencha e-mail e senha."
		return
	
	feedback_label.text = "Registrando..."
	Auth.register_user(email, password)

func _on_login_button_pressed():
	var email = email_input.text
	var password = password_input.text
	if email.is_empty() or password.is_empty():
		feedback_label.text = "Por favor, preencha e-mail e senha."
		return
	
	feedback_label.text = "Entrando..."
	Auth.login_user(email, password)

func _on_registration_succeeded(local_id: String):
	feedback_label.text = "Cadastro OK! Bem-vindo!"
	# É um usuário novo, não precisa carregar dados.
	Auth.player_data = {} # Limpa os dados
	get_tree().change_scene_to_file("res://cenas/game.tscn")

func _on_registration_failed(error_message: String):
	feedback_label.text = "Falha no cadastro: " + error_message

func _on_login_succeeded(local_id: String, id_token: String):
	feedback_label.text = "Login OK! Carregando dados..."
	# Chama o SaveSystem para carregar os dados do jogador
	SaveSystem.load_data()

func _on_login_failed(error_message: String):
	feedback_label.text = "Falha no login: " + error_message

func _on_load_succeeded(data: Dictionary):
	feedback_label.text = "Dados carregados! Entrando no jogo..."
	
	# 1. Salva os dados globalmente no Autoload do Auth
	Auth.player_data = data
	
	# 2. Muda para a cena principal do jogo
	get_tree().change_scene_to_file("res://cenas/game.tscn")

func _on_load_failed():
	feedback_label.text = "Erro ao carregar dados. Tente novamente."
