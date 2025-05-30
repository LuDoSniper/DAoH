extends Weapon

func _ready() -> void:
	data = EXISTING_ITEMS.get_item_by_name("Crossbow")
