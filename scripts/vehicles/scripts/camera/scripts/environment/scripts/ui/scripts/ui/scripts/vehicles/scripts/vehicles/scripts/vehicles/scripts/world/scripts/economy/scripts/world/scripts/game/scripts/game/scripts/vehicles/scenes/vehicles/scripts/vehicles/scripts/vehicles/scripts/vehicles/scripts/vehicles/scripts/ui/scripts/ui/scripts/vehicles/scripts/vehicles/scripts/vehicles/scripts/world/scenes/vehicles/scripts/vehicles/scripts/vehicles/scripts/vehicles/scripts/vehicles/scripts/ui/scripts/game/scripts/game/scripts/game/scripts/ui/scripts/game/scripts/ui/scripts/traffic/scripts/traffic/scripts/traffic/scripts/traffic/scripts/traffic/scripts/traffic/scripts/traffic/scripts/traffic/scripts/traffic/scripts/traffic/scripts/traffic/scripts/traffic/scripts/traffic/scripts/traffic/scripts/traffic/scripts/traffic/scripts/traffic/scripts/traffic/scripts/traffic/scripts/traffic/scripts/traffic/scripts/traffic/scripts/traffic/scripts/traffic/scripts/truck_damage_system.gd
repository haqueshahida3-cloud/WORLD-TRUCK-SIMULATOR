extends Node
class_name TruckDamageSystem

signal damage_changed(component: String, damage: float)
signal vehicle_condition_changed(condition: float)
signal repair_completed(cost: float)
signal critical_damage(component: String)

@export_group("References")
@export var truck: VehicleBody3D
@export var wallet: Node

@export_group("Damage Settings")
@export var engine_damage := 0.0
@export var body_damage := 0.0
@export var wheel_damage := 0.0

@export_group("Repair Prices")
@export var engine_repair_price := 100.0
@export var body_repair_price := 50.0
@export var wheel_repair_price := 75.0

var maximum_damage := 100.0


func apply_damage(component: String, amount: float) -> void:
    if amount <= 0.0:
        return

    var key := component.to_lower()

    match key:
        "engine":
            engine_damage = clampf(engine_damage + amount, 0.0, maximum_damage)
        "body":
            body_damage = clampf(body_damage + amount, 0.0, maximum_damage)
        "wheel":
            wheel_damage = clampf(wheel_damage + amount, 0.0, maximum_damage)
        _:
            return

    damage_changed.emit(key, get_component_damage(key))

    if get_component_damage(key) >= 80.0:
        critical_damage.emit(key)

    vehicle_condition_changed.emit(get_vehicle_condition())


func get_component_damage(component: String) -> float:
    match component.to_lower():
        "engine":
            return engine_damage
        "body":
            return body_damage
        "wheel":
            return wheel_damage
    return 0.0


func get_vehicle_condition() -> float:
    var total_damage := (engine_damage + body_damage + wheel_damage) / 3.0
    return 100.0 - total_damage


func get_repair_cost(component: String) -> float:
    match component.to_lower():
        "engine":
            return engine_damage * engine_repair_price
        "body":
            return body_damage * body_repair_price
        "wheel":
            return wheel_damage * wheel_repair_price
        "all":
            return (
                get_repair_cost("engine")
                + get_repair_cost("body")
                + get_repair_cost("wheel")
            )
    return 0.0


func repair_component(component: String) -> bool:
    var key := component.to_lower()
    var cost := get_repair_cost(key)

    if cost <= 0.0:
        return false

    if not is_instance_valid(wallet):
        return false

    if not wallet.has_method("spend_money"):
        return false

    if not wallet.spend_money(cost, "Truck Repair: " + key):
        return false

    match key:
        "engine":
            engine_damage = 0.0
        "body":
            body_damage = 0.0
        "wheel":
            wheel_damage = 0.0
        _:
            return false

    damage_changed.emit(key, 0.0)
    vehicle_condition_changed.emit(get_vehicle_condition())
    repair_completed.emit(cost)

    return true


func repair_all() -> bool:
    var cost := get_repair_cost("all")

    if cost <= 0.0:
        return false

    if not is_instance_valid(wallet):
        return false

    if not wallet.has_method("spend_money"):
        return false

    if not wallet.spend_money(cost, "Complete Truck Repair"):
        return false

    engine_damage = 0.0
    body_damage = 0.0
    wheel_damage = 0.0

    damage_changed.emit("engine", 0.0)
    damage_changed.emit("body", 0.0)
    damage_changed.emit("wheel", 0.0)

    vehicle_condition_changed.emit(get_vehicle_condition())
    repair_completed.emit(cost)

    return true
