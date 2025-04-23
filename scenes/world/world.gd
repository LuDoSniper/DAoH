extends Node3D

@export var player_scene: PackedScene

@onready var canvas_layer = $CanvasLayer
@onready var entities_container = $Entities

var players: Array

func _ready():
	if has_meta("is_hosting"):
		var hosting = get_meta("is_hosting")
		if hosting:
			MULTIPLAYER.create_server(init)
		else:
			MULTIPLAYER.join_server()

func _add_player(id: int = 1) -> void:
	var player = player_scene.instantiate()
	player.name = str(id)
	add_child(player)
	
	# Update list of players for the entities who depends on it
	if multiplayer.is_server():
		players.append(player)
		for entity in entities_container.get_children():
			if 'players' in entity:
				entity.players = players

func init(id: int = 1) -> void:
	# Pour le moment init ne fait qu'ajouter les joueurs mais c'est dans cette fonction qu'on initialisera tout ce dont on aura besoin
	_add_player(id)


func _on_retour_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/home/home_menu.tscn")


func _on_quitter_pressed() -> void:
	get_tree().quit()
