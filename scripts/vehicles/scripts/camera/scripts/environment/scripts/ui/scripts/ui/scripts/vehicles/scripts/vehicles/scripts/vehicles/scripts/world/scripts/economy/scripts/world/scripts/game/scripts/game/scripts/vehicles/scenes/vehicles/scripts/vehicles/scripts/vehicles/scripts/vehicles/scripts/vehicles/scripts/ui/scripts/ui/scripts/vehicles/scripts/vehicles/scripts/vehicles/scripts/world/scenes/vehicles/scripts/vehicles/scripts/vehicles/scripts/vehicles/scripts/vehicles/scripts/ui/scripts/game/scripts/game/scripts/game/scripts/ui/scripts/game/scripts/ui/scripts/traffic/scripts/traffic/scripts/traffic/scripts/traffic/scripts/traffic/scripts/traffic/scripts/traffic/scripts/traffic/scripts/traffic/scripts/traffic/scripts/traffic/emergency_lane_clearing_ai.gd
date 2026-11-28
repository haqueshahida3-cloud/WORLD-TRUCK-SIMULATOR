extends Node
class_name EmergencyLaneClearingAI

signal yielding_started(emergency_vehicle: Node3D)
signal yielding_completed

@export_group("References")
@export var vehicle: TrafficVehicleAI

@export_group("Detection")
@export var detection_radius: float = 35.0
@export var release_radius: float = 50.0

@export_group("Settings")
@export var system_enabled: bool = true
@export var stop_for_emergency: bool = true

var yielding: bool = false
var active_emergency: Node3D = null
var previous_ai_state: bool = true


func _ready() -> void:
    add_to_group("emergency_lane_clearing")

    if not is_instance_valid(vehicle):
        if get_parent() is TrafficVehicleAI:
            vehicle = get_parent() as TrafficVehicleAI


func _physics_process(_delta: float) -> void:

    if not system_enabled:
        _restore_vehicle()
        return

    if not is_instance_valid(vehicle):
        return

    if yielding:
        _update_yielding()
        return

    _find_emergency_vehicle()


# ============================================================
# FIND ACTIVE EMERGENCY VEHICLE
# ============================================================

func _find_emergency_vehicle() -> void:

    var emergency_vehicles := get_tree().get_nodes_in_group(
        "emergency_vehicles"
    )

    var nearest: Node3D = null
    var nearest_distance := detection_radius

    for node in emergency_vehicles:

        if not node is Node3D:
            continue

        if not node.has_method("is_emergency_active"):
            continue

        if not node.is_emergency_active():
            continue

        var distance := vehicle.global_position.distance_to(
            node.global_position
        )

        if distance < nearest_distance:
            nearest_distance = distance
            nearest = node as Node3D

    if is_instance_valid(nearest):
        _start_yielding(nearest)


# ============================================================
# START YIELDING
# ============================================================

func _start_yielding(emergency_vehicle: Node3D) -> void:

    if not stop_for_emergency:
        return

    if not is_instance_valid(vehicle):
        return

    active_emergency = emergency_vehicle

    previous_ai_state = vehicle.ai_enabled

    vehicle.ai_enabled = false

    yielding = true

    yielding_started.emit(emergency_vehicle)


# ============================================================
# UPDATE YIELDING
# ============================================================

func _update_yielding() -> void:

    if not is_instance_valid(active_emergency):
        _restore_vehicle()
        return

    var distance := vehicle.global_position.distance_to(
        active_emergency.global_position
    )

    if distance >= release_radius:
        _restore_vehicle()


# ============================================================
# RESTORE NORMAL TRAFFIC
# ============================================================

func _restore_vehicle() -> void:

    if not yielding:
        return

    if is_instance_valid(vehicle):
        vehicle.ai_enabled = previous_ai_state

    yielding = false
    active_emergency = null

    yielding_completed.emit()


# ============================================================
# PUBLIC FUNCTIONS
# ============================================================

func is_yielding() -> bool:
    return yielding


func get_emergency_vehicle() -> Node3D:
    return active_emergency


func enable_system() -> void:
    system_enabled = true


func disable_system() -> void:
    system_enabled = false
    _restore_vehicle()
