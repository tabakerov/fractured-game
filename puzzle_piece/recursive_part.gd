extends Node3D

class_name RecursivePart

@export var isRoot = false

var children

func OhHello() -> void:
	print("oh hello!")
	
func split() -> void:
	print("%s splitting" % name)
	var guide
	for child in get_children():
		if child is RecursivePart:
			child.split()
			
		if child is SplitGuide:
			guide = child
			guide.A.translate(guide.transform.basis.x.normalized()*guide.Distance)
			guide.B.translate(-guide.transform.basis.x.normalized()*guide.Distance)

func _ready() -> void:
	print("starting...")
	if isRoot:
		split()
