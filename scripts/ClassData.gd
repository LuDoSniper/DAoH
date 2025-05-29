class_name ClassData
extends RefCounted

var name: String
var attacks: Array[AttackData]

func _init(var_name: String) -> void:
	name = var_name

func add_attack(var_name: String) -> void:
	var attack = AttackData.new(var_name)
	attacks.append(attack)

func get_attack(var_name: String) -> AttackData:
	for attack in attacks:
		if attack.name == var_name:
			return attack
	
	return null
