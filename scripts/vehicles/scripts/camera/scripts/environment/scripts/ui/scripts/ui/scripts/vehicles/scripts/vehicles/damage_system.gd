extends Node
class_name TruckDamageSystem

@export_group("Damage Settings")
@export var max_damage: float = 100.0
@export var collision_damage_multiplier: float = 0.08
@export var minimum_impact_speed: float = 3.0

@export_group("Damage Components")
@export var engine_damage_multiplier: float = 0.5
@export var body_damage_multiplier: float = 1.0
@export var wheel_damage_multiplier: float = 0.3

@export_group("Repair")
@export var repair_cost_per_percent: float = 100.0

var truck: VehicleBody3D

var total_damage: float = 0.0
var engine_damage: float = 0.0
var body_damage: float = 0.0
var wheel_damage: float = 0.0

var last_impact_speed: float = 0.0
var damage_enabled: bool = true


func _ready() -> void:
    _find_truck()


func _physics_process(_delta: float) -> void:
    if not is_instance_valid(truck):
        _find_truck()


func _find_truck() -> void:
    var trucks := get_tree().get_nodes_in_group("player")

    if not trucks.is_empty():
        truck = trucks[0] as VehicleBody3D


# ============================================================
# COLLISION DAMAGE
# ============================================================

func apply_collision_damage(
    impact_speed: float,
    impact_strength: float = 1.0
) -> void:

    if not damage_enabled:
        return

    if impact_speed < minimum_impact_speed:
        return

    last_impact_speed = impact_speed

    var damage := (
        impact_speed *
        collision_damage_multiplier *
        impact_strength
    )

    damage = clampf(damage, 0.0, max_damage)

    _apply_damage(damage)


func _apply_damage(amount: float) -> void:

    if amount <= 0.0:
        return

    body_damage = clampf(
        body_damage + amount * body_damage_multiplier,
        0.0,
        max_damage
    )

    engine_damage = clampf(
        engine_damage + amount * engine_damage_multiplier,
        0.0,
        max_damage
    )

    wheel_damage = clampf(
        wheel_damage + amount * wheel_damage_multiplier,
        0.0,
        max_damage
    )

    _update_total_damage()
    _apply_vehicle_effects()


func _update_total_damage() -> void:

    total_damage = (
        body_damage +
        engine_damage +
        wheel_damage
    ) / 3.0


# ============================================================
# VEHICLE EFFECTS
# ============================================================

func _apply_vehicle_effects() -> void:

    if not is_instance_valid(truck):
        return

    if truck is Truck:
        var vehicle := truck as Truck

        var engine_condition := 1.0 - engine_damage / max_damage

        vehicle.max_engine_force = 4000.0 * engine_condition

        if engine_damage >= max_damage:
            vehicle.engine_on = false


# ============================================================
# REPAIR SYSTEM
# ============================================================

func repair_all() -> float:

    var cost := total_damage * repair_cost_per_percent

    body_damage = 0.0
    engine_damage = 0.0
    wheel_damage = 0.0
    total_damage = 0.0

    if is_instance_valid(truck) and truck is Truck:
        var vehicle := truck as Truck
        vehicle.engine_on = true
        vehicle.max_engine_force = 4000.0

    return cost


func repair_engine() -> float:

    var cost := engine_damage * repair_cost_per_percent

    engine_damage = 0.0
    _update_total_damage()
    _apply_vehicle_effects()

    return cost


func repair_body() -> float:

    var cost := body_damage * repair_cost_per_percent

    body_damage = 0.0
    _update_total_damage()

    return cost


func repair_wheels() -> float:

    var cost := wheel_damage * repair_cost_per_percent

    wheel_damage = 0.0
    _update_total_damage()

    return cost


# ============================================================
# DAMAGE INFORMATION
# ============================================================

func get_damage_percentage() -> float:
    return total_damage


func get_engine_condition() -> float:
    return 100.0 - engine_damage


func get_body_condition() -> float:
    return 100.0 - body_damage


func get_wheel_condition() -> float:
    return 100.0 - wheel_damage


func is_critical_damage() -> bool:
    return total_damage >= 75.0


func set_damage_enabled(enabled: bool) -> void:
    damage_enabled = enabled
