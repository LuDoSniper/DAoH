extends Node3D

@onready var sub_viewport: SubViewport = $SubViewport
@onready var skins: Node3D = $Skins

func _ready():
	hide_skin()

func get_viewport_texture():
	return sub_viewport.get_texture()

func hide_skin() -> void:
	for child in skins.get_children():
		if child is Node3D :
			child.hide()

func show_skin(skin_name) -> void:
	print("SHOW SKIN")
	for child in skins.get_children():
		if child is Node3D and child.name == skin_name:
			print("J'affiche : ", skin_name)
			child.show()
		print("Visibilité : ",child.visible)
		
func set_player_skin(skin_name: String) -> void:
	print("SET PLAYER SKIN")
	hide_skin()
	show_skin(skin_name)
	
