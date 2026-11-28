extends Node
class_name TrafficAIDebugger

signal debug_report_updated(report: Dictionary)
signal traffic_error_detected(error_message: String)

@export_group("Settings")
@export var debugger_enabled: bool = true
@export var auto_check: bool = true
@export var check_interval: float = 3.0

@export_group("Performance")
@export var warning_vehicle_count: int = 15
@export var critical_vehicle_count: int = 25

var check_timer: float = 0.0
var last_report: Dictionary = {}


func _ready() -> void:
    add_to_group("traffic_ai_debugger")
    run_diagnostics()


func _process(delta: float) -> void:

    if not debugger_enabled or not auto_check:
        return

    check_timer += delta

    if check_timer >= check_interval:
        check_timer = 0.0
        run_diagnostics()


# ============================================================
# MAIN DIAGNOSTICS
# ============================================================

func run_diagnostics() -> Dictionary:

    var report: Dictionary = {
        "vehicle_count": 0,
        "traffic_lights": 0,
        "emergency_vehicles": 0,
        "lane_systems": 0,
        "collision_systems": 0,
        "overtaking_systems": 0,
        "errors": [],
        "warnings": [],
        "status": "OK"
    }

    _check_vehicles(report)
    _check_traffic_lights(report)
    _check_emergency_vehicles(report)
    _check_ai_systems(report)
    _check_performance(report)

    if not report.errors.is_empty():
        report.status = "ERROR"
    elif not report.warnings.is_empty():
        report.status = "WARNING"

    last_report = report

    debug_report_updated.emit(report)

    return report


# ============================================================
# CHECK TRAFFIC VEHICLES
# ============================================================

func _check_vehicles(report: Dictionary) -> void:

    var vehicles := get_tree().get_nodes_in_group(
        "traffic_vehicles"
    )

    report.vehicle_count = vehicles.size()

    for node in vehicles:

        if not is_instance_valid(node):
            continue

        if not node is TrafficVehicleAI:
            report.warnings.append(
                "A traffic vehicle has an unexpected script."
            )
            continue

        var vehicle := node as TrafficVehicleAI

        if vehicle.waypoints.is_empty():
            report.warnings.append(
                "Traffic vehicle has no assigned waypoints."
            )

        if vehicle.max_speed_kmh <= 0.0:
            report.errors.append(
                "Traffic vehicle has an invalid speed limit."
            )


# ============================================================
# CHECK TRAFFIC LIGHTS
# ============================================================

func _check_traffic_lights(report: Dictionary) -> void:

    var lights := get_tree().get_nodes_in_group(
        "traffic_lights"
    )

    report.traffic_lights = lights.size()

    for light in lights:

        if not light is TrafficLightAI:
            report.warnings.append(
                "A traffic light has an unexpected script."
            )


# ============================================================
# CHECK EMERGENCY VEHICLES
# ============================================================

func _check_emergency_vehicles(report: Dictionary) -> void:

    var emergency_vehicles := get_tree().get_nodes_in_group(
        "emergency_vehicles"
    )

    report.emergency_vehicles = emergency_vehicles.size()

    for emergency in emergency_vehicles:

        if not emergency.has_method("is_emergency_active"):
            report.errors.append(
                "Emergency vehicle is missing its emergency status method."
            )


# ============================================================
# CHECK AI SYSTEMS
# ============================================================

func _check_ai_systems(report: Dictionary) -> void:

    report.lane_systems = get_tree().get_nodes_in_group(
        "lane_following_system"
    ).size()

    report.collision_systems = get_tree().get_nodes_in_group(
        "traffic_collision_avoidance"
    ).size()

    report.overtaking_systems = get_tree().get_nodes_in_group(
        "vehicle_overtaking_ai"
    ).size()

    var controllers := get_tree().get_nodes_in_group(
        "traffic_ai_controller"
    )

    if controllers.is_empty():
        report.warnings.append(
            "Traffic AI Central Controller was not found."
        )


# ============================================================
# PERFORMANCE CHECK
# ============================================================

func _check_performance(report: Dictionary) -> void:

    var count: int = report.vehicle_count

    if count >= critical_vehicle_count:
        report.errors.append(
            "Traffic vehicle count is critically high."
        )

    elif count >= warning_vehicle_count:
        report.warnings.append(
            "Traffic vehicle count is high."
        )


# ============================================================
# REPORT
# ============================================================

func get_last_report() -> Dictionary:
    return last_report


func get_status() -> String:

    if last_report.is_empty():
        return "NOT CHECKED"

    return str(last_report.status)


func print_report() -> void:

    print("========== TRAFFIC AI DEBUG ==========")

    print("Vehicles: ", last_report.get("vehicle_count", 0))
    print("Traffic Lights: ", last_report.get("traffic_lights", 0))
    print("Emergency Vehicles: ", last_report.get("emergency_vehicles", 0))

    print("Lane Systems: ", last_report.get("lane_systems", 0))
    print("Collision Systems: ", last_report.get("collision_systems", 0))
    print("Overtaking Systems: ", last_report.get("overtaking_systems", 0))

    print("Status: ", get_status())

    for error in last_report.get("errors", []):
        push_error(str(error))

    for warning in last_report.get("warnings", []):
        push_warning(str(warning))

    print("======================================")


func enable_debugger() -> void:
    debugger_enabled = true
    run_diagnostics()


func disable_debugger() -> void:
    debugger_enabled = false
