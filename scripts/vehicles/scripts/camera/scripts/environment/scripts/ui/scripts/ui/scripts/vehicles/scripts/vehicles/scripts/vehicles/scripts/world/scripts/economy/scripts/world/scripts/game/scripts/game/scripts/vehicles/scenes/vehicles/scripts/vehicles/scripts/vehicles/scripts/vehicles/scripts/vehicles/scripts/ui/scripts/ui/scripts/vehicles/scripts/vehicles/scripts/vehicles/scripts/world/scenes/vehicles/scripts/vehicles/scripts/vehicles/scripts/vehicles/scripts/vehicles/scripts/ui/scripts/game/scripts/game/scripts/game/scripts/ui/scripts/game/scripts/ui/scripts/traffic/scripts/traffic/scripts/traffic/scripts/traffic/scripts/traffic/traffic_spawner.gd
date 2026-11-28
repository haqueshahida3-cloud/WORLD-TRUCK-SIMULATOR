extends Node3D
class_name TrafficSpawner

signal vehicle_spawned(vehicle: Node3D)
signal vehicle_despawned(vehicle: Node3D)

@export_group("Vehicle Settings")
@export var vehicle_scenes: Array[PackedScene] = []
@export var maximum_vehicles: int = 12

@export_group("Spawn Points")
@export var spawn_points: Array[Node3D] = []
@export var minimum_spawn_distance: float = 40.0
@export var maximum_spawn_distance: float = 250.0

@export_group("Despawn Settings")
@export var despawn_distance: float = 400.0
@export var player: Node3D

@export_group("Performance")
@export var spawn_interval: float = 3.0
@export var update_interval: float = 1.0
@export var automatic_spawning: bool = true

var spawned_vehicles: Array[Node3D] = []

var spawn_timer: float = 0.0
var update_timer: float = 0.0

var random := RandomNumberGenerator.new()


func _ready() -> void:

    add_to_group("traffic_spawner")

    random.randomize()
    _find_player()


func _process(delta: float) -> void:

    _find_player()

    if not is_instance_valid(player):
        return

    update_timer += delta

    if update_timer >= update_interval:
        update_timer = 0.0
        _remove_invalid_vehicles()
        _despawn_distant_vehicles()

    if not automatic_spawning:
        return

    spawn_timer += delta

    if spawn_timer >= spawn_interval:
        spawn_timer = 0.0

        if spawned_vehicles.size() < maximum_vehicles:
            spawn_vehicle()


# ============================================================
# FIND PLAYER
# ============================================================

func _find_player() -> void:

    if is_instance_valid(player):
        return

    var found := get_tree().get_first_node_in_group("player")

    if found is Node3D:
        player = found as Node3D


# ============================================================
# SPAWN VEHICLE
# ============================================================

func spawn_vehicle() -> Node3D:

    if vehicle_scenes.is_empty():
        push_warning("TrafficSpawner: No vehicle scenes assigned.")
        return null

    if spawn_points.is_empty():
        push_warning("TrafficSpawner: No spawn points assigned.")
        return null

    if spawned_vehicles.size() >= maximum_vehicles:
        return null

    if not is_instance_valid(player):
        return null

    var spawn_point := _find_valid_spawn_point()

    if not is_instance_valid(spawn_point):
        return null

    var scene_index := random.randi_range(
        0,
        vehicle_scenes.size() - 1
    )

    var selected_scene := vehicle_scenes[scene_index]

    if selected_scene == null:
        return null

    var instance := selected_scene.instantiate()

    if not instance is Node3D:
        instance.free()
        push_warning("Traffic vehicle root must be Node3D.")
        return null

    var vehicle := instance as Node3D

    get_tree().current_scene.add_child(vehicle)

    vehicle.global_transform = spawn_point.global_transform

    spawned_vehicles.append(vehicle)

    vehicle_spawned.emit(vehicle)

    return vehicle


# ============================================================
# FIND VALID SPAWN POINT
# ============================================================

func _find_valid_spawn_point() -> Node3D:

    var valid_points: Array[Node3D] = []

    for point in spawn_points:

        if not is_instance_valid(point):
            continue

        var distance := player.global_position.distance_to(
            point.global_position
        )

        if distance >= minimum_spawn_distance \
        and distance <= maximum_spawn_distance:

            valid_points.append(point)

    if valid_points.is_empty():
        return null

    var index := random.randi_range(
        0,
        valid_points.size() - 1
    )

    return valid_points[index]


# ============================================================
# DESPAWN DISTANT VEHICLES
# ============================================================

func _despawn_distant_vehicles() -> void:

    if not is_instance_valid(player):
        return

    for i in range(spawned_vehicles.size() - 1, -1, -1):

        var vehicle := spawned_vehicles[i]

        if not is_instance_valid(vehicle):
            spawned_vehicles.remove_at(i)
            continue

        var distance := player.global_position.distance_to(
            vehicle.global_position
        )

        if distance > despawn_distance:

            spawned_vehicles.remove_at(i)

            vehicle_despawned.emit(vehicle)

            vehicle.queue_free()


# ============================================================
# REMOVE INVALID REFERENCES
# ============================================================

func _remove_invalid_vehicles() -> void:

    for i in range(spawned_vehicles.size() - 1, -1, -1):

        if not is_instance_valid(spawned_vehicles[i]):
            spawned_vehicles.remove_at(i)


# ============================================================
# MANUAL CONTROLS
# ============================================================

func set_spawning_enabled(enabled: bool) -> void:
    automatic_spawning = enabled


func clear_all_traffic() -> void:

    for vehicle in spawned_vehicles:

        if is_instance_valid(vehicle):
            vehicle.queue_free()

    spawned_vehicles.clear()


func get_vehicle_count() -> int:
    _remove_invalid_vehicles()
    return spawned_vehicles.size()


func set_maximum_vehicles(amount: int) -> void:
    maximum_vehicles = maxi(amount, 0)
