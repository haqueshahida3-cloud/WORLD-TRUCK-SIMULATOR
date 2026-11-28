extends VehicleBody3D
class_name TruckSuspension

@export_group("Suspension")
@export var front_rest_length := 0.25
@export var rear_rest_length := 0.30
@export var front_stiffness := 25.0
@export var rear_stiffness := 30.0
@export var front_damping := 4.0
@export var rear_damping := 5.0

@export_group("Wheel References")
@export var front_left: VehicleWheel3D
@export var front_right: VehicleWheel3D
@export var rear_left: VehicleWheel3D
@export var rear_right: VehicleWheel3D


func _ready():
    configure_suspension()


func configure_suspension():
    configure_wheel(
        front_left,
        front_rest_length,
        front_stiffness,
        front_damping
    )

    configure_wheel(
        front_right,
        front_rest_length,
        front_stiffness,
        front_damping
    )

    configure_wheel(
        rear_left,
        rear_rest_length,
        rear_stiffness,
        rear_damping
    )

    configure_wheel(
        rear_right,
        rear_rest_length,
        rear_stiffness,
        rear_damping
    )


func configure_wheel(
    wheel: VehicleWheel3D,
    rest_length: float,
    stiffness: float,
    damping: float
):
    if not is_instance_valid(wheel):
        return

    wheel.wheel_rest_length = rest_length
    wheel.suspension_stiffness = stiffness
    wheel.damping_compression = damping
    wheel.damping_relaxation = damping * 1.2


func set_suspension_stiffness(value: float):
    front_stiffness = clampf(value, 5.0, 60.0)
    rear_stiffness = front_stiffness * 1.2
    configure_suspension()


func set_suspension_damping(value: float):
    front_damping = clampf(value, 1.0, 15.0)
    rear_damping = front_damping * 1.2
    configure_suspension()


func set_heavy_load(enabled: bool):
    if enabled:
        rear_rest_length = 0.25
        rear_stiffness = 38.0
        rear_damping = 6.0
    else:
        rear_rest_length = 0.30
        rear_stiffness = 30.0
        rear_damping = 5.0

    configure_suspension()
