extends VehicleBody3D
class_name Truck

## Phase 1 — Realistic truck physics controller
## Uses Godot 4's built-in VehicleBody3D / VehicleWheel3D for suspension & traction,
## with a custom engine / transmission / torque model on top.

# === ENGINE ===
@export_group("Engine")
@export var max_engine_force: float = 4000.0
@export var max_brake_force: float = 80.0
@export var engine_braking_force: float = 6.0
@export var idle_rpm: float = 700.0
@export var max_engine_rpm: float = 2400.0
@export var peak_torque_rpm: float = 1400.0
@export var engine_on: bool = true

# === TRANSMISSION ===
@export_group("Transmission")
@export var automatic: bool = true
@export var final_drive: float = 4.0
@export var wheel_radius: float = 0.55
# [reverse, neutral, 1st, 2nd, 3rd, 4th, 5th, 6th, 7th]
var gear_ratios: Array[float] = [-4.0, 0.0, 9.0, 5.5, 3.5, 2.3, 1.6, 1.2, 0.95]

# === STEERING ===
@export_group("Steering")
@export var max_steer_angle: float = 0.55      # radians (~31°)
@export var steer_speed: float = 2.5
@export var steer_return_speed: float = 4.0

# === STATE ===
var throttle: float = 0.0
var brake_input: float = 0.0
var steer_target: float = 0.0
var current_gear_index: int = 1                 # 0=reverse, 1=neutral, 2+=forward
var current_rpm: float = 700.0
var speed_kmh: float = 0.0
var handbrake: bool = false
var auto_shift_cooldown: float = 0.0

# Internal
var _wheel_spin: float = 0.0
var _wheel_nodes: Array[VehicleWheel3D] = []

func _ready() -> void:
	add_to_group("player")
	for child in get_children():
		if child is VehicleWheel3D:
			_wheel_nodes.append(child)

func _physics_process(delta: float) -> void:
	_read_input()
	_update_steering(delta)
	_update_telemetry(delta)
	_update_transmission(delta)
	_apply_engine_and_brakes()
	_update_wheel_visuals(delta)

# ---------------------------------------------------------------------------
# INPUT
# ---------------------------------------------------------------------------
func _read_input() -> void:
	throttle = Input.get_action_strength("accelerate")
	brake_input = Input.get_action_strength("brake")
	steer_target = Input.get_axis("steer_left", "steer_right")
	handbrake = Input.is_action_pressed("handbrake")

	if Input.is_action_just_pressed("toggle_transmission"):
		automatic = not automatic
		auto_shift_cooldown = 1.0

	if Input.is_action_just_pressed("gear_up"):
		_shift_up()
		auto_shift_cooldown = 2.0
	if Input.is_action_just_pressed("gear_down"):
		_shift_down()
		auto_shift_cooldown = 2.0

# ---------------------------------------------------------------------------
# STEERING
# ---------------------------------------------------------------------------
func _update_steering(delta: float) -> void:
	var target: float = -steer_target * max_steer_angle
	var speed := 2.0 if abs(target) > abs(steering) else steer_return_speed
	steering = move_toward(steering, target, speed * delta)

# ---------------------------------------------------------------------------
# TELEMETRY (RPM + speed)
# ---------------------------------------------------------------------------
func _update_telemetry(delta: float) -> void:
	speed_kmh = linear_velocity.length() * 3.6
	if linear_velocity.length() > 0.1:
		# Sign from forward vector so reversing shows negative speed
		if get_forward_speed() < -0.1:
			speed_kmh = -speed_kmh

	var ratio := gear_ratios[current_gear_index]
	var forward_speed := get_forward_speed()

	if ratio != 0.0 and abs(forward_speed) > 0.5:
		var wheel_ang := forward_speed / wheel_radius
		var engine_ang := wheel_ang * ratio * final_drive
		var target_rpm := abs(engine_ang) * 60.0 / TAU
		current_rpm = lerp(current_rpm, clampf(target_rpm, idle_rpm, max_engine_rpm + 200.0), delta * 6.0)
	else:
		var rev_target := idle_rpm + throttle * (max_engine_rpm - idle_rpm) * 0.9
		current_rpm = lerp(current_rpm, rev_target, delta * 4.0)

# ---------------------------------------------------------------------------
# TRANSMISSION
# ---------------------------------------------------------------------------
func _update_transmission(delta: float) -> void:
	if auto_shift_cooldown > 0.0:
		auto_shift_cooldown -= delta
		return
	if not automatic:
		return

	if current_gear_index == 1:      # neutral → engage 1st when throttle applied
		if throttle > 0.05:
			current_gear_index = 2
	elif current_gear_index >= 2:    # forward gears — auto shift
		if current_rpm > 2000.0 and current_gear_index < gear_ratios.size() - 1:
			current_gear_index += 1
		elif current_rpm < 900.0 and current_gear_index > 2:
			current_gear_index -= 1

func _shift_up() -> void:
	if current_gear_index < gear_ratios.size() - 1:
		current_gear_index += 1

func _shift_down() -> void:
	if current_gear_index > 0:
		# Blocking reverse at speed — prevents damage / exploit
		if current_gear_index == 2 and speed_kmh > 5.0:
			return
		current_gear_index -= 1

# ---------------------------------------------------------------------------
# ENGINE + BRAKES
# ---------------------------------------------------------------------------
func _apply_engine_and_brakes() -> void:
	var ratio := gear_ratios[current_gear_index]
	var torque_factor := clampf(
		1.0 - abs(current_rpm - peak_torque_rpm) / 1200.0, 0.4, 1.0)

	if ratio == 0.0 or not engine_on:
		engine_force = 0.0
	else:
		engine_force = throttle * max_engine_force * ratio * torque_factor

	# Brakes: pedal + handbrake + engine braking
	var applied_brake := brake_input * max_brake_force
	if handbrake:
		applied_brake = max_brake_force
	elif throttle < 0.01 and ratio != 0.0 and abs(get_forward_speed()) > 0.5:
		applied_brake = max(applied_brake, engine_braking_force)
	brake = applied_brake

# ---------------------------------------------------------------------------
# WHEEL VISUALS
# ---------------------------------------------------------------------------
func _update_wheel_visuals(delta: float) -> void:
	var forward_speed := get_forward_speed()
	_wheel_spin += (forward_speed / wheel_radius) * delta
	var spin_basis := Basis(Vector3.RIGHT, _wheel_spin)
	var align_basis := Basis(Vector3.BACK, PI * 0.5)   # cylinder Y → X
	var combined := spin_basis * align_basis
	for w in _wheel_nodes:
		var m := w.get_node_or_null("Mesh") as MeshInstance3D
		if m:
			m.basis = combined

# ---------------------------------------------------------------------------
# HELPERS
# ---------------------------------------------------------------------------
func get_forward_speed() -> float:
	return linear_velocity.dot(-global_transform.basis.z)

func get_gear_name() -> String:
	match current_gear_index:
		0: return "R"
		1: return "N"
		_: return str(current_gear_index - 1)

func is_automatic() -> bool:
	return automatic
