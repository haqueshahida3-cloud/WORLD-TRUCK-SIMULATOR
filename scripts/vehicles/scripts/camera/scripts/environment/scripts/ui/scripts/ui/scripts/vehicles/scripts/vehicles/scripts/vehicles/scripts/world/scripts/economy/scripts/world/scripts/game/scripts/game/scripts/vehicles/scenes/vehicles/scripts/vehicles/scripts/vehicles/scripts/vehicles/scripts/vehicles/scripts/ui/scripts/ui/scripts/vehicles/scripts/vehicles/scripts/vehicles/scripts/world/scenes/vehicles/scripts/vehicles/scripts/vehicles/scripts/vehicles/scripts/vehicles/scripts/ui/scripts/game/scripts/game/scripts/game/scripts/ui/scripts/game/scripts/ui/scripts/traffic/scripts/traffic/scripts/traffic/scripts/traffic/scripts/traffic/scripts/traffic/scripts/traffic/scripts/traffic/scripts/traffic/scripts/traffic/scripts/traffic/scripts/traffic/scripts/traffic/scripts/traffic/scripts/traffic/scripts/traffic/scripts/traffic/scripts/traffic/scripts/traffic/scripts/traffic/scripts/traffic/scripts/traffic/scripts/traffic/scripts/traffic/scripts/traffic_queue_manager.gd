extends Node3D
class_name TrafficQueueManager

signal queue_updated(vehicle_count: int)
signal vehicle_added(vehicle: Node3D)
signal vehicle_removed(vehicle: Node3D)

@export_group("Queue Settings")
@export var max_queue_size := 20
@export var vehicle_spacing := 8.0
@export var first_stop_distance := 5.0

@export_group("Queue Position")
@export var queue_origin: Marker3D
@export var queue_direction := Vector3(0, 0, 1)

var vehicles: Array[Node3D] = []
var queue_positions: Dictionary = {}


func _ready():
    queue_direction = queue_direction.normalized()


func add_vehicle(vehicle: Node3D) -> bool:
    if not is_instance_valid(vehicle):
        return false

    if vehicles.has(vehicle):
        return false

    if vehicles.size() >= max_queue_size:
        return false

    vehicles.append(vehicle)
    vehicle_added.emit(vehicle)

    update_queue()
    return true


func remove_vehicle(vehicle: Node3D):
    if not vehicles.has(vehicle):
        return

    vehicles.erase(vehicle)
    queue_positions.erase(vehicle)

    vehicle_removed.emit(vehicle)
    update_queue()


func update_queue():
    if not is_instance_valid(queue_origin):
        return

    for i in range(vehicles.size()):
        var vehicle = vehicles[i]

        if not is_instance_valid(vehicle):
            continue

        var distance = first_stop_distance + i * vehicle_spacing

        var target = (
            queue_origin.global_position
            + queue_direction * distance
        )

        queue_positions[vehicle] = target

    queue_updated.emit(vehicles.size())


func get_queue_position(vehicle: Node3D) -> Vector3:
    if queue_positions.has(vehicle):
        return queue_positions[vehicle]

    return Vector3.ZERO


func get_queue_index(vehicle: Node3D) -> int:
    return vehicles.find(vehicle)


func get_queue_size() -> int:
    return vehicles.size()


func is_queue_full() -> bool:
    return vehicles.size() >= max_queue_size


func clear_queue():
    vehicles.clear()
    queue_positions.clear()
    queue_updated.emit(0)


func release_first_vehicle() -> Node3D:
    if vehicles.is_empty():
        return null

    var vehicle = vehicles[0]
    remove_vehicle(vehicle)

    return vehicle


func remove_invalid_vehicles():
    for i in range(vehicles.size() - 1, -1, -1):
        if not is_instance_valid(vehicles[i]):
            vehicles.remove_at(i)

    update_queue()
