extends Camera3D
class_name ChaseCamera

## Haul Master Truck Simulator
## Smooth third-person camera controller for Godot 4.3+

# ============================================================
# TARGET
# ============================================================

@export_group("Target")
@export var target: Node3D

@export_group("Camera Position")
@export var offset: Vector3 = Vector3(0.0, 4.0, 11.0)
@export var look_height: float = 1.5
@export var follow_speed: float = 5.0
@export var rotation_speed: float = 4.0

# ============================================================
# DYNAMIC CAMERA
# ============================================================

@export_group("Dynamic Camera")
@export var speed_zoom: float = 0.12
@export var min_fov: float = 65.0
@export var max_fov: float = 82.0
@export var acceleration_effect: float = 0.15

# ============================================================
# CAMERA COLLISION
# ============================================================

@export_group("Collision")
@export var collision_enabled: bool = true
@export var collision_radius: float = 0.3
@export var collision_margin: float = 0.25
@export_flags_3d_physics var collision_mask: int = 1

# ============================================================
# CAMERA SHAKE
# ============================================================

@export_group("Camera Shake")
@export var shake_enabled: bool = true
@export var shake_intensity: float = 0.025
@export var shake_speed: float = 12.0

# ============================================================
# INTERNAL STATE
# ============================================================

var base_fov: float = 75.0
var shake_time: float = 0.0
var shake_amount: float = 0.0
var previous_speed: float = 0.0

var _target_position: Vector3
var _look_position: Vector3


func _ready() -> void:
    base_fov = fov

    if target == null:
        var trucks := get_tree().get_nodes_in_group("player")
        if not trucks.is_empty():
            target = trucks[0] as Node3D

    if target != null:
        _target_position = global_position


# ============================================================
# PHYSICS UPDATE
# ============================================================

func _physics_process(delta: float) -> void:

    if not is_instance_valid(target):
        return

    _update_camera_position(delta)
    _update_camera_rotation(delta)
    _update_dynamic_fov(delta)
    _update_camera_shake(delta)


# ============================================================
# CAMERA POSITION
# ============================================================

func _update_camera_position(delta: float) -> void:

    var target_basis := target.global_transform.basis
    var desired_position := target.global_position + target_basis * offset

    if collision_enabled:
        desired_position = _check_camera_collision(
            target.global_position,
            desired_position
        )

    var weight := 1.0 - exp(-follow_speed * delta)

    _target_position = _target_position.lerp(
        desired_position,
        weight
    )

    global_position = _target_position


# ============================================================
# CAMERA ROTATION
# ============================================================

func _update_camera_rotation(delta: float) -> void:

    var desired_look := (
        target.global_position +
        Vector3.UP * look_height
    )

    var direction := desired_look - global_position

    if direction.length_squared() < 0.001:
        return

    var desired_basis := Basis.looking_at(
        -direction.normalized(),
        Vector3.UP
    )

    var weight := 1.0 - exp(-rotation_speed * delta)

    global_basis = global_basis.slerp(
        desired_basis,
        weight
    ).orthonormalized()


# ============================================================
# CAMERA COLLISION
# ============================================================

func _check_camera_collision(
    origin: Vector3,
    destination: Vector3
) -> Vector3:

    var space := get_world_3d().direct_space_state

    var query := PhysicsRayQueryParameters3D.create(
        origin,
        destination
    )

    query.collision_mask = collision_mask
    query.exclude = [target.get_rid()] if target is CollisionObject3D else []

    var result := space.intersect_ray(query)

    if not result.is_empty():
        var hit_position: Vector3 = result.position
        var direction := (destination - origin).normalized()

        return hit_position - direction * collision_margin

    return destination


# ============================================================
# SPEED BASED FOV
# ============================================================

func _update_dynamic_fov(delta: float) -> void:

    var speed := 0.0

    if target is VehicleBody3D:
        var truck := target as VehicleBody3D
        speed = truck.linear_velocity.length()

    var desired_fov := clampf(
        base_fov + speed * speed_zoom,
        min_fov,
        max_fov
    )

    var weight := 1.0 - exp(-3.0 * delta)

    fov = lerpf(
        fov,
        desired_fov,
        weight
    )


# ============================================================
# CAMERA SHAKE
# ============================================================

func _update_camera_shake(delta: float) -> void:

    if not shake_enabled:
        h_offset = 0.0
        v_offset = 0.0
        return

    var speed := 0.0

    if target is VehicleBody3D:
        var truck := target as VehicleBody3D
        speed = truck.linear_velocity.length()

    var acceleration := abs(speed - previous_speed) / maxf(delta, 0.001)

    previous_speed = speed

    shake_amount = clampf(
        acceleration * acceleration_effect * 0.001,
        0.0,
        shake_intensity
    )

    shake_time += delta * shake_speed

    h_offset = sin(shake_time) * shake_amount
    v_offset = cos(shake_time * 1.4) * shake_amount


# ============================================================
# CAMERA CONTROL
# ============================================================

func set_camera_target(new_target: Node3D) -> void:
    target = new_target


func set_camera_offset(new_offset: Vector3) -> void:
    offset = new_offset


func reset_camera() -> void:
    if not is_instance_valid(target):
        return

    global_position = (
        target.global_position +
        target.global_transform.basis * offset
    )


func get_camera_speed() -> float:
    if target is VehicleBody3D:
        return (target as VehicleBody3D).linear_velocity.length() * 3.6

    return 0.0
