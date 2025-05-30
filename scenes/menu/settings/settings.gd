extends Control

@onready var video_type_button: Button = $Panel/MenuBG/VBoxContainer/VBoxContainer2/TypeMenu/Video
@onready var audio_type_button: Button = $Panel/MenuBG/VBoxContainer/VBoxContainer2/TypeMenu/Audio
@onready var video: HBoxContainer = $Panel/MenuBG/VBoxContainer/VBoxContainer4/Video
@onready var audio: HBoxContainer = $Panel/MenuBG/VBoxContainer/VBoxContainer4/Audio

var state = "video"

var panel_selected = preload("res://addons/menu/panel_brown_arrows_dark_detail.png")
var panel = preload("res://addons/menu/panel_brown_damaged_dark.png")

func _ready() -> void:
	_update_button_styles()

func _on_video_pressed() -> void:
	if state != "video":
		state = "video"
		video.show()
		audio.hide()
		_update_button_styles()

func _on_audio_pressed() -> void:
	if state != "audio":
		state = "audio"
		video.hide()
		audio.show()
		_update_button_styles()

func _update_button_styles() -> void:
	var selected_stylebox = StyleBoxTexture.new()
	selected_stylebox.texture = panel_selected

	var default_stylebox = StyleBoxTexture.new()
	default_stylebox.texture = panel

	if state == "video":
		video_type_button.add_theme_stylebox_override("normal", selected_stylebox)
		audio_type_button.add_theme_stylebox_override("normal", default_stylebox)
		
		video_type_button.add_theme_stylebox_override("hover", selected_stylebox)
		audio_type_button.add_theme_stylebox_override("hover", default_stylebox)
	else:
		audio_type_button.add_theme_stylebox_override("normal", selected_stylebox)
		video_type_button.add_theme_stylebox_override("normal", default_stylebox)
		
		audio_type_button.add_theme_stylebox_override("hover", selected_stylebox)
		video_type_button.add_theme_stylebox_override("hover", default_stylebox)

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_borderless_toggled(toggled_on: bool) -> void:
	# Ne s'applique que si on est en mode fenêtré
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, toggled_on)

func _on_v_sync_toggled(toggled_on: bool) -> void:
	# Active ou désactive la V-Sync
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if toggled_on else DisplayServer.VSYNC_DISABLED
	)
	
func _on_master_value_changed(value: float) -> void:
	volume(0, value)

func _on_music_value_changed(value: float) -> void:
	volume(1, value)

func _on_sound_fx_value_changed(value: float) -> void:
	volume(2, value)

func volume(bus_index, value):
	AudioServer.set_bus_volume_db(bus_index, value)
