extends Node3D
class_name RoadLaneSystem

signal lane_registered(lane_index: int)
signal lane_removed(lane_index: int)

@export_group("Road Settings")
@export_range(1, 8) var lane_count: int = 4
@export var lane_width: float = 3.5
@export var road_length: float = 500.0

@export_group("Road Direction")
@export var road_start: Vector3 = Vector3.ZERO
@export var road_direction: Vector3 = Vector3(0, 0, -1)

@export_group("Lane Markers")
@export var create_markers_automatically: bool = true

var lane_markers: Array[Marker3D] = []
var lane_vehicle_counts: Dictionary = {}


func _ready() -> void:

    road_direction = road_direction.normalized()

    if create_markers_automatically:
        generate_lanes()


# ============================================================
# GENERATE LANES
# ============================================================

func generate_lanes() -> void:

    clear_lanes()

    var side_direction := Vector3.UP.cross(
        road_direction
    ).normalized()

    var total_width := lane_count * lane_width

    for i in range(lane_count):

        var marker := Marker3D.new()

        marker.name = "Lane_%02d" % i

        var lateral_offset := (
            float(i) - float(lane_count - 1) / 2.0
        ) * lane_width

        var lane_position := (
            road_start
            + side_direction * lateral_offset
        )

        marker.position = lane_position

        add_child(marker)

        lane_markers.append(marker)
        lane_vehicle_counts[i] = 0

        lane_registered.emit(i)


# ============================================================
# CLEAR LANES
# ============================================================

func clear_lanes() -> void:

    for marker in lane_markers:

        if is_instance_valid(marker):
            marker.queue_free()

    lane_markers.clear()
    lane_vehicle_counts.clear()


# ============================================================
# LANE INFORMATION
# ============================================================

func get_lane_count() -> int:
    return lane_markers.size()


func get_lane_marker(index: int) -> Marker3D:

    if index < 0 or index >= lane_markers.size():
        return null

    return lane_markers[index]


func get_lane_position(index: int) -> Vector3:

    var marker := get_lane_marker(index)

    if not is_instance_valid(marker):
        return Vector3.ZERO

    return marker.global_position


func get_lane_center(index: int) -> Vector3:
    return get_lane_position(index)


func get_road_width() -> float:
    return float(lane_count) * lane_width


# ============================================================
# LANE VEHICLE TRACKING
# ============================================================

func register_vehicle(vehicle: Node3D, lane_index: int) -> void:

    if not is_instance_valid(vehicle):
        return

    if lane_index < 0 or lane_index >= lane_markers.size():
        return

    vehicle.set_meta("road_lane_index", lane_index)

    lane_vehicle_counts[lane_index] = (
        int(lane_vehicle_counts.get(lane_index, 0)) + 1
    )


func unregister_vehicle(vehicle: Node3D) -> void:

    if not is_instance_valid(vehicle):
        return

    if not vehicle.has_meta("road_lane_index"):
        return

    var lane_index := int(
        vehicle.get_meta("road_lane_index")
    )

    if lane_vehicle_counts.has(lane_index):

        lane_vehicle_counts[lane_index] = maxi(
            0,
            int(lane_vehicle_counts[lane_index]) - 1
        )

    vehicle.remove_meta("road_lane_index")


func update_vehicle_lane(
    vehicle: Node3D,
    new_lane_index: int
) -> void:

    unregister_vehicle(vehicle)
    register_vehicle(vehicle, new_lane_index)


func get_vehicle_count(lane_index: int) -> int:

    return int(
        lane_vehicle_counts.get(lane_index, 0)
    )


# ============================================================
# LANE SELECTION
# ============================================================

func get_least_busy_lane() -> int:

    if lane_markers.is_empty():
        return -1

    var best_lane := 0
    var lowest_count := 2147483647

    for i in range(lane_markers.size()):

        var count := get_vehicle_count(i)

        if count < lowest_count:

            lowest_count = count
            best_lane = i

    return best_lane


func is_valid_lane(index: int) -> bool:

    return (
        index >= 0
        and index < lane_markers.size()
    )


func get_neighbouring_lanes(index: int) -> Array[int]:

    var result: Array[int] = []

    if not is_valid_lane(index):
        return result

    if index > 0:
        result.append(index - 1)

    if index < lane_markers.size() - 1:
        result.append(index + 1)

    return result


# ============================================================
# ROAD GEOMETRY HELPERS
# ============================================================

func get_road_end() -> Vector3:

    return road_start + road_direction * road_length


func get_lane_end(index: int) -> Vector3:

    if not is_valid_lane(index):
        return Vector3.ZERO

    var marker := lane_markers[index]

    return (
        marker.global_position
        + road_direction * road_length
    )


func get_distance_along_road(position: Vector3) -> float:

    return (
        position - road_start
    ).dot(road_direction)


func get_nearest_lane(position: Vector3) -> int:

    if lane_markers.is_empty():
        return -1

    var nearest_lane := -1
    var nearest_distance := INF

    for i in range(lane_markers.size()):

        var distance := position.distance_to(
            lane_markers[i].global_position
        )

        if distance < nearest_distance:

            nearest_distance = distance
            nearest_lane = i

    return nearest_lane
