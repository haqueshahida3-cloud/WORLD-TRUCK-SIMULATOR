
extends CanvasLayer
class_name TruckHUD

@export_group("Truck")
@export var truck: VehicleBody3D

@export_group("Display")
@export var update_rate: float = 0.1
@export var show_rpm: bool = true
@export var show_fuel: bool = true

var update_timer: float = 0.0
var speed_label: Label
var rpm_label: Label
var gear_label: Label
var transmission_label: Label
var fuel_label: Label
var engine_label: Label
var handbrake_label: Label
var status_label: Label
var rpm_bar: ProgressBar
var fuel_bar: ProgressBar


func _ready() -> void:
    _create_hud()


func _process(delta: float) -> void:
    update_timer += delta

    if update_timer >= update_rate:
        update_timer = 0.0
        _update_display()


func _create_hud() -> void:
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(root)

    var panel := PanelContainer.new()
    panel.position = Vector2(25, 25)
    panel.custom_minimum_size = Vector2(250, 175)
    root.add_child(panel)

    var layout := VBoxContainer.new()
    layout.add_theme_constant_override("separation", 7)
    panel.add_child(layout)

    speed_label = _make_label("0 KM/H", 30)
    layout.add_child(speed_label)

    rpm_label = _make_label("RPM: 700", 17)
    layout.add_child(rpm_label)

    rpm_bar = ProgressBar.new()
    rpm_bar.custom_minimum_size = Vector2(220, 12)
    rpm_bar.max_value = 2400
    layout.add_child(rpm_bar)

    var separator := HSeparator.new()
    layout.add_child(separator)

    gear_label = _make_label("GEAR: N", 23)
    layout.add_child(gear_label)

    transmission_label = _make_label("AUTOMATIC", 14)
    layout.add_child(transmission_label)

    if show_fuel:
        fuel_label = _make_label("FUEL: 100%", 15)
        layout.add_child(fuel_label)

        fuel_bar = ProgressBar.new()
        fuel_bar.custom_minimum_size = Vector2(220, 10)
        fuel_bar.max_value = 100
        fuel_bar.value = 100
        layout.add_child(fuel_bar)

    engine_label = _make_label("ENGINE: ON", 14)
    layout.add_child(engine_label)

    handbrake_label = _make_label("HANDBRAKE: OFF", 14)
    layout.add_child(handbrake_label)

    status_label = _make_label("READY", 12)
    layout.add_child(status_label)


func _make_label(text_value: String, font_size: int) -> Label:
    var label := Label.new()
    label.text = text_value
    label.add_theme_font_size_override("font_size", font_size)
    return label


func _update_display() -> void:
    if not is_instance_valid(truck):
        var trucks := get_tree().get_nodes_in_group("player")
        if trucks.is_empty():
            return
        truck = trucks[0] as VehicleBody3D

    var speed := truck.linear_velocity.length() * 3.6

    if truck is Truck:
        var vehicle := truck as Truck

        speed_label.text = "%03d KM/H" % int(speed)
        rpm_label.text = "RPM: %04d" % int(vehicle.current_rpm)
        rpm_bar.value = vehicle.current_rpm

        gear_label.text = "GEAR: " + vehicle.get_gear_name()

        transmission_label.text = (
            "AUTOMATIC" if vehicle.is_automatic()
            else "MANUAL"
        )

        engine_label.text = (
            "ENGINE: ON" if vehicle.engine_on
            else "ENGINE: OFF"
        )

        handbrake_label.text = (
            "HANDBRAKE: ON" if vehicle.handbrake
            else "HANDBRAKE: OFF"
        )

        status_label.text = (
            "PARKED" if speed < 1.0
            else "DRIVING"
        )

    else:
        speed_label.text = "%03d KM/H" % int(speed)
        rpm_label.text = "RPM: --"
        gear_label.text = "GEAR: --"

