extends Control

signal authentication_successfull

@onready var http: HTTPRequest = $HTTPRequest

@onready var server_container = $PanelContainer/MarginContainer/VBoxContainer/ServerSelectionMarginContainer/ScrollContainer/VBoxContainer
@onready var server_name = $PanelContainer/MarginContainer/VBoxContainer/Panel/ConnectionMarginContainer/VBoxContainer/ServerName

@onready var username_input = $PanelContainer/MarginContainer/VBoxContainer/Panel/ConnectionMarginContainer/VBoxContainer/UsernameInput
@onready var password_input = $PanelContainer/MarginContainer/VBoxContainer/Panel/ConnectionMarginContainer/VBoxContainer/PasswordInput

@onready var error_label = $PanelContainer/MarginContainer/VBoxContainer/Panel/ConnectionMarginContainer/VBoxContainer/ErrorLabel

var servers: Array = []

func _ready() -> void:
	# Virer tout les serveurs de test
	for child in server_container.get_children():
		child.queue_free()
	
	# Récupérer les serveurs existants
	reset_http_signal()
	http.connect("request_completed", Callable(self, "_on_server_received"))
	
	var url = "https://daoh-master.donnarieix.fr/api/node/list"
	
	var err = http.request(
		url,
		[],
		HTTPClient.METHOD_POST
	)
	
	if err != OK:
		print("Erreur lors de l'envoi de la requête :", err)

func _empty_error_label() -> void:
	error_label.text = ""

func _on_server_received(_result, response_code, _headers, body) -> void:
	if response_code == 200:
		var data = JSON.parse_string(body.get_string_from_utf8())
		if data == []:
			print("Erreur lors de la récupération des serveurs")
			return
		
		for server in data:
			servers.append({
				"id": server["id"],
				"name": server["name"],
				"address": server["address"]
			})
			
			var button = Button.new()
			server_container.add_child(button)
			button.text = server["name"]
			button.set("theme_override_font_sizes/font_size", 24)
			button.pressed.connect(func(): _on_server_pressed(server["id"]))
		
		# Par défaut sélectionner le premier
		_on_server_pressed(servers[0]["id"])
	else:
		print("Erreur inconnue :", response_code)

func _on_server_pressed(id: int) -> void:
	var server = get_server_by_id(id)
	if server == {}:
		print("Erreur lors de la récupération du serveur")
		return
	
	server_name.text = "Connexion à " + server["name"]
	server_name.set_meta("id", server["id"])
	
	_empty_error_label()

func get_server_by_id(id: int) -> Dictionary:
	for server in servers:
		if server["id"] == id:
			return server
	
	return {}

func _on_connect_button_pressed() -> void:
	if not server_name.has_meta("id"):
		print("Aucun serveur selectionné")
		return
	var server = get_server_by_id(server_name.get_meta("id"))
	
	reset_http_signal()
	http.connect("request_completed", Callable(self, "_on_connection_attempted"))
	
	var url = "https://" + server["address"] + "/login"
	
	var err = http.request(
		url,
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify({
			"username": username_input.text,
			"password": password_input.text
		})
	)
	
	if err != OK:
		print("Erreur lors de l'envoi de la requête :", err)

func _on_connection_attempted(_result, response_code, _headers, body) -> void:
	if response_code == 200:
		MULTIPLAYER.token = JSON.parse_string(body.get_string_from_utf8())["token"]
		get_port()
	elif response_code == 401:
		error_label.text = "Mauvais mot de passe et/ou nom d'utilisateur"
	else:
		print("Erreur inconnue :", response_code)

func get_port() -> void:
	if not server_name.has_meta("id"):
		print("Aucun serveur selectionné")
		return
	var server = get_server_by_id(server_name.get_meta("id"))
	
	reset_http_signal()
	http.connect("request_completed", Callable(self, "_on_port_received"))
	
	http.request(
		"https://" + server["address"] + "/api/get",
		[
			"Content-Type: application/json",
			"Authorization: Bearer " + MULTIPLAYER.token
		],
		HTTPClient.METHOD_POST,
	)

func _on_port_received(_result, response_code, _headers, body) -> void:
	if response_code == 200:
		var data = JSON.parse_string(body.get_string_from_utf8())
		MULTIPLAYER.LISTEN_PORT = data["port"]
		
		authentication_successfull.emit()
	elif response_code == 401:
		var data = JSON.parse_string(body.get_string_from_utf8())
		
		if data["message"] == "Expired JWT Token":
			# Token expiré, nouvelle tentative de connexion
			_on_connect_button_pressed()
		else:
			# Mauvais identifiants
			error_label.text = "Mauvais mot de passe et/ou nom d'utilisateur"
	else:
		print("Erreur inconnue :", response_code)

func reset_http_signal():
	for callback in [
		Callable(self, "_on_server_received"),
		Callable(self, "_on_connection_attempted"),
		Callable(self, "_on_port_received")
	]:
		if http.is_connected("request_completed", callback):
			http.disconnect("request_completed", callback)
