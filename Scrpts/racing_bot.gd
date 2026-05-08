# racing_bot.gd
class_name RacingBot
extends VehicleBody3D

@export var difficulty: BotDifficultyResource
@export var debug_draw: bool = false

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var current_speed: float = 0.0
var steering_angle: float = 0.0
var _delayed_target: Vector3 = Vector3.ZERO
var _reaction_timer: float = 0.0
var race_manager: Node

func _ready() -> void:
	nav_agent.path_desired_distance = 1.5
	nav_agent.target_desired_distance = 1.5
	nav_agent.path_postprocessing = NavigationPathQueryParameters3D.PATH_POSTPROCESSING_EDGECENTERED
	
	if difficulty == null:
		difficulty = BotDifficultyResource.new()
	
	race_manager = get_tree().get_first_node_in_group("race_manager")

func _physics_process(delta: float) -> void:
	if nav_agent.is_navigation_finished():
		_request_next_checkpoint()
		return
	
	_reaction_timer += delta
	
	if _reaction_timer >= difficulty.reaction_delay:
		_reaction_timer = 0.0
		_delayed_target = nav_agent.get_next_path_position()
	
	_update_movement(delta)

func _update_movement(delta: float) -> void:
	var target_pos := _delayed_target
	var local_target := global_transform.affine_inverse() * target_pos
	
	var steer_direction := clampf(local_target.x / difficulty.path_lookahead, -1.0, 1.0)
	steer_direction += randf_range(-difficulty.steering_error, difficulty.steering_error)
	
	steering_angle = lerpf(steering_angle, steer_direction, difficulty.steering_speed * delta)
	
	var target_speed: float = difficulty.max_speed
	
	if difficulty.brake_on_curve:
		var curve_sharpness := absf(steer_direction)
		if curve_sharpness > difficulty.curve_brake_threshold:
			var brake_factor := remap(curve_sharpness, difficulty.curve_brake_threshold, 1.0, 1.0, 0.4)
			target_speed *= brake_factor
	
	if difficulty.rubber_band_enabled and race_manager:
		target_speed = _apply_rubber_band(target_speed)
	
	current_speed = move_toward(current_speed, target_speed, difficulty.acceleration * delta)
	
	engine_force = current_speed * 10.0
	steering = steering_angle

func _apply_rubber_band(base_speed: float) -> float:
	if not race_manager:
		return base_speed
	
	var player_pos: int = race_manager.get_player_race_position()
	var bot_pos: int = race_manager.get_bot_race_position(self)
	var diff: int = player_pos - bot_pos
	
	var factor: float = 1.0 - (diff * difficulty.rubber_band_strength)
	return base_speed * clampf(factor, 0.6, 1.35)

func set_navigation_target(pos: Vector3) -> void:
	nav_agent.target_position = pos

func _request_next_checkpoint() -> void:
	if race_manager:
		var next: Node3D = race_manager.get_next_checkpoint(self)
		if next:
			set_navigation_target(next.global_position)
