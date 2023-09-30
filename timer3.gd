extends Panel

@onready var time_input: LineEdit = $SettingsUI/Inputs/TimeInput
@onready var title_input: LineEdit = $TitleInput
@onready var settings_ui: Node2D = $SettingsUI
@onready var running_ui: Node2D = $RunningUI
@onready var timeout_ui: Node2D = $TimeoutUI
@onready var cancel_button: Button = $RunningUI/ButtonsContainer/CancelButton
@onready var timeout_ok_button: Button = $TimeoutUI/TimeoutOKButton
@onready var rem_time_label: Label = $RunningUI/RemainingTimeLabel
@onready var feedback_label: Label = $SettingsUI/Inputs/FeedbackLabel
@onready var timer: Timer = $Timer
@onready var timeout_audio: AudioStreamPlayer = $TimeoutAudio

var _time_regex := RegEx.new()
var _arg_regex := RegEx.new()
var _one_time: bool = false


# Called when the node enters the scene tree for the first time.
func _ready():
	DisplayServer.window_set_size(size)
	_time_regex.compile("^((?<hours>\\d+)[Hh]){0,1}((?<mins>\\d+)[Mm]){0,1}((?<secs>\\d+)[Ss]?){0,1}$")
	_arg_regex.compile("^--time=((?<hours>\\d+)[Hh]){0,1}((?<mins>\\d+)[Mm]){0,1}((?<secs>\\d+)[Ss]?){0,1}$")
	time_input.text_changed.connect(_on_time_changed)
	time_input.text_submitted.connect(_on_time_submitted)
	cancel_button.pressed.connect(_on_cancel_button_pressed)
	timer.timeout.connect(_on_timeout)
	timeout_ok_button.pressed.connect(_on_timeout_ok_button_pressed)
	_set_always_on_top(true)
	_reset_timer_app.call_deferred()
	_parse_args.call_deferred()
	
	
func _parse_args():
	for argument in OS.get_cmdline_args():
		print(argument)
		var regex_match = _arg_regex.search(argument)
		if regex_match:
			var time_value = argument.replace("--time=", "")
			time_input.text = time_value
			time_input.text_submitted.emit(time_value)
		elif argument == "--one_time":
			_one_time = true
		elif argument.begins_with("--timer-title="):
			title_input.text = argument.replace("--timer-title=", "")
			

func _show_cmd_help():
	print("Options:")
	print("--one_time				: automatically quits after first timeout")
	print("--time=[XXh][YYm][ZZs]	: sets the time and starts timer")
	print("\nExample:")
	print("Timer.exe --one_time --time=30s")
	
	
func _on_cancel_button_pressed():
	_cancel_timer()
	
	
func _on_timeout_ok_button_pressed():
	_reset_timer_app()
	if _one_time:
		get_tree().quit()
	
	
func _reset_timer_app():
	_set_always_on_top(false)
	timeout_audio.stop()
	timer.stop()
	settings_ui.visible = true
	running_ui.visible = false
	timeout_ui.visible = false
	_setup_control_focus(time_input, [title_input, time_input])
	
	
func _on_timeout():
	_set_always_on_top(true)
	timer.stop()
	running_ui.visible = false
	timeout_ui.visible = true
	_setup_control_focus(timeout_ok_button, [title_input, timeout_ok_button])
	timeout_audio.play()


func _set_always_on_top(value: bool = false):
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, value)
	DisplayServer.window_is_focused()
	
	
func _cancel_timer():
	timer.stop()
	_reset_timer_app()

	
func _update_rem_time_label():
	var time_left = ceili(timer.time_left)
	rem_time_label.text = _format_time(time_left, "%02d:%02d:%02d")
	
	
func _format_time(time_sec, format_string):
	var hours = time_sec / 3600
	var mins = (time_sec % 3600) / 60
	var sec = time_sec % 60
	return format_string % [hours, mins, sec]
	
	
func _on_time_changed(text):
	var match_info = _time_regex.search(time_input.text)
	if match_info:
		feedback_label.text = ""
	else:
		feedback_label.text = "Time should be XXhYYmZZs. E.g.: 5m30s"

		
func _validate(input: LineEdit):
	input.text = _time_regex.get_string(input.text)


func _on_time_submitted(_new_text):
	var time = _parse_time(time_input.text)
	if time > 0:
		_start_timer(time)
	elif time == 0:
		feedback_label.text = "Time is zero"
			
			
func _parse_time(time_string: String) -> int:
	var time: int = 0
	var match_info = _time_regex.search(time_string)
	if match_info:
		for input in [["hours", 3600], ["mins", 60], ["secs", 1]]:
			var capt_group_name = input[0]
			var seconds_multiplier = input[1]
			var input_value = match_info.get_string(capt_group_name)
			if len(input_value) > 0:
				var int_value: int = int(input_value)
				time += int_value * seconds_multiplier	
	else:
		time = -1
	return time
	
		
func _start_timer(time):
	settings_ui.visible = false
	running_ui.visible = true
	timer.start(time)
	_setup_control_focus(cancel_button, [title_input, cancel_button])
	
	
func _setup_control_focus(control: Control, nav_order: Array[Control] = []):
	control.grab_focus()
	var nav_count: int = len(nav_order)
	for i in range(0, nav_count):
		var next = wrapi(i + 1, 0, nav_count)
		var prev = wrapi(i - 1, 0, nav_count)
		nav_order[i].focus_next = nav_order[next].get_path()
		nav_order[i].focus_neighbor_bottom = nav_order[next].get_path()
		nav_order[i].focus_previous = nav_order[prev].get_path()
		nav_order[i].focus_neighbor_top = nav_order[prev].get_path()

func _process(_delta):
	if not timer.is_stopped():
		_update_rem_time_label()
		
		

