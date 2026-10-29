import wollok.game.*
import Personajes.*

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

// Marca verde que muestra una casilla del patrón (minijuego de Caruso).
class MarcaPatron {
  const property position
  const property image = "img/Marca.png"
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

// Minijuego 3 - Caruso preso. Está en la otra punta; para llegar hay que resolver
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

// ---------- Minijuego 1: Toviggino ----------
object minijuegoToviggino {
  const pruebasTotales = 3
  var pruebasAgarradas = 0
  var pruebas = []
  var escapando = false
  var segundos = 0
  var property completado = false

  method iniciar() {
    pruebasAgarradas = 0
    escapando = false
    segundos = 0
    toviggino.reset()
    if (not game.hasVisual(toviggino)) { game.addVisual(toviggino) }
    pruebas = [ new Prueba(position = game.at(7, 9)),
                new Prueba(position = game.at(10, 9)),
                new Prueba(position = game.at(13, 9)) ]
    pruebas.forEach({ prueba => game.addVisual(prueba) })
    game.onTick(170, "tovGira", { toviggino.pensar() })
  }

  method terminar() {
    game.removeTickEvent("tovGira")
    game.removeTickEvent("tovTimer")
    pruebas.forEach({ prueba => if (game.hasVisual(prueba)) game.removeVisual(prueba) })
    pruebas = []
  }

  method jugadorSeMovio(pos) {
    if (toviggino.estaMirando()) {
      director.perderVida()          // te vio moverte
    } else {
      self.chequearPruebas(pos)
      self.chequearSalida(pos)
    }
  }

  method chequearPruebas(pos) {
    pruebas.forEach({ prueba =>
      if (game.hasVisual(prueba) and prueba.position().x() == pos.x() and prueba.position().y() == pos.y()) {
        game.removeVisual(prueba)
        pruebasAgarradas = pruebasAgarradas + 1
      }
    })
    if (pruebasAgarradas >= pruebasTotales and not escapando) {
      self.empezarEscape()
    }
  }

  method chequearSalida(pos) {
    if (salaToviggino.haySalida(pos)) {
      if (pruebasAgarradas >= pruebasTotales) {
        // Minijuego completado: suma 1 prueba y vas DIRECTO a la cárcel de Caruso.
        completado = true
        jugador.pruebas(jugador.pruebas() + 1)
        game.say(jugador, "Prueba conseguida! Vamos con Caruso")
        director.irA(salaCaruso)
      } else {
        director.irA(salaPrincipal)
      }
    }
  }

  method empezarEscape() {
    escapando = true
    segundos = 12
    game.say(jugador, segundos.toString() + "s para salir!")
    game.onTick(1000, "tovTimer", { self.tick() })
  }

  method tick() {
    segundos = segundos - 1
    if (segundos <= 0) {
      director.perderVida()          // se acabó el tiempo
    } else {
      game.say(jugador, segundos.toString() + "s")
    }
  }
}

// ---------- Minijuego 2: Beligoy (expedientes de Barracas Central) ----------
// Beligoy esconde los expedientes de los partidos arreglados para Barracas.
// Una pista te dice en qué fila están los arreglos; abrir un archivero "limpio"
// (partido legítimo) te hace perder tiempo. Juntá 3 arreglos antes de que vuelva.
object minijuegoBeligoy {
  const totalArreglos = 3
  var encontrados = 0
  var archiveros = []
  var segundos = 0
  var property completado = false

  const resultadosArreglo = ["Barracas 3-0 (3 penales)", "Barracas 2-1 (offside tapado)",
                             "Barracas 4-0 (rival con 8)", "Barracas gana de local y de visitante"]
  const resultadosLimpios = ["River 2-1 Boca", "Racing 1-0 Independiente", "San Lorenzo 0-0 Huracan"]

  method iniciar() {
    encontrados = 0
    segundos = 30
    const pistaArriba = [true, false].anyOne()
    const yArreglo = if (pistaArriba) 8 else 3
    const yLimpio = if (pistaArriba) 3 else 8
    archiveros = []
    [5, 10, 15].forEach({ x =>
      const arreglo = new Archivero(position = game.at(x, yArreglo))
      arreglo.ponerExpediente()       // este sí es un arreglo de Barracas
      archiveros.add(arreglo)
      archiveros.add(new Archivero(position = game.at(x, yLimpio)))   // partido limpio (trampa)
    })
    archiveros.forEach({ archivero => game.addVisual(archivero) })
    const donde = if (pistaArriba) "ARRIBA" else "ABAJO"
    game.say(jugador, "Los arreglos de Barracas estan " + donde + "! 30s")
    game.onTick(1000, "beliTimer", { self.tick() })
  }

  method terminar() {
    game.removeTickEvent("beliTimer")
    archiveros.forEach({ archivero => if (game.hasVisual(archivero)) game.removeVisual(archivero) })
    archiveros = []
  }

  method tick() {
    segundos = segundos - 1
    if (segundos <= 0) {
      director.perderVida()          // volvió Beligoy: se acabó el tiempo
    } else {
      game.say(jugador, segundos.toString() + "s")
    }
  }

  method jugadorSeMovio(pos) {
    archiveros.forEach({ archivero =>
      if (not archivero.revisado() and archivero.position().x() == pos.x() and archivero.position().y() == pos.y()) {
        archivero.revisar()
        if (archivero.tieneExpediente()) {
          encontrados = encontrados + 1
          game.say(jugador, resultadosArreglo.anyOne())
        } else {
          segundos = segundos - 5
          if (segundos < 1) { segundos = 1 }
          game.say(jugador, "Limpio: " + resultadosLimpios.anyOne() + " (-5s)")
        }
      }
    })
    if (encontrados >= totalArreglos and not completado) {
      completado = true
      jugador.pruebas(jugador.pruebas() + 1)
      game.say(jugador, "Conseguiste los expedientes de Barracas!")
      director.irA(salaPrincipal)
    }
  }
}

// ---------- Minijuego 3: Caruso preso (camino oculto) ----------
// Caruso está preso en la otra punta. Solo ciertas baldosas son seguras (patrón
// escalera: arriba, derecha, arriba, derecha...). Si pisás fuera, volvés al inicio.
// Caruso está preso en la otra punta. Se muestra el patrón (camino seguro) unos
// segundos, después se oculta y hay que seguirlo de memoria. Si pisás fuera,
// volvés al inicio y te lo muestra de nuevo.
object minijuegoCaruso {
  const posInicial = game.at(1, 1)
  const celda = game.at(10, 10)   // donde está Caruso preso
  var camino = []
  var marcas = []
  var mostrando = false
  var property completado = false

  method posInicial() = posInicial

  method iniciar() {
    completado = false
    self.construirCamino()
    aliadoCaruso.position(celda)
    if (not game.hasVisual(aliadoCaruso)) { game.addVisual(aliadoCaruso) }
    self.mostrarPatron(3000, "Memoriza el camino hasta Caruso!")
  }

  // Patrón escalera desde (1,1): arriba, derecha, arriba, derecha... hasta (10,10).
  method construirCamino() {
    camino = [ posInicial ]
    var x = 1
    var y = 1
    (1 .. 9).forEach({ i =>
      y = y + 1
      camino.add(game.at(x, y))
      x = x + 1
      camino.add(game.at(x, y))
    })
  }

  method mostrarPatron(ms, mensaje) {
    if (not mostrando) {
      mostrando = true
      marcas = camino.map({ p => new MarcaPatron(position = p) })
      marcas.forEach({ m => game.addVisual(m) })
      game.say(jugador, mensaje)
      game.onTick(ms, "caruPatron", { self.ocultarPatron() })
    }
  }

  method ocultarPatron() {
    game.removeTickEvent("caruPatron")
    marcas.forEach({ m => if (game.hasVisual(m)) game.removeVisual(m) })
    marcas = []
    mostrando = false
    game.say(jugador, "Ahora segui el patron!")
  }

  method terminar() {
    game.removeTickEvent("caruPatron")
    marcas.forEach({ m => if (game.hasVisual(m)) game.removeVisual(m) })
    marcas = []
    mostrando = false
  }

  method esCamino(pos) = camino.any({ p => p.x() == pos.x() and p.y() == pos.y() })

  method jugadorSeMovio(pos) {
    if (pos.x() == celda.x() and pos.y() == celda.y()) {
      self.liberar()
    } else if (not self.esCamino(pos)) {
      jugador.position(posInicial)
      self.mostrarPatron(2000, "Te equivocaste! Mira de nuevo")
    }
  }

  method liberar() {
    if (not completado) {
      completado = true
      jugador.pruebas(jugador.pruebas() + 1)
      game.say(jugador, "Liberaste a Caruso! Te dio una prueba")
    }
    director.irA(salaPrincipal)
  }
}
