import wollok.game.*
import Personajes.*
import Salas.*


// ---------- Minijuego 1: Toviggino ----------
object minijuegoToviggino {
  const pruebasTotales = 3
  var pruebasAgarradas = 0
  var property posicionesDePruebasGeneradas = false
  var pruebas = []
  var escapando = false
  var segundos = 0
  var property completado = false

  method posicionAleatoria() {
    const x = (1..(game.width() - 2)).anyOne()
    const y = (1..(game.height() - 2)).anyOne()

    return game.at(x, y)
  }

  method hayPruebaEn(posicion) {
    return pruebas.any({ prueba => 
        prueba.position().x() == posicion.x() and
        prueba.position().y() == posicion.y()})
  }

  method generarPruebas() {
    if (pruebas.size() < pruebasTotales) {
        const posicion = self.posicionAleatoria()

        if (not self.hayPruebaEn(posicion)
            and not salaToviggino.haySalida(posicion)
            and posicion != salaToviggino.posicionInicial()
            and posicion != toviggino.position()) {
            pruebas = pruebas + [new Imagen(position = posicion, image = "img/Prueba.png")]
        }

        self.generarPruebas()
    } else { return pruebas }
  }

  method iniciar() {
    pruebasAgarradas = 0
    escapando = false
    segundos = 0
    toviggino.reset()
    if (not game.hasVisual(toviggino)) { game.addVisual(toviggino) }

    if (not posicionesDePruebasGeneradas){
        pruebas = []
        self.generarPruebas()
        posicionesDePruebasGeneradas = true
    }
    
    pruebas.forEach({ prueba => game.addVisual(prueba) })
    game.onTick(170, "tovGira", { toviggino.pensar() })
  }

  method terminar() {
    game.removeTickEvent("tovGira")
    game.removeTickEvent("tovTimer")
    pruebas.forEach({ prueba => if (game.hasVisual(prueba)) game.removeVisual(prueba) })
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

// ---------- Minijuego 2: Caruso preso (camino oculto) ----------
// Caruso está preso en la otra punta. Solo ciertas baldosas son seguras (patrón
// escalera: arriba, derecha, arriba, derecha...). Si pisás fuera, volvés al inicio.
// Caruso está preso en la otra punta. Se muestra el patrón (camino seguro) unos
// segundos, después se oculta y hay que seguirlo de memoria. Si pisás fuera,
// volvés al inicio y te lo muestra de nuevo.
object minijuegoCaruso {
  const posInicial = game.at(1, 1)
  const celda = game.at(10, 10)   // donde está Caruso preso
  const caruso = new Imagen(position = celda, image = "img/Caruso.png")
  var camino = []
  var marcas = []
  var mostrando = false
  var property completado = false

  method posInicial() = posInicial

  method iniciar() {
    completado = false
    self.construirCamino()
    if (not game.hasVisual(caruso)) { game.addVisual(caruso) }
    self.mostrarPatron(3000, "Memoriza el camino hasta Caruso!")
  }

  // Patrón escalera desde (1,1): arriba, derecha, arriba, derecha... hasta (10,10).
  
  method generarSiguienteCamino(actual) {
    if (actual != celda) {
      const siguientes = []

      if (actual.x() < celda.x()){
        siguientes.add(game.at(actual.x() + 1, actual.y()))
      }

      if (actual.y() < celda.y()){
        siguientes.add(game.at(actual.x(), actual.y() + 1))
      }

      const siguiente = siguientes.anyOne()
      camino.add(siguiente)
      self.generarSiguienteCamino(siguiente)
    }
  }

  method construirCamino() {
    camino = [ posInicial ]
    self.generarSiguienteCamino(posInicial)
  }

  method mostrarPatron(ms, mensaje) {
    if (not mostrando) {
      mostrando = true
      marcas = camino.map({ p => new Imagen(position = p, image = "img/Marca.png") })
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

// ---------- Minijuego 3: Beligoy (expedientes de Barracas Central) ----------
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

// ---------- Minijuego 4: Pelado Bicampeon + Di Maria (persecucion en la cancha) ----------
// Di Maria esta arreglado con el Chiqui y tiene la ultima prueba. El Pelado
// Bicampeon lo defiende persiguiendote por toda la cancha. Esquivalo y llega
// hasta Di Maria para arrebatarle la prueba.
object minijuegoPelado {
  var property completado = false
  var barrera = []
  var sonido = null
  var sonidoCerca = null
  var cercaActivo = false

  // Pozos trampa esparcidos (patron damero, validado: siempre hay camino a Di Maria).
  const pozos = [game.at(1,5), game.at(1,9), game.at(2,6), game.at(3,9), game.at(4,2), game.at(5,3), game.at(6,8), game.at(7,5), game.at(7,7), game.at(10,4), game.at(11,1), game.at(11,3), game.at(12,2), game.at(13,5), game.at(13,7), game.at(15,1), game.at(15,5), game.at(16,4), game.at(17,5), game.at(18,4)]

  method iniciar() {
    completado = false
    pelado.reset()
    self.dibujarBarrera()
    if (not game.hasVisual(diMaria)) { game.addVisual(diMaria) }
    if (not game.hasVisual(pelado)) { game.addVisual(pelado) }
    game.say(jugador, "Gambetea al Pelado y llega a Di Maria!")
    // Audio del Pelado gritando "BICAMPEONES" en loop (placeholder: bicampeones.mp3).
    sonido = game.sound("bicampeones.mp3")
    sonido.shouldLoop(true)
    sonido.play()
    // Audio de tension que suena solo cuando el Pelado esta cerca (placeholder).
    sonidoCerca = game.sound("pelado_cerca.mp3")
    sonidoCerca.shouldLoop(true)
    cercaActivo = false
    game.onTick(417, "pelaPersigue", { self.moverPelado() })   // +20% de velocidad
    game.onTick(350, "diMariaAnim", { diMaria.animar() })      // anima a Di Maria
    game.onTick(300, "peladoAnim", { pelado.animar() })        // anima al Pelado
  }

  method dist(a, b) = (a.x() - b.x()).abs() + (a.y() - b.y()).abs()

  // Hay pozo trampa en esta celda? (si lo pisas no podes avanzar).
  method esBarrera(pos) = pozos.any({ p => p.x() == pos.x() and p.y() == pos.y() })

  method dibujarBarrera() {
    barrera = []
    pozos.forEach({ p =>
      const pozo = new Imagen(position = p, image = "img/pozotrampa.png")
      barrera.add(pozo)
      game.addVisual(pozo)
    })
  }

  method terminar() {
    game.removeTickEvent("pelaPersigue")
    game.removeTickEvent("diMariaAnim")
    game.removeTickEvent("peladoAnim")
    if (sonido != null) { sonido.stop() }
    if (sonidoCerca != null and cercaActivo) { sonidoCerca.stop() }   // solo si estaba sonando
    cercaActivo = false
    barrera.forEach({ m => if (game.hasVisual(m)) game.removeVisual(m) })
    barrera = []
    if (game.hasVisual(pelado)) { game.removeVisual(pelado) }
    if (game.hasVisual(diMaria)) { game.removeVisual(diMaria) }
  }

  // El Pelado se mueve siguiendo el camino mas corto (BFS) hacia el jugador,
  // rodeando los pozos. Asi nunca se queda trabado.
  method moverPelado() {
    // Solo actua si seguis en la cancha (evita ticks residuales al salir).
    if (director.salaActual() == salaPelado) {
      pelado.position(self.proximoPaso())   // si no hay camino, devuelve la misma celda
      self.chequearCercania()
      self.chequearChoque()
    }
  }

  method mismaCelda(a, b) = a.x() == b.x() and a.y() == b.y()

  method vecinos(p) = [ p.up(1), p.down(1), p.left(1), p.right(1) ]

  // Una celda es transitable para el Pelado si no es borde/pozo ni la de Di Maria.
  method libreParaPelado(p) = salaPelado.estaLibre(p)
    and not self.mismaCelda(p, diMaria.position())

  // Primer paso del camino mas corto del Pelado hacia el jugador (BFS).
  method proximoPaso() {
    const meta = jugador.position()
    const inicio = pelado.position()
    const visitados = [inicio]
    const frontera = []
    self.vecinos(inicio).forEach({ v =>
      if (self.libreParaPelado(v) and not visitados.any({ q => self.mismaCelda(q, v) })) {
        visitados.add(v)
        frontera.add([v, v])   // [celda, primer paso que lleva a ella]
      }
    })
    return self.bfs(frontera, visitados, meta, inicio)
  }

  // Devuelve el primer paso del camino mas corto a 'meta', o 'inicio' si no hay.
  method bfs(frontera, visitados, meta, inicio) {
    if (frontera.isEmpty()) {
      return inicio   // sin camino: el Pelado se queda donde esta
    } else {
      if (frontera.any({ par => self.mismaCelda(par.get(0), meta) })) {
        return frontera.find({ par => self.mismaCelda(par.get(0), meta) }).get(1)
      } else {
        const siguiente = []
        frontera.forEach({ par =>
          self.vecinos(par.get(0)).forEach({ v =>
            if (self.libreParaPelado(v) and not visitados.any({ q => self.mismaCelda(q, v) })) {
              visitados.add(v)
              siguiente.add([v, par.get(1)])
            }
          })
        })
        return self.bfs(siguiente, visitados, meta, inicio)
      }
    }
  }

  // Prende/apaga el audio de cercania segun la distancia al Pelado (<= 3 casillas).
  method chequearCercania() {
    if (sonidoCerca != null) {
      const cerca = self.dist(pelado.position(), jugador.position()) <= 3
      if (cerca and not cercaActivo) {
        cercaActivo = true
        sonidoCerca.play()
      } else if (not cerca and cercaActivo) {
        cercaActivo = false
        sonidoCerca.stop()
      }
    }
  }

  method chequearChoque() {
    if (pelado.position().x() == jugador.position().x() and
        pelado.position().y() == jugador.position().y()) {
      self.atrapado()
    }
  }

  method atrapado() {
    game.say(jugador, "Te agarro el Pelado!")
    jugador.vidas(jugador.vidas() - 1)
    if (jugador.vidas() <= 0) {
      director.gameOver()          // sin vidas: perdiste el juego
    } else {
      director.entrarA(salaPelado) // todavia tenes vidas: reintentas el Pelado
    }
  }

  method jugadorSeMovio(pos) {
    if (pos.x() == diMaria.position().x() and pos.y() == diMaria.position().y()) {
      self.ganar()
    } else if (pos.x() == pelado.position().x() and pos.y() == pelado.position().y()) {
      self.atrapado()
    }
  }

  method ganar() {
    if (not completado) {
      completado = true
      jugador.pruebas(jugador.pruebas() + 1)
      game.say(jugador, "Agarraste la prueba del arreglo Di Maria-Chiqui!")
      director.mostrarJuicioFinal()
    }
  }
}

// ---------- Minijuego 5 (final): El Chiqui Mafia ---------

object minijuegoChiqui {
  const pruebasParaGanar = 5
  const pruebasParaPerder = 2
  var pruebasJugador = 0
  var pruebasChiqui = 0
  var pruebaActual = null
  var property completado = false

  method iniciar() {
    completado = false
    pruebasJugador = 0
    pruebasChiqui = 0
    chiqui.reset()
    if (not game.hasVisual(chiqui)) { game.addVisual(chiqui) }
    game.say(jugador, "Agarra 5 pruebas antes de que el Chiqui destruya 2!")
    self.generarNuevaPrueba()
    game.onTick(380, "chiquiMueve", { self.turnoChiqui() })
  }

  method terminar() {
    game.removeTickEvent("chiquiMueve")
    if (pruebaActual != null and game.hasVisual(pruebaActual)) {
      game.removeVisual(pruebaActual)
    }
    pruebaActual = null
    if (game.hasVisual(chiqui)) { game.removeVisual(chiqui) }
  }

  method mismaCelda(a, b) = a.x() == b.x() and a.y() == b.y()

  // Busca una celda libre que no esté ocupada ni por el jugador ni por el Chiqui.
  method posicionAleatoriaLibre() {
    const x = (1 .. (game.width() - 2)).anyOne()
    const y = (1 .. (game.height() - 2)).anyOne()
    const pos = game.at(x, y)
    if (not self.mismaCelda(pos, jugador.position()) and not self.mismaCelda(pos, chiqui.position())) {
      return pos
    } else {
      return self.posicionAleatoriaLibre()
    }
  }

  method generarNuevaPrueba() {
    if (pruebaActual != null and game.hasVisual(pruebaActual)) {
      game.removeVisual(pruebaActual)
    }
    const pos = self.posicionAleatoriaLibre()
    pruebaActual = new Imagen(position = pos, image = "img/Prueba.png")
    game.addVisual(pruebaActual)
  }

  // El Chiqui avanza un paso hacia la prueba actual y revisa si la agarró.
  method turnoChiqui() {
    if (director.salaActual() == salaChiqui and pruebaActual != null) {
      chiqui.acercarseA(pruebaActual.position())
      if (self.mismaCelda(chiqui.position(), pruebaActual.position())) {
        self.chiquiAgarroPrueba()
      }
    }
  }

  // Cada vez que se mueve el jugador, revisamos si agarró la prueba.
  method jugadorSeMovio(pos) {
    if (pruebaActual != null and self.mismaCelda(pos, pruebaActual.position())) {
      self.jugadorAgarroPrueba()
    }
  }

  method jugadorAgarroPrueba() {
    pruebasJugador = pruebasJugador + 1
    if (pruebasJugador >= pruebasParaGanar) {
      self.ganar()
    } else {
      game.say(jugador, "Prueba " + pruebasJugador.toString() + "/" + pruebasParaGanar.toString() + "!")
      self.generarNuevaPrueba()
    }
  }

  method chiquiAgarroPrueba() {
    pruebasChiqui = pruebasChiqui + 1
    if (pruebasChiqui >= pruebasParaPerder) {
      game.say(chiqui, "Destrui las pruebas! Ganamos los mismos de siempre!")
      director.gameOver()
    } else {
      game.say(chiqui, "Destrui " + pruebasChiqui.toString() + "/" + pruebasParaPerder.toString() + " pruebas!")
      self.generarNuevaPrueba()
    }
  }

  method ganar() {
    if (not completado) {
      completado = true
      game.say(jugador, "Derrotaste al Chiqui Mafia! Salvaste al futbol!")
      director.completarJuego()
    }
  }
}