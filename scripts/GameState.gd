extends Node

var chat_active: bool	= false
var ignore_pause		= false
var player_moving		= false
var player_jumping		= false
var audio_walking_playing = false
var first_server_sound	= true
var sound_master_value	= null
var sound_music_value	= null
var sound_sfx_value		= null
var shield_blocking		= false

const SAVE_PATH = "user://audio_settings.save"

func save_audio_settings():
	var data = {
		"master": sound_master_value,
		"music":  sound_music_value,
		"sfx":    sound_sfx_value
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_var(data)
	file.close()
	#print("Audio settings saved.")

func load_audio_settings():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		var data = file.get_var()
		file.close()

		sound_master_value = data.get("master", 0.0)
		sound_music_value  = data.get("music", 0.0)
		sound_sfx_value    = data.get("sfx", 0.0)
		#print("Audio settings loaded.")
	else:
		pass
		#print("No audio settings file found. Using defaults.")
