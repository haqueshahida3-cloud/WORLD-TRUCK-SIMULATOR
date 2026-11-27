extends CanvasLayer
class_name DashboardWarningSystem

@export_group("System References")
@export var truck: VehicleBody3D
@export var fuel_system: Node
@export var damage_system: Node
@export var trailer_brakes: TrailerBrakeSystem
@export var trailer: TruckTrailer

@export_group("Warning Settings")
@export var low_fuel_threshold: float = 20.0
@export var high_damage_threshold: float = 60.0
@export var update_interval: float = 0.25

var update_timer: float = 0.0

var warning_labels: Dictionary = {}
var warning_states: Dictionary = {}


func _ready() -> void:
    add_to_group("dashboard_warning_system")
    _create_dashboard()
    _find_references()


func _process(delta: float) -> void:

    update_timer += delta

    if update_timer < update_interval:
        return

    update_timer = 0.0

    _update_warnings()


# ============================================================
# REFERENCES
# ============================================================

func _find_references() -> void:

    if not is_instance_valid(truck):
        var trucks := get_tree().get_nodes_in_group("player")

        if not trucks.is_empty():
            truck = trucks[0] as VehicleBody3D

    if not is_instance_valid(fuel_system):
        fuel_system = get_tree().get_first_node_in_group("fuel_system")

    if not is_instance_valid(damage_system):
        damage_system = get_tree().get_first_node_in_group("damage_system")

    if not is_instance_valid(trailer_brakes):
        trailer_brakes = get_tree().get_first_node_in_group(
            "trailer_brake_system"
        ) as TrailerBrakeSystem

    if not is_instance_valid(trailer):
        var trailers := get_tree().get_nodes_in_group("trailer")

        if not trailers.is_empty():
            trailer = trailers[0] as TruckTrailer


# ============================================================
# DASHBOARD UI
# ============================================================

func _create_dashboard() -> void:

    var panel := PanelContainer.new()
    panel.name = "WarningPanel"

    panel.position = Vector2(20, 150)
    panel.custom_minimum_size = Vector2(270, 0)

    add_child(panel)

    var layout := VBoxContainer.new()
    panel.add_child(layout)

    var heading := Label.new()
    heading.text = "VEHICLE WARNINGS"
    heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    layout.add_child(heading)

    _create_warning(layout, "engine", "ENGINE WARNING")
    _create_warning(layout, "fuel", "LOW FUEL")
    _create_warning(layout, "damage", "VEHICLE DAMAGE")
    _create_warning(layout, "brake", "BRAKE WARNING")
    _create_warning(layout, "abs", "ABS ACTIVE")
    _create_warning(layout, "trailer", "TRAILER STATUS")
    _create_warning(layout, "cargo", "CARGO DAMAGE")
    _create_warning(layout, "parking", "PARKING BRAKE")


func _create_warning(
    parent: VBoxContainer,
    warning_id: String,
    warning_text: String
) -> void:

    var label := Label.new()
    label.text = warning_text + ": OFF"
    label.add_theme_color_override(
        "font_color",
        Color(0.5, 0.5, 0.5)
    )

    parent.add_child(label)

    warning_labels[warning_id] = label
    warning_states[warning_id] = false


# ============================================================
# WARNING UPDATE
# ============================================================

func _update_warnings() -> void:

    _find_references()

    _check_engine()
    _check_fuel()
    _check_damage()
    _check_brakes()
    _check_abs()
    _check_trailer()
    _check_cargo()
    _check_parking_brake()


func _set_warning(
    warning_id: String,
    enabled: bool,
    message: String = ""
) -> void:

    warning_states[warning_id] = enabled

    if not warning_labels.has(warning_id):
        return

    var label: Label = warning_labels[warning_id]

    var status := "ON" if enabled else "OFF"

    if not message.is_empty():
        status = message

    label.text = warning_id.to_upper() + ": " + status

    var color := Color(1.0, 0.25, 0.15) if enabled else Color(0.5, 0.5, 0.5)

    label.add_theme_color_override("font_color", color)


# ============================================================
# ENGINE
# ============================================================

func _check_engine() -> void:

    var warning := false

    if is_instance_valid(truck):
        if truck.has_method("get"):
            warning = not bool(truck.get("engine_on"))

    _set_warning("engine", warning)


# ============================================================
# FUEL
# ============================================================

func _check_fuel() -> void:

    if not is_instance_valid(fuel_system):
        return

    if fuel_system.has_method("get_fuel_percentage"):
        var fuel: float = fuel_system.get_fuel_percentage()

        _set_warning(
            "fuel",
            fuel <= low_fuel_threshold,
            "%.1f%%" % fuel if fuel <= low_fuel_threshold else "OFF"
        )


# ============================================================
# DAMAGE
# ============================================================

func _check_damage() -> void:

    if not is_instance_valid(damage_system):
        return

    if damage_system.has_method("get_total_damage"):
        var damage: float = damage_system.get_total_damage()

        _set_warning(
            "damage",
            damage >= high_damage_threshold,
            "%.1f%%" % damage if damage >= high_damage_threshold else "OFF"
        )


# ============================================================
# BRAKES
# ============================================================

func _check_brakes() -> void:

    var warning := false

    if is_instance_valid(truck):
        warning = bool(truck.get("handbrake"))

    _set_warning("brake", warning)


func _check_abs() -> void:

    var active := false

    if is_instance_valid(trailer_brakes):
        active = trailer_brakes.is_abs_active()

    _set_warning("abs", active)


func _check_parking_brake() -> void:

    var active := false

    if is_instance_valid(truck):
        active = bool(truck.get("handbrake"))

    _set_warning("parking", active)


# ============================================================
# TRAILER
# ============================================================

func _check_trailer() -> void:

    var connected := false

    if is_instance_valid(trailer):
        connected = trailer.is_attached()

    _set_warning(
        "trailer",
        connected,
        "CONNECTED" if connected else "DISCONNECTED"
    )


# ============================================================
# CARGO
# ============================================================

func _check_cargo() -> void:

    var damaged := false

    var cargo := get_tree().get_first_node_in_group("cargo_system")

    if is_instance_valid(cargo):
        if cargo.has_method("get_cargo_condition_percentage"):
            damaged = cargo.get_cargo_condition_percentage() < 80.0

    _set_warning("cargo", damaged)


# ============================================================
# PUBLIC API
# ============================================================

func get_warning_status(warning_id: String) -> bool:
    return warning_states.get(warning_id, false)


func get_active_warning_count() -> int:

    var count := 0

    for warning_id in warning_states:
        if warning_states[warning_id]:
            count += 1

    return count
