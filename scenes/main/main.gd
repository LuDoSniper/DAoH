extends Node3D

@onready var home_menu: Control = $GUI/HomeMenu
@onready var credits: Control = $GUI/Credits
@onready var settings: Control = $GUI/Settings
@onready var classes: Control = $GUI/Classes

@onready var home_camera: Camera3D = $"3D/Cameras/Home"
@onready var classes_camera: Camera3D = $"3D/Cameras/Classes"
@onready var options_camera: Camera3D = $"3D/Cameras/Options"
@onready var credits_camera: Camera3D = $"3D/Cameras/Credits"

@onready var knight: Node3D = $"3D/Skins/Knight"
@onready var barbarian: Node3D = $"3D/Skins/Barbarian"
@onready var mage: Node3D = $"3D/Skins/Mage"
@onready var rogue: Node3D = $"3D/Skins/Rogue"
@onready var class_selector: Control = $GUI/Classes

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	class_selector.connect("class_selected", Callable(self, "_on_class_selected"))

func hide_menu():
	home_menu.hide()
	credits.hide()
	settings.hide()
	classes.hide()
	
	home_camera.current = false
	classes_camera.current = false
	options_camera.current = false
	credits_camera.current = false

func _on_start_pressed() -> void:
	hide_menu()
	classes.show()
	classes_camera.current = true

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
