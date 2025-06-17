#npc.gd
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

@export var quest_not_finish: Array[String] = [
	"Tu n'as pas encore fini la quête !",
]

@export var quest_finish: Array[String] = [
	"Merci d'avoir terminé la quête !", 
	"Voici une récompense : 10 COINS"
]

@export var thanks_msg: Array[String] = [
	"Merci pour ton aide soldat !", 
]

@export var is_quester: bool = false
@export var quest_to_give: Quest = null

# Skins
@onready var skins_lst: Node3D = $Skins
@onready var rogue_skin: Node3D = $Skins/Rogue
@onready var druid_skin: Node3D = $Skins/Druid
@onready var engineer_skin: Node3D = $Skins/Engineer
@onready var knight_skin: Node3D = $Skins/Knight
@onready var mage_skin: Node3D = $Skins/Mage
@onready var rogue_hooded_skin: Node3D = $Skins/RogueHooded

var animation_tree
var move_state_machine

enum skins {
	Rogue,
	Mage,
	Knight,
	Engineer,
	Druid,
	Rogue_hooded
}
@export var skin := skins.Rogue

func _ready():
	label.text = npc_name
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	label.visible = false
	
	hide_skin()
	
	match skin:
		0:
			rogue_skin.show()
			animation_tree = rogue_skin.get_node("AnimationTree")
		1:
			mage_skin.show()
			animation_tree = mage_skin.get_node("AnimationTree")
		2:
			knight_skin.show()
			animation_tree = knight_skin.get_node("AnimationTree")
		3:
			engineer_skin.show()
			animation_tree = engineer_skin.get_node("AnimationTree")
		4:
			druid_skin.show()
			animation_tree = druid_skin.get_node("AnimationTree")
		5:
			rogue_hooded_skin.show()
			animation_tree = rogue_hooded_skin.get_node("AnimationTree")

	move_state_machine = animation_tree.get("parameters/StateMachine/playback")
	get_move_state_current_node()

func _process(_delta):
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

func get_dialogue_lines(quest):
	if quest == null:
		return {
			"lines": dialogue_lines,
			"is_quester": is_quester,
			"quest": quest_to_give
		}

	if quest.state == Quest.QuestState.IN_PROGRESS:
		return {
			"lines": quest_not_finish,
			"is_quester": false,
			"quest": quest
		}
	elif quest.state == Quest.QuestState.COMPLETED:
		quest.state = Quest.QuestState.CANT_TALK
		return {
			"lines": quest_finish,
			"is_quester": false,
			"quest": quest
		}
	elif quest.state == Quest.QuestState.CANT_TALK:
		return {
			"lines": thanks_msg,
			"is_quester": false,
			"quest": quest
		}
	else:
		return null


func set_move_state(state: String) -> void:
	move_state_machine.travel(state)

func get_move_state_current_node() -> StringName:
	return move_state_machine.get_current_node()

func hide_skin():
	for var_skin in skins_lst.get_children():
		var_skin.hide()
