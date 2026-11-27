extends Node
class_name TruckCollisionDetector

@export_group("Truck")
@export var truck: VehicleBody3D

@export_group("Collision Settings")
@export var minimum_impact_speed: float = 3.0
@export var maximum_impact_speed: float = 35.0
@export var damage_multiplier: float = 0.08
@export var collision_cooldown: float = 0.8

@export_group("Detection")
@export var impact_threshold: float = 2.0

var damage_system: TruckDamageSystem

var previous_velocity: Vector3 = Vector3.ZERO
var cooldown_timer: float = 0.0
var last_impact_strength: float = 0.0


func _ready() -> void:
    _find_references()

    if is_instance_valid(truck):
        previous_velocity = truck.linear_velocity

    if is_instance_valid(truck):
        truck.contact_monitor = true
        truck.max_contacts_reported = 8

    if is_instance_valid(truck):
        truck.body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:

    if cooldown_timer > 0.0:
        cooldown_timer -= delta

    if not is_instance_valid(truck):
        _find_references()

    if not is_instance_valid(truck):
        return

    previous_velocity = truck.linear_velocity


func _find_references() -> void:

    if not is_instance_valid(truck):
        var trucks := get_tree().get_nodes_in_group("player")

        if not trucks.is_empty():
            truck = trucks[0] as VehicleBody3D

    if not is_instance_valid(damage_system):
        var systems := get_tree().get_nodes_in_group("damage_system")

        if not systems.is_empty():
            damage_system = systems[0] as TruckDamageSystem


# ============================================================
# COLLISION EVENT
# ============================================================

func _on_body_entered(_body: Node) -> void:

    if cooldown_timer > 0.0:
        return

    if not is_instance_valid(truck):
        return

    var current_velocity := truck.linear_velocity

    var impact_speed := (
        previous_velocity - current_velocity
    ).length()

    if impact_speed < minimum_impact_speed:
        return

    _process_impact(impact_speed)


# ============================================================
# DAMAGE CALCULATION
# ============================================================

func _process_impact(impact_speed: float) -> void:

    if impact_speed < minimum_impact_speed:
        return

    var normalized_impact := clampf(
        impact_speed / maximum_impact_speed,
        0.0,
        1.0
    )

    last_impact_strength = normalized_impact

    if is_instance_valid(damage_system):
        damage_system.apply_collision_damage(
            impact_speed,
            damage_multiplier
        )

    cooldown_timer = collision_cooldown


# ============================================================
# MANUAL IMPACT
# ============================================================

func register_impact(
    impact_speed: float,
    strength: float = 1.0
) -> void:

    if cooldown_timer > 0.0:
        return

    if is_instance_valid(damage_system):
        damage_system.apply_collision_damage(
            impact_speed,
            strength * damage_multiplier
        )

    cooldown_timer = collision_cooldown


func get_last_impact_strength() -> float:
    return last_impact_strength
