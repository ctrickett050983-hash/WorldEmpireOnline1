extends Control

var root: VBoxContainer
var status_label: Label
var title_label: Label
var server_status: Label
var email_input: LineEdit
var password_input: LineEdit
var display_name_input: LineEdit
var api_input: LineEdit
var remember_check: CheckBox
var loading_box: VBoxContainer
var mode := "login"
var busy := false

func _ready() -> void:
	_build_ui()
	API.request_finished.connect(_on_api_done)
	_check_server()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.025, 0.035, 0.055)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var glow := ColorRect.new()
	glow.color = Color(0.07, 0.13, 0.20, 0.65)
	glow.anchor_left = 0.06
	glow.anchor_top = 0.08
	glow.anchor_right = 0.94
	glow.anchor_bottom = 0.92
	add_child(glow)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(650, 680)
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -325
	panel.offset_top = -340
	panel.offset_right = 325
	panel.offset_bottom = 340
	add_child(panel)

	root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	panel.add_child(root)

	title_label = Label.new()
	title_label.text = "WORLD EMPIRE ONLINE"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 36)
	root.add_child(title_label)

	var tag := Label.new()
	tag.text = "Build a business. Own a city. Shape the world economy."
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_font_size_override("font_size", 16)
	root.add_child(tag)

	server_status = Label.new()
	server_status.text = "Server: checking..."
	server_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(server_status)

	var sep := HSeparator.new()
	root.add_child(sep)

	api_input = LineEdit.new()
	api_input.placeholder_text = "Server URL"
	api_input.text = Session.api_url
	root.add_child(api_input)

	email_input = LineEdit.new()
	email_input.placeholder_text = "Email"
	email_input.text = Session.saved_email
	root.add_child(email_input)

	password_input = LineEdit.new()
	password_input.placeholder_text = "Password"
	password_input.secret = true
	password_input.text = Session.saved_password
	root.add_child(password_input)

	display_name_input = LineEdit.new()
	display_name_input.placeholder_text = "Display name for registration"
	display_name_input.visible = false
	root.add_child(display_name_input)

	remember_check = CheckBox.new()
	remember_check.text = "Remember me on this computer"
	remember_check.button_pressed = Session.remember_me
	root.add_child(remember_check)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 10)
	root.add_child(button_row)

	var login_btn := Button.new()
	login_btn.text = "Login"
	login_btn.custom_minimum_size = Vector2(170, 44)
	login_btn.pressed.connect(_login)
	button_row.add_child(login_btn)

	var register_btn := Button.new()
	register_btn.text = "Register"
	register_btn.custom_minimum_size = Vector2(170, 44)
	register_btn.pressed.connect(_register)
	button_row.add_child(register_btn)

	var check_btn := Button.new()
	check_btn.text = "Check Server"
	check_btn.custom_minimum_size = Vector2(170, 44)
	check_btn.pressed.connect(_check_server)
	button_row.add_child(check_btn)

	status_label = Label.new()
	status_label.text = "Ready. Log in to enter the world."
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(status_label)

	loading_box = VBoxContainer.new()
	loading_box.add_theme_constant_override("separation", 5)
	root.add_child(loading_box)
	_set_loading_steps([])

func _set_loading_steps(steps: Array) -> void:
	for child in loading_box.get_children():
		child.queue_free()
	for step in steps:
		var label := Label.new()
		label.text = str(step)
		loading_box.add_child(label)

func _set_busy(value: bool, message: String = "") -> void:
	busy = value
	if message.length() > 0:
		status_label.text = message

func _save_preferences() -> void:
	Session.api_url = api_input.text.strip_edges()
	Session.remember_me = remember_check.button_pressed
	Session.saved_email = email_input.text.strip_edges()
	Session.saved_password = password_input.text if remember_check.button_pressed else ""
	Session.save_local_settings()

func _validate_auth_inputs(registering: bool) -> bool:
	if api_input.text.strip_edges().is_empty():
		status_label.text = "Enter your server URL, for example http://localhost:3000"
		return false
	if email_input.text.strip_edges().is_empty():
		status_label.text = "Enter your email address."
		return false
	if password_input.text.length() < 8:
		status_label.text = "Password must be at least 8 characters."
		return false
	if registering and display_name_input.text.strip_edges().length() < 2:
		status_label.text = "Enter a display name before registering."
		return false
	return true

func _login() -> void:
	if busy: return
	mode = "login"
	display_name_input.visible = false
	if not _validate_auth_inputs(false): return
	_save_preferences()
	_set_busy(true, "Signing in...")
	_set_loading_steps(["• Connecting to server", "• Authenticating account"])
	API.auth_post("/api/auth/login", {"email": email_input.text.strip_edges(), "password": password_input.text}, "login")

func _register() -> void:
	if busy: return
	if not display_name_input.visible:
		display_name_input.visible = true
		status_label.text = "Enter a display name, then press Register again."
		return
	mode = "register"
	if not _validate_auth_inputs(true): return
	_save_preferences()
	_set_busy(true, "Creating account...")
	_set_loading_steps(["• Connecting to server", "• Creating player account"])
	API.auth_post("/api/auth/register", {"email": email_input.text.strip_edges(), "password": password_input.text, "displayName": display_name_input.text.strip_edges()}, "register")

func _check_server() -> void:
	Session.api_url = api_input.text.strip_edges() if api_input != null else Session.api_url
	server_status.text = "Server: checking..."
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_health_done.bind(http))
	var err := http.request(Session.api_url + "/health", [], HTTPClient.METHOD_GET)
	if err != OK:
		server_status.text = "Server: offline or invalid URL"
		http.queue_free()

func _on_health_done(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest) -> void:
	if response_code >= 200 and response_code < 300:
		server_status.text = "Server: online"
	else:
		server_status.text = "Server: offline"
	http.queue_free()

func _on_api_done(ok: bool, data: Variant, status_code: int, context: String) -> void:
	if context != "login" and context != "register" and context != "world_load":
		return
	if context == "world_load":
		_handle_world_loaded(ok, data, status_code)
		return
	if not ok:
		_set_busy(false)
		_set_loading_steps([])
		status_label.text = _friendly_error(data, status_code)
		return
	if typeof(data) != TYPE_DICTIONARY:
		_set_busy(false)
		status_label.text = "Unexpected login response."
		return
	Session.apply_login(data)
	_set_loading_steps(["✓ Server connected", "✓ Account authenticated", "• Loading cities", "• Preparing world"])
	status_label.text = "Authenticated. Loading world..."
	API.get_json("/api/world", "world_load")

func _handle_world_loaded(ok: bool, data: Variant, status_code: int) -> void:
	_set_busy(false)
	if not ok:
		_set_loading_steps([])
		status_label.text = "Login worked, but world loading failed: " + _friendly_error(data, status_code)
		return
	if typeof(data) != TYPE_DICTIONARY:
		status_label.text = "World data was not valid."
		return
	Session.last_world_data = data
	_set_loading_steps(["✓ Server connected", "✓ Account authenticated", "✓ Cities loaded", "✓ Entering world"])
	status_label.text = "Welcome, " + Session.player_name + "."
	await get_tree().create_timer(0.35).timeout
	get_tree().change_scene_to_file("res://scenes/CitySelect.tscn")

func _friendly_error(data: Variant, status_code: int) -> String:
	var error_text := "unknown_error"
	if typeof(data) == TYPE_DICTIONARY:
		error_text = str(data.get("error", data.get("raw", "unknown_error")))
	match error_text:
		"bad_login":
			return "Login failed. Check the email and password."
		"email_taken":
			return "That email is already registered. Use Login instead."
		"request_failed":
			return "Request failed. Check the server URL and that the server is running."
		_:
			return "Error " + str(status_code) + ": " + error_text
