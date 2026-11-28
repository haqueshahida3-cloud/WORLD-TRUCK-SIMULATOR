extends Node
class_name TruckDeliveryJobs

signal job_started(job: Dictionary)
signal job_progress_updated(progress: float)
signal job_completed(reward: float)
signal job_failed(reason: String)

@export_group("References")
@export var truck: VehicleBody3D
@export var wallet: Node

@export_group("Job Settings")
@export var default_reward := 5000.0
@export var delivery_time_limit := 600.0
@export var arrival_distance := 8.0

var active_job: Dictionary = {}
var job_active := false
var elapsed_time := 0.0
var delivery_progress := 0.0


func _physics_process(delta):
    if not job_active:
        return

    elapsed_time += delta
    update_delivery_progress()

    if elapsed_time >= delivery_time_limit:
        fail_job("Delivery deadline expired")


func start_job(
    job_name: String,
    pickup: Vector3,
    destination: Vector3,
    reward: float = -1.0
) -> bool:
    if job_active:
        return false

    if reward < 0.0:
        reward = default_reward

    if reward <= 0.0 or pickup.distance_to(destination) < 1.0:
        return false

    active_job = {
        "name": job_name,
        "pickup": pickup,
        "destination": destination,
        "reward": reward
    }

    job_active = true
    elapsed_time = 0.0
    delivery_progress = 0.0

    job_started.emit(active_job.duplicate(true))
    return true


func update_delivery_progress():
    if not is_instance_valid(truck):
        return

    var pickup: Vector3 = active_job["pickup"]
    var destination: Vector3 = active_job["destination"]

    var distance_to_pickup := truck.global_position.distance_to(pickup)
    var distance_to_destination := truck.global_position.distance_to(destination)

    if delivery_progress < 50.0:
        if distance_to_pickup <= arrival_distance:
            delivery_progress = 50.0
    elif distance_to_destination <= arrival_distance:
        complete_job()
        return

    job_progress_updated.emit(delivery_progress)


func complete_job():
    if not job_active:
        return

    var reward: float = active_job["reward"]

    if is_instance_valid(wallet):
        if wallet.has_method("pay_job_reward"):
            wallet.pay_job_reward(reward)

    job_active = false
    delivery_progress = 100.0

    job_completed.emit(reward)
    active_job.clear()


func fail_job(reason: String):
    if not job_active:
        return

    job_active = false
    active_job.clear()
    delivery_progress = 0.0

    job_failed.emit(reason)


func cancel_job():
    fail_job("Job cancelled")


func get_job_progress() -> float:
    return delivery_progress


func get_remaining_time() -> float:
    return maxf(delivery_time_limit - elapsed_time, 0.0)


func is_job_active() -> bool:
    return job_active
