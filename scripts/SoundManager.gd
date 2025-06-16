extends Node

@onready var click_sound = preload("res://assets/sounds/button-click.mp3")
@onready var audio_player = AudioStreamPlayer.new()

func _ready():
	add_child(audio_player)

func play_click():
	#print("Click détecté")
	audio_player.stream = click_sound
	audio_player.bus = "SoundFX"
	audio_player.volume_db = -4.0
	audio_player.play()
