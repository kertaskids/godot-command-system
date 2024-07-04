extends Node2D
class_name CommandSystem

@onready var command_line = $command_line
@onready var command_label = $command_label

var num: int = 0

#region Core Command System Variables
# Regular expression patterns for accepted command patterns
static var regex_patterns = [
	r"^[a-zA-Z_][a-zA-Z0-9_]*\(\)$",                        # No parameters
	r"^[a-zA-Z_][a-zA-Z0-9_]*\(\"[^\"]*\"\)$",              # One string parameter
	r"^[a-zA-Z_][a-zA-Z0-9_]*\(\d+,\s*\d+\)$",              # Two numeric parameters
	r"^[a-zA-Z_][a-zA-Z0-9_]*\(\"[^\"]*\",\s*\"[^\"]*\"\)$",# Two string parameters
	r"^[a-zA-Z_][a-zA-Z0-9_]*\(\"[^\"]*\",\s*\d+,\s*\d+\)$" # One string and two numeric parameters
]

# List of available commands
static var battle_commands: PackedStringArray = [
	'move("robotname",x,y)',
	'attack("robotname",x,y)',
	'skillattack("robotname",x,y)',
	'endturn()'
]

static var status_commands: PackedStringArray = [
	'checkstatus(x,y)',
	'robotstatus("robotname")',
	'tilestatus(x,y)',
	'teamstatus("teamname")',
	'highlight("actionname",x,y)'
]

static var system_commands: PackedStringArray = [
	'clear()',
	'exit()'
]
#endregion

#region Command Snippets Variables
var _command_snippets: Array[String] = [""]
#endregion

#region Core Command System Methods
static func is_command_valid(command: String) -> bool:
	# Check the existence and the order of the brackets and comma
	var is_brackets_exist: bool = command.contains("(") and command.contains(")")
	var is_brackets_correct: bool = command.find("(") < command.find(")")
	if not is_brackets_exist or not is_brackets_correct:
		return false
	if not is_command_params_valid(command): 
		print("Check params types.")
		return false
	
	# Create a RegEx object
	var regex = RegEx.new()
	
	# Check the command against each pattern
	for pattern in regex_patterns:
		var compile_status = regex.compile(pattern)
		if compile_status != OK:
			print("Error compiling regex: ", compile_status)
			return false
		
		# If any pattern matches, return true
		var result = regex.search(command)
		# <Todo> Also need to check if the number of params for each command are correct
		if result != null:
			return true
	
	# If no patterns match, return false
	return false

static func is_command_exist(command: String) -> bool:
	if command.length() < 1: 
		return false
	var command_name: String = get_command_name(command)
	for cmd in get_all_commands(): 
		if cmd.contains(command_name): 
			return true
	return false

static func is_empty_params(command: String) -> bool: 
	return get_command_params(command).size() <= 1 and get_command_params(command)[0].length() <= 0

static func is_integer(value: String) -> bool:
	var number = int(value)
	return str(number) == value

static func is_string(value: String) -> bool:
	return value is String

static func is_command_params_valid(command: String) -> bool:
	var all_commands = get_all_commands()
	var is_match_name: bool = false
	var is_match_params_size: bool = false 
	var is_match_params_types: bool = false
	
	for cmd in all_commands: 
		# Check the matching name
		if get_command_name(command).match(get_command_name(cmd)): 
			is_match_name = true
			# Check the number of params
			if get_command_params(command).size() == get_command_params(cmd).size():
				is_match_params_size = true
				# Check if the param types are equal
				var current_params = get_command_params(command)
				var template_params = get_command_params(cmd, true)
				# Handle if the template params is "", then current_command("something") should be invalid
				if template_params[0] == "" and current_params[0] != "": 
					is_match_params_size = false
				for i in range(0, current_params.size()):
					if (is_string(current_params[i]) == is_string(template_params[i]) and is_integer(current_params[i]) == is_integer(template_params[i])):
						is_match_params_types = true
					else: 
						is_match_params_types = false
	return  is_match_name and is_match_params_size and is_match_params_types

static func get_command_name(command: String) -> String:
	return command.left(command.find("("))

static func get_command_params(command: String, replace: bool = false) -> PackedStringArray:
	# If repalce is true, return string x,y params replace with 0 int type
	var llimit = command.find("(")
	var rlimit = command.find(")")
	var raw_params = command.substr(llimit, rlimit-llimit)
	var chars_to_delete = ['(',')','"']
	for c in chars_to_delete:
		raw_params = raw_params.replace(c,"")
	var params: PackedStringArray = raw_params.split(",", true)
	if replace:
		for i in range(0, params.size()):
			if params[i] == "x" or params[i] == "y":
				params[i] = "0"
	return params

static func get_all_commands() -> PackedStringArray: 
	return battle_commands + status_commands + system_commands

func try_execute_command(command: String) -> void: 
	command_label.clear()
	var message: String = "Try executing command: " + command + ". "
	var success_message: String = "Success executing command: " + command
	var fail_message: String = "Failed to execute command: " + command
	
	if not is_command_exist(command): 
		message += "\nUnknown command. "
	if not is_command_valid(command):
		message += "\nInvalid command. "
	command_label.add_text(message) 
	
	if not is_command_exist(command) or not is_command_valid(command):
		message = "Fail executing command: " + get_command_name(command) + ", with params:" + ",".join(get_command_params(command))
		command_label.add_text("\n" + message)
		return
	
	# Implement the execution of command specifically 
	# 1. Check command name 
	# 2. Check the fitness of params (numbers and types) 
	# 3. Do the command 
	# ==========================================

	# Move action
	if get_command_name(command).match("move"): 
		var move_params = get_command_params(command) 
		var action_status: bool = move(move_params[0], move_params[1].to_int(), move_params[2].to_int())
		if action_status == true:
			message = success_message
		else: 
			message = fail_message
		command_label.add_text("\n" + message)

	# Attack action
	elif get_command_name(command).match("attack"): 
		message = success_message
		command_label.add_text("\n" + message)

	# SkillAttack action 
	elif get_command_name(command).match("skillattack"): 
		message = success_message
		command_label.add_text("\n" + message)

	# EndTurn action
	elif get_command_name(command).match("endturn"): 
		message = success_message
		command_label.add_text("\n" + message)

	# CheckStatus action
	elif get_command_name(command).match("checkstatus"):
		message = success_message
		command_label.add_text("\n" + message)
	
	# RobotStatus action
	elif get_command_name(command).match("robotstatus"):
		message = success_message
		command_label.add_text("\n" + message)
	
	#TileStatus action
	elif get_command_name(command).match("tilestatus"):
		message = success_message
		command_label.add_text("\n" + message)
	
	# TeamStatus action
	elif get_command_name(command).match("teamstatus"):
		message = success_message
		command_label.add_text("\n" + message)
	
	#Highlight action
	elif get_command_name(command).match("highlight"):
		message = success_message
		command_label.add_text("\n" + message)
	
	# Clear()
	elif get_command_name(command).match("clear"):
		message = success_message
		command_label.add_text("\n" + message)
	
	# Exit()
	elif get_command_name(command).match("exit"):
		message = success_message
		command_label.add_text("\n" + message)
	
	# Other actions here 
	# Default action 
	else: 
		message = "Command is not implemented yet: " + command
		command_label.add_text("\n" + message)

func _on_command_line_submitted(command: String) -> void:
	try_execute_command(command)
#endregion

#region Command Snippets Methods
static func get_last_space(command: String) -> int:
	return command.rfind(" ")

static func get_left_command_string(command: String) -> String: 
	var left_string: String = ""
	var last_space: int = get_last_space(command)
	if last_space > 0:
		left_string = command.left(last_space)
	return left_string

static func get_most_right_command_string(command: String) -> String: 
	var most_right_string: String = command
	var last_space: int = get_last_space(command)
	if last_space > 0: 
		most_right_string = command.right(command.length() - (last_space + 1))	
	return most_right_string

func _show_snippet(command: String) -> void:
	command_label.clear()
	_command_snippets.clear()
	for cmd in get_all_commands(): 
		if cmd.contains(command): 
			command_label.add_text(cmd + "\n")
			_command_snippets.append(cmd)

func _on_command_line_edited(command: String) -> void: 
	_show_snippet(get_most_right_command_string(command))

func _on_command_line_gui_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_TAB: 
			if _command_snippets.size() > 0: 
				var new_text: String 
				if get_last_space(command_line.text) <= 0:
					# Closest snippet is always chosen 
					new_text = _command_snippets[0]
				else:
					new_text = get_left_command_string(command_line.text) + " " + _command_snippets[0]
				command_line.text = new_text
			else: 
				command_label.clear()
				command_label.add_text("Unknown snippet.")
			command_line.set_caret_column(command_line.text.length())
#endregion

#region Virtual Actions
# Sample action 
func move(robotname: String, x:int, y:int) -> bool:
	var sucsess = false
	var actor: CharacterBody2D = get_node(robotname)
	if not actor == null:
		actor.position = Vector2(x,y)
		sucsess = true
	else:
		command_label.text = robotname + " is not found."
		sucsess = false
	return sucsess
#endregion

func _ready():
	# <Testing>
	
	# <End of testing>
	pass
	
