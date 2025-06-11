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



var peer_to_character_id := {}
@rpc("any_peer")
func _register_character(peer_id: int, character_id: int) -> void:
	peer_to_character_id[peer_id] = character_id
	#print("peers:")
	#print(peer_to_character_id)


func get_character_id_by_peer_id(peer_id: int) -> int:
	if peer_id in peer_to_character_id:
		return peer_to_character_id[peer_id]
	return -1


func get_character_name_by_peer_id(peer_id: int) -> String:
	var character_id = get_character_id_by_peer_id(peer_id)
	#print(character_id)
	if character_id == -1:
		return "None"
	return get_character_name_by_id(character_id)
