extends Node3D

# Настраиваемые параметры
@export var min_radius: float = 5.0                # минимальное расстояние от объекта для выбора правильной точки
@export var max_radius: float = 10.0               # максимальное расстояние
@export var disassemble_offset: float = 1.0        # смещение половинок в разобранном состоянии (в локальных координатах объекта)
@export var near_scale_factor: float = 0.8         # коэффициент масштабирования для половинки, приближающейся к камере (<1 – уменьшается)
@export var far_scale_factor: float = 1.2          # коэффициент масштабирования для половинки, отдаляющейся от камеры (>1 – увеличивается)
@export var alignment_threshold: float = 5.0       # порог угла (в градусах), при котором объект считается собранным
@export var disassemble_animation_time: float = 1.0  # время анимации сборки

var target_view_offset: Vector3                   # выбранная случайная точка (смещение от центра объекта)
var target_view_direction: Vector3                # нормализованный вектор от объекта к выбранной точке

# Сохраним исходные (собранные) трансформации половинок (локальные)
var assembled_transform_half_a: Transform3D
var assembled_transform_half_b: Transform3D

var solved: bool = false

@onready var half_a = $NodeA
@onready var half_b = $NodeB

func _ready() -> void:
	randomize()
	# Сохраняем собранное положение половинок
	assembled_transform_half_a = half_a.transform
	assembled_transform_half_b = half_b.transform

	# Выбираем случайную точку на сфере вокруг объекта:
	var random_dir: Vector3 = Vector3(randf() * 2 - 1, randf() * 2 - 1, randf() * 2 - 1).normalized()
	var random_radius: float = lerp(min_radius, max_radius, randf())
	target_view_offset = random_dir * random_radius
	target_view_direction = target_view_offset.normalized()
	
	# Поворачиваем объект, чтобы его «лицевая сторона» была направлена к выбранной точке.
	# (Вызов look_at использует глобальные координаты)
	look_at(global_transform.origin + target_view_offset, Vector3.UP)
	
	# Определяем, какая из половинок находится ближе к выбранной точке.
	# Вычисляем вектор от центра объекта до центра каждой половинки (в глобальных координатах)
	var dot_a: float = (half_a.global_transform.origin - global_transform.origin).dot(target_view_direction)
	var dot_b: float = (half_b.global_transform.origin - global_transform.origin).dot(target_view_direction)
	
	# Для вычислений смещения удобно перевести target_view_direction в локальное пространство объекта:
	var local_target_dir: Vector3 = global_transform.basis.inverse() * target_view_direction
	var a_transform
	var b_transform
	# На основании сравнения dot-произведений назначаем половинкам «ближайшую» (near) и «удалённую» (far)
	if dot_a > dot_b:
		# half_a – ближе, half_b – дальше
		a_transform = compute_disassembled_transform(assembled_transform_half_a, local_target_dir, true)
		b_transform = compute_disassembled_transform(assembled_transform_half_b, local_target_dir, false)
	else:
		# half_b – ближе, half_a – дальше
		b_transform = compute_disassembled_transform(assembled_transform_half_b, local_target_dir, true)
		a_transform = compute_disassembled_transform(assembled_transform_half_a, local_target_dir, false)
	
	var tween = get_tree().create_tween().set_parallel(true)
	tween.tween_property(half_a, "transform", a_transform, disassemble_animation_time)
	tween.tween_property(half_b, "transform", b_transform, disassemble_animation_time)

	# Добавляем объект в группу для GameManager, если требуется
	add_to_group("puzzle_objects")

# Функция для вычисления разобранной трансформации
# original – исходная (собранная) локальная трансформация половинки
# local_dir – направление (в локальных координатах объекта) к выбранной точке (куда направлена камера)
# is_near – true для половинки, которая должна «приближаться» к камере (и уменьшаться), false – для другой
func compute_disassembled_transform(original: Transform3D, local_dir: Vector3, is_near: bool) -> Transform3D:
	var new_transform: Transform3D = original
	if is_near:
		# Для ближней половинки: смещаем её вдоль local_dir (то есть в сторону камеры) и уменьшаем масштаб
		new_transform.origin += local_dir * disassemble_offset
		new_transform.basis = new_transform.basis.scaled(Vector3(near_scale_factor, near_scale_factor, near_scale_factor))
	else:
		# Для дальней половинки: смещаем её в противоположном направлении и увеличиваем масштаб
		new_transform.origin += -local_dir * disassemble_offset
		new_transform.basis = new_transform.basis.scaled(Vector3(far_scale_factor, far_scale_factor, far_scale_factor))
	return new_transform

func _process(delta: float) -> void:
	if solved:
		return
	var camera = get_viewport().get_camera_3d()
	if camera:
		# Определяем вектор взгляда камеры (в Godot направление взгляда – вдоль -Z)
		var cam_forward: Vector3 = -camera.global_transform.basis.z.normalized()
		# Вычисляем угол между направлением, выбранным для камеры, и направлением взгляда камеры
		var dot_val = clamp(target_view_direction.dot(cam_forward), -1.0, 1.0)
		var angle = rad_to_deg(acos(dot_val))
		if angle < alignment_threshold:
			solve()

func solve() -> void:
	solved = true
	# Анимируем возвращение половинок в исходное (собранное) состояние
	var tween = get_tree().create_tween().set_parallel(true)
	tween.tween_property(half_a, "transform", assembled_transform_half_a, disassemble_animation_time)
	tween.tween_property(half_b, "transform", assembled_transform_half_b, disassemble_animation_time)
