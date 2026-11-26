"""The Catastro parts of some parcels, in a house's frame.  python partes.py <house id> <rc> [<rc> ...]"""
import json, re, sys, zipfile, math, numpy as np
P='X:/MatritellusGPT/'
src=open(P+'tools/bake_godot.py',encoding='utf-8').read()
i=src.index('def utm30_to_local'); j=src.index('# ======', i+10)
ns={'np':np,'math':math,'LAT0':39.4690,'LON0':-3.5335,'KX':math.cos(math.radians(39.4690))*111320.0,'KZ':110574.0}
for mm in re.finditer(r'^([A-Z][A-Z_0-9]*(?:, [A-Z][A-Z_0-9]*)*) = ([-0-9., ()*/+a-z]+?)\s*(?:#.*)?$', src[:i], re.M):
    try: exec(mm.group(0), ns)
    except Exception: pass
exec(src[i:j], ns)
m=json.load(open(P+'godot/data/map.json',encoding='utf-8'))
h=[x for x in m['houses'] if x['id']==sys.argv[1]][0]; o=h['o'];u=h['u'];n=(-u[1],u[0])
zf=zipfile.ZipFile(P+'tools/catastro/A.ES.SDGC.BU.45088.zip')
t=zf.read([q for q in zf.namelist() if q.endswith('.buildingpart.gml')][0]).decode('utf-8')
for mm in re.finditer(r'<bu-ext2d:BuildingPart gml:id="ES\.SDGC\.BU\.([^"]+)">(.*?)</bu-ext2d:BuildingPart>', t, re.S):
    if mm.group(1).split('_')[0] not in sys.argv[2:]: continue
    fl=re.search(r'numberOfFloorsAboveGround>(\d+)<', mm.group(2)); bl=re.search(r'numberOfFloorsBelowGround>(\d+)<', mm.group(2))
    for ring in re.findall(r'<gml:exterior>.*?<gml:posList[^>]*>([^<]+)</gml:posList>', mm.group(2), re.S):
        v=np.array(ring.split(),dtype=float).reshape(-1,2)
        x,z=ns['utm30_to_local'](v[:,0],v[:,1])
        print(mm.group(1),'floors',fl.group(1) if fl else None,[(round(float((a-o[0])*u[0]+(b-o[1])*u[1]),1),round(float((a-o[0])*n[0]+(b-o[1])*n[1]),1)) for a,b in zip(x,z)][:-1])
