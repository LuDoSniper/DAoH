extends Resource
class_name Quest

enum QuestState { NOT_STARTED, IN_PROGRESS, COMPLETED, CANT_TALK }

@export var id: String = ""
@export var title: String = ""
@export var description: String = ""
@export var required_amount: int = 5
@export var current_amount: int = 0
@export var state: QuestState = QuestState.NOT_STARTED
@export var reward_xp: int = 100
@export var reward_gold: int = 100

func to_dict() -> Dictionary:
	return {
		"id": id,
		"title": title,
		"description": description,
		"required_amount": required_amount,
		"current_amount": current_amount,
		"state": state,
		"reward_xp": reward_xp,
		"reward_gold": reward_gold,
	}
