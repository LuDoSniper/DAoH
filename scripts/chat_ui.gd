extends CanvasLayer

@onready var chat_panel = $ChatPanel
@onready var message_input: LineEdit = $ChatPanel/VBoxContainer/ContainerInput/MessageInput
@onready var message_container: VBoxContainer = $ChatPanel/VBoxContainer/Container/ScrollContainer/MessageContainer
@onready var auto_hide_timer: Timer = $FermetureAutomatique

func _ready():
	chat_panel.hide()
	message_input.show()
	message_input.text = ""

func _input(event):
	if event.is_action_pressed("open_chat") and (!chat_panel.visible or !GameState.chat_active):
		chat_panel.show()
		if chat_panel.visible:
			GameState.ignore_pause = true
			GameState.chat_active = true
			message_input.show()
			get_viewport().set_input_as_handled()
			message_input.grab_focus()
			auto_hide_timer.stop()
		else:
			GameState.chat_active = false
			GameState.ignore_pause = false
			auto_hide_timer.stop()
	if event.is_action_pressed("pause") and chat_panel.visible:
		GameState.ignore_pause = true
		chat_panel.hide()
		GameState.chat_active = false
		auto_hide_timer.stop()

func _on_message_input_text_submitted(new_text: String) -> void:
	send_message(new_text)

func send_message(message: String, origin: int = multiplayer.get_unique_id(), prompt: bool = true) -> void:
	
	if message.begins_with("/msg"):

		var parts = message.split(" ", false, 2) # sépare en 3 parties max : /msg, id, reste
		if parts.size() >= 2:
			var target_id = MULTIPLAYER.get_peer_id_by_character_name(parts[1])
			if target_id != -1:
				UTILS.print_local(self, "Sending pm to " + str(target_id))
				rpc_id(target_id, "_test456", origin, parts[2])

				# @todo bleu + click
				message = "[color=#44a2eb]à " + MULTIPLAYER.get_character_name_by_peer_id(target_id) + ": " + parts[2].strip_edges() + "[/color]"
				
				var label = RichTextLabel.new()
				label.bbcode_enabled = true
				label.text = ""  # évite de mélanger avec `text`, utilise .append_text() ou .bbcode_text
				label.bbcode_text = message
				label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				label.fit_content = true  # utile pour éviter des tailles fixes
				label.scroll_active = false  # pas besoin de scroll dans le label lui-même



				message_container.add_child(label)
				message_input.text = ""
				message_input.hide()

				await get_tree().process_frame
				_scroll_to_bottom()
				GameState.chat_active = false
				
				chat_panel.show()
				auto_hide_timer.start()
			else:
				message = "[color=#d63d1e]Joueur Introuvable[/color]"
				
				var label = RichTextLabel.new()
				label.bbcode_enabled = true
				label.text = ""  # évite de mélanger avec `text`, utilise .append_text() ou .bbcode_text
				label.bbcode_text = message
				label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				label.fit_content = true  # utile pour éviter des tailles fixes
				label.scroll_active = false  # pas besoin de scroll dans le label lui-même



				message_container.add_child(label)
				message_input.text = ""
				message_input.hide()

				await get_tree().process_frame
				_scroll_to_bottom()
				GameState.chat_active = false
				
				chat_panel.show()
				auto_hide_timer.start()

		else:
			UTILS.print_local(self, "Usage: /msg <id>")
		return
	
	if not multiplayer.is_server():
		if message != "":
			UTILS.print_local(self, "I AM REQUESTING A SENDING : " + message)
			rpc_id(1, "_request_send_message", origin, message, prompt)
		else:
			auto_hide_timer.start()
	else:
		_request_send_message(origin, message, prompt)


@rpc("any_peer") 
func _test456(sender_id: int, message: String) -> void: #receive mp
	UTILS.print_local(self, "I AM RECEIVING A MESSAGE : " + message)
	#@todo mettre en bleu et cliquable

	message = "[color=#44a2eb] de " + MULTIPLAYER.get_character_name_by_peer_id(sender_id) + ": " + message + "[/color]"

	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.text = ""  
	label.bbcode_text = message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.fit_content = true  
	label.scroll_active = false 



	message_container.add_child(label)
	message_input.text = ""
	message_input.hide()

	await get_tree().process_frame
	_scroll_to_bottom()
	GameState.chat_active = false
	
	chat_panel.show()
	auto_hide_timer.start()




@rpc("any_peer")
func _request_send_message(id: int, message: String, prompt: bool = true) -> void:
	if multiplayer.is_server():
		UTILS.print_local(self, "I AM RECEIVING A REQUEST : " + message + " FROM : " + str(id))
		rpc("_remote_recieve_message", id, message, prompt)

@rpc("any_peer")
func _remote_recieve_message(id: int, message: String, prompt: bool = true) -> void:
	if not multiplayer.is_server():
		UTILS.print_local(self, "I AM RECEIVING A MESSAGE : " + message)
		
		var prompt_str = "[" + MULTIPLAYER.get_character_name_by_peer_id(id) + "]: " if prompt else ""

		message = prompt_str + message.strip_edges()
		
		var label = Label.new()
		label.text = message
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL 
		message_container.add_child(label)
		message_input.text = ""
		message_input.hide()

		await get_tree().process_frame
		_scroll_to_bottom()
		GameState.chat_active = false
		
		chat_panel.show()
		auto_hide_timer.start()

func _scroll_to_bottom():
	await get_tree().process_frame
	await get_tree().process_frame

	var scroll = $ChatPanel/VBoxContainer/Container/ScrollContainer
	var content_height = message_container.get_minimum_size().y
	var viewport_height = scroll.get_size().y

	scroll.scroll_vertical = max(content_height - viewport_height, 0)


func _on_fermeture_automatique_timeout() -> void:
	chat_panel.hide()
	message_input.hide()
	GameState.chat_active = false
