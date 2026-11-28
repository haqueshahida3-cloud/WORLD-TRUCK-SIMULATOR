extends Node3D
class_name TrafficIntersectionAI

signal vehicle_entered(vehicle: TrafficVehicleAI)
signal vehicle_exited(vehicle: TrafficVehicleAI)
signal intersection_blocked

@export_group("Intersection Settings")
@export var intersection_name: String = "Intersection 01"
@export var maximum_vehicles: int = 1
@export var entry_distance: float = 12.0
@export var exit_distance: float = 18.0

@export_group("Traffic Light")
@export var traffic_light: TrafficLightAI

@export_group("Intersection Control")
@export var automatic_control: bool = true
@export var allow_multiple_vehicles: bool = false

var approaching_vehicles: Array[TrafficVehicleAI] = []
var vehicles_inside: Array[TrafficVehicleAI] = []

var intersection_locked: bool = false


func _ready() -> void:

    add_to_group("traffic_intersections")

    _find_traffic_light()


func _physics_process(_delta: float) -> void:

    _remove_invalid_vehicles()

    if not automatic_control:
        return

    _update_intersection()


# ============================================================
# FIND REFERENCES
# ============================================================

func _find_traffic_light() -> void:

    if not is_instance_valid(traffic_light):

        var lights := get_tree().get_nodes_in_group(
            "traffic_lights"
        )

        if not lights.is_empty():
            traffic_light = lights[0] as TrafficLightAI


# ============================================================
# REGISTER APPROACHING VEHICLES
# ============================================================

func register_approaching_vehicle(
    vehicle: TrafficVehicleAI
) -> void:

    if not is_instance_valid(vehicle):
        return

    if approaching_vehicles.has(vehicle):
        return

    approaching_vehicles.append(vehicle)


func unregister_approaching_vehicle(
    vehicle: TrafficVehicleAI
) -> void:

    approaching_vehicles.erase(vehicle)


# ============================================================
# INTERSECTION ENTRY
# ============================================================

func request_entry(
    vehicle: TrafficVehicleAI
) -> bool:

    if not is_instance_valid(vehicle):
        return false

    if vehicles_inside.has(vehicle):
        return true

    if intersection_locked:
        return false

    if not allow_multiple_vehicles:

        if not vehicles_inside.is_empty():
            intersection_blocked.emit()
            return false

    elif vehicles_inside.size() >= maximum_vehicles:

        intersection_blocked.emit()
        return false

    if is_instance_valid(traffic_light):

        if traffic_light.current_state != TrafficLightAI.LightState.GREEN:
            return false

    vehicles_inside.append(vehicle)

    approaching_vehicles.erase(vehicle)

    intersection_locked = true

    vehicle_entered.emit(vehicle)

    return true


# ============================================================
# INTERSECTION EXIT
# ============================================================

func report_vehicle_exit(
    vehicle: TrafficVehicleAI
) -> void:

    if not is_instance_valid(vehicle):
        return

    if not vehicles_inside.has(vehicle):
        return

    vehicles_inside.erase(vehicle)

    intersection_locked = not vehicles_inside.is_empty()

    vehicle_exited.emit(vehicle)


# ============================================================
# AUTOMATIC INTERSECTION UPDATE
# ============================================================

func _update_intersection() -> void:

    if vehicles_inside.is_empty():
        intersection_locked = false

    if approaching_vehicles.is_empty():
        return

    if intersection_locked:
        return

    var vehicle := approaching_vehicles[0]

    if not is_instance_valid(vehicle):
        approaching_vehicles.erase(vehicle)
        return

    var distance := global_position.distance_to(
        vehicle.global_position
    )

    if distance <= entry_distance:

        if request_entry(vehicle):
            vehicle.set_intersection_permission(true)


# ============================================================
# VEHICLE POSITION CHECK
# ============================================================

func update_vehicle_position(
    vehicle: TrafficVehicleAI
) -> void:

    if not is_instance_valid(vehicle):
        return

    if not vehicles_inside.has(vehicle):
        return

    var distance := global_position.distance_to(
        vehicle.global_position
    )

    if distance >= exit_distance:
        vehicle.set_intersection_permission(false)
        report_vehicle_exit(vehicle)


# ============================================================
# CLEANUP
# ============================================================

func _remove_invalid_vehicles() -> void:

    for i in range(approaching_vehicles.size() - 1, -1, -1):

        if not is_instance_valid(approaching_vehicles[i]):
            approaching_vehicles.remove_at(i)

    for i in range(vehicles_inside.size() - 1, -1, -1):

        if not is_instance_valid(vehicles_inside[i]):
            vehicles_inside.remove_at(i)

    intersection_locked = not vehicles_inside.is_empty()


# ============================================================
# INFORMATION
# ============================================================

func is_intersection_locked() -> bool:
    return intersection_locked


func get_vehicle_count() -> int:
    return vehicles_inside.size()


func get_waiting_vehicle_count() -> int:
    return approaching_vehicles.size()


func clear_intersection() -> void:

    for vehicle in vehicles_inside:

        if is_instance_valid(vehicle):
            vehicle.set_intersection_permission(false)

    vehicles_inside.clear()
    approaching_vehicles.clear()

    intersection_locked = false
