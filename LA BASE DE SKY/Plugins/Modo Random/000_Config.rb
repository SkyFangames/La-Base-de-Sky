################################################################################
#
#                            Script de Pokémon Random
#                           por DPertierra y Skyflyer
#
################################################################################
# Utilizado principalmente para un desafío de Pokémon aleatorizado.
# 
# Por aleatorizado, me refiero a que TODOS los Pokémon serán aleatorios, incluso 
# los Pokémon con los que interactúas como los legendarios (puedes desactivar 
# fácilmente el aleatorizador para ciertas situaciones como batallas legendarias
# y selección de Pokémon inicial apagando el interruptor correspondiente.)
#
# Para usarlo: simplemente activa el Interruptor del modo Random (este interruptor
# es el que viene definido más abajo en la línea 28, donde pone "Switch = 60").
#
# Si no quieres que ciertos Pokémon aparezcan nunca, agrégalos dentro de la lista 
# negra en BlackListedPokemon (Esto no tiene efecto si el interruptor mencionado 
# arriba está apagado.)
#
# Si quieres que SOLO ciertos Pokémon aparezcan, agrégalos a la lista blanca llamada
# WhiteListedPokemon. Esto solo se recomienda cuando la cantidad de Pokémon aleatorios
# disponibles es alrededor de 32 o menos. (Esto no tiene efecto si el interruptor 
# mencionado arriba está apagado.)
#
# Tienes más opciones de customización como ataques o habilidades baneadas. Puedes
# encontrar todo esto en las siguientes líneas.
#
################################################################################


module RandomizedChallenge

  #********************************************************
  # CONFIGURACIÓN GENERAL
  #********************************************************

  # ID del Interruptor/Switch para randomizar a los Pokémon. En caso
  # de estar en ON, todos los Pokémon del juego sin excepción serán
  # randomizados, con las restricciones de las opciones siguientes.
  Switch = 60

  # BST PROGRESIVO DE POKÉMON RANDOMIZADOS
  # Los BST de cada medalla se definen en getMaxBSTCap.
  # Desactiva esto en cualquier momento con toggle_progressive_random.
  PROGRESSIVE_RANDOM_DEFAULT_VALUE = true

  # MOVIMIENTOS RANDOMIZADOS
  # Si quieres que los movimientos esten randomizados pon esta constante en true.
  # Puedes modificar esto en cualquier momento llamando al método toggle_random_moves.
  RANDOM_MOVES_DEFAULT_VALUE = true

  # RANDOMIZAR COMPATIBILIDAD DE LAS MTs
  # Si quieres que el aprendizaje de MTs sea aleatorio.
  # Puedes modificar esto en cualquier momento llamando al método toggle_tm_compat.
  RANDOM_TM_COMPAT_DEFAULT_VALUE = true

  # RANDOMIZAR EVOLUCIONES
  # Si quieres que las evoluciones estén randomizadas.
  RANDOM_EVOLUTIONS_DEFAULT_VALUE = false

  # EVOLUCIONES RANDOM CON BST SIMILAR
  RANDOM_EVOLUTIONS_SIMILAR_BST_DEFAULT_VALUE = false
  

  #********************************************************
  # RESTRICCIONES DEL RANDOMIZADO
  #********************************************************
  
  # Pokémon que no pueden salir en el modo Random. Añade aquí los que no quieres que salgan
  # con el mismo formato de los que ya aparecen.
  BlackListedPokemon = [:MEW, :ARCEUS]
  
  # Lista de los únicos Pokémon que pueden aparecer en el modo Random. Si la dejas VACÍA,
  # aparecerán todos los Pokémon del juego SALVO los que añadas a la lista que hay
  # encima de esta, BlackListedPokemon.
  WhiteListedPokemon = []
  
  # Lista de movimientos que no pueden aparecer en el modo Random.
  # Debes añadirlos con el nombre interno que aparece en el PBS moves.txt.
  MOVEBLACKLIST=[:CHATTER, :DIG, :TELEPORT, :SONICBOOM, :DRAGONRAGE, :STRUGGLE]
  
  # Lista de posibles Pokémon que aparecerán como Pokémon Iniciales.
  ListaStartersRandomizado = [
    :BULBASAUR, :CHARMANDER, :SQUIRTLE, :PIDGEY, :NIDORANmA, :NIDORANfE, :ZUBAT, :MANKEY, :POLIWAG, :ABRA, :MACHOP, :BELLSPROUT, :GEODUDE,
    :MAGNEMITE, :GASTLY, :RHYHORN, :HORSEA, :ELEKID, :MAGBY, :PORYGON, :ODDISH, :DRATINI, :CHIKORITA, :CYNDAQUIL, :TOTODILE, :MAREEP,
    :HOPPIP, :SWINUB, :TEDDIURSA, :LARVITAR, :TREECKO, :TORCHIC, :MUDKIP, :LOTAD, :SEEDOT, :RALTS, :ARON, :BUDEW, :TRAPINCH, :DUSKULL,
    :SHUPPET, :BAGON, :BELDUM, :SPHEAL, :TURTWIG, :CHIMCHAR, :PIPLUP, :STARLY, :SHINX, :GIBLE, :SNIVY, :TEPIG, :OSHAWOTT, :LILLIPUP, :SEWADDLE,
    :VENIPEDE, :ROGGENROLA, :TIMBURR, :SOLOSIS, :GOTHITA, :SANDILE, :VANILLITE, :KLINK, :TYNAMO, :LITWICK, :AXEW, :DEINO, :PAWNIARD, :CHESPIN,
    :FENNEKIN, :FROAKIE, :FLETCHLING, :FLABEBE, :GOOMY, :HONEDGE, :ROWLET, :LITTEN, :POPPLIO, :GRUBBIN, :JANGMOO, :GROOKEY, :SCORBUNNY,
    :SOBBLE, :ROLYCOLY, :BLIPBUG, :ROOKIDEE, :HATENNA, :IMPIDIMP, :DREEPY, :SPRIGATITO, :FUECOCO, :QUAXLY, :PAWMI, :SMOLIV, :NACLI, :TINKATINK,
    :FRIGIBAX
  ]



  #********************************************************
  # HABILIDADES RANDOMIZADAS
  #********************************************************
  
  # TIPO DE RANDOMIZADO DE HABILIDADES
  # Definir el tipo de randomizado de habilidades. Hay tres opciones:
  #   :FULLRANDOM      - Todas las habilidades serán aleatorias.
  #   :MAPABILITIES    - Cada habilidad se intercambia por otra siempre.
  #                      Por ejemplo, si Presión se cambia por Llovizna, todos los Pokémon con Presión ahora van a tener Llovizna.
  #                      Sin embargo, los Pokémon que tenían Llovizna no tienen por qué tener Presión, puede haberle tocado otra habilidad.
  #   :SAMEINEVOLUTION - Se mantiene la habilidad al evolucionar.
  #
  # Si no quieres ningún tipo de randomizado pon "TIPO_DE_RANDOM_DE_HABILIDADES = nil"
  TIPO_DE_RANDOM_DE_HABILIDADES = :FULLRANDOM

  # Lista de habilidades que no pueden aparecer en el modo Random.
  # Debes añadirlas con el nombre interno que aparece en el PBS abilities.txt.
  ABILITY_EXCLUSIONS = [
    :IMPOSTER, :PLUS, :MINUS, :WONDERGUARD, :FORECAST, :HARVEST, :HONEYGATHER,
    :BATTLEBOND,:HUNGERSWITCH,:SHIELDSDOWN,:SCHOOLING,:RKSSYSTEM,:POWERCONSTRUCT, 
    :STANCECHANGE, :ZENMODE,:COMMANDER, :MULTITYPE, :GULPMISSILE, :ICEFACE, :ZEROTOHERO, :DISGUISE
  ]

  # Interruptores que se usan para el modo Random.
  # Ten en cuenta que los NPCs de ejemplo usan estos switches, si cambias el número deberás modificarlos también a ellos.
  ABILITY_RANDOMIZER_SWITCH      = 61
  ABILITY_SEMI_RANDOMIZER_SWITCH = 62
  ABILITY_SWAP_RANDOMIZER_SWITCH = 63



  #********************************************************
  # OBJETOS RANDOMIZADAS
  #********************************************************
  
  # Lista de objetos que no quieres que aparezcan entre los objetos Random.
  BLACK_LIST = []

  # Lista de las MTs que pueden salir en el modo Random.
  # Elimina las que prefieras que se entreguen por NPCs y por tanto no
  # se puedan encontrar en objetos del suelo.
  MTLIST_RANDOM = [
    :TM01, :TM02, :TM03, :TM04, :TM05, :TM06, :TM07, :TM08, :TM09, :TM10,
    :TM11, :TM12, :TM13, :TM14, :TM15, :TM16, :TM17, :TM18, :TM19, :TM20,
    :TM21, :TM22, :TM23, :TM24, :TM25, :TM26, :TM27, :TM28, :TM29, :TM30,
    :TM31, :TM32, :TM33, :TM34, :TM35, :TM36, :TM37, :TM38, :TM39, :TM40,
    :TM41, :TM42, :TM43, :TM44, :TM45, :TM46, :TM47, :TM48, :TM49, :TM50,
    :TM51, :TM52, :TM53, :TM54, :TM55, :TM56, :TM57, :TM58, :TM59, :TM60,
    :TM61, :TM62, :TM63, :TM64, :TM65, :TM66, :TM67, :TM68, :TM69, :TM70,
    :TM71, :TM72, :TM73, :TM74, :TM75, :TM76, :TM77, :TM78, :TM79, :TM80, 
    :TM81, :TM82, :TM83, :TM84, :TM85, :TM86, :TM87, :TM88, :TM89, :TM90,
    :TM91, :TM92, :TM93, :TM94, :TM95, :TM96, :TM97, :TM98, :TM99, :TM100
  ]

end