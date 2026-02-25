extends Node

@export var mob_scene: PackedScene
@export var powerup_scene: PackedScene
@export var mob_path: Path2D
@export var mod_spawn_location: PathFollow2D

var score = 0

# Variables de tiempo para efectos
var dash_time_left = 0.0
var shield_time_left = 0.0
var enemy_more_time_left = 0.0
var enemy_fast_time_left = 0.0
var player_big_time_left = 0.0
var player_slow_time_left = 0.0

func _ready() -> void:
	$HUD.update_score(score)

func game_over():
	$ScoreTimer.stop()
	$MobTimer.stop()
	$PowerUpTimer.stop()
	$EffectTimer.stop()
	$HUD.show_game_over()
	$Music.stop()
	$DeathSound.play()
	$HUD.update_effects_display("") # Limpia la lista de efectos al morir
	_reset_effects()

func _reset_effects():
	dash_time_left = 0
	shield_time_left = 0
	enemy_more_time_left = 0
	enemy_fast_time_left = 0
	player_big_time_left = 0
	player_slow_time_left = 0
	_apply_effects()

func new_game():
	score = 0
	$HUD.update_score(score)
	_reset_effects() # Esto ya limpia todas las variables de arriba
	
	$HUD.show_message("Get Ready")
	$Player.start($StartPosition.position)
	
	# Limpiar enemigos viejos
	get_tree().call_group("mobs", "queue_free")

	$Music.play()
	$StartTimer.start()

func _on_start_timer_timeout() -> void:
	$MobTimer.start()
	$ScoreTimer.start()
	$PowerUpTimer.start()
	$EffectTimer.start()


func _on_mob_timer_timeout():
	var mob_spawn_location: PathFollow2D = $MobPath/MobSpawnLocation
	var mob = mob_scene.instantiate()
	# var mob_spawn_location = $MobPath/MobSpawnLocation
	mob_spawn_location.progress_ratio = randf()

	mob.position = mob_spawn_location.position
	var direction = mob_spawn_location.rotation + PI / 2
	direction += randf_range(-PI / 4, PI / 4)
	mob.rotation = direction

	# Lógica de velocidad dinámica
	var speed_min = 150.0
	var speed_max = 250.0
	if enemy_fast_time_left > 0:
		speed_min *= 1.5 # Aumentado un poco más para que se note
		speed_max *= 2.0

	var velocity = Vector2(randf_range(speed_min, speed_max), 0.0)
	mob.linear_velocity = velocity.rotated(direction)

	add_child(mob)
	# IMPORTANTE: Asegúrate que el Mob tenga el grupo "mobs" en su escena.

	# Spawn extra si el efecto está activo
	if enemy_more_time_left > 0 and randf() < 0.30: # Subí la probabilidad a 30%
		_spawn_extra_mob(speed_min, speed_max)

func _spawn_extra_mob(s_min, s_max):
	var mob2 = mob_scene.instantiate()
	var loc = $MobPath/MobSpawnLocation
	loc.progress_ratio = randf()
	mob2.position = loc.position
	var dir = loc.rotation + PI / 2 + randf_range(-PI / 4, PI / 4)
	mob2.rotation = dir
	mob2.linear_velocity = Vector2(randf_range(s_min, s_max), 0.0).rotated(dir)
	add_child(mob2)

func _on_score_timer_timeout() -> void:
	score += 1
	$HUD.update_score(score)

func _on_hud_start_game() -> void:
	new_game()

func _on_power_up_timer_timeout() -> void:
	if powerup_scene == null: return
	
	var p = powerup_scene.instantiate()
	var screen = get_viewport().get_visible_rect().size
	# Margen de seguridad para que no aparezcan pegados al borde
	p.position = Vector2(randf_range(100, screen.x - 100), randf_range(100, screen.y - 100))
	
	p.type = randi_range(0, 12) # Cambiado a 12 porque tu match llega hasta 12
	p.collected.connect(_on_powerup_collected)
	add_child(p)

# Variable para activar/desactivar el modo debug fácilmente
var debug_mode = true


func _on_powerup_collected(power_type):
	# Lista para el DEBUG (Debe tener 13 elementos, del 0 al 12)
	var power_names = [
		"DASH", "SHIELD", "ENEMY_MORE", "ENEMY_FAST", "PLAYER_BIG", 
		"PLAYER_SLOW", "SCORE_PLUS_5", "SCORE_PLUS_10", "SCORE_PLUS_50", 
		"SCORE_MINUS_5", "SCORE_MINUS_10", "SCORE_MINUS_50", "KILL_ALL"
	]

	match power_type:
		0: dash_time_left += 15
		1: shield_time_left += 10
		2: enemy_more_time_left += 10
		3: enemy_fast_time_left += 10
		4: player_big_time_left += 7
		5: player_slow_time_left += 7
		6: score += 5
		7: score += 10
		8: score += 50
		9: score -= 5
		10: score -= 10
		11: score -= 50
		12: 
			get_tree().call_group("mobs", "queue_free")

	$HUD.update_score(score)
	_apply_effects()
	
	if debug_mode:
		print("RECOGIDO: ", power_names[power_type], " (ID: ", power_type, ")")

'''func _on_powerup_collected(power_type):
	# ... (Tu lógica de match está perfecta)
	match power_type:
		0: dash_time_left += 15 # Usar += permite acumular tiempo si agarras dos
		1: shield_time_left += 10
		2: enemy_more_time_left += 10
		3: enemy_fast_time_left += 10
		4: player_big_time_left += 7
		5: player_slow_time_left += 7
		6: score += 5
		7: score += 10
		8: score += 50
		9: score -= 5
		10: score -= 10
		11: score -= 50
		12: get_tree().call_group("mobs", "queue_free")

	$HUD.update_score(score)
	_apply_effects() # Aplicar inmediatamente al recoger
'''
func _on_effect_timer_timeout() -> void:
	# Decrementar todos los efectos
	dash_time_left = max(0, dash_time_left - 1)
	shield_time_left = max(0, shield_time_left - 1)
	enemy_more_time_left = max(0, enemy_more_time_left - 1)
	enemy_fast_time_left = max(0, enemy_fast_time_left - 1)
	player_big_time_left = max(0, player_big_time_left - 1)
	player_slow_time_left = max(0, player_slow_time_left - 1)

	_apply_effects()
	
	# 2. Construir el texto para el HUD
	var effects_text = ""
	
	if dash_time_left > 0:
		effects_text += "DASH: %ds\n" % dash_time_left
	if shield_time_left > 0:
		effects_text += "ESCUDO: %ds\n" % shield_time_left
	if player_big_time_left > 0:
		effects_text += "GIGANTE: %ds\n" % player_big_time_left
	if player_slow_time_left > 0:
		effects_text += "LENTO: %ds\n" % player_slow_time_left
	if enemy_more_time_left > 0:
		effects_text += "HORDAS: %ds\n" % enemy_more_time_left
		
	# 3. Enviar al HUD
	$HUD.update_effects_display(effects_text)
	
	# Si hay algún efecto activo, mostrar el tiempo restante en consola cada segundo
	if debug_mode and _any_effect_active():
		_print_status_report()

func _apply_effects():
	# Verificamos si el nodo Player existe para evitar errores en el cierre del juego
	if not has_node("Player"): return
	
	var player = $Player
	player.shield_active = shield_time_left > 0
	player.dash_enabled = dash_time_left > 0

	# Ajuste de escala suave o directo
	player.scale = Vector2(1.2, 1.2) if player_big_time_left > 0 else Vector2(0.5, 0.5)
	
	# Ajuste de velocidad
	player.speed = 250 if player_slow_time_left > 0 else 400

# Función auxiliar para ver el estado en consola
func _print_status_report():
	print("TIEMPOS ACTIVOS: " + 
		"Dash: %s | " % dash_time_left +
		"Escudo: %s | " % shield_time_left +
		"PlayerBig: %s | " % player_big_time_left +
		"PlayerSlow: %s" % player_slow_time_left
	)

func _any_effect_active() -> bool:
	return dash_time_left > 0 or shield_time_left > 0 or player_big_time_left > 0 or player_slow_time_left > 0
