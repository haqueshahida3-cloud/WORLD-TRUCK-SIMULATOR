extends Node3D
class_name JunctionTrafficLightSystem

signal signal_changed(direction: String, state: int)

enum State { RED, YELLOW, GREEN }

@export var green_duration := 25.0
@export var yellow_duration := 3.0
@export var all_red_duration := 1.5
@export var automatic_cycle := true
@export var pole_height := 5.0

var phase := 0
var timer := 25.0
var lights := {}
var materials := {}


func _ready():
    create_materials()
    create_poles()
    apply_phase()


func _process(delta):
    if not automatic_cycle:
        return

    timer -= delta

    if timer <= 0:
        phase = (phase + 1) % 6
        apply_phase()


func create_materials():
    var colors = {
        "red": Color.RED,
        "yellow": Color.YELLOW,
        "green": Color.GREEN,
        "off": Color(0.03, 0.03, 0.03)
    }

    for key in colors:
        var mat = StandardMaterial3D.new()
        mat.albedo_color = colors[key]

        if key != "off":
            mat.emission_enabled = true
            mat.emission = colors[key]

        materials[key] = mat


func create_poles():
    var positions = {
        "north": Vector3(-7, 0, -11),
        "south": Vector3(7, 0, 11),
        "east": Vector3(11, 0, -7),
        "west": Vector3(-11, 0, 7)
    }

    for direction in positions:
        var pole = MeshInstance3D.new()
        var cylinder = CylinderMesh.new()

        cylinder.height = pole_height
        cylinder.top_radius = 0.12
        cylinder.bottom_radius = 0.12

        pole.mesh = cylinder
        pole.position = positions[direction] + Vector3.UP * pole_height / 2
        add_child(pole)

        var housing = MeshInstance3D.new()
        var box = BoxMesh.new()

        box.size = Vector3(0.8, 2.2, 0.5)
        housing.mesh = box
        housing.position = pole.position + Vector3.UP * 2.7
        add_child(housing)

        var group = []

        for i in 3:
            var light = MeshInstance3D.new()
            var sphere = SphereMesh.new()

            sphere.radius = 0.28
            light.mesh = sphere
            light.position = housing.position + Vector3(0, 0.7 - i * 0.7, -0.28)
            light.material_override = materials["off"]

            add_child(light)
            group.append(light)

        lights[direction] = group


func apply_phase():
    if phase == 0 or phase == 3:
        timer = green_duration
    elif phase == 1 or phase == 4:
        timer = yellow_duration
    else:
        timer = all_red_duration

    var ns = State.RED
    var ew = State.RED

    if phase == 0:
        ns = State.GREEN
    elif phase == 1:
        ns = State.YELLOW
    elif phase == 3:
        ew = State.GREEN
    elif phase == 4:
        ew = State.YELLOW

    set_signal_state("north", ns)
    set_signal_state("south", ns)
    set_signal_state("east", ew)
    set_signal_state("west", ew)


func set_signal_state(direction: String, state: int):
    if not lights.has(direction):
        return

    var colors = ["red", "yellow", "green"]

    for i in 3:
        var key = colors[i] if i == state else "off"
        lights[direction][i].material_override = materials[key]

    signal_changed.emit(direction, state)


func force_all_red():
    for direction in lights:
        set_signal_state(direction, State.RED)


func set_automatic(enabled: bool):
    automatic_cycle = enabled
