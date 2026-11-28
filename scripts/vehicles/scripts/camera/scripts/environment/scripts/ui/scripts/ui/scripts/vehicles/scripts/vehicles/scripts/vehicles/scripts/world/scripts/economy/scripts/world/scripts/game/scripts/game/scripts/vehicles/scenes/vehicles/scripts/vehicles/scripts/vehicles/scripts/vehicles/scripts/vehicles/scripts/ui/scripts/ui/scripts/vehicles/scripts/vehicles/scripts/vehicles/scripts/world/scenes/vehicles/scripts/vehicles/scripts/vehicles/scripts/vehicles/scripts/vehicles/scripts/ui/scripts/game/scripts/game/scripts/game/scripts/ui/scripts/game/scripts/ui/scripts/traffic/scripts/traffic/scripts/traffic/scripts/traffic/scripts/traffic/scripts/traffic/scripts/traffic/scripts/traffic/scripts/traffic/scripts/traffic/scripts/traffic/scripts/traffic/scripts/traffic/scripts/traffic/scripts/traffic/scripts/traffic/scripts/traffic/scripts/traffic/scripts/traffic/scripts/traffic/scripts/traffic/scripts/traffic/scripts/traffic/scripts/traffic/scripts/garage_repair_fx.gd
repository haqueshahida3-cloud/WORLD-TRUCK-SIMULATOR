extends Node3D
class_name GarageRepairFX

@export_group("References")
@export var garage: Node
@export var warning_beacon: Node3D
@export var service_light: OmniLight3D
@export var repair_particles: GPUParticles3D

@export_group("Settings")
@export var beacon_speed := 3.0
@export var light_pulse_speed := 3.0
@export var light_min_energy := 0.5
@export var light_max_energy := 2.0

var repair_active := false
var pulse_time := 0.0


func _ready() -> void:
    if is_instance_valid(garage):
        garage.repair_started.connect(_on_repair_started)
        garage.repair_finished.connect(_on_repair_finished)
        garage.repair_failed.connect(_on_repair_failed)

    stop_effects()


func _process(delta: float) -> void:
    if not repair_active:
        return

    if is_instance_valid(warning_beacon):
        warning_beacon.rotate_y(beacon_speed * delta)

    if is_instance_valid(service_light):
        pulse_time += delta * light_pulse_speed

        service_light.light_energy = lerpf(
            light_min_energy,
            light_max_energy,
            (sin(pulse_time) + 1.0) * 0.5
        )


func _on_repair_started() -> void:
    repair_active = true
    pulse_time = 0.0

    if is_instance_valid(repair_particles):
        repair_particles.emitting = true


func _on_repair_finished(_cost: float) -> void:
    stop_effects()


func _on_repair_failed(_reason: String) -> void:
    stop_effects()


func stop_effects() -> void:
    repair_active = false

    if is_instance_valid(repair_particles):
        repair_particles.emitting = false

    if is_instance_valid(service_light):
        service_light.light_energy = light_min_energy
