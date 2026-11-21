"""The panorama nearest a point, people's own 360 photos included (the blue circles of Google Maps' Street View layer):

    python tools/silo/cerca360.py LAT LON RADIUS        e.g. 39.46620 -3.52755 40  (the silo's yard)

Google Maps' `photometa/si/v1` (what took the place of GeoPhotoService.SingleImageSearch, turned off in 2026). The
coverage tiles (`photometa/ac/v1`) list only Google's own cars; a place's page lists only flat photos. Prints the ids
it names: [10, id] is a person's photo or 360 (tools/silo/tour360.py walks on from one), [2, id] Google's own.
"""
import sys, re, urllib.request
lat, lon, rad = sys.argv[1], sys.argv[2], sys.argv[3]
V = {'solo10': '!3m10!2m2!1sen!2sUS!9m1!1e2!11m4!1m3!1e10!2b1!3e2',
     'todo': '!3m18!2m2!1sen!2sUS!9m1!1e2!11m12!1m3!1e2!2b1!3e2!1m3!1e3!2b1!3e2!1m3!1e10!2b1!3e2'}
for name, third in V.items():
    for head in ('!1m4!1smaps_sv.tactile!11m2!2m1!1b1', '!1m5!1sapiv3!5sUS!11m2!1m1!1b0'):
        pb = '%s!2m4!1m2!3d%s!4d%s!2d%s%s!4m6!1e1!1e2!1e3!1e4!1e8!1e6' % (head, lat, lon, rad, third)
        url = 'https://www.google.com/maps/photometa/si/v1?authuser=0&hl=en&gl=us&pb=' + pb
        try:
            t = urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (map-tool)'}), timeout=40).read().decode('utf8', 'replace')
            ids = re.findall(r'\[(\d+),"([\w-]{15,})"\]', t)
            print(name, head[:12], len(t), ids[:6])
        except Exception as e:
            print(name, head[:12], 'fail', e)
