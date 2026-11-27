extends Node
class_name RoadsideAssistance

signal assistance_requested
signal recovery_started
signal recovery_completed
signal recovery_cancelled
signal recovery_cost_charged(amount: float)

@export_group("Vehicle")
@export var truck: VehicleBody3D

@export_group("Recovery Settings")
@export var recovery_cost: float = 2500.0
@export var recovery_duration: float = 8.0
@export var recovery_position: Vector3 = Vector3.ZERO
@export var recovery_rotation: Vector3 = Vector3.ZERO

@export_group("Safety")
@export var require_engine_failure: bool = true
@export var minimum_recovery_speed: float = 0.5

var wallet: Node
var failure_system: EngineFailureSystem

var assistance_requested_state: bool = false
var recovery_in_progress: bool = false

var recovery_timer: float = 0.0
var original_engine_state: bool = false


func _ready() -> void:
    add_to_group("roadside_assistance")
    _find_references()


func _physics_process(delta: float) -> void:

    _find_missing_references()

    if not recovery_in_progress:
        return

    recovery_timer += delta

    if recovery_timer >= recovery_duration:
        _finish_recovery()


# ============================================================
# REFERENCES
# ============================================================

func _find_references() -> void:

    if not is_instance_valid(truck):
        var trucks := get_tree().get_nodes_in_group("player")

        if not trucks.is_empty():
            truck = trucks[0] as VehicleBody3D

    if not is_instance_valid(wallet):
        wallet = get_tree().get_first_node_in_group("wallet_system")

    if not is_instance_valid(failure_system):
        failure_system = get_tree().get_first_node_in_group(
            "engine_failure_system"
        ) as EngineFailureSystem


func _find_missing_references() -> void:

    if (
        not is_instance_valid(truck)
        or not is_instance_valid(wallet)
        or not is_instance_valid(failure_system)
    ):
        _find_references()


# ============================================================
# REQUEST ASSISTANCE
# ============================================================

func request_assistance() -> bool:

    if recovery_in_progress:
        return false

    if assistance_requested_state:
        return false

    if not is_instance_valid(truck):
        return false

    if not is_instance_valid(wallet):
        return false

    if require_engine_failure:

        if not is_instance_valid(failure_system):
            return false

        if not (
            failure_system.is_engine_failed()
            or failure_system.is_transmission_failed()
            or failure_system.is_brakes_failed()
        ):
            return false

    assistance_requested_state = true

    assistance_requested.emit()

    return true


# ============================================================
# START RECOVERY
# ============================================================

func start_recovery() -> bool:

    if not assistance_requested_state:
        return false

    if recovery_in_progress:
        return false

    if not is_instance_valid(truck):
        return false

    if not is_instance_valid(wallet):
        return false

    if truck.linear_velocity.length() > minimum_recovery_speed:
        return false

    if not wallet.can_afford(recovery_cost):
        return false

    original_engine_state = bool(truck.get("engine_on"))

    recovery_in_progress = true
    recovery_timer = 0.0

    truck.set("engine_on", false)
    truck.freeze = true

    recovery_started.emit()

    return true


# ============================================================
# FINISH RECOVERY
# ============================================================

func _finish_recovery() -> void:

    if not is_instance_valid(truck):
        cancel_recovery()
        return

    if not is_instance_valid(wallet):
        cancel_recovery()
        return

    if not wallet.spend_money(
        recovery_cost,
        "Roadside Assistance"
    ):
        cancel_recovery()
        return

    truck.global_position = recovery_position
    truck.global_rotation = recovery_rotation

    truck.linear_velocity = Vector3.ZERO
    truck.angular_velocity = Vector3.ZERO

    truck.freeze = false

    if not is_instance_valid(failure_system):
        _find_references()

    if is_instance_valid(failure_system):
        failure_system.repair_all_components()

    truck.set("engine_on", false)

    recovery_cost_charged.emit(recovery_cost)

    recovery_in_progress = false
    assistance_requested_state = false
    recovery_timer = 0.0

    recovery_completed.emit()


# ============================================================
# CANCEL RECOVERY
# ============================================================

func cancel_recovery() -> void:

    if is_instance_valid(truck):
        truck.freeze = false
        truck.linear_velocity = Vector3.ZERO
        truck.angular_velocity = Vector3.ZERO

    recovery_in_progress = false
    assistance_requested_state = false
    recovery_timer = 0.0

    recovery_cancelled.emit()


# ============================================================
# INFORMATION
# ============================================================

func is_assistance_requested() -> bool:
    return assistance_requested_state


func is_recovering() -> bool:
    return recovery_in_progress


func get_recovery_progress() -> float:

    if recovery_duration <= 0.0:
        return 0.0

    return clampf(
        recovery_timer / recovery_duration * 100.0,
        0.0,
        100.0
    )


func get_recovery_cost() -> float:
    return recovery_cost
