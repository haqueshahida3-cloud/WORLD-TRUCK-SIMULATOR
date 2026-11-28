extends Node
class_name TrafficAICentralController

signal traffic_updated(vehicle_count: int)
signal emergency_vehicle_detected(vehicle: Node3D)
signal traffic_density_changed(level: String)

@export_group("Traffic Settings")
@export var controller_enabled: bool = true
@export var update_interval: float = 0.5
@export var maximum_controlled_vehicles: int = 20

@export_group("Speed Management")
@export var city_speed_limit: float = 40.0
@export var highway_speed_limit: float = 80.0
@export var village_speed_limit: float = 30.0
@export var rural_speed_limit: float = 50.0

@export_group("Safety")
@export var emergency_braking_enabled: bool = true
@export var safe_distance_enabled: bool = true

@export_group("Area")
@export_enum("City", "Highway", "Village", "Rural")
var current_area: String = "City"

var controlled_vehicles: Array[TrafficVehicleAI] = []
var update_timer: float = 0.0


func _ready() -> void:

    add_to_group("traffic_ai_controller")

    _refresh_traffic_vehicles()


func _physics_process(delta: float) -> void:

    if not controller_enabled:
        return

    update_timer += delta

    if update_timer >= update_interval:

        update_timer = 0.0

        _refresh_traffic_vehicles()
        _manage_traffic()
        _update_traffic_density()


# ============================================================
# REFRESH VEHICLES
# ============================================================

func _refresh_traffic_vehicles() -> void:

    controlled_vehicles.clear()

    var vehicles := get_tree().get_nodes_in_group(
        "traffic_vehicles"
    )

    for node in vehicles:

        if not node is TrafficVehicleAI:
            continue

        if controlled_vehicles.size() >= maximum_controlled_vehicles:
            break

        controlled_vehicles.append(node as TrafficVehicleAI)

    traffic_updated.emit(controlled_vehicles.size())


# ============================================================
# MANAGE TRAFFIC
# ============================================================

func _manage_traffic() -> void:

    var speed_limit := _get_area_speed_limit()

    for traffic_vehicle in controlled_vehicles:

        if not is_instance_valid(traffic_vehicle):
            continue

        _apply_speed_limit(
            traffic_vehicle,
            speed_limit
        )

        _check_vehicle_safety(traffic_vehicle)


# ============================================================
# SPEED LIMIT
# ============================================================

func _get_area_speed_limit() -> float:

    match current_area:

        "City":
            return city_speed_limit

        "Highway":
            return highway_speed_limit

        "Village":
            return village_speed_limit

        "Rural":
            return rural_speed_limit

        _:
            return city_speed_limit


func _apply_speed_limit(
    traffic_vehicle: TrafficVehicleAI,
    speed_limit: float
) -> void:

    if traffic_vehicle.max_speed_kmh > speed_limit:

        traffic_vehicle.max_speed_kmh = speed_limit


# ============================================================
# SAFETY MANAGEMENT
# ============================================================

func _check_vehicle_safety(
    traffic_vehicle: TrafficVehicleAI
) -> void:

    if not safe_distance_enabled:
        return

    var forward := -traffic_vehicle.global_transform.basis.z

    var origin := traffic_vehicle.global_position + Vector3(
        0.0,
        1.0,
        0.0
    )

    var destination := origin + forward * 25.0

    var query := PhysicsRayQueryParameters3D.create(
        origin,
        destination
    )

    query.exclude = [traffic_vehicle.get_rid()]

    var result := traffic_vehicle.get_world_3d().direct_space_state.intersect_ray(
        query
    )

    if result.is_empty():
        return

    var collider: Object = result.get("collider")

    if collider is TrafficVehicleAI:

        var distance := origin.distance_to(
            result.get("position")
        )

        if distance < 8.0:
            traffic_vehicle.target_speed = 0.0

        elif distance < 18.0:

            var lead_vehicle := collider as TrafficVehicleAI

            traffic_vehicle.target_speed = minf(
                traffic_vehicle.target_speed,
                lead_vehicle.current_speed
            )


# ============================================================
# EMERGENCY VEHICLES
# ============================================================

func notify_emergency_vehicle(
    emergency_vehicle: Node3D
) -> void:

    if not is_instance_valid(emergency_vehicle):
        return

    emergency_vehicle_detected.emit(emergency_vehicle)

    for traffic_vehicle in controlled_vehicles:

        if not is_instance_valid(traffic_vehicle):
            continue

        traffic_vehicle.target_speed = minf(
            traffic_vehicle.target_speed,
            0.0
        )


# ============================================================
# TRAFFIC DENSITY
# ============================================================

func _update_traffic_density() -> void:

    var count := controlled_vehicles.size()

    var level := "Low"

    if count >= 15:
        level = "Heavy"

    elif count >= 8:
        level = "Medium"

    traffic_density_changed.emit(level)


# ============================================================
# AREA CONTROL
# ============================================================

func set_area_type(area: String) -> void:

    if area in ["City", "Highway", "Village", "Rural"]:

        current_area = area

        _manage_traffic()


func get_controlled_vehicle_count() -> int:
    return controlled_vehicles.size()


func get_current_speed_limit() -> float:
    return _get_area_speed_limit()


func set_controller_enabled(enabled: bool) -> void:
    controller_enabled = enabled
