@tool
extends EditorNode3DGizmoPlugin

const Stairs := preload("res://addons/stairs_generator/stairs.gd")

func _init():
	create_material("main", Color(1,0,0))
	create_handle_material("handles")

func _redraw(gizmo: EditorNode3DGizmo) -> void:
	gizmo.clear()
	
	var node: Stairs = gizmo.get_node_3d()
	
	var lines: PackedVector3Array = box_get_lines(node.size)
	var handles: PackedVector3Array = box_get_handles(node.size)
	
	gizmo.add_lines(lines, get_material("main", gizmo))
	gizmo.add_handles(handles, get_material("handles", gizmo), [0,1,2,3,4,5],)

func _get_handle_value(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool) -> Variant:
	var node: Stairs = gizmo.get_node_3d()
	return {position = node.position, size = node.size}

func _begin_handle_action(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool) -> void:
	var node: Stairs = gizmo.get_node_3d()
	gizmo.set_meta(&"initial_transform", Transform3D(node.global_transform))
	gizmo.set_meta(&"initial_size", node.size)

func box_get_points(size: Vector3) -> PackedVector3Array:
	var half_size: Vector3 = size/2.0
	var points: PackedVector3Array
	for x: float in [half_size.x, -half_size.x]:
		for y: float in [half_size.y, -half_size.y]:
			for z: float in [half_size.z, -half_size.z]:
				points.push_back(Vector3(x, y, z))
	return points

func box_get_lines(size: Vector3) -> PackedVector3Array:
	var half_size: Vector3 = size/2.0
	var points: PackedVector3Array = box_get_points(size)
	
	var lines: PackedVector3Array
	for a : Vector3 in points:
		for b: Vector3 in points:
			if int(a[0] == b[0]) + int(a[1] == b[1]) + int(a[2] == b[2]) == 2: 
				lines.push_back(a)
				lines.push_back(b)
		#points.remove_at(points.find(a))
	
	return lines 

func get_segment(camera: Camera3D, screen_pos: Vector2, initial_transform: Transform3D) -> PackedVector3Array:
	var segment: PackedVector3Array
	var global_inverse: Transform3D = initial_transform.affine_inverse()
	
	var ray_from: Vector3 = camera.project_ray_origin(screen_pos)
	var ray_dir: Vector3 = camera.project_ray_normal(screen_pos)
	
	segment.push_back(global_inverse * ray_from)
	segment.push_back(global_inverse * (ray_from + ray_dir * 4096))
	
	return segment

func box_get_handles(size: Vector3) -> PackedVector3Array:
	var handles: PackedVector3Array
	for i: int in 3:
		var ax: Vector3 = Vector3()
		ax[i] = size[i] / 2.0
		handles.push_back(ax)
		handles.push_back(-ax)
	
	return handles

func box_get_handle_name(handle_id: int) -> String:
	match handle_id:
		0,1: return "Size X"
		2,3: return "Size Y"
		4,5: return "Size Z"
	return ""

#func _get_handle_value(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool) -> Variant:
	#return


func _set_handle(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool, camera: Camera3D, screen_pos: Vector2) -> void:
	var node: Stairs = gizmo.get_node_3d()
	var initial_transform: Transform3D = gizmo.get_meta(&"initial_transform")
	
	var axis: int = handle_id/2
	var sign: int = handle_id % 2 * -2 + 1
	
	var initial_size: Vector3 = gizmo.get_meta(&"initial_size")
	var pos_end: float = initial_size[axis] * 0.5
	var neg_end: float = initial_size[axis] * -0.5
	
	var axis_segments: PackedVector3Array = [Vector3(), Vector3()]
	axis_segments[0][axis] = 4096.0
	axis_segments[1][axis] = -4096.0
	
	var p_segments:= get_segment(camera, screen_pos, initial_transform)
	
	var r_segments:= Geometry3D.get_closest_points_between_segments(axis_segments[0], axis_segments[1], p_segments[0], p_segments[1] )
	var ra: Vector3 = r_segments[0]
	
	var r_box_size: Vector3 = initial_size
	if Input.is_key_pressed(KEY_ALT):
		r_box_size[axis] = ra[axis] * sign * 2
	else:
		r_box_size[axis] = ra[axis] - neg_end if sign > 0 else pos_end - ra[axis]
	
	#TODO Snapping
	
	r_box_size[axis] = max(r_box_size[axis], 0.001)
	
	if Input.is_physical_key_pressed(KEY_ALT):
		node.position = initial_transform.origin
	else:
		if sign > 0:
			pos_end = neg_end + r_box_size[axis]
		else:
			pos_end = neg_end - r_box_size[axis]
		
		var offset: Vector3 = Vector3()
		offset[axis] = (pos_end + neg_end) * 0.5
		node.position = initial_transform * offset
	
	node.size = r_box_size
	_redraw(gizmo)

func _commit_handle(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool, restore: Variant, cancel: bool) -> void:
	var node: Stairs = gizmo.get_node_3d()
	if cancel:
		node.size = restore.size
		node.position = restore.position
		return
	
	var ur : EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	ur.create_action("Change Stairs Size")
	ur.add_do_property(node, &"size", node.size) 
	ur.add_do_property(node, &"position", node.position) 
	ur.add_undo_property(node, &"size", restore.size)
	ur.add_undo_property(node, &"position", restore.position)
	ur.commit_action(false)

func _has_gizmo(for_node_3d: Node3D) -> bool:
	return is_instance_of(for_node_3d, Stairs)

func _get_gizmo_name() -> String:
	return "Stairs"
