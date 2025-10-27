extends Node

# save_system.gd

# Sinais para avisar a interface
signal save_succeeded
signal save_failed
signal load_succeeded(data)
signal load_failed

# --- CONFIGURAÇÃO ---
# 1. Vá no Firebase Realtime Database
# 2. Copie a URL do seu banco (ex: https://meu-projeto-default-rtdb.firebaseio.com/)
# 3. COLE A URL AQUI!
var DATABASE_URL = "https://godot-mobile-auth-default-rtdb.firebaseio.com/"


# --- FUNÇÕES PÚBLICAS ---

# Recebe um dicionário (ex: {"moedas": 10}) e salva na nuvem
func save_data(data: Dictionary):
	# Se não estivermos logados, não faz nada
	if Auth.id_token.is_empty() or Auth.local_id.is_empty():
		print("Save System: Usuário não está logado.")
		save_failed.emit()
		return
		
	# Montamos a URL específica do usuário
	# O .json no final é OBRIGATÓRIO para a API do Realtime Database!
	var url = DATABASE_URL + "/users/" + Auth.local_id + ".json?auth=" + Auth.id_token
	
	# O método 'PUT' substitui *todos* os dados lá.
	# O corpo é só o JSON simples dos nossos dados.
	_send_request(url, HTTPClient.METHOD_PUT, "save", JSON.stringify(data))


# Busca os dados do usuário na nuvem
func load_data():
	if Auth.id_token.is_empty() or Auth.local_id.is_empty():
		print("Save System: Usuário não está logado.")
		load_failed.emit()
		return
	
	# A URL de "ler" é idêntica à de "salvar"
	var url = DATABASE_URL + "/users/" + Auth.local_id + ".json?auth=" + Auth.id_token
	
	# O método 'GET' apenas "lê" os dados.
	_send_request(url, HTTPClient.METHOD_GET, "load")


# --- FUNÇÕES INTERNAS (HTTP) ---
# (Isto é quase idêntico ao auth.gd)

func _send_request(url: String, method: HTTPClient.Method, request_type: String, body: String = "") -> void:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	http_request.request_completed.connect(
		func(result, response_code, headers, response_body):
			_on_request_completed(result, response_code, headers, response_body, request_type, http_request)
	)

	# Headers para a API (só no PUT)
	var headers = ["Content-Type: application/json"]
	
	var error
	if method == HTTPClient.METHOD_PUT:
		error = http_request.request(url, headers, method, body)
	else: # GET
		error = http_request.request(url, headers, method)
	
	if error != OK:
		print("Erro ao iniciar a requisição: ", error)
		if request_type == "save":
			save_failed.emit()
		else:
			load_failed.emit()
		http_request.queue_free()

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, request_type: String, http_node: HTTPRequest) -> void:
	
	var json = JSON.new()
	var body_string = body.get_string_from_utf8()
	
	# Se a resposta estiver vazia (ex: no 'load' de um usuário novo),
	# tratamos como um dicionário vazio.
	if body_string.is_empty() or body_string == "null":
		if request_type == "load":
			load_succeeded.emit({}) # Emite um dicionário vazio
		http_node.queue_free()
		return
	
	var parse_error = json.parse(body_string)
	
	if parse_error != OK:
		print("Erro de parse do JSON: ", json.get_error_message())
		if request_type == "save":
			save_failed.emit()
		else:
			load_failed.emit()
		http_node.queue_free()
		return

	var response_data = json.get_data()
	
	# Se a resposta tiver um erro do Firebase (ex: "Permission denied")
	if response_data.has("error"):
		print("Erro do Firebase: ", response_data["error"])
		if request_type == "save":
			save_failed.emit()
		else:
			load_failed.emit()
	
	# Se deu tudo certo
	else:
		if request_type == "save":
			print("Dados salvos com sucesso!")
			save_succeeded.emit()
		elif request_type == "load":
			print("Dados carregados: ", response_data)
			# response_data aqui JÁ é o nosso dicionário (ex: {"moedas": 10})
			load_succeeded.emit(response_data)
	
	http_node.queue_free()
