extends Node3D

@export var player_scene: PackedScene

@onready var canvas_layer = $CanvasLayer
@onready var entities_container = $Entities
@onready var spawners: Node3D = $Spawners

#var players: Array

func _ready():
	print("I'M READY !")
	if has_meta("server") and get_meta("server"):
		MULTIPLAYER.create_server(init)
		UTILS.print_local(self, "I'M THE SERVER")
	else:
		MULTIPLAYER.join_server()
		UTILS.print_local(self, "I'VE JUST JOINED")

# >>> ADD PLAYER
# request et remote sont quasiment identiques mais restent dans deux fonctions séparées pour la lisibilité du code
@rpc("any_peer")
func _request_add_player(peer_id: int, selected_skin: String) -> void:
	if multiplayer.is_server():
		UTILS.print_local(self, "Request \"add_player\" recieved")
		var player = player_scene.instantiate()
		player.name = str(peer_id)
		player.set_multiplayer_authority(peer_id)
		UTILS.print_local(self, "PEER_ID AUTHORITY : " + str(peer_id))
		
		entities_container.add_child(player)
		
		player.global_position = get_first_spawner_pos_available(player)
		player.initialize_class(selected_skin)
		player.initialize_inventory()

		# Update list of players for the entities who depends on it
		#if multiplayer.is_server():
			#players.append(player)
			#for entity in entities_container.get_children():
				#if entity.is_in_group("enemy") and 'players' in entity:
					#entity.players = players
		
		for var_player in get_players():
			if var_player.name.to_int() == peer_id:
				rpc("_remote_add_player", var_player.name.to_int(), var_player.selected_class.name, var_player.global_position)
			else:
				rpc_id(peer_id, "_remote_add_player", var_player.name.to_int(), var_player.selected_class.name, var_player.global_position)

@rpc("any_peer")
func _remote_add_player(id: int, selected_skin: String, pos: Vector3) -> void:
	if not multiplayer.is_server():
		UTILS.print_local(self, "Remote \"add_player\" recieved")
		var player = player_scene.instantiate()
		player.name = str(id)
		player.set_multiplayer_authority(id)
		
		entities_container.add_child(player)
		
		player.global_position = pos
		player.initialize_class(selected_skin)
		player.initialize_inventory()
# <<< ADD PLAYER

func init(peer_id: int) -> void:
	''''
	Cette fonction n'existe que chez le serveur. Elle s'active à chaque connexion entrante.
	Elle indique au nouveau client d'initialiser la procédure de d'initialisation du monde.
	'''
	rpc_id(peer_id, "_remote_init_player", peer_id)
	send_message("[" + str(peer_id) + "] has joined the game", peer_id, false)

@rpc("any_peer")
func _remote_init_player(id: int) -> void:
	if not multiplayer.is_server():
		UTILS.print_local(self, "Sending \"add_player\" request")
		rpc("_request_add_player", id, get_meta("selected_skin"))

func get_enemies() -> Array:
	var enemies = []
	for child in entities_container.get_children():
		if child.is_in_group("enemy"):
			enemies.append(child)
	
	return enemies

func get_players() -> Array:
	var players = []
	for child in entities_container.get_children():
		if child.is_in_group("player"):
			players.append(child)
	
	return players

func get_first_spawner_pos_available(object: Node3D) -> Vector3:
	for child in spawners.get_children():
		if not child.is_busy():
			child._on_area_3d_body_entered(object)
			return child.get_global_pos()
	
	return spawners.get_children()[randi_range(0, len(spawners.get_children()) - 1)].get_global_pos()

func send_message(message: String, origin: int = multiplayer.get_unique_id(), prompt: bool = true) -> void:
	get_node("ChatUi").send_message(message, origin, prompt)

func _on_retour_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/home/home_menu.tscn")

func _on_quitter_pressed() -> void:
	get_tree().quit()
