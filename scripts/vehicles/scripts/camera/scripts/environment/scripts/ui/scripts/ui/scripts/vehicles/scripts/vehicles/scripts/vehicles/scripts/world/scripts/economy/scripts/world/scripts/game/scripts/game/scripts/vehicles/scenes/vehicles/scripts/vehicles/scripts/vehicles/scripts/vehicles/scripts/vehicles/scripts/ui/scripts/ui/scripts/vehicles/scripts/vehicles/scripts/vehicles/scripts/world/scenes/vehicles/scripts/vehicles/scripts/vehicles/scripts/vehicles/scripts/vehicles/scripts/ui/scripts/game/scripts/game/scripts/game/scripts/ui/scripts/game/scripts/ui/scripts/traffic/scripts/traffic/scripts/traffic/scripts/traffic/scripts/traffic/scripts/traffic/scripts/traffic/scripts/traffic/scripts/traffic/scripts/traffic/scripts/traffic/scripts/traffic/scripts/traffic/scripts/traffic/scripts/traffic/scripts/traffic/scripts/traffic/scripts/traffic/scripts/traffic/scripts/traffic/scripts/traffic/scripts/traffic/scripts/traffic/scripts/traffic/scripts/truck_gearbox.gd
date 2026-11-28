extends Node
class_name TruckGearbox

signal gear_changed(new_gear: int)
signal engine_rpm_changed(rpm: float)

@export_group("Truck")
@export var truck: VehicleBody3D

@export_group("Engine")
@export var max_rpm := 3000.0
@export var idle_rpm := 700.0
@export var max_engine_force := 2500.0

@export_group("Transmission")
@export var automatic := true
@export var gear_ratios: Array[float] = [
    3.5, 2.2, 1.5, 1.1, 0.85, 0.65
]
@export var shift_speeds: Array[float] = [
    15.0, 30.0, 50.0, 70.0, 90.0
]

var current_gear := 1
var engine_rpm := 700.0
var throttle := 0.0
var brake_input := 0.0
var reverse := false


func _physics_process(delta):
    if not is_instance_valid(truck):
        return

    var speed := truck.linear_velocity.length() * 3.6

    if automatic:
        update_gear(speed)

    update_engine(speed, delta)
    apply_controls()


func set_controls(acceleration: float, braking: float):
    throttle = clampf(acceleration, 0.0, 1.0)
    brake_input = clampf(braking, 0.0, 1.0)


func set_reverse(enabled: bool):
    reverse = enabled
    if enabled:
        throttle = 0.0


func update_gear(speed: float):
    if reverse:
        return

    var next_gear := current_gear

    if current_gear < gear_ratios.size():
        if current_gear <= shift_speeds.size():
            if speed >= shift_speeds[current_gear - 1]:
                next_gear += 1

    if current_gear > 1:
        if speed < shift_speeds[current_gear - 2] * 0.65:
            next_gear -= 1

    if next_gear != current_gear:
        current_gear = clampi(
            next_gear, 1, gear_ratios.size()
        )
        gear_changed.emit(current_gear)


func update_engine(speed: float, delta: float):
    if reverse:
        engine_rpm = lerpf(
            engine_rpm, 1500.0 + throttle * 1000.0,
            delta * 4.0
        )
    else:
        var ratio: float = gear_ratios[current_gear - 1]
        var target_rpm := idle_rpm + speed * ratio * 18.0
        target_rpm = clampf(
            target_rpm, idle_rpm, max_rpm
        )

        if throttle > 0.05:
            target_rpm = maxf(
                target_rpm,
                idle_rpm + throttle * 800.0
            )

        engine_rpm = lerpf(
            engine_rpm, target_rpm, delta * 3.0
        )

    engine_rpm_changed.emit(engine_rpm)


func apply_controls():
    var force := throttle * max_engine_force

    if reverse:
        truck.engine_force = -force
    else:
        truck.engine_force = force

    truck.brake = brake_input * 80.0


func get_current_gear() -> String:
    return "R" if reverse else str(current_gear)


func get_engine_rpm() -> float:
    return engine_rpm


func reset_transmission():
    current_gear = 1
    engine_rpm = idle_rpm
    throttle = 0.0
    brake_input = 0.0
    reverse = false
