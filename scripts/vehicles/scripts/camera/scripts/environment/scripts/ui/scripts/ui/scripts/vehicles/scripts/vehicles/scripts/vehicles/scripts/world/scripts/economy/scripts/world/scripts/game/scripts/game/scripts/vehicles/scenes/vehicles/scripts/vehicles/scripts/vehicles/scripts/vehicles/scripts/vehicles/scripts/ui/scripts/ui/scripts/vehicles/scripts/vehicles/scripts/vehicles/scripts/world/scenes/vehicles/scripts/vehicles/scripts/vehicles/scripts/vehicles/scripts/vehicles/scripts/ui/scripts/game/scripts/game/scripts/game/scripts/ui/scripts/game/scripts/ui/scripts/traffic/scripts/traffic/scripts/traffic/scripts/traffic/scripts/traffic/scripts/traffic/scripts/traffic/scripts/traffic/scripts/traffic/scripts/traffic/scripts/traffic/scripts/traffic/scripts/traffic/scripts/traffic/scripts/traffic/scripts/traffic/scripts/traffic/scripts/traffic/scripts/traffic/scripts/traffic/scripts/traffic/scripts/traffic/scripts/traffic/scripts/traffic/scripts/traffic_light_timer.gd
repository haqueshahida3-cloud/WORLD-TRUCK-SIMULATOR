extends Node3D
class_name TrafficLightTimer

@export var traffic_light: JunctionTrafficLightSystem
@export var display_height := 7.8
@export var display_distance := 11.0
@export var font_size := 96

var displays := {}

var positions = {
    "north": Vector3(-7, 0, -11),
    "south": Vector3(7, 0, 11),
    "east": Vector3(11, 0, -7),
    "west": Vector3(-11, 0, 7)
}


func _ready():
    create_displays()


func _process(_delta):
    if not is_instance_valid(traffic_light):
        return

    update_displays()


func create_displays():
    for direction in positions:
        var label = Label3D.new()

        label.name = direction + "_Timer"
        label.font_size = font_size
        label.pixel_size = 0.01
        label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        label.no_depth_test = true
        label.outline_size = 12
        label.text = "25"

        add_child(label)

        label.position = positions[direction] + Vector3.UP * display_height
        displays[direction] = label


func update_displays():
    var seconds = maxi(ceili(traffic_light.timer), 0)

    var color = Color.GREEN

    if traffic_light.phase == 1 or traffic_light.phase == 4:
        color = Color.YELLOW
    elif traffic_light.phase == 2 or traffic_light.phase == 5:
        color = Color.RED

    for direction in displays:
        var label: Label3D = displays[direction]
        label.text = str(seconds)
        label.modulate = color


func set_display_visible(enabled: bool):
    visible = enabled


func reset_display():
    for direction in displays:
        displays[direction].text = "25"
