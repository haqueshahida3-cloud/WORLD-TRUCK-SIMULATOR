extends Node3D
class_name SmartIntersectionAI

signal phase_changed(phase_name: String)
signal intersection_locked
signal intersection_unlocked

enum Phase {
    NORTH_SOUTH_GREEN,
    NORTH_SOUTH_YELLOW,
    EAST_WEST_GREEN,
    EAST_WEST_YELLOW,
    ALL_RED
}

@export_group("Traffic Timing")
@export var green_duration: float = 20.0
@export var yellow_duration: float = 3.0
@export var all_red_duration: float = 2.0

@export_group("Signal References")
@export var north_signal: Node
@export var south_signal: Node
@export var east_signal: Node
@export var west_signal: Node

@export_group("Intersection Settings")
@export var automatic_mode: bool = true
@export var start_phase: Phase = Phase.NORTH_SOUTH_GREEN

@export_group("Safety")
@export var maximum_vehicles_inside: int = 2
@export var vehicle_detection_radius: float = 35.0

var current_phase: Phase
var phase_timer: float = 0.0

var intersection_is_locked: bool = false

var vehicles_inside: Array[Node3D] = []
var north_south_queue: Array[Node3D] = []
var east_west_queue: Array[Node3D] = []


func _ready() -> void:

    add_to_group("smart_intersections")

    current_phase = start_phase

    _apply_phase()
    refresh_intersection()


func _process(delta: float) -> void:

    _remove_invalid_vehicles()

    if not automatic_mode:
        return

    phase_timer += delta

    match current_phase:

        Phase.NORTH_SOUTH_GREEN:
            if phase_timer >= green_duration:
                set_phase(Phase.NORTH_SOUTH_YELLOW)

        Phase.NORTH_SOUTH_YELLOW:
            if phase_timer >= yellow_duration:
                set_phase(Phase.ALL_RED)

        Phase.ALL_RED:
            if phase_timer >= all_red_duration:
                if _has_north_south_traffic():
                    set_phase(Phase.EAST_WEST_GREEN)
                else:
                    set_phase(Phase.EAST_WEST_GREEN)

        Phase.EAST_WEST_GREEN:
            if phase_timer >= green_duration:
                set_phase(Phase.EAST_WEST_YELLOW)

        Phase.EAST_WEST_YELLOW:
            if phase_timer >= yellow_duration:
                set_phase(Phase.ALL_RED)


# ============================================================
# PHASE MANAGEMENT
# ============================================================

func set_phase(new_phase: Phase) -> void:

    if current_phase == new_phase:
        return

    current_phase = new_phase
    phase_timer = 0.0

    _apply_phase()

    phase_changed.emit(
        _get_phase_name(current_phase)
    )


func _get_phase_name(phase: Phase) -> String:

    match phase:

        Phase.NORTH_SOUTH_GREEN:
            return "NORTH_SOUTH_GREEN"

        Phase.NORTH_SOUTH_YELLOW:
            return "NORTH_SOUTH_YELLOW"

        Phase.EAST_WEST_GREEN:
            return "EAST_WEST_GREEN"

        Phase.EAST_WEST_YELLOW:
            return "EAST_WEST_YELLOW"

        Phase.ALL_RED:
            return "ALL_RED"

    return "UNKNOWN"


# ============================================================
# APPLY SIGNALS
# ============================================================

func _apply_phase() -> void:

    var ns_green := (
        current_phase == Phase.NORTH_SOUTH_GREEN
    )

    var ns_yellow := (
        current_phase == Phase.NORTH_SOUTH_YELLOW
    )

    var ew_green := (
        current_phase == Phase.EAST_WEST_GREEN
    )

    var ew_yellow := (
        current_phase == Phase.EAST_WEST_YELLOW
    )

    _set_signal(north_signal, ns_green, ns_yellow)
    _set_signal(south_signal, ns_green, ns_yellow)

    _set_signal(east_signal, ew_green, ew_yellow)
    _set_signal(west_signal, ew_green, ew_yellow)

    _update_vehicle_permissions()


func _set_signal(
    signal_node: Node,
    green: bool,
    yellow: bool
) -> void:

    if not is_instance_valid(signal_node):
        return

    if not signal_node.has_method("set_signal_state"):
        return

    if green:
        signal_node.set_signal_state(2)

    elif yellow:
        signal_node.set_signal_state(1)

    else:
        signal_node.set_signal_state(0)


# ============================================================
# VEHICLE DETECTION
# ============================================================

func refresh_intersection() -> void:

    north_south_queue.clear()
    east_west_queue.clear()

    var vehicles := get_tree().get_nodes_in_group(
        "traffic_vehicles"
    )

    for node in vehicles:

        if not node is Node3D:
            continue

        var vehicle := node as Node3D

        var distance := global_position.distance_to(
            vehicle.global_position
        )

        if distance > vehicle_detection_radius:
            continue

        var relative := (
            vehicle.global_position - global_position
        )

        if absf(relative.z) > absf(relative.x):
            north_south_queue.append(vehicle)
        else:
            east_west_queue.append(vehicle)


# ============================================================
# VEHICLE PERMISSIONS
# ============================================================

func _update_vehicle_permissions() -> void:

    refresh_intersection()

    var ns_allowed := (
        current_phase == Phase.NORTH_SOUTH_GREEN
    )

    var ew_allowed := (
        current_phase == Phase.EAST_WEST_GREEN
    )

    for vehicle in north_south_queue:
        _set_vehicle_permission(vehicle, ns_allowed)

    for vehicle in east_west_queue:
        _set_vehicle_permission(vehicle, ew_allowed)


func _set_vehicle_permission(
    vehicle: Node3D,
    allowed: bool
) -> void:

    if not is_instance_valid(vehicle):
        return

    if vehicle.has_method("set_intersection_permission"):
        vehicle.set_intersection_permission(allowed)


# ============================================================
# INTERSECTION LOCK
# ============================================================

func request_entry(vehicle: Node3D) -> bool:

    if not is_instance_valid(vehicle):
        return false

    if intersection_is_locked:
        return false

    if vehicles_inside.size() >= maximum_vehicles_inside:
        return false

    if vehicle in vehicles_inside:
        return true

    vehicles_inside.append(vehicle)

    if vehicles_inside.size() >= maximum_vehicles_inside:
        intersection_is_locked = true
        intersection_locked.emit()

    return true


func release_vehicle(vehicle: Node3D) -> void:

    vehicles_inside.erase(vehicle)

    if vehicles_inside.size() < maximum_vehicles_inside:

        if intersection_is_locked:
            intersection_is_locked = false
            intersection_unlocked.emit()


func _remove_invalid_vehicles() -> void:

    for i in range(vehicles_inside.size() - 1, -1, -1):

        if not is_instance_valid(vehicles_inside[i]):
            vehicles_inside.remove_at(i)

    if vehicles_inside.size() < maximum_vehicles_inside:
        intersection_is_locked = false


# ============================================================
# TRAFFIC PRIORITY
# ============================================================

func _has_north_south_traffic() -> bool:

    refresh_intersection()

    return not north_south_queue.is_empty()


func get_north_south_queue_count() -> int:
    refresh_intersection()
    return north_south_queue.size()


func get_east_west_queue_count() -> int:
    refresh_intersection()
    return east_west_queue.size()


func get_current_phase() -> String:
    return _get_phase_name(current_phase)


func set_automatic_mode(enabled: bool) -> void:
    automatic_mode = enabled


func force_all_red() -> void:
    set_phase(Phase.ALL_RED)
