"""Finds a street address of Madridejos in the game's own metres, through the public Catastro services.

    python tools/locate.py CL "REYES CATOLICOS" 21        (CL calle, AV avenida, PS paseo, CR carretera, PZ plaza...)
    python tools/locate.py ? CATOLICOS                    lists how Catastro spells the streets that contain a word

Prints the cadastral reference, longitude/latitude and x (east) / z (south) as used by bake_godot.py.
"""
import math, re, sys, urllib.parse, urllib.request

LAT0, LON0 = 39.4690, -3.5335
KX = math.cos(math.radians(LAT0)) * 111320.0
KZ = 110574.0
BASE = 'https://ovc.catastro.meh.es/ovcservweb/OVCSWLocalizacionRC/'

def get(service, **q):
    url = BASE + service + '?' + urllib.parse.urlencode(q)
    req = urllib.request.Request(url, headers={'User-Agent': 'map-tool/1.0'})
    return urllib.request.urlopen(req, timeout=60).read().decode('utf8', 'replace')

def streets(word):
    xml = get('OVCCallejero.asmx/ConsultaVia', Provincia='TOLEDO', Municipio='MADRIDEJOS', TipoVia='', NombreVia=word)
    for tv, nv in re.findall(r'<tv>([^<]*)</tv>\s*<nv>([^<]*)</nv>', xml):
        print(tv, nv)

def locate(sigla, street, number):
    xml = get('OVCCallejero.asmx/Consulta_DNPLOC', Provincia='TOLEDO', Municipio='MADRIDEJOS', Sigla=sigla, Calle=street,
              Numero=number, Bloque='', Escalera='', Planta='', Puerta='')
    refs = []
    for pc1, pc2 in re.findall(r'<pc1>([^<]*)</pc1>\s*<pc2>([^<]*)</pc2>', xml):
        if pc1 + pc2 not in refs: refs.append(pc1 + pc2)
    if not refs:
        print(re.sub(r'\s+', ' ', xml)[:600]); return
    for rc in refs:
        cx = get('OVCCoordenadas.asmx/Consulta_CPMRC', Provincia='', Municipio='', SRS='EPSG:4326', RC=rc)
        m = re.search(r'<xcen>([^<]*)</xcen>\s*<ycen>([^<]*)</ycen>', cx)
        addr = re.search(r'<ldt>([^<]*)</ldt>', cx)
        if not m:
            print(rc, 'no coordinates'); continue
        lon, lat = float(m.group(1)), float(m.group(2))
        print('%s  lon %.6f lat %.6f  ->  x %.1f  z %.1f   %s' % (rc, lon, lat, (lon - LON0) * KX, -(lat - LAT0) * KZ, addr.group(1) if addr else ''))

if __name__ == '__main__':
    if sys.argv[1] == '?': streets(sys.argv[2])
    else: locate(sys.argv[1], sys.argv[2], sys.argv[3])
