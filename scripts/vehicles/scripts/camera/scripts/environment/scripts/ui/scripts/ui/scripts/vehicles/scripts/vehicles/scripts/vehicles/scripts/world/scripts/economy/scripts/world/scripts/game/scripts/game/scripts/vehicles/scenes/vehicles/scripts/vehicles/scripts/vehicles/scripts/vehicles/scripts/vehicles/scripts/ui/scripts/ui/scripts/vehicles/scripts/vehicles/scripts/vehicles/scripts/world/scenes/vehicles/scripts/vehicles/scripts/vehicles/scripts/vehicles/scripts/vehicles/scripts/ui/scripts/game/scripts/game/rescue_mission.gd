extends Node
class_name RescueMission

signal mission_available(mission: Dictionary)
signal mission_started(mission: Dictionary)
signal mission_completed(reward: float)
signal mission_failed(reason: String)
signal mission_progress_changed(progress: float)

@export_group("Mission Settings")
@export var base_reward: float = 5000.0
@export var reward_per_km: float = 250.0
@export var time_limit_minutes: float = 30.0

@export_group("References")
@export var tow_manager: TowTruckManager
@export var wallet: Node

var current_mission: Dictionary = {}
var mission_active: bool = false

var elapsed_time: float = 0.0
var mission_distance: float = 0.0
var completed_missions: int = 0


func _ready() -> void:
    add_to_group("rescue_mission")
    _find_references()


func _process(delta: float) -> void:

    if not mission_active:
        return

    elapsed_time += delta

    if elapsed_time >= time_limit_minutes * 60.0:
        fail_mission("Rescue time limit exceeded.")


func _find_references() -> void:

    if not is_instance_valid(tow_manager):
        tow_manager = get_tree().get_first_node_in_group(
            "tow_truck_manager"
        ) as TowTruckManager

    if not is_instance_valid(wallet):
        wallet = get_tree().get_first_node_in_group(
            "wallet_system"
        )


# ============================================================
# CREATE MISSION
# ============================================================

func create_mission(
    rescue_name: String,
    pickup_position: Vector3,
    delivery_position: Vector3
) -> Dictionary:

    var distance := pickup_position.distance_to(
        delivery_position
    ) / 1000.0

    current_mission = {
        "name": rescue_name,
        "pickup": pickup_position,
        "destination": delivery_position,
        "distance_km": distance,
        "reward": base_reward + distance * reward_per_km,
        "time_limit": time_limit_minutes,
        "status": "available"
    }

    mission_available.emit(current_mission)

    return current_mission.duplicate(true)


# ============================================================
# START MISSION
# ============================================================

func start_mission() -> bool:

    if mission_active:
        return false

    if current_mission.is_empty():
        return false

    if not is_instance_valid(tow_manager):
        _find_references()

    if not is_instance_valid(tow_manager):
        return false

    if not tow_manager.is_system_ready():
        return false

    mission_active = true
    elapsed_time = 0.0
    mission_distance = 0.0

    current_mission["status"] = "active"

    mission_started.emit(current_mission)

    return true


# ============================================================
# RESCUE VEHICLE
# ============================================================

func rescue_vehicle(vehicle: RigidBody3D) -> bool:

    if not mission_active:
        return false

    if not is_instance_valid(vehicle):
        return false

    if not is_instance_valid(tow_manager):
        return false

    return tow_manager.attach_vehicle(vehicle)


# ============================================================
# DELIVERY CHECK
# ============================================================

func check_delivery() -> bool:

    if not mission_active:
        return false

    if not is_instance_valid(tow_manager):
        return false

    if not tow_manager.is_vehicle_attached():
        return false

    var vehicle := tow_manager.get_attached_vehicle()

    if not is_instance_valid(vehicle):
        return false

    var destination: Vector3 = current_mission["destination"]

    var distance := vehicle.global_position.distance_to(
        destination
    )

    if distance > 12.0:
        return false

    complete_mission()

    return true


# ============================================================
# COMPLETE MISSION
# ============================================================

func complete_mission() -> void:

    if not mission_active:
        return

    if not is_instance_valid(wallet):
        _find_references()

    if not is_instance_valid(wallet):
        return

    var reward := float(current_mission.get("reward", base_reward))

    if not wallet.add_money(reward, "Truck Rescue Mission"):
        return

    if is_instance_valid(tow_manager):
        tow_manager.detach_vehicle()

    mission_active = false
    current_mission["status"] = "completed"

    completed_missions += 1

    mission_completed.emit(reward)


# ============================================================
# FAIL MISSION
# ============================================================

func fail_mission(reason: String) -> void:

    if not mission_active:
        return

    if is_instance_valid(tow_manager):
        tow_manager.detach_vehicle()

    mission_active = false
    current_mission["status"] = "failed"

    mission_failed.emit(reason)


# ============================================================
# PROGRESS
# ============================================================

func get_time_remaining() -> float:

    if not mission_active:
        return 0.0

    return maxf(
        time_limit_minutes * 60.0 - elapsed_time,
        0.0
    )


func get_mission_reward() -> float:
    return float(current_mission.get("reward", 0.0))


func get_completed_missions() -> int:
    return completed_missions


func is_mission_active() -> bool:
    return mission_active


func cancel_mission() -> void:

    if not mission_active:
        return

    if is_instance_valid(tow_manager):
        tow_manager.detach_vehicle()

    mission_active = false
    current_mission["status"] = "cancelled"
