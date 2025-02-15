extends Node3D

@export var rotation_speed : float = 0.3


var rotating = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			rotating = event.pressed
	elif event is InputEventMouseMotion and rotating:
		rotate_y(deg_to_rad(-event.relative.x * rotation_speed))
		rotate_x(deg_to_rad(-event.relative.y * rotation_speed))
