
extends DirectionalLight3D
class_name DayNightCycle

@export_group("Time")
@export_range(0.0, 24.0) var start_time: float = 8.0
@export var time_speed: float = 60.0
@export var auto_cycle: bool = true

@export_group("Sun")
@export var sunrise_hour: float = 6.0
@export var sunset_hour: float = 18.0
@export var day_energy: float = 1.2
@export var night_energy: float = 0.05

@export_group("Environment")
@export var environment_node: WorldEnvironment
@export var day_color: Color = Color(0.65, 0.8, 1.0)
@export var sunset_color: Color = Color(1.0, 0.55, 0.3)
@export var night_color: Color = Color(0.025, 0.04, 0.12)

var current_time: float = 8.0
var sun_energy: float = 1.0


func _ready() -> void:
    current_time = start_time
    _update_world()


func _process(delta: float) -> void:
    if auto_cycle:
        current_time += (delta * time_speed) / 3600.0
        current_time = fmod(current_time, 24.0)

    _update_world()


func _update_world() -> void:
    var sun_angle := (current_time / 24.0) * 360.0 - 90.0

    rotation_degrees.x = sun_angle
    rotation_degrees.y = -35.0

    var daylight := _get_daylight_factor()

    light_energy = lerpf(
        night_energy,
        day_energy,
        daylight
    )

    _update_sky(daylight)


func _get_daylight_factor() -> float:
    var sunrise := sunrise_hour
    var sunset := sunset_hour

    if current_time < sunrise or current_time > sunset:
        return 0.0

    var progress := (
        (current_time - sunrise) /
        (sunset - sunrise)
    )

    return sin(progress * PI)


func _update_sky(daylight: float) -> void:
    if environment_node == null:
        return

    var env := environment_node.environment

    if env == null:
        return

    var sky_color: Color

    if current_time >= 17.0 and current_time <= 19.0:
        var sunset_blend := clampf(
            (current_time - 17.0) / 2.0,
            0.0,
            1.0
        )
        sky_color = day_color.lerp(
            sunset_color,
            sunset_blend
        )
    elif daylight > 0.0:
        sky_color = night_color.lerp(
            day_color,
            daylight
        )
    else:
        sky_color = night_color

    env.background_mode = Environment.BG_SKY

    if env.sky != null and env.sky.sky_material is ProceduralSkyMaterial:
        var sky := env.sky.sky_material as ProceduralSkyMaterial
        sky.sky_top_color = sky_color
        sky.sky_horizon_color = sky_color.lightened(0.25)


func set_time(hour: float) -> void:
    current_time = wrapf(hour, 0.0, 24.0)
    _update_world()


func get_time_string() -> String:
    var hour := int(current_time)
    var minute := int((current_time - hour) * 60.0)

    return "%02d:%02d" % [hour, minute]


func pause_time() -> void:
    auto_cycle = false


func resume_time() -> void:
    auto_cycle = true
