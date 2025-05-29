extends Node3D

@export var player_scene: PackedScene

@onready var canvas_layer = $CanvasLayer
@onready var entities_container = $Entities

var players: Array

func _ready():
	if has_meta("server") and get_meta("server"):
		MULTIPLAYER.create_server(init)
	else:
		MULTIPLAYER.join_server()

# >>> ADD PLAYER
# request et remote sont quasiment identiques mais restent dans deux fonctions séparées pour la lisibilité du code
@rpc("any_peer")
func _request_add_player(id: int, selected_skin: String) -> void:
	var player = player_scene.instantiate()
	player.name = str(id)
	add_child(player)
	player.initialize_class(selected_skin)
	player.initialize_inventory()
	
	# Update list of players for the entities who depends on it
	if multiplayer.is_server():
		players.append(player)
		for entity in entities_container.get_children():
			if 'players' in entity:
				entity.players = players
	
	rpc("_remote_add_player", id, selected_skin)

@rpc("any_peer")
func _remote_add_player(id: int, selected_skin: String) -> void:
	if not multiplayer.is_server():
		var player = player_scene.instantiate()
		player.name = str(id)
		add_child(player)
		player.initialize_class(selected_skin)
		player.initialize_inventory()
		
		# Update list of players for the entities who depends on it
		if multiplayer.is_server():
			players.append(player)
			for entity in entities_container.get_children():
				if 'players' in entity:
					entity.players = players
# <<< ADD PLAYER

func init(id: int = 1) -> void:
	if has_meta("server") and not get_meta("server"):
		rpc_id(id, "_request_add_player", id, get_meta("selected_skin"))

func get_enemies() -> Array[Node]:
	return get_node("Entities").get_children()

func _on_retour_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/home/home_menu.tscn")

func _on_quitter_pressed() -> void:
	get_tree().quit()
