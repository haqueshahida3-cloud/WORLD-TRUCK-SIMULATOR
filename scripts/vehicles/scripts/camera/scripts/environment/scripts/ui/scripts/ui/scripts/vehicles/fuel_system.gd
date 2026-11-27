extends Node
class_name TruckFuelSystem

@export_group("Fuel Tank")
@export var tank_capacity: float = 500.0
@export var starting_fuel: float = 500.0

@export_group("Fuel Consumption")
@export var idle_consumption: float = 0.8
@export var driving_consumption: float = 0.035
@export var load_factor: float = 1.0

@export_group("Warnings")
@export var low_fuel_warning: float = 20.0

var current_fuel: float = 500.0
var fuel_percentage: float = 100.0
var fuel_empty: bool = false
var low_fuel: bool = false

var truck: VehicleBody3D


func _ready() -> void:
    current_fuel = clampf(starting_fuel, 0.0, tank_capacity)
    _update_fuel_state()


func _physics_process(delta: float) -> void:
    if truck == null:
        _find_truck()

    if not is_instance_valid(truck):
        return

    if fuel_empty:
        if truck is Truck:
            (truck as Truck).engine_on = false
        return

    if truck is Truck and not (truck as Truck).engine_on:
        return

    _consume_fuel(delta)


func _find_truck() -> void:
    var trucks := get_tree().get_nodes_in_group("player")

    if not trucks.is_empty():
        truck = trucks[0] as VehicleBody3D


func _consume_fuel(delta: float) -> void:
    var speed := truck.linear_velocity.length()

    var consumption := idle_consumption

    if speed > 0.5:
        consumption += speed * driving_consumption

    consumption *= load_factor

    current_fuel -= consumption * delta / 3600.0

    current_fuel = maxf(current_fuel, 0.0)

    _update_fuel_state()


func _update_fuel_state() -> void:
    fuel_percentage = (
        current_fuel / tank_capacity
    ) * 100.0 if tank_capacity > 0.0 else 0.0

    fuel_empty = current_fuel <= 0.0
    low_fuel = fuel_percentage <= low_fuel_warning


func refuel(amount: float) -> float:
    if amount <= 0.0:
        return 0.0

    var previous_fuel := current_fuel

    current_fuel = minf(
        current_fuel + amount,
        tank_capacity
    )

    _update_fuel_state()

    return current_fuel - previous_fuel


func refuel_full() -> void:
    current_fuel = tank_capacity
    _update_fuel_state()


func get_fuel_percentage() -> float:
    return fuel_percentage


func get_fuel_liters() -> float:
    return current_fuel


func is_low_fuel() -> bool:
    return low_fuel


func is_fuel_empty() -> bool:
    return fuel_empty
