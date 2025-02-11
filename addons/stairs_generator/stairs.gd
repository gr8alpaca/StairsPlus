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
	pass

func draw_box() -> void:
	var arr: Array
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = box_get_points(size)
	
	RenderingServer.mesh_add_surface_from_arrays(mesh, 
	RenderingServer.PRIMITIVE_TRIANGLES, 
	[]
	)

enum { FACE_FORWARD = 0, FACE_BACK= 1 }

func foo() -> void:
	const FACES:Array[PackedInt32Array] = [ 
		[1,5,7,7,3,1], # FORWARD
		[6,4,0,0,2,6], # BACK
		[2,0,1,1,3,2], # RIGHT
		[7,5,4,4,6,7], # LEFT
		[5,1,0,0,4,5 ], # UP
		[2,3,7,7,6,2], # DOWN
		]
	
	var verts:= box_get_points(size) * global_transform.affine_inverse()
	
	var indexes: PackedInt32Array =  FACES[0] + FACES[1] + FACES[2] + FACES[3] + FACES[4] + FACES[5]
	const UVS: PackedVector2Array = \
	#[
		#Vector2.ZERO, Vector2.RIGHT, 
		#
		#Vector2.DOWN, Vector2.RIGHT + Vector2.DOWN, 
		#
		#-Vector2.RIGHT, Vector2.ZERO, 
		#
		#-Vector2.RIGHT - Vector2.DOWN, -Vector2.DOWN, 
		#]
	
	[
		Vector2.RIGHT, 					# 0
		Vector2.UP,						# 1
		Vector2.DOWN + Vector2.RIGHT, 	# 2
		Vector2.LEFT + Vector2.UP,		# 3
		Vector2.DOWN,					# 4
		Vector2.DOWN,					# 5
		Vector2.DOWN,					# 6
		Vector2.DOWN,					# 7
		
		
		
	]
	
	
	RenderingServer.mesh_clear(mesh)
	var arr: Array
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_INDEX] = indexes
	arr[Mesh.ARRAY_TEX_UV] = UVS
	RenderingServer.mesh_add_surface_from_arrays(mesh, RenderingServer.PRIMITIVE_TRIANGLES, arr )
	apply_material()
	
	#draw_triangles(
		#PackedVector3Array([Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN]),
		#[Vector2.RIGHT, Vector2.DOWN,  Vector2.ZERO,  Vector2.RIGHT + Vector2.DOWN,],
		#[0,1,2,3,1,0], 
		#)

#func draw_quad()

func draw_triangles(verts: PackedVector3Array,  uv:= PackedVector2Array(), indexes: PackedInt32Array = [1,2,3], ) -> void:
	RenderingServer.mesh_clear(mesh)
	var arr: Array
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_INDEX] = indexes
	arr[Mesh.ARRAY_TEX_UV] = uv
	RenderingServer.mesh_add_surface_from_arrays(mesh, RenderingServer.PRIMITIVE_TRIANGLES, arr )
	apply_material()
	#print(box_get_points(size))

func get_array() -> Array:
	var arr: Array
	return arr

func apply_material() -> void:
	for i: int in RenderingServer.mesh_get_surface_count(mesh):
		RenderingServer.mesh_surface_set_material(mesh, i, material)

func get_step_height() -> float:
	return size.y / float(step_count)

func box_get_points(size: Vector3) -> PackedVector3Array:
	var half_size: Vector3 = size/2.0
	var points: PackedVector3Array
	for x: float in [half_size.x, -half_size.x]:
		for y: float in [half_size.y, -half_size.y]:
			for z: float in [half_size.z, -half_size.z]:
				points.push_back(Vector3(x, y, z))
	return points

func box_get_indexes() -> PackedInt32Array:
	var inds: PackedInt32Array
	return [
		
	]

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
