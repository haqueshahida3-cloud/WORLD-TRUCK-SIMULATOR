extends Node3D
class_name ProceduralRoadBuilder

@export_group("Road System")
@export var road_system: RoadLaneSystem

@export_group("Road Appearance")
@export var road_color: Color = Color(0.12, 0.12, 0.12)
@export var shoulder_color: Color = Color(0.3, 0.3, 0.3)

@export_group("Road Dimensions")
@export var road_thickness: float = 0.25
@export var shoulder_width: float = 1.0
@export var road_surface_height: float = 0.0

@export_group("Collision")
@export var create_collision: bool = true

@export_group("Generation")
@export var generate_on_ready: bool = true

var road_mesh_instance: MeshInstance3D
var road_body: StaticBody3D
var road_material: StandardMaterial3D


func _ready() -> void:

    if generate_on_ready:
        generate_road()


# ============================================================
# MAIN ROAD GENERATOR
# ============================================================

func generate_road() -> void:

    if not is_instance_valid(road_system):
        push_warning("RoadBuilder: RoadSystem is not assigned.")
        return

    if road_system.get_lane_count() < 1:
        push_warning("RoadBuilder: No lanes available.")
        return

    clear_road()

    var direction := road_system.road_direction.normalized()

    if direction.length_squared() < 0.001:
        push_warning("RoadBuilder: Invalid road direction.")
        return

    var side := Vector3.UP.cross(direction).normalized()

    var total_width := (
        road_system.get_road_width()
        + shoulder_width * 2.0
    )

    var start := road_system.road_start
    var finish := start + direction * road_system.road_length

    var left_start := (
        start - side * total_width * 0.5
    )

    var right_start := (
        start + side * total_width * 0.5
    )

    var left_end := (
        finish - side * total_width * 0.5
    )

    var right_end := (
        finish + side * total_width * 0.5
    )

    _create_road_surface(
        left_start,
        right_start,
        left_end,
        right_end
    )

    if create_collision:
        _create_road_collision(
            left_start,
            right_start,
            left_end,
            right_end
        )


# ============================================================
# ROAD SURFACE
# ============================================================

func _create_road_surface(
    left_start: Vector3,
    right_start: Vector3,
    left_end: Vector3,
    right_end: Vector3
) -> void:

    var mesh := ArrayMesh.new()

    var vertices := PackedVector3Array([
        left_start,
        right_start,
        right_end,
        left_end
    ])

    var normals := PackedVector3Array([
        Vector3.UP,
        Vector3.UP,
        Vector3.UP,
        Vector3.UP
    ])

    var uvs := PackedVector2Array([
        Vector2(0, 0),
        Vector2(1, 0),
        Vector2(1, 1),
        Vector2(0, 1)
    ])

    var indices := PackedInt32Array([
        0, 2, 1,
        0, 3, 2
    ])

    var arrays := []
    arrays.resize(Mesh.ARRAY_MAX)

    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_NORMAL] = normals
    arrays[Mesh.ARRAY_TEX_UV] = uvs
    arrays[Mesh.ARRAY_INDEX] = indices

    mesh.add_surface_from_arrays(
        Mesh.PRIMITIVE_TRIANGLES,
        arrays
    )

    road_mesh_instance = MeshInstance3D.new()
    road_mesh_instance.name = "GeneratedRoadSurface"

    road_mesh_instance.mesh = mesh

    road_material = StandardMaterial3D.new()
    road_material.albedo_color = road_color
    road_material.roughness = 0.95
    road_material.cull_mode = BaseMaterial3D.CULL_DISABLED

    road_mesh_instance.material_override = road_material

    add_child(road_mesh_instance)

    road_mesh_instance.position.y = road_surface_height


# ============================================================
# ROAD COLLISION
# ============================================================

func _create_road_collision(
    left_start: Vector3,
    right_start: Vector3,
    left_end: Vector3,
    right_end: Vector3
) -> void:

    var center_start := (
        left_start + right_start
    ) * 0.5

    var center_end := (
        left_end + right_end
    ) * 0.5

    var length := center_start.distance_to(center_end)

    var width := left_start.distance_to(right_start)

    var collision_shape := CollisionShape3D.new()
    var box := BoxShape3D.new()

    box.size = Vector3(
        width,
        road_thickness,
        length
    )

    collision_shape.shape = box

    road_body = StaticBody3D.new()
    road_body.name = "GeneratedRoadCollision"

    road_body.position = (
        center_start + center_end
    ) * 0.5

    road_body.position.y = (
        road_surface_height - road_thickness * 0.5
    )

    road_body.add_child(collision_shape)

    add_child(road_body)


# ============================================================
# CLEAR ROAD
# ============================================================

func clear_road() -> void:

    for child in get_children():
        child.queue_free()

    road_mesh_instance = null
    road_body = null


# ============================================================
# ROAD SETTINGS
# ============================================================

func set_road_color(color: Color) -> void:

    road_color = color

    if is_instance_valid(road_material):
        road_material.albedo_color = color


func rebuild_road() -> void:
    generate_road()


func get_road_width() -> float:

    if not is_instance_valid(road_system):
        return 0.0

    return (
        road_system.get_road_width()
        + shoulder_width * 2.0
    )


func get_road_length() -> float:

    if not is_instance_valid(road_system):
        return 0.0

    return road_system.road_length
