@tool
extends EditorPlugin
const SETTING_SNAP_ENABLED: StringName = &"plugin/stair_generator/snap_enabled"
const SETTING_SNAP_DISTANCE: StringName = &"plugin/stair_generator/snap_distance"

var gizmo_plugin: EditorNode3DGizmoPlugin

func _enable_plugin() -> void:
	ProjectSettings.set_setting(SETTING_SNAP_ENABLED, true)
	ProjectSettings.set_setting(SETTING_SNAP_DISTANCE, 0.25)
	ProjectSettings.add_property_info({"name": SETTING_SNAP_ENABLED, "type": TYPE_BOOL,})
	ProjectSettings.add_property_info({"name": SETTING_SNAP_DISTANCE,"type": TYPE_FLOAT,"hint": PROPERTY_HINT_RANGE,"hint_string": "0.001,5.0,0.05,or_greater,suffix:m"})
	
	ProjectSettings.set_initial_value(SETTING_SNAP_ENABLED, true)
	ProjectSettings.set_initial_value(SETTING_SNAP_DISTANCE, 0.25)
	ProjectSettings.save()

func _enter_tree() -> void:
	Engine.set_meta(_get_plugin_name(), self)
	gizmo_plugin = preload("gizmo_plugin.gd").new()
	add_node_3d_gizmo_plugin(gizmo_plugin)
	add_custom_type("Stairs", "Node3D", preload("stairs.gd"), preload("stairs.svg"))

func _exit_tree() -> void:
	remove_node_3d_gizmo_plugin(gizmo_plugin)
	Engine.set_meta(_get_plugin_name(), null)

func _disable_plugin() -> void:
	ProjectSettings.set_setting(SETTING_SNAP_ENABLED, null)
	ProjectSettings.set_setting(SETTING_SNAP_DISTANCE, null)
	ProjectSettings.save()


func _get_plugin_name() -> String:
	return "stairs_generator"

func _get_plugin_icon() -> Texture2D:
	return preload("icon.svg")

##Temporary custom snap until 3D editor snap settings are [url=https://github.com/godotengine/godot/pull/96763/]exposed[/url]
func is_snap_enabled() -> bool:
	return ProjectSettings.get_setting(SETTING_SNAP_ENABLED, false)

func get_snap_distance() -> float:
	return ProjectSettings.get_setting(SETTING_SNAP_DISTANCE, 0.25)
