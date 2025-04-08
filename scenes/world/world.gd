extends Node3D

@export var player_scene: PackedScene

@onready var canvas_layer = $CanvasLayer

func _on_host_pressed() -> void:
	MULTIPLAYER.create_server(init)
	canvas_layer.hide()

func _on_join_pressed() -> void:
	MULTIPLAYER.join_server()
	canvas_layer.hide()

func _add_player(id: int = 1) -> void:
	var player = player_scene.instantiate()
	player.name = str(id)
	add_child(player)

func init(id: int = 1) -> void:
	# Pour le moment init ne fait qu'ajouter les joueurs mais c'est dans cette fonction qu'on initialisera tout ce dont on aura besoin
	_add_player(id)
