extends Node
class_name SafeLaneChangeAI

@export_group("Vehicle")
@export var vehicle: CharacterBody3D

@export_group("Lane Settings")
@export var lane_markers: Array[Marker3D] = []
@export var current_lane: int = 0
@export var lane_change_speed: float = 3.0
@export var lane_detection_distance: float = 18.0

@export_group("Overtaking")
@export var overtaking_speed_bonus: float = 15.0
@export var overtaking_cooldown: float = 4.0
@export var return_after_overtake: bool = true

@export_group("Safety")
@export var side_detection_distance: float = 12.0
@export var minimum_safe_distance: float = 8.0
@export var detection_height: float = 1.0

var original_lane: int = 0
var target_lane: int = 0

var is_changing_lane: bool = false
var is_overtaking: bool = false

var lane_change_timer: float = 0.0
var cooldown_timer: float = 0.0

var original_speed: float = 0.0
var current_speed_limit: float = 0.0


func _ready() -> void:

    if not is_instance_valid(vehicle):
        push_warning("SafeLaneChangeAI: Vehicle is not assigned.")
        set_physics_process(false)
        return

    original_lane = current_lane
    target_lane = current_lane

    if vehicle.has_method("get_speed_kmh"):
        original_speed = vehicle.get_speed_kmh()


func _physics_process(delta: float) -> void:

    if not is_instance_valid(vehicle):
        return

    if cooldown_timer > 0.0:
        cooldown_timer -= delta

    if is_changing_lane:
        _update_lane_change(delta)
        return

    if is_overtaking:
        _check_overtake_completion()
        return

    _check_for_slow_vehicle()


# ============================================================
# SLOW VEHICLE DETECTION
# ============================================================

func _check_for_slow_vehicle() -> void:

    if cooldown_timer > 0.0:
        return

    if not _has_front_obstacle():
        return

    var next_lane := _find_safe_lane()

    if next_lane == -1:
        return

    if _begin_lane_change(next_lane):
        is_overtaking = true


func _has_front_obstacle() -> bool:

    var space := vehicle.get_world_3d().direct_space_state

    var origin := vehicle.global_position
    origin.y += detection_height

    var direction := -vehicle.global_transform.basis.z

    var query := PhysicsRayQueryParameters3D.create(
        origin,
        origin + direction * lane_detection_distance
    )

    query.exclude = [vehicle.get_rid()]

    var result := space.intersect_ray(query)

    if result.is_empty():
        return false

    var collider: Object = result.get("collider")

    return (
        collider is CharacterBody3D
        or collider is VehicleBody3D
    )


# ============================================================
# SAFE LANE SEARCH
# ============================================================

func _find_safe_lane() -> int:

    if lane_markers.size() < 2:
        return -1

    var left_lane := current_lane - 1
    var right_lane := current_lane + 1

    if left_lane >= 0 and _is_lane_safe(left_lane):
        return left_lane

    if right_lane < lane_markers.size() and _is_lane_safe(right_lane):
        return right_lane

    return -1


func _is_lane_safe(lane_index: int) -> bool:

    if lane_index < 0 or lane_index >= lane_markers.size():
        return false

    var marker := lane_markers[lane_index]

    if not is_instance_valid(marker):
        return false

    var target_position := marker.global_position

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
            target_position
        )

        if distance < minimum_safe_distance:
            return false

    return true


# ============================================================
# LANE CHANGE
# ============================================================

func _begin_lane_change(new_lane: int) -> bool:

    if new_lane < 0 or new_lane >= lane_markers.size():
        return false

    if not _is_lane_safe(new_lane):
        return false

    original_lane = current_lane
    target_lane = new_lane

    is_changing_lane = true
    lane_change_timer = 0.0

    return true


func _update_lane_change(delta: float) -> void:

    if target_lane < 0 or target_lane >= lane_markers.size():
        _cancel_lane_change()
        return

    var marker := lane_markers[target_lane]

    if not is_instance_valid(marker):
        _cancel_lane_change()
        return

    lane_change_timer += delta

    var target_position := marker.global_position

    var current_position := vehicle.global_position

    var direction := (
        target_position - current_position
    )

    direction.y = 0.0

    var distance := direction.length()

    if distance < 0.5:

        vehicle.global_position.x = target_position.x
        vehicle.global_position.z = target_position.z

        current_lane = target_lane
        is_changing_lane = false

        if is_overtaking:
            _apply_overtaking_speed()

        return

    var movement := direction.normalized()

    var step := lane_change_speed * delta

    vehicle.global_position += movement * minf(
        step,
        distance
    )


func _cancel_lane_change() -> void:

    is_changing_lane = false
    is_overtaking = false

    cooldown_timer = overtaking_cooldown


# ============================================================
# OVERTAKING
# ============================================================

func _apply_overtaking_speed() -> void:

    if not is_instance_valid(vehicle):
        return

    if vehicle.has_method("set_speed_limit"):

        vehicle.set_speed_limit(
            original_speed + overtaking_speed_bonus
        )


func _check_overtake_completion() -> void:

    if not _has_front_obstacle():

        is_overtaking = false

        if return_after_overtake:
            _return_to_original_lane()

        else:
            _finish_overtaking()


func _return_to_original_lane() -> void:

    if original_lane == current_lane:
        _finish_overtaking()
        return

    if original_lane < 0 or original_lane >= lane_markers.size():
        _finish_overtaking()
        return

    if not _is_lane_safe(original_lane):
        _finish_overtaking()
        return

    _begin_lane_change(original_lane)


func _finish_overtaking() -> void:

    is_overtaking = false
    is_changing_lane = false

    if vehicle.has_method("clear_speed_limit"):
        vehicle.clear_speed_limit()

    cooldown_timer = overtaking_cooldown


# ============================================================
# PUBLIC FUNCTIONS
# ============================================================

func get_current_lane() -> int:
    return current_lane


func is_lane_changing() -> bool:
    return is_changing_lane


func is_vehicle_overtaking() -> bool:
    return is_overtaking


func set_current_lane(lane_index: int) -> void:

    if lane_index < 0 or lane_index >= lane_markers.size():
        return

    current_lane = lane_index
    target_lane = lane_index
    original_lane = lane_index


func force_return_to_original_lane() -> void:

    if not is_instance_valid(vehicle):
        return

    is_overtaking = false
    _return_to_original_lane()
