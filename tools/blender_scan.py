"""
Blender background script: scans Z-Anatomy.blend and writes
all collections + mesh object names to blender_scan.json.
Run with:
  blender -b Z-Anatomy.blend --python blender_scan.py
"""
import bpy
import json
import os

out_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "blender_scan.json")

def walk_collections(collection, depth=0):
    result = {
        "name": collection.name,
        "depth": depth,
        "meshes": [obj.name for obj in collection.objects if obj.type == 'MESH'],
        "children": [walk_collections(c, depth + 1) for c in collection.children],
    }
    return result

data = {
    "scene": bpy.context.scene.name,
    "total_objects": len(bpy.data.objects),
    "total_meshes": len([o for o in bpy.data.objects if o.type == 'MESH']),
    "collections": [walk_collections(c) for c in bpy.context.scene.collection.children],
    "all_mesh_names": sorted([obj.name for obj in bpy.data.objects if obj.type == 'MESH']),
}

with open(out_path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print(f"[scan] Written {out_path}")
print(f"[scan] Total meshes: {data['total_meshes']}")
