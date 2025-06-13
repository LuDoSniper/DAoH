extends CharacterBody3D

@onready var area: Area3D = $Area3D
@onready var label: Label3D = $Label3D
@export var npc_name: String = "CACA"
var player_camera: Camera3D = null

@export var dialogue_lines: Array[String] = [
	"Salut, aventurier !",
	"Bienvenue dans le monde de Godoria.",
	"Bonne chance pour ta quête !"
]

@export var is_quester: bool = false
@export var quest_to_give: Quest = null

func _ready():
	label.text = npc_name
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	label.visible = false

func _process(delta):
	if player_camera and label.visible:
		label.look_at(player_camera.global_transform.origin, Vector3.UP)
		label.rotation.y += deg_to_rad(180)

func _on_body_entered(body):
	if body.is_in_group("players") and body.is_multiplayer_authority():
		label.visible = true
		body.set_current_npc(self)

		if body.get_node("CameraController").has_node("Camera3D"):
			player_camera = body.get_node("CameraController").get_node("Camera3D")

func _on_body_exited(body):
	if body.is_in_group("players") and body.is_multiplayer_authority():
		label.visible = false
		body.set_current_npc(null)
		player_camera = null

func get_dialogue_lines():
	return {
		"lines": dialogue_lines,
		"is_quester": is_quester,
		"quest": quest_to_give
	}
