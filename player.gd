extends CharacterBody2D

const SPEED := 800.0
const JUMP_VELOCITY := -900.0

# Gravity tuning
const GRAVITY := 1600.0
const FALL_MULT := 1.6          # extra gravity when falling
const JUMP_CUTOFF_MULT := 2.0   # extra gravity if jump released early

# Forgiveness
const COYOTE_TIME := 0.10       # time after leaving ground you can still jump
const JUMP_BUFFER := 0.10       # press jump slightly early and still jump

# Air-jumps
const MAX_AIR_JUMPS := 2

# Player values
var isBlind = true

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


@export var death_y: float = 1500.0
var death_count: int = 0
var _spawn_pos: Vector2


var _coyote := 0.0
var _jump_buffer := 0.0
var _air_jumps_left := MAX_AIR_JUMPS

func _physics_process(delta: float) -> void:
	# --- Floor state & timers ---
	if is_on_floor():
		_coyote = COYOTE_TIME
		_air_jumps_left = MAX_AIR_JUMPS
	else:
		_coyote = max(0.0, _coyote - delta)
	
	if isBlind:
		$VabBlind.show()
		$VabBlind.flip_h = $AnimatedSprite2D.flip_h
	else:
		$VabBlind.hide()


		
	# Buffer jump input
	if Input.is_action_just_pressed("jump"):
		_jump_buffer = JUMP_BUFFER
	else:
		_jump_buffer = max(0.0, _jump_buffer - delta)

	# --- Balanced gravity (vertical only) ---
	if not is_on_floor():
		var g := GRAVITY
		if velocity.y > 0.0:                # falling
			g *= FALL_MULT
		elif not Input.is_action_pressed("jump"):
			# rising but jump key released → lower apex
			g *= JUMP_CUTOFF_MULT
		velocity.y += g * delta
	else:
		# Kill tiny downward creep on slopes
		if velocity.y > 0.0:
			velocity.y = 0.0

	# --- Handle jump / double jump ---
	if _jump_buffer > 0.0:
		if _coyote > 0.0:
			_do_jump()
			_coyote = 0.0
			_jump_buffer = 0.0
		elif _air_jumps_left > 0:
			_do_jump()
			_air_jumps_left -= 1
			_jump_buffer = 0.0

	# --- Horizontal movement ---
	var direction := Input.get_axis("left", "right")
	if direction != 0.0:
		velocity.x = direction * SPEED
		animated_sprite.flip_h = direction < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

	move_and_slide()
	
	if global_position.y > death_y:
		_kill_and_respawn()


	# --- Animation state (safe fallbacks) ---
	if not is_on_floor():
		if velocity.y < 0.0:
			_safe_play("jump")   # rising
		else:
			_safe_play("fall")   # falling
	else:
		if abs(velocity.x) > 1.0:
			_safe_play("walk")
		else:
			_safe_play("idle")

func _do_jump() -> void:
	velocity.y = JUMP_VELOCITY

func _safe_play(anim: String) -> void:
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim):
		if animated_sprite.animation != anim or not animated_sprite.is_playing():
			animated_sprite.play(anim)
	else:
		# Fallback to existing ones you already have
		if anim in ["jump", "fall"]:
			# prefer walk while moving, else idle
			if abs(velocity.x) > 1.0:
				animated_sprite.play("walk")
			else:
				animated_sprite.play("idle")
				
func _ready() -> void:
	_spawn_pos = global_position
func _kill_and_respawn() -> void:
	death_count += 1
	global_position = _spawn_pos
	velocity = Vector2.ZERO
	print("Deaths:", death_count)

				
				
