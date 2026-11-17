# Referencia: la casa de la esquina del Salvador con Ramón y Cajal («Salvador 2»)

Pedida por Luis el 17-11-2026: «Puedes ponerte con Salvador 2. La casa pegada a toti con dos entradas que hace esquina
en la calle». En el juego no se ve ni la dirección ni el número.

El modelo es `godot/scripts/salvador2.gd` (sobre `obra.gd`), en `world.salvador2`, sobre la casa `cajal_1` del mapa.
Texturas la marca `["obra"]` en `casas_calles.gd`; su línea de antes está en las notas compartidas,
`cajal_1_antes_de_pretil.md`. Sin rehorneado. Herramientas en `tools/salvador2/`.

## Fuentes
- **Street View**: noviembre de 2024, con 2021, 2019, 2013 y 2009 en los mismos sitios, desde el cruce (al norte y al
  oeste) y desde Ramón y Cajal. Por el Salvador, al este del cruce, solo hay de marzo de 2013. Lo descarga
  `tools/salvador2/capturas.py`; las fotos son de Google y no se guardan aquí.
- **Planta**: el contorno del Catastro, menos la esquina. El Catastro saca la esquina 0,9 m hacia Ramón y Cajal y
  0,8 m hacia el Salvador, y en las fotos la planta baja va a haces con las dos fachadas. Así que las dos fachadas siguen
  sus líneas hasta un chaflán de 2 m (`C1`, `C2`), paralelo al del Catastro.

## Lo que lleva
- **Planta baja**: azulejo blanco puesto en rombos sobre un zócalo de granito gris.
  - **A Ramón y Cajal**:
    - la ventana grande con barrotes y su aparato de aire encima;
    - un tramo de ladrillo con la puerta labrada de los pisos, tapada por la cortina de rayas crema y marrón (así está
      desde 2019; en 2013 se veía la madera labrada), con marco de piedra.
  - **En el chaflán**: una puerta acristalada tras una reja de tijera.
  - **Al Salvador**, desde el este: una ventana con barrotes, la otra puerta (oscura, con su rejilla) y la ventana
    grande con barrotes.
  - Las dos entradas de las que habla Luis serían la puerta de Ramón y Cajal y la del Salvador; la del chaflán es una
    tercera.
- **Arriba**: ladrillo marrón oscuro (el `brick_dark` de las casas).
  - En la esquina, un mirador que sobresale 0,55 m en las dos plantas, con tres caras (la redondez real va en
    chaflanes): ventanas anchas con la persiana crema bajada, un antepecho de ladrillo y losas blancas con el sofito de
    madera.
  - A Ramón y Cajal, un balcón por planta. Al Salvador, un balcón largo por planta con dos puertas.
  - Todos los balcones llevan barandilla blanca y toldos de rayas.
  - Bandas blancas en los forjados, albardilla arriba y dos aparatos de aire.
- **La calle**:
  - las dos señales de la esquina (la azul de sentido obligatorio hacia Ramón y Cajal abajo, y la de prohibido salvo
    residentes, con su placa);
  - una maceta redonda con su seto en la acera de la esquina.

## Pruebas
`python tools/run_tests.py salvador2`: fotos desde el cruce, por las dos calles, del mirador y de la puerta, de noche
y desde el aire. Comprueba:
- que está sobre su casa del mapa y que `casas.gd` ya no la dibuja;
- que la esquina te para;
- el mirador (seis ventanas) y los cuatro balcones;
- que la maceta no pisa el asfalto.

Hojas para Luis: `python tools/salvador2/hojas.py CARPETA_SV`, en `guion/fotos/salvador2/`.
