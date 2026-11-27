extends DirectionalLight3D
## Rotates the sun and blends sky + light colours across a full day cycle.
## Attach to the main DirectionalLight3D ("Sun") node.

@export var day_length_seconds: float = 600.0
@export var environment: Environment
@export_range(0.0, 1.0) var start_time: float = 0.35   # 0.25=sunrise, 0.5=noon, 0.75=sunset

var time_of_day: float = 0.35

# Colour palette
const DAY_TOP       := Color(0.24, 0.44, 0.76)
const DAY_HORIZON   := Color(0.66, 0.79, 0.93)
const SUNSET_TOP    := Color(0.18, 0.18, 0.38)
const SUNSET_HORIZON:= Color(1.00, 0.50, 0.28)
const NIGHT_TOP     := Color(0.01, 0.02, 0.06)
const NIGHT_HORIZON := Color(0.03, 0.05, 0.13)

const SUN_DAY     := Color(1.00, 0.97, 0.90)
const SUN_SUNSET  := Color(1.00, 0.55, 0.30)
const SUN_NIGHT   := Color(0.28, 0.36, 0.62)

func _ready() -> void:
	time_of_day = start_time
	_apply()

func _process(delta: float) -> void:
	time_of_day = fmod(time_of_day + delta / day_length_seconds, 1.0)
	_apply()

func _apply() -> void:
	var sun_angle := (time_of_day - 0.25) * TAU
	rotation.x = -sun_angle

	var height: float = sin(sun_angle)                 # -1..1
	var day_factor: float = clampf(height, 0.0, 1.0)
	var night_factor: float = clampf(-height * 2.0, 0.0, 1.0)
	var sunset_factor: float = clampf(1.0 - absf(height) * 3.0, 0.0, 1.0) * clampf(height + 0.4, 0.0, 1.0)

	# ---- Sun light ----
	var col: Color = SUN_DAY
	col = col.lerp(SUN_SUNSET, sunset_factor)
	col = col.lerp(SUN_NIGHT, night_factor)
	light_color = col
	light_energy = lerp(0.05, 1.35, day_factor)

	# ---- Sky ----
	if environment and environment.sky and environment.sky.sky_material is ProceduralSkyMaterial:
		var sm := environment.sky.sky_material as ProceduralSkyMaterial
		var top: Color = DAY_TOP
		top = top.lerp(SUNSET_TOP, sunset_factor)
		top = top.lerp(NIGHT_TOP, night_factor)
		var hor: Color = DAY_HORIZON
		hor = hor.lerp(SUNSET_HORIZON, sunset_factor)
		hor = hor.lerp(NIGHT_HORIZON, night_factor)
		sm.sky_top_color = top
		sm.sky_horizon_color = hor
		sm.ground_horizon_color = hor
		sm.ground_bottom_color = top.lerp(Color.BLACK, 0.6)
		environment.ambient_light_energy = lerp(0.15, 1.0, day_factor)
