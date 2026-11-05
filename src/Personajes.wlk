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

// Una prueba (carpeta de evidencia) sobre el escritorio.
class Prueba {
  var property position
  var property image = "img/Prueba.png"
}

// Aliado Caruso: está preso en su sala; al llegar a él (resolviendo el camino) te da una prueba.
object aliadoCaruso {
  var property position = game.at(10, 10)
  var property image = "img/Caruso.png"
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
