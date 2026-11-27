extends Node3D
class_name TowTruckWinch

signal boom_moved(angle: float)
signal cable_extended(length: float)
signal vehicle_hooked(vehicle: RigidBody3D)
signal vehicle_released

@export_group("Hydraulic Boom")
@export var boom: Node3D
@export var boom_speed: float = 20.0
@export var minimum_boom_angle: float = -10.0
@export var maximum_boom_angle: float = 55.0

@export_group("Winch Cable")
@export var cable: MeshInstance3D
@export var hook: Node3D
@export var cable_speed: float = 2.0
@export var minimum_cable_length: float = 0.5
@export var maximum_cable_length: float = 8.0

@export_group("Towing")
@export var towing_force: float = 18000.0
@export var hook_distance: float = 1.5

var boom_angle: float = 0.0
var cable_length: float = 2.0

var hooked_vehicle: RigidBody3D
var winch_active: bool = false
var hook_connected: bool = false


func _ready() -> void:
    add_to_group("tow_truck_winch")

    if boom == null:
        boom = get_node_or_null("Boom")

    if cable == null:
        cable = get_node_or_null("Cable")

    if hook == null:
        hook = get_node_or_null("Hook")

    _update_boom()
    _update_cable()


func _process(delta: float) -> void:
    _read_controls(delta)

    if winch_active and hook_connected:
        _pull_vehicle(delta)


# ============================================================
# CONTROLS
# ============================================================

func _read_controls(delta: float) -> void:

    if Input.is_action_pressed("boom_up"):
        move_boom(delta)

    if Input.is_action_pressed("boom_down"):
        lower_boom(delta)

    if Input.is_action_pressed("winch_extend"):
        extend_cable(delta)

    if Input.is_action_pressed("winch_retract"):
        retract_cable(delta)

    if Input.is_action_just_pressed("hook_vehicle"):
        try_hook_vehicle()

    if Input.is_action_just_pressed("release_hook"):
        release_vehicle()


# ============================================================
# HYDRAULIC BOOM
# ============================================================

func move_boom(delta: float) -> void:

    boom_angle = move_toward(
        boom_angle,
        maximum_boom_angle,
        boom_speed * delta
    )

    _update_boom()
    boom_moved.emit(boom_angle)


func lower_boom(delta: float) -> void:

    boom_angle = move_toward(
        boom_angle,
        minimum_boom_angle,
        boom_speed * delta
    )

    _update_boom()
    boom_moved.emit(boom_angle)


func _update_boom() -> void:

    if boom == null:
        return

    boom.rotation_degrees.x = boom_angle


# ============================================================
# WINCH CABLE
# ============================================================

func extend_cable(delta: float) -> void:

    cable_length = clampf(
        cable_length + cable_speed * delta,
        minimum_cable_length,
        maximum_cable_length
    )

    _update_cable()
    cable_extended.emit(cable_length)


func retract_cable(delta: float) -> void:

    cable_length = clampf(
        cable_length - cable_speed * delta,
        minimum_cable_length,
        maximum_cable_length
    )

    _update_cable()
    cable_extended.emit(cable_length)


func _update_cable() -> void:

    if cable != null:
        cable.position.y = -cable_length * 0.5
        cable.scale.y = cable_length

    if hook != null:
        hook.position.y = -cable_length


# ============================================================
# HOOK CONNECTION
# ============================================================

func try_hook_vehicle() -> bool:

    if hook_connected:
        return false

    if hook == null:
        return false

    var candidates := get_tree().get_nodes_in_group("towable_vehicle")

    var nearest_vehicle: RigidBody3D
    var nearest_distance := hook_distance

    for candidate in candidates:

        if not candidate is RigidBody3D:
            continue

        var vehicle := candidate as RigidBody3D
        var distance := hook.global_position.distance_to(
            vehicle.global_position
        )

        if distance < nearest_distance:
            nearest_distance = distance
            nearest_vehicle = vehicle

    if nearest_vehicle == null:
        return false

    hooked_vehicle = nearest_vehicle
    hook_connected = true

    vehicle_hooked.emit(hooked_vehicle)

    return true


# ============================================================
# TOWING
# ============================================================

func start_winch() -> void:
    if hook_connected:
        winch_active = true


func stop_winch() -> void:
    winch_active = false


func _pull_vehicle(delta: float) -> void:

    if not is_instance_valid(hooked_vehicle):
        release_vehicle()
        return

    if hook == null:
        release_vehicle()
        return

    var direction := hook.global_position - hooked_vehicle.global_position
    var distance := direction.length()

    if distance < 0.5:
        return

    direction = direction.normalized()

    hooked_vehicle.apply_central_force(
        direction * towing_force
    )


func release_vehicle() -> void:

    winch_active = false
    hook_connected = false
    hooked_vehicle = null

    vehicle_released.emit()


# ============================================================
# STATUS
# ============================================================

func is_vehicle_hooked() -> bool:
    return hook_connected


func get_cable_length() -> float:
    return cable_length


func get_boom_angle() -> float:
    return boom_angle
