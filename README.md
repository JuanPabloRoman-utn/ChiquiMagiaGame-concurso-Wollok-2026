# Chiqui Mafia Game

Juego con Wollok Game — TP Paradigmas de Programación (UTN) · Equipo LosDelFondo.

## Cómo correr

```
wollok run src.Juego.juego --port 4200
```

Luego abrir `http://localhost:4200`. Para moverse: clic en el tablero + **W A S D** (una casilla por tecla).

## Convenciones del motor (base para todos los tableros / salas)

Sistema de **tiles**: todo se alinea a una grilla. Esta es la base para construir las salas del juego sobre las mismas dimensiones.

- **Casilla (`cellSize`): 64 px.** 1 casilla = 1 baldosa = 1 movimiento. Siempre alineado.
- **Tablero estándar: 20 × 12 casillas** (= 1280 × 768 px).
- **Piso:** `game.ground("img/PisoAFA.png")` — una baldosa de 64×64 que se repite en cada casilla (grilla uniforme y pareja). NO usar una sola imagen grande estirada (`boardGround`): deforma y descuadra la grilla.
- **Sprites:** PNG de **64×64**, **fondo transparente**, personaje centrado. Los originales en alta resolución van en `assets/img/hd/`.
- **Movimiento:** casilla por casilla; el método `moverA` chequea los límites del tablero → **paredes invisibles** en el borde (no te salís).
- **Decoración / paredes / muebles:** se agregan como **objetos (visuales) sobre casillas** (estilo tilemap), no como una foto de fondo. Así todo queda alineado a la grilla.
- **Assets:** viven en `assets/` (declarado por `resourceFolder: "assets"` en `package.json`) y se referencian con su ruta relativa, respetando mayúsculas: `"img/Nombre.png"`.

## Estructura

- `src/Juego.wpgm` — programa principal (tablero, piso, controles).
- `src/Personajes.wlk` — objetos del dominio (por ahora `jugador`).
- `assets/img/` — imágenes del juego (sprites 64×64, baldosas). `assets/img/hd/` guarda los originales HD.
