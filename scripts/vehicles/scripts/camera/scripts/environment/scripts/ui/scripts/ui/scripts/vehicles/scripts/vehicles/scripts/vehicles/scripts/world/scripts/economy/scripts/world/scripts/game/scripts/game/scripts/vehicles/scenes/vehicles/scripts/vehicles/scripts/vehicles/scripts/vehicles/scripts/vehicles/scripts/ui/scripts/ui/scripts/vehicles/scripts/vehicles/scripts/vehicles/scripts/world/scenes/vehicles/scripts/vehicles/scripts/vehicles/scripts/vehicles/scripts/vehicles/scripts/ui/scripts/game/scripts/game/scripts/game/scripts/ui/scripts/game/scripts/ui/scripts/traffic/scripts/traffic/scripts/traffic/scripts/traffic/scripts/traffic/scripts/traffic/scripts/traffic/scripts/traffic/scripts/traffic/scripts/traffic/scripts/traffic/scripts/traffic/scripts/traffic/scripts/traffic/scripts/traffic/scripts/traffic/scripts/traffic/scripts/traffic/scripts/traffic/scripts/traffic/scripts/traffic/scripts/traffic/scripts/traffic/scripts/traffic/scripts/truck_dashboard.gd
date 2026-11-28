extends Control
class_name TruckDashboard

@export_group("Vehicle")
@export var truck: VehicleBody3D
@export var gearbox: Node

@export_group("Dashboard Labels")
@export var speed_label: Label
@export var rpm_label: Label
@export var gear_label: Label
@export var fuel_label: Label

@export_group("Dashboard Gauges")
@export var rpm_bar: ProgressBar
@export var speed_bar: ProgressBar

@export_group("Settings")
@export var maximum_speed := 140.0
@export var maximum_rpm := 3000.0

var fuel_level := 100.0


func _process(_delta):
    if not is_instance_valid(truck):
        return

    update_speedometer()
    update_engine_meter()
    update_gear_indicator()
    update_fuel_display()


func update_speedometer():
    var speed := truck.linear_velocity.length() * 3.6

    if is_instance_valid(speed_label):
        speed_label.text = "%03d km/h" % int(speed)

    if is_instance_valid(speed_bar):
        speed_bar.max_value = maximum_speed
        speed_bar.value = clampf(speed, 0.0, maximum_speed)


func update_engine_meter():
    var rpm := 0.0

    if is_instance_valid(gearbox):
        if gearbox.has_method("get_engine_rpm"):
            rpm = gearbox.get_engine_rpm()

    if is_instance_valid(rpm_label):
        rpm_label.text = "RPM: %04d" % int(rpm)

    if is_instance_valid(rpm_bar):
        rpm_bar.max_value = maximum_rpm
        rpm_bar.value = clampf(rpm, 0.0, maximum_rpm)


func update_gear_indicator():
    if not is_instance_valid(gear_label):
        return

    if is_instance_valid(gearbox):
        if gearbox.has_method("get_current_gear"):
            gear_label.text = "GEAR: " + gearbox.get_current_gear()


func update_fuel_display():
    if is_instance_valid(fuel_label):
        fuel_label.text = "FUEL: %d%%" % int(fuel_level)


func set_fuel_level(value: float):
    fuel_level = clampf(value, 0.0, 100.0)
    update_fuel_display()


func get_fuel_level() -> float:
    return fuel_level
