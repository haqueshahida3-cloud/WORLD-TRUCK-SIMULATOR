extends Node
class_name VehicleOvertakingAI

signal overtaking_started(target: Node3D)
signal overtaking_completed
signal overtaking_cancelled

@export_group("References")
@export var vehicle: TrafficVehicleAI
@export var lane_system: LaneFollowingAI

@export_group("Safe Distance")
@export var minimum_safe_distance: float = 12.0
@export var following_distance: float = 25.0
@export var detection_distance: float = 45.0

@export_group("Overtaking Settings")
@export var allow_overtaking: bool = true
@export var overtaking_speed_bonus: float = 15.0
@export var overtaking_duration: float = 5.0
@export var overtaking_cooldown: float = 4.0

@export_group("Detection")
@export var detection_height: float = 1.0
@export var lane_check_distance: float = 20.0

var target_vehicle: Node3D
var overtaking: bool = false
var cooldown_timer: float = 0.0
var overtaking_timer: float = 0.0
var original_speed: float = 0.0


func _ready() -> void:

    add_to_group("vehicle_overtaking_ai")

    _find_references()


func _physics_process(delta: float) -> void:

    _find_references()

    cooldown_timer = maxf(
        cooldown_timer - delta,
        0.0
    )

    if overtaking:
        _update_overtaking(delta)
        return

    if not is_instance_valid(vehicle):
        return

    var detected := _find_vehicle_ahead()

    if is_instance_valid(detected):

        target_vehicle = detected

        var distance := vehicle.global_position.distance_to(
            target_vehicle.global_position
        )

        if distance < following_distance:
            _maintain_safe_distance()

        if (
            allow_overtaking
            and cooldown_timer <= 0.0
            and distance > minimum_safe_distance
        ):
            _try_overtake()


# ============================================================
# FIND REFERENCES
# ============================================================

func _find_references() -> void:

    if not is_instance_valid(vehicle):

        var parent := get_parent()

        if parent is TrafficVehicleAI:
            vehicle = parent

    if not is_instance_valid(lane_system):

        for node in get_tree().get_nodes_in_group(
            "lane_following_system"
        ):

            if node is LaneFollowingAI:
                if node.vehicle == vehicle:
                    lane_system = node
                    break


# ============================================================
# FIND VEHICLE AHEAD
# ============================================================

func _find_vehicle_ahead() -> Node3D:

    if not is_instance_valid(vehicle):
        return null

    var forward := -vehicle.global_transform.basis.z

    var origin := vehicle.global_position + Vector3(
        0.0,
        detection_height,
        0.0
    )

    var destination := origin + (
        forward * detection_distance
    )

    var query := PhysicsRayQueryParameters3D.create(
        origin,
        destination
    )

    query.exclude = [vehicle.get_rid()]

    var result := vehicle.get_world_3d().direct_space_state.intersect_ray(
        query
    )

    if result.is_empty():
        return null

    var collider: Object = result.get("collider")

    if collider is TrafficVehicleAI:
        return collider as TrafficVehicleAI

    return null


# ============================================================
# MAINTAIN SAFE DISTANCE
# ============================================================

func _maintain_safe_distance() -> void:

    if not is_instance_valid(vehicle):
        return

    if not is_instance_valid(target_vehicle):
        return

    var distance := vehicle.global_position.distance_to(
        target_vehicle.global_position
    )

    if distance < minimum_safe_distance:

        vehicle.target_speed = 0.0

    elif distance < following_distance:

        var target_speed := 0.0

        if target_vehicle is TrafficVehicleAI:
            target_speed = target_vehicle.current_speed

        vehicle.target_speed = minf(
            vehicle.target_speed,
            target_speed
        )


# ============================================================
# CHECK OVERTAKING POSSIBILITY
# ============================================================

func _try_overtake() -> void:

    if not is_instance_valid(lane_system):
        return

    if lane_system.is_changing_lane():
        return

    if lane_system.current_lane < 0:
        return

    if lane_system.current_lane >= lane_system.lane_points.size():
        return

    var current_index := lane_system.current_lane

    # Check right lane first
    var right_lane := current_index + 1

    if _is_lane_available(right_lane):

        if lane_system.change_lane(right_lane):
            _start_overtaking()
            return

    # Then check left lane
    var left_lane := current_index - 1

    if _is_lane_available(left_lane):

        if lane_system.change_lane(left_lane):
            _start_overtaking()


# ============================================================
# CHECK LANE AVAILABILITY
# ============================================================

func _is_lane_available(lane_index: int) -> bool:

    if not is_instance_valid(lane_system):
        return false

    if lane_index < 0:
        return false

    if lane_index >= lane_system.lane_points.size():
        return false

    var lane_point := lane_system.lane_points[lane_index]

    if not is_instance_valid(lane_point):
        return false

    var nearby_vehicles := get_tree().get_nodes_in_group(
        "traffic_vehicles"
    )

    for other in nearby_vehicles:

        if other == vehicle:
            continue

        if not other is TrafficVehicleAI:
            continue

        var distance := other.global_position.distance_to(
            lane_point.global_position
        )

        if distance < lane_check_distance:
            return false

    return true


# ============================================================
# START OVERTAKING
# ============================================================

func _start_overtaking() -> void:

    if not is_instance_valid(vehicle):
        return

    original_speed = vehicle.max_speed_kmh

    vehicle.set_max_speed(
        original_speed + overtaking_speed_bonus
    )

    overtaking_timer = 0.0
    overtaking = true

    overtaking_started.emit(target_vehicle)


# ============================================================
# UPDATE OVERTAKING
# ============================================================

func _update_overtaking(delta: float) -> void:

    if not is_instance_valid(vehicle):
        _cancel_overtaking()
        return

    overtaking_timer += delta

    if not is_instance_valid(target_vehicle):
        _finish_overtaking()
        return

    var distance := vehicle.global_position.distance_to(
        target_vehicle.global_position
    )

    if distance > following_distance + 15.0:
        _finish_overtaking()
        return

    if overtaking_timer >= overtaking_duration:
        _cancel_overtaking()


# ============================================================
# FINISH OVERTAKING
# ============================================================

func _finish_overtaking() -> void:

    if is_instance_valid(vehicle):
        vehicle.set_max_speed(original_speed)

    overtaking = false
    cooldown_timer = overtaking_cooldown

    if is_instance_valid(lane_system):
        lane_system.return_to_current_lane()

    overtaking_completed.emit()


func _cancel_overtaking() -> void:

    if is_instance_valid(vehicle):
        vehicle.set_max_speed(original_speed)

    overtaking = false
    cooldown_timer = overtaking_cooldown

    overtaking_cancelled.emit()


# ============================================================
# INFORMATION
# ============================================================

func is_overtaking() -> bool:
    return overtaking


func get_target_vehicle() -> Node3D:
    return target_vehicle
