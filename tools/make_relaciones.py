"""Builds guion/relaciones.html — the relationship tree of Matritellus, for the writer (not part of the game).

Data: guion/relaciones.json (people, links, loose ends). Photos: guion/fotos/<id>.png, made by the game itself with
    godot --path godot --fixed-fps 60 -- --selftest --portraits
The page is one self-contained file (photos embedded) so it can be opened anywhere.

    python tools/make_relaciones.py
"""
import base64
import html
import json
import os
from datetime import date

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, "guion", "relaciones.json")
FOTOS = os.path.join(ROOT, "guion", "fotos")
OUT = os.path.join(ROOT, "guion", "relaciones.html")

DX, DY = 176, 186          # grid pitch of the drawing
R = 44                     # radius of a face
PAD_X, PAD_Y = 96, 70
KINDS = {"familia": "Familia", "trato": "Vecindad y trato", "negocio": "Negocio"}

e = html.escape


def photo(pid):
    path = os.path.join(FOTOS, pid + ".png")
    if not os.path.exists(path):
        return ""
    with open(path, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode("ascii")


def wrap(text, width):
    """breaks a name into lines of about `width` characters"""
    lines, line = [], ""
    for word in text.split():
        if line and len(line) + 1 + len(word) > width:
            lines.append(line)
            line = word
        else:
            line = (line + " " + word).strip()
    if line:
        lines.append(line)
    return lines


def main():
    with open(DATA, encoding="utf8") as f:
        data = json.load(f)
    people = {p["id"]: p for p in data["people"]}
    for link in data["links"]:
        assert link["a"] in people and link["b"] in people, link
        assert link["kind"] in KINDS, link
    spots = {}
    for p in data["people"]:
        spot = tuple(p["pos"])
        assert spot not in spots, "two people on the same square: %s and %s" % (spots[spot], p["id"])
        spots[spot] = p["id"]

    def at(pid):
        c, r = people[pid]["pos"]
        return PAD_X + c * DX, PAD_Y + r * DY

    cols = max(p["pos"][0] for p in data["people"]) + 1
    rows = max(p["pos"][1] for p in data["people"]) + 1
    width = PAD_X * 2 + (cols - 1) * DX
    height = PAD_Y + (rows - 1) * DY + 110

    svg = ['<svg viewBox="0 0 %d %d" width="%d" height="%d" role="img" aria-label="Árbol de relaciones">' % (width, height, width, height)]
    svg.append("<defs>")
    for p in data["people"]:
        x, y = at(p["id"])
        svg.append('<clipPath id="c_%s"><circle cx="%d" cy="%d" r="%d"/></clipPath>' % (p["id"], x, y, R))
    svg.append("</defs>")

    # the links first, so the faces sit on top of them
    labels = []
    for link in data["links"]:
        ax, ay = at(link["a"])
        bx, by = at(link["b"])
        svg.append('<line class="k_%s" x1="%d" y1="%d" x2="%d" y2="%d"><title>%s</title></line>'
                   % (link["kind"], ax, ay, bx, by, e(link["detail"])))
        mx, my = (ax + bx) / 2.0, (ay + by) / 2.0
        if ax == bx:
            my = min(ay, by) + abs(by - ay) * 0.74    # clear of the upper one's name, which hangs under the face
        text = link["label"]
        w = 7.0 * len(text) + 14
        labels.append('<g class="lab k_%s"><rect x="%.0f" y="%.0f" width="%.0f" height="20" rx="10"/>'
                      '<text x="%.0f" y="%.0f">%s</text><title>%s</title></g>'
                      % (link["kind"], mx - w / 2, my - 10, w, mx, my + 4.5, e(text), e(link["detail"])))

    for p in data["people"]:
        x, y = at(p["id"])
        src = photo(p["id"]) if p.get("foto") else ""
        if src:
            svg.append('<circle class="back" cx="%d" cy="%d" r="%d"/>' % (x, y, R))
            svg.append('<image href="%s" x="%d" y="%d" width="%d" height="%d" preserveAspectRatio="xMidYMin slice" clip-path="url(#c_%s)"/>'
                       % (src, x - R, y - R, R * 2, R * 2, p["id"]))
            svg.append('<circle class="ring" cx="%d" cy="%d" r="%d"/>' % (x, y, R))
        else:
            svg.append('<circle class="ghost" cx="%d" cy="%d" r="%d"/>' % (x, y, R - 6))
            svg.append('<text class="q" x="%d" y="%d">?</text>' % (x, y + 11))
        top = y + (R if src else R - 6) + 18
        for i, line in enumerate(wrap(p["name"], 17)):
            svg.append('<text class="name%s" x="%d" y="%d">%s</text>' % ("" if src else " faint", x, top + i * 17, e(line)))
    svg.extend(labels)
    svg.append("</svg>")

    # the cards
    cards = []
    for p in data["people"]:
        mine = []
        for link in data["links"]:
            if p["id"] in (link["a"], link["b"]):
                other = people[link["b"] if link["a"] == p["id"] else link["a"]]
                mine.append('<li><span class="dot k_%s"></span><b>%s</b> — %s <span class="src">%s</span></li>'
                            % (link["kind"], e(other["name"]), e(link["detail"]), e(link["source"])))
        src = photo(p["id"]) if p.get("foto") else ""
        pic = '<img src="%s" alt="">' % src if src else '<div class="nopic">?</div>'
        tag = "" if p.get("foto") else '<span class="tag">solo se nombra</span>'
        cards.append(
            '<article class="card" id="p_%s">%s<div><h3>%s %s</h3><p>%s</p><p class="where">%s</p>%s%s</div></article>'
            % (p["id"], pic, e(p["name"]), tag, e(p["role"]), e(p["where"]),
               ('<p class="note">%s</p>' % e(p["notes"])) if p.get("notes") else "",
               ("<ul>%s</ul>" % "".join(mine)) if mine else '<p class="none">Sin relaciones dichas todavía.</p>'))

    seen = sum(1 for p in data["people"] if p.get("foto"))
    page = PAGE % {
        "svg": "\n".join(svg),
        "cards": "\n".join(cards),
        "cabos": "".join("<li>%s</li>" % e(c) for c in data.get("cabos", [])),
        "legend": "".join('<span><i class="sw k_%s"></i>%s</span>' % (k, v) for k, v in KINDS.items()),
        "count": "%d personajes en el juego · %d solo nombrados · %d relaciones" % (seen, len(people) - seen, len(data["links"])),
        "day": date.today().strftime("%d/%m/%Y"),
    }
    with open(OUT, "w", encoding="utf8", newline="\n") as f:
        f.write(page)
    print("relaciones.html: %d people, %d links, %d KB" % (len(people), len(data["links"]), os.path.getsize(OUT) // 1024))


PAGE = """<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Matritellus · Relaciones</title>
<style>
:root {
  --paper: #f8f5ec; --card: #fffdf7; --ink: #2a221c; --soft: #6d5f52; --line: #d9cfbd;
  --familia: #c0492f; --trato: #3b6f9a; --negocio: #a8791a; --wash: #cdd9e6;
}
@media (prefers-color-scheme: dark) {
  :root { --paper: #1d1a17; --card: #26221e; --ink: #f1eadc; --soft: #b3a696; --line: #453d35;
          --familia: #ec7a5e; --trato: #7fb2dc; --negocio: #e0b354; --wash: #3a4654; }
}
* { box-sizing: border-box; }
body { margin: 0; background: var(--paper); color: var(--ink); font: 16px/1.5 "Segoe UI", system-ui, sans-serif; }
main { max-width: 1500px; margin: 0 auto; padding: 28px 16px 60px; }
h1 { font-size: 30px; margin: 0 0 2px; letter-spacing: .01em; }
h2 { font-size: 20px; margin: 40px 0 12px; }
.sub { color: var(--soft); margin: 0 0 14px; }
.legend { display: flex; flex-wrap: wrap; gap: 6px 20px; font-size: 14px; color: var(--soft); margin: 0 0 10px; }
.legend span { display: inline-flex; align-items: center; gap: 7px; }
.sw { width: 26px; height: 0; border-top: 3px solid; display: inline-block; }
.sw.k_familia { border-color: var(--familia); } .sw.k_trato { border-color: var(--trato); }
.sw.k_negocio { border-color: var(--negocio); border-top-style: dashed; }
.ghostkey { width: 18px; height: 18px; border-radius: 50%%; border: 2px dashed var(--soft); display: inline-block; }
.tree { overflow-x: auto; background: var(--card); border: 1px solid var(--line); border-radius: 14px; padding: 8px; }
svg { display: block; margin: 0 auto; max-width: none; }
svg line { stroke-width: 3; stroke-linecap: round; }
line.k_familia { stroke: var(--familia); } line.k_trato { stroke: var(--trato); }
line.k_negocio { stroke: var(--negocio); stroke-dasharray: 7 6; }
.back { fill: var(--wash); } .ring { fill: none; stroke: var(--ink); stroke-width: 3; }
.ghost { fill: var(--card); stroke: var(--soft); stroke-width: 2.5; stroke-dasharray: 5 5; }
.q { font-size: 32px; font-weight: 700; fill: var(--soft); text-anchor: middle; }
.name { font-size: 14.5px; font-weight: 700; fill: var(--ink); text-anchor: middle; }
.name.faint { font-weight: 600; font-style: italic; fill: var(--soft); }
.lab rect { fill: var(--card); stroke-width: 1.5; }
.lab text { font-size: 12.5px; font-weight: 600; text-anchor: middle; }
.lab.k_familia rect { stroke: var(--familia); } .lab.k_familia text { fill: var(--familia); }
.lab.k_trato rect { stroke: var(--trato); } .lab.k_trato text { fill: var(--trato); }
.lab.k_negocio rect { stroke: var(--negocio); } .lab.k_negocio text { fill: var(--negocio); }
.cards { display: grid; grid-template-columns: repeat(auto-fill, minmax(340px, 1fr)); gap: 14px; }
.card { display: grid; grid-template-columns: 84px 1fr; gap: 14px; background: var(--card); border: 1px solid var(--line);
        border-radius: 12px; padding: 14px; }
.card img, .nopic { width: 84px; height: 103px; border-radius: 6px; border: 2px solid var(--ink); background: var(--wash); object-fit: cover; }
.nopic { display: grid; place-items: center; font-size: 34px; font-weight: 700; color: var(--soft); border-style: dashed;
         border-color: var(--soft); background: none; }
.card h3 { margin: 0 0 4px; font-size: 17px; }
.card p { margin: 0 0 4px; }
.where { color: var(--soft); font-size: 14px; } .note { font-size: 14px; font-style: italic; }
.none { color: var(--soft); font-size: 14px; }
.tag { font-size: 11.5px; font-weight: 600; color: var(--soft); border: 1px dashed var(--soft); border-radius: 9px; padding: 1px 7px;
       vertical-align: 2px; margin-left: 4px; white-space: nowrap; }
.card ul { list-style: none; margin: 8px 0 0; padding: 8px 0 0; border-top: 1px solid var(--line); font-size: 14px; }
.card li { margin: 0 0 5px; padding-left: 16px; position: relative; }
.dot { position: absolute; left: 0; top: 7px; width: 9px; height: 9px; border-radius: 50%%; }
.dot.k_familia { background: var(--familia); } .dot.k_trato { background: var(--trato); } .dot.k_negocio { background: var(--negocio); }
.src { color: var(--soft); font-size: 12px; font-family: Consolas, monospace; white-space: nowrap; }
.cabos { padding-left: 20px; } .cabos li { margin-bottom: 4px; }
footer { color: var(--soft); font-size: 13px; margin-top: 34px; }
code { font-family: Consolas, monospace; font-size: .92em; }
</style>
</head>
<body>
<main>
<h1>Matritellus · quién es de quién</h1>
<p class="sub">%(count)s · al día a %(day)s</p>
<div class="legend">%(legend)s<span><i class="ghostkey"></i>Solo se le nombra en los diálogos</span></div>
<div class="tree">
%(svg)s
</div>
<h2>Fichas</h2>
<div class="cards">
%(cards)s
</div>
<h2>Cabos sueltos</h2>
<ul class="cabos">%(cabos)s</ul>
<footer>Documento de trabajo, no forma parte del juego. Sale de <code>guion/relaciones.json</code> con
<code>python tools/make_relaciones.py</code>; las fotos, del propio juego (<code>--selftest --portraits</code>).
El texto gris de cada relación es la clave del diálogo donde se dice (<code>godot/scripts/loc.gd</code>).</footer>
</main>
</body>
</html>
"""

if __name__ == "__main__":
    main()
