extends Node
class_name EngineFailureSystem

signal engine_failure(failure_name: String)
signal engine_recovered
signal component_wear_changed(component: String, wear: float)
signal breakdown_warning(message: String)

@export_group("Vehicle References")
@export var truck: VehicleBody3D
@export var cooling_system: EngineCoolingSystem
@export var oil_system: EngineOilSystem

@export_group("Failure Settings")
@export var overheating_limit: float = 120.0
@export var critical_oil_pressure: float = 0.5
@export var critical_oil_temperature: float = 140.0

@export_group("Mechanical Wear")
@export var engine_wear_rate: float = 0.0005
@export var transmission_wear_rate: float = 0.0002
@export var brake_wear_rate: float = 0.0001

@export_group("Recovery")
@export var recovery_temperature: float = 85.0
@export var recovery_oil_pressure: float = 1.0

var engine_failed: bool = false
var transmission_failed: bool = false
var brakes_failed: bool = false

var engine_wear: float = 0.0
var transmission_wear: float = 0.0
var brake_wear: float = 0.0

var failure_reason: String = ""
var warning_timer: float = 0.0


func _ready() -> void:
    add_to_group("engine_failure_system")
    _find_references()


func _physics_process(delta: float) -> void:

    _find_missing_references()

    _update_component_wear(delta)
    _check_engine_failure()
    _check_transmission_failure()
    _check_brake_failure()
    _update_recovery()


# ============================================================
# REFERENCES
# ============================================================

func _find_references() -> void:

    var trucks := get_tree().get_nodes_in_group("player")

    if not is_instance_valid(truck) and not trucks.is_empty():
        truck = trucks[0] as VehicleBody3D

    if not is_instance_valid(cooling_system):
        cooling_system = get_tree().get_first_node_in_group(
            "engine_cooling_system"
        ) as EngineCoolingSystem

    if not is_instance_valid(oil_system):
        oil_system = get_tree().get_first_node_in_group(
            "engine_oil_system"
        ) as EngineOilSystem


func _find_missing_references() -> void:

    if (
        not is_instance_valid(truck)
        or not is_instance_valid(cooling_system)
        or not is_instance_valid(oil_system)
    ):
        _find_references()


# ============================================================
# COMPONENT WEAR
# ============================================================

func _update_component_wear(delta: float) -> void:

    if not is_instance_valid(truck):
        return

    if not bool(truck.get("engine_on")):
        return

    var speed := truck.linear_velocity.length()

    if engine_wear < 100.0:
        engine_wear += engine_wear_rate * delta

        if speed > 15.0:
            engine_wear += engine_wear_rate * delta

    if transmission_wear < 100.0:
        transmission_wear += transmission_wear_rate * delta

    if brake_wear < 100.0:
        brake_wear += brake_wear_rate * delta

    engine_wear = clampf(engine_wear, 0.0, 100.0)
    transmission_wear = clampf(transmission_wear, 0.0, 100.0)
    brake_wear = clampf(brake_wear, 0.0, 100.0)


# ============================================================
# ENGINE FAILURE
# ============================================================

func _check_engine_failure() -> void:

    if engine_failed:
        return

    if not is_instance_valid(truck):
        return

    if is_instance_valid(cooling_system):

        if cooling_system.get_engine_temperature() >= overheating_limit:
            _fail_engine("ENGINE OVERHEATING")
            return

    if is_instance_valid(oil_system):

        if oil_system.get_oil_level() <= 0.0:
            _fail_engine("ENGINE OIL EMPTY")
            return

        if oil_system.get_oil_pressure() <= critical_oil_pressure:
            if oil_system.is_oil_pump_active():
                _fail_engine("CRITICAL OIL PRESSURE")
                return

        if oil_system.get_oil_temperature() >= critical_oil_temperature:
            _fail_engine("ENGINE OIL OVERHEATING")
            return

    if engine_wear >= 100.0:
        _fail_engine("ENGINE COMPONENT FAILURE")


func _fail_engine(reason: String) -> void:

    engine_failed = true
    failure_reason = reason

    truck.set("engine_on", false)

    engine_failure.emit(reason)
    breakdown_warning.emit(reason)


# ============================================================
# TRANSMISSION FAILURE
# ============================================================

func _check_transmission_failure() -> void:

    if transmission_failed:
        return

    if transmission_wear >= 100.0:
        transmission_failed = true

        failure_reason = "TRANSMISSION FAILURE"

        engine_failure.emit(failure_reason)
        breakdown_warning.emit(failure_reason)


# ============================================================
# BRAKE FAILURE
# ============================================================

func _check_brake_failure() -> void:

    if brakes_failed:
        return

    if brake_wear >= 100.0:
        brakes_failed = true

        failure_reason = "BRAKE SYSTEM FAILURE"

        engine_failure.emit(failure_reason)
        breakdown_warning.emit(failure_reason)


# ============================================================
# RECOVERY
# ============================================================

func _update_recovery() -> void:

    if not engine_failed:
        return

    if not is_instance_valid(cooling_system):
        return

    if not is_instance_valid(oil_system):
        return

    if cooling_system.get_engine_temperature() <= recovery_temperature:
        if oil_system.get_oil_pressure() >= recovery_oil_pressure:
            return


func repair_engine() -> void:

    engine_failed = false
    engine_wear = 0.0
    failure_reason = ""

    engine_recovered.emit()


func repair_transmission() -> void:

    transmission_failed = false
    transmission_wear = 0.0


func repair_brakes() -> void:

    brakes_failed = false
    brake_wear = 0.0


func repair_all_components() -> void:

    repair_engine()
    repair_transmission()
    repair_brakes()


# ============================================================
# STATUS
# ============================================================

func is_engine_failed() -> bool:
    return engine_failed


func is_transmission_failed() -> bool:
    return transmission_failed


func is_brakes_failed() -> bool:
    return brakes_failed


func get_engine_wear() -> float:
    return engine_wear


func get_transmission_wear() -> float:
    return transmission_wear


func get_brake_wear() -> float:
    return brake_wear


func get_failure_reason() -> String:
    return failure_reason


func get_component_status() -> Dictionary:

    return {
        "engine": engine_wear,
        "transmission": transmission_wear,
        "brakes": brake_wear,
        "engine_failed": engine_failed,
        "transmission_failed": transmission_failed,
        "brakes_failed": brakes_failed
    }
