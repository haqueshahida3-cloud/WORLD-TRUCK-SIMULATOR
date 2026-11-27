extends Node
class_name MissionManager

signal mission_started(mission: Dictionary)
signal mission_completed(reward: float)
signal mission_failed(reason: String)
signal delivery_progress_changed(progress: float)

@export_group("Mission Settings")
@export var minimum_reward: float = 2000.0
@export var reward_per_km: float = 150.0
@export var damage_penalty: float = 0.5
@export var time_limit_enabled: bool = true

var wallet: WalletSystem
var damage_system: TruckDamageSystem
var truck: VehicleBody3D

var current_mission: Dictionary = {}
var mission_active: bool = false
var mission_completed_count: int = 0

var mission_time: float = 0.0
var mission_deadline: float = 0.0
var delivery_distance: float = 0.0
var distance_travelled: float = 0.0


func _ready() -> void:
    add_to_group("mission_manager")
    _find_systems()


func _process(delta: float) -> void:
    if not mission_active:
        return

    mission_time += delta

    if time_limit_enabled and mission_time >= mission_deadline:
        fail_mission("Delivery deadline exceeded")
        return

    _update_distance()


# ============================================================
# FIND SYSTEMS
# ============================================================

func _find_systems() -> void:
    for node in get_tree().get_nodes_in_group("player"):
        if node is VehicleBody3D:
            truck = node as VehicleBody3D
            break

    for node in get_tree().get_nodes_in_group("wallet_system"):
        if node is WalletSystem:
            wallet = node as WalletSystem
            break

    for node in get_tree().get_nodes_in_group("damage_system"):
        if node is TruckDamageSystem:
            damage_system = node as TruckDamageSystem
            break


# ============================================================
# CREATE MISSION
# ============================================================

func create_mission(
    cargo_name: String,
    pickup_location: String,
    destination: String,
    distance_km: float,
    time_limit_minutes: float = 60.0
) -> Dictionary:

    var reward := maxf(
        minimum_reward,
        distance_km * reward_per_km
    )

    return {
        "cargo": cargo_name,
        "pickup": pickup_location,
        "destination": destination,
        "distance_km": distance_km,
        "reward": reward,
        "time_limit": time_limit_minutes
    }


# ============================================================
# START MISSION
# ============================================================

func start_mission(mission: Dictionary) -> bool:

    if mission_active:
        return false

    if mission.is_empty():
        return false

    if not mission.has_all([
        "cargo",
        "pickup",
        "destination",
        "distance_km",
        "reward",
        "time_limit"
    ]):
        return false

    _find_systems()

    if not is_instance_valid(truck):
        return false

    current_mission = mission.duplicate(true)

    mission_active = true
    mission_time = 0.0
    distance_travelled = 0.0

    delivery_distance = maxf(
        float(current_mission["distance_km"]) * 1000.0,
        1.0
    )

    mission_deadline = maxf(
        float(current_mission["time_limit"]) * 60.0,
        1.0
    )

    mission_started.emit(current_mission)

    return true


# ============================================================
# DISTANCE TRACKING
# ============================================================

func _update_distance() -> void:

    if not is_instance_valid(truck):
        return

    distance_travelled += (
        truck.linear_velocity.length() *
        get_process_delta_time()
    )

    var progress := clampf(
        distance_travelled / delivery_distance,
        0.0,
        1.0
    )

    delivery_progress_changed.emit(progress)


# ============================================================
# COMPLETE MISSION
# ============================================================

func complete_mission() -> bool:

    if not mission_active:
        return false

    _find_systems()

    if not is_instance_valid(wallet):
        return false

    var reward := float(current_mission["reward"])

    if is_instance_valid(damage_system):
        var penalty := (
            reward *
            damage_system.get_damage_percentage() /
            100.0 *
            damage_penalty
        )

        reward = maxf(reward - penalty, 0.0)

    wallet.add_money(reward, "Cargo Delivery")

    mission_active = false
    mission_completed_count += 1

    current_mission.clear()

    mission_completed.emit(reward)

    return true


# ============================================================
# FAIL MISSION
# ============================================================

func fail_mission(reason: String) -> void:

    if not mission_active:
        return

    mission_active = false
    current_mission.clear()

    mission_failed.emit(reason)


# ============================================================
# MISSION INFORMATION
# ============================================================

func get_mission_progress() -> float:

    if not mission_active or delivery_distance <= 0.0:
        return 0.0

    return clampf(
        distance_travelled / delivery_distance,
        0.0,
        1.0
    )


func get_remaining_time() -> float:

    if not mission_active:
        return 0.0

    return maxf(mission_deadline - mission_time, 0.0)


func get_current_reward() -> float:

    if not mission_active:
        return 0.0

    return float(current_mission["reward"])


func get_completed_missions() -> int:
    return mission_completed_count


func cancel_mission() -> void:
    fail_mission("Mission cancelled")
