extends Node
class_name TowTruckManager

signal tow_truck_ready
signal vehicle_attached(vehicle: RigidBody3D)
signal vehicle_detached
signal integration_warning(message: String)

@export_group("Tow Truck Components")
@export var tow_truck: TowTruckDrive
@export var winch: TowTruckWinch
@export var rope: TowRopePhysics

@export_group("Safety")
@export var maximum_towing_speed: float = 25.0
@export var allow_towing_while_driving: bool = true
@export var stop_before_hooking: bool = true

var attached_vehicle: RigidBody3D
var system_ready: bool = false


func _ready() -> void:
    add_to_group("tow_truck_manager")

    _find_components()
    _connect_signals()
    _check_systems()


func _physics_process(_delta: float) -> void:
    _find_missing_components()
    _check_towing_speed()


# ============================================================
# COMPONENT DISCOVERY
# ============================================================

func _find_components() -> void:

    if not is_instance_valid(tow_truck):
        tow_truck = get_tree().get_first_node_in_group(
            "tow_truck"
        ) as TowTruckDrive

    if not is_instance_valid(winch):
        winch = get_tree().get_first_node_in_group(
            "tow_truck_winch"
        ) as TowTruckWinch

    if not is_instance_valid(rope):
        rope = get_tree().get_first_node_in_group(
            "tow_rope_physics"
        ) as TowRopePhysics


func _find_missing_components() -> void:

    if (
        not is_instance_valid(tow_truck)
        or not is_instance_valid(winch)
        or not is_instance_valid(rope)
    ):
        _find_components()
        _check_systems()


# ============================================================
# SYSTEM VALIDATION
# ============================================================

func _check_systems() -> void:

    var ready := (
        is_instance_valid(tow_truck)
        and is_instance_valid(winch)
        and is_instance_valid(rope)
    )

    if ready and not system_ready:
        system_ready = true
        tow_truck_ready.emit()

    elif not ready:
        system_ready = false


# ============================================================
# SIGNAL CONNECTIONS
# ============================================================

func _connect_signals() -> void:

    if is_instance_valid(winch):

        if not winch.vehicle_hooked.is_connected(
            _on_vehicle_hooked
        ):
            winch.vehicle_hooked.connect(
                _on_vehicle_hooked
            )

        if not winch.vehicle_released.is_connected(
            _on_vehicle_released
        ):
            winch.vehicle_released.connect(
                _on_vehicle_released
            )


# ============================================================
# HOOK VEHICLE
# ============================================================

func attach_vehicle(vehicle: RigidBody3D) -> bool:

    if not system_ready:
        integration_warning.emit(
            "Tow truck systems are not ready."
        )
        return false

    if not is_instance_valid(vehicle):
        return false

    if vehicle == tow_truck:
        return false

    if attached_vehicle != null:
        return false

    if stop_before_hooking:
        if tow_truck.linear_velocity.length() > 0.5:
            integration_warning.emit(
                "Stop the tow truck before connecting."
            )
            return false

    var hook_success := winch.try_hook_vehicle()

    if not hook_success:
        integration_warning.emit(
            "No towable vehicle is close enough to the hook."
        )
        return false

    if winch.hooked_vehicle != vehicle:
        winch.release_vehicle()
        return false

    if not rope.connect_vehicle(vehicle):
        winch.release_vehicle()
        integration_warning.emit(
            "Could not create the rope connection."
        )
        return false

    attached_vehicle = vehicle

    vehicle_attached.emit(vehicle)

    return true


# ============================================================
# DETACH VEHICLE
# ============================================================

func detach_vehicle() -> void:

    if is_instance_valid(rope):
        rope.disconnect_vehicle()

    if is_instance_valid(winch):
        winch.release_vehicle()

    attached_vehicle = null

    vehicle_detached.emit()


# ============================================================
# SPEED SAFETY
# ============================================================

func _check_towing_speed() -> void:

    if not is_instance_valid(tow_truck):
        return

    if not is_instance_valid(attached_vehicle):
        return

    var speed := tow_truck.linear_velocity.length() * 3.6

    if speed > maximum_towing_speed:

        if not allow_towing_while_driving:
            tow_truck.engine_force = 0.0

        integration_warning.emit(
            "Warning: Towing speed is too high!"
        )


# ============================================================
# SIGNAL CALLBACKS
# ============================================================

func _on_vehicle_hooked(vehicle: RigidBody3D) -> void:
    attached_vehicle = vehicle


func _on_vehicle_released() -> void:
    attached_vehicle = null


# ============================================================
# INFORMATION
# ============================================================

func is_system_ready() -> bool:
    return system_ready


func is_vehicle_attached() -> bool:
    return is_instance_valid(attached_vehicle)


func get_attached_vehicle() -> RigidBody3D:
    return attached_vehicle


func get_towing_speed() -> float:

    if not is_instance_valid(tow_truck):
        return 0.0

    return tow_truck.linear_velocity.length() * 3.6
