extends Control

#@onready var knight: Node3D = $Skins/Knight
#@onready var barbarian: Node3D = $Skins/Barbarian
#@onready var mage: Node3D = $Skins/Mage
#@onready var rogue: Node3D = $Skins/Rogue
@onready var label: Label = $Panel/MenuBG/Bandeau/Label
@onready var rich_text_label: RichTextLabel = $Panel/MenuBG/VBoxContainer/VBoxContainer/RichTextLabel

@onready var chevalier_button: Button = $HBoxContainer/VBoxContainer2/Chevalier
@onready var barbare_button: Button = $HBoxContainer/VBoxContainer2/VBoxContainer/Barbare
@onready var voleur_button: Button = $HBoxContainer/VBoxContainer/Voleur
@onready var mage_button: Button = $HBoxContainer/VBoxContainer/Mage

@onready var players_picker_margin: MarginContainer = $PlayersPickerMargin
@onready var class_desc: Panel = $Panel
@onready var class_picker: HBoxContainer = $HBoxContainer

###> Gestion des personnages ###
@onready var http: HTTPRequest = $HTTPRequest
@onready var new_character_panel_container: TextureRect = $NewPlayer
@onready var character_container: HBoxContainer = $PlayersPickerMargin/VBoxContainer/HBoxContainer/PlayerPickers
@onready var character_name_input: LineEdit = $NewPlayer/MarginContainer/VBoxContainer/CharacterNameInput

var _relogin_callback: Callable = Callable()
###< Gestion des personnages ###

var panel_selected = preload("res://addons/menu/round_damaged_brown.png")
var panel = preload("res://addons/menu/round_damaged_brown_dark.png")

var selected_stylebox = StyleBoxTexture.new()
var default_stylebox = StyleBoxTexture.new()

signal class_selected(classes_name: String)
var selected_skin: String

var description = {
	"Chevalier": "Noble guerrier en armure lourde, le Chevalier incarne l'honneur et la défense. Il manie l’épée et le bouclier avec brio, protégeant ses alliés et tenant la ligne face à l’ennemi. Grâce à sa robustesse et ses compétences défensives, il est le pilier de toute escouade.",
	"Voleur": "Rapide, agile et rusé, le Voleur frappe dans l’ombre avant de disparaître. Maître des attaques critiques et de l’évasion, il utilise dagues, poisons et techniques de furtivité pour éliminer ses cibles sans être vu. L’ennemi ne le voit jamais venir.",
	"Mage": "Maître des arcanes, le Mage puise son pouvoir dans les éléments. Qu’il déchaîne le feu, le givre ou la foudre, il inflige des dégâts massifs à distance. Bien qu’il soit fragile, sa puissance mystique peut renverser le cours d’une bataille en un instant.",
	"Barbare": "Furie incarnée, le Barbare est une brute sauvage qui charge dans la mêlée sans crainte. Armé de haches ou de massues, il utilise sa rage pour infliger des dégâts colossaux. Plus il est blessé, plus il devient dangereux. Il est la tempête dans le chaos du champ de bataille."
}

func _ready() -> void:
	# Skin par défaut : Knight
	_on_knight_pressed()
	
	###> Gestion des personnages ###
	players_picker_margin.show()
	new_character_panel_container.hide()
	###< Gestion des personnages ###

func _on_knight_pressed() -> void:
	selected_skin = "Knight"
	emit_signal("class_selected", selected_skin)
	_update_skin(selected_skin)

func _on_barbarian_pressed() -> void:
	selected_skin = "Barbarian"
	emit_signal("class_selected", selected_skin)
	_update_skin(selected_skin)

func _on_rogue_pressed() -> void:
	selected_skin = "Rogue"
	emit_signal("class_selected", selected_skin)
	_update_skin(selected_skin)

func _on_mage_pressed() -> void:
	selected_skin = "Mage"
	emit_signal("class_selected", selected_skin)
	_update_skin(selected_skin)

func _update_skin(skin):
	selected_stylebox.texture = panel_selected
	default_stylebox.texture = panel
	#knight.hide()
	#barbarian.hide()
	#mage.hide()
	#rogue.hide()
	
	update_theme(chevalier_button, default_stylebox)
	update_theme(barbare_button, default_stylebox)
	update_theme(voleur_button, default_stylebox)
	update_theme(mage_button, default_stylebox)
	
	if skin == "Knight":
		#knight.show()
		label.text = "Chevalier"
		update_theme(chevalier_button, selected_stylebox)
	elif skin == "Barbarian":
		#barbarian.show()
		label.text = "Barbare"
		update_theme(barbare_button, selected_stylebox)
	elif skin == "Mage":
		#mage.show()
		label.text = "Mage"
		update_theme(mage_button, selected_stylebox)
	elif skin == "Rogue":
		#rogue.show()
		label.text = "Voleur"
		update_theme(voleur_button, selected_stylebox)
	rich_text_label.text = description[label.text]

func _on_join_pressed() -> void:
	var world_scene = preload("res://scenes/world/world.tscn")
	var world = world_scene.instantiate()
	world.set_meta("server", false)
	world.set_meta("selected_skin", selected_skin)
	
	get_tree().root.add_child(world)
	get_tree().set_current_scene(world)
	get_tree().root.get_node("Main").queue_free()

func update_theme(button, texture):
	button.add_theme_stylebox_override("normal", texture)
	button.add_theme_stylebox_override("hover", texture)
	button.add_theme_stylebox_override("pressed", texture)
	button.add_theme_stylebox_override("focus", texture)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/home/home_menu.tscn")

func _on_button_pressed() -> void:
	print("Test")

###> Gestion des personnages ###
func get_characters() -> void:
	reset_http_signal()
	http.connect("request_completed", Callable(self, "_on_characters_receive"))
	
	var err = http.request(
		"https://" + MULTIPLAYER.get_server_by_id(MULTIPLAYER.current_server)["address"] + "/api/character/list",
		[
			"Content-Type: application/json",
			"Authorization: Bearer " + MULTIPLAYER.token
		],
		HTTPClient.METHOD_POST
	)
	
	if err != OK:
		print("Erreur lors de l'envoi de la requête :", err)

func _on_characters_receive(_result, response_code, _headers, body) -> void:
	if response_code == 200:
		# Supprimer les boutons de test
		for child in character_container.get_children():
			if not child.is_in_group("create_button"):
				child.queue_free()
		
		var data = JSON.parse_string(body.get_string_from_utf8())
		for character in data:
			var button = Button.new()
			button.text = character["name"]
			
			# Configuration du remplissage horizontal et vertical
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.size_flags_vertical = Control.SIZE_EXPAND_FILL
			
			character_container.add_child(button)
	elif response_code == 401:
		# JWT expiré, récupération d'un nouveau token
		_relogin_callback = Callable(self, "get_characters")
		relogin()
	else:
		print("Erreur inconnue: ", response_code)


func _on_create_pressed() -> void:
	players_picker_margin.hide()
	new_character_panel_container.show()

func _on_create_character_pressed() -> void:
	reset_http_signal()
	http.connect("request_completed", Callable(self, "_on_create_character_receive"))
	
	var err = http.request(
		"https://" + MULTIPLAYER.get_server_by_id(MULTIPLAYER.current_server)["address"] + "/api/character/create",
		[
			"Content-Type: application/json",
			"Authorization: Bearer " + MULTIPLAYER.token
		],
		HTTPClient.METHOD_POST,
		JSON.stringify({
			"name": character_name_input.text,
			"saved_data": {
				"class": selected_skin
			}
		})
	)
	
	if err != OK:
		print("Erreur lors de l'envoi de la requête :", err)

func _on_create_character_receive(_result, response_code, _headers, _body) -> void:
	if response_code == 201:
		get_characters()
		character_name_input.text = ""
		players_picker_margin.show()
		new_character_panel_container.hide()
	elif response_code == 401:
		# JWT expired, get new token
		_relogin_callback = Callable(self, "get_characters")
		relogin()
	else:
		print("Erreur inconnue: ", response_code)

func relogin() -> void:
	reset_http_signal()
	http.connect("request_completed", Callable(self, "_on_relogin_receive"))
	
	var err = http.request(
		"https://" + MULTIPLAYER.get_server_by_id(MULTIPLAYER.current_server)["address"] + "/login",
		[
			"Content-Type: application/json",
		],
		HTTPClient.METHOD_POST,
		JSON.stringify({
			"username": MULTIPLAYER.username,
			"password": MULTIPLAYER.password
		})
	)
	
	if err != OK:
		print("Erreur lors de l'envoi de la requête :", err)

func _on_relogin_receive(_result, response_code, _headers, body) -> void:
	if response_code == 200:
		var data = JSON.parse_string(body.get_string_from_utf8())
		MULTIPLAYER.token = data["token"]
		
		if _relogin_callback.is_valid():
			_relogin_callback.call()
			_relogin_callback = Callable()
	elif response_code == 401:
		print("Mauvais identifiants")
	else:
		print("Erreur inconnue: ", response_code)

func reset_http_signal():
	for callback in [
		Callable(self, "_on_characters_receive"),
		Callable(self, "_on_relogin_receive"),
		Callable(self, "_on_create_character_receive"),
	]:
		if http.is_connected("request_completed", callback):
			http.disconnect("request_completed", callback)
###< Gestion des personnages ###

func _on_close_pressed():
	players_picker_margin.visible = true
	new_character_panel_container.visible = false


func _on_choisir_pressed() -> void:
	class_desc.visible = true
	class_picker.visible = true
	players_picker_margin.visible = false
