class_name WeaponData
extends RefCounted

enum hands_variants {
	Left,
	Right,
	Both
}

var name: String
var class_owners: Array[String]
var hands: Array[hands_variants]
var damage: float

func _init(weapon_name: String, weapon_class_owners: Array[String], hands_data: Array[hands_variants], weapon_damage: float) -> void:
	name = weapon_name
	class_owners = weapon_class_owners
	hands = hands_data
	damage = weapon_damage
