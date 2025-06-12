extends Button

@onready var label: Label = $PanelContainer/VBoxContainer/Label
@onready var skins: Node3D = $Skins

func _ready():
	for child in get_tree().get_nodes_in_group(""):
		print(child.name, " -> ", child)

	hide_skin()
	label.text = ""

func hide_skin(show_skin = null) -> void:
	for child in skins.get_children():
		if child is Node3D and not(child.name == show_skin):
			child.hide()
		else:
			child.show()

func set_player_name(name: String) -> void:
	print(name)
	label.text = name

func set_player_skin(player_class: String) -> void:
	hide_skin(player_class)
