extends Node

# sinal quando o cadastro dá certo ou errado.
signal registration_succeeded(local_id)
signal registration_failed(error_message)

# login dá certo ou errado.
signal login_succeeded(local_id, id_token)
signal login_failed(error_message)

# API fica aqui
var FIREBASE_API_KEY: String = ""

# id_token é a chave temporária
# local_id é o ID permanente do usuário no Firebase
var id_token: String = ""
var local_id: String = ""


# chama a função para carregar a api
func _ready():
	_load_api_key()

# Guardando a api num aquivo
func _load_api_key():
	var config = ConfigFile.new()
	var err = config.load("res://secrets.cfg")
	
	if err != OK:
		print("ERRO: Não foi possível carregar o 'secrets.cfg'.")
		print("Certifique-se de que o arquivo existe e tem a sua [firebase] api_key.")
	else:
		FIREBASE_API_KEY = config.get_value("firebase", "api_key", "")
		if FIREBASE_API_KEY.is_empty():
			print("ERRO: 'api_key' não encontrada dentro de [firebase] no 'secrets.cfg'")

func register_user(email, password):
	if FIREBASE_API_KEY.is_empty():
		print("API Key não carregada. Verifique o 'secrets.cfg'.")
		return

	# Este é o endpoint (URL) do Firebase para criar contas
	var url = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=" + FIREBASE_API_KEY
	
	# Estes são os dados que o Firebase espera (email, senha).
	var body = {
		"email": email,
		"password": password,
		"returnSecureToken": true
	}
	
	_send_request(url, body, "register")

# A tela de login vai chamar esta função para logar um usuário.
func login_user(email, password):
	if FIREBASE_API_KEY.is_empty():
		print("API Key não carregada. Verifique o 'secrets.cfg'.")
		return

	# O endpoint de login é diferente (signInWithPassword).
	var url = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=" + FIREBASE_API_KEY
	var body = {
		"email": email,
		"password": password,
		"returnSecureToken": true
	}
	_send_request(url, body, "login")

# A tela de login chama esta função para deslogar.
func logout():
	id_token = ""
	local_id = ""
	print("Usuário deslogado com sucesso.")

# Esta é a função principal que faz a comunicação HTTP.
func _send_request(url: String, body: Dictionary, request_type: String) -> void:
	# HTTPRequest em tempo real (via código).
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	http_request.request_completed.connect(
		func(result, response_code, headers, response_body):
			_on_request_completed(result, response_code, headers, response_body, request_type, http_request)
	)

	# enviando dados no formato JSON.
	var headers = ["Content-Type: application/json"]
	
	# convertendo o body para string JSON
	var body_string = JSON.stringify(body)
	
	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, body_string)
	
	# Se falhar vai avisar aqui
	if error != OK:
		print("Erro ao iniciar a requisição: ", error)
		if request_type == "register":
			registration_failed.emit("Erro de conexão inicial.")
		else:
			login_failed.emit("Erro de conexão inicial.")
		http_request.queue_free() # Limpa o nó.

# Quando o Firebase responde
func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, request_type: String, http_node: HTTPRequest) -> void:
	var json = JSON.new()
	
	var body_string = body.get_string_from_utf8()
	
	var parse_error = json.parse(body_string)
	if parse_error != OK:
		print("Erro de parse do JSON: ", json.get_error_message())
		if request_type == "register":
			registration_failed.emit("Resposta inválida do servidor.")
		else:
			login_failed.emit("Resposta inválida do servidor.")
		http_node.queue_free() # Limpa o nó.
		return

	var response_data = json.get_data()

	if response_data.has("error"):

		var error_code = response_data["error"]["message"]
		print("Erro do Firebase (código): ", error_code)
		
		var translated_message = _translate_firebase_error(error_code)
	
		if request_type == "register":
			registration_failed.emit(translated_message)
		else:
			login_failed.emit(translated_message)
	
	elif response_data.has("idToken"):
		id_token = response_data["idToken"]
		local_id = response_data["localId"]
		print("Sucesso! Tipo: ", request_type, " | ID do Usuário: ", local_id)
		
		if request_type == "register":
			registration_succeeded.emit(local_id)
		else:
			login_succeeded.emit(local_id, id_token)
	else:
		print("Resposta desconhecida do Firebase: ", response_data)
		if request_type == "register":
			registration_failed.emit("Ocorreu um erro desconhecido.")
		else:
			login_failed.emit("Ocorreu um erro desconhecido.")
	
	http_node.queue_free()

func _translate_firebase_error(error_code: String) -> String:
	match error_code:
		"EMAIL_EXISTS":
			return "Este e-mail já está em uso."
		"EMAIL_NOT_FOUND":
			return "E-mail não encontrado."
		"INVALID_PASSWORD":
			return "Senha incorreta."
		"WEAK_PASSWORD":
			return "Senha muito fraca (precisa ter no mínimo 6 caracteres)."
		"INVALID_EMAIL":
			return "O formato do e-mail é inválido."
		"MISSING_PASSWORD":
			return "Por favor, digite uma senha."
		# Você pode adicionar mais traduções aqui
		_:
			return "Ocorreu um erro: (" + error_code + ")"
