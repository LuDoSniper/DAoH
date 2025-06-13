extends Resource
class_name Quest

enum QuestState { NOT_STARTED, IN_PROGRESS, COMPLETED }

var id: String
var title: String
var description: String
var required_amount: int = 5
var current_amount: int = 0
var state: int = QuestState.NOT_STARTED
var reward_xp: int = 100
var reward_gold: int = 100
