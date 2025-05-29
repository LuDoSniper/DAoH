class_name InventoryData
extends RefCounted

var weapons: Array[WeaponData] = []
var left_hand = "empty"
var right_hand = "empty"

func initialize_base_class(name: String) -> void:
	match name:
		"Knight":
			weapons = [
				EXISTING_ITEMS.sword_1h,
				EXISTING_ITEMS.shield_badge
				#EXISTING_ITEMS.sword_2h
			]
			left_hand = weapons[1]
			right_hand = weapons[0]
		"Barbarian":
			weapons = [
				EXISTING_ITEMS.axe_1h,
				EXISTING_ITEMS.shield_round_barbarian
				#EXISTING_ITEMS.axe_2h
			]
			left_hand = weapons[1]
			right_hand = weapons[0]
		"Mage":
			weapons = [
				#EXISTING_ITEMS.wand
				EXISTING_ITEMS.staff
			]
			right_hand = weapons[0]
		"Rogue":
			weapons = [
				#EXISTING_ITEMS.dagger
				EXISTING_ITEMS.crossbow
			]
			right_hand = weapons[0]
