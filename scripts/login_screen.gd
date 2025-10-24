extends Control

# Referências aos nós da cena. Arraste-os do painel de cena para essas variáveis no inspetor.
@onready var email_input: LineEdit = $VBoxContainer/EmailInput
@onready var password_input: LineEdit = $VBoxContainer/PasswordInput
@onready var register_button: Button = $VBoxContainer/HBoxContainer/RegisterButton
@onready var login_button: Button = $VBoxContainer/HBoxContainer/LoginButton
@onready var feedback_label: Label = $VBoxContainer/FeedbackLabel
@onready var auth: Node = $VBoxContainer/HBoxContainer/LoginButton/Auth# Referência ao nosso nó com o script auth.gd
@onready var logout_button: Button = $VBoxContainer/HBoxContainer/LogoutButton


func _ready():
	# Conecta os sinais dos botões às funções deste script
	register_button.pressed.connect(_on_register_button_pressed)
	login_button.pressed.connect(_on_login_button_pressed)
	logout_button.pressed.connect(_on_logout_button_pressed)
	
	# Conecta os sinais do nosso nó de autenticação às funções de feedback
	auth.registration_succeeded.connect(_on_registration_succeeded)
	auth.registration_failed.connect(_on_registration_failed)
	auth.login_succeeded.connect(_on_login_succeeded)
	auth.login_failed.connect(_on_login_failed)
	
func _on_logout_button_pressed():
	auth.logout() # Chama a função que você adicionou no auth.gd

	feedback_label.text = "Você saiu."

	# Esconde o botão de logout e mostra os de login/registro novamente
	logout_button.visible = false
	register_button.visible = true
	login_button.visible = true
	email_input.visible = true
	password_input.visible = true

	# Limpa os campos
	email_input.text = ""
	password_input.text = ""

func _on_register_button_pressed():
	var email = email_input.text
	var password = password_input.text
	
	if email.is_empty() or password.is_empty():
		feedback_label.text = "Por favor, preencha email e senha."
		return
	
	feedback_label.text = "Registrando..."
	auth.register_user(email, password)

func _on_login_button_pressed():
	var email = email_input.text
	var password = password_input.text

	if email.is_empty() or password.is_empty():
		feedback_label.text = "Por favor, preencha email e senha."
		return
	
	feedback_label.text = "Entrando..."
	auth.login_user(email, password)

# --- Funções para lidar com as respostas do Auth ---

func _on_registration_succeeded(local_id: String):
	feedback_label.text = "Cadastro realizado com sucesso!"
	print("Cadastro OK! O ID do usuário para depuração é: ", local_id)
	
	# Esconde os botões de login/registro e mostra o de logout
	register_button.visible = false
	login_button.visible = false
	email_input.visible = false
	password_input.visible = false
	logout_button.visible = true

func _on_registration_failed(error_message: String):
	feedback_label.text = "Falha no cadastro: " + error_message
	print("Cadastro Falhou: ", error_message)

func _on_login_succeeded(local_id: String, id_token: String):
	feedback_label.text = "Login realizado com sucesso!"
	print("Login OK! O ID do usuário para depuração é: ", local_id)

	# Esconde os botões de login/registro e mostra o de logout
	#register_button.visible = false
	#login_button.visible = false
	#email_input.visible = false
	#password_input.visible = false
	logout_button.visible = true

	# get_tree().change_scene_to_file("res://main_menu.tscn")

func _on_login_failed(error_message: String):
	feedback_label.text = "Falha no login: " + error_message
	print("Login Falhou: ", error_message)
