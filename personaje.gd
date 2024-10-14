extends CharacterBody2D

const SPEED = 300.0  # Velocidad horizontal del personaje
const JUMP_VELOCITY = -550.0  # Velocidad del salto (negativa porque va hacia arriba)
const STAND_TO_IDLE_DELAY = 0.5  # Tiempo antes de pasar de "stand" a "idle"
const DUCK_DURATION = 0.2  # Duración de la animación "duck" al aterrizar después de un salto o caída

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D  # Referencia al sprite animado del personaje

# Variables de estado
var stand_timer = 0.0  # Temporizador para cambiar de "stand" a "idle"
var duck_timer = 0.0  # Temporizador para controlar la duración de la animación "duck"
var was_in_air = false  # Indica si el personaje estaba en el aire (por salto o caída)
var is_ducking = false  # Indica si el personaje está actualmente agachado
var landed_from_jump = false  # Indica si el personaje acaba de aterrizar de un salto o caída

# Función principal del ciclo de físicas que se ejecuta cada frame
func _physics_process(delta):
	handle_gravity(delta)  # Aplicar la gravedad si no está en el suelo
	handle_movement(delta)  # Controlar el movimiento horizontal
	handle_jump()  # Verificar si el personaje salta
	handle_manual_duck()  # Manejar el agachado manual con la tecla abajo
	handle_landing(delta)  # Verificar y manejar el aterrizaje después de un salto o caída
	move_and_slide()  # Mover el personaje y aplicar la física de colisiones

# Aplica la gravedad cuando el personaje está en el aire
func handle_gravity(delta):
	if not is_on_floor():
		velocity.y += ProjectSettings.get_setting("physics/2d/default_gravity") * delta

# Controla el movimiento horizontal del personaje, según la dirección y si está agachado o acaba de aterrizar
func handle_movement(delta):
	var direction = Input.get_axis("ui_left", "ui_right")  # Obtener la dirección de entrada (izquierda/derecha)
	
	if direction != 0 and not is_ducking and not landed_from_jump:
		# Mover el personaje en la dirección ingresada si no está agachado o aterrizando
		velocity.x = direction * SPEED
		sprite.flip_h = direction < 0  # Voltear el sprite si se mueve a la izquierda
		if is_on_floor() and not is_ducking:
			sprite.play("walk")  # Reproducir la animación de caminar
		reset_timers()  # Reiniciar los temporizadores cuando se mueve
	else:
		# Detener el movimiento horizontal gradualmente
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if is_on_floor() and not is_ducking and not landed_from_jump:
			handle_idle_transition(delta)  # Controlar la transición a "idle" si no se mueve

# Verifica si el personaje debe saltar
func handle_jump():
	if Input.is_action_just_pressed("ui_up") and is_on_floor() and not is_ducking:
		velocity.y = JUMP_VELOCITY  # Aplicar la velocidad de salto
		sprite.play("jump")  # Reproducir la animación de salto
		was_in_air = true  # Marcar que el personaje está en el aire

# Maneja el agachado manual con la tecla hacia abajo
func handle_manual_duck():
	if Input.is_action_pressed("ui_down") and is_on_floor():
		sprite.play("duck")  # Reproducir la animación de agachado
		is_ducking = true
	elif Input.is_action_just_released("ui_down") and is_ducking:
		is_ducking = false
		sprite.play("stand")  # Volver a la animación de estar de pie cuando se suelta la tecla
		stand_timer = 0.0  # Reiniciar el temporizador de "stand" a "idle"

# Controla el aterrizaje después de un salto o caída
func handle_landing(delta):
	if not is_on_floor():
		if velocity.y > 0:
			sprite.play("fall")  # Reproducir la animación de caída si está descendiendo
		was_in_air = true
	elif was_in_air and not is_ducking:
		# Si el personaje aterriza después de estar en el aire y no está agachado manualmente
		sprite.play("duck")  # Reproducir la animación de "duck" al aterrizar
		landed_from_jump = true  # Marcar que acaba de aterrizar
		was_in_air = false  # Restablecer el estado de estar en el aire
		duck_timer = DUCK_DURATION  # Iniciar el temporizador de "duck"

	# Transición automática de "duck" a "stand" y luego "idle" tras aterrizar
	if landed_from_jump:
		duck_timer -= delta
		if duck_timer <= 0:
			landed_from_jump = false  # Terminar la transición de aterrizaje
			sprite.play("stand")  # Pasar a la animación de estar de pie
			stand_timer = 0.0  # Reiniciar el temporizador de "stand" a "idle"

# Controla la transición de "stand" a "idle" si el personaje está quieto
func handle_idle_transition(delta):
	stand_timer += delta
	if stand_timer >= STAND_TO_IDLE_DELAY:
		sprite.play("idle")  # Reproducir la animación de "idle" si el personaje está quieto

# Reinicia todos los temporizadores y estados
func reset_timers():
	stand_timer = 0.0
	duck_timer = 0.0
	landed_from_jump = false
	is_ducking = false
