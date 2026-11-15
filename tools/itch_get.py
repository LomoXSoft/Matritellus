"""Fetch the free download of an itch.io asset page the way the page's own "Download Now -> No thanks" does.

  python -I itch_get.py PAGE_URL OUT_DIR          lists the uploads on offer and saves the free one(s) into OUT_DIR
"""
import sys, re, json, os, html
import urllib.request, urllib.parse, http.cookiejar

page, out = sys.argv[1].rstrip("/"), sys.argv[2]
jar = http.cookiejar.CookieJar()
op = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(jar))
op.addheaders = [("User-Agent", "Mozilla/5.0 (asset-fetch)")]


def get(url, data=None):
    if data is not None:
        data = urllib.parse.urlencode(data).encode()
    with op.open(url, data, timeout=120) as r:
        return r.read()


s = get(page).decode("utf8", "replace")
m = re.search(r'name="csrf_token" value="([^"]+)"', s)
csrf = html.unescape(m.group(1))
j = json.loads(get(page + "/download_url", {"csrf_token": csrf}))
print("download page:", "ok" if "url" in j else j)
d = get(j["url"]).decode("utf8", "replace")
key = j["url"].rsplit("/", 1)[1]
ups = re.findall(r'data-upload_id="(\d+)"', d)
names = re.findall(r'<strong class="name" title="([^"]*)"', d)
sizes = re.findall(r'<span class="file_size"><span>([^<]*)</span>', d)
print("uploads:", ups, names, sizes)
os.makedirs(out, exist_ok=True)
for i, u in enumerate(dict.fromkeys(ups)):
    f = json.loads(get("%s/file/%s?%s" % (page, u, urllib.parse.urlencode({"source": "game_download"})), {"csrf_token": csrf}))
    if "url" not in f:
        print("no url for", u, f)
        continue
    name = names[i] if i < len(names) else "upload_%s.zip" % u
    name = re.sub(r'[^A-Za-z0-9._ -]', "_", html.unescape(name))
    with op.open(f["url"], timeout=300) as r:
        blob = r.read()
        cd = r.headers.get("Content-Disposition") or ""
    m2 = re.search(r'filename="?([^";]+)', cd)
    if m2:
        name = re.sub(r'[^A-Za-z0-9._ -]', "_", m2.group(1))
    elif not name.lower().endswith(".zip"):
        name += ".zip"
    open(os.path.join(out, name), "wb").write(blob)
    print("saved", name, len(blob), "bytes")
