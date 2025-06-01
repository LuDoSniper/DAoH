extends Node

const DEFAULT_ADDRESS := "localhost"

# Par défaut il est à 3642 pour le debug local
# Attention, cela veux donc dire qu'en local on ne peux se connecter qu'à Europe.
# Le problème sera réglé lorsque tout les serveur dédiés seront déployés
var LISTEN_PORT := 3642
var token := ""

var peer := WebSocketMultiplayerPeer.new()

func create_server(peer_connected: Callable) -> void:
	peer.create_server(LISTEN_PORT)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(peer_connected)
	#peer_connected.call()
	
func join_server() -> void:
	peer.create_client("ws://" + DEFAULT_ADDRESS + ":" + str(LISTEN_PORT))
	multiplayer.multiplayer_peer = peer
