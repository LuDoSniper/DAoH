extends Button

@onready var label: Label = $PanelContainer/MarginContainer/VBoxContainer/Label
@onready var skins: Node3D = $Skins
@onready var cameras: SubViewport = $SubViewport

func _ready():
	label.text = ""
	hide_skin()
	set_false_cam()

func set_player_name(name: String) -> void:
	label.text = name

func hide_skin() -> void:
	for child in skins.get_children():
		if child is Node3D :
			child.hide()

func show_skin(skin_name) -> void:
	for child in skins.get_children():
		if child is Node3D and child.name == skin_name:
			child.show()

func set_false_cam() -> void:
	for child in cameras.get_children():
		if child is Camera3D :
			child.current = false

func set_true_cam(skin_name) -> void:
	for child in cameras.get_children():
		if child is Camera3D and child.name == skin_name:
			child.current = true

func set_player_skin(skin_name: String) -> void:
	hide_skin()
	set_false_cam()
	show_skin(skin_name)
	set_true_cam(skin_name)
