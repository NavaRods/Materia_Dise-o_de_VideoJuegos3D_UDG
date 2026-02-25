extends Area2D

@onready var icon = $Sprite2D

var lifetime = 10.0 # El powerup durará 10 segundos en total

enum PowerType {
	DASH,
	SHIELD,
	ENEMY_MORE,
	ENEMY_FAST,
	PLAYER_BIG,
	PLAYER_SLOW,
	SCORE_PLUS_5,
	SCORE_PLUS_10,
	SCORE_PLUS_50,
	SCORE_MINUS_5,
	SCORE_MINUS_10,
	SCORE_MINUS_50,
	KILL_ALL
}

@export var type: PowerType
signal collected(power_type)

func _ready():
	# Primero, nos aseguramos de que el icono se cargue
	_setup_visuals() 
	
	# Usamos la sintaxis moderna de Godot 4 para conectar
	# Esto asegura que la señal esté vinculada correctamente
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	
	# Creamos un timer por código para la desaparición
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(_on_lifetime_timeout)

func _process(delta):
	lifetime -= delta
	
	# 1. Validamos que el objeto no esté marcado para borrarse
	if is_queued_for_deletion():
		return
	# Si quedan menos de 5 segundos, empezamos el parpadeo
	if lifetime <= 5.0:
		# 2. Verificamos que el icono sea válido
		if is_instance_valid(icon):
			var speed = 15.0
			icon.modulate.a = (sin(Time.get_ticks_msec() * 0.01 * speed) + 1.0) / 2.0

func _on_lifetime_timeout():
	queue_free()

func _setup_visuals():
	var path = "res://assets/powerups/pu_"
	var texture_name = ""
	
	match type:
		PowerType.DASH: texture_name = "dash"
		PowerType.SHIELD: texture_name = "shield"
		PowerType.ENEMY_MORE: texture_name = "enemy_more"
		PowerType.ENEMY_FAST: texture_name = "enemy_fast"
		PowerType.PLAYER_BIG: texture_name = "player_big"
		PowerType.PLAYER_SLOW: texture_name = "player_slow"
		PowerType.SCORE_PLUS_5: texture_name = "score_plus_5"
		PowerType.SCORE_PLUS_10: texture_name = "score_plus_10"
		PowerType.SCORE_PLUS_50: texture_name = "score_plus_50"
		PowerType.SCORE_MINUS_5: texture_name = "score_minus_5"
		PowerType.SCORE_MINUS_10: texture_name = "score_minus_10"
		PowerType.SCORE_MINUS_50: texture_name = "score_minus_50"
		PowerType.KILL_ALL: texture_name = "kill_all"
	
	if texture_name != "":
		icon.texture = load(path + texture_name + ".png")

func _on_area_entered(area):
	print("COLISIÓN DETECTADA CON: ", area.name) # <-- ESTO ES VITAL
	
	# Intentamos detectar al jugador de tres formas distintas para estar seguros
	if area.is_in_group("player") or area.name == "Player" or area.has_method("start"):
		print("¡POWERUP RECOGIDO!")
		collected.emit(type)
		queue_free()
