@tool
extends EditorPlugin

var gizmo_plugin: EditorNode3DGizmoPlugin

func _enter_tree() -> void:
	Engine.set_meta(_get_plugin_name(), self)
	gizmo_plugin = preload("gizmo_plugin.gd").new()
	add_node_3d_gizmo_plugin(gizmo_plugin)
	add_custom_type("Stairs", "Node3D", preload("stairs.gd"), preload("stairs.svg"))

func _exit_tree() -> void:
	remove_node_3d_gizmo_plugin(gizmo_plugin)
	Engine.set_meta(_get_plugin_name(), null)

func _get_plugin_name() -> String:
	return "Stairs"

func _get_plugin_icon() -> Texture2D:
	return preload("icon.svg")

## Temporary custom snap until 3D editor snap settings are [url=https://github.com/godotengine/godot/pull/96763/]exposed[/url]
func is_snap_enabled() -> bool:
	const BUTTON_PATH: PackedInt32Array = [1, 0, 0, 0, 14]
	return get_child_property(EditorInterface.get_editor_main_screen(), BUTTON_PATH, "button_pressed", false)

func get_snap_distance() -> float:
	const TRANSLATE_SNAP_LINE_EDIT: PackedInt32Array = [1, 2, 0, 1, 0]
	return float(get_child_property(EditorInterface.get_editor_main_screen(), TRANSLATE_SNAP_LINE_EDIT, "text", 0.00))
	
func get_child_property(node: Node, child_path: PackedInt32Array, property_path: String, default: Variant = null) -> Variant:
	for i : int in child_path:
		if node.get_child_count() <= i: 
			push_warning("Unable to find child property '%s'." % property_path)
			return default
		node = node.get_child(i)
		
	if not property_path in node:
		push_warning("Unable to find child property '%s'." % property_path)
		return default
		
	return node.get_indexed(property_path)
