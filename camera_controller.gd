extends Node3D

# Настраиваемые параметры
@export var rotation_speed: float = 0.005       # скорость вращения (чем меньше — тем медленнее)
@export var min_pitch: float = deg_to_rad(-98)       # минимальный угол по вертикали (в радианах)
@export var max_pitch: float = deg_to_rad(98)        # максимальный угол по вертикали (в радианах)

var yaw: float = 0.0   # горизонтальный угол (в радианах)
var pitch: float = 0.0 # вертикальный угол (в радианах)
var rotating: bool = false

func _ready() -> void:
	# Инициализируем углы текущей ориентацией камеры
	yaw = rotation.y
	pitch = rotation.x

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			rotating = event.pressed
	elif event is InputEventMouseMotion and rotating:
		yaw -= event.relative.x * rotation_speed
		pitch -= event.relative.y * rotation_speed
		# Ограничиваем вертикальный угол, чтобы камера не переворачивалась
		pitch = clamp(pitch, min_pitch, max_pitch)
		# Устанавливаем новую ориентацию, сбрасывая roll (т.е. третий компонент равен 0)
		rotation = Vector3(pitch, yaw, 0)
