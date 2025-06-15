extends Node3D

@export var player_scene: PackedScene
@export var enemy_scene: PackedScene

@onready var canvas_layer = $CanvasLayer
@onready var entities_container = $Entities
@onready var spawners: Node3D = $Spawners
@onready var enemy_spawners: Node3D = $EnemySpawners

@onready var main_camera: Camera3D = $Map/Camera3D

#var players: Array

var authority_player = null

func _ready():
	print("I'M READY !")
	if has_meta("server") and get_meta("server"):
		MULTIPLAYER.create_server(init, client_disconnected)
		UTILS.print_local(self, "I'M THE SERVER")
	else:
		MULTIPLAYER.join_server()
		UTILS.print_local(self, "I'VE JUST JOINED")
		$AudioStreamPlayer3D.play()
		$AudioStreamPlayer3D.stream.loop = true
	
	select_authority_player()

func _physics_process(_delta: float) -> void:
	if multiplayer.is_server():
		while len(get_enemies()) < 10:
			enemy_spawn()

	if not multiplayer.has_multiplayer_peer():
		return

	var local_player_id = multiplayer.get_unique_id()
	var local_player = entities_container.get_node_or_null(str(local_player_id))
	if local_player == null:
		return

	var local_camera = local_player.get_node_or_null("CameraController/Camera3D") # Adapte le chemin si nécessaire
	if local_camera == null:
		return

	for other_player in get_players():
		if other_player == local_player:
			other_player.username_label.visible = false
			continue

		var distance = local_player.global_position.distance_to(other_player.global_position)
		
		if distance <= 20.0:
			other_player.username_label.visible = true

			var look_pos = local_camera.global_position
			look_pos.y = other_player.username_label.global_position.y  # On garde l’axe Y du label pour éviter un tilt
			other_player.username_label.look_at(look_pos, Vector3.UP)
			other_player.username_label.rotate_y(deg_to_rad(180))
		else:
			other_player.username_label.visible = false

	# move camera with player authority
	if not multiplayer.is_server() and authority_player != null:
		main_camera.global_position = authority_player.global_position

func select_authority_player() -> void:
	if not multiplayer.is_server():
		var players = get_players()
		if players != []:
			authority_player = players[0]
			for player in players:
				if player.is_multiplayer_authority():
					authority_player = player

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
			print("PLAYER HEALTH SERVER ", player.health)
		if saved_data.has("xp"):
			player.current_xp = saved_data["xp"]
		if saved_data.has("gold"):
			player.gold = saved_data["gold"]
		if saved_data.has("camera_rot"):
			player.camera_controller.rotation = parse_vector3_from_string(saved_data["camera_rot"])
		if saved_data.has("active_quests"):
			var quests = []
			for quest_dict in saved_data["active_quests"]:
				var q = Quest.new()
				q.id = quest_dict.get("id", "")
				q.title = quest_dict.get("title", "")
				q.description = quest_dict.get("description", "")
				q.required_amount = quest_dict.get("required_amount", 0)
				q.current_amount = quest_dict.get("current_amount", 0)
				q.state = quest_dict.get("state", Quest.QuestState.NOT_STARTED)
				q.reward_xp = quest_dict.get("reward_xp", 0)
				q.reward_gold = quest_dict.get("reward_gold", 0)
				quests.append(q)
			player.active_quests = quests
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
		
		select_authority_player()

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
		player.hud.update_health(player.health)
		if saved_data.has("xp"):
			player.current_xp = saved_data["xp"]
		player.hud.update_xp(player.current_xp)
		if saved_data.has("gold"):
			player.gold = saved_data["gold"]
		player.hud.update_money(player.gold)
		if saved_data.has("camera_rot"):
			player.camera_controller.rotation = parse_vector3_from_string(saved_data["camera_rot"])
		if saved_data.has("active_quests"):
			var quests = []
			for quest_dict in saved_data["active_quests"]:
				var q = Quest.new()
				q.id = quest_dict.get("id", "")
				q.title = quest_dict.get("title", "")
				q.description = quest_dict.get("description", "")
				q.required_amount = quest_dict.get("required_amount", 0)
				q.current_amount = quest_dict.get("current_amount", 0)
				q.state = quest_dict.get("state", Quest.QuestState.NOT_STARTED)
				q.reward_xp = quest_dict.get("reward_xp", 0)
				q.reward_gold = quest_dict.get("reward_gold", 0)
				quests.append(q)
			player.active_quests = quests
		player.initialize_inventory()
		
		select_authority_player()
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
		rpc_id(1, "_request_add_player", id, get_meta("selected_skin"), get_meta("username"), get_meta("saved_data"))
		rpc_id(1, "_request_spawn_enemies", multiplayer.get_unique_id())
		MULTIPLAYER._register_character(multiplayer.get_unique_id(), MULTIPLAYER.current_character)
		send_message("[" + MULTIPLAYER.get_character_name_by_peer_id(id) + "] has joined the game", id, false)


func client_disconnected(peer_id: int) -> void:
	for player in get_players():
		if player.name.to_int() == peer_id:
			player._request_disconnect(peer_id, MULTIPLAYER.owner_id, true)

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

func get_random_free_enemy_spawner() -> Variant:
	var usable_spawners = []
	for spawner in enemy_spawners.get_children():
		if not spawner.is_busy():
			usable_spawners.append(spawner)
	
	if usable_spawners != []:
		return usable_spawners[randi_range(0, len(usable_spawners) - 1)]
	
	return null

func enemy_spawn() -> void:
	if multiplayer.is_server():
		var spawner = get_random_free_enemy_spawner()
		if spawner != null:
			var enemy = enemy_scene.instantiate()
			enemy.variant = enemy.variants.values()[randi_range(0, enemy.variants.size() - 1)]
			var enemy_name = get_enemy_unique_id()
			enemy.name = enemy_name
			entities_container.add_child(enemy)
			enemy.global_position = spawner.get_global_pos()
			spawner.emitt()
			#print("j'envois avec le nom : ", enemy.name)
			rpc("_remote_spawn_enemy", enemy_name, enemy.global_position, enemy.variant, spawner.name)
			print("j'ai envoyé")

@rpc("any_peer")
func _remote_spawn_enemy(enemy_name: String, pos: Vector3, variant: int, spawner_name: String = "") -> void:
	if not multiplayer.is_server():
		#print("j'ai reçu avec le nom : ", enemy_name)
		var enemy = enemy_scene.instantiate()
		enemy.variant = variant
		#print("Avant le désastre ?")
		enemy.name = enemy_name
		entities_container.add_child(enemy)
		#print("Apres le désastre ?")
		enemy.global_position = pos
		if spawner_name != "":
			for spawner in enemy_spawners.get_children():
				if spawner.name == spawner_name:
					spawner.emitt()
		#print("Maintenant peut etre ? Le nom est : ", enemy.name)

@rpc("any_peer")
func _request_spawn_enemies(peer_id: int) -> void:
	if multiplayer.is_server():
		for enemy in get_enemies():
			rpc_id(peer_id, "_remote_spawn_enemy", enemy.name, enemy.global_position, enemy.variant)

@rpc("any_peer")
func _request_spawn_enemy_debug() -> void:
	if multiplayer.is_server():
		enemy_spawn()

func get_enemy_unique_id():
	if multiplayer.is_server():
		var ids = []
		for enemy in get_enemies():
			ids.append(int(enemy.name.split('_')[1]))
		
		var id = 0
		while id in ids:
			id += 1
		
		return "Enemy_" + str(id)
