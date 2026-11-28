extends Node3D
class_name CurvedRoadGenerator

signal road_generated
signal road_generation_failed(reason: String)

@export_group("Road Path")
@export var control_points: Array[Vector3] = [
    Vector3(0, 0, 0),
    Vector3(0, 0, -50),
    Vector3(20, 0, -100),
    Vector3(20, 0, -150)
]

@export_group("Road Dimensions")
@export var road_width: float = 14.0
@export var road_thickness: float = 0.25

@export_group("Curve Quality")
@export_range(2, 32) var subdivisions: int = 8

@export_group("Appearance")
@export var road_color: Color = Color(0.12, 0.12, 0.12)

@export_group("Collision")
@export var generate_collision: bool = true

var generated_mesh: MeshInstance3D
var generated_body: StaticBody3D
var road_points: PackedVector3Array = []


func _ready() -> void:
    generate_road()


# ============================================================
# GENERATE ROAD
# ============================================================

func generate_road() -> void:

    clear_road()

    if control_points.size() < 2:
        road_generation_failed.emit(
            "At least two control points are required."
        )
        return

    road_points = _calculate_curve_points()

    if road_points.size() < 2:
        road_generation_failed.emit(
            "Could not generate curve points."
        )
        return

    _build_road_mesh()

    if generate_collision:
        _build_road_collision()

    road_generated.emit()


# ============================================================
# CATMULL ROM CURVE
# ============================================================

func _calculate_curve_points() -> PackedVector3Array:

    var result := PackedVector3Array()

    for i in range(control_points.size() - 1):

        var p0 := control_points[maxi(i - 1, 0)]
        var p1 := control_points[i]
        var p2 := control_points[i + 1]
        var p3 := control_points[
            mini(i + 2, control_points.size() - 1)
        ]

        for step in range(subdivisions):

            var t := float(step) / float(subdivisions)

            var point := _catmull_rom(
                p0, p1, p2, p3, t
            )

            result.append(point)

    result.append(control_points[
        control_points.size() - 1
    ])

    return result


func _catmull_rom(
    p0: Vector3,
    p1: Vector3,
    p2: Vector3,
    p3: Vector3,
    t: float
) -> Vector3:

    var t2 := t * t
    var t3 := t2 * t

    return 0.5 * (
        2.0 * p1
        + (-p0 + p2) * t
        + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
        + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
    )


# ============================================================
# ROAD MESH
# ============================================================

func _build_road_mesh() -> void:

    var vertices := PackedVector3Array()
    var normals := PackedVector3Array()
    var uvs := PackedVector2Array()
    var indices := PackedInt32Array()

    var half_width := road_width * 0.5

    for i in range(road_points.size()):

        var forward := _get_forward(i)

        var side := Vector3.UP.cross(
            forward
        ).normalized()

        var left := road_points[i] - side * half_width
        var right := road_points[i] + side * half_width

        vertices.append(left)
        vertices.append(right)

        normals.append(Vector3.UP)
        normals.append(Vector3.UP)

        var distance := _distance_to_point(i)

        uvs.append(Vector2(0.0, distance / 5.0))
        uvs.append(Vector2(1.0, distance / 5.0))

    for i in range(road_points.size() - 1):

        var a := i * 2
        var b := a + 1
        var c := a + 2
        var d := a + 3

        indices.append_array([
            a, c, b,
            b, c, d
        ])

    var arrays := []
    arrays.resize(Mesh.ARRAY_MAX)

    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_NORMAL] = normals
    arrays[Mesh.ARRAY_TEX_UV] = uvs
    arrays[Mesh.ARRAY_INDEX] = indices

    var mesh := ArrayMesh.new()

    mesh.add_surface_from_arrays(
        Mesh.PRIMITIVE_TRIANGLES,
        arrays
    )

    generated_mesh = MeshInstance3D.new()
    generated_mesh.name = "CurvedRoadSurface"
    generated_mesh.mesh = mesh

    var material := StandardMaterial3D.new()

    material.albedo_color = road_color
    material.roughness = 0.95
    material.cull_mode = BaseMaterial3D.CULL_DISABLED

    generated_mesh.material_override = material

    add_child(generated_mesh)


# ============================================================
# ROAD COLLISION
# ============================================================

func _build_road_collision() -> void:

    var collision_mesh := ArrayMesh.new()

    var vertices := PackedVector3Array()
    var indices := PackedInt32Array()

    var half_width := road_width * 0.5

    for i in range(road_points.size()):

        var forward := _get_forward(i)

        var side := Vector3.UP.cross(
            forward
        ).normalized()

        vertices.append(
            road_points[i] - side * half_width
        )

        vertices.append(
            road_points[i] + side * half_width
        )

    for i in range(road_points.size() - 1):

        var a := i * 2
        var b := a + 1
        var c := a + 2
        var d := a + 3

        indices.append_array([
            a, c, b,
            b, c, d
        ])

    var arrays := []
    arrays.resize(Mesh.ARRAY_MAX)

    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_INDEX] = indices

    collision_mesh.add_surface_from_arrays(
        Mesh.PRIMITIVE_TRIANGLES,
        arrays
    )

    generated_body = StaticBody3D.new()
    generated_body.name = "CurvedRoadCollision"

    var collision_shape := CollisionShape3D.new()

    collision_shape.shape = (
        collision_mesh.create_trimesh_shape()
    )

    generated_body.add_child(collision_shape)

    add_child(generated_body)


# ============================================================
# DIRECTION HELPERS
# ============================================================

func _get_forward(index: int) -> Vector3:

    var previous := road_points[
        maxi(index - 1, 0)
    ]

    var next := road_points[
        mini(index + 1, road_points.size() - 1)
    ]

    var direction := next - previous

    direction.y = 0.0

    if direction.length_squared() < 0.0001:
        return Vector3(0, 0, -1)

    return direction.normalized()


func _distance_to_point(index: int) -> float:

    var total := 0.0

    for i in range(1, index + 1):

        total += road_points[i - 1].distance_to(
            road_points[i]
        )

    return total


# ============================================================
# ROAD MANAGEMENT
# ============================================================

func clear_road() -> void:

    if is_instance_valid(generated_mesh):
        generated_mesh.queue_free()

    if is_instance_valid(generated_body):
        generated_body.queue_free()

    generated_mesh = null
    generated_body = null

    road_points.clear()


func rebuild_road() -> void:
    generate_road()


func get_road_points() -> PackedVector3Array:
    return road_points


func get_road_point_count() -> int:
    return road_points.size()


func get_road_length() -> float:

    var total := 0.0

    for i in range(1, road_points.size()):

        total += road_points[i - 1].distance_to(
            road_points[i]
        )

    return total


func set_road_width(value: float) -> void:

    road_width = maxf(value, 2.0)
    generate_road()
