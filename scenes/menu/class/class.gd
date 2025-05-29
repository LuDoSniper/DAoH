extends Control

#@onready var knight: Node3D = $Skins/Knight
#@onready var barbarian: Node3D = $Skins/Barbarian
#@onready var mage: Node3D = $Skins/Mage
#@onready var rogue: Node3D = $Skins/Rogue
@onready var label: Label = $Panel/MenuBG/Bandeau/Label
@onready var rich_text_label: RichTextLabel = $Panel/MenuBG/VBoxContainer/VBoxContainer/RichTextLabel

@onready var chevalier_button: Button = $HBoxContainer/VBoxContainer2/Chevalier
@onready var barbare_button: Button = $HBoxContainer/VBoxContainer2/VBoxContainer/Barbare
@onready var voleur_button: Button = $HBoxContainer/VBoxContainer/Voleur
@onready var mage_button: Button = $HBoxContainer/VBoxContainer/Mage

var panel_selected = preload("res://addons/menu/round_damaged_brown.png")
var panel = preload("res://addons/menu/round_damaged_brown_dark.png")

var selected_stylebox = StyleBoxTexture.new()
var default_stylebox = StyleBoxTexture.new()

var selected_skin := "Knight"

signal class_selected(classes_name: String)

var description = {
	"Chevalier": "Noble guerrier en armure lourde, le Chevalier incarne l'honneur et la défense. Il manie l’épée et le bouclier avec brio, protégeant ses alliés et tenant la ligne face à l’ennemi. Grâce à sa robustesse et ses compétences défensives, il est le pilier de toute escouade.",
	"Voleur": "Rapide, agile et rusé, le Voleur frappe dans l’ombre avant de disparaître. Maître des attaques critiques et de l’évasion, il utilise dagues, poisons et techniques de furtivité pour éliminer ses cibles sans être vu. L’ennemi ne le voit jamais venir.",
	"Mage": "Maître des arcanes, le Mage puise son pouvoir dans les éléments. Qu’il déchaîne le feu, le givre ou la foudre, il inflige des dégâts massifs à distance. Bien qu’il soit fragile, sa puissance mystique peut renverser le cours d’une bataille en un instant.",
	"Barbare": "Furie incarnée, le Barbare est une brute sauvage qui charge dans la mêlée sans crainte. Armé de haches ou de massues, il utilise sa rage pour infliger des dégâts colossaux. Plus il est blessé, plus il devient dangereux. Il est la tempête dans le chaos du champ de bataille."
}

func _on_knight_pressed() -> void:
	_update_skin("Knight")

func _on_barbarian_pressed() -> void:
	_update_skin("Barbarian")

func _on_rogue_pressed() -> void:
	_update_skin("Rogue")

func _on_mage_pressed() -> void:
	_update_skin("Mage")

func _update_skin(skin):
	selected_skin = skin
	selected_stylebox.texture = panel_selected
	default_stylebox.texture = panel
	knight.hide()
	barbarian.hide()
	mage.hide()
	rogue.hide()
	
	update_theme(chevalier_button, default_stylebox)
	update_theme(barbare_button, default_stylebox)
	update_theme(voleur_button, default_stylebox)
	update_theme(mage_button, default_stylebox)
	
	if skin == "Knight":
		knight.show()
		label.text = "Chevalier"
		update_theme(chevalier_button, selected_stylebox)
	elif skin == "Barbarian":
		barbarian.show()
		label.text = "Barbare"
		update_theme(barbare_button, selected_stylebox)
	elif skin == "Mage":
		mage.show()
		label.text = "Mage"
		update_theme(mage_button, selected_stylebox)
	elif skin == "Rogue":
		rogue.show()
		label.text = "Voleur"
		update_theme(voleur_button, selected_stylebox)
	rich_text_label.text = description[label.text]

func _on_rejoindre_pressed() -> void:
	var world_scene = preload("res://scenes/world/world.tscn")
	var world = world_scene.instantiate()
	world.set_meta("selected_skin", selected_skin)
	get_tree().root.add_child(world)
	queue_free()

func update_theme(button, texture):
	button.add_theme_stylebox_override("normal", texture)
	button.add_theme_stylebox_override("hover", texture)
	button.add_theme_stylebox_override("pressed", texture)
	button.add_theme_stylebox_override("focus", texture)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/home/home_menu.tscn")


func _on_button_pressed() -> void:
	print("Test")
