extends Node
class_name EngineOilSystem

signal oil_pressure_changed(pressure: float)
signal oil_temperature_changed(temperature: float)
signal oil_level_low
signal low_oil_pressure
signal engine_damage_warning

@export_group("Oil Settings")
@export var oil_capacity: float = 35.0
@export var starting_oil_level: float = 35.0
@export var minimum_oil_level: float = 5.0

@export_group("Oil Pressure")
@export var idle_oil_pressure: float = 1.5
@export var maximum_oil_pressure: float = 5.5
@export var low_pressure_threshold: float = 0.8

@export_group("Oil Temperature")
@export var ambient_temperature: float = 25.0
@export var starting_oil_temperature: float = 35.0
@export var maximum_oil_temperature: float = 140.0
@export var oil_heating_rate: float = 0.08
@export var oil_cooling_rate: float = 0.025

@export_group("Vehicle")
@export var truck: VehicleBody3D

var oil_level: float = 35.0
var oil_pressure: float = 0.0
var oil_temperature: float = 35.0

var oil_pump_active: bool = false
var pressure_warning_active: bool = false
var damage_warning_active: bool = false

var low_level_warning_sent: bool = false


func _ready() -> void:
    add_to_group("engine_oil_system")

    oil_level = starting_oil_level
    oil_temperature = starting_oil_temperature

    _find_truck()


func _physics_process(delta: float) -> void:

    if not is_instance_valid(truck):
        _find_truck()
        return

    _update_oil_pump()
    _update_oil_pressure()
    _update_oil_temperature(delta)
    _check_oil_condition()


func _find_truck() -> void:

    var trucks := get_tree().get_nodes_in_group("player")

    if not trucks.is_empty():
        truck = trucks[0] as VehicleBody3D


# ============================================================
# OIL PUMP
# ============================================================

func _update_oil_pump() -> void:

    oil_pump_active = false

    if not is_instance_valid(truck):
        return

    if truck.has_method("get"):
        oil_pump_active = bool(truck.get("engine_on"))

    if oil_level <= 0.0:
        oil_pump_active = false


# ============================================================
# OIL PRESSURE
# ============================================================

func _update_oil_pressure() -> void:

    if not oil_pump_active:
        oil_pressure = 0.0
        oil_pressure_changed.emit(oil_pressure)
        return

    var rpm := 700.0

    if truck.has_method("get"):
        var value = truck.get("current_rpm")

        if value != null:
            rpm = float(value)

    var rpm_factor := clampf(
        rpm / 2500.0,
        0.0,
        1.0
    )

    var oil_factor := clampf(
        oil_level / oil_capacity,
        0.0,
        1.0
    )

    var temperature_factor := 1.0

    if oil_temperature > 100.0:
        temperature_factor = clampf(
            1.0 - (oil_temperature - 100.0) * 0.01,
            0.4,
            1.0
        )

    oil_pressure = lerpf(
        idle_oil_pressure,
        maximum_oil_pressure,
        rpm_factor
    )

    oil_pressure *= oil_factor
    oil_pressure *= temperature_factor

    oil_pressure_changed.emit(oil_pressure)


# ============================================================
# OIL TEMPERATURE
# ============================================================

func _update_oil_temperature(delta: float) -> void:

    if oil_pump_active:

        var engine_load := 1.0

        if truck.linear_velocity.length() > 0.1:
            engine_load = 1.5

        oil_temperature += (
            oil_heating_rate * engine_load * delta
        )

    else:

        oil_temperature -= (
            oil_cooling_rate * delta
        )

    oil_temperature = maxf(
        oil_temperature,
        ambient_temperature
    )

    oil_temperature_changed.emit(oil_temperature)


# ============================================================
# CONDITION WARNINGS
# ============================================================

func _check_oil_condition() -> void:

    if oil_level <= minimum_oil_level:

        if not low_level_warning_sent:
            low_level_warning_sent = true
            oil_level_low.emit()

    else:
        low_level_warning_sent = false

    var previous_warning := pressure_warning_active

    pressure_warning_active = (
        oil_pump_active
        and oil_pressure < low_pressure_threshold
    )

    if pressure_warning_active and not previous_warning:
        low_oil_pressure.emit()

    damage_warning_active = (
        oil_level <= 0.0
        or oil_temperature >= maximum_oil_temperature
    )

    if damage_warning_active:
        engine_damage_warning.emit()


# ============================================================
# ADD ENGINE OIL
# ============================================================

func add_oil(amount: float) -> float:

    if amount <= 0.0:
        return 0.0

    var added := minf(
        amount,
        oil_capacity - oil_level
    )

    oil_level += added

    return added


func drain_oil(amount: float) -> void:

    if amount <= 0.0:
        return

    oil_level = maxf(
        oil_level - amount,
        0.0
    )


# ============================================================
# OIL INFORMATION
# ============================================================

func get_oil_level() -> float:
    return oil_level


func get_oil_percentage() -> float:
    return (oil_level / oil_capacity) * 100.0


func get_oil_pressure() -> float:
    return oil_pressure


func get_oil_temperature() -> float:
    return oil_temperature


func is_oil_pressure_warning() -> bool:
    return pressure_warning_active


func is_oil_level_low() -> bool:
    return oil_level <= minimum_oil_level


func is_oil_pump_active() -> bool:
    return oil_pump_active


func get_oil_status() -> String:

    if oil_level <= 0.0:
        return "NO OIL"

    if pressure_warning_active:
        return "LOW PRESSURE"

    if oil_temperature >= maximum_oil_temperature:
        return "OVERHEATED"

    if is_oil_level_low():
        return "LOW OIL"

    return "NORMAL"
