extends Node
class_name TrafficDensityManager

signal density_changed(new_density: float)
signal traffic_level_changed(level: String)

enum TrafficLevel {
    VERY_LOW,
    LOW,
    MEDIUM,
    HIGH,
    VERY_HIGH
}

@export_group("References")
@export var traffic_spawner: TrafficSpawner
@export var player: Node3D

@export_group("Density Settings")
@export_range(0.0, 1.0, 0.05)
var traffic_density: float = 0.5

@export var maximum_density: float = 1.0
@export var minimum_density: float = 0.1

@export_group("Area Settings")
@export var city_density: float = 0.9
@export var village_density: float = 0.4
@export var highway_density: float = 0.6
@export var rural_density: float = 0.2

@export_group("Performance")
@export var update_interval: float = 5.0
@export var minimum_vehicle_count: int = 2
@export var maximum_vehicle_count: int = 20

var current_level: TrafficLevel = TrafficLevel.MEDIUM

var update_timer: float = 0.0
var current_area: String = "Highway"


func _ready() -> void:

    add_to_group("traffic_density_manager")

    _find_references()
    _apply_density()


func _process(delta: float) -> void:

    update_timer += delta

    if update_timer < update_interval:
        return

    update_timer = 0.0

    _find_references()
    _update_traffic_density()


# ============================================================
# FIND REFERENCES
# ============================================================

func _find_references() -> void:

    if not is_instance_valid(traffic_spawner):

        traffic_spawner = get_tree().get_first_node_in_group(
            "traffic_spawner"
        ) as TrafficSpawner

    if not is_instance_valid(player):

        var found := get_tree().get_first_node_in_group(
            "player"
        )

        if found is Node3D:
            player = found as Node3D


# ============================================================
# UPDATE TRAFFIC DENSITY
# ============================================================

func _update_traffic_density() -> void:

    if not is_instance_valid(player):
        return

    _apply_density()


func set_area_type(area: String) -> void:

    current_area = area.to_lower()

    match current_area:

        "city":
            traffic_density = city_density

        "village":
            traffic_density = village_density

        "highway":
            traffic_density = highway_density

        "rural":
            traffic_density = rural_density

        _:
            traffic_density = 0.5

    traffic_density = clampf(
        traffic_density,
        minimum_density,
        maximum_density
    )

    _apply_density()


# ============================================================
# APPLY DENSITY
# ============================================================

func _apply_density() -> void:

    if not is_instance_valid(traffic_spawner):
        return

    var vehicle_count := roundi(
        lerpf(
            float(minimum_vehicle_count),
            float(maximum_vehicle_count),
            traffic_density
        )
    )

    traffic_spawner.set_maximum_vehicles(
        vehicle_count
    )

    density_changed.emit(traffic_density)

    _update_traffic_level()


# ============================================================
# TRAFFIC LEVEL
# ============================================================

func _update_traffic_level() -> void:

    var new_level := TrafficLevel.MEDIUM

    if traffic_density < 0.2:
        new_level = TrafficLevel.VERY_LOW

    elif traffic_density < 0.4:
        new_level = TrafficLevel.LOW

    elif traffic_density < 0.65:
        new_level = TrafficLevel.MEDIUM

    elif traffic_density < 0.85:
        new_level = TrafficLevel.HIGH

    else:
        new_level = TrafficLevel.VERY_HIGH

    if new_level != current_level:

        current_level = new_level

        traffic_level_changed.emit(
            get_traffic_level_name()
        )


# ============================================================
# MANUAL DENSITY CONTROL
# ============================================================

func set_traffic_density(value: float) -> void:

    traffic_density = clampf(
        value,
        minimum_density,
        maximum_density
    )

    _apply_density()


func increase_density(amount: float = 0.1) -> void:
    set_traffic_density(traffic_density + amount)


func decrease_density(amount: float = 0.1) -> void:
    set_traffic_density(traffic_density - amount)


# ============================================================
# INFORMATION
# ============================================================

func get_traffic_level_name() -> String:

    match current_level:

        TrafficLevel.VERY_LOW:
            return "Very Low"

        TrafficLevel.LOW:
            return "Low"

        TrafficLevel.MEDIUM:
            return "Medium"

        TrafficLevel.HIGH:
            return "High"

        TrafficLevel.VERY_HIGH:
            return "Very High"

    return "Unknown"


func get_density_percentage() -> float:
    return traffic_density * 100.0


func get_current_area() -> String:
    return current_area


func get_current_density() -> float:
    return traffic_density
