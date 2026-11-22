# Chiqui Magia Game

Videojuego 2D desarrollado en **Wollok Game** para la materia *Paradigmas de Programación* y presentado para el concurso de Wollok. Encarnás al detective **Lucho**, que investiga irregularidades en el fútbol y debe reunir pruebas a través de distintos minijuegos antes de llegar al juicio final.

![Pantalla principal del juego](img/FondoMenu.png)

## Participantes

* **[Nehuel Melo]**
* **[Augusto Yañez]**
* **[Juan Pablo Román]**
* **[Carlos Tolosa]**

## Institución

* **Universidad Tecnológica Nacional – Facultad Regional Buenos Aires (UTN FRBA)**
* **Asignatura:** Paradigmas de Programación (2026)

## Reglas del juego

* Empezás la partida con **2 vidas** y **0 pruebas**. Si perdés todas las vidas o fallás las condiciones límite de los minijuegos finales, se activa el *Game Over* y se reinicia el progreso.
* Desde el menú inicial avanzás con `ENTER` al patio y luego al hall principal (`salaPrincipal`), donde se van habilitando los desafíos de forma progresiva:
  1. **Torbellino:** recolectá las **3 pruebas** sin que te vea moverte cuando se da vuelta, y salí antes de que se agoten los **12 segundos** de escape.
  2. **Caruso:** memorizá el camino seguro hasta la celda (`(10, 10)`) antes de que se oculten las marcas y llegá sin pisar fuera del recorrido.
  3. **Archiveros:** encontrá **3 expedientes** en los archiveros antes de que se acabe el tiempo (**30 segundos**). Revisar un archivero limpio resta tiempo.
  4. **Pelado Bicampeón + El fideo:** esquivá al rival por la cancha evitando los pozos trampa hasta llegar a **El fideo** y conseguir la prueba que lleva a las pantallas de historia y al juicio final.
  5. **Juicio final:** conseguí **5 pruebas** antes de que el rival destruya **2** o te toque.

## Forma de uso

* **Desde VS Code:** abrí el proyecto con la extensión de **Wollok** instalada y ejecutá `juego.wpgm` (tablero de `20x12` casillas de `64x64` px).
* **Desde consola:** corré el programa principal en el puerto que uses (por ejemplo `wollok run ... --port 4200`) y abrí `http://localhost:4200` en el navegador.
* **Controles:**
  * `ENTER`: confirmar / avanzar en menús, carteles de introducción, instrucciones e historias.
  * `W`, `A`, `S`, `D`: mover a Lucho casilla por casilla (`W` cambia el sprite a vista de espaldas; `A`, `S`, `D` a vista de frente).

## Información adicional

* **Arquitectura:** el código está organizado en `juego.wpgm` (punto de entrada y bindings de teclado/ticks), `Salas.wlk` (jerarquía `Sala` / `SalaMinijuego`, estados del juego mediante `Estado` y coordinación en `director`), `Personajes.wlk` (entidades, sprites y comportamientos) y `Minijuegos.wlk` (lógica específica de cada minijuego).
* **Modo test (`config.debug`):** el proyecto incluye atajos de teclado (`T`, `B`, `C`, `L`, `K`, `U`) en `juego.wpgm` pensados para pruebas rápidas durante el desarrollo.
* **Assets:** las carpetas `img/` y `sounds/` mantienen sus rutas relativas utilizadas en el código.