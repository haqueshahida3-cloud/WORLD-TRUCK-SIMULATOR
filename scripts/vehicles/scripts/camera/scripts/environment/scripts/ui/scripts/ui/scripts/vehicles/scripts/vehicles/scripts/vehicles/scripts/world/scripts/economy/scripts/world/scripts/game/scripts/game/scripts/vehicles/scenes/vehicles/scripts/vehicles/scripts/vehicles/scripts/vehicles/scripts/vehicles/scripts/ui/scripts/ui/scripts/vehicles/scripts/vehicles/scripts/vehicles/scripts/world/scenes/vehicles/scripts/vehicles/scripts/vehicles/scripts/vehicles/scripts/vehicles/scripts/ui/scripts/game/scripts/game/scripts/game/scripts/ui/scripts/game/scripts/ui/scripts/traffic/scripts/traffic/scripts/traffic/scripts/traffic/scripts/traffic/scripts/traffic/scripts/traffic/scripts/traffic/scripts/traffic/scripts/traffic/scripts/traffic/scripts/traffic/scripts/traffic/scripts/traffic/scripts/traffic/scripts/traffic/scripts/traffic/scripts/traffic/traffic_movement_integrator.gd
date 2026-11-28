extends Node
class_name TrafficMovementIntegrator

@export_group("Vehicle")
@export var vehicle: CharacterBody3D

@export_group("Lane Changing")
@export var lane_change_enabled: bool = true
@export var lane_change_speed: float = 3.0

@export_group("Safety")
@export var minimum_lane_distance: float = 8.0
@export var detection_distance: float = 20.0

var lane_markers: Array[Marker3D] = []

var current_lane: int = 0
var target_lane: int = 0

var lane_change_active: bool = false
var lane_change_progress: float = 0.0

var original_position: Vector3
var target_position: Vector3


func _ready() -> void:

    if not is_instance_valid(vehicle):
        push_error("TrafficMovementIntegrator: Vehicle is missing.")
        set_physics_process(false)
        return

    original_position = vehicle.global_position


func _physics_process(delta: float) -> void:

    if not is_instance_valid(vehicle):
        return

    if not lane_change_enabled:
        return

    if not lane_change_active:
        return

    _update_lane_change(delta)


# ============================================================
# REGISTER LANES
# ============================================================

func set_lane_markers(markers: Array[Marker3D]) -> void:

    lane_markers.clear()

    for marker in markers:

        if is_instance_valid(marker):
            lane_markers.append(marker)


func set_current_lane(index: int) -> void:

    if index < 0 or index >= lane_markers.size():
        return

    current_lane = index
    target_lane = index


# ============================================================
# LANE CHANGE REQUEST
# ============================================================

func request_lane_change(new_lane: int) -> bool:

    if not lane_change_enabled:
        return false

    if lane_change_active:
        return false

    if new_lane < 0 or new_lane >= lane_markers.size():
        return false

    if new_lane == current_lane:
        return false

    if not _is_lane_safe(new_lane):
        return false

    target_lane = new_lane

    original_position = vehicle.global_position
    target_position = lane_markers[new_lane].global_position

    lane_change_progress = 0.0
    lane_change_active = true

    return true


# ============================================================
# SAFE LANE DETECTION
# ============================================================

func _is_lane_safe(index: int) -> bool:

    if index < 0 or index >= lane_markers.size():
        return false

    var marker := lane_markers[index]

    if not is_instance_valid(marker):
        return false

    var vehicles := get_tree().get_nodes_in_group(
        "traffic_vehicles"
    )

    for node in vehicles:

        if node == vehicle:
            continue

        if not node is Node3D:
            continue

        var other := node as Node3D

        var distance := other.global_position.distance_to(
            marker.global_position
        )

        if distance < minimum_lane_distance:
            return false

    return true


# ============================================================
# SMOOTH LANE MOVEMENT
# ============================================================

func _update_lane_change(delta: float) -> void:

    lane_change_progress += (
        lane_change_speed * delta
    )

    var weight := clampf(
        lane_change_progress,
        0.0,
        1.0
    )

    weight = smoothstep(0.0, 1.0, weight)

    var destination := original_position.lerp(
        target_position,
        weight
    )

    # Only move sideways; preserve the vehicle's forward progress.
    var forward := -vehicle.global_transform.basis.z
    forward.y = 0.0
    forward = forward.normalized()

    var lateral_offset := (
        target_position - original_position
    )

    lateral_offset.y = 0.0

    var lateral_position := (
        original_position + lateral_offset * weight
    )

    vehicle.global_position.x = lateral_position.x
    vehicle.global_position.z = lateral_position.z

    if lane_change_progress >= 1.0:

        current_lane = target_lane
        lane_change_active = false

        vehicle.global_position.x = target_position.x
        vehicle.global_position.z = target_position.z


# ============================================================
# CANCEL / CONTROL
# ============================================================

func cancel_lane_change() -> void:

    lane_change_active = false
    lane_change_progress = 0.0


func is_changing_lane() -> bool:
    return lane_change_active


func get_current_lane() -> int:
    return current_lane


func get_target_lane() -> int:
    return target_lane


func set_lane_change_enabled(enabled: bool) -> void:

    lane_change_enabled = enabled

    if not enabled:
        cancel_lane_change()
