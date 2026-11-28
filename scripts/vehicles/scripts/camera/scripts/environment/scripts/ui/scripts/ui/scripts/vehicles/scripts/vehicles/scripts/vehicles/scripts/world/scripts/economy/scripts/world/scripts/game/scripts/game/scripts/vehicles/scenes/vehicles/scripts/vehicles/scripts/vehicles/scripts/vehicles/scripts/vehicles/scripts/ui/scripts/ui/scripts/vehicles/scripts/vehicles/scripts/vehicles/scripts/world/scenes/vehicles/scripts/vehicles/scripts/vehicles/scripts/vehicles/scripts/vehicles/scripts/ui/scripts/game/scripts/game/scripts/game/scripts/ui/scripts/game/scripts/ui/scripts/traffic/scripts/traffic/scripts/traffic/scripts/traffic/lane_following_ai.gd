extends Node
class_name LaneFollowingAI

signal lane_changed(old_lane: int, new_lane: int)
signal lane_change_started(target_lane: int)
signal lane_change_completed(current_lane: int)

@export_group("Lane Settings")
@export var lane_points: Array[Node3D] = []
@export var current_lane: int = 0
@export var lane_change_speed: float = 3.0
@export var lane_tolerance: float = 1.5

@export_group("Vehicle Reference")
@export var vehicle: TrafficVehicleAI

@export_group("Lane Change Settings")
@export var allow_lane_change: bool = true
@export var lane_change_duration: float = 2.5
@export var minimum_change_distance: float = 8.0

var target_lane: int = -1
var changing_lane: bool = false
var change_progress: float = 0.0

var original_position: Vector3
var destination_position: Vector3


func _ready() -> void:

    add_to_group("lane_following_system")

    _find_vehicle()


func _physics_process(delta: float) -> void:

    _find_vehicle()

    if not is_instance_valid(vehicle):
        return

    if lane_points.is_empty():
        return

    if changing_lane:
        _update_lane_change(delta)
    else:
        _follow_current_lane()


# ============================================================
# FIND VEHICLE
# ============================================================

func _find_vehicle() -> void:

    if not is_instance_valid(vehicle):

        var parent := get_parent()

        if parent is TrafficVehicleAI:
            vehicle = parent


# ============================================================
# FOLLOW CURRENT LANE
# ============================================================

func _follow_current_lane() -> void:

    if current_lane < 0:
        return

    if current_lane >= lane_points.size():
        return

    var lane_point := lane_points[current_lane]

    if not is_instance_valid(lane_point):
        return

    var lane_position := lane_point.global_position

    var vehicle_position := vehicle.global_position

    var offset := lane_position - vehicle_position
    offset.y = 0.0

    var distance := offset.length()

    if distance > lane_tolerance:

        var direction := offset.normalized()

        var desired_yaw := atan2(
            -direction.x,
            -direction.z
        )

        vehicle.global_rotation.y = lerp_angle(
            vehicle.global_rotation.y,
            desired_yaw,
            lane_change_speed * get_physics_process_delta_time()
        )


# ============================================================
# START LANE CHANGE
# ============================================================

func change_lane(new_lane: int) -> bool:

    if not allow_lane_change:
        return false

    if changing_lane:
        return false

    if new_lane < 0 or new_lane >= lane_points.size():
        return false

    if new_lane == current_lane:
        return false

    var target_point := lane_points[new_lane]

    if not is_instance_valid(target_point):
        return false

    var distance := vehicle.global_position.distance_to(
        target_point.global_position
    )

    if distance < minimum_change_distance:
        return false

    target_lane = new_lane

    original_position = vehicle.global_position

    destination_position = target_point.global_position

    change_progress = 0.0
    changing_lane = true

    lane_change_started.emit(target_lane)

    return true


# ============================================================
# UPDATE LANE CHANGE
# ============================================================

func _update_lane_change(delta: float) -> void:

    if not is_instance_valid(vehicle):
        return

    change_progress += delta / maxf(
        lane_change_duration,
        0.1
    )

    var weight := clampf(change_progress, 0.0, 1.0)

    # Smooth interpolation
    weight = weight * weight * (3.0 - 2.0 * weight)

    var next_position := original_position.lerp(
        destination_position,
        weight
    )

    var movement := next_position - vehicle.global_position

    movement.y = 0.0

    if movement.length_squared() > 0.001:

        var direction := movement.normalized()

        var desired_yaw := atan2(
            -direction.x,
            -direction.z
        )

        vehicle.global_rotation.y = lerp_angle(
            vehicle.global_rotation.y,
            desired_yaw,
            lane_change_speed * delta
        )

    if change_progress >= 1.0:

        var old_lane := current_lane

        current_lane = target_lane

        target_lane = -1
        changing_lane = false

        lane_changed.emit(old_lane, current_lane)
        lane_change_completed.emit(current_lane)


# ============================================================
# AUTOMATIC LANE CHANGE
# ============================================================

func change_to_left_lane() -> bool:

    return change_lane(current_lane - 1)


func change_to_right_lane() -> bool:

    return change_lane(current_lane + 1)


func return_to_current_lane() -> void:

    if changing_lane:
        return

    if current_lane < 0 or current_lane >= lane_points.size():
        return

    var point := lane_points[current_lane]

    if not is_instance_valid(point):
        return

    destination_position = point.global_position


# ============================================================
# INFORMATION
# ============================================================

func get_current_lane() -> int:
    return current_lane


func is_changing_lane() -> bool:
    return changing_lane


func get_target_lane() -> int:
    return target_lane
