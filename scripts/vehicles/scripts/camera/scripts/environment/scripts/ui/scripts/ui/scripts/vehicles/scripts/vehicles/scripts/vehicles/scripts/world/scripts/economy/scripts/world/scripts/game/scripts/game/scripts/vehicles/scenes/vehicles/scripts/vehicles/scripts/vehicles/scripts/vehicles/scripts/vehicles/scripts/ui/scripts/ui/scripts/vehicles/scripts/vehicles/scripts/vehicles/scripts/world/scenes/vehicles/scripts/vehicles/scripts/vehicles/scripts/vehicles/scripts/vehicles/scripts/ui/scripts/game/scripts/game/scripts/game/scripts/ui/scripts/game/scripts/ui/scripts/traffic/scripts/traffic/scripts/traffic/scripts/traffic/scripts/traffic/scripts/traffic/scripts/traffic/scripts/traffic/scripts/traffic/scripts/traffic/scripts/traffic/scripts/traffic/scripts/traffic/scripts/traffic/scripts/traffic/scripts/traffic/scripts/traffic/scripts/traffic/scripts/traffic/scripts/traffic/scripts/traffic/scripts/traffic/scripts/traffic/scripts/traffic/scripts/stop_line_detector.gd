extends Node3D
class_name StopLineDetector

signal vehicle_approaching
signal vehicle_stopped
signal vehicle_crossed

@export_group("Vehicle")
@export var vehicle: Node3D

@export_group("Stop Line")
@export var stop_line: Marker3D
@export var detection_distance := 25.0
@export var stopping_distance := 5.0

@export_group("Movement")
@export var braking_distance := 12.0
@export var movement_controller: Node

var approaching := false
var stopped := false
var crossed := false


func _physics_process(_delta):
    if not is_instance_valid(vehicle):
        return

    if not is_instance_valid(stop_line):
        return

    check_vehicle_position()


func check_vehicle_position():
    var distance = vehicle.global_position.distance_to(
        stop_line.global_position
    )

    if distance <= detection_distance and not approaching:
        approaching = true
        vehicle_approaching.emit()

    if distance <= braking_distance and not crossed:
        request_stop()

    if distance <= stopping_distance and not stopped:
        stopped = true
        vehicle_stopped.emit()

    if has_crossed_line():
        if not crossed:
            crossed = true
            vehicle_crossed.emit()


func request_stop():
    if not is_instance_valid(movement_controller):
        return

    if movement_controller.has_method("set_emergency_stop"):
        movement_controller.set_emergency_stop(true)
    elif movement_controller.has_method("set_speed_limit"):
        movement_controller.set_speed_limit(0.0)


func has_crossed_line() -> bool:
    var forward = -stop_line.global_basis.z
    var vehicle_offset = vehicle.global_position - stop_line.global_position

    return vehicle_offset.dot(forward) > 0.0


func release_vehicle():
    if is_instance_valid(movement_controller):
        if movement_controller.has_method("set_emergency_stop"):
            movement_controller.set_emergency_stop(false)
        elif movement_controller.has_method("clear_speed_limit"):
            movement_controller.clear_speed_limit()

    approaching = false
    stopped = false
    crossed = false


func reset_detector():
    approaching = false
    stopped = false
    crossed = false


func is_stopped() -> bool:
    return stopped


func is_approaching() -> bool:
    return approaching


func has_crossed() -> bool:
    return crossed
