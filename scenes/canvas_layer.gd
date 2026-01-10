extends CanvasLayer

@onready var panel: Panel = $Panel
# Fixed: Node name is 'output' in your scene tree, not 'Output'
@onready var output: RichTextLabel = $Panel/VBoxContainer/output
@onready var input: LineEdit = $Panel/VBoxContainer/input

var is_open := false

func _ready() -> void:
	# Ensure the console is hidden at start
	panel.visible = false
	output.text = ""
	
	# IMPORTANT: In Inspector, set ConsoleUI 'Process Mode' to 'Always' 
	# so it doesn't freeze when the tree is paused.
	_log("Console ready. Try: cube_01.delete()")

func _input(event) -> void:
	if event.is_action_pressed("toggle_console"):
		_toggle_console()
		get_viewport().set_input_as_handled()

func _toggle_console() -> void:
	is_open = !is_open
	panel.visible = is_open
	get_tree().paused = is_open

	if is_open:
		input.text = ""
		input.grab_focus()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		input.release_focus()
		# Return to gameplay mouse mode
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_input_text_submitted(new_text: String) -> void:
	var cmd := new_text.strip_edges()
	input.text = "" # Clear input field immediately
	
	if cmd.is_empty():
		return

	_log("> " + cmd)
	_execute_command(cmd)

func _execute_command(cmd: String) -> void:
	# Expected format: target.action(args)
	if "." not in cmd:
		_log_err("Syntax: target.action(args)")
		return

	var parts := cmd.split(".", false, 1)
	var target_name := parts[0].strip_edges()
	var rest := parts[1].strip_edges()

	# Parse action and arguments
	var action := rest
	var args_str := ""
	
	if "(" in rest and rest.ends_with(")"):
		action = rest.substr(0, rest.find("(")).strip_edges()
		args_str = rest.substr(rest.find("(") + 1, rest.length() - rest.find("(") - 2).strip_edges()
	elif "(" in rest or rest.ends_with(")"):
		_log_err("Missing parentheses. Example: object.ping()")
		return

	# Find the target in the 'hackable' group
	var target := _find_hackable(target_name)
	if target == null:
		_log_err("No hackable target named: " + target_name)
		return

	# Command execution
	match action:
		"delete":
			target.queue_free()
			_log("Deleted: " + target_name)
		"ping":
			_log("pong from " + target_name)
		"hide":
			target.visible = false
			_log("Hid " + target_name)
		_:
			_log_err("Unknown action: " + action + "()")

func _find_hackable(target_name: String) -> Node:
	var nodes := get_tree().get_nodes_in_group("hackable")
	for n in nodes:
		if n.name == target_name:
			return n
	return null

func _log(msg: String) -> void:
	output.append_text(msg + "\n")
	# Auto-scroll logic:
	await get_tree().process_frame # Wait for text to render
	var scrollbar = output.get_v_scroll_bar()
	scrollbar.value = scrollbar.max_value

func _log_err(msg: String) -> void:
	output.append_text("[color=tomato]ERROR: " + msg + "[/color]\n")
	# Also trigger auto-scroll for errors
	await get_tree().process_frame
	var scrollbar = output.get_v_scroll_bar()
	scrollbar.value = scrollbar.max_value
