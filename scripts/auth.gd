extends Node
signal registration_succeeded(local_id)
signal registration_failed(error_message)
signal login_succeeded(local_id, id_token)
signal login_failed(error_message)

# Substitua pela sua Web API Key do Firebase
var FIREBASE_API_KEY = ""

var id_token: String = ""
var local_id: String = ""

func _ready():
	_load_api_key()

func _load_api_key():
	var config = ConfigFile.new()
	# Tenta carregar o nosso arquivo de segredos
	var err = config.load("res://secrets.cfg")
	
	if err != OK:
		print("ERRO: Não foi possível carregar o 'secrets.cfg'.")
		print("Certifique-se de que o arquivo existe e tem a sua [firebase] api_key.")
	else:
		# Carrega a chave do arquivo e a armazena na variável
		FIREBASE_API_KEY = config.get_value("firebase", "api_key", "")
		if FIREBASE_API_KEY.is_empty():
			print("ERRO: 'api_key' não encontrada dentro de [firebase] no 'secrets.cfg'")

func register_user(email, password):
	var url = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=" + FIREBASE_API_KEY
	var body = {
		"email": email,
		"password": password,
		"returnSecureToken": true
	}
	_send_request(url, body, "register")

func login_user(email, password):
	var url = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=" + FIREBASE_API_KEY
	var body = {
		"email": email,
		"password": password,
		"returnSecureToken": true
	}
	_send_request(url, body, "login")

func _send_request(url: String, body: Dictionary, request_type: String) -> void:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	http_request.request_completed.connect(
		func(result, response_code, headers, response_body):
			_on_request_completed(result, response_code, headers, response_body, request_type, http_request)
	)

	var headers = ["Content-Type: application/json"]
	
	var body_string = JSON.stringify(body)
	
	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, body_string)
	
	if error != OK:
		print("Erro ao iniciar a requisição: ", error)
		if request_type == "register":
			registration_failed.emit("Erro de conexão inicial.")
		else:
			login_failed.emit("Erro de conexão inicial.")
		http_request.queue_free()

func _on_request_completed(result: int,
response_code: int,
headers: PackedStringArray,
body: PackedByteArray,
request_type: String,
http_node: HTTPRequest) -> void:
		
	var json = JSON.new()
	var body_string = body.get_string_from_utf8()
	
	var parse_error = json.parse(body_string)
	if parse_error != OK:
		print("Erro de parse do JSON: ", json.get_error_message())
		if request_type == "register":
			registration_failed.emit("Resposta inválida do servidor.")
		else:
			login_failed.emit("Resposta inválida do servidor.")
		http_node.queue_free()
		return

	var response_data = json.get_data()

	if response_data.has("error"):
		var error_message = response_data["error"]["message"]
		print("Erro do Firebase: ", error_message)
		if request_type == "register":
			registration_failed.emit(error_message)
		else:
			login_failed.emit(error_message)
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
	
func logout():
	id_token = ""
	local_id = ""
	print("Usuário deslogado com sucesso.")
