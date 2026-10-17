



class Denuncia {
  var property position
  var property image = "assets/img/Denuncia.png"

  method volar() {
    // Se desplaza hacia arriba en el eje Y
    position = position.up(1)

    // Si sale por la parte superior del mapa, desaparece
    if (position.y() < 0) {
      self.desaparecer()
    }
  }

  method desaparecer() {
    game.removeTickEvent("moverDenuncia_" + self.identity())
    if (game.hasVisual(self)) {
      game.removeVisual(self)
    }
  }
}

object detective {
  var property position = game.at(15, 3)
  var property image = "assets/img/Detective.png"
  var property vidas = 3
  var property danio = 1

  // Movimiento con límites de pantalla
  method moverA(nuevaPosicion) {
    if (nuevaPosicion.x().between(0, game.width() - 1) and 
        nuevaPosicion.y().between(0, game.height() - 1)) {
      position = nuevaPosicion
    }
  }

  method recibirDanio() {
    vidas = vidas - 1
    game.say(self, "¡Ouch! Me quedan " + vidas.toString() + " vidas")
    
    if (vidas <= 0) {
      game.say(self, "¡Game Over!")
      game.stop()
    }
  }

  method revolear() {
    // Nace justo debajo del detective en su coordenada X actual
    const denuncia = new Denuncia(position = position.up(1))
  }

}

class Chori {
  var property position
  var property image = "assets/img/Chori.png"

  method volar() {
    // Se desplaza hacia abajo en el eje Y
    position = position.down(1)

    // Si sale por la parte inferior del mapa, desaparece
    if (position.y() < 0) {
      self.desaparecer()
    }
  }

  method desaparecer() {
    game.removeTickEvent("moverChori_" + self.identity())
    if (game.hasVisual(self)) {
      game.removeVisual(self)
    }
  }
}


object chiqui {
  var property position = game.at(15, 15) // Nace arriba del todo
  var property image = "assets/img/Chiqui.png"
  var direccionX = 1 // 1 para ir a la derecha, -1 para ir a la izquierda
  var property vida = 10

  method mover() {
    // Si llega al borde derecho o izquierdo, invierte el sentido
    if (position.x() >= game.width() - 1) {
      direccionX = -1
    } else if (position.x() <= 0) {
      direccionX = 1
    }

    position = position.right(direccionX)
  }

  method recibirDanio() {
    vida = vida - 1
    
    if (vida <= 0) {
      game.say(self, "Cayó preso gordito")
      game.stop()
    }
  }

  method revolear() {
    // Nace justo debajo del Chiqui en su coordenada X actual
    const chori = new Chori(position = position.down(1))

    game.addVisual(chori)

    // El chori avanza hacia abajo cada 100 ms
    game.onTick(100, "moverChori_" + chori.identity(), {
      chori.volar()
    })
  }
}

// el polimorfismo lo aplicamos con el metodo revolear, donde los dos personajes actuan de manera distinta con la clase que lanzan,
// y dependiendo de cual sea esta actuan de manera distinta