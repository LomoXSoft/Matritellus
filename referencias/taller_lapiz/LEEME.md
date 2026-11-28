# «Taller Lápiz» y «Dulces San Paquito» (Avenida de Martín Descalzo)

El electricista del automóvil (el Taller López de verdad) y el obrador de dulces de al lado (Dulces San Francisco).
Los nombres son de Luis, del 27/11/2026: «Vamos ahora con Taller López (que llamaremos taller Lápiz) y dulces san
Francisco (que llamaremos dulces san Paquito) ya que están los edificios pegados». En el juego pone «TALLER LÁPIZ» y
«DULCES SAN PAQUITO».

**Estado**: APROBADO por Luis el 27/11/2026 («Sin azafrán. Visto bueno y pasamos al siguiente local»). No lleva
azafrán. No hay commit.

## Dónde y quién

- Sobre las tres casas del mapa `md_9e` (el taller y la puerta azul), `md_9d` (la nave, que es el obrador) y `md_9c`
  (el pilar blanco, la casa blanca y el almacén beige). Texturas las entregó con `"id": ["obra"]` en `casas_calles.gd`.
  `md_7` (la casa salmón) y `md_9` siguen siendo suyas.
- Sin rehorneado: el mapa tenía las casas y nada más en la parcela.
- Código: `godot/scripts/lapiz.gd` (sobre el kit `obra.gd`). Se construye solo si las tres casas están entregadas, o
  con `--lapiz` en las pruebas.
- Dibujos: `tools/lapiz/dibujos.py` → `godot/assets/lapiz/` (`rotulo.png`, `letras.png`, `dulces.png`,
  `baldosa_gris.png`, `baldosa_salmon.png`).

## Medidas (marco del sitio)

- Origen A = (53.65, −620.16), la esquina entre la casa salmón y el taller. `u` a lo largo de la fachada
  (EU = (0.6112, −0.7915), hacia la casa blanca) y `v` hacia la calle (EV = (0.7915, 0.6112)).
- **Línea de la calle (v = 0)**: el taller y la casa blanca dan a ella, como la casa salmón. **La puerta azul y la
  nave están 2,6 m más atrás** (`BACK`), con la jardinera y las rampas delante (foto aérea de Google; fotos de Luis).
- Taller: de 0 a 14,45. Fachada de 5 m, revoco blanco y zócalo de azulejo gris con rombos blancos. El portón (5,8 ×
  3,35 m) está medio abierto y el resto cerrado con chapa azul. Ventanita y antena.
  - Letras pintadas «ELECTRICIDAD DEL AUTOMÓVIL» de punta a punta de la fachada (0,92 m de alto), con «DEL» más
    pequeño.
  - Tabla «TALLER LÁPIZ» de 7,1 × 1,12 m sobre el pretil, con las letras rosa desvaídas de borde a borde.
  - Dentro: banco, baterías, cargador y neumáticos.
- Puerta azul (de 14,45 a 18,69) y nave (de 18,69 a 33,27): ladrillo cara vista color tostado, postes azules, tres
  ventanas con reja, la puerta de tijera del obrador y el portón azul grande con su farol (`W.lamp_spots`).
  - Fondo de la nave: hasta 20,07 m de la calle (Catastro). Alero a 4,7 m y cumbrera a 6,05 m.
  - Suelo de la nave a 0,38 m. La acera de detrás de la jardinera está a esa altura (son `decks`).
- Jardinera: muro bajo blanco con su remate, 1,7 m por delante de la nave (`ZW`), con rosales en sus hoyos. Dos rampas
  de hormigón (`decks` en cuesta con `grad`), una ante la puerta azul y otra ante el portón, bajan hasta v = 0,3.
- Pilar blanco (de 33,27 a 35,0): sale 0,2 m sobre la línea de la calle.
  - **Su costado suroeste (2,8 m de fondo) da a la calle**. Lleva la tabla de «DULCES SAN PAQUITO», la caja de
    contadores debajo (sobre el final del muro) y la caja blanca de los cables, que dobla la esquina hasta el poste.
  - Luis, 27/11: «El cartel no está en el frente, está en la fachada lateral de la casa blanca, por los que vienen
    conduciendo desde la rotonda vean el cartel de frente».
- Casa blanca (de 36,1 a 42,7): ventana con persiana marrón y reja negra, puerta de madera con cristal, zócalo de
  azulejo salmón. Después, el almacén beige hasta 48,08.
- Delante, hasta la acera del pueblo (la banda de `MapData.sunk`), donde el mapa dejaba tierra:
  - hormigón ante el taller, la puerta azul y el portón;
  - baldosa gris ante la jardinera, el pilar y la casa;
  - el alcorque del árbol.
- En la calle: un árbol (`W.add_trees`), el contenedor beige de tapa verde ante el pilar (`W.extra_props`) y el poste
  de hormigón con su cruceta.

## Horarios (Google Maps) y estados

- Taller: de lunes a viernes de 9 a 20:45, y los sábados de 9 a 14.
  - Cerrado: la hoja de chapa corrida.
  - Abierto: los tubos encendidos y una luz sin sombra.
- Dulces: todos los días de 9 a 14 y de 16 a 20.
  - Cerrado: la tijera echada y la puerta cerrada.
  - Abierto: la tijera plegada, la puerta abierta hacia dentro, el pasillo hacia la mesa del obrador y un brillo flojo.
- `_process` sigue `game.weekday` y `game.clock`.

## La tabla de Dulces

- El fraile es una silueta lisa, como en el cartel de verdad.
- El texto del pergamino es mío: «Obrador artesano / Rosquillas de anís / Mantecados / Mazapanes / Bizcochos /
  Flores de sartén».
- No lleva teléfonos ni direcciones.

## Pruebas

- `python tools/run_tests.py lapiz --timeout 600`: 14 vistas (más las de cerrado y las de noche) y las comprobaciones:
  - las tres casas entregadas;
  - las piezas y los nombres;
  - las fachadas paran al jugador y nada pisa el asfalto;
  - el suelo de detrás de la jardinera y la rampa del portón;
  - el árbol y el contenedor;
  - los horarios y los estados.
- `zfight solo=lapiz.gd`: 1,2 m² exactos, casi todo caras escondidas dentro de la pared de la nave.
- Fotos en `guion/fotos/taller_lapiz/lapiz_vistas.jpg`. La comparación con Street View está en el scratchpad (no se
  guarda en el proyecto).
