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

  method realizarAccionEnSala(){}

  method tieneInstrucciones() = false
}

class SalaMinijuego inherits Sala {
    const property minijuego
    method imagenInstrucciones()
    override method tieneInstrucciones() = true
    override method alEntrar() { minijuego.iniciar() }
    override method alSalir() { minijuego.terminar() }
    override method jugadorSeMovio(pos) { minijuego.jugadorSeMovio(pos) } 
}

// Hall de la AFA. La puerta habilitada depende de en qué paso del juego estás.
object salaPrincipal inherits Sala {
  override method fondo() = "img/FondoAFA.png"
  override method posicionInicial() = game.at(9, 2)   // abajo, sobre la alfombra

  // Progresión: Toviggino (x=7) -> Beligoy (x=12) -> Pelado (x=9). El Chiqui NO es
  // puerta del menú: se llega desde la pantalla de juicio final (tras ganar el Pelado).
  override method salidas() =
    if (not minijuegoToviggino.completado()) [ new Salida(x = 7, y = 8, destino = salaToviggino) ]
    else if (not minijuegoBeligoy.completado()) [ new Salida(x = 12, y = 8, destino = salaBeligoy) ]
    else if (not minijuegoPelado.completado()) [ new Salida(x = 9, y = 8, destino = salaPelado) ]
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
object salaToviggino inherits SalaMinijuego(minijuego = minijuegoToviggino) {
  override method fondo() = "img/SalaToviggino.png"
  override method imagenInstrucciones() = "img/InstruccionesToviggino.png"
  override method posicionInicial() = game.at(10, 2)
  override method salidas() = [ new Salida(x = 10, y = 1, destino = salaPrincipal) ]
}


// Minijuego 2 - Caruso preso. Está en la otra punta; para llegar hay que resolver
// el "camino oculto": solo ciertas baldosas son seguras (patrón escalera).
object salaCaruso inherits SalaMinijuego(minijuego = minijuegoCaruso) {
  override method fondo() = "img/SalaCaruso.png"
  override method imagenInstrucciones() = "img/InstruccionesCaruso.png"
  override method posicionInicial() = minijuegoCaruso.posInicial()
  override method salidas() = []   // se gana resolviendo el camino hasta Caruso
}


// Minijuego 3 - Beligoy. Beligoy salió un rato: revisá su archivo antes de que vuelva (30s).
object salaBeligoy inherits SalaMinijuego(minijuego = minijuegoBeligoy) {
  override method fondo() = "img/SalaBeligoy.png"
  override method imagenInstrucciones() = "img/InstruccionesBeligoy.png"
  override method posicionInicial() = game.at(10, 2)
  override method salidas() = []   // se gana encontrando los expedientes; se pierde si se acabó el tiempo
}


// Minijuego final - Chiqui Mafia (el juicio final).
object salaChiqui inherits SalaMinijuego(minijuego = minijuegoChiqui) {
  override method fondo() = "img/fondoJuicio.png"
  override method imagenInstrucciones() = "img/InstruccionesChiqui.png"
  override method posicionInicial() = game.at(10, 1)   // Abajo al centro
  override method salidas() = []
}


// Minijuego 4 - Pelado Bicampeon + Di Maria (persecucion en la cancha).
object salaPelado inherits SalaMinijuego(minijuego = minijuegoPelado) {
  override method fondo() = "img/CanchaFutbol.png"   // cancha abierta
  override method imagenInstrucciones() = "img/InstruccionesPelado.png"
  override method posicionInicial() = game.at(1, 1)
  override method salidas() = []   // se gana llegando a Di Maria
  // Cancha con barrera: bordes + la fila-barrera con hueco central.
  override method estaLibre(pos) = super(pos) and not minijuegoPelado.esBarrera(pos)
}

// ---------- Config / modo test ----------
object config {
  var property debug = true
}

// ---------- Estados ----------

class Estado {
    method permiteMover() = false
    method confirmar() { }
}

object estadoMenu inherits Estado {
  override method confirmar(){
    director.reiniciarDatos()
    director.iniciarMusica()   // arranca la musica de fondo apenas empezas a jugar
    director.irA(salaPatio)
  }
}

object estadoJugando inherits Estado {
  override method permiteMover() = true
}

object estadoCartel inherits Estado {
  override method confirmar(){ director.irA(salaPrincipal) }
}

object estadoPerdido inherits Estado{
  override method confirmar(){ director.mostrarMenu() } 
}

object estadoVictoria inherits Estado {
  override method confirmar(){ director.mostrarMenu()}
}

class EstadoInstrucciones inherits Estado{
    const sala
    override method confirmar(){ director.entrarA(sala)}
}

// ---------- Director: salas, transiciones y vidas ----------
object director {
  var property salaActual = null
  var estado = estadoMenu   // "menu" | "jugando" | "cartel"
  const indicadores = []
  var musica = null   // musica de fondo (loop) mientras se juega

  // Arranca la musica de fondo en loop. Se llama al empezar la partida (ENTER en el
  // menu, que ademas cuenta como gesto del usuario para que el navegador la deje sonar).
  method iniciarMusica() {
    if (musica == null) {
      musica = game.sound("sounds/fondoMusica.mp3")
      musica.shouldLoop(true)
      musica.volume(0.08)   // 0 = mudo, 1 = maximo. Bien bajo, solo de ambiente.
      musica.play()
    }
  }

  // Corta la musica de fondo (al ganar o perder el juego).
  method detenerMusica() {
    if (musica != null) {
      musica.stop()
      musica = null
    }
  }

  // Muestra una secuencia de imágenes tipo slide; al terminar ejecuta 'alTerminar'.
  method mostrarSlides(imagenes, alTerminar) {
    self.mostrarPantalla(imagenes.first(), new EstadoSlide(
      imagenes = imagenes,
      indiceActual = 0,
      alTerminar = alTerminar
    ))
  }


  method irA(sala){
    if (sala.tieneInstrucciones()) { self.mostrarInstrucciones(sala) }
    else { self.entrarA(sala) }
  }


  method entrarA(sala) {
    estado = estadoJugando
    if (salaActual != null) { salaActual.alSalir() }
    // OJO: no llamar limpiarTicks aca. iniciar() re-registra sus ticks en esta misma
    // llamada y el motor rompe si se hace removeTickEvent + onTick del mismo nombre en
    // el mismo frame (congela el minijuego). La limpieza se hace en mostrarPantalla
    // (pantalla de instrucciones previa a cada minijuego), que si limpia lo acumulado.
    // Limpieza segura: copio la lista antes de borrar (no itero la lista viva).
    game.allVisuals().map({ visual => visual }).forEach({ visual => game.removeVisual(visual) })
    indicadores.clear()
    salaActual = sala
    game.addVisual(new Imagen(position = game.at(0,0), image = sala.fondo()))
    sala.salidas().forEach({ unaSalida =>
      const flecha = new Imagen(position = game.at(unaSalida.x(), unaSalida.y()), image = "img/FlechaVerde.png")
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
        game.addVisual(new Imagen(position = game.at(i,0), image = "img/Prueba.png"))
      })
    }
    if (jugador.vidas() > 0) {
      (1 .. jugador.vidas()).forEach({ i =>
        game.addVisual(new Imagen(position = game.at(game.width() - i, 0), image = "img/Vida.png"))
      })
    }
  }

  // Cambia SOLO el fondo de la sala actual, sin reiniciar el minijuego.
  // Redibuja fondo nuevo + salidas + jugador + HUD en el orden de capas correcto.
  // Los sprites propios del minijuego (ej: toviggino) los re-agrega quien llama.
  method cambiarFondo(nuevoFondo) {
    game.allVisuals().map({ visual => visual }).forEach({ visual => game.removeVisual(visual) })
    indicadores.clear()
    game.addVisual(new Imagen(position = game.at(0,0), image = nuevoFondo))
    salaActual.salidas().forEach({ unaSalida =>
      const flecha = new Imagen(position = game.at(unaSalida.x(), unaSalida.y()), image = "img/FlechaVerde.png")
      indicadores.add(flecha)
      game.addVisual(flecha)
    })
    if (not game.hasVisual(jugador)) { game.addVisual(jugador) }
    self.dibujarHud()
  }

  method titilar() {
    indicadores.forEach({ indicador =>
      if (game.hasVisual(indicador)) game.removeVisual(indicador) else game.addVisual(indicador)
    })
  }

  // Quita todos los ticks de minijuegos (defensa contra acumulacion al reentrar/reiniciar).
  method limpiarTicks() {
    ["tovGira", "tovTimer", "caruPatron", "beliTimer", "pelaPersigue",
     "diMariaAnim", "peladoAnim", "chiquiMueve", "chiquiAnim"].forEach({ t => game.removeTickEvent(t) })
  }

  // Limpia la pantalla y deja un fondo de pantalla completa (menú / cartel).
  method mostrarPantalla(imagen, nuevoEstado) {
    if (salaActual != null) { salaActual.alSalir() }
    self.limpiarTicks()
    estado = nuevoEstado
    salaActual = null
    indicadores.clear()
    game.allVisuals().map({ visual => visual }).forEach({ visual => game.removeVisual(visual) })
    game.addVisual(new Imagen(position = game.at(0,0), image = imagen))
  }

  method mostrarMenu() { self.mostrarPantalla("img/FondoMenu.png", estadoMenu) }
  method mostrarCartel() { self.mostrarPantalla("img/FondoIntro.png", estadoCartel) }
  method mostrarInstrucciones(sala) { self.mostrarPantalla(sala.imagenInstrucciones(), new EstadoInstrucciones(sala = sala)) }
  
  // Reiniciar vidas y progreso
  method reiniciarDatos(){
    jugador.reiniciarVidas()
    jugador.reiniciarPruebas()
    minijuegoBeligoy.completado(false)
    minijuegoCaruso.completado(false)
    minijuegoToviggino.completado(false)
    minijuegoPelado.completado(false)
    minijuegoChiqui.completado(false)
    minijuegoToviggino.posicionesDePruebasGeneradas(false)
  }

  // Pantalla "Conseguiste todas las pruebas, es hora del juicio final".
  method mostrarJuicioFinal() {
    self.mostrarPantalla("img/PantallaJuicioFinal.png", estadoJuicioFinal)
  }

  // Se llama al derrotar al Chiqui para mostrar la pantalla de juego ganado
  method completarJuego() {
    self.detenerMusica()   // corto la musica de fondo antes del sonido de ganar
    self.mostrarPantalla("img/PantallaGanador.png", estadoVictoria)
    game.sound("sounds/sonidoGanar.mp3").play()   // sonido de ganar el juego
  }

  // ENTER: avanza según en qué pantalla estés.
  method confirmar() { estado.confirmar() }

  method moverJugador(movimiento) {
    if (estado.permiteMover() and salaActual != null) {
        jugador.moverse(movimiento, salaActual)
    }
}

  method decidirSegunVidasActuales() {
    if (jugador.seQuedoSinVidas()) {
      self.gameOver()          // te quedaste sin vidas: perdés el juego
    } else {
      self.irA(salaPrincipal)  // todavía tenés vidas: volvés al hall (menú)
    }
  }

  // Game Over: reinicia el juego completo (vidas, inventario, progreso).
  method gameOver() {
    self.detenerMusica()   // corto la musica de fondo antes de la trompeta de perder
    self.reiniciarDatos()
    self.mostrarPantalla("img/Pantalla_Perdida.jpg", estadoPerdido)
    game.sound("sounds/sonidoPerder.mp3").play()   // trompeta de perder el juego
  }

  // ----- Modo test (solo si config.debug) -----
  // Saltar directo a una sala sin tener que desbloquearla.
  method saltarA(sala) {
    if (config.debug) { self.entrarA(sala) }
  }

  // Marcar todos los minijuegos como completados y volver al hall.
  method completarTodo() {
    if (config.debug) {
      minijuegoToviggino.completado(true)
      minijuegoBeligoy.completado(true)
      minijuegoCaruso.completado(true)
      minijuegoPelado.completado(true)
      minijuegoChiqui.completado(true)
      self.irA(salaPrincipal)
      game.say(jugador, "[TEST] Todo completado")
    }
  }

  // Atajo de test: saltar directo a la cancha del Pelado desde el menu limpio.
  method irAlLaberinto() {
    if (config.debug) {
      self.reiniciarDatos()
      self.irA(salaPelado)   // via instrucciones (el entrarA directo daba error)
    }
  }
}

// Pantalla de juicio final: ENTER entra directo al Chiqui.
object estadoJuicioFinal inherits Estado {
  // irA (no entrarA) para que muestre las instrucciones del Chiqui antes de jugar.
  override method confirmar(){ director.irA(salaChiqui) }
}

class EstadoSlide inherits Estado {
  const imagenes
  const indiceActual
  const alTerminar

  override method confirmar() {
    const siguiente = indiceActual + 1
    if (siguiente < imagenes.size()) {
      director.mostrarPantalla(imagenes.get(siguiente), new EstadoSlide(
        imagenes = imagenes,
        indiceActual = siguiente,
        alTerminar = alTerminar
      ))
    } else {
      alTerminar.apply()
    }
  }
}