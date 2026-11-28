extends Node
class_name TruckFuelSystem

signal fuel_changed(current_fuel: float)
signal low_fuel_warning
signal fuel_empty
signal refueling_completed

@export_group("Fuel Tank")
@export var tank_capacity := 300.0
@export var starting_fuel := 250.0

@export_group("Consumption")
@export var idle_consumption := 0.015
@export var driving_consumption := 0.025
@export var heavy_load_multiplier := 1.5

@export_group("Vehicle")
@export var truck: VehicleBody3D
@export var gearbox: Node

var current_fuel := 250.0
var engine_running := true
var heavy_load := false
var low_fuel_triggered := false


func _ready():
    current_fuel = clampf(
        starting_fuel, 0.0, tank_capacity
    )
    fuel_changed.emit(current_fuel)


func _physics_process(delta):
    if not engine_running:
        return

    if current_fuel <= 0.0:
        current_fuel = 0.0
        engine_running = false
        fuel_empty.emit()
        return

    consume_fuel(delta)
    check_fuel_level()


func consume_fuel(delta: float):
    var consumption := idle_consumption

    if is_instance_valid(truck):
        var speed := truck.linear_velocity.length()

        consumption += speed * driving_consumption

    if heavy_load:
        consumption *= heavy_load_multiplier

    current_fuel = maxf(
        current_fuel - consumption * delta,
        0.0
    )

    fuel_changed.emit(current_fuel)


func check_fuel_level():
    var percentage := get_fuel_percentage()

    if percentage <= 15.0 and not low_fuel_triggered:
        low_fuel_triggered = true
        low_fuel_warning.emit()

    if percentage > 15.0:
        low_fuel_triggered = false


func refuel(amount: float):
    if amount <= 0.0:
        return

    current_fuel = minf(
        current_fuel + amount,
        tank_capacity
    )

    if current_fuel > 0.0:
        engine_running = true

    fuel_changed.emit(current_fuel)

    if current_fuel >= tank_capacity:
        refueling_completed.emit()


func set_heavy_load(enabled: bool):
    heavy_load = enabled


func set_engine_running(enabled: bool):
    if enabled and current_fuel <= 0.0:
        engine_running = false
        return

    engine_running = enabled


func get_fuel_level() -> float:
    return current_fuel


func get_fuel_percentage() -> float:
    return (current_fuel / tank_capacity) * 100.0


func is_engine_running() -> bool:
    return engine_running
