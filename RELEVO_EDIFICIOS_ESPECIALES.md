# Relevo de «Edificios Especiales»

Hoja para la IA que continúe el trabajo de la sesión de Claude «Edificios Especiales» (Pretil) mientras está en pausa. Escrita el 22 de noviembre de 2026. Recoge las normas de Luis que solo estaban en la memoria de esa sesión y lo que hay que respetar para no romper su trabajo ni el de las otras sesiones.

## Qué es este papel

Edificios Especiales hace a mano los lugares singulares del pueblo: iglesias, plazas, tiendas con nombre, el cruce de los semáforos. Cada uno es un archivo propio en `godot/scripts/` sobre el kit `obra.gd`.

No son de este papel:

- las casas calle a calle (sesión «Texturas»: `casas.gd`, `casas_calles.gd`, `texturas.gd`, `tools/casas/`, el horneado del mapa);
- los sistemas del juego (sesión «Sistemas»: misiones, tráfico, personajes, `props.gd`, `semaforos.gd`, `game.gd`, commits y versiones).

## Antes de tocar nada

Leer, en este orden:

1. [PROJECT_STATE.md](PROJECT_STATE.md): el apartado «Cómo trabajar» y la lista «Sin publicar».
2. [README.md](README.md): «Varias sesiones en la misma carpeta».
3. [TRASPASO_CLAUDE.md](TRASPASO_CLAUDE.md): las últimas entradas de «Edificios Especiales» y el apartado «Cómo mantener el registro».
4. El `LEEME.md` del lugar en `referencias/<lugar>/`. Para el cruce, [referencias/cruce/LEEME.md](referencias/cruce/LEEME.md).

## Lo que puede estropear el trabajo

**Git.** `HEAD` es `d4066ba` (0.0.20) y hay unas 150 rutas sin commit. Casi todo el cruce de los semáforos son archivos sin seguimiento: `cruce.gd`, `esquina.gd`, `sopiss.gd`, `clinica.gd`, `stana2.gd`, `mirador.gd`, `beige.gd`, sus carpetas de `assets/`, `tools/cruce/` y `referencias/cruce/`.

- No ejecutar `git clean`, `git reset --hard`, `git checkout -- .`, `git restore .`, `git stash` ni cambiar de rama: se perderían.
- No hacer commit, push ni etiquetas. Los hace Sistemas, o Luis.
- No tocar `X:\Matritellus`: es la copia de seguridad.

**Godot.** Nunca dos a la vez: antes de cada prueba, comprobar que no hay otro (`tasklist | findstr /i godot`). No lanzar pruebas mientras otra sesión hornea el mapa.

**Mapa.** No hornear (`tools/bake_godot.py`) ni editar `godot/data/map.json` sin que Luis lo sepa: es de Texturas, y un horneado a medias de otra sesión se pisa.

**Archivos compartidos.** `world.gd`, `selftest.gd`, `map_data.gd`, `game.gd`, `loc.gd`, `entradas.gd`: solo añadir líneas, nunca reordenar, reformatear ni reescribir el archivo. Decírselo antes a Luis.

**Archivos de otros.** No editar `semaforos.gd`, `props.gd`, `traffic.gd` (Sistemas) ni `casas.gd`, `casas_calles.gd`, `texturas.gd`, `tools/casas/` (Texturas). Si hace falta un cambio ahí, pedírselo a Luis.

**Formato.** Cambios pequeños y localizados. Conservar los finales de línea de cada archivo y los tabuladores de GDScript. Los comentarios del código van en inglés; los textos del juego, en castellano manchego ([guion/palabros.md](guion/palabros.md)); las notas, en castellano.

**Lugares aprobados.** Lo que Luis ha dado por bueno no se retoca si él no lo pide. No renombrar nada que ya tenga nombre.

**Nombres que usan otros archivos.** No cambiar funciones ni variables públicas de un lugar sin buscar antes quién las usa. Del cruce, `semaforos.gd` y `props.gd` usan: `world.cruce.heads` (los nombres `"avenida"` y `"arcos"` tienen que ser exactos), `walk`, `auto`, `broken`, `down`, `set_light()`, `set_walk()`, `repair()`, `fallen()`. La prueba usa además `part()`, `lights()` y `put_back()`.

## Normas de Luis para estos lugares

- **Marcas y números.** En el juego no hay marcas reales ni números de portal. Cada lugar lleva el nombre que le puso Luis; está en su LEEME.
- **«La Mancha».** En los rótulos, nunca «Castilla-La Mancha».
- **Personajes.** No crear personajes ni figuras de personas por cuenta propia.
- **Azafrán escondido.** Solo se propone, un sitio por lugar, y se espera a que Luis diga sí o no. No se añade sin su sí.
- **Luces.** Las nuevas, sin sombras. Mejor un material que brille que una luz.
- **Sin censura.** Los insultos y palabras locales van tal cual.
- **Lo sucio se queda sucio.** Pintadas, desconchones y trastos de las fotos se copian, no se limpian.
- **Fotos ajenas.** Las capturas de Street View y demás no se guardan en el repositorio; van a una carpeta temporal fuera de él. En `guion/fotos/<lugar>/` solo van capturas del juego.
- **Nada hacia fuera.** No subir nada a servicios externos ni poner datos personales de Luis en peticiones.
- **Fuentes.** Para fachadas y huecos, fiarse más del Street View que del Catastro, que a veces va desplazado uno o dos metros.
- **Modelos libres.** Si un objeto pequeño existe como modelo CC0 o CC-BY, usarlo en vez de hacerlo con cajas. Los descargados van en carpeta nueva y sin ejecutar nada de ellos.
- **Poco a poco.** Un lugar, o una pieza de un lugar, cada vez. Enseñar hojas de capturas comparadas con las fotos y esperar el visto bueno antes de seguir.

## Cómo se hace un lugar

- **Código.** Un archivo `godot/scripts/<lugar>.gd` que extiende `obra.gd` (o `esquina.gd`, para casas de esquina). Las piezas se dibujan con `box`, `bar`, `drum`, `slab`, `flat`… y se cierran con `_commit()`. Lo que para al jugador se añade con `solid()`.
- **Enganche.** En `world.gd`: un `preload`, una variable y un paso de construcción. Si ocupa una casa del mapa, esa casa pasa a `["obra"]` en `casas_calles.gd`, y eso lo cede Texturas.
- **Alturas.** Siempre `MapData.height(p)`. En calles en cuesta hay trampas de terrazas: están en los LEEME de `escuela_calasanz`, `ermita_caridad` y `travesia_clavel`.
- **Medidas.** La receta está en [referencias/petril/LEEME.md](referencias/petril/LEEME.md) y [referencias/plaza_ayuntamiento/LEEME.md](referencias/plaza_ayuntamiento/LEEME.md); la del cruce, con sus herramientas (`tools/cruce/`), en su LEEME.
- **Prueba.** Un modo propio en `selftest.gd` (`--<lugar>`): comprobaciones y, si procede, modo de fotos. Se lanza con `python tools/run_tests.py <lugar> --timeout 400`. Del registro se mira solo el resumen y las líneas `ok`/`FAIL`: no volcarlo entero.
- **Notas.** Un `referencias/<lugar>/LEEME.md` con fuentes, medidas, lo aproximado y las trampas.

## Estado al dejarlo

**Cruce de los semáforos («las cuatro esquinas»).** Seis piezas hechas:

| Pieza | Archivo | Estado |
| --- | --- | --- |
| Seguros Sopiss | `sopiss.gd` | Aprobada |
| Clínica Dental | `clinica.gd` | Aprobada |
| Casa blanca de Santa Ana 2 | `stana2.gd` | Aprobada, sin azafrán |
| Casa crema del mirador | `mirador.gd` | Aprobada, sin azafrán |
| Casa beige del Salvador | `beige.gd` | Aprobada, sin azafrán |
| Semáforos, espejo y señales | `cruce.gd` | Luis dijo «Increíble» y pidió que se rompieran de un golpe; hecho. Falta su visto bueno final |

- Los semáforos se rompen de un golpe y el cruce pasa a ámbar intermitente. Se arreglan al día siguiente con el resto del mobiliario (`props.gd`, `mend()`, de Sistemas).
- Pruebas del 22/11: `cruce` 5 ok y `arreglos` 2 ok. No se ha pasado la prueba completa.
- Sin colocar, por si Luis los pide: los faroles de brazo de las fachadas, las señales de dirección y el semáforo siguiente de la avenida, al norte.
- Propuesto a Sistemas y sin respuesta: que `mend()` mire todos los sitios de `world.cruce.fallen()` antes de levantar lo caído, y no solo la parada de la avenida.

El resto de lugares hechos y aprobados está en «Sin publicar» de `PROJECT_STATE.md`.

## Al terminar cada tarea

- Una entrada en `TRASPASO_CLAUDE.md`, antes del título `## Cómo mantener el registro`, firmada con la IA y «Edificios Especiales». Debe decir qué se hizo, qué archivos se tocaron (los compartidos, aparte), qué prueba se pasó y con qué resultado, y qué queda pendiente.
- Lo que Luis decida o corrija, con sus palabras literales y la fecha. La memoria de Claude no se entera sola: solo sabrá lo que esté escrito ahí.
- La línea del lugar en `PROJECT_STATE.md` y su LEEME, al día.
- Lo que haga falta de Sistemas o de Texturas, escrito en la entrada y dicho a Luis: desde fuera no se puede hablar con esas sesiones.
