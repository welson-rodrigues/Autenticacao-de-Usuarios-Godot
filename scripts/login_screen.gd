extends Control

# login_screen.gd
# Este script controla a *interface* de login.
# Ele não sabe *como* o login é feito, ele apenas:
# 1. Pega os dados dos campos de texto (LineEdit).
# 2. Envia os dados para o script 'auth.gd'.
# 3. Ouve os sinais do 'auth.gd' para mostrar mensagens de sucesso/erro.

# --- REFERÊNCIAS DA INTERFACE (@onready) ---
# Usamos @onready para garantir que o nó já exista na cena
# antes de tentarmos acessá-lo.
@onready var email_input: LineEdit = $VBoxContainer/EmailInput
@onready var password_input: LineEdit = $VBoxContainer/PasswordInput
@onready var register_button: Button = $VBoxContainer/HBoxContainer/RegisterButton
@onready var login_button: Button = $VBoxContainer/HBoxContainer/LoginButton
@onready var feedback_label: Label = $VBoxContainer/FeedbackLabel
@onready var logout_button: Button = $VBoxContainer/HBoxContainer/LogoutButton # Botão de Sair

# Esta é a referência ao nosso nó "cérebro", o Auth.
@onready var auth: Node = $VBoxContainer/HBoxContainer/LoginButton/Auth


# --- FUNÇÃO DE INICIALIZAÇÃO ---
# _ready é chamada quando a cena é iniciada.
# Nós a usamos para "conectar os fios".
func _ready():
	# --- CONECTANDO SINAIS DOS BOTÕES ---
	# Conecta o sinal 'pressed' (clique) de cada botão a uma função deste script.
	register_button.pressed.connect(_on_register_button_pressed)
	login_button.pressed.connect(_on_login_button_pressed)
	logout_button.pressed.connect(_on_logout_button_pressed)
	
	# --- CONECTANDO SINAIS DO AUTH.GD ---
	# Aqui nós "ouvimos" os sinais que o auth.gd vai emitir.
	# Quando o auth.gd emitir 'registration_succeeded', ele chama nossa função '_on_registration_succeeded'.	auth.registration_succeeded.connect(_on_registration_succeeded)
	auth.registration_failed.connect(_on_registration_failed)
	auth.login_succeeded.connect(_on_login_succeeded)
	auth.login_failed.connect(_on_login_failed)
	
	# Começamos mostrando a tela no estado "deslogado".
	_update_ui_for_logout()


# --- FUNÇÕES DE AÇÃO (O que acontece ao clicar) ---

# Chamada quando o botão "Cadastrar" é pressionado.
func _on_register_button_pressed():
	var email = email_input.text
	var password = password_input.text
	
	# Validação simples para não enviar dados vazios.
	if email.is_empty() or password.is_empty():
		feedback_label.text = "Por favor, preencha e-mail e senha."
		return
	
	# Damos um feedback visual imediato.
	feedback_label.text = "Registrando..."
	
	# Mandamos o "cérebro" (auth.gd) fazer o trabalho dele.
	auth.register_user(email, password)

# Chamada quando o botão "Entrar" é pressionado.
func _on_login_button_pressed():
	var email = email_input.text
	var password = password_input.text

	if email.is_empty() or password.is_empty():
		feedback_label.text = "Por favor, preencha e-mail e senha."
		return
	
	feedback_label.text = "Entrando..."
	
	# Mandamos o "cérebro" (auth.gd) fazer o trabalho dele.
	auth.login_user(email, password)

# Chamada quando o botão "Sair" é pressionado.
func _on_logout_button_pressed():
	# Manda o "cérebro" (auth.gd) deslogar.
	auth.logout()
	
	# Atualiza a interface para o estado "deslogado".
	_update_ui_for_logout()
	feedback_label.text = "Você saiu."


# --- FUNÇÕES DE REAÇÃO (O que acontece quando o Auth.gd responde) ---

# Esta função é chamada pelo *sinal* do auth.gd
func _on_registration_succeeded(local_id: String):
	# Mostramos o feedback de sucesso.
	# NÃO mostramos o ID ou Token na tela, apenas no console para depuração.
	feedback_label.text = "Cadastro realizado com sucesso!"
	print("Cadastro OK! O ID do usuário para depuração é: ", local_id)
	
	# Atualizamos a interface para o estado "logado".
	_update_ui_for_login()

# Esta função é chamada pelo *sinal* do auth.gd
func _on_registration_failed(error_message: String):
	# Mostramos a mensagem de erro amigável que o auth.gd nos enviou.
	feedback_label.text = "Falha no cadastro: " + error_message
	print("Cadastro Falhou: ", error_message)

# Esta função é chamada pelo *sinal* do auth.gd
func _on_login_succeeded(local_id: String, id_token: String):
	feedback_label.text = "Login realizado com sucesso!"
	print("Login OK! O ID do usuário para depuração é: ", local_id)
	
	# Atualizamos a interface para o estado "logado".
	_update_ui_for_login()
	
	# NOTA: Em um jogo real, aqui é onde você mudaria para a cena principal:
	# get_tree().change_scene_to_file("res://main_menu.tscn")

# Esta função é chamada pelo *sinal* do auth.gd
func _on_login_failed(error_message: String):
	feedback_label.text = "Falha no login: " + error_message
	print("Login Falhou: ", error_message)


# --- FUNÇÕES AUXILIARES DE UI ---

# Centraliza a lógica de mostrar/esconder coisas quando estamos logados.
func _update_ui_for_login():
	# Esconde os campos de texto e botões de login
	#email_input.visible = false
	#password_input.visible = false
	#register_button.visible = false
	#login_button.visible = false
	
	# Mostra o botão de sair
	logout_button.visible = true

# Centraliza a lógica para o estado deslogado.
func _update_ui_for_logout():
	# Mostra os campos de texto e botões de login
	email_input.visible = true
	password_input.visible = true
	register_button.visible = true
	login_button.visible = true
	
	# Limpa os campos de texto
	email_input.text = ""
	password_input.text = ""
	
	# Esconde o botão de sair
	logout_button.visible = false
