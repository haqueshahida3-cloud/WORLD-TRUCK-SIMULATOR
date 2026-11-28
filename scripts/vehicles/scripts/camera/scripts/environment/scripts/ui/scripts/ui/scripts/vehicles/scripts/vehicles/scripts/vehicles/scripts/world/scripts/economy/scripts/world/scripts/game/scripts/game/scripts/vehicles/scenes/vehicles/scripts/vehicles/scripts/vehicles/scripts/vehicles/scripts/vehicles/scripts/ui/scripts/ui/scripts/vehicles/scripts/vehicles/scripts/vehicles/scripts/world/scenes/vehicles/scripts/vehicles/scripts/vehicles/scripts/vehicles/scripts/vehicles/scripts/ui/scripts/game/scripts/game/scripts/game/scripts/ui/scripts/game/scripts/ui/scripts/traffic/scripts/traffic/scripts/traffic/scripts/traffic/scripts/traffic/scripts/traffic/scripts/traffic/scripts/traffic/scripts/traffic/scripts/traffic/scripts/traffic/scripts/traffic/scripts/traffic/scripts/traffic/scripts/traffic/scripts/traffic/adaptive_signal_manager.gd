extends Node
class_name AdaptiveSignalManager

@export_group("Intersection")
@export var intersection: SmartIntersectionAI

@export_group("Adaptive Timing")
@export var minimum_green_time: float = 10.0
@export var maximum_green_time: float = 40.0
@export var default_green_time: float = 20.0
@export var update_interval: float = 2.0

@export_group("Traffic Density")
@export var low_traffic_threshold: int = 2
@export var medium_traffic_threshold: int = 5
@export var high_traffic_threshold: int = 8

var update_timer: float = 0.0

var north_south_density: int = 0
var east_west_density: int = 0

var north_south_green_time: float = 20.0
var east_west_green_time: float = 20.0


func _ready() -> void:

    if not is_instance_valid(intersection):
        push_warning("AdaptiveSignalManager: Intersection is not assigned.")
        set_process(false)
        return

    north_south_green_time = default_green_time
    east_west_green_time = default_green_time

    _update_density()


func _process(delta: float) -> void:

    if not is_instance_valid(intersection):
        return

    if not intersection.automatic_mode:
        return

    update_timer += delta

    if update_timer >= update_interval:

        update_timer = 0.0

        _update_density()
        _calculate_green_times()


# ============================================================
# TRAFFIC DENSITY
# ============================================================

func _update_density() -> void:

    north_south_density = (
        intersection.get_north_south_queue_count()
    )

    east_west_density = (
        intersection.get_east_west_queue_count()
    )


# ============================================================
# ADAPTIVE GREEN TIME
# ============================================================

func _calculate_green_times() -> void:

    north_south_green_time = _calculate_time(
        north_south_density
    )

    east_west_green_time = _calculate_time(
        east_west_density
    )

    _apply_current_green_time()


func _calculate_time(vehicle_count: int) -> float:

    var calculated_time := default_green_time

    if vehicle_count <= low_traffic_threshold:

        calculated_time = minimum_green_time

    elif vehicle_count <= medium_traffic_threshold:

        calculated_time = default_green_time

    elif vehicle_count >= high_traffic_threshold:

        calculated_time = maximum_green_time

    else:

        var density_ratio := float(
            vehicle_count - medium_traffic_threshold
        ) / float(
            high_traffic_threshold - medium_traffic_threshold
        )

        calculated_time = lerpf(
            default_green_time,
            maximum_green_time,
            density_ratio
        )

    return clampf(
        calculated_time,
        minimum_green_time,
        maximum_green_time
    )


# ============================================================
# APPLY TIMING
# ============================================================

func _apply_current_green_time() -> void:

    match intersection.current_phase:

        SmartIntersectionAI.Phase.NORTH_SOUTH_GREEN:
            intersection.green_duration = north_south_green_time

        SmartIntersectionAI.Phase.EAST_WEST_GREEN:
            intersection.green_duration = east_west_green_time


# ============================================================
# INFORMATION
# ============================================================

func get_north_south_green_time() -> float:
    return north_south_green_time


func get_east_west_green_time() -> float:
    return east_west_green_time


func get_traffic_density_report() -> Dictionary:

    _update_density()

    return {
        "north_south_vehicles": north_south_density,
        "east_west_vehicles": east_west_density,
        "north_south_green": north_south_green_time,
        "east_west_green": east_west_green_time
    }


func reset_adaptive_timing() -> void:

    north_south_green_time = default_green_time
    east_west_green_time = default_green_time

    intersection.green_duration = default_green_time
