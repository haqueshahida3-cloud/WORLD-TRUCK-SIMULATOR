extends Node3D
class_name TrafficSignalDetector

@export_group("Vehicle")
@export var vehicle: CharacterBody3D
@export var vehicle_speed := 12.0

@export_group("Traffic Signal")
@export var traffic_light: JunctionTrafficLightSystem
@export var direction := "north"

@export_group("Detection")
@export var detection_distance := 35.0
@export var stop_distance := 7.0
@export var acceleration := 8.0
@export var braking := 18.0

var current_speed := 0.0
var must_stop := false
var signal_state := 0


func _physics_process(delta):
    if not is_instance_valid(vehicle):
        return

    if not is_instance_valid(traffic_light):
        return

    check_signal()
    control_vehicle(delta)


func check_signal():
    if not traffic_light.lights.has(direction):
        must_stop = true
        return

    signal_state = get_direction_state()

    var distance = detection_distance

    if signal_state == 0:
        must_stop = true
    elif signal_state == 1:
        must_stop = true
    else:
        must_stop = false

    var speed = vehicle.velocity.length()

    if speed > 0.1:
        distance = minf(detection_distance, speed * 2.0)

    if distance < stop_distance:
        must_stop = true


func get_direction_state() -> int:
    var group = traffic_light.lights[direction]

    for i in 3:
        if group[i].material_override == traffic_light.materials[
            ["red", "yellow", "green"][i]
        ]:
            return i

    return 0


func control_vehicle(delta):
    if must_stop:
        current_speed = move_toward(
            current_speed,
            0.0,
            braking * delta
        )
    else:
        current_speed = move_toward(
            current_speed,
            vehicle_speed,
            acceleration * delta
        )


func get_target_speed() -> float:
    return current_speed


func is_vehicle_stopped() -> bool:
    return current_speed <= 0.1


func set_vehicle_speed(value: float):
    vehicle_speed = maxf(value, 0.0)


func set_signal_direction(value: String):
    direction = value


func emergency_stop():
    must_stop = true
    current_speed = 0.0


func resume_vehicle():
    must_stop = false
