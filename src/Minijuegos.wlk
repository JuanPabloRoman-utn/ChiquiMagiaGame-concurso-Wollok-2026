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

        if (not self.hayPruebaEn(posicion)) {
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

  method iniciar() {
    completado = false
    pelado.reset()
    // El laberinto ya viene dibujado en el fondo (img/SalaPelado.png).
    if (not game.hasVisual(diMaria)) { game.addVisual(diMaria) }
    if (not game.hasVisual(pelado)) { game.addVisual(pelado) }
    game.say(jugador, "Gambetea al Pelado y llega a Di Maria!")
    game.onTick(400, "pelaPersigue", { self.moverPelado() })
  }

  method terminar() {
    game.removeTickEvent("pelaPersigue")
    if (game.hasVisual(pelado)) { game.removeVisual(pelado) }
    if (game.hasVisual(diMaria)) { game.removeVisual(diMaria) }
  }

  // El Pelado se mueve una casilla hacia el jugador por los pasillos libres.
  method moverPelado() {
    // Solo actua si seguis en el laberinto (evita ticks residuales al salir).
    if (director.salaActual() == salaPelado) {
      const objetivo = jugador.position()
      const candidatos = [ pelado.position().up(1), pelado.position().down(1),
                           pelado.position().left(1), pelado.position().right(1) ]
        .filter({ p => salaPelado.estaLibre(p) })
      if (not candidatos.isEmpty()) {
        const mejor = candidatos.min({ p =>
          (p.x() - objetivo.x()).abs() + (p.y() - objetivo.y()).abs() })
        pelado.position(mejor)
        self.chequearChoque()
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
    director.perderVida()
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

// ---------- Minijuego 5 (final): El Chiqui Mafia ----------
object minijuegoChiqui {
  var property completado = false
  var choripanes = []
  var denuncias = []

  method iniciar() {
    completado = false
    choripanes = []
    denuncias = []
    chiqui.reset()

    if (not game.hasVisual(chiqui)) { game.addVisual(chiqui) }

    game.say(jugador, "Llego la hora! Disparale 5 denuncias con ESPACIO!")

    // Ticks para proyectiles y movimiento del Chiqui
    game.onTick(800, "generarChori", { self.generarChoripan() })
    game.onTick(200, "moverProyectiles", { self.actualizarProyectiles() })
    game.onTick(700, "moverChiqui", { self.moverChiqui() }) // <-- Chiqui más lento (cada 700ms)
  }

  method terminar() {
    game.removeTickEvent("generarChori")
    game.removeTickEvent("moverProyectiles")
    game.removeTickEvent("moverChiqui") // <-- Limpiamos el tick
    
    choripanes.forEach({ c => if (game.hasVisual(c)) game.removeVisual(c) })
    denuncias.forEach({ d => if (game.hasVisual(d)) game.removeVisual(d) })
    if (game.hasVisual(chiqui)) game.removeVisual(chiqui)
    
    choripanes = []
    denuncias = []
  }

  method moverChiqui() {
    // Se mueve de forma independiente y más pausada
    const nuevaX = (1 .. (game.width() - 2)).anyOne()
    chiqui.position(game.at(nuevaX, 10))
  }

  method generarChoripan() {
    const xAleatoria = (1 .. (game.width() - 2)).anyOne()
    const chori = new Choripan(position = game.at(xAleatoria, 9))
    choripanes.add(chori)
    game.addVisual(chori)
  }

  method dispararDenuncia() {
    const posDisparo = jugador.position().up(1)
    const denuncia = new Denuncia(position = posDisparo)
    denuncias.add(denuncia)
    game.addVisual(denuncia)
  }

  method actualizarProyectiles() {
    // 1. Mover Choripanes abajo y chequear colisión con jugador
    choripanes.map({ c => c }).forEach({ c =>
      c.moverAbajo()
      if (c.position().x() == jugador.position().x() and c.position().y() == jugador.position().y()) {
        self.removerChoripan(c)
        director.perderVida()
      } else if (c.position().y() <= 0) {
        self.removerChoripan(c)
      }
    })

    // 2. Mover Denuncias arriba y chequear colisión con Chiqui
    denuncias.map({ d => d }).forEach({ d =>
      d.moverArriba()
      if (d.position().x() == chiqui.position().x() and d.position().y() >= chiqui.position().y()) {
        self.removerDenuncia(d)
        chiqui.recibirDenuncia()
        game.say(chiqui, "Auch! Vidas: " + chiqui.vidas().toString())
        if (chiqui.estaDerrotado()) {
          self.ganar()
        }
      } else if (d.position().y() >= game.height() - 1) {
        self.removerDenuncia(d)
      }
    })
  }

  method removerChoripan(chori) {
    if (game.hasVisual(chori)) game.removeVisual(chori)
    choripanes.remove(chori)
  }

  method removerDenuncia(denuncia) {
    if (game.hasVisual(denuncia)) game.removeVisual(denuncia)
    denuncias.remove(denuncia)
  }

  method jugadorSeMovio(pos) {
    const choriTocado = choripanes.findOrDefault({ c => c.position().x() == pos.x() and c.position().y() == pos.y() }, null)
    if (choriTocado != null) {
      self.removerChoripan(choriTocado)
      director.perderVida()
    }
  }

  method ganar() {
    // El Chiqui es el juicio final (atraparlo con todas las pruebas), no suma prueba.
    completado = true
    game.say(jugador, "Derrotaste al Chiqui Mafia! Salvaste al futbol!")
    director.completarJuego()
  }
}