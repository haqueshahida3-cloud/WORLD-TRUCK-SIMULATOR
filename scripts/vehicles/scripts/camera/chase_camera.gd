extends Camera3D
## Smooth third-person chase camera. Follows a target Node3D (the truck).

@export var target: Node3D
@export var offset: Vector3 = Vector3(0.0, 3.5, 10.0)
@export var follow_speed: float = 4.0
@export var look_height: float = 1.5

func _physics_process(delta: float) -> void:
	if target == null:
		return
	# Desired world position = target's local + offset rotated by target's yaw
	var desired := target.global_transform * offset
	global_position = global_position.lerp(desired, clampf(delta * follow_speed, 0.0, 1.0))
	var look_at_point := target.global_position + Vector3(0.0, look_height, 0.0)
	look_at(look_at_point, Vector3.UP)
