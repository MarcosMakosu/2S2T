extends Node3D

# ── Referências ──────────────────────────────────────────────
@export var car: CharacterBody3D

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera:     Camera3D    = $SpringArm3D/Camera3D

# ── Parâmetros (ajuste no Inspector) ─────────────────────────
@export var pivot_distance:  float = 8.0    # Distância atrás do carro
@export var camera_height:   float = 2.5    # Altura em relação ao pivot
@export var look_ahead_dist: float = 4.0    # Para onde a câmera olha à frente

@export var rot_smooth:  float = 5.0   # Suavidade de rotação (horizontal)
@export var pitch_angle: float = -12.0 # Ângulo de inclinação vertical (graus)

@export var fov_base:    float = 65.0
@export var fov_max:     float = 88.0
@export var speed_fov:   float = 30.0  # m/s para atingir fov_max
@export var fov_smooth:  float = 4.0

@export var tilt_max:    float = 4.0   # Graus de inclinação em curva (roll)
@export var tilt_smooth: float = 6.0

# ── Estado interno ────────────────────────────────────────────
var _target_yaw:   float = 0.0
var _current_yaw:  float = 0.0
var _current_fov:  float = 65.0
var _current_tilt: float = 0.0

func _ready() -> void:
	# Desparentar do carro para não herdar rotação automaticamente
	top_level = true

	spring_arm.spring_length = pivot_distance
	spring_arm.position      = Vector3(0, camera_height, 0)
	spring_arm.rotation_degrees.x = pitch_angle

	_current_yaw = car.rotation.y
	_target_yaw  = _current_yaw

func _physics_process(delta: float) -> void:
	if not is_instance_valid(car):
		return

	# ── 1. Posição: segue o carro suavemente ──────────────────
	global_position = car.global_position

	# ── 2. Yaw: rotação horizontal acompanha direção do carro ─
	_target_yaw = car.rotation.y

	# Interpola o menor caminho entre ângulos (evita giro 360°)
	var yaw_diff = wrapf(_target_yaw - _current_yaw, -PI, PI)
	_current_yaw += yaw_diff * min(rot_smooth * delta, 1.0)

	rotation.y = _current_yaw

	# ── 3. Tilt: inclina em curva (roll) ──────────────────────
	var steer_input  = _get_steer_input()
	var speed        = car.velocity.length()
	var speed_ratio  = clamp(speed / speed_fov, 0.0, 1.0)
	var desired_tilt = -steer_input * tilt_max * speed_ratio

	_current_tilt = lerp(_current_tilt, desired_tilt, tilt_smooth * delta)
	rotation.z    = deg_to_rad(_current_tilt)

	# ── 4. FOV dinâmico com a velocidade ─────────────────────
	var desired_fov = lerp(fov_base, fov_max, speed_ratio)
	_current_fov    = lerp(_current_fov, desired_fov, fov_smooth * delta)
	camera.fov      = _current_fov

	# ── 5. Ponto de foco à frente do carro ───────────────────
	var look_target = car.global_position \
		+ car.global_transform.basis.z * -look_ahead_dist \
		+ Vector3.UP * camera_height
	camera.look_at(look_target, Vector3.UP)

# ── Lê o input de direção do carro ───────────────────────────
# Adapte para o seu sistema de input / variável do carro
func _get_steer_input() -> float:
	return Input.get_axis("ui_left", "ui_right")
