# Diagrama de clases — Chiqui Mafia Game

```mermaid
classDiagram
    direction TB

    %% ---------- Jerarquía de salas (herencia + clase abstracta) ----------
    class Sala {
        <<abstract>>
        +fondo()
        +posicionInicial()
        +salidas() : Salida[]
        +esPared(pos)
        +estaLibre(pos)
        +haySalida(pos)
        +alEntrar()
        +alSalir()
        +jugadorSeMovio(pos)
    }
    class salaPatio {
        <<object>>
        +estaLibre(pos) *override*
        +jugadorSeMovio(pos) *override*
    }
    class salaPrincipal {
        <<object>>
        +estaLibre(pos) = super(pos)...
        +hayMueble(pos)
    }
    class salaToviggino {
        <<object>>
    }
    class salaBeligoy {
        <<object>>
    }
    class salaCaruso {
        <<object>>
    }
    Sala <|-- salaPatio
    Sala <|-- salaPrincipal
    Sala <|-- salaToviggino
    Sala <|-- salaBeligoy
    Sala <|-- salaCaruso

    %% ---------- Coordinador ----------
    class director {
        <<object>>
        salaActual : Sala
        estado
        indicadores
        +irA(sala)
        +moverJugador(mov)
        +perderVida()
        +gameOver()
        +confirmar()
        +mostrarPantalla(img, estado)
        +dibujarHud()
        +titilar()
    }
    director --> Sala : salaActual
    director ..> jugador : mueve / pierde vida

    %% ---------- Jugador y PNJs ----------
    class jugador {
        <<object>>
        position
        image
        vidas
        pruebas
        +mirar(haciaArriba)
    }
    class toviggino {
        <<object>>
        mirando
        ticks
        +estaMirando()
        +reset()
        +pensar()
        +girar()
    }
    class aliadoCaruso {
        <<object>>
        position
        image
    }

    %% ---------- Minijuegos (delegación desde las salas) ----------
    class minijuegoToviggino {
        <<object>>
        completado
        +iniciar()
        +jugadorSeMovio(pos)
        +chequearPruebas(pos)
        +empezarEscape()
    }
    class minijuegoBeligoy {
        <<object>>
        completado
        +iniciar()
        +jugadorSeMovio(pos)
    }
    class minijuegoCaruso {
        <<object>>
        completado
        camino
        +iniciar()
        +mostrarPatron(ms, msg)
        +jugadorSeMovio(pos)
    }
    salaToviggino ..> minijuegoToviggino : delega
    salaBeligoy ..> minijuegoBeligoy : delega
    salaCaruso ..> minijuegoCaruso : delega

    minijuegoToviggino ..> toviggino
    minijuegoToviggino ..> Prueba : crea
    minijuegoToviggino ..> director : perderVida()
    minijuegoBeligoy ..> Archivero : crea
    minijuegoBeligoy ..> director : perderVida()
    minijuegoCaruso ..> aliadoCaruso
    minijuegoCaruso ..> MarcaPatron : crea
    minijuegoCaruso ..> director

    %% ---------- Clases de apoyo ----------
    class Salida {
        x
        y
        destino : Sala
        +esAca(pos)
    }
    class Prueba {
        position
        image
    }
    class Archivero {
        guardaExpediente
        revisado
        +ponerExpediente()
        +tieneExpediente()
        +revisar()
    }
    class MarcaPatron {
        position
        image
    }
    class Flecha {
        position
        image
    }
    class IconoHud {
        position
        image
    }
    class Fondo {
        position
        image
    }
    Sala ..> Salida : salidas()
    Salida --> Sala : destino
    director ..> Flecha : indicadores
    director ..> IconoHud : HUD
    director ..> Fondo

    %% ---------- Config ----------
    class config {
        <<object>>
        debug
    }
    director ..> config : modo test
```

## Notas de diseño (para la defensa)

- **Clase abstracta + herencia:** `Sala` define el contrato (`fondo`, `posicionInicial`, `salidas`, movimiento, colisiones) y 5 salas lo heredan.
- **override:** cada sala redefine `fondo`, `posicionInicial`, `salidas`, y algunas `estaLibre` / `jugadorSeMovio`.
- **super:** `salaPrincipal.estaLibre(pos) = super(pos) and not hayMueble(pos)` — reutiliza la lógica base (bordes) y le suma las paredes de los muebles.
- **Delegación:** las salas de minijuego no tienen la lógica adentro; delegan en los objetos `minijuego*` (bajo acoplamiento, responsabilidades separadas).
- **Coordinador (`director`):** centraliza transiciones entre salas, vidas, game over y HUD.
