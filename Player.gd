extends KinematicBody2D

const PlayerHurtSound = preload("res://Player/PlayerHurtSound.tscn")

var state = MOVE
var velocity = Vector2.ZERO
var roll_vector = Vector2.DOWN
var stats = PlayerStats

export var ACCELERATION = 500
export var MAX_SPEED = 80 
export var  ROLL_SPEED = 120
export var FRICTION = 500

onready var AnimationPlayer = $AnimationPlayer
onready var AnimationTree = $AnimationTree
onready var AnimationState = AnimationTree.get("parameters/playback")
onready var SwordHitbox = $HitboxPivot/SwordHitbox
onready var hurtbox = $Hurtbox
onready var blinkAnimationPlayer = $BlinkAnimationPlayer

enum {
	MOVE,
	ROLL,
	ATTACK
}

func _ready():
	randomize()
	stats.connect("no_health", self, "queue_free")
	SwordHitbox.knockback_vector = roll_vector
	AnimationTree.active = true

func move_state(delta):

	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()

	if input_vector != Vector2.ZERO:
		roll_vector = input_vector
		SwordHitbox.knockback_vector = input_vector
		AnimationTree.set("parameters/Idle/blend_position",input_vector)
		AnimationTree.set("parameters/Run/blend_position",input_vector)
		AnimationTree.set("parameters/Attack/blend_position",input_vector)
		AnimationTree.set("parameters/Roll/blend_position",input_vector)
		AnimationState.travel("Run")
		velocity = velocity.move_toward(input_vector*MAX_SPEED, ACCELERATION*delta)
	else:
		AnimationState.travel("Idle")
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

	move()

	if Input.is_action_just_pressed("roll"):
		state = ROLL

	if Input.is_action_just_pressed("attack"):
		state = ATTACK

func roll_state(_delta):
	velocity = roll_vector * ROLL_SPEED
	AnimationState.travel("Roll")
	move()

func attack_state(_delta):
	velocity = Vector2.ZERO
	AnimationState.travel("Attack")

func move():
	velocity = move_and_slide(velocity)

func roll_animation_finished():
	velocity *= 0.8
	state = MOVE

func attack_animation_finished():
	state = MOVE

func _physics_process(delta):
	match state:
		MOVE:
			move_state(delta)
		ROLL:
			roll_state(delta)
		ATTACK:
			attack_state(delta)

func _on_Hurtbox_area_entered(area):
		stats.health -= area.damage	
		hurtbox.start_invincibility(0.6)
		hurtbox.create_hit_effect()
		var playerHurtSound = PlayerHurtSound.instance()
		get_tree().current_scene.add_child((playerHurtSound))

func _on_Hurtbox_invincibility_started():
	blinkAnimationPlayer.play("Start")

func _on_Hurtbox_invincibility_ended():
	blinkAnimationPlayer.play("Stop")
