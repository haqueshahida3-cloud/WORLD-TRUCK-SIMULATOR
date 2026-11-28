extends Node
class_name TrafficCollisionAvoidance

signal obstacle_detected(obstacle: Object, distance: float)
signal emergency_braking_started
signal emergency_braking_released

@export_group("References")
@export var vehicle: TrafficVehicleAI

@export_group("Detection")
@export var detection_distance: float = 35.0
@export var detection_height: float = 1.2
@export var number_of_rays: int = 3
@export var ray_spread: float = 0.35

@export_group("Braking")
@export var warning_distance: float = 20.0
@export var emergency_distance: float = 8.0
@export var emergency_release_distance: float = 15.0
@export var braking_strength: float = 12.0

@export_group("Settings")
@export var system_enabled: bool = true
@export var ignore_static_obstacles: bool = false

var emergency_braking: bool = false
var obstacle_distance: float = INF
var detected_obstacle: Object = null
var original_speed: float = 0.0


func _ready() -> void:
    add_to_group("traffic_collision_avoidance")

    if not is_instance_valid(vehicle):
        if get_parent() is TrafficVehicleAI:
            vehicle = get_parent() as TrafficVehicleAI


func _physics_process(delta: float) -> void:

    if not system_enabled:
        _release_emergency_brake()
        return

    if not is_instance_valid(vehicle):
        return

    var result := _detect_obstacle()

    if result.is_empty():
        detected_obstacle = null
        obstacle_distance = INF
        _release_emergency_brake()
        return

    detected_obstacle = result.get("collider")
    obstacle_distance = float(result.get("distance", INF))

    obstacle_detected.emit(
        detected_obstacle,
        obstacle_distance
    )

    _apply_collision_avoidance(delta)


# ============================================================
# OBSTACLE DETECTION
# ============================================================

func _detect_obstacle() -> Dictionary:

    var forward := -vehicle.global_transform.basis.z
    var right := vehicle.global_transform.basis.x

    var origin := vehicle.global_position + Vector3(
        0.0,
        detection_height,
        0.0
    )

    var space := vehicle.get_world_3d().direct_space_state

    var directions: Array[Vector3] = [
        forward,
        (forward + right * ray_spread).normalized(),
        (forward - right * ray_spread).normalized()
    ]

    var nearest_result: Dictionary = {}
    var nearest_distance := INF

    for i in range(mini(number_of_rays, directions.size())):

        var destination := origin + (
            directions[i] * detection_distance
        )

        var query := PhysicsRayQueryParameters3D.create(
            origin,
            destination
        )

        query.exclude = [vehicle.get_rid()]

        var result := space.intersect_ray(query)

        if result.is_empty():
            continue

        var collider: Object = result.get("collider")

        if ignore_static_obstacles and collider is StaticBody3D:
            continue

        var hit_position: Vector3 = result.get("position")

        var distance := origin.distance_to(hit_position)

        if distance < nearest_distance:

            nearest_distance = distance
            nearest_result = result

            nearest_result["distance"] = distance

    return nearest_result


# ============================================================
# COLLISION AVOIDANCE
# ============================================================

func _apply_collision_avoidance(delta: float) -> void:

    if obstacle_distance <= emergency_distance:

        _activate_emergency_brake()
        vehicle.target_speed = 0.0

    elif obstacle_distance <= warning_distance:

        _release_emergency_brake()

        var safe_speed := (
            obstacle_distance - emergency_distance
        ) / maxf(
            warning_distance - emergency_distance,
            0.1
        )

        safe_speed = clampf(safe_speed, 0.0, 1.0)

        var allowed_speed := (
            vehicle.max_speed_kmh / 3.6
        ) * safe_speed

        vehicle.target_speed = minf(
            vehicle.target_speed,
            allowed_speed
        )

    else:

        if emergency_braking:
            if obstacle_distance >= emergency_release_distance:
                _release_emergency_brake()


# ============================================================
# EMERGENCY BRAKING
# ============================================================

func _activate_emergency_brake() -> void:

    if emergency_braking:
        return

    emergency_braking = true

    original_speed = vehicle.max_speed_kmh

    emergency_braking_started.emit()


func _release_emergency_brake() -> void:

    if not emergency_braking:
        return

    emergency_braking = false

    emergency_braking_released.emit()


# ============================================================
# PUBLIC FUNCTIONS
# ============================================================

func is_emergency_braking() -> bool:
    return emergency_braking


func get_obstacle_distance() -> float:
    return obstacle_distance


func get_detected_obstacle() -> Object:
    return detected_obstacle


func enable_system() -> void:
    system_enabled = true


func disable_system() -> void:
    system_enabled = false
    _release_emergency_brake()
