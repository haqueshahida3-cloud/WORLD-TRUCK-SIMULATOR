extends Node3D
class_name RoadJunctionGenerator

@export_group("Junction Settings")
@export var junction_width: float = 16.0
@export var junction_length: float = 16.0
@export var road_width: float = 14.0
@export var road_thickness: float = 0.3

@export_group("Road Connections")
@export var connect_north: bool = true
@export var connect_south: bool = true
@export var connect_east: bool = true
@export var connect_west: bool = true

@export_group("Appearance")
@export var road_color: Color = Color(0.12, 0.12, 0.12)
@export var generate_collision: bool = true

var junction_mesh: MeshInstance3D
var junction_body: StaticBody3D


func _ready() -> void:
    generate_junction()


# ============================================================
# GENERATE JUNCTION
# ============================================================

func generate_junction() -> void:

    clear_junction()

    if junction_width <= 0.0 or junction_length <= 0.0:
        push_warning("Junction dimensions must be positive.")
        return

    _create_surface()

    if generate_collision:
        _create_collision()


# ============================================================
# CREATE ROAD SURFACE
# ============================================================

func _create_surface() -> void:

    var vertices := PackedVector3Array()
    var indices := PackedInt32Array()
    var normals := PackedVector3Array()
    var uvs := PackedVector2Array()

    _add_rectangle(
        vertices,
        indices,
        normals,
        uvs,
        Vector2(-junction_width * 0.5, -junction_length * 0.5),
        Vector2(junction_width * 0.5, junction_length * 0.5)
    )

    if connect_north:
        _add_rectangle(
            vertices, indices, normals, uvs,
            Vector2(-road_width * 0.5, -junction_length * 0.5 - road_width * 3.0),
            Vector2(road_width * 0.5, -junction_length * 0.5)
        )

    if connect_south:
        _add_rectangle(
            vertices, indices, normals, uvs,
            Vector2(-road_width * 0.5, junction_length * 0.5),
            Vector2(road_width * 0.5, junction_length * 0.5 + road_width * 3.0)
        )

    if connect_west:
        _add_rectangle(
            vertices, indices, normals, uvs,
            Vector2(-junction_width * 0.5 - road_width * 3.0, -road_width * 0.5),
            Vector2(-junction_width * 0.5, road_width * 0.5)
        )

    if connect_east:
        _add_rectangle(
            vertices, indices, normals, uvs,
            Vector2(junction_width * 0.5, -road_width * 0.5),
            Vector2(junction_width * 0.5 + road_width * 3.0, road_width * 0.5)
        )

    var arrays := []
    arrays.resize(Mesh.ARRAY_MAX)

    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_INDEX] = indices
    arrays[Mesh.ARRAY_NORMAL] = normals
    arrays[Mesh.ARRAY_TEX_UV] = uvs

    var mesh := ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

    var material := StandardMaterial3D.new()
    material.albedo_color = road_color
    material.roughness = 1.0

    junction_mesh = MeshInstance3D.new()
    junction_mesh.name = "JunctionSurface"
    junction_mesh.mesh = mesh
    junction_mesh.material_override = material

    add_child(junction_mesh)


# ============================================================
# RECTANGLE BUILDER
# ============================================================

func _add_rectangle(
    vertices: PackedVector3Array,
    indices: PackedInt32Array,
    normals: PackedVector3Array,
    uvs: PackedVector2Array,
    minimum: Vector2,
    maximum: Vector2
) -> void:

    var start_index := vertices.size()

    vertices.append(Vector3(minimum.x, 0.0, minimum.y))
    vertices.append(Vector3(maximum.x, 0.0, minimum.y))
    vertices.append(Vector3(maximum.x, 0.0, maximum.y))
    vertices.append(Vector3(minimum.x, 0.0, maximum.y))

    for i in range(4):
        normals.append(Vector3.UP)

    uvs.append(Vector2(0, 0))
    uvs.append(Vector2(1, 0))
    uvs.append(Vector2(1, 1))
    uvs.append(Vector2(0, 1))

    indices.append(start_index)
    indices.append(start_index + 2)
    indices.append(start_index + 1)

    indices.append(start_index)
    indices.append(start_index + 3)
    indices.append(start_index + 2)


# ============================================================
# COLLISION
# ============================================================

func _create_collision() -> void:

    if junction_mesh == null or junction_mesh.mesh == null:
        return

    junction_body = StaticBody3D.new()
    junction_body.name = "JunctionCollision"

    var collision := CollisionShape3D.new()
    collision.name = "JunctionCollisionShape"

    collision.shape = junction_mesh.mesh.create_trimesh_shape()

    junction_body.add_child(collision)
    add_child(junction_body)


# ============================================================
# CLEAR
# ============================================================

func clear_junction() -> void:

    if is_instance_valid(junction_mesh):
        junction_mesh.queue_free()

    if is_instance_valid(junction_body):
        junction_body.queue_free()

    junction_mesh = null
    junction_body = null


# ============================================================
# SETTINGS
# ============================================================

func set_road_width(value: float) -> void:

    road_width = maxf(value, 1.0)
    generate_junction()


func set_junction_size(width: float, length: float) -> void:

    junction_width = maxf(width, 1.0)
    junction_length = maxf(length, 1.0)

    generate_junction()


func set_connection(
    north: bool,
    south: bool,
    east: bool,
    west: bool
) -> void:

    connect_north = north
    connect_south = south
    connect_east = east
    connect_west = west

    generate_junction()
