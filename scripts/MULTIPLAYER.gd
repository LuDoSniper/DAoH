extends Node


# Par défaut il est à 3642 pour le debug local
# Attention, cela veux donc dire qu'en local on ne peux se connecter qu'à Europe.
# Le problème sera réglé lorsque tout les serveur dédiés seront déployés
var DEFAULT_ADDRESS_BEGIN := "daoh-"
var DEFAULT_ADDRESS_END := ".donnarieix.fr"
var REGION := "eu"
var LISTEN_PORT := 3642
var MAX_CHARACTER_COUNT := 4
var token := ""
var servers: Array = []
var current_server := 0
var username := ""
var password := ""
var owners_id: Array[int] = []
var owner_id: int
var characters: Array = []
var current_character := 0
var last_connection := "none"

var peer := WebSocketMultiplayerPeer.new()

func create_server(peer_connected: Callable) -> void:
	peer.create_server(LISTEN_PORT, "0.0.0.0")
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(peer_connected)
	#peer_connected.call()
	
func join_server() -> void:
	peer.create_client("ws://" + DEFAULT_ADDRESS_BEGIN + REGION + DEFAULT_ADDRESS_END + ":" + str(LISTEN_PORT))
	multiplayer.multiplayer_peer = peer

func get_server_by_id(id: int) -> Dictionary:
	for server in servers:
		if server["id"] == id:
			return server
	
	return {}

func get_character_by_id(id: int) -> Dictionary:
	for character in characters:
		if character["id"] == id:
			return character
	return {}

func get_character_name_by_id(id: int) -> String:
	for character in characters:
		if character["id"] == id:
			return character["name"]
	return "None"

func get_characters():
	pass
	#print(characters)





var peer_to_character_id := {}

func _ready():
	if multiplayer.is_server():
		multiplayer.peer_connected.connect(_on_peer_connected)

func _on_peer_connected(new_peer_id: int) -> void:
	for peer_id in peer_to_character_id.keys():
		var character_data = peer_to_character_id[peer_id]
		# On envoie à CE nouveau peer les données des anciens joueurs
		rpc_id(new_peer_id, "_update_peer_character", peer_id, character_data)




@rpc("any_peer")
func _register_character(peer_id: int, character_id: int) -> void:
	var character_data = get_character_by_id(character_id)
	peer_to_character_id[peer_id] = character_data


	# Broadcast aux clients (appelera _update_peer_character sur CHAQUE instance)
	rpc("_update_peer_character", peer_id, character_data)

@rpc("any_peer")
func _update_peer_character(peer_id: int, character_data: Dictionary) -> void:

	# Chaque client (et le serveur) tient à jour son propre peer_to_character_id
	peer_to_character_id[peer_id] = character_data




func get_character_id_by_peer_id(peer_id: int) -> int:
	if peer_id in peer_to_character_id:
		return int(peer_to_character_id[peer_id].get("id", -1))
	return -1


func get_character_name_by_peer_id(peer_id: int) -> String:
	var char_data = peer_to_character_id.get(peer_id, null)
	if char_data == null:
		print("Erreur: Aucun personnage associé à ce peer_id:", peer_id)
		return "None"
		
	var char_name = char_data.get("name", "None")
	return char_name

func get_peer_id_by_character_name(char_name: String) -> int:
	for peer_id in peer_to_character_id.keys():
		var char_data = peer_to_character_id[peer_id]
		if char_data.get("name", "") == char_name:
			return peer_id
	return -1
