extends Node3D

@onready var home_menu: Control = $GUI/HomeMenu
@onready var credits: Control = $GUI/Credits
@onready var settings: Control = $GUI/Settings
@onready var classes: Control = $GUI/Classes
@onready var authentication: Control = $GUI/Authentication
@onready var join_attempt_fail: Control = $GUI/JoinAttemptFail

@onready var home_camera: Camera3D = $"3D/Cameras/Home"
@onready var classes_camera: Camera3D = $"3D/Cameras/Classes"
@onready var options_camera: Camera3D = $"3D/Cameras/Options"
@onready var credits_camera: Camera3D = $"3D/Cameras/Credits"
@onready var new_personnage_camera: Camera3D = $"3D/Cameras/NewPersonnage"
@onready var player_pickers_camera: Camera3D = $"3D/Cameras/PlayerPickers"
@onready var player_pickers_empty_camera: Camera3D = $"3D/Cameras/PlayerPickersEmpty"

@onready var knight: Node3D = $"3D/Skins/Knight"
@onready var barbarian: Node3D = $"3D/Skins/Barbarian"
@onready var mage: Node3D = $"3D/Skins/Mage"
@onready var rogue: Node3D = $"3D/Skins/Rogue"
@onready var class_selector: Control = $GUI/Classes

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AudioStreamPlayer3D.play()
	$AudioStreamPlayer3D.stream.loop = true
	play_click_on_all_buttons(self)
	if MULTIPLAYER.last_connection == "failure":
		join_attempt_fail.show()
	else:
		join_attempt_fail.hide()
	
	authentication.authentication_successfull.connect(_on_authentication_successfull)
	class_selector.connect("class_selected", Callable(self, "_on_class_selected"))
	hide_menu()
	
	home_menu.show()
	home_camera.current = true

func hide_menu():
	home_menu.hide()
	credits.hide()
	settings.hide()
	classes.hide()
	authentication.hide()
	
	home_camera.current = false
	classes_camera.current = false
	options_camera.current = false
	credits_camera.current = false
	new_personnage_camera.current = false
	player_pickers_empty_camera.current = false
	player_pickers_camera.current = false

func _on_start_pressed() -> void:
	#hide_menu()
	#classes.show()
	#classes_camera.current = true
	
	hide_menu()
	authentication.show()

func _on_settings_pressed() -> void:
	hide_menu()
	settings.show()
	options_camera.current = true

func _on_credits_pressed() -> void:
	hide_menu()
	credits.show()
	credits_camera.current = true

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_back_pressed() -> void:
	hide_menu()
	home_menu.show()
	home_camera.current = true

func _on_back_class_pressed() -> void:
	classes.create_back_pressed()
	classes_camera.current = false
	show_player_picker()

func _on_class_selected(classes_name) -> void:
	knight.hide()
	barbarian.hide()
	mage.hide()
	rogue.hide()
	match classes_name:
		"Knight":
			knight.show()
		"Barbarian":
			barbarian.show()
		"Mage":
			mage.show()
		"Rogue":
			rogue.show()

func _on_authentication_successfull() -> void:
	hide_menu()
	classes.show()
	classes.get_characters()

func _on_back_to_main_pressed() -> void:
	authentication_back_pressed()

func authentication_back_pressed() -> void:
	hide_menu()
	authentication.reset_view()
	authentication.hide()
	home_menu.show()
	home_camera.current = true

func _on_ok_pressed() -> void:
	join_attempt_fail.hide()


func _on_create_pressed() -> void:
	player_pickers_empty_camera.current = false
	player_pickers_camera.current = false
	new_personnage_camera.current = true


func _on_close_pressed() -> void:
	new_personnage_camera.current = false
	show_player_picker()


func _on_next_pressed() -> void:
	new_personnage_camera.current = false
	classes_camera.current = true


func _on_create_character_pressed() -> void:
	classes_camera.current = false
	show_player_picker()


func show_player_picker(empty = null) -> void:
	if empty == null : 
		print(MULTIPLAYER.characters)
		print(len(MULTIPLAYER.characters))
		empty = len(MULTIPLAYER.characters) == 0
	if empty:
		player_pickers_empty_camera.current = true
	else:
		player_pickers_camera.current = true
		
		
func play_click_on_all_buttons(node):
	for child in node.get_children():
		if child is Button:
			child.pressed.connect(SoundManager.play_click)
		elif child.has_method("get_children"):
			play_click_on_all_buttons(child)
