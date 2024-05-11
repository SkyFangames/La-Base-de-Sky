module Settings
    # Si se recalcula el orden de turno después de que un Pokémon Mega Evolucione.
    RECALCULATE_TURN_ORDER_AFTER_MEGA_EVOLUTION = (MECHANICS_GENERATION >= 7)
    # Si se recalcular el orden de turno después de que cambie la estadística de 
    # Velocidad de un Pokémon.
    RECALCULATE_TURN_ORDER_AFTER_SPEED_CHANGES  = (MECHANICS_GENERATION >= 8)
    # Si es true, cualquier Pokémon (propio o extranjero) puede desobedecer los 
    # comandos del jugador si el Pokémon tiene un nivel demasiado alto en 
    # comparación con las Medallas de Gimnasio obtenidas.
    ANY_HIGH_LEVEL_POKEMON_CAN_DISOBEY          = false
    # Si es true, los Pokémon extranjeros pueden desobedecer los comandos del
    # jugador si el Pokémon tiene un nivel demasiado alto en comparación con 
    # las Medallas de Gimnasio obtenidas.
    FOREIGN_HIGH_LEVEL_POKEMON_CAN_DISOBEY      = true
    # Determina si la categoría física/especial de un movimiento depende del 
    # movimiento mismo (true) o de su tipo (false).
    MOVE_CATEGORY_PER_MOVE                      = (MECHANICS_GENERATION >= 4)
    # Determina si los golpes críticos hacen 1.5x de daño y tienen 4 etapas
    # (true) o hacen 2x de daño y tienen 5 etapas como en la Gen 5 (false).
    # También determina si la tasa de golpe crítico puede ser copiada por 
    # Transform/Psych Up.
    NEW_CRITICAL_HIT_RATE_MECHANICS             = (MECHANICS_GENERATION >= 6)
  
    #=============================================================================
  
    # Determina si varios efectos se aplican en relación con el tipo de un Pokémon:
    #   * Inmunidad de los Pokémon tipo Eléctrico a la parálisis
    #   * Inmunidad de los Pokémon tipo Fantasma a quedar atrapados
    #   * Inmunidad de los Pokémon tipo Planta a movimientos en polvo y Espora
    #   * Los Pokémon de tipo Veneno no pueden fallar al usar Tóxico
    MORE_TYPE_EFFECTS                   = (MECHANICS_GENERATION >= 6)
    # Determina si el clima causado por una habilidad dura 5 rondas (true) o para
    # siempre (false).
    FIXED_DURATION_WEATHER_FROM_ABILITY = (MECHANICS_GENERATION >= 6)
    # Determina si los objetos X (Ataque X, etc.) aumentan su estadística en 2 etapas
    # (true) o en 1 (false).
    X_STAT_ITEMS_RAISE_BY_TWO_STAGES    = (MECHANICS_GENERATION >= 7)
    # Determina si algunas Poké Balls tienen multiplicadores de tasa de captura 
    # desde la Gen 7 (true) o desde generaciones anteriores (false).
    NEW_POKE_BALL_CATCH_RATES           = (MECHANICS_GENERATION >= 7)
    # Determina si Rocío Bondad potencia los movimientos de tipo Psíquico y 
    # Dragón en un 20% (true) o aumenta el Ataque Especial y la Defensa Especial
    # del portador en un 50% (false).
    SOUL_DEW_POWERS_UP_TYPES            = (MECHANICS_GENERATION >= 7)
  
    #=============================================================================
  
    # Si es true, los Pokémon con alta felicidad ganarán más Exp en las batallas,
    # tendrán la posibilidad de evitar/curar efectos negativos por sí mismos, 
    # resistirán el desmayo, etc.
    AFFECTION_EFFECTS        = false
    # Si AFFECTION_EFFECTS es true, determina si la felicidad de un Pokémon
    # está limitada a 179 y solo puede aumentarse más con bayas que aumenten 
    # la amistad. Relacionado con AFFECTION_EFFECTS por defecto porque los efectos 
    # de afecto solo comienzan a aplicarse por encima de una felicidad de 179. 
    # También reduce el umbral de evolución por felicidad a 160.
    APPLY_HAPPINESS_SOFT_CAP = AFFECTION_EFFECTS
  
    #=============================================================================
  
    # El número mínimo de medallas requeridas para aumentar cada estadística de 
    # los Pokémon del jugador en 1.1x, solo en batalla.
    NUM_BADGES_BOOST_ATTACK  = (MECHANICS_GENERATION >= 4) ? 999 : 1
    NUM_BADGES_BOOST_DEFENSE = (MECHANICS_GENERATION >= 4) ? 999 : 5
    NUM_BADGES_BOOST_SPATK   = (MECHANICS_GENERATION >= 4) ? 999 : 7
    NUM_BADGES_BOOST_SPDEF   = (MECHANICS_GENERATION >= 4) ? 999 : 7
    NUM_BADGES_BOOST_SPEED   = (MECHANICS_GENERATION >= 4) ? 999 : 3
  
    #=============================================================================
  
    # El switch del juego que, cuando está activado, evita que todos los Pokémon
    # en batalla realicen una Mega Evolución incluso si de otra manera pudieran.
    NO_MEGA_EVOLUTION = 34
  
    #=============================================================================
  
    # Determina si la exp obtenida al vencer a un Pokémon debe escalarse según el
    # nivel del receptor.
    SCALED_EXP_FORMULA                   = (MECHANICS_GENERATION == 5 || MECHANICS_GENERATION >= 7)
    # Si es true, la exp. obtenida al vencer a un Pokémon se divide equitativamente 
    # entre cada participante (true), o cada participante gana esa cantidad de exp.
    # (false). Esto también se aplica a la exp. obtenida a través del Rep. Exp. 
    # (versión de objeto equipable) que se distribuye a todos los que lo llevan equipado.
    SPLIT_EXP_BETWEEN_GAINERS            = (MECHANICS_GENERATION <= 5)
    # Si es true, la Exp obtenida al vencer a un Pokémon se multiplica por 1.5 si 
    # ese Pokémon es propiedad de otro entrenador.
    MORE_EXP_FROM_TRAINER_POKEMON        = (MECHANICS_GENERATION <= 6)
    # Determina si un Pokémon que lleva un objeto Power gana 8 (true) o 4 (false) 
    # EV en la estadística relevante.
    MORE_EVS_FROM_POWER_ITEMS            = (MECHANICS_GENERATION >= 7)
    # Si es true, se aplica el mecanismo de captura crítica. Ten en cuenta que su 
    # cálculo se basa en un total de 600+ especies (es decir, tantas especies deben 
    # ser capturadas para proporcionar la mayor probabilidad de captura crítica de 
    # 2.5x), y puede haber menos especies en tu juego.
    ENABLE_CRITICAL_CAPTURES             = (MECHANICS_GENERATION >= 5)
    # Si es true, los Pokémon ganan Exp por capturar a un Pokémon.
    GAIN_EXP_FOR_CAPTURE                 = (MECHANICS_GENERATION >= 6)
    # Si es true, se le pregunta al jugador qué hacer con un Pokémon recién capturado 
    # si su equipo está lleno. Si es true, el jugador puede cambiar si se le pregunta 
    # esto en la pantalla de Opciones.
    NEW_CAPTURE_CAN_REPLACE_PARTY_MEMBER = (MECHANICS_GENERATION >= 7)
  
    #=============================================================================
  
    # El switch de juego que, cuando está activado, evita que el jugador pierda 
    # dinero si pierde un combate (todavía puede ganar dinero de entrenadores por ganar).
    NO_MONEY_LOSS                       = 33
    # Si es true, los Pokémon del equipo comprueban si pueden evolucionar después 
    # de todas las batallas, independientemente del resultado (true), o solo después 
    # de las batallas que el jugador ganó (false).
    CHECK_EVOLUTION_AFTER_ALL_BATTLES   = (MECHANICS_GENERATION >= 6)
    # Si es true, los Pokémon debilitados pueden intentar evolucionar después 
    # de un combate.
    CHECK_EVOLUTION_FOR_FAINTED_POKEMON = true
  
    #=============================================================================
  
    # Si es true, los Pokémon salvajes marcados como "Legendario", "Mítico" o 
    # "Ultraente" (según se define en pokemon.txt) tienen una IA más inteligente.
    # Su nivel de habilidad se establece en 32, que es un nivel de habilidad medio.
    SMARTER_WILD_LEGENDARY_POKEMON = true
  end
  
