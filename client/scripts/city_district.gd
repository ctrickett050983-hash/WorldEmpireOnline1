extends Node3D

@onready var city_label: Label = $HUD/TopBar/CityLabel
@onready var stats_label: Label = $HUD/TopBar/StatsLabel
@onready var property_list: ItemList = $HUD/PropertyPanel/PropertyList
@onready var action_status: Label = $HUD/PropertyPanel/ActionStatus
@onready var buildings_root: Node3D = $Buildings
@onready var player: CharacterBody3D = $Player
@onready var interact_label: Label = $HUD/InteractionPrompt
@onready var phone_panel: Panel = $HUD/PhonePanel
@onready var phone_title: Label = $HUD/PhonePanel/PhoneTitle
@onready var phone_body: RichTextLabel = $HUD/PhonePanel/PhoneBody

var properties: Array = []
var city: Dictionary = {}
var businesses: Array = []
var building_lookup: Array = []
var nearby_property_index: int = -1

func _ready() -> void:
	$HUD/BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/WorldMap.tscn"))
	$HUD/PropertyPanel/BuyButton.pressed.connect(buy_selected_property)
	$HUD/PropertyPanel/RefreshCityButton.pressed.connect(refresh_city)
	$HUD/PhoneButton.pressed.connect(toggle_phone)
	$HUD/PhonePanel/ClosePhoneButton.pressed.connect(func(): phone_panel.visible = false)
	$HUD/PhonePanel/PropertyAppButton.pressed.connect(show_phone_properties)
	$HUD/PhonePanel/BankAppButton.pressed.connect(show_phone_bank)
	$HUD/PhonePanel/CityAppButton.pressed.connect(show_phone_city)
	$HUD/PhonePanel/BusinessAppButton.pressed.connect(show_phone_business)
	phone_panel.visible = false
	render_city(Session.selected_city_detail)

func _process(_delta: float) -> void:
	update_nearby_property()
	if Input.is_action_just_pressed("interact") and nearby_property_index >= 0:
		property_list.select(nearby_property_index)
		show_selected_property_details(nearby_property_index)
	if Input.is_action_just_pressed("phone"):
		toggle_phone()

func render_city(data: Variant) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		action_status.text = "No city data loaded."
		return
	city = data.get("city", Session.selected_city)
	properties = data.get("properties", [])
	businesses = data.get("businesses", [])
	city_label.text = str(city.get("name", "City")) + ", " + str(city.get("country", ""))
	stats_label.text = "Population: %s | Happiness: %s | Safety: %s | Treasury: £%s | Businesses: %s" % [
		city.get("population", "?"), city.get("happiness", "?"), city.get("safety", "?"), city.get("treasury", "?"), businesses.size()
	]
	property_list.clear()
	for p in properties:
		var owner := "Available"
		if str(p.get("owner_user_id", "")) != "": owner = "Owned"
		var price: String = str(p.get("value", "?"))
		property_list.add_item("%s | %s | £%s | %s" % [p.get("name", "Property"), p.get("kind", ""), price, owner])
	spawn_buildings()
	show_phone_city()

func spawn_buildings() -> void:
	for child in buildings_root.get_children():
		child.queue_free()
	building_lookup.clear()
	var index := 0
	for p in properties:
		var root := Node3D.new()
		root.name = str(p.get("name", "Building"))
		var h := 2.0 + float(index % 5)
		root.position = Vector3((index % 6) * 7 - 18, 0, int(index / 6) * 7 - 16)

		var box := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(4, h, 4)
		box.mesh = mesh
		box.position = Vector3(0, h / 2.0, 0)
		root.add_child(box)

		var sign := Label3D.new()
		sign.text = str(p.get("name", "Property")) + "\n£" + str(p.get("value", "?"))
		sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		sign.position = Vector3(0, h + 0.9, 0)
		sign.font_size = 36
		root.add_child(sign)

		buildings_root.add_child(root)
		building_lookup.append({"node": root, "property": p, "index": index})
		index += 1

func update_nearby_property() -> void:
	nearby_property_index = -1
	var best_distance := 99999.0
	for entry in building_lookup:
		var node: Node3D = entry.get("node")
		var distance := player.global_position.distance_to(node.global_position)
		if distance < 5.5 and distance < best_distance:
			best_distance = distance
			nearby_property_index = int(entry.get("index", -1))
	if nearby_property_index >= 0:
		var p: Dictionary = properties[nearby_property_index]
		interact_label.visible = true
		interact_label.text = "Press E to inspect: %s (£%s)" % [p.get("name", "Property"), p.get("value", "?")]
	else:
		interact_label.visible = false

func show_selected_property_details(index: int) -> void:
	if index < 0 or index >= properties.size():
		return
	var p: Dictionary = properties[index]
	var owner := "Available"
	if str(p.get("owner_user_id", "")) != "":
		owner = "Owned"
	action_status.text = "%s\nType: %s\nValue: £%s\nStatus: %s\nUse Buy Selected to purchase." % [
		p.get("name", "Property"), p.get("kind", ""), p.get("value", "?"), owner
	]

func buy_selected_property() -> void:
	var selected := property_list.get_selected_items()
	if selected.is_empty():
		action_status.text = "Select or inspect a property first."
		return
	var p: Dictionary = properties[int(selected[0])]
	action_status.text = "Buying " + str(p.get("name", "property")) + "..."
	Api.request_finished.connect(_on_property_bought, CONNECT_ONE_SHOT)
	Api.post_json("/api/properties/" + str(p.get("id", "")) + "/buy", {}, Session.token)

func _on_property_bought(ok: bool, data: Variant, status: int, raw: String) -> void:
	if not ok:
		action_status.text = "Purchase failed: " + raw
		return
	action_status.text = "Property bought. Refreshing city..."
	refresh_city()

func refresh_city() -> void:
	if not city.has("id"):
		action_status.text = "Missing city id."
		return
	Api.request_finished.connect(_on_city_refreshed, CONNECT_ONE_SHOT)
	Api.get_json("/api/cities/" + str(city.get("id", "")), Session.token)

func _on_city_refreshed(ok: bool, data: Variant, status: int, raw: String) -> void:
	if not ok:
		action_status.text = "Refresh failed: " + raw
		return
	Session.selected_city_detail = data
	render_city(data)
	action_status.text = "City refreshed."

func toggle_phone() -> void:
	phone_panel.visible = not phone_panel.visible
	if phone_panel.visible:
		show_phone_city()

func show_phone_city() -> void:
	phone_title.text = "City App"
	phone_body.text = "[b]%s[/b]\nCountry: %s\nPopulation: %s\nHappiness: %s\nSafety: %s\nTreasury: £%s\n\nGoal: keep this city attractive so residents and businesses want to stay." % [
		city.get("name", "City"), city.get("country", ""), city.get("population", "?"), city.get("happiness", "?"), city.get("safety", "?"), city.get("treasury", "?")
	]

func show_phone_properties() -> void:
	phone_title.text = "Property App"
	var available := 0
	var owned := 0
	for p in properties:
		if str(p.get("owner_user_id", "")) == "":
			available += 1
		else:
			owned += 1
	phone_body.text = "Properties in city: %s\nAvailable: %s\nOwned: %s\n\nWalk to a building and press E to inspect it, or select one in the panel." % [properties.size(), available, owned]

func show_phone_bank() -> void:
	phone_title.text = "Bank App"
	phone_body.text = "Personal account connected.\n\nNext Sprint feature: mortgages, loans, deposits, bank ownership, and developer oversight screens."

func show_phone_business() -> void:
	phone_title.text = "Business App"
	phone_body.text = "Businesses in this city: %s\n\nNext Sprint feature: create a business inside a property you own, hire staff, stock shelves, and set prices." % [businesses.size()]
