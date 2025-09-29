extends Node

var FIREBASE_API_KEY = "chave"
var id_token = ""
var local_id = ""

func register_user(email, password):
	var url = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=" + FIREBASE_API_KEY
	var data = { "email": email, "password": password, "returnSecureToken": true }
	_send_request(url, data)

func login_user(email, password):
	var url = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=" + FIREBASE_API_KEY
	var data = { "email": email, "password": password, "returnSecureToken": true }
	_send_request(url, data)

func _send_request(url, data):
	var http = HTTPRequest.new()
	add_child(http)
	http.request(url, [], true, HTTPClient.METHOD_POST, JSON.stringify(data))
