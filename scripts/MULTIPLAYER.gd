extends Node

const LISTEN_PORT := 3642
const DEFAULT_ADDRESS := "localhost"

var peer := WebSocketMultiplayerPeer.new()

func create_server(peer_connected: Callable) -> void:
	peer.create_server(LISTEN_PORT)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(peer_connected)
	peer_connected.call()
	
func join_server() -> void:
	peer.create_client("ws://" + DEFAULT_ADDRESS + ":" + str(LISTEN_PORT))
	multiplayer.multiplayer_peer = peer
