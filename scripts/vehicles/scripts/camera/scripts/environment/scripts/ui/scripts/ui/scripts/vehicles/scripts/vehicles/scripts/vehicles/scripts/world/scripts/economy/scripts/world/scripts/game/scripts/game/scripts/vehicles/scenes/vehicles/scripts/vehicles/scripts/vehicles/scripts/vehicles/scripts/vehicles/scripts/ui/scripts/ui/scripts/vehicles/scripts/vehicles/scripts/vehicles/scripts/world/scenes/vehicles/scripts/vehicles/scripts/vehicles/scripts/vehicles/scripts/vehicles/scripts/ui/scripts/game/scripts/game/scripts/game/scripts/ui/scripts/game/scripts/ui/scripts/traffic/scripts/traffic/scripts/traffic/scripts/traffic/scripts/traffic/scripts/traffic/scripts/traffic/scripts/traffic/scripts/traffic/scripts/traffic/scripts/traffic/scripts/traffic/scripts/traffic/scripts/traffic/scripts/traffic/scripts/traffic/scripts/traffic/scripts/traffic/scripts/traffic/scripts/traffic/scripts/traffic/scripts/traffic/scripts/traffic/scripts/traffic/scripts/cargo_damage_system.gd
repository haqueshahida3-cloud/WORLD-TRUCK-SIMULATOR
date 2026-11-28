extends Node
class_name CargoDamageSystem

signal cargo_damage_changed(damage: float)
signal cargo_damaged(cargo_name: String, damage: float)
signal cargo_destroyed(cargo_name: String)

@export_group("References")
@export var truck: VehicleBody3D
@export var wallet: Node

@export_group("Damage Settings")
@export var collision_damage_multiplier := 0.02
@export var rough_road_damage_multiplier := 0.01
@export var maximum_damage := 100.0

var cargo_name := "General Cargo"
var cargo_type := "General"
var cargo_fragile := false
var cargo_damage := 0.0
var cargo_value := 5000.0
var last_speed := 0.0


func _physics_process(delta):
    if not is_instance_valid(truck):
        return

    var current_speed := truck.linear_velocity.length()

    var acceleration := absf(
        current_speed - last_speed
    ) / maxf(delta, 0.001)

    last_speed = current_speed

    if cargo_fragile and acceleration > 8.0:
        apply_damage(
            (acceleration - 8.0) *
            rough_road_damage_multiplier * delta
        )


func set_cargo(
    name: String,
    type: String,
    value: float,
    fragile: bool = false
):
    cargo_name = name
    cargo_type = type
    cargo_value = maxf(value, 0.0)
    cargo_fragile = fragile
    cargo_damage = 0.0
    last_speed = 0.0


func apply_collision_damage(impact_speed: float):
    if impact_speed <= 5.0:
        return

    var damage := (
        impact_speed - 5.0
    ) * collision_damage_multiplier

    if cargo_fragile:
        damage *= 2.0

    apply_damage(damage)


func apply_rough_road_damage(amount: float):
    if not cargo_fragile:
        return

    apply_damage(
        amount * rough_road_damage_multiplier
    )


func apply_damage(amount: float):
    if amount <= 0.0 or cargo_damage >= maximum_damage:
        return

    var actual_damage := minf(
        amount,
        maximum_damage - cargo_damage
    )

    cargo_damage += actual_damage

    cargo_damage_changed.emit(cargo_damage)
    cargo_damaged.emit(cargo_name, cargo_damage)

    if cargo_damage >= maximum_damage:
        cargo_destroyed.emit(cargo_name)


func get_cargo_condition() -> float:
    return 100.0 - cargo_damage


func get_delivery_reward() -> float:
    return cargo_value * (
        get_cargo_condition() / 100.0
    )


func get_damage_level() -> String:
    if cargo_damage >= 75.0:
        return "Critical"

    if cargo_damage >= 40.0:
        return "Heavy"

    if cargo_damage >= 10.0:
        return "Minor"

    return "Good"


func reset_cargo_damage():
    cargo_damage = 0.0
    last_speed = 0.0
    cargo_damage_changed.emit(cargo_damage)
