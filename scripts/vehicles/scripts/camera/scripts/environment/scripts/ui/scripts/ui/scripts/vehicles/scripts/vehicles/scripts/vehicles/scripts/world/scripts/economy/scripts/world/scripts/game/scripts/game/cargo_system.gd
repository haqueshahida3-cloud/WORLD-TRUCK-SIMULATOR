extends Node
class_name CargoSystem

signal cargo_loaded(cargo_name: String)
signal cargo_unloaded(cargo_name: String)
signal cargo_condition_changed(condition: float)
signal cargo_load_failed(reason: String)

@export_group("Cargo Settings")
@export var maximum_cargo_weight: float = 30000.0
@export var default_cargo_condition: float = 100.0

@export_group("Cargo Physics")
@export var load_center_height: float = 0.0
@export var weight_steering_effect: float = 0.15

var truck: VehicleBody3D

var cargo_loaded_state: bool = false
var cargo_name: String = ""
var cargo_weight: float = 0.0
var cargo_condition: float = 100.0

var original_truck_mass: float = 0.0


func _ready() -> void:
    add_to_group("cargo_system")
    _find_truck()


func _find_truck() -> void:
    var trucks := get_tree().get_nodes_in_group("player")

    if not trucks.is_empty():
        truck = trucks[0] as VehicleBody3D

        if is_instance_valid(truck):
            original_truck_mass = truck.mass


# ============================================================
# LOAD CARGO
# ============================================================

func load_cargo(
    name: String,
    weight: float
) -> bool:

    if cargo_loaded_state:
        cargo_load_failed.emit("Cargo already loaded")
        return false

    if not is_instance_valid(truck):
        _find_truck()

    if not is_instance_valid(truck):
        cargo_load_failed.emit("Truck not found")
        return false

    if name.strip_edges().is_empty():
        cargo_load_failed.emit("Invalid cargo name")
        return false

    if weight <= 0.0 or weight > maximum_cargo_weight:
        cargo_load_failed.emit("Invalid cargo weight")
        return false

    cargo_name = name
    cargo_weight = weight
    cargo_condition = default_cargo_condition

    cargo_loaded_state = true

    _apply_cargo_weight()

    cargo_loaded.emit(cargo_name)

    return true


# ============================================================
# APPLY CARGO WEIGHT
# ============================================================

func _apply_cargo_weight() -> void:

    if not is_instance_valid(truck):
        return

    truck.mass = original_truck_mass + cargo_weight


# ============================================================
# CARGO CONDITION
# ============================================================

func damage_cargo(amount: float) -> void:

    if not cargo_loaded_state:
        return

    if amount <= 0.0:
        return

    cargo_condition = clampf(
        cargo_condition - amount,
        0.0,
        100.0
    )

    cargo_condition_changed.emit(cargo_condition)


func get_cargo_condition() -> float:
    return cargo_condition


# ============================================================
# UNLOAD CARGO
# ============================================================

func unload_cargo() -> bool:

    if not cargo_loaded_state:
        return false

    var unloaded_name := cargo_name

    cargo_loaded_state = false
    cargo_name = ""
    cargo_weight = 0.0
    cargo_condition = 100.0

    _restore_truck_mass()

    cargo_unloaded.emit(unloaded_name)

    return true


func _restore_truck_mass() -> void:

    if not is_instance_valid(truck):
        return

    truck.mass = original_truck_mass


# ============================================================
# INFORMATION
# ============================================================

func has_cargo() -> bool:
    return cargo_loaded_state


func get_cargo_name() -> String:
    return cargo_name


func get_cargo_weight() -> float:
    return cargo_weight


func get_cargo_condition_percentage() -> float:
    return cargo_condition


func get_truck_total_mass() -> float:

    if not is_instance_valid(truck):
        return 0.0

    return truck.mass


func reset_cargo() -> void:

    if cargo_loaded_state:
        unload_cargo()
