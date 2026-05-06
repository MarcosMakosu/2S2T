extends Node3D

@export var alvo: Node3D
@export var distancia := 1.6
@export var altura := 3.5   # aumenta para deixar mais "diagonal"
@export var suavidade := 6.0

func _process(delta):
	if alvo == null:
		return
	
	# direção do carro
	var forward = -alvo.global_transform.basis.z
	
	# posição: atrás + mais alto
	var pos_desejada = alvo.global_transform.origin \
		- forward * distancia \
		+ Vector3(0, altura, 0)
	
	global_transform.origin = global_transform.origin.lerp(pos_desejada, suavidade * delta)
	
	# olha para um ponto mais baixo que a câmera → cria o ângulo diagonal
	var alvo_olhar = alvo.global_transform.origin + Vector3(0, 1.2, 0)
	look_at(alvo_olhar, Vector3.UP)
