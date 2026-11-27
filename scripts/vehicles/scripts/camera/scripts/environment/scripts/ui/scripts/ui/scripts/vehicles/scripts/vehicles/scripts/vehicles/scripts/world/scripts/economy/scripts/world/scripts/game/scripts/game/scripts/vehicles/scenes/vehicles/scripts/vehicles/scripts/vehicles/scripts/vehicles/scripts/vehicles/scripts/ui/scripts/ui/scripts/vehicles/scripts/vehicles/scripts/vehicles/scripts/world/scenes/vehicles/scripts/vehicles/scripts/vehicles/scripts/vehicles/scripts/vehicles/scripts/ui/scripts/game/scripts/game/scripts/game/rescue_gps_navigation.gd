extends Node3D
class_name RescueGPSNavigation

signal destination_reached
signal navigation_updated(distance: float)

@export_group("References")
@export var truck: VehicleBody3D
@export var rescue_mission: RescueMission

@export_group("Navigation")
@export var marker_height: float = 5.0
@export var arrival_distance: float = 12.0
@export var update_interval: float = 0.25

@export_group("Marker")
@export var marker_size: float = 1.5

var destination_marker: MeshInstance3D
var marker_material: StandardMaterial3D

var destination_position: Vector3 = Vector3.ZERO
var navigation_active: bool = false
var distance_to_destination: float = 0.0

var update_timer: float = 0.0
var arrival_reported: bool = false


func _ready() -> void:
    add_to_group("rescue_gps")
    _find_references()
    _create_marker()


func _process(delta: float) -> void:

    if not navigation_active:
        return

    update_timer += delta

    if update_timer < update_interval:
        return

    update_timer = 0.0

    _update_navigation()


# ============================================================
# REFERENCES
# ============================================================

func _find_references() -> void:

    if not is_instance_valid(truck):
        truck = get_tree().get_first_node_in_group(
            "tow_truck"
        ) as VehicleBody3D

    if not is_instance_valid(rescue_mission):
        rescue_mission = get_tree().get_first_node_in_group(
            "rescue_mission"
        ) as RescueMission


# ============================================================
# CREATE MARKER
# ============================================================

func _create_marker() -> void:

    destination_marker = MeshInstance3D.new()
    destination_marker.name = "DestinationMarker"

    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.0
    mesh.bottom_radius = marker_size
    mesh.height = marker_height
    mesh.radial_segments = 4

    destination_marker.mesh = mesh

    marker_material = StandardMaterial3D.new()
    marker_material.albedo_color = Color(0.1, 0.9, 0.3, 1.0)
    marker_material.emission_enabled = true
    marker_material.emission = Color(0.05, 0.8, 0.2)
    marker_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

    destination_marker.material_override = marker_material

    add_child(destination_marker)

    destination_marker.visible = false


# ============================================================
# START NAVIGATION
# ============================================================

func start_navigation(position: Vector3) -> void:

    destination_position = position
    navigation_active = true
    arrival_reported = false

    if destination_marker != null:
        destination_marker.visible = true

    _update_navigation()


func start_delivery_navigation() -> bool:

    _find_references()

    if not is_instance_valid(rescue_mission):
        return false

    if not rescue_mission.is_mission_active():
        return false

    if rescue_mission.current_mission.is_empty():
        return false

    var destination: Vector3 = rescue_mission.current_mission[
        "destination"
    ]

    start_navigation(destination)

    return true


func start_pickup_navigation() -> bool:

    _find_references()

    if not is_instance_valid(rescue_mission):
        return false

    if rescue_mission.current_mission.is_empty():
        return false

    var pickup: Vector3 = rescue_mission.current_mission[
        "pickup"
    ]

    start_navigation(pickup)

    return true


# ============================================================
# UPDATE NAVIGATION
# ============================================================

func _update_navigation() -> void:

    if not is_instance_valid(truck):
        _find_references()

    if not is_instance_valid(truck):
        return

    var target := destination_position
    var vehicle_position := truck.global_position

    distance_to_destination = vehicle_position.distance_to(
        target
    )

    if destination_marker != null:
        destination_marker.global_position = Vector3(
            target.x,
            target.y + marker_height * 0.5,
            target.z
        )

    navigation_updated.emit(distance_to_destination)

    if (
        distance_to_destination <= arrival_distance
        and not arrival_reported
    ):
        arrival_reported = true
        destination_reached.emit()


# ============================================================
# STOP NAVIGATION
# ============================================================

func stop_navigation() -> void:

    navigation_active = false

    if destination_marker != null:
        destination_marker.visible = false

    arrival_reported = false


# ============================================================
# INFORMATION
# ============================================================

func get_distance_to_destination() -> float:
    return distance_to_destination


func get_distance_km() -> float:
    return distance_to_destination / 1000.0


func get_destination_position() -> Vector3:
    return destination_position


func is_navigation_active() -> bool:
    return navigation_active


func get_direction_to_destination() -> Vector3:

    if not is_instance_valid(truck):
        return Vector3.ZERO

    return (
        destination_position - truck.global_position
    ).normalized()
