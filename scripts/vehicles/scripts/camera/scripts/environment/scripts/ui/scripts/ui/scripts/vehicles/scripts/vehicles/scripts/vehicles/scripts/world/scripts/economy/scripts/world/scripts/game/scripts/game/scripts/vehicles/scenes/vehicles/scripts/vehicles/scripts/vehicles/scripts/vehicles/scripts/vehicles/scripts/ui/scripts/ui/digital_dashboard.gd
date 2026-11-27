extends CanvasLayer
class_name DigitalTruckDashboard

@export_group("Vehicle References")
@export var truck: VehicleBody3D
@export var fuel_system: Node

@export_group("Dashboard Settings")
@export var update_interval: float = 0.1
@export var maximum_speed: float = 160.0
@export var maximum_rpm: float = 3000.0

var update_timer: float = 0.0
var total_distance: float = 0.0

var speed_label: Label
var rpm_label: Label
var gear_label: Label
var fuel_label: Label
var temperature_label: Label
var odometer_label: Label

var speed_bar: ProgressBar
var rpm_bar: ProgressBar
var fuel_bar: ProgressBar


func _ready() -> void:
    add_to_group("digital_dashboard")
    _find_references()
    _create_dashboard()


func _process(delta: float) -> void:

    if not is_instance_valid(truck):
        _find_references()
        return

    total_distance += truck.linear_velocity.length() * delta / 1000.0

    update_timer += delta

    if update_timer >= update_interval:
        update_timer = 0.0
        _update_dashboard()


func _find_references() -> void:

    if not is_instance_valid(truck):
        var trucks := get_tree().get_nodes_in_group("player")

        if not trucks.is_empty():
            truck = trucks[0] as VehicleBody3D

    if not is_instance_valid(fuel_system):
        fuel_system = get_tree().get_first_node_in_group("fuel_system")


# ============================================================
# DASHBOARD UI
# ============================================================

func _create_dashboard() -> void:

    var panel := PanelContainer.new()
    panel.name = "DigitalDashboard"
    panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    panel.offset_top = -150
    panel.offset_bottom = -15
    panel.offset_left = 20
    panel.offset_right = -20

    add_child(panel)

    var layout := VBoxContainer.new()
    panel.add_child(layout)

    var heading := Label.new()
    heading.text = "HAUL MASTER | DIGITAL INSTRUMENT CLUSTER"
    heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    layout.add_child(heading)

    var top_row := HBoxContainer.new()
    layout.add_child(top_row)

    speed_label = _create_value(top_row, "SPEED")
    rpm_label = _create_value(top_row, "ENGINE RPM")
    gear_label = _create_value(top_row, "GEAR")

    var bottom_row := HBoxContainer.new()
    layout.add_child(bottom_row)

    fuel_label = _create_value(bottom_row, "FUEL")
    temperature_label = _create_value(bottom_row, "ENGINE TEMP")
    odometer_label = _create_value(bottom_row, "ODOMETER")

    speed_bar = _create_bar(layout, 160.0)
    rpm_bar = _create_bar(layout, maximum_rpm)
    fuel_bar = _create_bar(layout, 100.0)


func _create_value(parent: HBoxContainer, title: String) -> Label:

    var label := Label.new()
    label.text = title + "\n--"
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

    parent.add_child(label)

    return label


func _create_bar(parent: VBoxContainer, maximum: float) -> ProgressBar:

    var bar := ProgressBar.new()
    bar.min_value = 0.0
    bar.max_value = maximum
    bar.value = 0.0
    bar.show_percentage = false
    bar.custom_minimum_size = Vector2(0, 10)

    parent.add_child(bar)

    return bar


# ============================================================
# UPDATE DASHBOARD
# ============================================================

func _update_dashboard() -> void:

    if not is_instance_valid(truck):
        return

    var speed := truck.linear_velocity.length() * 3.6

    var rpm := 0.0

    if truck.has_method("get"):
        rpm = float(truck.get("current_rpm"))

    var gear := "N"

    if truck.has_method("get_gear_name"):
        gear = truck.get_gear_name()

    speed_label.text = "SPEED\n%.0f km/h" % speed
    rpm_label.text = "ENGINE RPM\n%.0f" % rpm
    gear_label.text = "GEAR\n%s" % gear

    speed_bar.value = clampf(speed, 0.0, maximum_speed)
    rpm_bar.value = clampf(rpm, 0.0, maximum_rpm)

    _update_fuel()
    _update_temperature()

    odometer_label.text = "ODOMETER\n%.2f km" % total_distance


# ============================================================
# FUEL
# ============================================================

func _update_fuel() -> void:

    if not is_instance_valid(fuel_system):
        fuel_label.text = "FUEL\n--"
        return

    if fuel_system.has_method("get_fuel_percentage"):

        var fuel: float = fuel_system.get_fuel_percentage()

        fuel_label.text = "FUEL\n%.1f%%" % fuel
        fuel_bar.value = clampf(fuel, 0.0, 100.0)

    else:
        fuel_label.text = "FUEL\n--"


# ============================================================
# ENGINE TEMPERATURE
# ============================================================

func _update_temperature() -> void:

    if truck.has_method("get"):

        var temperature = truck.get("engine_temperature")

        if temperature != null:
            temperature_label.text = "ENGINE TEMP\n%.1f °C" % float(temperature)
            return

    temperature_label.text = "ENGINE TEMP\nN/A"


# ============================================================
# PUBLIC FUNCTIONS
# ============================================================

func get_odometer() -> float:
    return total_distance


func reset_odometer() -> void:
    total_distance = 0.0


func get_current_speed() -> float:

    if not is_instance_valid(truck):
        return 0.0

    return truck.linear_velocity.length() * 3.6
