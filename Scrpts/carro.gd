extends CharacterBody3D

@export var max_speed := 20.0
@export var aceleracao := 10.0
@export var frenagem := 15.0
@export var giro := 2.5  # velocidade de rotação
@export var friccao := 5.0

var velocidade_atual := 0.0

func _physics_process(delta):
	var input_acelerar = Input.get_action_strength("move_forward")
	var input_re = Input.get_action_strength("move_backward")
	var input_direcao = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	
	# Aceleração / ré
	if input_acelerar > 0:
		velocidade_atual += aceleracao * delta
	elif input_re > 0:
		velocidade_atual -= aceleracao * delta
	else:
		# desaceleração natural
		velocidade_atual = move_toward(velocidade_atual, 0, friccao * delta)
	
	# Limite de velocidade
	velocidade_atual = clamp(velocidade_atual, -max_speed / 2, max_speed)
	
	# Rotação (só gira se estiver em movimento)
	if abs(velocidade_atual) > 0.1:
		rotate_y(-input_direcao * giro * delta * sign(velocidade_atual))
	
	# Movimento para frente baseado na rotação
	var direcao = -transform.basis.z
	velocity = direcao * velocidade_atual
	
	move_and_slide()
