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
	foo()


func foo() -> void:
	var verts:= box_get_points(size) * global_transform.affine_inverse()
	
	var indexes: PackedInt32Array =  [
		2,0,1,1,3,2, # Front
		4,0,2,2,6,4, # Left
		4,6,7,7,5,4, # Back
		6,2,3,3,7,6, # Bottom
		1,5,7,7,3,1,# Right
		5,1,0,0,4,5, # Top
		]
	
	const UVS: PackedVector2Array = \
	[
		Vector2(0, 0),
		Vector2(1, 0),
		Vector2(0, 1),
		Vector2(1, 1),
		Vector2(1, 1),
		Vector2(0, 1),
		Vector2(1, 0),
		Vector2(0, 0),
	]
	
	#indexes = Geometry3D.tetrahedralize_delaunay(verts)
	draw_mesh(verts, indexes, UVS)


func draw_stair(size: Vector3, trans: Transform3D = Transform3D()) -> void:
	size /= 2.0
	var step_size:= get_step_size()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var offset: Vector3 = size * Vector3(0.0, -0.5, 0.5)
	var set_offset: Vector3 = Vector3(0.0, step_size.y, -step_size.z)
	
	for i: int in step_count:
		
		offset += set_offset


func draw_mesh( verts: PackedVector3Array, indexes: PackedInt32Array, uvs: PackedVector2Array) -> void:
	RenderingServer.mesh_clear(mesh)
	var arr: Array
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_INDEX] = indexes
	arr[Mesh.ARRAY_TEX_UV] = uvs
	RenderingServer.mesh_add_surface_from_arrays(mesh, RenderingServer.PRIMITIVE_TRIANGLES, arr )
	apply_material()


func get_array() -> Array:
	var arr: Array
	return arr

func apply_material() -> void:
	for i: int in RenderingServer.mesh_get_surface_count(mesh):
		RenderingServer.mesh_surface_set_material(mesh, i, material)

func box_get_points(size: Vector3) -> PackedVector3Array:
	size /= 2.0
	return [
		Vector3(-size.x, size.y, size.z), 
		Vector3(size.x, size.y, size.z), 
		Vector3(-size.x, -size.y, size.z), 
		Vector3(size.x, -size.y, size.z), 
		Vector3(-size.x, size.y, -size.z), 
		Vector3(size.x, size.y, -size.z), 
		Vector3(-size.x, -size.y, -size.z), 
		Vector3(size.x, -size.y, -size.z), 
	]


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
		NOTIFICATION_VISIBILITY_CHANGED:
			RenderingServer.instance_set_visible(instance, visible)
		NOTIFICATION_PREDELETE:
			RenderingServer.free_rid(mesh)
			RenderingServer.free_rid(instance)
			PhysicsServer3D.free_rid(body)
		NOTIFICATION_TRANSFORM_CHANGED:
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
	
#endregion
