extends Node
class_name TruckCargoSystem

signal cargo_loaded(weight: float)
signal cargo_unloaded(weight: float)
signal load_changed(current_weight: float)
signal overload_warning

@export_group("Truck")
@export var truck: VehicleBody3D

@export_group("Cargo Capacity")
@export var maximum_capacity := 20000.0
@export var starting_cargo_weight := 0.0

@export_group("Physics")
@export var loaded_mass_multiplier := 1.0
@export var maximum_steering_reduction := 0.25

var current_cargo_weight := 0.0
var original_mass := 0.0


func _ready():
    if is_instance_valid(truck):
        original_mass = truck.mass

    current_cargo_weight = clampf(
        starting_cargo_weight,
        0.0,
        maximum_capacity
    )

    update_truck_physics()


func load_cargo(weight: float) -> bool:
    if weight <= 0.0:
        return false

    if current_cargo_weight + weight > maximum_capacity:
        overload_warning.emit()
        return false

    current_cargo_weight += weight

    update_truck_physics()
    cargo_loaded.emit(weight)
    load_changed.emit(current_cargo_weight)

    return true


func unload_cargo(weight: float) -> bool:
    if weight <= 0.0:
        return false

    if weight > current_cargo_weight:
        return false

    current_cargo_weight -= weight

    update_truck_physics()
    cargo_unloaded.emit(weight)
    load_changed.emit(current_cargo_weight)

    return true


func unload_all_cargo():
    if current_cargo_weight <= 0.0:
        return

    var removed_weight := current_cargo_weight
    current_cargo_weight = 0.0

    update_truck_physics()
    cargo_unloaded.emit(removed_weight)
    load_changed.emit(current_cargo_weight)


func update_truck_physics():
    if not is_instance_valid(truck):
        return

    var added_mass := current_cargo_weight * loaded_mass_multiplier

    truck.mass = original_mass + added_mass

    var load_ratio := clampf(
        current_cargo_weight / maximum_capacity,
        0.0,
        1.0
    )

    var steering_factor := 1.0 - (
        load_ratio * maximum_steering_reduction
    )

    truck.steering = clampf(
        truck.steering * steering_factor,
        -0.6,
        0.6
    )


func get_cargo_weight() -> float:
    return current_cargo_weight


func get_remaining_capacity() -> float:
    return maxf(
        maximum_capacity - current_cargo_weight,
        0.0
    )


func get_load_percentage() -> float:
    return (
        current_cargo_weight / maximum_capacity
    ) * 100.0


func is_overloaded() -> bool:
    return current_cargo_weight > maximum_capacity


func reset_cargo():
    unload_all_cargo()
