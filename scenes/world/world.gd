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
		$AudioStreamPlayer3D.play()
		$AudioStreamPlayer3D.stream.loop = true

func strip_custom(string: String, to_remove: Array[String]) -> String:
	var striped := ""
	for c in string:
		if c not in to_remove:
			striped += c
	
	return striped

func parse_vector3_from_string(pos_string: String) -> Vector3:
	# Enlève les parenthèses
	var trimmed := strip_custom(pos_string, ["(", ")", " "])
	# Sépare les composantes
	var parts := trimmed.split(",")
	if parts.size() != 3:
		push_error("Invalid position format: %s" % pos_string)
		return Vector3.ZERO
	# Convertit chaque partie en float
	print("Converted vector : ", Vector3(parts[0].to_float(), parts[1].to_float(), parts[2].to_float()))
	return Vector3(parts[0].to_float(), parts[1].to_float(), parts[2].to_float())

# >>> ADD PLAYER
# request et remote sont quasiment identiques mais restent dans deux fonctions séparées pour la lisibilité du code
@rpc("any_peer")
func _request_add_player(peer_id: int, selected_skin: String, username: String, saved_data: Dictionary) -> void:
	if multiplayer.is_server():
		UTILS.print_local(self, "Request \"add_player\" recieved")
		var player = player_scene.instantiate()
		player.name = str(peer_id)
		player.set_multiplayer_authority(peer_id)
		UTILS.print_local(self, "PEER_ID AUTHORITY : " + str(peer_id))
		
		entities_container.add_child(player)
		
		player.global_position = get_first_spawner_pos_available(player)
		player.initialize_class(selected_skin)
		player.set_username(username)
		print(saved_data)
		print(saved_data.has("pos"))
		if saved_data.has("pos"):
			player.global_position = parse_vector3_from_string(saved_data["pos"])
		if saved_data.has("rot"):
			player.skin.rotation.y = saved_data["rot"]
		if saved_data.has("health"):
			player.health = saved_data["health"]
		if saved_data.has("xp"):
			player.current_xp = saved_data["xp"]
		if saved_data.has("gold"):
			player.gold = saved_data["gold"]
		if saved_data.has("camera_rot"):
			player.camera_controller.rotation = parse_vector3_from_string(saved_data["camera_rot"])
		player.initialize_inventory()

		# Update list of players for the entities who depends on it
		#if multiplayer.is_server():
			#players.append(player)
			#for entity in entities_container.get_children():
				#if entity.is_in_group("enemy") and 'players' in entity:
					#entity.players = players
		
		for var_player in get_players():
			if var_player.name.to_int() == peer_id:
				rpc("_remote_add_player", var_player.name.to_int(), var_player.selected_class.name, var_player.global_position, var_player.username, saved_data)
			else:
				rpc_id(peer_id, "_remote_add_player", var_player.name.to_int(), var_player.selected_class.name, var_player.global_position, var_player.username, saved_data)

@rpc("any_peer")
func _remote_add_player(id: int, selected_skin: String, pos: Vector3, username: String, saved_data: Dictionary) -> void:
	if not multiplayer.is_server():
		UTILS.print_local(self, "Remote \"add_player\" recieved")
		var player = player_scene.instantiate()
		player.name = str(id)
		player.set_multiplayer_authority(id)
		
		entities_container.add_child(player)
		
		player.global_position = pos
		player.initialize_class(selected_skin)
		player.set_username(username)
		if saved_data.has("pos"):
			player.global_position = parse_vector3_from_string(saved_data["pos"])
		if saved_data.has("rot"):
			player.skin.rotation.y = saved_data["rot"]
		if saved_data.has("health"):
			player.health = saved_data["health"]
		if saved_data.has("xp"):
			player.current_xp = saved_data["xp"]
		if saved_data.has("gold"):
			player.gold = saved_data["gold"]
		if saved_data.has("camera_rot"):
			player.camera_controller.rotation = parse_vector3_from_string(saved_data["camera_rot"])
		player.initialize_inventory()
# <<< ADD PLAYER

func init(peer_id: int) -> void:
	''''
	Cette fonction n'existe que chez le serveur. Elle s'active à chaque connexion entrante.
	Elle indique au nouveau client d'initialiser la procédure de d'initialisation du monde.
	'''
	rpc_id(peer_id, "_authenticate")

@rpc("any_peer")
func _authenticate() -> void:
	if not multiplayer.is_server():
		rpc_id(1, "_authentication_attempt", multiplayer.get_unique_id(), MULTIPLAYER.owner_id)

@rpc("any_peer")
func _authentication_attempt(peer_id: int, owner_id: int) -> void:
	if multiplayer.is_server():
		if owner_id not in MULTIPLAYER.owners_id:
			MULTIPLAYER.owners_id.append(owner_id)
			rpc_id(peer_id, "_remote_init_player", peer_id)
			send_message("[" + MULTIPLAYER.get_character_name_by_peer_id(peer_id) + "] has joined the game", peer_id, false)
		else:
			rpc_id(peer_id, "_authentication_failed")

@rpc("any_peer")
func _authentication_failed() -> void:
	MULTIPLAYER.peer.close()
	MULTIPLAYER.last_connection = "failure"
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

@rpc("any_peer")
func _remote_init_player(id: int) -> void:
	if not multiplayer.is_server():
		MULTIPLAYER.last_connection = "success"
		UTILS.print_local(self, "Sending \"add_player\" request")
		rpc("_request_add_player", id, get_meta("selected_skin"), get_meta("username"), get_meta("saved_data"))
		MULTIPLAYER._register_character(multiplayer.get_unique_id(), MULTIPLAYER.current_character)

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
