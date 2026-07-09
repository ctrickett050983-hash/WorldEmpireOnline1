extends Control

var first_name: LineEdit
var last_name: LineEdit
var dob: LineEdit
var nationality: LineEdit
var gender: OptionButton
var starting_city: OptionButton
var hair: OptionButton
var beard: OptionButton
var eyes: OptionButton
var skin: OptionButton
var outfit: OptionButton
var shoes: OptionButton
var status: Label
var city_ids: Array[String] = []

func _ready() -> void:
	_build_ui()
	API.request_finished.connect(_on_api_done)
	_populate_cities()

func _exit_tree() -> void:
	if API.request_finished.is_connected(_on_api_done):
		API.request_finished.disconnect(_on_api_done)

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.035, 0.045, 0.065)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(780, 700)
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -390
	panel.offset_top = -350
	panel.offset_right = 390
	panel.offset_bottom = 350
	add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	panel.add_child(root)

	var title := Label.new()
	title.text = "Create Your Character"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "This profile is saved to PostgreSQL and becomes your persistent online character."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(subtitle)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 10)
	root.add_child(grid)

	first_name = _add_line(grid, "First name", "Cameron")
	last_name = _add_line(grid, "Last name", "Trickett")
	dob = _add_line(grid, "Date of birth", "1990-01-01")
	nationality = _add_line(grid, "Nationality", "United Kingdom")
	gender = _add_options(grid, "Gender", ["Male", "Female", "Non-binary"])
	starting_city = _add_options(grid, "Starting city", [])
	hair = _add_options(grid, "Hair", ["Short", "Long", "Buzz Cut", "Curly", "Bald"])
	beard = _add_options(grid, "Beard", ["None", "Stubble", "Short Beard", "Full Beard"])
	eyes = _add_options(grid, "Eyes", ["Blue", "Brown", "Green", "Hazel", "Grey"])
	skin = _add_options(grid, "Skin tone", ["Light", "Medium", "Tan", "Dark"])
	outfit = _add_options(grid, "Clothes", ["Casual", "Business", "Streetwear", "Workwear"])
	shoes = _add_options(grid, "Shoes", ["Trainers", "Formal", "Boots", "Casual"])

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 14)
	root.add_child(buttons)

	var create_btn := Button.new()
	create_btn.text = "Create Character"
	create_btn.custom_minimum_size = Vector2(220, 48)
	create_btn.pressed.connect(_create_character)
	buttons.add_child(create_btn)

	var logout_btn := Button.new()
	logout_btn.text = "Back to Login"
	logout_btn.custom_minimum_size = Vector2(180, 48)
	logout_btn.pressed.connect(_back_to_login)
	buttons.add_child(logout_btn)

	status = Label.new()
	status.text = "Choose your look and starting city."
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(status)

func _add_label(parent: Control, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(label)

func _add_line(parent: Control, label_text: String, default_value: String = "") -> LineEdit:
	_add_label(parent, label_text)
	var line := LineEdit.new()
	line.text = default_value
	line.custom_minimum_size = Vector2(300, 36)
	parent.add_child(line)
	return line

func _add_options(parent: Control, label_text: String, values: Array) -> OptionButton:
	_add_label(parent, label_text)
	var opt := OptionButton.new()
	opt.custom_minimum_size = Vector2(300, 36)
	for value in values:
		opt.add_item(str(value))
	parent.add_child(opt)
	return opt

func _populate_cities() -> void:
	city_ids.clear()
	starting_city.clear()
	var world: Dictionary = Session.last_world_data
	var cities_value: Variant = world.get("cities", [])
	if typeof(cities_value) != TYPE_ARRAY:
		status.text = "No cities loaded. Please log in again."
		return
	var index := 0
	for c in cities_value:
		if typeof(c) != TYPE_DICTIONARY:
			continue
		var city_name := str(c.get("name", "Unknown City"))
		var country := str(c.get("country", ""))
		var city_id := str(c.get("id", ""))
		if city_id.length() == 0:
			continue
		city_ids.append(city_id)
		starting_city.add_item(city_name + " - " + country, index)
		index += 1
	if city_ids.is_empty():
		starting_city.add_item("No cities available")

func _create_character() -> void:
	if first_name.text.strip_edges().length() < 2:
		status.text = "First name must be at least 2 characters."
		return
	if last_name.text.strip_edges().length() < 2:
		status.text = "Last name must be at least 2 characters."
		return
	if city_ids.is_empty():
		status.text = "No starting city available."
		return
	var selected_index := starting_city.selected
	if selected_index < 0 or selected_index >= city_ids.size():
		selected_index = 0
	var payload := {
		"first_name": first_name.text.strip_edges(),
		"last_name": last_name.text.strip_edges(),
		"date_of_birth": dob.text.strip_edges(),
		"nationality": nationality.text.strip_edges(),
		"gender": gender.get_item_text(gender.selected),
		"starting_city_id": city_ids[selected_index],
		"hair": hair.get_item_text(hair.selected),
		"beard": beard.get_item_text(beard.selected),
		"eyes": eyes.get_item_text(eyes.selected),
		"skin_tone": skin.get_item_text(skin.selected),
		"clothes": outfit.get_item_text(outfit.selected),
		"shoes": shoes.get_item_text(shoes.selected)
	}
	status.text = "Saving character..."
	API.authed_post("/api/characters/create", payload, "character_create")

func _on_api_done(ok: bool, data: Variant, status_code: int, context: String) -> void:
	if context != "character_create":
		return
	if not ok:
		status.text = "Character save failed: " + str(data)
		return
	var character_value: Variant = data.get("character", {})
	if typeof(character_value) == TYPE_DICTIONARY:
		Session.current_character = character_value
	status.text = "Character created. Entering world..."
	get_tree().change_scene_to_file("res://scenes/CitySelect.tscn")

func _back_to_login() -> void:
	Session.logout()
	get_tree().change_scene_to_file("res://scenes/Login.tscn")
