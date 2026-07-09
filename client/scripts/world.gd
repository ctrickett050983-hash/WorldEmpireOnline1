extends Control

@onready var info: Label = $Info
@onready var cities_list: ItemList = $CitiesList

func _ready() -> void:
	$RefreshButton.pressed.connect(refresh_world)
	$LogoutButton.pressed.connect(logout)
	render_world(Session.last_world_data)

func render_world(data) -> void:
	cities_list.clear()
	if typeof(data) != TYPE_DICTIONARY or not data.has("cities"):
		info.text = "No world data loaded."
		return

	var cities = data.cities
	info.text = "Loaded " + str(cities.size()) + " cities from " + Session.api_url

	for city in cities:
		var owner = "No owner"
		if city.has("owner_user_id") and str(city.owner_user_id) != "":
			owner = "Owned"
		var label = "%s, %s | Pop: %s | Treasury: %s | Happiness: %s | %s" % [
			city.get("name", "Unknown"),
			city.get("country", ""),
			city.get("population", "?"),
			city.get("treasury", "?"),
			city.get("happiness", "?"),
			owner
		]
		cities_list.add_item(label)

func refresh_world() -> void:
	info.text = "Refreshing world..."
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_world_refreshed.bind(http))
	http.request(
		Session.api_url + "/api/world",
		["Authorization: Bearer " + Session.token],
		HTTPClient.METHOD_GET
	)

func _on_world_refreshed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
	var data = JSON.parse_string(body.get_string_from_utf8())
	if response_code != 200 or typeof(data) != TYPE_DICTIONARY:
		info.text = "Refresh failed."
		return
	Session.last_world_data = data
	render_world(data)

func logout() -> void:
	Session.token = ""
	Session.last_world_data = {}
	get_tree().change_scene_to_file("res://scenes/Login.tscn")
