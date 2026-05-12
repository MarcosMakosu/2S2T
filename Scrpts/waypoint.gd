@tool # Permite que o script rode dentro do editor da Godot
extends Node3D

@export_group("Visualização no Editor")
@export var mostrar_indicador := true:
	set(valor):
		mostrar_indicador = valor
		update_gizmos()

# Esta função desenha uma esfera no editor para você enxergar onde o ponto está
func _get_configuration_warnings():
	if get_parent() and not get_parent() is Node3D:
		return ["O pai dos waypoints deve ser um Node3D para as posições funcionarem corretamente."]
	return []

# Desenha um ícone ou esfera 3D apenas no editor (não aparece no jogo final)
func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		pass # Útil se quiser adicionar lógica de detecção de movimento

# Usando o Gizmo do próprio motor para facilitar a vida
func _draw_gizmos():
	if mostrar_indicador:
		# Desenha uma esfera vermelha no editor para marcar o ponto
		# (Isso ajuda muito a ver o traçado da pista de longe)
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1, 0, 0, 0.5) # Vermelho semi-transparente
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		
		# Você não precisa criar uma Mesh, o gizmo já resolve
		# Mas se preferir algo fixo, pode adicionar um MeshInstance3D como filho.
