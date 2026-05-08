# BotDifficultyResource.gd
class_name BotDifficultyResource
extends Resource

@export_group("Velocidade")
@export var max_speed: float = 20.0
@export var acceleration: float = 10.0
@export var brake_force: float = 18.0

@export_group("Dirigibilidade")
@export var steering_speed: float = 3.0        # Quão rápido vira
@export var path_lookahead: float = 4.0        # Distância de antecipação da curva

@export_group("Comportamento")
@export var brake_on_curve: bool = true
@export var curve_brake_threshold: float = 0.6 # 0-1, menor = freia mais cedo
@export var rubber_band_enabled: bool = true   # Rubber band (kart-like)
@export var rubber_band_strength: float = 0.15 # Boost/nerf proporcional à distância

@export_group("Erros humanos")
@export var reaction_delay: float = 0.1  # Delay de reação em segundos
@export var steering_error: float = 0.05 # Desvio aleatório no volante (0 = perfeito)
