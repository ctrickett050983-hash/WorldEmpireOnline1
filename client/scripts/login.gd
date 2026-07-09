extends Control

var email: LineEdit
var password: LineEdit
var api_url: LineEdit
var status: Label

func _ready() -> void:
	_build_ui()
	API.request_finished.connect(_on_api_done)

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.06, 0.09)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 520)
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -260
	panel.offset_top = -260
	panel.offset_right = 260
	panel.offset_bottom = 260
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)

	var title := Label.new()
	title.text = "WORLD EMPIRE ONLINE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Persistent city economy • Player-owned businesses • Online world"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(subtitle)

	api_url = LineEdit.new()
	api_url.text = Session.api_url
	api_url.placeholder_text = "Server URL"
	box.add_child(api_url)

	email = LineEdit.new()
	email.placeholder_text = "Email"
	email.text = "player1@example.com"
	box.add_child(email)

	password = LineEdit.new()
	password.placeholder_text = "Password"
	password.secret = true
	password.text = "Password123!"
	box.add_child(password)

	var buttons := HBoxContainer.new()
	box.add_child(buttons)
	var login_btn := Button.new()
	login_btn.text = "Login"
	login_btn.pressed.connect(_login)
	buttons.add_child(login_btn)
	var register_btn := Button.new()
	register_btn.text = "Register"
	register_btn.pressed.connect(_register)
	buttons.add_child(register_btn)

	status = Label.new()
	status.text = "Start your empire."
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(status)

func _login() -> void:
	Session.api_url = api_url.text.strip_edges()
	status.text = "Logging in..."
	API.auth_post("/api/auth/login", {"email":email.text.strip_edges(), "password":password.text}, "login")

func _register() -> void:
	Session.api_url = api_url.text.strip_edges()
	status.text = "Registering..."
	API.auth_post("/api/auth/register", {"email":email.text.strip_edges(), "password":password.text, "displayName":email.text.get_slice("@", 0)}, "register")

func _on_api_done(ok: bool, data: Variant, status_code: int, context: String) -> void:
	if context != "login" and context != "register": return
	if not ok:
		status.text = "Auth failed: " + str(data)
		return
	Session.token = str(data.get("token", ""))
	Session.user = data.get("user", {})
	Session.player_cash = float(Session.user.get("cash", 0))
	Session.player_name = str(Session.user.get("display_name", "Player"))
	status.text = "Connected. Loading world..."
	API.get_json("/api/world", "world")
	API.request_finished.disconnect(_on_api_done)
	API.request_finished.connect(_on_world_done)

func _on_world_done(ok: bool, data: Variant, status_code: int, context: String) -> void:
	if context != "world": return
	if not ok:
		status.text = "World load failed: " + str(data)
		return
	Session.last_world_data = data
	status.text = "Checking character..."
	API.request_finished.disconnect(_on_world_done)
	API.request_finished.connect(_on_character_done)
	API.get_json("/api/characters/me", "character_me")

func _on_character_done(ok: bool, data: Variant, status_code: int, context: String) -> void:
	if context != "character_me": return
	if ok and typeof(data) == TYPE_DICTIONARY and data.has("character") and data["character"] != null:
		Session.current_character = data["character"]
		Realtime.connect_to_server()
		get_tree().change_scene_to_file("res://scenes/CitySelect.tscn")
		return
	if status_code == 404:
		get_tree().change_scene_to_file("res://scenes/CharacterCreate.tscn")
		return
	status.text = "Character check failed: " + str(data)
