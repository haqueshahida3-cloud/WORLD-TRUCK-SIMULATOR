extends RayCast3D
class_name TrailerWheel

@export_group("Wheel Settings")
@export var wheel_radius: float = 0.48
@export var suspension_length: float = 0.45
@export var suspension_stiffness: float = 35000.0
@export var suspension_damping: float = 4500.0

@export_group("Wheel Physics")
@export var wheel_grip: float = 1.2
@export var rolling_resistance: float = 0.015

@export_group("Visual")
@export var wheel_mesh: MeshInstance3D
@export var rotation_speed: float = 1.0

var trailer: RigidBody3D
var previous_suspension_length: float = 0.0
var wheel_rotation: float = 0.0


func _ready() -> void:
    trailer = get_parent() as RigidBody3D

    target_position = Vector3(
        0.0,
        -(wheel_radius + suspension_length),
        0.0
    )

    enabled = true
    previous_suspension_length = suspension_length


func _physics_process(delta: float) -> void:

    if not is_instance_valid(trailer):
        return

    force_raycast_update()

    if not is_colliding():
        return

    var hit_point := get_collision_point()
    var hit_normal := get_collision_normal()

    var distance := global_position.distance_to(hit_point)
    var compression := (
        wheel_radius + suspension_length - distance
    )

    var compression_ratio := clampf(
        compression / suspension_length,
        0.0,
        1.0
    )

    var suspension_velocity := (
        previous_suspension_length - compression
    ) / maxf(delta, 0.001)

    previous_suspension_length = compression

    var suspension_force := (
        compression * suspension_stiffness
        + suspension_velocity * suspension_damping
    )

    suspension_force = maxf(suspension_force, 0.0)

    var force := hit_normal * suspension_force

    trailer.apply_force(
        force,
        hit_point - trailer.global_position
    )

    _update_wheel_rotation(delta)


func _update_wheel_rotation(delta: float) -> void:

    if not is_instance_valid(wheel_mesh):
        return

    var speed := trailer.linear_velocity.length()

    wheel_rotation += (
        speed * delta / maxf(wheel_radius, 0.01)
    ) * rotation_speed

    wheel_mesh.rotation.x = wheel_rotation


func get_suspension_compression() -> float:
    return previous_suspension_length


func is_wheel_grounded() -> bool:
    return is_colliding()
