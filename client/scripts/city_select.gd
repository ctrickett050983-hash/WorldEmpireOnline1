extends Control

var list: VBoxContainer
var status: Label

func _ready() -> void:
	_build_ui()
	_populate()
	API.request_finished.connect(_on_api_done)

func _build_ui() -> void:
	var bg := ColorRect.new(); bg.color = Color(0.03, 0.05, 0.08); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var root := VBoxContainer.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.add_theme_constant_override("separation", 14); root.offset_left=40; root.offset_top=35; root.offset_right=-40; root.offset_bottom=-35; add_child(root)
	var title := Label.new(); title.text="Choose Your City"; title.add_theme_font_size_override("font_size", 34); root.add_child(title)
	var help := Label.new(); help.text="Cities are owned and maintained by players. Pick a city to inspect properties, businesses and banks."; help.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; root.add_child(help)
	var scroll := ScrollContainer.new(); scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL; root.add_child(scroll)
	list = VBoxContainer.new(); list.add_theme_constant_override("separation", 10); scroll.add_child(list)
	status = Label.new(); status.text=""; root.add_child(status)

func _populate() -> void:
	for child in list.get_children(): child.queue_free()
	var cities: Array = Session.last_world_data.get("cities", [])
	for c in cities:
		var b := Button.new()
		var owner := str(c.get("owner_name", "Unowned"))
		if owner.is_empty(): owner = "Unowned"
		b.text = "%s, %s  | Pop %s | Happiness %s | Owner %s" % [c.get("name","City"), c.get("country",""), str(c.get("population",0)), str(c.get("happiness",0)), owner]
		b.pressed.connect(_select_city.bind(c))
		list.add_child(b)

func _select_city(city: Dictionary) -> void:
	Session.selected_city = city
	status.text = "Loading " + str(city.get("name", "city")) + "..."
	API.get_json("/api/cities/%s" % str(city.get("id", "")), "city_detail")

func _on_api_done(ok: bool, data: Variant, status_code: int, context: String) -> void:
	if context != "city_detail": return
	if not ok:
		status.text = "Could not load city: " + str(data)
		return
	Session.city_detail = data
	get_tree().change_scene_to_file("res://scenes/District.tscn")
