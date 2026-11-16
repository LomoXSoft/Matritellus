"""Readies the furniture of the inside of the Papelería Rocas (godot/scripts/rocas.gd).

Takes the chosen models of Kenney's "Furniture Kit" (CC0; the download is in tools/descargas/kenney_furniture_kit/, its
OBJ files taken out of the zip into obj/) and writes each as godot/assets/rocas/mueble_<name>.glb, as it is: rocas.gd
sizes and places them (and makes their materials matt).

    blender.exe -b --python tools/rocas/muebles.py -- SRC_FOLDER OUT_FOLDER
"""
import bpy, sys, os

args = sys.argv[sys.argv.index('--') + 1:]
SRC, DST = args[0], args[1]
NAMES = ['bookcaseOpen', 'books', 'chairDesk', 'computerScreen', 'computerKeyboard', 'cardboardBoxClosed', 'cardboardBoxOpen',
         'rugRectangle', 'table']

os.makedirs(DST, exist_ok=True)
for name in NAMES:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.wm.obj_import(filepath=os.path.join(SRC, name + '.obj'))
    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bpy.context.view_layer.objects.active.name = name
    bpy.ops.export_scene.gltf(filepath=os.path.join(DST, 'mueble_%s.glb' % name), export_format='GLB', export_apply=True)
    print('written', name, [round(v, 3) for v in bpy.context.view_layer.objects.active.dimensions])
