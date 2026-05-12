extends CharacterBody3D

# === Propriedades de Movimento (Igual ao seu Player) ===
@export_group("Física do Carro")
@export var max_speed := 20.0
@export var aceleracao := 10.0
@export var frenagem := 15.0
@export var giro := 2.5
@export var friccao := 5.0
@export var gravidade := 9.8

# === Configurações da IA ===
@export_group("Configurações da IA")
@export var dificuldade := 1.0          # 0.5 = fácil, 1.0 = normal, 1.5 = difícil
@export var distancia_waypoint := 4.0   # Raio de detecção do ponto
@export var waypoints_path: NodePath    # Arraste o nó pai dos waypoints aqui

var velocidade_atual := 0.0
var waypoints: Array = []
var waypoint_atual := 0

func _ready():
	# Inicializa a lista de waypoints
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

	# Se não houver caminho, o bot não se move
	if waypoints.size() == 0:
		move_and_slide()
		return

	# --- Lógica de Navegação ---
	var alvo: Node3D = waypoints[waypoint_atual]
	var direcao_alvo = (alvo.global_position - global_position)
	direcao_alvo.y = 0.0 # Ignora altura para o cálculo de direção

	# Verifica se chegou no ponto atual para focar no próximo
	if direcao_alvo.length() < distancia_waypoint:
		waypoint_atual = (waypoint_atual + 1) % waypoints.size()
		return

	# --- Cálculo de Direção (Onde o bot precisa olhar) ---
	var frente_carro = -global_transform.basis.z # Na Godot, -Z é a frente
	frente_carro.y = 0
	var dir_norm = direcao_alvo.normalized()

	# Calcula o ângulo necessário para encarar o alvo
	var angulo_para_alvo = frente_carro.signed_angle_to(dir_norm, Vector3.UP)

	# --- Controle de Velocidade ---
	var vel_max_ia = max_speed * dificuldade

	if is_on_floor():
		# Se o alvo estiver muito "atrás" (curva muito fechada), ele freia
		if abs(angulo_para_alvo) > 1.5: # Aproximadamente 85-90 graus
			velocidade_atual = move_toward(velocidade_atual, 2.0, frenagem * delta)
		else:
			# Acelera até o limite da dificuldade
			if velocidade_atual < vel_max_ia:
				velocidade_atual += aceleracao * dificuldade * delta
	
	# Aplica fricção se não estiver acelerando (segurança)
	if velocidade_atual > 0:
		velocidade_atual = clamp(velocidade_atual, 0.0, vel_max_ia)
	
	# --- Aplica a Rotação ---
	if is_on_floor() and abs(velocidade_atual) > 0.1:
		# Suaviza o giro baseado na variável 'giro'
		var forca_giro = clamp(angulo_para_alvo, -giro * delta, giro * delta)
		rotate_y(forca_giro)

	# --- Movimento Final ---
	var direcao_movimento = -global_transform.basis.z
	velocity.x = direcao_movimento.x * velocidade_atual
	velocity.z = direcao_movimento.z * velocidade_atual

	move_and_slide()
