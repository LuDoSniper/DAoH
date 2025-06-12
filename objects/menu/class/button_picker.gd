extends Button

@onready var label: Label = $PanelContainer/VBoxContainer/Label
@onready var texture_rect: TextureRect = $PanelContainer/VBoxContainer/TextureRect

func _ready():
	label.text = ""

func set_player_name(name: String) -> void:
	print(name)
	label.text = name

func set_viewport_texture(texture: Texture2D) -> void:
	texture_rect.texture = texture
