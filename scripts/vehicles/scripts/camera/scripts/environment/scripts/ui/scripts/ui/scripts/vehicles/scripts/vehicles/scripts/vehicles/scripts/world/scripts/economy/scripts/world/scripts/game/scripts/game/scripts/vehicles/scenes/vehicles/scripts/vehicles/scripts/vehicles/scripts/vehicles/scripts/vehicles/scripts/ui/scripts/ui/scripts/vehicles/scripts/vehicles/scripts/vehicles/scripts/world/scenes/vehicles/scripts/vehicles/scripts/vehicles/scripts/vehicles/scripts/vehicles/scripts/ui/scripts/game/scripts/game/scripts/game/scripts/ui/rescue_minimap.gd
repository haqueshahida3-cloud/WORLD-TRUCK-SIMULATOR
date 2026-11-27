extends CanvasLayer
class_name RescueMinimap

@export_group("References")
@export var truck: VehicleBody3D
@export var gps: RescueGPSNavigation

@export_group("Map Settings")
@export var map_size: Vector2 = Vector2(220, 220)
@export var map_range: float = 500.0
@export var update_interval: float = 0.1

var map_panel: PanelContainer
var map_draw: Control
var distance_label: Label
var direction_label: Label

var update_timer: float = 0.0


func _ready() -> void:
    _find_references()
    _create_minimap()


func _process(delta: float) -> void:

    update_timer += delta

    if update_timer >= update_interval:
        update_timer = 0.0

        _find_references()

        if map_draw != null:
            map_draw.queue_redraw()

        _update_information()


func _find_references() -> void:

    if not is_instance_valid(truck):
        truck = get_tree().get_first_node_in_group(
            "tow_truck"
        ) as VehicleBody3D

    if not is_instance_valid(gps):
        gps = get_tree().get_first_node_in_group(
            "rescue_gps"
        ) as RescueGPSNavigation


# ============================================================
# CREATE UI
# ============================================================

func _create_minimap() -> void:

    map_panel = PanelContainer.new()
    map_panel.position = Vector2(20, 20)
    map_panel.custom_minimum_size = map_size
    add_child(map_panel)

    var layout := VBoxContainer.new()
    map_panel.add_child(layout)

    var title := Label.new()
    title.text = "GPS NAVIGATION"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    layout.add_child(title)

    map_draw = Control.new()
    map_draw.custom_minimum_size = map_size - Vector2(20, 65)
    map_draw.draw.connect(_draw_map)
    layout.add_child(map_draw)

    distance_label = Label.new()
    distance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    layout.add_child(distance_label)

    direction_label = Label.new()
    direction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    layout.add_child(direction_label)


# ============================================================
# DRAW MAP
# ============================================================

func _draw_map() -> void:

    var center := map_draw.size * 0.5

    map_draw.draw_rect(
        Rect2(Vector2.ZERO, map_draw.size),
        Color(0.08, 0.12, 0.14, 0.95)
    )

    map_draw.draw_line(
        Vector2(center.x, 0),
        Vector2(center.x, map_draw.size.y),
        Color(0.3, 0.35, 0.38),
        1.0
    )

    map_draw.draw_line(
        Vector2(0, center.y),
        Vector2(map_draw.size.x, center.y),
        Color(0.3, 0.35, 0.38),
        1.0
    )

    if not is_instance_valid(truck):
        return

    # Player marker
    map_draw.draw_circle(
        center,
        6.0,
        Color(0.1, 0.8, 1.0)
    )

    if not is_instance_valid(gps):
        return

    if not gps.is_navigation_active():
        return

    var direction := gps.get_direction_to_destination()

    var local_direction := truck.global_transform.basis.inverse() * direction

    var map_direction := Vector2(
        local_direction.x,
        -local_direction.z
    )

    var scale_factor := map_range

    var marker_position := center + map_direction * (
        map_draw.size.x * 0.45 / scale_factor
    ) * gps.get_distance_to_destination()

    marker_position.x = clampf(
        marker_position.x,
        8.0,
        map_draw.size.x - 8.0
    )

    marker_position.y = clampf(
        marker_position.y,
        8.0,
        map_draw.size.y - 8.0
    )

    # Destination marker
    map_draw.draw_circle(
        marker_position,
        6.0,
        Color(0.2, 1.0, 0.3)
    )

    # Direction line
    map_draw.draw_line(
        center,
        marker_position,
        Color(0.2, 1.0, 0.3),
        2.0
    )


# ============================================================
# INFORMATION
# ============================================================

func _update_information() -> void:

    if not is_instance_valid(gps):
        distance_label.text = "GPS: Waiting..."
        direction_label.text = ""
        return

    if not gps.is_navigation_active():
        distance_label.text = "GPS: Inactive"
        direction_label.text = ""
        return

    var distance := gps.get_distance_to_destination()

    if distance >= 1000.0:
        distance_label.text = "Distance: %.2f km" % (
            distance / 1000.0
        )
    else:
        distance_label.text = "Distance: %.0f m" % distance

    direction_label.text = "Destination: GREEN"


func set_map_range(value: float) -> void:
    map_range = maxf(value, 50.0)


func get_map_range() -> float:
    return map_range
