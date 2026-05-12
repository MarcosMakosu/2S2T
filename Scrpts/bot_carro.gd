extends CharacterBody3D

# === Mesmas propriedades do carro jogável ===
@export var max_speed := 20.0
@export var aceleracao := 10.0
@export var frenagem := 15.0
@export var giro := 2.5
@export var friccao := 5.0
@export var gravidade := 9.8

# === Configurações da IA ===
@export var dificuldade := 1.0          # 0.5 = fácil, 1.0 = normal, 1.5 = difícil
@export var distancia_waypoint := 3.0   # distância para considerar waypoint alcançado
@export var waypoints_path: NodePath    # arraste o nó pai dos waypoints aqui no editor

var velocidade_atual := 0.0
var waypoints: Array = []
var waypoint_atual := 0

func _ready():
	# Pega todos os waypoints filhos do nó indicado
	var container = get_node_or_null(waypoints_path)
	if container:
		for filho in container.get_children():
			waypoints.append(filho)
	else:
		push_warning("BotCarro: waypoints_path não definido ou inválido!")

func _physics_process(delta):
	# --- Gravidade ---
	if not is_on_floor():
		velocity.y -= gravidade * delta
	else:
		velocity.y = 0.0

	if waypoints.size() == 0:
		move_and_slide()
		return

	var alvo: Node3D = waypoints[waypoint_atual]
	var direcao_alvo = (alvo.global_position - global_position)
	direcao_alvo.y = 0.0  # ignora diferença vertical

	# --- Verifica se chegou no waypoint ---
	if direcao_alvo.length() < distancia_waypoint:
		waypoint_atual = (waypoint_atual + 1) % waypoints.size()

	# --- Calcula o quanto precisa girar ---
	var frente = -transform.basis.z
	frente.y = 0.0
	frente = frente.normalized()
	var dir_norm = direcao_alvo.normalized()

	# Produto cruzado para saber se vira esquerda ou direita
	var cross = frente.cross(dir_norm).y
	# Produto escalar para saber se o alvo está na frente ou atrás
	var dot = frente.dot(dir_norm)

	# --- Aceleração com dificuldade aplicada ---
	var velocidade_max_ajustada = max_speed * dificuldade

	if is_on_floor():
		# Freia em curvas fechadas
		var fator_curva = clamp(abs(cross), 0.0, 1.0)
		if dot > 0.2:
			# Reduz velocidade proporcional à curva
			var vel_alvo = lerp(velocidade_max_ajustada, velocidade_max_ajustada * 0.4, fator_curva)
			if velocidade_atual < vel_alvo:
				velocidade_atual += aceleracao * dificuldade * delta
			else:
				velocidade_atual = move_toward(velocidade_atual, vel_alvo, frenagem * delta)
		else:
			# Alvo atrás: freia forte e vai devagar
			velocidade_atual = move_toward(velocidade_atual, 2.0, frenagem * delta)

	# Limite de velocidade
	velocidade_atual = clamp(velocidade_atual, 0.0, velocidade_max_ajustada)

	# --- Rotação suave em direção ao waypoint ---
	if is_on_floor() and abs(velocidade_atual) > 0.1:
		# Intensidade do giro proporcional ao erro angular
		var intensidade = clamp(abs(cross) * 2.0, 0.0, 1.0)
		rotate_y(-sign(cross) * giro * intensidade * dificuldade * delta)

	# --- Movimento ---
	var direcao_frente = -transform.basis.z
	velocity.x = direcao_frente.x * velocidade_atual
	velocity.z = direcao_frente.z * velocidade_atual

	move_and_slide()
