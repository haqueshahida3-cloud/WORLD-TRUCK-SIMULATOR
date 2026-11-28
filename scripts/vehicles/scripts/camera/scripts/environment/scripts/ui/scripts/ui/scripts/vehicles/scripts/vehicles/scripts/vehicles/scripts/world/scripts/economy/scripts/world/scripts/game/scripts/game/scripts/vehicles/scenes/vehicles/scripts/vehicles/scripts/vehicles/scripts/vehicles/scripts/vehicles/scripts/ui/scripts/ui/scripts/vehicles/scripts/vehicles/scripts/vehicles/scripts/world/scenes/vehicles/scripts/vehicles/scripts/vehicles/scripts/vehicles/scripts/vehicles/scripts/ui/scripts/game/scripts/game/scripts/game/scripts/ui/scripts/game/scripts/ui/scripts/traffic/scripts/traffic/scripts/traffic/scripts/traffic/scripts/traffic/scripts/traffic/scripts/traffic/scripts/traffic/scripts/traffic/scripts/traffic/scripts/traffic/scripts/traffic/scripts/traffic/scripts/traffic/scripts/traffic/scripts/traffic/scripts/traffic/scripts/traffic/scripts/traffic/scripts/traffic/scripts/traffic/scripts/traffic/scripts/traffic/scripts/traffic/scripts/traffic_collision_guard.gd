extends Node
class_name TrafficCollisionGuard

signal collision_warning(distance: float)
signal emergency_braking
signal safe_distance_restored

@export_group("Vehicle")
@export var vehicle: CharacterBody3D

@export_group("Detection")
@export var detection_area: Area3D
@export var safe_distance := 10.0
@export var emergency_distance := 3.0

@export_group("Braking")
@export var braking_strength := 15.0
@export var reaction_time := 1.0

var detected_vehicles: Array[Node3D] = []
var target_speed := 0.0
var emergency_active := false


func _ready():
    if is_instance_valid(detection_area):
        detection_area.body_entered.connect(_on_body_entered)
        detection_area.body_exited.connect(_on_body_exited)


func _physics_process(delta):
    if not is_instance_valid(vehicle):
        return

    check_front_vehicle(delta)


func _on_body_entered(body: Node3D):
    if body == vehicle:
        return

    if body.is_in_group("traffic_vehicles"):
        if not detected_vehicles.has(body):
            detected_vehicles.append(body)


func _on_body_exited(body: Node3D):
    detected_vehicles.erase(body)


func check_front_vehicle(delta):
    var front = find_front_vehicle()

    if front == null:
        emergency_active = false
        safe_distance_restored.emit()
        return

    var distance = vehicle.global_position.distance_to(
        front.global_position
    )

    var relative_speed = maxf(
        vehicle.velocity.length() - front.velocity.length(),
        0.0
    )

    var braking_distance = (
        relative_speed * reaction_time
        + pow(relative_speed, 2) / (2.0 * braking_strength)
    )

    var required_distance = maxf(
        safe_distance,
        braking_distance
    )

    collision_warning.emit(distance)

    if distance <= emergency_distance or distance <= braking_distance:
        activate_emergency_braking()
    elif distance < required_distance:
        target_speed = minf(
            target_speed,
            front.velocity.length()
        )
    else:
        emergency_active = false


func find_front_vehicle() -> Node3D:
    var nearest: Node3D = null
    var nearest_distance := INF

    var forward = -vehicle.global_basis.z

    for other in detected_vehicles:
        if not is_instance_valid(other):
            continue

        var offset = other.global_position - vehicle.global_position
        var distance = offset.length()

        if forward.dot(offset.normalized()) < 0.7:
            continue

        if distance < nearest_distance:
            nearest_distance = distance
            nearest = other

    return nearest


func activate_emergency_braking():
    if not emergency_active:
        emergency_braking.emit()

    emergency_active = true
    target_speed = 0.0


func get_target_speed() -> float:
    return target_speed


func is_emergency_active() -> bool:
    return emergency_active


func reset_guard():
    emergency_active = false
    target_speed = 0.0
    detected_vehicles.clear()
