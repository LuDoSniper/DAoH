extends CanvasLayer

@onready var panel = $PanelContainer
@onready var label_name: Label = $PanelContainer/LabelName
@onready var rich_text_label: RichTextLabel = $PanelContainer/RichTextLabel

var lines: Array[String] = []
var current_index := 0

func show_dialogue(npc_name: String, dialogue: Array[String]) -> void:
	lines = dialogue.duplicate()
	current_index = 0
	if label_name:
		label_name.text = npc_name + ":"
	if panel:
		panel.show()
	_show_next_line()

func _show_next_line() -> void:
	if current_index < lines.size():
		if label_name:
			rich_text_label.text = lines[current_index]
		current_index += 1
	elif panel:
		panel.hide()
