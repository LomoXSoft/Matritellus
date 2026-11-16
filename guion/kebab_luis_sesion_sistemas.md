# Encargo para una sesión aparte: sistemas de juego del Kebab Luis

(Para pegar tal cual al abrir una sesión nueva en `C:\Users\luis_\Matritellus`.)

Responde siempre en español. Lee primero tus notas de memoria del proyecto. Otra sesión se dedica SOLO a texturas y
modelos y edita a la vez en esta carpeta: no toques `godot/scripts/casas.gd`, `casas_calles.gd`, `texturas.gd`,
`tela.gd`, `tools/bake_godot.py` ni `godot/data/map.json`, y no hornees el mapa. Puedes editar `kebab.gd` y `game.gd`
para la lógica, pero no cambies el aspecto del local.

Construye los sistemas de juego que el usuario ha pedido para el Kebab Luis y que aún no existen. La especificación
completa, con sus palabras, está en `guion/kebab_luis_diseno.md`: léela entera y síguela al pie de la letra; lo que no
diga, pregúntaselo en vez de suponerlo. Son cuatro piezas, en este orden, enseñándole cada una antes de pasar a la
siguiente:

1. **Clientes del kebab**: los vecinos que pasen cerca tienen un 33 % de parar, hacer cola ante Don Luis, pedir y
   sentarse en una mesa libre de `kebab.tables` (la mesa `kebab.busy` ya tiene gente fija ese día); comen 30–45 s
   reales, se van 15–30 s después y siguen su ruta.
2. **Comida y estado físico** (sistema general): más de tres comidas en un día del juego suben al jugador a la
   siguiente anchura (`build` en `godot/scripts/creator.gd`: 0.86, 1.0, 1.2); cuatro en la anchura máxima provocan el
   desmayo (pantalla de borracho, tropezón tipo ragdoll cada 10 s, a los 50 s fundido a negro y aparecer en el centro
   de salud, que aún no está modelado: pregunta dónde aparecer mientras tanto).
3. **Reglas generales de misiones**: aceptar o rechazar toda misión; Sí/No en las de teléfono y rellamada; Pitufos a
   la mitad con misión activa.
4. **Misión secundaria de Don Luis** (sabotear los otros tres kebabs siguiendo al camión de reparto). Los otros tres
   son **Kebab Deluxe** (Av. Castilla-La Mancha 17), **Tele Dürum** (Calle Santa Ana 44) y **ShawarMadridejos**
   (Av. Castilla-La Mancha 4); sus coordenadas salen de `python tools/locate.py AV "CASTILLA LA MANCHA" 17`, etc.
   El camión y el repartidor: usa un vehículo y un personaje de los que hay y avisa de que son provisionales.

Hecho significa: cada pieza funciona jugando, tiene su comprobación en `godot/scripts/selftest.gd`, la prueba completa
pasa y el usuario ha visto fotos o un clip y ha dicho que vale. Texto nuevo en manchego y en inglés en `loc.gd`; un
personaje nuevo con nombre necesita `firma_si_<id>` y `firma_no_<id>`, entrar en `guion/relaciones.json` y ejecutar
`tools/make_relaciones.py`.
