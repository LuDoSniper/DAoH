extends Node

func _ready() -> void:
	var args = OS.get_cmdline_args()
	GameState.load_audio_settings()
	
	print("Ready to start")
	
	if "--custom_debug" in args:
		print("debug activated")
		MULTIPLAYER.debug = true
	
	if "--server" in args:
		print("Starting as Server")
		var world_scene = preload("res://scenes/world/world.tscn")
		var world = world_scene.instantiate()
		world.set_meta("server", true)
		get_tree().root.call_deferred("add_child", world)
		get_tree().call_deferred("set_current_scene", world)
		call_deferred("queue_free")
	else:
		print("Starting as client")
		get_tree().call_deferred("change_scene_to_file", "res://scenes/main/main.tscn")
