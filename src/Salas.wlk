import wollok.game.*
import Personajes.*
import Minijuegos.*

// ---------- Salidas, indicadores y fondo ----------
class Salida {
  const property x
  const property y
  const property destino
  method esAca(pos) = pos.x() == x and pos.y() == y
}

class Flecha {
  const property position
  const property image = "img/FlechaVerde.png"
}

class Fondo {
  const property position = game.at(0, 0)
  const property image
}

// Icono del HUD (inventario de pruebas, vidas) parado en una casilla.
class IconoHud {
  const property position
  const property image
}

// ---------- Salas ----------
class Sala {
  method fondo()            // polimórfico
  method posicionInicial()  // polimórfico
  method salidas() = []

  method esPared(pos) =
    pos.x() == 0 or pos.x() == game.width() - 1 or
    pos.y() == 0 or pos.y() == game.height() - 1

  method estaLibre(pos) =
    pos.x().between(0, game.width() - 1) and
    pos.y().between(0, game.height() - 1) and
    not self.esPared(pos)

  method haySalida(pos) = self.salidas().any({ unaSalida => unaSalida.esAca(pos) })
  method salidaEn(pos) = self.salidas().find({ unaSalida => unaSalida.esAca(pos) })

  // Hooks (por defecto vacíos / comportamiento simple)
  method alEntrar() { }
  method alSalir() { }

  // Reacción a cada movimiento. Por defecto: si pisa una salida, cambia de sala.
  method jugadorSeMovio(pos) {
    if (self.haySalida(pos)) {
      director.irA(self.salidaEn(pos).destino())
    }
  }
}

// Hall de la AFA. La puerta habilitada depende de en qué paso del juego estás.
object salaPrincipal inherits Sala {
  override method fondo() = "img/FondoAFA.png"
  override method posicionInicial() = game.at(9, 2)   // abajo, sobre la alfombra

  // Progresión: Toviggino (puerta x=7) y, al completarlo, Beligoy (puerta x=12).
  // Caruso se juega saliendo directo de Toviggino. El resto de las puertas es futuro.
  override method salidas() =
    if (not minijuegoToviggino.completado()) [ new Salida(x = 7, y = 8, destino = salaToviggino) ]
    else if (not minijuegoBeligoy.completado()) [ new Salida(x = 12, y = 8, destino = salaBeligoy) ]
    else []

  // Vitrinas de las paredes laterales (x1, x18) y pared del fondo con las puertas (y>=9).
  // Reusa la lógica base con super y le suma las paredes internas.
  override method estaLibre(pos) = super(pos) and not self.hayMueble(pos)

  method hayMueble(pos) = pos.x() == 1 or pos.x() == 18 or pos.y() >= 9
}

// Patio de la AFA: aparecés acá al empezar (tras el menú) y caminás hasta la
// puerta del edificio (arriba al centro) para entrar. Al entrar sale el cartel de intro.
object salaPatio inherits Sala {
  override method fondo() = "img/FondoPatioAFA.png"
  override method posicionInicial() = game.at(9, 1)   // portón de abajo
  override method salidas() = [ new Salida(x = 9, y = 9, destino = salaPrincipal) ]  // flecha en la puerta

  // Solo se camina por el camino central (columna x=9), en línea recta hasta la puerta.
  // No se puede pisar el pasto: todo lo demás está bloqueado.
  override method estaLibre(pos) = pos.x() == 9 and pos.y().between(1, 9)

  // En vez de entrar directo, dispara el cartel de intro.
  override method jugadorSeMovio(pos) {
    if (self.haySalida(pos)) { director.mostrarCartel() }
  }
}

// Minijuego 1 - Toviggino. Entrás abajo (al lado de la puerta) y subís al escritorio.
object salaToviggino inherits Sala {
  override method fondo() = "img/SalaToviggino.png"
  override method posicionInicial() = game.at(10, 2)
  override method salidas() = [ new Salida(x = 10, y = 1, destino = salaPrincipal) ]

  override method alEntrar() { minijuegoToviggino.iniciar() }
  override method alSalir() { minijuegoToviggino.terminar() }
  override method jugadorSeMovio(pos) { minijuegoToviggino.jugadorSeMovio(pos) }
}

// Minijuego 2 - Caruso preso. Está en la otra punta; para llegar hay que resolver
// el "camino oculto": solo ciertas baldosas son seguras (patrón escalera).
object salaCaruso inherits Sala {
  override method fondo() = "img/SalaCaruso.png"
  override method posicionInicial() = minijuegoCaruso.posInicial()
  override method salidas() = []   // se gana resolviendo el camino hasta Caruso

  override method alEntrar() { minijuegoCaruso.iniciar() }
  override method alSalir() { minijuegoCaruso.terminar() }
  override method jugadorSeMovio(pos) { minijuegoCaruso.jugadorSeMovio(pos) }
}

// Minijuego 2 - Beligoy. Beligoy salió un rato: revisá su archivo antes de que vuelva (30s).
object salaBeligoy inherits Sala {
  override method fondo() = "img/SalaBeligoy.png"
  override method posicionInicial() = game.at(10, 2)
  override method salidas() = []   // se gana encontrando los expedientes; se pierde si se acaba el tiempo
  override method alEntrar() { minijuegoBeligoy.iniciar() }
  override method alSalir() { minijuegoBeligoy.terminar() }
  override method jugadorSeMovio(pos) { minijuegoBeligoy.jugadorSeMovio(pos) }
}

// ---------- Config / modo test ----------
// Con debug = true se habilitan teclas para saltar a cualquier sala y marcar
// minijuegos como completados (para no tener que jugarlos cada vez que pruebo).
// IMPORTANTE: poner debug = false para la entrega final.
object config {
  var property debug = true
}

// ---------- Director: salas, transiciones y vidas ----------
object director {
  var property salaActual = null
  var estado = "menu"   // "menu" | "jugando" | "cartel"
  const indicadores = []

  method irA(sala) {
    estado = "jugando"
    if (salaActual != null) { salaActual.alSalir() }
    // Limpieza segura: copio la lista antes de borrar (no itero la lista viva).
    game.allVisuals().map({ visual => visual }).forEach({ visual => game.removeVisual(visual) })
    indicadores.clear()
    salaActual = sala
    game.addVisual(new Fondo(image = sala.fondo()))
    sala.salidas().forEach({ unaSalida =>
      const flecha = new Flecha(position = game.at(unaSalida.x(), unaSalida.y()))
      indicadores.add(flecha)
      game.addVisual(flecha)
    })
    jugador.position(sala.posicionInicial())
    if (not game.hasVisual(jugador)) { game.addVisual(jugador) }
    sala.alEntrar()
    self.dibujarHud()
  }

  // HUD: inventario de pruebas (abajo-izquierda) y vidas (abajo-derecha).
  method dibujarHud() {
    if (jugador.pruebas() > 0) {
      (1 .. jugador.pruebas()).forEach({ i =>
        game.addVisual(new IconoHud(position = game.at(i, 0), image = "img/Prueba.png"))
      })
    }
    if (jugador.vidas() > 0) {
      (1 .. jugador.vidas()).forEach({ i =>
        game.addVisual(new IconoHud(position = game.at(game.width() - i, 0), image = "img/Vida.png"))
      })
    }
  }

  method titilar() {
    indicadores.forEach({ indicador =>
      if (game.hasVisual(indicador)) game.removeVisual(indicador) else game.addVisual(indicador)
    })
  }

  // Limpia la pantalla y deja un fondo de pantalla completa (menú / cartel).
  method mostrarPantalla(imagen, nuevoEstado) {
    if (salaActual != null) { salaActual.alSalir() }
    estado = nuevoEstado
    salaActual = null
    indicadores.clear()
    game.allVisuals().map({ visual => visual }).forEach({ visual => game.removeVisual(visual) })
    game.addVisual(new Fondo(image = imagen))
  }

  method mostrarMenu() { self.mostrarPantalla("img/FondoMenu.png", "menu") }
  method mostrarCartel() { self.mostrarPantalla("img/FondoIntro.png", "cartel") }
  
  // Reiniciar vidas y progreso
  method reiniciarDatos(){
    jugador.vidas(2)
    jugador.pruebas(0)
    minijuegoBeligoy.completado(false)
    minijuegoCaruso.completado(false)
    minijuegoToviggino.completado(false)
  }

  // ENTER: avanza según en qué pantalla estés.
  method confirmar() {
    if (estado == "menu") { 
      self.reiniciarDatos()
      self.irA(salaPatio) 
    }

    else if (estado == "cartel") { self.irA(salaPrincipal) }
    else if (estado == "perdiste") {self.mostrarMenu()}
  }

  method moverJugador(movimiento) {
    if (estado == "jugando" and salaActual != null) {
      const destino = movimiento.apply(jugador.position())
      if (salaActual.estaLibre(destino)) {
        jugador.position(destino)
        salaActual.jugadorSeMovio(destino)
      }
    }
  }

  method perderVida() {
    jugador.vidas(jugador.vidas() - 1)
    if (jugador.vidas() <= 0) {
      self.gameOver()          // te quedaste sin vidas: perdés el juego
    } else {
      self.irA(salaPrincipal)  // todavía tenés vidas: volvés al hall (menú)
    }
  }

  // Game Over: reinicia el juego completo (vidas, inventario, progreso).
  method gameOver() {
    self.reiniciarDatos()
    self.mostrarPantalla("img/Pantalla_Perdida.jpg", "perdiste")
  }

  // ----- Modo test (solo si config.debug) -----
  // Saltar directo a una sala sin tener que desbloquearla.
  method saltarA(sala) {
    if (config.debug) { self.irA(sala) }
  }

  // Marcar todos los minijuegos como completados y volver al hall.
  method completarTodo() {
    if (config.debug) {
      minijuegoToviggino.completado(true)
      minijuegoBeligoy.completado(true)
      minijuegoCaruso.completado(true)
      self.irA(salaPrincipal)
      game.say(jugador, "[TEST] Todo completado")
    }
  }
}

