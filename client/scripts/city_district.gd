extends Node3D

@onready var city_label: Label = $HUD/TopBar/CityLabel
@onready var stats_label: Label = $HUD/TopBar/StatsLabel
@onready var property_list: ItemList = $HUD/PropertyPanel/PropertyList
@onready var action_status: Label = $HUD/PropertyPanel/ActionStatus
@onready var buildings_root: Node3D = $Buildings

var properties: Array = []
var city: Dictionary = {}

func _ready() -> void:
	$HUD/BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/WorldMap.tscn"))
	$HUD/PropertyPanel/BuyButton.pressed.connect(buy_selected_property)
	$HUD/PropertyPanel/RefreshCityButton.pressed.connect(refresh_city)
	render_city(Session.selected_city_detail)

func render_city(data: Variant) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		action_status.text = "No city data loaded."
		return
	city = data.get("city", Session.selected_city)
	properties = data.get("properties", [])
	var businesses: Array = data.get("businesses", [])
	city_label.text = str(city.get("name", "City")) + ", " + str(city.get("country", ""))
	stats_label.text = "Population: %s | Happiness: %s | Safety: %s | Treasury: £%s | Businesses: %s" % [
		city.get("population", "?"), city.get("happiness", "?"), city.get("safety", "?"), city.get("treasury", "?"), businesses.size()
	]
	property_list.clear()
	for p in properties:
		var owner := "Available"
		if str(p.get("owner_user_id", "")) != "": owner = "Owned"
		var price := p.get("value", "?")
		property_list.add_item("%s | %s | £%s | %s" % [p.get("name", "Property"), p.get("kind", ""), price, owner])
	spawn_buildings()

func spawn_buildings() -> void:
	for child in buildings_root.get_children(): child.queue_free()
	var index := 0
	for p in properties:
		var box := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		var h := 2.0 + float(index % 5)
		mesh.size = Vector3(4, h, 4)
		box.mesh = mesh
		box.position = Vector3((index % 6) * 7 - 18, h / 2.0, int(index / 6) * 7 - 16)
		box.name = str(p.get("name", "Building"))
		buildings_root.add_child(box)
		index += 1

func buy_selected_property() -> void:
	var selected := property_list.get_selected_items()
	if selected.is_empty():
		action_status.text = "Select a property first."
		return
	var p = properties[selected[0]]
	action_status.text = "Buying " + str(p.get("name", "property")) + "..."
	Api.request_finished.connect(_on_property_bought, CONNECT_ONE_SHOT)
	Api.post_json("/api/properties/" + str(p.id) + "/buy", {}, Session.token)

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
	Api.get_json("/api/cities/" + str(city.id), Session.token)

func _on_city_refreshed(ok: bool, data: Variant, status: int, raw: String) -> void:
	if not ok:
		action_status.text = "Refresh failed: " + raw
		return
	Session.selected_city_detail = data
	render_city(data)
	action_status.text = "City refreshed."
