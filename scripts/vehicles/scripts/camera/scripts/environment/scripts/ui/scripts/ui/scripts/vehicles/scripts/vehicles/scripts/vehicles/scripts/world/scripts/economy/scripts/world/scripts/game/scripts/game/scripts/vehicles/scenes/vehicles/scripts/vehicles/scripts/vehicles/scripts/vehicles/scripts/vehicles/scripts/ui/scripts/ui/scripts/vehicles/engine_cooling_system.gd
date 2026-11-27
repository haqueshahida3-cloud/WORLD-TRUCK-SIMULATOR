extends Node
class_name EngineCoolingSystem

signal temperature_changed(temperature: float)
signal engine_overheated
signal cooling_fan_changed(active: bool)
signal coolant_low

@export_group("Temperature")
@export var ambient_temperature: float = 25.0
@export var starting_temperature: float = 35.0
@export var normal_temperature: float = 90.0
@export var warning_temperature: float = 105.0
@export var critical_temperature: float = 120.0

@export_group("Engine Heat")
@export var idle_heat_rate: float = 0.8
@export var driving_heat_rate: float = 0.025
@export var maximum_heat_rate: float = 15.0

@export_group("Cooling System")
@export var radiator_cooling: float = 0.12
@export var fan_cooling: float = 0.18
@export var fan_start_temperature: float = 95.0
@export var fan_stop_temperature: float = 88.0

@export_group("Coolant")
@export var coolant_capacity: float = 20.0
@export var starting_coolant: float = 20.0

@export_group("Vehicle")
@export var truck: VehicleBody3D

var engine_temperature: float = 35.0
var coolant_level: float = 20.0

var cooling_fan_active: bool = false
var overheating: bool = false
var engine_was_running: bool = false


func _ready() -> void:
    add_to_group("engine_cooling_system")

    engine_temperature = starting_temperature
    coolant_level = starting_coolant

    _find_truck()


func _physics_process(delta: float) -> void:

    if not is_instance_valid(truck):
        _find_truck()
        return

    _update_cooling_fan()
    _update_engine_temperature(delta)
    _check_overheating()


func _find_truck() -> void:

    var trucks := get_tree().get_nodes_in_group("player")

    if not trucks.is_empty():
        truck = trucks[0] as VehicleBody3D


# ============================================================
# ENGINE HEAT
# ============================================================

func _update_engine_temperature(delta: float) -> void:

    var engine_running := false

    if truck.has_method("get"):
        engine_running = bool(truck.get("engine_on"))

    if engine_running:

        var speed := truck.linear_velocity.length()

        var heat := idle_heat_rate
        heat += speed * driving_heat_rate

        heat = minf(heat, maximum_heat_rate)

        engine_temperature += heat * delta

        engine_was_running = true

    else:

        engine_temperature -= 0.4 * delta
        engine_was_running = false

    _apply_cooling(delta)

    engine_temperature = maxf(
        engine_temperature,
        ambient_temperature
    )

    temperature_changed.emit(engine_temperature)


# ============================================================
# RADIATOR COOLING
# ============================================================

func _apply_cooling(delta: float) -> void:

    var cooling_rate := radiator_cooling

    if cooling_fan_active:
        cooling_rate += fan_cooling

    if coolant_level <= 0.0:
        cooling_rate *= 0.1

    var difference := engine_temperature - ambient_temperature

    if difference > 0.0:
        engine_temperature -= difference * cooling_rate * delta


# ============================================================
# COOLING FAN
# ============================================================

func _update_cooling_fan() -> void:

    var previous_state := cooling_fan_active

    if engine_temperature >= fan_start_temperature:
        cooling_fan_active = true

    elif engine_temperature <= fan_stop_temperature:
        cooling_fan_active = false

    if previous_state != cooling_fan_active:
        cooling_fan_changed.emit(cooling_fan_active)


# ============================================================
# OVERHEATING PROTECTION
# ============================================================

func _check_overheating() -> void:

    if engine_temperature >= critical_temperature:

        if not overheating:
            overheating = true
            engine_overheated.emit()

        if truck.has_method("set"):
            truck.set("engine_on", false)

    elif engine_temperature < warning_temperature:
        overheating = false


func is_engine_overheated() -> bool:
    return overheating


func is_temperature_warning() -> bool:
    return engine_temperature >= warning_temperature


# ============================================================
# COOLANT
# ============================================================

func add_coolant(amount: float) -> float:

    if amount <= 0.0:
        return 0.0

    var added := minf(
        amount,
        coolant_capacity - coolant_level
    )

    coolant_level += added

    return added


func drain_coolant(amount: float) -> void:

    if amount <= 0.0:
        return

    coolant_level = maxf(
        coolant_level - amount,
        0.0
    )

    if coolant_level <= 2.0:
        coolant_low.emit()


func get_coolant_percentage() -> float:
    return (coolant_level / coolant_capacity) * 100.0


func get_coolant_level() -> float:
    return coolant_level


# ============================================================
# INFORMATION
# ============================================================

func get_engine_temperature() -> float:
    return engine_temperature


func is_cooling_fan_active() -> bool:
    return cooling_fan_active


func get_temperature_status() -> String:

    if engine_temperature >= critical_temperature:
        return "CRITICAL"

    if engine_temperature >= warning_temperature:
        return "WARNING"

    if engine_temperature >= normal_temperature:
        return "HOT"

    return "NORMAL"
