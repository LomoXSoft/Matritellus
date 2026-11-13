"""Downloads the elevation model the relief is baked from: MDT05 (5 m grid, ETRS89 / UTM 30N), © Instituto Geográfico
Nacional, CC BY 4.0, from the IDEE coverage service, for the square of country round Madridejos.

    python tools/fetch_mdt.py      ->  tools/ign/mdt05_utm.npz   (z: heights in metres, row 0 = north; x0, y0, cell)

Then python tools/bake_godot.py puts it in the map (see RELIEF there). The service's certificate chain is not in
Python's own store on this machine, so the download goes through curl, which uses the system's.
"""
import io, os, subprocess
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
X0, X1, Y0, Y1 = 451000, 458000, 4366000, 4373000          # UTM 30N metres: 7 km square, the town in the middle
URL = ('https://servicios.idee.es/wcs-inspire/mdt?SERVICE=WCS&VERSION=2.0.1&REQUEST=GetCoverage&COVERAGEID=Elevacion25830_5'
       '&SUBSET=x(%d,%d)&SUBSET=y(%d,%d)&FORMAT=application/asc' % (X0, X1, Y0, Y1))

def main():
    raw = subprocess.run(['curl', '-sS', '-A', 'map-tool/1.0', URL], check=True, capture_output=True).stdout
    text = raw[raw.index(b'ncols'):].decode('ascii', 'replace').split('\n')
    head = {}
    k = 0
    while text[k].split() and text[k].split()[0][0].isalpha():
        a, b = text[k].split(); head[a.lower()] = float(b); k += 1
    z = np.loadtxt(io.StringIO('\n'.join(text[k:k + int(head['nrows'])]))).astype('float32')
    out = os.path.join(HERE, 'ign', 'mdt05_utm.npz')
    os.makedirs(os.path.dirname(out), exist_ok=True)
    np.savez_compressed(out, z=z, x0=head['xllcorner'], y0=head['yllcorner'], cell=head['cellsize'])
    print('mdt05_utm.npz', z.shape, 'from %.0f to %.0f m' % (z.min(), z.max()))

if __name__ == '__main__':
    main()
