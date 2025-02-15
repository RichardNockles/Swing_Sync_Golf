extends RigidBody3D

@export var power_multiplier: float = 20.0
@export var mouse_sensitivity: float = 0.2
@export var camera_distance: float = 4.0
@export var camera_height: float = 1.5
@export var charge_speed: float = 0.3
@export var stop_threshold: float = 0.1

@onready var ball_camera = $BallCamera

var is_aiming: bool = true
var is_moving: bool = false
var shot_power: float = 0.0

signal hole_completed

func _ready():
    print("🏌️ Golf Ball Ready!")
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    freeze = false
    # Initial camera setup (still needed)
    ball_camera.global_transform.origin = global_transform.origin + Vector3(0, camera_height, -camera_distance)
    ball_camera.look_at(global_transform.origin, Vector3.UP)

func _unhandled_input(event):
    if is_aiming:
        if event is InputEventMouseMotion:
            rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))

        if event.is_action_pressed("swing"):
            shot_power = 0.1
        if event.is_action_released("swing"):
            _hit_ball()

func _process(delta):
    if is_aiming and Input.is_action_pressed("swing"):
        shot_power = min(1.0, shot_power + delta * charge_speed)

func _physics_process(_delta):
    if is_moving:
        if linear_velocity.length() < stop_threshold:
            linear_velocity = Vector3.ZERO
            angular_velocity = Vector3.ZERO
            is_moving = false
            is_aiming = true
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

        # Camera follow *ONLY WHILE MOVING*
        ball_camera.global_transform.origin = global_transform.origin + Vector3(0, camera_height, -camera_distance)
        ball_camera.look_at(global_transform.origin, Vector3.UP)

func _hit_ball():
    if is_aiming:
        print("🏌️ Hitting Ball! Power:", shot_power)
        is_aiming = false
        is_moving = true
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

        var direction = -transform.basis.z
        apply_impulse(direction * shot_power * power_multiplier)

        shot_power = 0.0
        freeze = false

func _on_HoleTrigger_body_entered(body):
    if body == self:
        print("🏆 Ball in the hole!")
        hole_completed.emit()
        set_deferred("sleeping", true)
