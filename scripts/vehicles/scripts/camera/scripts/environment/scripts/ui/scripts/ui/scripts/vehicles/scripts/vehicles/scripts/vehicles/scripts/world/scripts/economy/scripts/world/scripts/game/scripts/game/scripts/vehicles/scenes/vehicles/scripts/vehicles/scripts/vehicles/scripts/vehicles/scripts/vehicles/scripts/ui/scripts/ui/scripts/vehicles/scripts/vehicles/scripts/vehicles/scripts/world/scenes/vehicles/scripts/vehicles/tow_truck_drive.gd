extends VehicleBody3D
class_name TowTruckDrive

@export_group("Engine")
@export var max_engine_force: float = 3500.0
@export var max_brake_force: float = 100.0
@export var max_speed_kmh: float = 100.0
@export var reverse_speed_kmh: float = 25.0

@export_group("Steering")
@export var max_steering_angle: float = 0.45
@export var steering_speed: float = 2.5
@export var steering_return_speed: float = 3.5

@export_group("Handling")
@export var engine_braking: float = 3.0
@export var handbrake_force: float = 180.0

var steering_input: float = 0.0
var throttle_input: float = 0.0
var brake_input: float = 0.0

var current_speed_kmh: float = 0.0
var handbrake_active: bool = false
var engine_on: bool = true


func _ready() -> void:
    add_to_group("tow_truck")
    mass = 9000.0
    max_contacts_reported = 8
    contact_monitor = true


func _physics_process(delta: float) -> void:
    current_speed_kmh = linear_velocity.length() * 3.6

    _read_input(delta)
    _apply_engine()
    _apply_steering(delta)
    _apply_brakes()


func _read_input(delta: float) -> void:
    throttle_input = Input.get_action_strength("accelerate")
    brake_input = Input.get_action_strength("brake")

    if Input.is_action_pressed("steer_left"):
        steering_input = move_toward(
            steering_input,
            -1.0,
            steering_speed * delta
        )
    elif Input.is_action_pressed("steer_right"):
        steering_input = move_toward(
            steering_input,
            1.0,
            steering_speed * delta
        )
    else:
        steering_input = move_toward(
            steering_input,
            0.0,
            steering_return_speed * delta
        )

    handbrake_active = Input.is_action_pressed("handbrake")


func _apply_engine() -> void:
    engine_force = 0.0

    if not engine_on:
        return

    var forward_speed := linear_velocity.dot(
        -global_transform.basis.z
    ) * 3.6

    if throttle_input > 0.0:
        if forward_speed < max_speed_kmh:
            engine_force = max_engine_force * throttle_input

    elif brake_input > 0.0:
        if forward_speed > 1.0:
            engine_force = 0.0
        elif forward_speed <= 1.0:
            engine_force = -max_engine_force * 0.35 * brake_input


func _apply_steering(delta: float) -> void:
    steering = move_toward(
        steering,
        steering_input * max_steering_angle,
        steering_speed * delta
    )


func _apply_brakes() -> void:
    brake = 0.0

    if brake_input > 0.0:
        brake = max_brake_force * brake_input

    if handbrake_active:
        brake = handbrake_force


func get_speed_kmh() -> float:
    return current_speed_kmh


func set_engine_state(enabled: bool) -> void:
    engine_on = enabled


func toggle_engine() -> void:
    engine_on = not engine_on


func is_engine_running() -> bool:
    return engine_on
