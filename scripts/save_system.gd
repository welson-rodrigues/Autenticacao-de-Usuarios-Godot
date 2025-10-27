extends Node

signal save_succeeded
signal save_failed
signal load_succeeded(data)
signal load_failed

# Copie a URL do seu banco
var DATABASE_URL = "https://godot-mobile-auth-default-rtdb.firebaseio.com/"

func save_data(data: Dictionary):
	if Auth.id_token.is_empty() or Auth.local_id.is_empty():
		print("Save System: Usuário não está logado.")
		save_failed.emit()
		return
		
	# Montamos a URL
	var url = DATABASE_URL + "/users/" + Auth.local_id + ".json?auth=" + Auth.id_token

	_send_request(url, HTTPClient.METHOD_PUT, "save", JSON.stringify(data))


# Busca os dados do usuário na nuvem
func load_data():
	if Auth.id_token.is_empty() or Auth.local_id.is_empty():
		print("Save System: Usuário não está logado.")
		load_failed.emit()
		return

	var url = DATABASE_URL + "/users/" + Auth.local_id + ".json?auth=" + Auth.id_token
	
	_send_request(url, HTTPClient.METHOD_GET, "load")

func _send_request(url: String, method: HTTPClient.Method, request_type: String, body: String = "") -> void:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	http_request.request_completed.connect(
		func(result, response_code, headers, response_body):
			_on_request_completed(result, response_code, headers, response_body, request_type, http_request)
	)
	
	var headers = ["Content-Type: application/json"]
	
	var error
	if method == HTTPClient.METHOD_PUT:
		error = http_request.request(url, headers, method, body)
	else: 
		error = http_request.request(url, headers, method)
	
	if error != OK:
		print("Erro ao iniciar a requisição: ", error)
		if request_type == "save":
			save_failed.emit()
		else:
			load_failed.emit()
		http_request.queue_free()

# Transforma a resposta de bytes em texto
func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, request_type: String, http_node: HTTPRequest) -> void:
	
	var json = JSON.new()
	var body_string = body.get_string_from_utf8()

	if body_string.is_empty() or body_string == "null":
		if request_type == "load":
			load_succeeded.emit({}) 
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
	
	# Se a resposta tiver um erro do Firebase
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
			load_succeeded.emit(response_data)
	
	http_node.queue_free()
