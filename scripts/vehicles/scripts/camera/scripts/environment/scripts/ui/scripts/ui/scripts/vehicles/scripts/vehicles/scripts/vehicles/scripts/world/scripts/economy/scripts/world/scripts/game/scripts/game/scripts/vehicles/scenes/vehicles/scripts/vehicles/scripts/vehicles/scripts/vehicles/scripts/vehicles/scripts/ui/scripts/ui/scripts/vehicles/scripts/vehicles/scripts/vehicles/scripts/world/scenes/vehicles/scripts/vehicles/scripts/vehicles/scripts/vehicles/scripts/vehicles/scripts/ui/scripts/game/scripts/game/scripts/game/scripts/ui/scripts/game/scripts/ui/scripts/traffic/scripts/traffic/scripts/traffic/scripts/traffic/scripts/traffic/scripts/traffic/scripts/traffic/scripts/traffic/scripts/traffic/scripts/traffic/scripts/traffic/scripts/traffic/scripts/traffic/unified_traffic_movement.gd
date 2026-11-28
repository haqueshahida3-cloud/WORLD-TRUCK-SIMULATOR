extends CharacterBody3D
class_name UnifiedTrafficMovement

signal vehicle_stopped
signal vehicle_started
signal speed_changed(speed_kmh: float)
signal waypoint_reached(index: int)

@export_group("Movement")
@export var maximum_speed_kmh: float = 60.0
@export var acceleration: float = 3.5
@export var braking: float = 8.0
@export var steering_speed: float = 3.0
@export var gravity: float = 9.8

@export_group("Route")
@export var waypoints: Array[Node3D] = []
@export var waypoint_distance: float = 5.0
@export var loop_route: bool = true

@export_group("Safety")
@export var safe_distance: float = 12.0
@export var detection_distance: float = 30.0
@export var emergency_braking_distance: float = 7.0

@export_group("Control")
@export var ai_enabled: bool = true
@export var traffic_light_green: bool = true
@export var intersection_permission: bool = true
@export var emergency_stop: bool = false

var current_waypoint: int = 0

var current_speed: float = 0.0
var desired_speed: float = 0.0

var speed_limit_kmh: float = 60.0
var external_speed_limit: float = INF

var obstacle_detected: bool = false
var obstacle_distance: float = INF

var was_stopped: bool = false


func _ready() -> void:

    add_to_group("traffic_vehicles")

    speed_limit_kmh = maximum_speed_kmh

    desired_speed = maximum_speed_kmh / 3.6


func _physics_process(delta: float) -> void:

    if not ai_enabled:
        _stop_vehicle(delta)
        _apply_gravity(delta)
        move_and_slide()
        return

    if emergency_stop:
        _stop_vehicle(delta)
        _apply_gravity(delta)
        move_and_slide()
        return

    if waypoints.is_empty():
        _stop_vehicle(delta)
        _apply_gravity(delta)
        move_and_slide()
        return

    _update_waypoint()
    _detect_obstacles()
    _calculate_desired_speed()
    _update_speed(delta)
    _steer_to_waypoint(delta)
    _apply_movement()
    _apply_gravity(delta)

    move_and_slide()


# ============================================================
# WAYPOINT MANAGEMENT
# ============================================================

func _update_waypoint() -> void:

    if current_waypoint >= waypoints.size():
        current_waypoint = 0

    var point := waypoints[current_waypoint]

    if not is_instance_valid(point):
        return

    var distance := global_position.distance_to(
        point.global_position
    )

    if distance <= waypoint_distance:

        waypoint_reached.emit(current_waypoint)

        current_waypoint += 1

        if current_waypoint >= waypoints.size():

            if loop_route:
                current_waypoint = 0
            else:
                current_waypoint = waypoints.size() - 1
                desired_speed = 0.0


# ============================================================
# OBSTACLE DETECTION
# ============================================================

func _detect_obstacles() -> void:

    obstacle_detected = false
    obstacle_distance = INF

    var forward := -global_transform.basis.z

    var origin := global_position + Vector3(
        0.0,
        1.0,
        0.0
    )

    var destination := origin + (
        forward * detection_distance
    )

    var query := PhysicsRayQueryParameters3D.create(
        origin,
        destination
    )

    query.exclude = [get_rid()]

    var result := get_world_3d().direct_space_state.intersect_ray(
        query
    )

    if result.is_empty():
        return

    var collider: Object = result.get("collider")

    if collider is UnifiedTrafficMovement:
        obstacle_detected = true

        obstacle_distance = origin.distance_to(
            result.get("position")
        )

    elif collider is TrafficVehicleAI:
        obstacle_detected = true

        obstacle_distance = origin.distance_to(
            result.get("position")
        )


# ============================================================
# SPEED CALCULATION
# ============================================================

func _calculate_desired_speed() -> void:

    var allowed_speed := minf(
        maximum_speed_kmh,
        speed_limit_kmh
    )

    allowed_speed = minf(
        allowed_speed,
        external_speed_limit
    )

    if not traffic_light_green:
        allowed_speed = 0.0

    if not intersection_permission:
        allowed_speed = 0.0

    if obstacle_detected:

        if obstacle_distance <= emergency_braking_distance:
            allowed_speed = 0.0

        elif obstacle_distance < safe_distance:

            allowed_speed *= clampf(
                obstacle_distance / safe_distance,
                0.0,
                1.0
            )

    desired_speed = allowed_speed / 3.6


# ============================================================
# SPEED UPDATE
# ============================================================

func _update_speed(delta: float) -> void:

    var old_speed := current_speed

    if desired_speed > current_speed:

        current_speed = move_toward(
            current_speed,
            desired_speed,
            acceleration * delta
        )

    else:

        current_speed = move_toward(
            current_speed,
            desired_speed,
            braking * delta
        )

    current_speed = maxf(current_speed, 0.0)

    if absf(old_speed - current_speed) > 0.1:
        speed_changed.emit(current_speed * 3.6)

    _update_stop_state()


func _stop_vehicle(delta: float) -> void:

    current_speed = move_toward(
        current_speed,
        0.0,
        braking * delta
    )

    desired_speed = 0.0

    _update_stop_state()


func _update_stop_state() -> void:

    var stopped := current_speed < 0.1

    if stopped and not was_stopped:
        vehicle_stopped.emit()

    elif not stopped and was_stopped:
        vehicle_started.emit()

    was_stopped = stopped


# ============================================================
# STEERING
# ============================================================

func _steer_to_waypoint(delta: float) -> void:

    if waypoints.is_empty():
        return

    var point := waypoints[current_waypoint]

    if not is_instance_valid(point):
        return

    var direction := (
        point.global_position - global_position
    )

    direction.y = 0.0

    if direction.length_squared() < 0.01:
        return

    direction = direction.normalized()

    var target_angle := atan2(
        -direction.x,
        -direction.z
    )

    rotation.y = lerp_angle(
        rotation.y,
        target_angle,
        steering_speed * delta
    )


# ============================================================
# MOVEMENT
# ============================================================

func _apply_movement() -> void:

    var forward := -global_transform.basis.z

    velocity.x = forward.x * current_speed
    velocity.z = forward.z * current_speed


func _apply_gravity(delta: float) -> void:

    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = 0.0


# ============================================================
# EXTERNAL AI INTERFACE
# ============================================================

func set_speed_limit(speed_kmh: float) -> void:
    external_speed_limit = maxf(speed_kmh, 0.0)


func clear_speed_limit() -> void:
    external_speed_limit = INF


func set_traffic_light_state(is_green: bool) -> void:
    traffic_light_green = is_green


func set_intersection_permission(allowed: bool) -> void:
    intersection_permission = allowed


func set_emergency_stop(enabled: bool) -> void:
    emergency_stop = enabled


func set_ai_enabled(enabled: bool) -> void:
    ai_enabled = enabled


func get_speed_kmh() -> float:
    return current_speed * 3.6


func get_current_waypoint() -> int:
    return current_waypoint


func is_vehicle_stopped() -> bool:
    return current_speed < 0.1
