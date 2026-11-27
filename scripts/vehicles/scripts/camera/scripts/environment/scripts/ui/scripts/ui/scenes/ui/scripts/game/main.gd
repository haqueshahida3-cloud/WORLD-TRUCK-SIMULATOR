extends Node3D
## Phase 1 orchestrator — camera switching, truck reset.

@onready var truck: Truck = get_tree().get_first_node_in_group("player") as Truck
@onready var cockpit_cam: Camera3D = $Truck/CockpitCamera
@onready var chase_cam: Camera3D = $ChaseCamera
@onready var sun: DirectionalLight3D = $Sun
@onready var world_env: WorldEnvironment = $WorldEnvironment

var _cockpit_active: bool = false

func _ready() -> void:
	chase_cam.target = truck
	chase_cam.current = true
	cockpit_cam.current = false
	# Wire the day/night script to the environment
	sun.environment = world_env.environment

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_camera"):
		_toggle_camera()
	elif event.is_action_pressed("reset_truck"):
		_reset_truck()

func _toggle_camera() -> void:
	_cockpit_active = not _cockpit_active
	chase_cam.current = not _cockpit_active
	cockpit_cam.current = _cockpit_active

func _reset_truck() -> void:
	if truck == null:
		return
	truck.global_transform = Transform3D(Basis.IDENTITY, Vector3(0.0, 2.0, 0.0))
	truck.linear_velocity = Vector3.ZERO
	truck.angular_velocity = Vector3.ZERO
