extends VehicleWheel3D
class_name TowTruckWheel

@export_group("Wheel Configuration")
@export var front_wheel: bool = false
@export var wheel_radius: float = 0.55
@export var wheel_width: float = 0.35

@export_group("Suspension")
@export var suspension_travel: float = 0.25
@export var suspension_stiffness: float = 25.0
@export var suspension_damping_compression: float = 4.0
@export var suspension_damping_relaxation: float = 5.0

@export_group("Grip")
@export var wheel_friction: float = 3.5
@export var traction_enabled: bool = true


func _ready() -> void:
    wheel_radius = maxf(wheel_radius, 0.1)

    use_as_steering = front_wheel
    use_as_traction = traction_enabled

    wheel_rest_length = 0.3
    suspension_travel = maxf(suspension_travel, 0.05)
    suspension_stiffness = maxf(suspension_stiffness, 1.0)

    suspension_max_force = 100000.0

    wheel_friction_slip = wheel_friction

    wheel_roll_influence = 0.08
    damping_compression = suspension_damping_compression
    damping_relaxation = suspension_damping_relaxation
