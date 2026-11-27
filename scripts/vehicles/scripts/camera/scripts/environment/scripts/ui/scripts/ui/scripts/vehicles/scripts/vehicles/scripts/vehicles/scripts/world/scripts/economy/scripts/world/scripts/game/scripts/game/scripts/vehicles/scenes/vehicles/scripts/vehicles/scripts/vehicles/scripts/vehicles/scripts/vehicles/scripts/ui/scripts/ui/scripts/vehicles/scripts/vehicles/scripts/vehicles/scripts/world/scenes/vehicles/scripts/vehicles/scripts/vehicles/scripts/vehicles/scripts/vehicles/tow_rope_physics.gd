extends Node3D
class_name TowRopePhysics

signal rope_connected(vehicle: RigidBody3D)
signal rope_disconnected
signal rope_length_changed(length: float)

@export_group("Connection")
@export var hook_point: Marker3D
@export var target_vehicle: RigidBody3D

@export_group("Rope")
@export var rope_length: float = 4.0
@export var minimum_length: float = 1.0
@export var maximum_length: float = 12.0
@export var rope_strength: float = 25000.0

@export_group("Physics")
@export var enable_joint: bool = true
@export var joint_bias: float = 0.3
@export var joint_damping: float = 1.0
@export var joint_impulse_clamp: float = 25000.0

var rope_joint: PinJoint3D
var rope_visual: MeshInstance3D
var connected: bool = false


func _ready() -> void:
    add_to_group("tow_rope_physics")

    if hook_point == null:
        hook_point = get_node_or_null("HookPoint") as Marker3D

    if rope_visual == null:
        rope_visual = get_node_or_null("RopeVisual") as MeshInstance3D

    _update_rope_visual()


func _physics_process(_delta: float) -> void:
    if connected:
        _update_rope_visual()


# ============================================================
# CONNECT
# ============================================================

func connect_vehicle(vehicle: RigidBody3D) -> bool:

    if connected:
        return false

    if not enable_joint:
        return false

    if not is_instance_valid(vehicle):
        return false

    if not is_instance_valid(hook_point):
        return false

    var tow_body := _find_tow_body()

    if tow_body == null:
        return false

    if tow_body == vehicle:
        return false

    target_vehicle = vehicle

    rope_joint = PinJoint3D.new()
    rope_joint.name = "TowPinJoint"

    tow_body.add_child(rope_joint)

    rope_joint.global_position = hook_point.global_position

    rope_joint.node_a = rope_joint.get_path_to(tow_body)
    rope_joint.node_b = rope_joint.get_path_to(target_vehicle)

    rope_joint.set_param(
        PinJoint3D.PARAM_BIAS,
        joint_bias
    )

    rope_joint.set_param(
        PinJoint3D.PARAM_DAMPING,
        joint_damping
    )

    rope_joint.set_param(
        PinJoint3D.PARAM_IMPULSE_CLAMP,
        joint_impulse_clamp
    )

    connected = true

    rope_connected.emit(target_vehicle)

    return true


func _find_tow_body() -> RigidBody3D:

    var current: Node = get_parent()

    while current != null:

        if current is RigidBody3D:
            return current as RigidBody3D

        current = current.get_parent()

    return null


# ============================================================
# ROPE LENGTH
# ============================================================

func increase_rope_length(amount: float) -> void:

    rope_length = clampf(
        rope_length + amount,
        minimum_length,
        maximum_length
    )

    rope_length_changed.emit(rope_length)


func decrease_rope_length(amount: float) -> void:

    rope_length = clampf(
        rope_length - amount,
        minimum_length,
        maximum_length
    )

    rope_length_changed.emit(rope_length)


# ============================================================
# ROPE VISUAL
# ============================================================

func _update_rope_visual() -> void:

    if rope_visual == null or hook_point == null:
        return

    if not is_instance_valid(target_vehicle):
        rope_visual.visible = false
        return

    var start_position := to_local(hook_point.global_position)
    var end_position := to_local(target_vehicle.global_position)

    var difference := end_position - start_position
    var distance := difference.length()

    if distance < 0.01:
        return

    rope_visual.visible = true
    rope_visual.position = (start_position + end_position) * 0.5
    rope_visual.look_at(
        rope_visual.position + difference.normalized(),
        Vector3.UP
    )

    rope_visual.scale = Vector3(0.035, 0.035, distance * 0.5)


# ============================================================
# DISCONNECT
# ============================================================

func disconnect_vehicle() -> void:

    if not connected:
        return

    if is_instance_valid(rope_joint):
        rope_joint.queue_free()

    rope_joint = null
    target_vehicle = null
    connected = false

    if rope_visual != null:
        rope_visual.visible = false

    rope_disconnected.emit()


func is_connected_to_vehicle() -> bool:
    return connected


func get_rope_length() -> float:
    return rope_length
