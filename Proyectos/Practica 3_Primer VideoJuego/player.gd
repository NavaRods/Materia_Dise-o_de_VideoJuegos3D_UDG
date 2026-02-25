extends Area2D

@export var speed = 400
var screen_size
signal hit

var shield_active = false
var dash_enabled = false
var dash_cooldown = 0.0
var dash_multiplier = 1.0 # Para controlar la duración del impulso

func _ready() -> void:
	screen_size = get_viewport_rect().size
	hide()

func _process(delta):
	# Manejo de Cooldown y duración del Dash
	if dash_cooldown > 0:
		dash_cooldown -= delta
	
	# 2. El lerp debe ser constante. Si está muy cerca de 1.0, lo forzamos a 1.0
	if dash_multiplier > 1.0:
		dash_multiplier = lerp(dash_multiplier, 1.0, 0.1)
	else:
		dash_multiplier = 1.0
	
	$AnimatedSprite2D.modulate = lerp($AnimatedSprite2D.modulate, Color(1, 1, 1), 0.1)
	
	var velocity = Vector2.ZERO

	if Input.is_action_pressed("move_right"): velocity.x += 1
	if Input.is_action_pressed("move_left"): velocity.x -= 1
	if Input.is_action_pressed("move_down"): velocity.y += 1
	if Input.is_action_pressed("move_up"): velocity.y -= 1

	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		# --- TEST DE DIAGNÓSTICO ---
		if Input.is_action_just_pressed("Dash"): # <------- No entra
			print("TECLA M DETECTADA") # Si esto no sale, es el Input Map
			if not dash_enabled:
				print("DASH FALLÓ: dash_enabled es FALSE (Main.gd no lo activó)")
			if dash_cooldown > 0:
				print("DASH FALLÓ: Esperando cooldown: ", dash_cooldown)
				
			if dash_enabled and dash_cooldown <= 0:
				dash_multiplier = 4.0
				dash_cooldown = 0.8
				$AnimatedSprite2D.modulate = Color(5, 5, 5)
				print("--- ¡DASH EXITOSO! ---")
			
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()

	# Aplicamos el movimiento final
	position += velocity * dash_multiplier * delta
	position = position.clamp(Vector2.ZERO, screen_size)
	# Efecto visual de Escudo: Si está activo, lo hacemos brillar en azul/cian
	$ShieldVisual.visible = shield_active
	if shield_active:
	# Hace que la burbuja rote o pulse un poco
		$ShieldVisual.rotation += delta * 5
		var pulse = (sin(Time.get_ticks_msec() * 0.01) * 0.1) + 1.0
		$ShieldVisual.scale = Vector2(pulse, pulse)
	else:
		# Si no hay escudo, vuelve al color normal (solo si no está en medio de un Dash)
		if dash_multiplier <= 1.1:
			$AnimatedSprite2D.modulate = lerp($AnimatedSprite2D.modulate, Color(1, 1, 1, 1), 0.1)
			
	# Animaciones
	if velocity.x != 0:
		$AnimatedSprite2D.animation = "walk"
		$AnimatedSprite2D.flip_v = false
		$AnimatedSprite2D.flip_h = velocity.x < 0
	elif velocity.y != 0:
		$AnimatedSprite2D.animation = "up"
		$AnimatedSprite2D.flip_v = velocity.y > 0
		
		
func _on_body_entered(body: Node2D) -> void:
	# Si el escudo está activo, destruimos al enemigo pero no morimos
	if shield_active:
		# OPCIÓN A: El enemigo rebota (si es RigidBody2D)
		if body is RigidBody2D:
			var push_direction = (body.global_position - global_position).normalized()
			body.apply_central_impulse(push_direction * 500)
		
		# Eliminamos el "body.queue_free()" para que NO mueran
		print("Escudo bloqueó el impacto")
		
		return
		

	# Si no hay escudo, morimos
	hide()
	hit.emit()
	$CollisionShape2D.set_deferred("disabled", true)

func start(pos):
	position = pos
	scale = Vector2(0.5, 0.5)
	show()
	# speed = 400
	dash_multiplier = 1.0
	dash_cooldown = 0.0
	$CollisionShape2D.disabled = false
