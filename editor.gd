@tool
extends EditorScript
#const BRICK_MATERIAL = preload("res://brick_material.tres")
#@export var physics_mode: PhysicsServer3D.BodyMode
#const Stairs = preload("res://addons/stairs_generator/stairs.gd")

func _run() -> void:
	print("Running...")
	var scene:= get_scene()
	#var stairs: Stairs = scene.get_node("Stairs")
	#var shape: Shape3D = Shape3D.new()
	#const NEW_CONVEX_POLYGON_SHAPE_3D = preload("res://new_convex_polygon_shape_3d.tres")
	const BUTTON_PATH:= [1, 0, 0, 0, 14]
	const TRANSLATE_SNAP_LINE_EDIT:= [1, 2, 0, 1, 0]
	const TRANSFORM_PATH:=[1, 0, 0, 0, 20, "get_popup"]
	var node: Node = EditorInterface.get_editor_main_screen()
	var child_index_path:=[
		1, 2, 0, 1, 0
	]
	for i in child_index_path:
		node = node.get_child(i) if i is int else node.call(i)
		
	print("\n",node)
	for i in node.get_child_count():
		var child = node.get_child(i) 
		printt("┖ %d (%d)" % [i, child.get_child_count()], child,
		child.text if "text" in child else "", 
		child.title if "title" in child else "",
		child.tooltip_text if "tooltip_text" in child else "",
		)
		if child.get(&"icon") is Texture:
			var img: Image = child.get(&"icon").get_image()
			if not img: continue
			var bit: BitMap = BitMap.new()
			bit.create_from_image_alpha(img, 0.2)
			var img_str: String = ""
			for y: int in bit.get_size().y:
				img_str += "\n\t" if img_str else "\t"
				for x: int in bit.get_size().x:
					img_str += "■ " if bit.get_bit(x, y) else "□ "
			print(img_str)

func print_flags(flag_value: int, _class: StringName, _enum: StringName, no_inheretance: bool = false) -> void:
	const MAX_ENUM_STRING_LENGTH: int = 25
	for name: String in ClassDB.class_get_enum_constants(_class, _enum, no_inheretance):
		print(name.rpad(MAX_ENUM_STRING_LENGTH) + " => ", ClassDB.class_get_integer_constant(_class, name) & flag_value)
