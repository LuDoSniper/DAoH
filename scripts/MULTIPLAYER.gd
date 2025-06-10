extends Node

const DEFAULT_ADDRESS := "localhost"

# Par défaut il est à 3642 pour le debug local
# Attention, cela veux donc dire qu'en local on ne peux se connecter qu'à Europe.
# Le problème sera réglé lorsque tout les serveur dédiés seront déployés
var LISTEN_PORT := 3642
var MAX_CHARACTER_COUNT := 4
var token := ""
var servers: Array = []
var current_server := 0
var username := ""
var password := ""
var characters: Array = []
var current_character := 0

var peer := WebSocketMultiplayerPeer.new()

func create_server(peer_connected: Callable) -> void:
	peer.create_server(LISTEN_PORT)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(peer_connected)
	#peer_connected.call()
	
func join_server() -> void:
	peer.create_client("ws://" + DEFAULT_ADDRESS + ":" + str(LISTEN_PORT))
	multiplayer.multiplayer_peer = peer

func get_server_by_id(id: int) -> Dictionary:
	for server in servers:
		if server["id"] == id:
			return server
	
	return {}

func get_unique_character_id() -> int:
	var id = 0
	# Itérer sur tout les charactères car un dict n'est pas ordonné
	for character in characters:
		if character["id"] == id:
			id += 1
	return id

func get_character_by_id(id: int) -> Dictionary:
	for character in characters:
		if character["id"] == id:
			return character
	
	return {}
