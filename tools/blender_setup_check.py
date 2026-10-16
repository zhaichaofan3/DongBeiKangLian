"""Configure portable Blender and verify native save plus game-model export."""
import json
from pathlib import Path

import bpy

output = Path(__file__).resolve().parent / "blender-verification"
output.mkdir(exist_ok=True)
view = bpy.context.preferences.view
view.language = "zh_HANS"
view.use_translate_interface = True
view.use_translate_tooltips = True
view.use_translate_new_dataname = False
bpy.ops.wm.save_userpref()

# Use Blender's small factory scene; keep this check outside the game project.
bpy.ops.object.select_all(action="DESELECT")
cube = bpy.data.objects["Cube"]
cube.select_set(True)
bpy.context.view_layer.objects.active = cube
bpy.ops.wm.save_as_mainfile(filepath=str(output / "pipeline-check.blend"))
bpy.ops.export_scene.gltf(
    filepath=str(output / "pipeline-check.glb"),
    export_format="GLB",
    use_selection=True,
)
report = {
    "version": bpy.app.version_string,
    "background_python": True,
    "language": view.language,
    "preferences_directory": bpy.utils.user_resource("CONFIG"),
    "native_project": str(output / "pipeline-check.blend"),
    "game_export": str(output / "pipeline-check.glb"),
}
(output / "setup-check.json").write_text(
    json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
)
print("BLENDER_SETUP_OK " + json.dumps(report, ensure_ascii=False))
