extends CharacterBody3D

# === Propriedades de Movimento ===
@export_group("Física do Carro")
@export var max_speed := 20.0
@export var aceleracao := 10.0
@export var frenagem := 15.0
@export var giro := 2.5
@export var friccao := 5.0
@export var gravidade := 9.8

# === Configurações da IA ===
@export_group("Configurações da IA")
@export var dificuldade := 1.0
@export var distancia_waypoint := 4.0
@export var waypoints_path: NodePath

var velocidade_atual := 0.0
var waypoints: Array = []
var waypoint_atual := 0
var ultimo_waypoint_visitado := -1 # NOVO: evita contar o mesmo waypoint duas vezes

func _ready():
	var container = get_node_or_null(waypoints_path)
	if container:
		for filho in container.get_children():
			if filho is Node3D:
				waypoints.append(filho)

	if waypoints.size() == 0:
		push_warning("BotCarro: Nenhum waypoint encontrado! Verifique o waypoints_path.")

func _physics_process(delta):
	# --- Gravidade ---
	if not is_on_floor():
		velocity.y -= gravidade * delta
	else:
		velocity.y = 0.0

	if waypoints.size() == 0:
		move_and_slide()
		return

	# --- Navegação ---
	var alvo: Node3D = waypoints[waypoint_atual]
	var direcao_alvo = alvo.global_position - global_position
	direcao_alvo.y = 0.0

	# CORRIGIDO: avança o waypoint mas não dá return,
	# o carro continua se movendo no mesmo frame
	if direcao_alvo.length() < distancia_waypoint:
		if waypoint_atual != ultimo_waypoint_visitado:
			ultimo_waypoint_visitado = waypoint_atual
			waypoint_atual = (waypoint_atual + 1) % waypoints.size()
		# Recalcula para o novo alvo imediatamente
		alvo = waypoints[waypoint_atual]
		direcao_alvo = alvo.global_position - global_position
		direcao_alvo.y = 0.0

	# --- Direção ---
	var frente_carro = -global_transform.basis.z
	frente_carro.y = 0.0
	var dir_norm = direcao_alvo.normalized()
	var angulo_para_alvo = frente_carro.signed_angle_to(dir_norm, Vector3.UP)

	# --- Velocidade ---
	var vel_max_ia = max_speed * dificuldade
	if is_on_floor():
		if abs(angulo_para_alvo) > 1.5:
			velocidade_atual = move_toward(velocidade_atual, 2.0, frenagem * delta)
		else:
			if velocidade_atual < vel_max_ia:
				velocidade_atual += aceleracao * dificuldade * delta

	velocidade_atual = clamp(velocidade_atual, 0.0, vel_max_ia)

	# --- Rotação ---
	if is_on_floor() and abs(velocidade_atual) > 0.1:
		var forca_giro = clamp(angulo_para_alvo, -giro * delta, giro * delta)
		rotate_y(forca_giro)

	# --- Movimento ---
	var direcao_movimento = -global_transform.basis.z
	velocity.x = direcao_movimento.x * velocidade_atual
	velocity.z = direcao_movimento.z * velocidade_atual
	move_and_slide()
