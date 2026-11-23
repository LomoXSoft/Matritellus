extends RefCounted
## The clothes and accessories shops (the user, 23 November 2026: "Al colgar desbloqueas todas las tiendas de ropa y
## complementos disponibles. Aparecen como un icono de pesetas"). Shut to you until Josefa's Vizum (fondo_casa.gd
## _vizum; the user first gave it to Tía Paca, then to Josefa, who has the business errands: she rings once you walk
## away from Tía Paca after the tax debt, "una cosa es serlo y otra parecerlo", and sends you 20 € for
## some decent clothes); from then on their doors let you in and a peseta marks each on the map (minimap.gd).
##
## Today: the MaxiPrecio (Pretil's maxiprecio.gd; Maxi inside, maxi.gd), the Tetoqa (Pretil's tetoqa.gd, accessories) and the
## Pisacastaña (Pretil's pisacastana.gd, shoes). A new one goes in SHOPS: the
## world's name for it, what it sells and where its mark goes (its `door`, before its steps or its door, on the pavement).
## What it sells picks its icon on the map (the user, 23 Nov 2026: "iconos para el mapa para las tiendas de ropa, de
## complementos y zapaterías"): the peseta's gold coin with a shirt, a ring or a shoe on it (minimap.gd _shop_icon).

## The Tetoqa is Pretil's accessories shop at Santa Ana and the Cristo; the Pisacastaña, Pretil's shoe shop at Arcos and
## Argentina ("Mismo tratamiento que las otras dos tiendas pero solo con zapatos", the user). One not built yet has no mark.
## Glasses are the opticians' and only theirs (the user, 23 Nov 2026, of the Óptica Corsa of the Calle del Salvador:
## "icono de gafas, y dividimos las tiendas entre complementos y gafas, gafas en las ópticas y complementos en las
## tiendas de complementos"): Pretil's optica.gd, Fátima Corsa inside (fatima.gd).
const KINDS := ["ropa", "complementos", "zapatos", "gafas"]
const SHOPS := {
	"maxiprecio": "ropa",
	"tetoqa": "complementos",
	"pisacastana": "zapatos",
	"optica": "gafas",
}

var G

func setup(game) -> void:
	G = game

func unlocked() -> bool:
	return G != null and G.stats.has("vizum")

## is this place (a set's dentro) one of them, and shut to you yet?
func shut(place) -> bool:
	if unlocked() or place == null:
		return false
	for id in SHOPS:
		var s = G.world.get(id) if G.get("world") != null else null
		if s != null and s.get("dentro") == place:
			return true
	return false

## for the map: {p, kind} at each, once they are open to you
func marks() -> Array:
	var out: Array = []
	if not unlocked():
		return out
	for id in SHOPS:
		var s = G.world.get(id) if G.get("world") != null else null
		if s != null and s.get("door") != null:
			out.append({"p": s.door, "kind": SHOPS[id]})
	return out
