extends Node
class_name TrailerBrakeSystem

signal brake_applied(brake_strength: float)
signal abs_activated
signal emergency_brake_activated

@export_group("Brake Settings")
@export var maximum_brake_force: float = 18000.0
@export var service_brake_strength: float = 0.7
@export var emergency_brake_strength: float = 1.0

@export_group("ABS Settings")
@export var abs_enabled: bool = true
@export var wheel_lock_threshold: float = 0.85
@export var abs_release_strength: float = 0.55

@export_group("Trailer")
@export var trailer: RigidBody3D

var brake_input: float = 0.0
var emergency_brake: bool = false
var abs_active: bool = false

var wheel_nodes: Array[TrailerWheel] = []


func _ready() -> void:
    add_to_group("trailer_brake_system")
    _find_trailer()
    _find_wheels()


func _find_trailer() -> void:
    if is_instance_valid(trailer):
        return

    var trailers := get_tree().get_nodes_in_group("trailer")

    if not trailers.is_empty():
        trailer = trailers[0] as RigidBody3D


func _find_wheels() -> void:
    wheel_nodes.clear()

    if not is_instance_valid(trailer):
        return

    for child in trailer.get_children():
        _collect_wheels(child)


func _collect_wheels(node: Node) -> void:
    if node is TrailerWheel:
        wheel_nodes.append(node as TrailerWheel)

    for child in node.get_children():
        _collect_wheels(child)


func _physics_process(_delta: float) -> void:

    if not is_instance_valid(trailer):
        _find_trailer()
        return

    if not emergency_brake and brake_input <= 0.0:
        abs_active = false
        return

    var strength := brake_input

    if emergency_brake:
        strength = emergency_brake_strength

    _apply_brakes(strength)


# ============================================================
# APPLY BRAKES
# ============================================================

func _apply_brakes(strength: float) -> void:

    strength = clampf(strength, 0.0, 1.0)

    var final_strength := strength

    if abs_enabled and _should_activate_abs():
        final_strength *= abs_release_strength

        if not abs_active:
            abs_activated.emit()

        abs_active = true
    else:
        abs_active = false

    var brake_force := maximum_brake_force * final_strength

    var velocity := trailer.linear_velocity

    if velocity.length_squared() > 0.01:
        var braking_direction := -velocity.normalized()

        trailer.apply_central_force(
            braking_direction * brake_force
        )

    brake_applied.emit(final_strength)


# ============================================================
# ABS
# ============================================================

func _should_activate_abs() -> bool:

    if wheel_nodes.is_empty():
        return false

    var speed := trailer.linear_velocity.length()

    if speed < 1.0:
        return false

    var grounded_count := 0

    for wheel in wheel_nodes:
        if wheel.is_wheel_grounded():
            grounded_count += 1

    if grounded_count == 0:
        return false

    var braking_ratio := (
        brake_input * wheel_lock_threshold
    )

    return braking_ratio >= wheel_lock_threshold


# ============================================================
# DRIVER CONTROLS
# ============================================================

func set_brake_input(value: float) -> void:
    brake_input = clampf(value, 0.0, 1.0)


func activate_emergency_brake() -> void:
    emergency_brake = true
    emergency_brake_activated.emit()


func release_emergency_brake() -> void:
    emergency_brake = false


func release_brakes() -> void:
    brake_input = 0.0
    emergency_brake = false
    abs_active = false


# ============================================================
# INFORMATION
# ============================================================

func is_abs_active() -> bool:
    return abs_active


func is_emergency_brake_active() -> bool:
    return emergency_brake


func get_brake_percentage() -> float:
    if emergency_brake:
        return 100.0

    return brake_input * 100.0
