# Herramientas de la Plaza del Ayuntamiento

Con esto se midió y se afinó `godot/scripts/plaza.gd` (noviembre de 2026). Son las mismas ideas que en
`tools/petril/` (léelo primero), más lo que hizo falta para un sitio grande y llano visto desde dentro.

Marco de la plaza: **u** a lo largo de la fachada del ayuntamiento (hacia Zaragoza), **n** hacia la plaza, alturas
sobre su suelo. Es el de `MapData.townhall`.

## Qué hay
- `vistas_sv.py` — las 21 vistas de Street View con que se compara el juego: desde dónde (ya corregido), rumbo,
  cabeceo y campo. Sin argumentos imprime el `--vistas=...` para la prueba; con `hoja` monta «Street View | juego».
  Las capturas no están en el repositorio (son de Google y de un particular): hay que volver a hacerlas.
- `suelo_px.py` — dónde cae en el suelo un píxel de una captura (el pie de un muro, un bordillo, el pie de un
  árbol), dada la cámara. Así se sacaron los parterres, la fuente y sus anillos.
- `marco_p.py` — el marco de la plaza: `python marco_p.py w x,z` (mapa → marco) y `l u,n` (marco → mapa).
- `aerea_wmts.py` — baja la ortofoto del IGN por teselas (la de `tools/ign/plaza_wmts.jpg`); `historico.py`, las de
  otros años. `aerea_marco.py` las gira al marco de la plaza con rejilla en metros. `desde_arriba.py` pone la
  ortofoto al lado de la vista cenital del juego.
- `suelo.py` — reconstruye el suelo visto desde arriba a partir de capturas que miran hacia abajo.
- `encaja.py`, `pareja.py`, `color.py`, `zoom.py` — como en `tools/petril/` (ajustar una cámara a puntos conocidos,
  hoja foto | juego, color medio de un parche, trozo ampliado con rejilla).

## Lo que se aprendió aquí
1. **La posición de Google no vale para panorámicas tomadas dentro de una plaza** (falló hasta 4 m; en calle, 1–2).
   Antes de medir nada desde una panorámica, hay que clavarla:
   - *distancia a una fachada*: si la fachada tiene un ritmo conocido (aquí, arcos cada 3,0 m), los píxeles entre
     dos pilares dan la distancia: `d = f · 3,0 / píxeles`, con `f = (alto/2) / tan(campo/2)`;
   - *de lado*: un punto de la fachada cuya u se conoce (el frontón, una esquina);
   - *altura de la cámara*: el pie de los pilares (coche de 2013: 2,56 m; fotoesfera a mano: 1,3 m);
   - una **fotoesfera de particular** (cosida por un móvil) no se deja clavar: sus rumbos bailan hasta 4° de una
     parte a otra de la esfera. Sirve para ver cómo son las cosas (la valla, el surtidor, los anillos de colores),
     no para situarlas. Aquí moví el parque infantil y un abeto dos veces siguiéndola, hasta que miré la ortofoto.
2. **Las cifras de una rejilla son píxeles de la captura original**, no de la hoja donde se pegó reducida. Comparar
   una coordenada leída en una hoja de 560 px con otra en 800 px costó una hora de conclusiones falsas.
3. **Lejos, la profundidad no vale; la dirección sí.** A 25 m, un grado de error en el cabeceo son 5 m. Para algo
   lejano, cruzar las direcciones desde dos panorámicas; para algo redondo, sus dos tangentes y el punto más cercano.
4. **El pie, no la coronación.** Un murete de 0,45 m visto desde 2,5 m de altura «cae» más lejos por arriba.
5. **Un tinte es un color de pantalla (sRGB), no luz.** Para multiplicar la luz por k hay que poner
   `srgb(lin(tinte) · k)`; poner 2,5 en el azul es nueve veces la luz (el ladrillo salió azul).
6. **Los colores, por proporción** respecto a algo blanco de la misma foto (aquí, la planta alta): las fotos de día
   nublado son más oscuras que el juego, pero la razón ladrillo/blanco se conserva.
7. **Catastro puede tener «edificios» que no lo son** (la fuente): mirar qué levanta el mapa dentro de la zona.
8. **Muchos sólidos, cuerpo propio.** El cuerpo físico del mundo es una sola forma compuesta y tiene un tope de
   piezas; al pasarlo, *todo el pueblo* deja de ser sólido («Compound hierarchy is too deep»). `obra.gd` pone los
   sólidos de cada sitio en un `StaticBody3D` suyo.
9. **A cada fuente, lo suyo.** Catastro para la planta de los edificios; la ortofoto para todo lo que está a ras de
   suelo (y para el *tamaño* de un tejado, no para su sitio); las panorámicas del coche, ya clavadas, para alturas y
   para lo que la ortofoto tapa con árboles; la fotoesfera, solo para el aspecto. Y la vista cenital del juego
   (`shots/plaza_above.png`) al lado de la ortofoto es la comprobación que más errores saca de una vez.
9b. **Ortofotos de otros años** (`pnoa-historico`, capas `PNOA2006` … `PNOA2024`): dicen qué es nuevo y qué estaba,
   y enseñan el suelo donde hoy lo tapan los árboles.

10. **La prueba completa depende de lo primero que `props.gd` pone en el pueblo**, que es la terraza de esta plaza:
    estrella un coche contra su toldo viniendo desde 6 m al norte y deja el coche allí para una docena de
    comprobaciones más. Si se cambia la terraza (dónde está, o toldo por sombrillas) o se pone algo sólido en ese
    pasillo, fallan «driving into street furniture…» y «the car rolls on». Por eso el toldo del quiosco es corto y
    sus toneles están pegados a la pared.
    Desde el 15-11-2026 la terraza la coloca la plaza pieza a pieza (`_kiosk`, al final), y se hizo de modo que
    esa prueba vea lo mismo que veía: **la primera pieza es un toldo en `spot(-12.5, 56.6)`** con el mismo radio de
    golpe (2,3 m: por eso ese mide 4 m), y en el pasillo del coche (de (-15,3, 50,6) a (-12,8, 56,0) en el marco de
    la plaza) no hay nada más a su alcance que ese toldo y la mesa de debajo: los demás toldos están a más de 4 m
    de esa línea, las mesas a más de 2 y los clientes de pie lejos. Quien mueva un toldo, que rehaga la cuenta
    (alcance = 1,11 m del coche + el radio de la pieza).

## Pruebas
`--selftest --plaza` (con ventana) fotografía la plaza desde quince sitios y comprueba niveles, lo que debe parar y
lo que no, y que se entra a pie por los arcos y las dos escalinatas. `--selftest --acera`, el lado del Arroyuelo.
