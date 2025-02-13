@tool
extends Node3D

signal resized

@export_tool_button("Debug", "EditorPlugin")
var foo_callabled: Callable = foo

@export
var size: Vector3 = Vector3.ONE: set = set_size

@export_range(1, 32, 1, "or_greater") 
var step_count: int = 12: set = set_step_count

@export var material: Material = StandardMaterial3D.new(): set = set_material
@export var uv_scale: Vector2 = Vector2.ONE : set = set_uv_scale




@export_group("Physics")
@export_enum("Static", "Kinematic", "Rigid", "Rigid Linear")
var physics_mode: int = 0: set = set_physics_mode

@export_flags_3d_physics 
var collision_layers: int = 1: set = set_collision_layers

@export_flags_3d_physics 
var collision_mask: int = 1: set = set_collision_mask

@export_group("Rendering")
@export_flags_3d_render 
var render_layers: int = 0xFFFFFF: set = set_render_layers

var instance: RID
var mesh: RID
var body: RID

func foo() -> void:
	redraw()

func _init() -> void:
	instance = RenderingServer.instance_create()
	mesh = RenderingServer.mesh_create()
	RenderingServer.instance_set_base(instance, mesh)
	
	body = PhysicsServer3D.body_create()
	PhysicsServer3D.body_set_mode(body, PhysicsServer3D.BODY_MODE_STATIC)
	PhysicsServer3D.body_set_collision_layer(body, 1)
	PhysicsServer3D.body_set_collision_mask(body, 1)
	set_notify_transform(true)


func redraw() -> void:
	RenderingServer.mesh_clear(mesh)
	draw_stair(size, global_transform)
	apply_material()

func draw_stair(size: Vector3, trans: Transform3D = Transform3D()) -> void:
	if size.x == 0 or size.y == 0 or size.z == 0: return
	size /= 2.0
	var step_size:= get_step_size()
	var half_step:= step_size/2.0
	
	var offset: Vector3 = Vector3(0.0, -size.y, size.z) * float(step_count-1) / float(step_count)
	var step_offset: Vector3 = Vector3(0.0, step_size.y, -step_size.z)
	
	
	var arrays: Array
	var st := SurfaceTool.new()
	
	for i: int in step_count:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.set_tangent(Plane.PLANE_XY)
		st.set_uv(uv_scale * Vector2.DOWN)
		st.set_normal(Vector3.BACK)
		st.add_vertex(trans * (offset + Vector3(-half_step.x, -half_step.y, half_step.z)))
		
		st.set_uv(uv_scale * Vector2.ZERO)
		st.add_vertex(trans * (offset + Vector3(-half_step.x, half_step.y, half_step.z)))
		
		st.set_uv(uv_scale * Vector2.RIGHT)
		st.add_vertex(trans * (offset + Vector3(half_step.x, half_step.y, half_step.z)))
		
		st.set_uv(uv_scale * Vector2.ONE)
		st.add_vertex(trans * (offset + Vector3(half_step.x, -half_step.y, half_step.z)))
		st.add_index(0)
		st.add_index(1)
		st.add_index(2)
		st.add_index(2)
		st.add_index(3)
		st.add_index(0)
		
		st.set_tangent(-Plane.PLANE_XZ)
		st.set_normal(Vector3.UP)
		st.set_uv(uv_scale * Vector2.DOWN)
		st.add_vertex(trans * (offset + Vector3(-half_step.x, half_step.y, half_step.z))) 
		st.set_uv(uv_scale * Vector2.ZERO)
		st.add_vertex(trans * (offset + Vector3(-half_step.x, half_step.y, -half_step.z)))
		st.set_uv(uv_scale * Vector2.RIGHT)
		st.add_vertex(trans * (offset + Vector3(half_step.x, half_step.y, -half_step.z)))
		st.set_uv(uv_scale * Vector2.ONE)
		st.add_vertex(trans * (offset + Vector3(half_step.x, half_step.y, half_step.z)))
		st.add_index(4)
		st.add_index(5)
		st.add_index(6)
		st.add_index(6)
		st.add_index(7)
		st.add_index(4)
		
		var side_scale: float =  i * step_size.y
		var uv_scale:= Vector2(step_size.z/step_size.x  , 1 + i) * uv_scale
		# BUG Strange Shadow Banding issue on this side, other size is fine
		
		st.set_normal(Vector3.RIGHT)
		st.set_tangent(-Plane.PLANE_YZ)
		st.set_uv(uv_scale * Vector2.DOWN)
		st.add_vertex(trans * (offset + Vector3(-half_step.x, -half_step.y - side_scale, -half_step.z)))
		st.set_uv(uv_scale * Vector2.ZERO)
		st.add_vertex(trans * (offset + Vector3(-half_step.x, half_step.y, -half_step.z)))
		st.set_uv(uv_scale * Vector2.RIGHT)
		st.add_vertex(trans * (offset + Vector3(-half_step.x, half_step.y , half_step.z)))
		st.set_uv(uv_scale * Vector2.ONE)
		st.add_vertex(trans * (offset + Vector3(-half_step.x, -half_step.y - side_scale, half_step.z)))
		st.add_index(8)
		st.add_index(9)
		st.add_index(10)
		st.add_index(10)
		st.add_index(11)
		st.add_index(8)
		
		st.set_normal(Vector3.RIGHT)
		st.set_tangent(-Plane.PLANE_YZ)
		st.set_uv(uv_scale * Vector2.ONE)
		st.add_vertex(trans *  (offset +Vector3(half_step.x, -half_step.y - side_scale, half_step.z)))
		st.set_uv(uv_scale * Vector2.RIGHT)
		st.add_vertex(trans * (offset + Vector3(half_step.x, half_step.y , half_step.z)))
		st.set_uv(uv_scale * Vector2.ZERO)
		st.add_vertex(trans * (offset + Vector3(half_step.x, half_step.y, -half_step.z)))
		st.set_uv(uv_scale * Vector2.DOWN)
		st.add_vertex(trans *  (offset +Vector3(half_step.x, -half_step.y - side_scale, -half_step.z)))
		st.add_index(12)
		st.add_index(13)
		st.add_index(14)
		st.add_index(14)
		st.add_index(15)
		st.add_index(12)
		
		
		
		RenderingServer.mesh_add_surface_from_arrays(mesh, RenderingServer.PRIMITIVE_TRIANGLES, st.commit_to_arrays() )
		st.clear()
		#merge_arrays(arrays, st.commit_to_arrays())
		
		offset += step_offset
		
		if i != step_count - 1: continue
		
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.FORWARD)
	st.set_tangent(Plane.PLANE_XY)
	st.set_uv(uv_scale * Vector2(0, step_count))
	st.add_vertex(trans * (size * Vector3(1.0, -1.0, -1.0))) 
	st.set_uv(uv_scale * Vector2.ZERO)
	st.add_vertex(trans * (size * Vector3(1.0, 1.0, -1.0))) 
	st.set_uv(uv_scale * Vector2.RIGHT)
	st.add_vertex(trans * (size * Vector3(-1.0, 1.0, -1.0))) 
	st.set_uv(uv_scale * Vector2(1, step_count))
	st.add_vertex(trans * (size * Vector3(-1.0, -1.0, -1.0))) 
	
	st.add_index(0)
	st.add_index(1)
	st.add_index(2)
	st.add_index(2)
	st.add_index(3)
	st.add_index(0)
	
	st.set_normal(Vector3.UP)
	st.set_tangent(-Plane.PLANE_XZ)
	st.set_uv(uv_scale * Vector2(0, step_count))
	st.add_vertex(trans * (size * Vector3(-1.0, -1.0, -1.0))) 
	st.set_uv(uv_scale * Vector2.ZERO)
	st.add_vertex(trans * (size * Vector3(-1.0, -1.0, 1.0))) 
	st.set_uv(uv_scale * Vector2.RIGHT)
	st.add_vertex(trans * (size * Vector3(1.0, -1.0, 1.0))) 
	st.set_uv(uv_scale * Vector2(1, step_count))
	st.add_vertex(trans * (size * Vector3(1.0, -1.0, -1.0))) 
	
	st.add_index(4)
	st.add_index(5)
	st.add_index(6)
	st.add_index(6)
	st.add_index(7)
	st.add_index(4)
	
	
	RenderingServer.mesh_add_surface_from_arrays(mesh, RenderingServer.PRIMITIVE_TRIANGLES, st.commit_to_arrays())

func get_array() -> Array:
	var arr: Array
	return arr

func apply_material() -> void:
	var rid: RID = material.get_rid() if material else RID()
	for i: int in RenderingServer.mesh_get_surface_count(mesh):
		RenderingServer.mesh_surface_set_material(mesh, i, rid)


func get_step_height() -> float:
	return size.y / float(step_count)

func get_step_length() -> float:
	return size.z / float(step_count)

func get_step_size() -> Vector3:
	return size / Vector3(1.0, step_count, step_count)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_WORLD:
			RenderingServer.instance_set_scenario(instance, get_world_3d().scenario)
		NOTIFICATION_EXIT_WORLD:
			RenderingServer.instance_set_scenario(instance, RID())
		NOTIFICATION_VISIBILITY_CHANGED:
			RenderingServer.instance_set_visible(instance, visible)
		NOTIFICATION_PREDELETE:
			RenderingServer.mesh_clear(mesh)
			RenderingServer.free_rid(mesh)
			RenderingServer.free_rid(instance)
			PhysicsServer3D.free_rid(body)
		
		NOTIFICATION_TRANSFORM_CHANGED when is_inside_tree():
			redraw()



#region Setters

func set_physics_mode(val: int) -> void:
	physics_mode = val
	PhysicsServer3D.body_set_mode(body, physics_mode as PhysicsServer3D.BodyMode)

func set_collision_layers(val: int) -> void:
	collision_layers = val 
	PhysicsServer3D.body_set_collision_layer(body, collision_layers)

func set_collision_mask(val: int) -> void:
	collision_mask = val 
	PhysicsServer3D.body_set_collision_mask(body, collision_mask)

func set_render_layers(val: int) -> void:
	render_layers = val 
	RenderingServer.instance_set_layer_mask(instance, render_layers)

func set_step_count(val: int) -> void:
	step_count = maxi(1, val)
	redraw()

func set_size(val: Vector3) -> void:
	size = val.maxf(0.0)
	redraw()
	resized.emit()

func set_material(val: Material) -> void:
	material = val
	apply_material()

func set_uv_scale(val: Vector2) -> void:
	uv_scale = val
	redraw()

#endregion
