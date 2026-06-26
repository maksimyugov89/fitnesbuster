import bpy
op = bpy.ops.export_scene.gltf
rna = op.get_rna_type()
params = [p.identifier for p in rna.properties if p.identifier not in ('rna_type',)]
params.sort()
print("[params] gltf exporter properties:")
for p in params:
    print(f"  {p}")
