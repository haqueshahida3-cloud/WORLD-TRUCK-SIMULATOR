extends Control
class_name GarageStatusUI

@export_group("References")
@export var garage: Node
@export var damage_system: Node

@export_group("Damage Bars")
@export var engine_bar: ProgressBar
@export var body_bar: ProgressBar
@export var wheel_bar: ProgressBar

@export_group("Repair Progress")
@export var repair_bar: ProgressBar
@export var repair_label: Label
@export var condition_label: Label

@export_group("Settings")
@export var update_interval := 0.15

var update_timer := 0.0


func _ready() -> void:
    for bar in [engine_bar, body_bar, wheel_bar]:
        if is_instance_valid(bar):
            bar.min_value = 0.0
            bar.max_value = 100.0

    if is_instance_valid(repair_bar):
        repair_bar.min_value = 0.0
        repair_bar.max_value = 100.0
        repair_bar.value = 0.0

    if is_instance_valid(garage):
        garage.repair_started.connect(_on_repair_started)
        garage.repair_finished.connect(_on_repair_finished)
        garage.repair_failed.connect(_on_repair_failed)

    refresh_display()


func _process(delta: float) -> void:
    update_timer += delta

    if update_timer < update_interval:
        return

    update_timer = 0.0
    refresh_display()


func refresh_display() -> void:
    if not is_instance_valid(damage_system):
        return

    set_damage_bar(engine_bar, "engine")
    set_damage_bar(body_bar, "body")
    set_damage_bar(wheel_bar, "wheel")

    if is_instance_valid(condition_label):
        condition_label.text = (
            "Truck Condition: "
            + str(snappedf(damage_system.get_vehicle_condition(), 0.1))
            + "%"
        )

    update_repair_progress()


func set_damage_bar(bar: ProgressBar, component: String) -> void:
    if not is_instance_valid(bar):
        return

    var damage: float = damage_system.get_component_damage(component)
    bar.value = damage

    bar.tooltip_text = component.capitalize() + " Damage: " + str(snappedf(damage, 0.1)) + "%"


func update_repair_progress() -> void:
    if not is_instance_valid(garage):
        return

    if not is_instance_valid(repair_bar):
        return

    if garage.repairing:
        repair_bar.value = garage.get_repair_progress() * 100.0

        if is_instance_valid(repair_label):
            repair_label.text = "Repairing... " + str(round(repair_bar.value)) + "%"
    else:
        repair_bar.value = 0.0


func _on_repair_started() -> void:
    if is_instance_valid(repair_label):
        repair_label.text = "Repair Started"


func _on_repair_finished(cost: float) -> void:
    if is_instance_valid(repair_label):
        repair_label.text = "Repair Complete! Cost: $" + str(snappedf(cost, 0.01))

    refresh_display()


func _on_repair_failed(reason: String) -> void:
    if is_instance_valid(repair_label):
        repair_label.text = "Repair Failed: " + reason
