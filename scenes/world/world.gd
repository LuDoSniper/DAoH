extends Node3D

const LISTEN_PORT = 3642
const DEFAULT_ADDRESS = "localhost"

@export var player_scene: PackedScene

var peer = WebSocketMultiplayerPeer.new()

@onready var hud = $Control

func _on_host_pressed():
	peer.create_server(LISTEN_PORT)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_add_player)
	_add_player()
	hud.hide()

func _add_player(id: int = 1) -> void:
	var player = player_scene.instantiate()
	player.name = str(id)
	add_child(player)

func _on_join_pressed():
	peer.create_client("ws://" + DEFAULT_ADDRESS + ":" + str(LISTEN_PORT))
	multiplayer.multiplayer_peer = peer
	hud.hide()
