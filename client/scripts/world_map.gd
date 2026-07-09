extends Control

@onready var cities_list: ItemList = $CitiesList
@onready var status_label: Label = $Status

const CITY_SCENE := "res://scenes/CityDistrict.tscn"
var cities: Array = []

func _ready() -> void:
	$EnterCityButton.pressed.connect(enter_selected_city)
	$RefreshButton.pressed.connect(refresh_world)
	$LogoutButton.pressed.connect(logout)
	render_world(Session.last_world_data)

func render_world(data: Variant) -> void:
	cities_list.clear()
	cities = []
	if typeof(data) != TYPE_DICTIONARY or not data.has("cities"):
		status_label.text = "No world data loaded."
		return
	cities = data.cities
	status_label.text = "Loaded " + str(cities.size()) + " cities from " + Session.api_url
	for city in cities:
		var owner := "Unclaimed"
		if str(city.get("owner_user_id", "")) != "":
			owner = "Owned by " + str(city.get("owner_name", "player"))
		var label := "%s, %s | Pop %s | £%s treasury | Happy %s | %s" % [
			city.get("name", "Unknown"),
			city.get("country", ""),
			city.get("population", "?"),
			city.get("treasury", "?"),
			city.get("happiness", "?"),
			owner
		]
		cities_list.add_item(label)

func refresh_world() -> void:
	status_label.text = "Refreshing world..."
	Api.request_finished.connect(_on_world_refreshed, CONNECT_ONE_SHOT)
	Api.get_json("/api/world", Session.token)

func _on_world_refreshed(ok: bool, data: Variant, status: int, raw: String) -> void:
	if not ok:
		status_label.text = "Refresh failed: " + raw
		return
	Session.last_world_data = data
	render_world(data)

func enter_selected_city() -> void:
	var selected := cities_list.get_selected_items()
	if selected.is_empty():
		status_label.text = "Select a city first."
		return
	var city = cities[selected[0]]
	Session.selected_city = city
	status_label.text = "Loading " + str(city.get("name", "city")) + "..."
	Api.request_finished.connect(_on_city_loaded, CONNECT_ONE_SHOT)
	Api.get_json("/api/cities/" + str(city.id), Session.token)

func _on_city_loaded(ok: bool, data: Variant, status: int, raw: String) -> void:
	if not ok:
		status_label.text = "City load failed: " + raw
		return
	Session.selected_city_detail = data
	get_tree().change_scene_to_file(CITY_SCENE)

func logout() -> void:
	Session.reset()
	get_tree().change_scene_to_file("res://scenes/Login.tscn")
