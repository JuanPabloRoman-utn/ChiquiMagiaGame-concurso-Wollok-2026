import wollok.game.*

// El detective (jugador), Lucho. Es pasivo: el director maneja su movimiento.
object jugador {
  var property position = game.at(10, 6)
  var property image = "img/LuchoFrente.png"
  var property vidas = 2
  var property pruebas = 0   // inventario: pruebas conseguidas (minijuegos completados)

  // Cambia el sprite según la dirección: de espaldas cuando sube, de frente si no.
  method mirar(haciaArriba) {
    if (haciaArriba) { image = "img/LuchoEspaldas.png" }
    else { image = "img/LuchoFrente.png" }
  }
}

// Toviggino: está de espaldas y se da vuelta cada tanto (rápido, casi sin aviso).
object toviggino {
  var property position = game.at(10, 10)
  var property image = "img/TovigginoEspaldas.png"
  var mirando = false
  var ticks = 8

  method estaMirando() = mirando

  method reset() {
    mirando = false
    image = "img/TovigginoEspaldas.png"
    ticks = (6 .. 12).anyOne()
  }

  // Se llama por tick: cuenta y, cuando llega a 0, se da vuelta.
  method pensar() {
    ticks = ticks - 1
    if (ticks <= 0) {
      self.girar()
    }
  }

  method girar() {
    mirando = not mirando
    if (mirando) {
      image = "img/TovigginoFrente.png"
      ticks = (3 .. 6).anyOne()      // mirando: poco tiempo
    } else {
      image = "img/TovigginoEspaldas.png"
      ticks = (6 .. 13).anyOne()     // de espaldas: un poco más
    }
  }
}

class Imagen {
  const property position
  const property image
}

// ---------- Minijuego 4 (previo al Chiqui): Pelado Bicampeon y Di Maria ----------
// Di Maria esta arreglado con el Chiqui: tiene la ultima prueba y esta fijo,
// custodiando el expediente. El Pelado Bicampeon lo defiende persiguiendote por
// el laberinto como un fantasma de Pac-Man.
object diMaria {
  var property position = game.at(10, 10)   // fijo, arriba-centro de la cancha
  var property image = "img/DiMariaUno.png"
  var enUno = true

  // Alterna entre los dos sprites para simular movimiento.
  method animar() {
    enUno = not enUno
    if (enUno) { image = "img/DiMariaUno.png" } else { image = "img/DiMariaDOS.png" }
  }
}

object pelado {
  var property position = game.at(10, 8)
  var property image = "img/peladoUNO.png"
  var enUno = true

  method reset() {
   position = game.at(10, 8)
    }   // arranca arriba, defendiendo a Di Maria

  // Alterna entre los dos sprites para simular movimiento.
  method animar() {
    enUno = not enUno
    if (enUno) { 
    image = "img/peladoUNO.png" 
    } else {
     image = "img/peladoDOS.png" 
     }
  }
}

// Archivero (cajón): se revisa al pararte encima. Adentro puede haber un expediente.
class Archivero {
  const property position
  var property image = "img/Archivero.png"
  var guardaExpediente = false
  var property revisado = false

  method ponerExpediente() { guardaExpediente = true }
  method tieneExpediente() = guardaExpediente

  method revisar() {
    revisado = true
    if (guardaExpediente) {
      image = "img/ArchiveroExpediente.png"
    } else {
      image = "img/ArchiveroVacio.png"
    }
  }
}

// ---------- Minijuego 4: Chiqui Mafia y Proyectiles ----------

object chiqui {
  var property position = game.at(9, 10)
  var property image = "img/Chiqui.png"
  var property vidas = 5

  method reset() {
    vidas = 5
    position = game.at(9, 10)
  }

  method recibirDenuncia() {
    vidas = vidas - 1
  }

  method estaDerrotado() = vidas <= 0
}

class Choripan {
  var property position
  const property image = "img/Chori.png"

  method moverAbajo() {
    position = position.down(1)
  }
}

class Denuncia {
  var property position
  const property image = "img/Denuncia.png"

  method moverArriba() {
    position = position.up(1)
  }
}
