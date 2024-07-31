#==============================================================================#
#                              Pokémon Essentials                              #
#                                LA BASE DE SKY                                #
#                         Creada sobre la version 21.1                         #
#                           por Skyflyer y DPertierra                          #
#==============================================================================#

module Settings
  # Esta es la versión de tu juego. El formato debe ser MAYOR.MENOR.PARCHE.
  GAME_VERSION = "1.0.0"

  # Esto indica de qué generación son las mecánicas que se apliquen en tu juego.
  # Esto se usa en batallas, scripts y otras secciones que son usadas dentro y
  # fuera de batalla, como por ejemplo perder vida por veneno fuera de comabte.
  # Puedes elegir la que más se adecué a tu juego. Ten en cuenta que esto no es
  # perfecto y puede que haya alguna mecánica que no sea exactamente como en esa
  # gen, pero en general se acercará mucho. A partir de la generación 5 sí
  # que está todo más preciso en base a la gen que elijas.
  # Efectos actualizados:
  # -La habilidad Fuerte afecto sube las caracteristicas en lugar de cambiar de forma a Greninja
  # -Las habilidades Mutatipo/Líbero solo se activan 1 vez por cambio.
  # -Escudo recio/Espada indómita solo se activan 1 vez por combate.
  # -Cambio de banda fallará si se usa consecutivamente
  # -El efecto de carga ahora dura hasta que se realice un ataque eléctrico
  # -La habilidad Transistor ahora da una mejora del 30%, reducido de 50% en gens anteriores.
  # -El incienso ya no es requerido para criar algunos Pokémon.
  MECHANICS_GENERATION = 9
  
  # Si esto está en true, se mostrará la pantalla de titulo incluso estando
  # en modo debug
  SHOW_TITLE_SCREEN_ON_DEBUG = true
  
  # Muestra unas barras negras en los marcos superirores e inferiores 
  # A medida que se acercan a un entrenador se vuelven mas oscuras.
  MOSTRAR_BARRAS_ENTRENADORES = true
  
  #=============================================================================

  # La cantidad máxima de dinero que el jugador puede llegar a tener.
  MAX_MONEY            = 999_999
  # La cantidad máxima de fichas del Casino que el jugador puede llegar a tener.
  MAX_COINS            = 99_999
  # La cantidad máxima de Puntos de Batalla que el jugador puede llegar a tener.
  MAX_BATTLE_POINTS    = 9_999
  # La cantidad máxima de ceniza que el jugador puede llegar a tener.
  MAX_SOOT             = 9_999
  # La cantidad máxima de caracteres que puede tener el nombre del jugador.
  MAX_PLAYER_NAME_SIZE = 13  # Por defecto 10
  # La cantidad máxima de Pokémon que puede llevar el jugador en el equipo.
  MAX_PARTY_SIZE       = 6
  # El nivel máximo que puede tener un Pokémon.
  MAXIMUM_LEVEL        = 100
  # El nivel al que nace un Pokémon de un Huevo.
  EGG_LEVEL            = 1
  # La posibilidad de que un Pokémon que consigas sea Variocolor (Shiny).
  # (Se aplica sobre 65536. Si pones 1, será 1 de cada 65536).
  SHINY_POKEMON_CHANCE = (MECHANICS_GENERATION >= 6) ? 16 : 8
  # Si los Super Variocolor están activados (usan una animación distinta).
  SUPER_SHINY          = (MECHANICS_GENERATION >= 8)
  # La posibilidad de que un Pokémon salvaje o de Huevo tenga Pokérus
  # (Cuántos de cada 65536).
  POKERUS_CHANCE       = 3
  # Si quieres que los IVs y EVs sean tratados como 0 cuando se calculen las
  # estadísticas de un Pokémon. A pesar de ello, seguirán existiendo ya que son
  # utilizados para cosas como el Poder Oculto.
  DISABLE_IVS_AND_EVS  = false

  #=============================================================================

  # Si la iluminación de los mapas dependa de la hora del día.
  TIME_SHADING                               = true
  # Si los reflejos del jugador y eventos onduleen horizontalmente.
  ANIMATE_REFLECTIONS                        = true
  # Si los Pokémon envenenados pierden PS al caminar el jugador.
  POISON_IN_FIELD                            = (MECHANICS_GENERATION <= 4)
  # Si los Pokémon envenenados se debilitan al caminar si llegan a 1 PS.
  POISON_FAINT_IN_FIELD                      = (MECHANICS_GENERATION <= 3)
  # Si las bayas plantadas crecen según las mecánicas de generación 4 (true) o
  # de generación 3 (false).
  NEW_BERRY_PLANTS                           = (MECHANICS_GENERATION >= 4)
  # Si al pescar el anzuelo pica automáticamente (true) o hay antes un test 
  # de reacción (false).
  FISHING_AUTO_HOOK                          = false
  # El ID del Evento Común que se muestra cuando el jugador empieza a pescar
  # (lo muestra en lugar de enseñar la animación de lanzamiento).
  FISHING_BEGIN_COMMON_EVENT                 = -1
  # El ID del evento común que se ejecuta cuando el jugador deja de pescar 
  # (se ejecuta en lugar de mostrar el tambaleo en la animación)
  FISHING_END_COMMON_EVENT                   = -1
  # Si los Pokémon en la guardería ganan experiencia por cada paso que da el 
  # jugador. Tiene el valor true para la Guardería. y false para la Enfermera
  # Pokémon, ya que ambos usan el mismo código. En el primero te cobran el 
  # dinero al sacar el Pokémon y ganan experiencia, en la segunda al dejarlo
  # y no ganas experiencia.
  DAY_CARE_POKEMON_GAIN_EXP_FROM_WALKING     = (MECHANICS_GENERATION <= 6)
  # Si dos Pokémon son de la misma especie y pueden aprender movimientos huevo 
  # del otro Pokémon.
  DAY_CARE_POKEMON_CAN_SHARE_EGG_MOVES       = (MECHANICS_GENERATION >= 8)
  # Si un Pokémon criado puede heredar cualquier MT/DT/MO de su padre.
  # Nunca lo heredará de su madre.
  BREEDING_CAN_INHERIT_MACHINE_MOVES         = (MECHANICS_GENERATION <= 5)
  # Whether a bred baby Pokémon can inherit egg moves from its mother. It can
  # always inherit egg moves from its father.
  # Si un Pokémon criado puede heredar movimientos huevo de su madre.
  # Siempre podrá heredar movimientos huevo del padre.
  BREEDING_CAN_INHERIT_EGG_MOVES_FROM_MOTHER = (MECHANICS_GENERATION >= 6)
  # Si se muestra la entrada de la Pokédex de un pokémon nuevo que haya
  # nacido de un huevo, tras evolucionarlo y tras obtenerlo de intercambio,
  # además de cuando lo capturas en combate.
  SHOW_NEW_SPECIES_POKEDEX_ENTRY_MORE_OFTEN  = (MECHANICS_GENERATION >= 7)
  # Si consigues una Honor Ball por cada 10 Poké Ball de cualquier tipo que
  # compres de una sola vez (true) o que te den 1 sola Honor Ball cuando compras
  # 10 o más Poké Balls (false). 
  MORE_BONUS_PREMIER_BALLS                   = (MECHANICS_GENERATION >= 8)
  # El número de pasos permitodos en la Zona Safari antes de que te echen
  # (0 = infinito).
  SAFARI_STEPS                               = 600
  # El número de segundos que dura el Concurso de Bichos (0 = infinito).
  BUG_CONTEST_TIME                           = 20 * 60   # 20 minutos 
  #                                                      # (20 x 60 segundos)

  #=============================================================================
  
  # Si un movimiento enseñado por MT/DT/MO reemplaza otro movimiento, esto
  # indica si el nuevo ataque tiene los mismos PP que el ataque anterior (true)
  # o tiene todos sus PP (false).
  TAUGHT_MACHINES_KEEP_OLD_PP          = (MECHANICS_GENERATION == 5)
  # Si el Tutor de Moviminetos puede también enseñar movimientos huevo que el
  # Pokémon sabía cuando nació o que en algún momento aprendió por DT.
  # Movimientos que aprende por nivel del nivel inferior al del Pokémon siempre
  # se pueden recordar.
  MOVE_RELEARNER_CAN_TEACH_MORE_MOVES  = (MECHANICS_GENERATION >= 6)
  # Si los objetos curativos de PS están actualizados a las últimas gens (7+)
  # (true) o en generaciones anteriores (falso).
  REBALANCED_HEALING_ITEM_AMOUNTS      = (MECHANICS_GENERATION >= 7)
  # Si el Caramelo Furia actúa como cura total (true) o Poción false).
  RAGE_CANDY_BAR_CURES_STATUS_PROBLEMS = (MECHANICS_GENERATION >= 7)
  # Si las vitaminas pueden dar EVs sin depender de los que ya tenga el Pokémon
  # (true) o si no se pueden dar si ya tiene al menos 100 (false).
  NO_VITAMIN_EV_CAP                    = (MECHANICS_GENERATION >= 8)
  # Si los Caramelo Raro se pueden usar en un Pokémon que ya estén a su máximo
  # nivel en caso de que sea capaz de evolucionar por nivel (si lo es, se pone
  # a evolucionar).
  RARE_CANDY_USABLE_AT_MAX_LEVEL       = (MECHANICS_GENERATION >= 8)
  # Si el jugador puede elegir la cantidad de objetos que utiliza de una sola
  # vez en un Pokémon. Esto aplica a los objetos de experiencia (Caramelo Raro 
  # y caramelos de experienia) y a los que cambian EVs (vitaminas, plumas, 
  # bayas que bajan EVs).
  USE_MULTIPLE_STAT_ITEMS_AT_ONCE      = (MECHANICS_GENERATION >= 8)

  #=============================================================================

  # Si los Repelentes usan el nivel del primer Pokémon del equipo 
  # independientemente de que esté o no debilitado (true) o usa el nivel del 
  # primer Pokémon no debilitado (false).
  REPEL_COUNTS_FAINTED_POKEMON             = (MECHANICS_GENERATION >= 6)
  # Si se tienen en cuenta las habilidades que afectan a la aparición de
  # Pokémon salvajes de 8 generación.
  MORE_ABILITIES_AFFECT_WILD_ENCOUNTERS    = (MECHANICS_GENERATION >= 8)
  # Si las flautas blanca y negra aumentan o disminuyen el nivel de los Pokémon
  # salvaes respectivamente (true) o suben y bajan el ratio de aparición 
  # respectivamente (falso).
  FLUTES_CHANGE_WILD_ENCOUNTER_LEVELS      = (MECHANICS_GENERATION >= 6)
  # Si el raio de aparición de Pokémon Variocolor (shiny) aumenta si el jugador
  # ha derrotado y capturado previamente muchos otros Pokémon de la misma
  # especie.
  HIGHER_SHINY_CHANCES_WITH_NUMBER_BATTLED = (MECHANICS_GENERATION >= 8)
  # Si el clima que haga en el mapa puede definir el terreno en combate.
  # Clima de tormenta activa Campo Eléctrico, y niebla activa Campo de Niebla.
  OVERWORLD_WEATHER_SETS_BATTLE_TERRAIN    = (MECHANICS_GENERATION >= 8)
  # La configuración default para Phone.rematches_enabled, que determina si
  # los entrenadores registrados en el teléfono pueden estar listos para una
  # revancha. Si es false, Phone.rematches_enabled = true activará las revanchas
  # en cualquier momento que quieras.
  PHONE_REMATCHES_POSSIBLE_FROM_BEGINNING  = false
  # Si el mensaje en una llamada telefónica de un entrenador se recolorea en 
  # azul o rojo dependiendo de su género. Ten en cuenta que esto no se aplica a
  # contactos que no sean entrenaodres. En esos casos deben ser recoloreados 
  # manualmente.
  COLOR_PHONE_CALL_MESSAGES_BY_CONTACT_GENDER = true

  #=============================================================================

  # Un conjunto de arrays que cada uno contiene un tipo de entrenador seguido
  # de un número de una variable del juego. Si esa variable no está a 0, 
  # todos los entrenadores con ese tipo de entrenador se llamarán con el nombre
  # que indique esa variable.
  # Como se ve en el ejemplo, esto se suele usar con rivales cuyo tipo de 
  # entrenador vaya a cambiar durante el juego.
  RIVAL_NAMES = [
    [:RIVAL1,   12],
    [:RIVAL2,   12],
    [:CHAMPION, 12]
  ]

  #=============================================================================

  # Si para usar alguna MO necesitas tener una cantidad de medallas concreta 
  # (independientemente de qué medallas sean) o si necesitas tener una medalla
  # en específico para usar cada MO (false). La cantidad de medallas o la
  # medalla en concreto que necesites viene definido debajo.
  FIELD_MOVES_COUNT_BADGES = true
  # Dependiendo de lo que hayas puesto aquí encima en FIELD_MOVES_COUNT_BADGES,
  # si has puesto true, estos números indican cuántas medallas tienes que tener
  # para usar cada MO, independientemente de qué medallas sean. Si arriba has
  # puesto false, el número de cada medalla indica qué medalla en concreto
  # necesitas para usar cada MO.
  # IMPORTANTE: la primera medalla es la 0, la segunda la 1, la tercera es la 2,
  # etc. Tenlo en cuenta si quieres indicar una medalla en concreto.
  # Ejemplo:
  #      - Si hace falta que tengas la segunda medalla para usar SURF, pondrías
  #        arriba false y abajo en BADGE_FOR_SURF = 1.
  #      - Si hace falta que tengas 3 medallas para usar CORTE, pondrías
  #        arriba true y abajo en BADGE_FOR_CUT = 3.
  BADGE_FOR_CUT       = 1
  BADGE_FOR_FLASH     = 2
  BADGE_FOR_ROCKSMASH = 3
  BADGE_FOR_SURF      = 4
  BADGE_FOR_FLY       = 5
  BADGE_FOR_STRENGTH  = 6
  BADGE_FOR_DIVE      = 7
  BADGE_FOR_WATERFALL = 8

  #=============================================================================

  # Los nombres de cada bolsillo de la Mochila.
  def self.bag_pocket_names
    return [
      _INTL("Objetos"),
      _INTL("Medicinas"),
      _INTL("Poké Balls"),
      _INTL("MTs & MOs"),
      _INTL("Bayas"),
      _INTL("Cartas"),
      _INTL("Obj. Batalla"),
      _INTL("Obj. Clave")
    ]
  end
  # El máximo número de espacios en cada bolsillo (-1 significa sin límite).
  BAG_MAX_POCKET_SIZE  = [-1, -1, -1, -1, -1, -1, -1, -1]
  # Si cada bolsillo auto ordena los objetos en base a su ID.
  BAG_POCKET_AUTO_SORT = [false, false, false, true, true, false, false, false]
  # El máximo número de objetos que puedes tener en la mochila de cada.
  BAG_MAX_PER_SLOT     = 999

  #=============================================================================

  # El número de cajas de almacenamiento de Pokémon que tiene el PC.
  NUM_STORAGE_BOXES   = 40
  # Si dejar un Pokémon en el PC te lo cura o no. Si es false, son curados 
  # cuando usas el comando de eventos Recover All: Entire Party (en los Centro
  # Pokémon).
  HEAL_STORED_POKEMON = (MECHANICS_GENERATION <= 7)

  #=============================================================================

  # Si la lista de la Pokédex que se muestra es la de la región actual en la que
  # está el jugador en ese momento (true), o si aparece un menú para que el 
  # jugador elija qué Pokédex consultar si tiene más de una disponible (false).
  USE_CURRENT_REGION_DEX = false
  # Los nombres de las distintas Pokédex, en orden en el que están definidas en
  # el PBS llamado "regional_dexes.txt". El último nombre es para la Pokédex
  # Nacional y se añade al final de la lista (recuerda que no necesitas usarlo).
  # Este array también indica el orden en el que aparecen en la variable
  # $player.pokedex.unlocked_dexes, que guarda las Pokédex que se han 
  # desbloqueado (la primera Pokédex siempre viene ya desbloqueada de forma
  # predeterminada).
  
  # Si una entrada es solo un nombre, el mapa de la región que se muestra en la 
  # página de Área de un Pokémon será el mapa de la región en la que esté el 
  # jugador en ese momento. La Pokédex Nacional debería funcionar siempre así.
  # En caso de que alguna entrada tenga la forma [nombre, número], entonces el
  # número es el número de la región, y el mapa de esa región es el que 
  # aparecerá en la página Área de la Pokédex, independientemente de la región
  # en la que se encuentre el jugador.
  def self.pokedex_names
    return [
      [_INTL("Pokédex de Kanto"), 0],
      [_INTL("Pokédex de Johto"), 1],
      _INTL("Pokédex Nacional")
    ]
  end
  
  def self.pokedex_names
    return [
      [_INTL("Pokédex de Kanto"),   0],
      [_INTL("Pokédex de Johto"),   1],
      [_INTL("Pokédex de Hoenn"),   2],
      [_INTL("Pokédex de Sinnoh"),  3],
      [_INTL("Pokédex de Teselia"), 4],
      [_INTL("Pokédex de Kalos"),   5],
      [_INTL("Pokédex de Alola"),   6],
      [_INTL("Pokédex de Galar"),   7],
      [_INTL("Pokédex de Paldea"),  8],
      _INTL("Pokédex Nacional")
    ]
  end
  # Si todas las formas de una especie de Pokémon concreto se pueden ver en la
  # Pokédex con solo haber visto una de ellas (true) o necesitas ver cada forma
  # por separado para que esa forma en concreto se vea en la Pokédex (falso).
  DEX_SHOWS_ALL_FORMS = false
  # Una lista de números, donde cada número es el de una de las Pokédex (en el 
  # mismo orden que las que hay arriba, salvo la Nacional, que es -1). Todas las
  # diferentes Pokédex que pongas aquí empezarán su número en 0 en lugar de en
  # 1 (como pasa en Teselia con Victini, que es el nº 0 de la Pokédex).
  DEXES_WITH_OFFSETS  = []

  #=============================================================================

  # Un conjunto de listas, cada contiene detalles de un gráfico que será mostrado
  # en el mapa de la región que corresponda. Los valores de cada lista son:
  #   * El número de la región.
  #   * Un interruptor; el gráfico se muestra si está en ON (solo en mapas que no
  #     estén en paredes).
  #   * Coordenada X del gráfico en el mapa, en cuadrados.
  #   * Coordenada Y del gráfico en el mapa, en cuadrados.
  #   * Nombre del gráfico, que está en la carpeta Graphics/UI/Town Map.
  #   * El gráfico siempre (true) o nunca (false) se mostrará en mapas de pared.
  REGION_MAP_EXTRAS = [
    [0, 51, 16, 15, "hidden_Berth", false],
    [0, 52, 20, 14, "hidden_Faraday", false]
  ]

  # Si el jugador puede hacer Vuelo mientras mira el mapa. Esto solo se permite
  # si el jugador puede usar Vuelo de forma normal.
  CAN_FLY_FROM_TOWN_MAP = true

  #=============================================================================
  
  # Par de IDs de mapas, en los que el mensaje con el nombre de la zona no se 
  # muestra al cambiar de un mapa a otro (y viceversa). Útil para rutas largas
  # que las separas en diferentes mapas.
  #   Ej.: [4,5,16,17,42,43] hace que los mapas 4 y 5 estén conectados, el 16 
  # con el 17 también, y el 42 con el 43. De todos modos, esto no te hace falta
  # si los dos mapas se llaman exactamente igual, puesto que en esos casos no
  # se ve tampoco el nombre al cambiar entre ellos (y no hace falta ponerlos
  # aquí).
  NO_SIGNPOSTS = []

  #=============================================================================

  # Una lista de los mapas en los que hay Pokémon errantes (estos son los que
  # van cambiando de ruta, como algunos legendarios). Cada mapa tiene una lista
  # del resto de mapas a los que puede saltar el Pokémon (por eso cada número
  # tiene en su lista de la derecha el resto de mapas a los que saltaría).
  ROAMING_AREAS = {
    5  => [   21, 28, 31, 39, 41, 44, 47, 66, 69],
    21 => [5,     28, 31, 39, 41, 44, 47, 66, 69],
    28 => [5, 21,     31, 39, 41, 44, 47, 66, 69],
    31 => [5, 21, 28,     39, 41, 44, 47, 66, 69],
    39 => [5, 21, 28, 31,     41, 44, 47, 66, 69],
    41 => [5, 21, 28, 31, 39,     44, 47, 66, 69],
    44 => [5, 21, 28, 31, 39, 41,     47, 66, 69],
    47 => [5, 21, 28, 31, 39, 41, 44,     66, 69],
    66 => [5, 21, 28, 31, 39, 41, 44, 47,     69],
    69 => [5, 21, 28, 31, 39, 41, 44, 47, 66    ]
  }
  # Conjunto de listas, cada una contiene detalles sobre Pokémon errantes.
  # La información se pone de esta manera:
  #   * Especie.
  #   * Nivel.
  #   * Número del interruptor que activa al Pokémon.
  #   * Tipo de encuentro (0=cualquiera, 1=hierba/andando en cueva, 2=surf,
  #     3=pescando, 4=surfeando y pescando). Mira en la parte de abajo de
  #     PField_RoamingPokemon para ver las listas posibles.
  #   * Nombre de la música (BGM) que sonará cuando lo encuentras (OPCIONAL).
  #   * Zonas específicas en las que puede salir este Pokémon (OPCIONAL).
  ROAMING_SPECIES = [
    [:LATIAS, 30, 53, 0, "Battle roaming"],
    [:LATIOS, 30, 53, 0, "Battle roaming"],
    [:KYOGRE, 40, 54, 2, nil, {
      2  => [   21, 31    ],
      21 => [2,     31, 69],
      31 => [2, 21,     69],
      69 => [   21, 31    ]
    }],
    [:ENTEI, 40, 55, 1]
  ]

  #=============================================================================

  ###########################
  # INTERRUPTORES DEL JUEGO
  ###########################
  
  # Número del interruptor que se activa cuando el jugador cae derrotado.
  STARTING_OVER_SWITCH      = 1
  # Número del interruptor que se activa cuando el jugador ha visto el
  # Pokérus en un Centro Pokémon (para que no le suelten el mensaje más veces).
  SEEN_POKERUS_SWITCH       = 2
  # Número del interruptor que, si está en ON, todos los Pokémon salvajes 
  # serán Variocolor (shiny).
  SHINY_WILD_POKEMON_SWITCH = 31
  # Número del interruptor que, si está en ON, todos los Pokémon que se generen
  # se consideren de "encuentro fatídico" (lo que sale en Pokémon de evento
  # cuando miras en sus datos dónde se ha conseguido).
  FATEFUL_ENCOUNTER_SWITCH  = 32
  # Número del interruptor que, si está en ON, desactiva el acceso a la caja de
  # almacenamiento de Pokémon (PC) a través de la pantalla de Equipo.
  DISABLE_BOX_LINK_SWITCH   = 35

  #=============================================================================
  
  ######################
  # IDS DE ANIMACIONES (en la pestaña de Animations, al lado de los Tilesets).
  ######################
  
  # Animación que aparece cuando el jugador anda por la hierba (grass rustling).
  GRASS_ANIMATION_ID           = 1
  # Animación que aparece cuando el jugador cae al suelo tras hacer un salto 
  # de un bordillo (muestra el efecto de polvo).
  DUST_ANIMATION_ID            = 2
  # Animación que aparece cuando un entrenador ve a otro entrenador (un símbolo
  # de exclamación).
  EXCLAMATION_ANIMATION_ID     = 3
  # Animación que aparece cuando se mueve un trozo de hierba debido al Poké 
  # Radar.
  RUSTLE_NORMAL_ANIMATION_ID   = 1
  # Animación que aparece cuando se mueve un trozo de hierba mucho debido al 
  # Poké Radar. (Especies raras)
  RUSTLE_VIGOROUS_ANIMATION_ID = 5
  # Animación que aparece cuando se mueve un trozo de hierba y brilla debido al 
  # Poké Radar. (Encuentro variocolor)
  RUSTLE_SHINY_ANIMATION_ID    = 6
  # Animación que aparece cuando un árbol de bayas crece mientras el jugador
  # está en el mimso mapa (solo para nuevas mecánicas de crecimiento).
  PLANT_SPARKLE_ANIMATION_ID   = 7

  #=============================================================================

  # El ANCHO por defecto de la pantalla en píxeles (en escala 1.0).
  SCREEN_WIDTH  = 512
  # El ALTO de la pantalla en píxelex (en escala 1.0).
  SCREEN_HEIGHT = 384
  # El tamaño de la pantalla por defecto. 
  #   * Posibles valores: 0.5, 1.0, 1.5 y 2.0.
  SCREEN_SCALE  = 1.0

  #=============================================================================

  # Lista de los posibles idiomas del juego. Cada uno es una lista que contiene
  # el nombre del idioma que se muestra en el juego y el fragmento del archivo
  # de ese lenguaje. Un lenguaje usa los archivos de datos que están en la 
  # carpeta Data llamados essages_FRAGMENT_core.dat y messages_FRAGMENT_game.dat 
  # (en caso de que existan).
  LANGUAGES = [
#    ["Español", "español"],
#    ["English", "english"]
  ]

  #=============================================================================

  # Posibles marcos de texto. Los gráficos están en "Graphics/Windowskins/".
  SPEECH_WINDOWSKINS = [
    "speech hgss 1",
    "speech hgss 2",
    "speech hgss 3",
    "speech hgss 4",
    "speech hgss 5",
    "speech hgss 6",
    "speech hgss 7",
    "speech hgss 8",
    "speech hgss 9",
    "speech hgss 10",
    "speech hgss 11",
    "speech hgss 12",
    "speech hgss 13",
    "speech hgss 14",
    "speech hgss 15",
    "speech hgss 16",
    "speech hgss 17",
    "speech hgss 18",
    "speech hgss 19",
    "speech hgss 20",
    "speech pl 18"
  ]

  # Posibles marcos de menú. Los gráficos están en "Graphics/Windowskins/".
  MENU_WINDOWSKINS = [
    "choice 1",
    "choice 2",
    "choice 3",
    "choice 4",
    "choice 5",
    "choice 6",
    "choice 7",
    "choice 8",
    "choice 9",
    "choice 10",
    "choice 11",
    "choice 12",
    "choice 13",
    "choice 14",
    "choice 15",
    "choice 16",
    "choice 17",
    "choice 18",
    "choice 19",
    "choice 20",
    "choice 21",
    "choice 22",
    "choice 23",
    "choice 24",
    "choice 25",
    "choice 26",
    "choice 27",
    "choice 28"
  ]
  
  #=============================================================================
  # Weather Settings (Hail/Snow)
  #=============================================================================
  # 0 : Hail     (Clásico) Granizo funciona como en Gen 8 y anteriores
  # 1 : Snow     (Gen 9+) Nevada reemplaza granizo. Boosteando la Defensa de los tipo Hielo.
  #-----------------------------------------------------------------------------
  #-----------------------------------------------------------------------------
  HAIL_WEATHER_TYPE = 1
  
  
  #=============================================================================
  # Status Settings (Frostbite)
  #=============================================================================
  # Cuando está en true efectos que normalmente congelan generaran 
  # la congelacion de Hisui
  #-----------------------------------------------------------------------------
  FREEZE_EFFECTS_CAUSE_FROSTBITE = false
  
  
  ENABLE_SKIP_TEXT = false

  #=============================================================================

  # Aquí van los créditos de tu juego, en un array. Puedes poner las líneas 
  # dentro de un _INTL() para que sea fácil de traducirlas a otros idiomas.
  # Para que una línea se separe en dos columnas, pon "<s>" entre ellas.
  # Los créditos de los Plugins y del motor de Essentials se añaden de forma
  # automática al final de los créditos.
  def self.game_credits
    return [
    
      " PON AQUÍ TUS CRÉDITOS ",
      "",
      
    
      "LA BASE DE SKY",
      _INTL("Creada por:"),
      "Skyflyer<s>DPertierra",
      "",
      _INTL("Colaboraciones:"),
      "DarmanInigo<s>Nieves1236",
      "deNombreTuri<s>Pokepachito",
      "Ebaru",
      "",
      _INTL("Testeo:"),
      "DanzanteSinMega<s>axel_kreiss",
      "glitchybek<s>abogadouuu",
      "jonidelta<s> ",
      "",
      "",
      _INTL("Animaciones de ataques:"),
      _INTL("Versión del 20.04.2022"),
      "Project lead by StCooler.",
      "Contributors:",
      "StCooler<s>DarryBD99",
      "WolfPP<s>ardicoozer",
      "riddlemeree",
      "Thanks to the Reborn team for",
      "letting people use their resources.",
      "You are awesome.",
      "Thanks to BellBlitzKing for",
      "his Pokemon Sound Effects Pack:",
      "Gen 1 to Gen 7 - All Attacks SFX.",
      "Kirik<s>Marin",
      "Maruno<s>AiurJordan",
      "Appletun<s>ThatWelshOne_",
      "",
      _INTL("Sprites de combate estilo 4 gen:"),
      "TheLuiz<s>leparagon",
      "French-Cyndaquil<s>Z-nogyroP",
      "Prodigal96<s>TheLuiz",
      "Vanilla Sunshine<s>fishbowlsoul90",
      "zlolxd<s>elazulmax",
      "mangamanga<s>MrDollSteak",
      "Spherical-Ice<s>Dreadwing93",
      "Smogon Gen 8 Sprite Project",
      "Smogon Sun/Moon Sprite Project",
      "Gen VI: Pokémon Sprite Resource",
      "",
      "Sprites Poké Ball actualizados:",
      "SrGio<s>Pokepachito",
      "",
      "",_INTL("Iconos Pokémon 9 gen:"),
      "CarmaNekko<s>Divaruta 666",
      "Okyo<s>JLauz735 ",
      "JLauz735<s>ShenseyGrenin",
      "",
      "",_INTL("Pokédex regionales:"),
      "HeddyGames",
      "",
      "",_INTL("Incubadora:"),
      "Kyu",
      "",
      "",
      "",_INTL("Huellas de Pokémon"),
      "भाग्य ज्योति<s>WolfPP ",
      "Caruban<s>komeiji514 ",
      "",
      "",
      "Pokémon Essentials v21.1",
      _INTL("Creado por:"),
      "Maruno",
      "",
      _INTL("También involucrados:"),
      "A. Lee Uss<s>Anne O'Nymus",
      "Ecksam Pell<s>Jane Doe",
      "Joe Dan<s>Nick Nayme",
      "Sue Donnim<s>"
    ]
  end
end

# ¡NO CAMBIES ESTO DE AQUÍ!
module Essentials
  VERSION = "21.1"
  ERROR_TEXT = ""
  MKXPZ_VERSION = "2.4.2/c9378cf"
end


