extends SpringArm3D

@export var camera_min_height := -0.8
@export var camera_max_height := 0.5
@export var horizontal_acceleration := 4.0
@export var vertical_acceleration := 2.0

var paused := false
var focusing := false

func _ready():
	get_parent().pause.connect(pause)
	get_parent().unpause.connect(unpause)

func pause() -> void:
	paused = true

func unpause() -> void:
	paused = false

func _physics_process(delta):
	if not paused and not focusing:
		# Prise en charge de la manette
		var joy_direction = Input.get_vector("pan_left", "pan_right", "pan_up", "pan_down")
		rotation.y -= joy_direction.x * horizontal_acceleration * delta
		rotation.x -= joy_direction.y * vertical_acceleration * delta

func _input(event):
	if not paused and not focusing and event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * 0.005
		rotation.x -= event.relative.y * 0.005
		rotation.x = clamp(rotation.x, camera_min_height, camera_max_height)
