module QuestModule

  # En realidad, no es necesario agregar ninguna información, pero los campos respectivos en la interfaz de usuario estarán en blanco o "???"
  # Se incluye esto aquí principalmente como un ejemplo de lo que no se debe hacer, pero también para mostrar que es algo que existe.
  Quest0 = {

  }

  # Este es el ejemplo más simple de una misión de una sola etapa con todo lo especificado
  Quest1 = {
    :ID => "1",
    :Name => "Necesito Hielo",
    :QuestGiver => "Heladero de Costa Berdán",
    :Stage1 => "Busca hielo en el Comedor de la Academia Eón.",
    :Location1 => "Academia Eón",
    :QuestDescription => "Seguramente hay hielo en el Comedor de la Academia Eón.",
    :RewardString => "Piedra Hielo",
    :QuestGiverOW => "Graphics/Characters/BW_Heladero"
  }

  Quest2 = {
    :ID => "2",
    :Name => "Entrega mi Ramo",
    :QuestGiver => "Ianto en su casa de Pueblo Berdán",
    :Stage1 => "Entrega este ramo en la tumba de mi difunta esposa en Jardín Freya.",
    :Location1 => "Jardín Freya",
    :QuestDescription => "Deja el Ramo en la tumba al final del Jardín Freya.",
    :RewardString => "Campana Alivio",
    :QuestGiverOW => "Graphics/Characters/BW_Abuelo"
  }

  Quest3 = {
    :ID => "3",
    :Name => "Desenvename",
    :QuestGiver => "Policía Envenenado",
    :Stage1 => "Entrega este ramo en la tumba de mi difunta esposa en Jardín Freya.",
    :Location1 => "Clase Químicos",
    :QuestDescription => "Entrega el antídoto al Policía Envenenado en la Clase de Químicos.",
    :RewardString => "Flecha venenosa",
    :QuestGiverOW => "Graphics/Characters/BW_PoliciaKO"
  }














  # Extensión de lo anterior que incluye múltiples etapas
  Quest22 = {
    :ID => "2",
    :Name => "Introducciones 2",
    :QuestGiver => "Niño pequeño",
    :Stage1 => "Busca pistas",
    :Stage2 => "Sigue el rastro",
    :Stage3 => "¡Atrapa a los alborotadores!",
    :Location1 => "Pueblo Macabeo",
    :Location2 => "Bosque Verde",
    :Location3 => "Ruta 3",
	:StageLabel1 => "1",
	:StageLabel2 => "2",
    :QuestDescription => "Unos Pokémon salvajes robaron el juguete favorito de un niño. Encuentra a esos alborotadores y ayúdale a recuperarlo.",
    :RewardString => "¡Algo shiny!"
  }

  # Ejemplo de una misión con muchas etapas que tampoco tiene una ubicación definida para cada una
  Quest23 = {
    :ID => "3",
    :Name => "Tareas de última hora",
    :QuestGiver => "Abuela",
    :Stage1 => "A",
    :Stage2 => "B",
    :Stage3 => "C",
    :Stage4 => "D",
    :Stage5 => "E",
    :Stage6 => "F",
    :Stage7 => "G",
    :Stage8 => "H",
    :Stage9 => "I",
    :Stage10 => "J",
    :Stage11 => "K",
    :Stage12 => "L",
    :Location1 => "nil",
    :Location2 => "nil",
    :Location3 => "Pueblo Azuliza",
    :QuestDescription => "¿No es el alfabeto más largo que esto?",
    :RewardString => "Caldo de pollo",
    :QuestGiverOW => "Graphics/Characters/NPC 11"
  }


  # Otros ejemplos aleatorios para consultar si se desea completar la interfaz de usuario y comprobar el desplazamiento de la página
  Quest25 = {
    :ID => "5",
    :Name => "Todos mis amigos",
    :QuestGiver => "Israel",
    :Stage1 => "Queda con tus amigos cerca del Lago Agudeza",
    :QuestDescription => "Israel me dijo que vio algo interesante en el Lago Agudeza y que debería ir a verlo. Espero que no sea otro truco.",
    :RewardString => "No ganas nada por ceder a la presión de tus compañeros"
  }

  Quest26 = {
    :ID => "6",
    :Name => "El viaje comienza",
    :QuestGiver => "Profesor Oak",
    :Stage1 => "Entrega el paquete en la Tienda Pokémon de Ciudad Verde",
    :Stage2 => "Vuelve con el Profesor",
    :Location1 => "Ciudad Verde",
    :Location2 => "nil",
    :QuestDescription => "El profesor me ha confiado una entrega importante para la Tienda Pokémon de Ciudad Verde. Esta es mi primera tarea, ¡mejor no estropearla!",
    :RewardString => "nil"
  }

  Quest27 = {
    :ID => "7",
    :Name => "¿Encuentros cercanos de la... primera fase?",
    :QuestGiver => "nil",
    :Stage1 => "Ponte en contacto con las extrañas criaturas.",
    :Location1 => "Túnel Roca",
    :QuestDescription => "¡Un repentino estallido de luz, y luego...! ¿Qué sucede?",
    :RewardString => "Un posible interrogatorio."
  }

  Quest28 = {
    :ID => "8",
    :Name => "Estas botas fueron hechas para caminar.",
    :QuestGiver => "Músico 1",
    :Stage1 => "Escucha la música del... músico.",
    :Stage2 => "Encuentre la fuente del corte de energía.",
    :Location1 => "nil",
    :Location2 => "Cloacas de Ciudad Azulona",
    :QuestDescription => "Un músico se siente deprimido porque cree que a nadie le gusta su música. Debería ayudarlo a conseguir algún negocio."
  }

  Quest29 = {
    :ID => "9",
    :Name => "¿Tienes uvas?",
    :QuestGiver => "Pato",
    :Stage1 => "Escucha The Duck Song",
    :Stage2 => "Intenta no cantarla en todo el día",
    :Location1 => "YouTube",
    :QuestDescription => "Intentemos revivir viejos memes escuchando esta divertida canción sobre un pato que quiere uvas.",
    :RewardString => "Una pérdida de neuronas. ¡Viva!"
  }

  Quest100 = {
    :ID => "10",
    :Name => "Cantando bajo la lluvia",
    :QuestGiver => "Un hombre mayor",
    :Stage1 => "Me he quedado sin cosas para escribir",
    :Stage2 => "Si estás leyendo esto, ¡espero que tengas un gran día!",
    :Location1 => "¿En algún lugar propenso que llueva?",
    :QuestDescription => "Lo que quieras que sea.",
    :RewardString => "Ropa mojada"
  }

  Quest110 = {
    :ID => "11",
    :Name => "¿Cuándo terminará esta lista?",
    :QuestGiver => "Me",
    :Stage1 => "¿Cuándo terminará esta lista?",
    :Stage2 => "123",
    :Stage3 => "456",
    :Stage4 => "789",
    :QuestDescription => "Estoy perdiendo la cordura.",
    :RewardString => "nil"
  }

  Quest120 = {
    :ID => "12",
    :Name => "La úuultima",
    :QuestGiver => "Un dodo estúpido",
    :Stage1 => "Lucha por lo último de la comida",
    :Stage2 => "No mueras",
    :Location1 => "¿Un sitio volcánico?",
    :Location2 => "Buen consejo para la vida",
    :QuestDescription => "¿Alguien quiere té y galletas?",
    :RewardString => "¡Comida, gloriosa comida!"
  }

end
