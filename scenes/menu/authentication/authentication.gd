extends Control

signal authentication_successfull

@onready var http: HTTPRequest = $HTTPRequest

@onready var server_container = $Panel/MenuBG/ServerContainer/ServerSelectionMarginContainer/ScrollContainer/VBoxContainer
@onready var server_name_login = $Panel/MenuBG/LoginContainer/VBoxContainer/Options
@onready var server_name: Label = $Panel/MenuBG/ServerContainer/VBoxContainer/Serveur

@onready var main_server_container: VBoxContainer = $Panel/MenuBG/ServerContainer
@onready var main_login_container: VBoxContainer = $Panel/MenuBG/LoginContainer

@onready var username_input = $Panel/MenuBG/LoginContainer/VBoxContainer4/UsernameInput
@onready var password_input = $Panel/MenuBG/LoginContainer/VBoxContainer4/PasswordInput

@onready var error_label = $Panel/MenuBG/LoginContainer/VBoxContainer4/ErrorLabel

@onready var server_panel: VBoxContainer = $Panel/MenuBG/ServerContainer
@onready var login_panel: VBoxContainer = $Panel/MenuBG/LoginContainer

@onready var login_type_button: Button = $Panel/MenuBG/LoginContainer/VBoxContainer2/TypeMenu/Login
@onready var register_type_button: Button = $Panel/MenuBG/LoginContainer/VBoxContainer2/TypeMenu/Register

@onready var connect_button: Button = $Panel/MenuBG/LoginContainer/VBoxContainer3/ConnectButton
@onready var register_button: Button = $Panel/MenuBG/LoginContainer/VBoxContainer3/RegisterButton

var state = "login"
var panel_selected = preload("res://addons/menu/panel_brown_arrows_dark_detail.png")
var panel = preload("res://addons/menu/panel_brown_damaged_dark.png")
var font = preload("res://addons/menu/AveriaGruesaLibre-Regular.ttf")

func _ready() -> void:
	main_server_container.show()
	main_login_container.hide()
	
	_update_button_styles()
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
	error_label.visible = false
	error_label.text = ""

func _on_server_received(_result, response_code, _headers, body) -> void:
	if response_code == 200:
		var data = JSON.parse_string(body.get_string_from_utf8())
		if data == []:
			print("Erreur lors de la récupération des serveurs")
			return
		
		for server in data:
			MULTIPLAYER.servers.append({
				"id": server["id"],
				"name": server["name"],
				"address": server["address"]
			})
			
			var button = Button.new()
			var theme := Theme.new()
			var stylebox_normal := StyleBoxFlat.new()
			var stylebox_hover = StyleBoxFlat.new()
			var stylebox_pressed = StyleBoxFlat.new()
			
			stylebox_normal.bg_color = Color('#6D4B27')
			stylebox_normal.set_corner_radius_all(3)
			stylebox_normal.set_content_margin_all(8)
			theme.set_stylebox("normal", "Button", stylebox_normal)
			theme.set_color("font_color", "Button", Color('#fff1d2'))
			theme.set_font("font", "Button", font)
			theme.set_color("font_color_hover", "Button", Color('#fff1d2'))
			theme.set_color("font_color_pressed", "Button", Color('#fff1d2'))
			

			stylebox_hover.bg_color = Color('#614426')
			stylebox_hover.set_corner_radius_all(3)
			stylebox_hover.set_content_margin_all(8)
			theme.set_stylebox("hover", "Button", stylebox_hover)

			
			stylebox_pressed.bg_color = Color('#5b4024')
			stylebox_pressed.set_corner_radius_all(3)
			stylebox_pressed.set_content_margin_all(8)
			theme.set_stylebox("pressed", "Button", stylebox_pressed)

			server_container.add_child(button)
			button.theme = theme
			button.text = server["name"]
			button.set("theme_override_font_sizes/font_size", 24)
			button.pressed.connect(func(): _on_server_pressed(server["id"]))
		
		# Par défaut sélectionner le premier
		_on_server_pressed(MULTIPLAYER.servers[0]["id"])
	else:
		print("Erreur inconnue :", response_code)

func _on_server_pressed(id: int) -> void:
	var server = MULTIPLAYER.get_server_by_id(id)
	if server == {}:
		print("Erreur lors de la récupération du serveur")
		return
	
	server_name.text = server["name"]
	server_name_login.text = server["name"]
	MULTIPLAYER.current_server = server["id"]
	
	_empty_error_label()

func _on_connect_button_pressed() -> void:
	if MULTIPLAYER.current_server == 0:
		print("Aucun serveur selectionné")
		return
	var server = MULTIPLAYER.get_server_by_id(MULTIPLAYER.current_server)
	MULTIPLAYER.username = username_input.text
	MULTIPLAYER.password = password_input.text
	
	reset_http_signal()
	http.connect("request_completed", Callable(self, "_on_connection_attempted"))
	
	var url = "https://" + server["address"] + "/login"
	
	var err = http.request(
		url,
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify({
			"username": MULTIPLAYER.username,
			"password": MULTIPLAYER.password
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
		error_label.visible = true
	else:
		print("Erreur inconnue :", response_code)

func get_port() -> void:
	if MULTIPLAYER.current_server == 0:
		print("Aucun serveur selectionné")
		return
	var server = MULTIPLAYER.get_server_by_id(MULTIPLAYER.current_server)
	
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
		MULTIPLAYER.REGION = data["region"]
		MULTIPLAYER.LISTEN_PORT = data["port"]
		MULTIPLAYER.MAX_CHARACTER_COUNT = data["max_character_count"]
		
		authentication_successfull.emit()
	elif response_code == 401:
		var data = JSON.parse_string(body.get_string_from_utf8())
		
		if data["message"] == "Expired JWT Token":
			# Token expiré, nouvelle tentative de connexion
			_on_connect_button_pressed()
		else:
			# Mauvais identifiants
			error_label.text = "Mauvais mot de passe et/ou nom d'utilisateur"
			error_label.visible = true
	else:
		print("Erreur inconnue :", response_code)

func _on_register_button_pressed() -> void:
	if MULTIPLAYER.current_server == 0:
		print("Aucun serveur selectionné")
		return
	var server = MULTIPLAYER.get_server_by_id(MULTIPLAYER.current_server)
	
	reset_http_signal()
	http.connect("request_completed", Callable(self, "_on_register_attempted"))
	
	var url = "https://" + server["address"] + "/register"
	
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

func _on_register_attempted(_result, response_code, _headers, _body) -> void:
	if response_code == 201:
		error_label.text = "Inscription réussie"
		error_label.visible = true
	else:
		print("Erreur inconnue :", response_code)

func reset_http_signal():
	for callback in [
		Callable(self, "_on_server_received"),
		Callable(self, "_on_connection_attempted"),
		Callable(self, "_on_port_received"),
		Callable(self, "_on_register_attempted")
	]:
		if http.is_connected("request_completed", callback):
			http.disconnect("request_completed", callback)

func _on_login_pressed() -> void:
	if state != "login":
		state = "login"
		_update_button_styles()
		connect_button.visible = true
		register_button.visible = false

func _on_register_pressed() -> void:
	if state != "register":
		state = "register"
		_update_button_styles()
		connect_button.visible = false
		register_button.visible = true

func _update_button_styles() -> void:
	var selected_stylebox = StyleBoxTexture.new()
	selected_stylebox.texture = panel_selected

	var default_stylebox = StyleBoxTexture.new()
	default_stylebox.texture = panel

	if state == "login":
		login_type_button.add_theme_stylebox_override("normal", selected_stylebox)
		register_type_button.add_theme_stylebox_override("normal", default_stylebox)
		
		login_type_button.add_theme_stylebox_override("hover", selected_stylebox)
		register_type_button.add_theme_stylebox_override("hover", default_stylebox)
	else:
		login_type_button.add_theme_stylebox_override("normal", default_stylebox)
		register_type_button.add_theme_stylebox_override("normal", selected_stylebox)
		
		login_type_button.add_theme_stylebox_override("hover", default_stylebox)
		register_type_button.add_theme_stylebox_override("hover", selected_stylebox)

func _on_continuer_pressed() -> void:
	server_panel.hide()
	login_panel.show()

func _on_back_button_pressed() -> void:
	get_tree().root.get_node("Main").authentication_back_pressed()

func reset_view() -> void:
	server_panel.show()
	login_panel.hide()
