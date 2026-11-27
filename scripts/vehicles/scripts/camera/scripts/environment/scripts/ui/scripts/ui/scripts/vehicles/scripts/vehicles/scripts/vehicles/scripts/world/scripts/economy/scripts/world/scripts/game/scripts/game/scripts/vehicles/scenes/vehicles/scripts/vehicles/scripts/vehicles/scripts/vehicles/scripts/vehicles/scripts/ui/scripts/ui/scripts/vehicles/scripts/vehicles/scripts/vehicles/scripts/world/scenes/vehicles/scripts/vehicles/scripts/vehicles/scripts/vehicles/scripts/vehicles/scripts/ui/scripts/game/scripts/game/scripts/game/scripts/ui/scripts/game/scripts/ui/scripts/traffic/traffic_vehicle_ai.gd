extends CharacterBody3D
class_name TrafficVehicleAI

signal waypoint_reached(index: int)
signal obstacle_detected
signal vehicle_stopped
signal vehicle_started

@export_group("Traffic Settings")
@export var vehicle_type: String = "Car"
@export var max_speed_kmh: float = 60.0
@export var acceleration: float = 4.0
@export var braking: float = 9.0
@export var steering_speed: float = 2.0

@export_group("Road Navigation")
@export var waypoints: Array[Node3D] = []
@export var waypoint_distance: float = 5.0
@export var loop_route: bool = true

@export_group("Obstacle Detection")
@export var obstacle_detection_distance: float = 12.0
@export var obstacle_height: float = 1.0

@export_group("AI Control")
@export var ai_enabled: bool = true
@export var gravity: float = 9.8

var current_waypoint: int = 0
var current_speed: float = 0.0
var target_speed: float = 0.0

var obstacle_ahead: bool = false
var was_stopped: bool = false


func _ready() -> void:
    add_to_group("traffic_vehicles")

    target_speed = max_speed_kmh / 3.6

    if waypoints.is_empty():
        push_warning("Traffic AI: No waypoints assigned.")


func _physics_process(delta: float) -> void:

    if not ai_enabled:
        _apply_brakes(delta)
        _apply_gravity(delta)
        move_and_slide()
        return

    if waypoints.is_empty():
        _apply_brakes(delta)
        _apply_gravity(delta)
        move_and_slide()
        return

    _update_waypoint()

    _check_obstacles()

    _update_target_speed()

    _update_vehicle_speed(delta)

    _steer_towards_waypoint(delta)

    _apply_movement(delta)

    move_and_slide()


# ============================================================
# WAYPOINT NAVIGATION
# ============================================================

func _update_waypoint() -> void:

    if current_waypoint >= waypoints.size():
        return

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
                ai_enabled = false
                target_speed = 0.0


# ============================================================
# OBSTACLE DETECTION
# ============================================================

func _check_obstacles() -> void:

    obstacle_ahead = false

    var forward := -global_transform.basis.z

    var origin := global_position + Vector3(
        0.0,
        obstacle_height,
        0.0
    )

    var destination := origin + (
        forward * obstacle_detection_distance
    )

    var query := PhysicsRayQueryParameters3D.create(
        origin,
        destination
    )

    query.exclude = [get_rid()]

    var result := get_world_3d().direct_space_state.intersect_ray(
        query
    )

    if not result.is_empty():

        var collider: Object = result.get("collider")

        if collider != null and collider != self:
            obstacle_ahead = true
            obstacle_detected.emit()


# ============================================================
# TARGET SPEED
# ============================================================

func _update_target_speed() -> void:

    if obstacle_ahead:
        target_speed = 0.0
    else:
        target_speed = max_speed_kmh / 3.6


# ============================================================
# ACCELERATION AND BRAKING
# ============================================================

func _update_vehicle_speed(delta: float) -> void:

    var previous_speed := current_speed

    if current_speed < target_speed:

        current_speed = move_toward(
            current_speed,
            target_speed,
            acceleration * delta
        )

    elif current_speed > target_speed:

        current_speed = move_toward(
            current_speed,
            target_speed,
            braking * delta
        )

    if current_speed <= 0.05:
        current_speed = 0.0

    if current_speed == 0.0 and previous_speed > 0.0:

        if not was_stopped:
            vehicle_stopped.emit()

        was_stopped = true

    elif current_speed > 0.0:

        if was_stopped:
            vehicle_started.emit()

        was_stopped = false


# ============================================================
# STEERING
# ============================================================

func _steer_towards_waypoint(delta: float) -> void:

    if current_waypoint >= waypoints.size():
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

    var desired_yaw := atan2(
        -direction.x,
        -direction.z
    )

    global_rotation.y = lerp_angle(
        global_rotation.y,
        desired_yaw,
        steering_speed * delta
    )


# ============================================================
# PHYSICS MOVEMENT
# ============================================================

func _apply_movement(delta: float) -> void:

    var forward := -global_transform.basis.z

    velocity.x = forward.x * current_speed
    velocity.z = forward.z * current_speed

    _apply_gravity(delta)


func _apply_gravity(delta: float) -> void:

    if is_on_floor():
        velocity.y = 0.0
    else:
        velocity.y -= gravity * delta


func _apply_brakes(delta: float) -> void:

    current_speed = move_toward(
        current_speed,
        0.0,
        braking * delta
    )

    var forward := -global_transform.basis.z

    velocity.x = forward.x * current_speed
    velocity.z = forward.z * current_speed


# ============================================================
# PUBLIC FUNCTIONS
# ============================================================

func set_ai_enabled(enabled: bool) -> void:
    ai_enabled = enabled


func set_max_speed(speed_kmh: float) -> void:
    max_speed_kmh = maxf(speed_kmh, 0.0)


func set_route(new_waypoints: Array[Node3D]) -> void:

    waypoints = new_waypoints
    current_waypoint = 0
    ai_enabled = true


func get_speed_kmh() -> float:
    return current_speed * 3.6


func is_obstacle_ahead() -> bool:
    return obstacle_ahead


func get_current_waypoint() -> int:
    return current_waypoint
