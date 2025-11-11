#===============================================================================
# Configuraciones.
#===============================================================================
module Settings
  #-----------------------------------------------------------------------------
  # La cantidad de zoom aplicada a los sprites frontales de todos los Pokémon. (1 para no escalar)
  #-----------------------------------------------------------------------------
  FRONT_BATTLER_SPRITE_SCALE = 2
  
  #-----------------------------------------------------------------------------
  # La cantidad de zoom aplicada a los sprites traseros de todos los Pokémon. (1 para no escalar)
  #-----------------------------------------------------------------------------
  BACK_BATTLER_SPRITE_SCALE = 3
  
  #-----------------------------------------------------------------------------
  # El número base de fotogramas que se tarda en cargar cada nuevo fotograma de la animación de un sprite.
  # Aumenta para que todos los sprites animen más lento. Disminuye para animar más rápido.
  #-----------------------------------------------------------------------------
  ANIMATION_FRAME_DELAY = 60
  
  #-----------------------------------------------------------------------------
  # Oculta los sprites de sombra del combatiente en el lado del jugador cuando es true.
  # Esto es false por defecto porque la interfaz de batalla predeterminada los ocultará de todos modos.
  #-----------------------------------------------------------------------------
  SHOW_PLAYER_SIDE_SHADOW_SPRITES = true

  #-----------------------------------------------------------------------------
  # Decide si quieres que la sombra del bando del jugador esté invertida o no.
  # En caso de que elijas que se invierta, deberás recolocarlas todas desde el editor del juego.
  #-----------------------------------------------------------------------------
  INVERTIR_SOMBRA_JUGADOR = false
  
  #-----------------------------------------------------------------------------
  # Cuando es true, los sprites se restringirán en las interfaces de Resumen/Almacenamiento/Pokédex.
  #-----------------------------------------------------------------------------
  CONSTRICT_POKEMON_SPRITES = true
  
  #-----------------------------------------------------------------------------
  # Métricas de coordenadas Y para los sprites traseros y frontales de la muñeca de Sustituto, respectivamente.
  #-----------------------------------------------------------------------------
  SUBSTITUTE_DOLL_METRICS = [87, 60]

  #-----------------------------------------------------------------------------
  # Adjustments to the [X, Y] coordinates for species sprites displayed in UI's.
  # This is used for sprites that need additional fine-tuning even after auto-positioning.
  # You can add/remove any species to this hash as you wish.
  #-----------------------------------------------------------------------------
  POKEMON_UI_METRICS = {
    #---------------------------------------------------------------------------
    # Base species
    :FEAROW        => [0, -36],
    :GOLBAT        => [0, -8],
    :VENOMOTH      => [10, -14],
    :CLOYSTER      => [-8, -4],
    :GASTLY        => [0, -14],
    :HAUNTER       => [-6, -12],
    :ZAPDOS        => [8, -10],
    :MOLTRES       => [4, -14],
    :CROBAT        => [0, -10],
    :MANTINE       => [0, -12],
    :LUGIA         => [0, -26],
    :HOOH          => [0, -14],
    :RAYQUAZA      => [12, 0],
    :TALONFLAME    => [0, -12],
    :DRAGALGE      => [8, 0],
    :CLAWITZER     => [0, -16],
    :TYRANTRUM     => [8, 0],
    :AURORUS       => [8, 0],
    :SALAZZLE      => [16, 0],
    :MINIOR        => [-6, -8],
    :TAPUFINI      => [12, 0],
    :SIRFETCHD     => [-8, -4],
    :FROSMOTH      => [12, -16],
    :ETERNATUS     => [8, -12],
    :WYRDEER       => [-14, 0],
    :BASCULEGION   => [6, -6],
    :SKELEDIRGE    => [0, 6],
    :ARBOLIVA      => [6, 0],
    :IRONJUGULIS   => [6, 0],
    :BAXCALIBUR    => [4, 8],
    :KORAIDON      => [18, 0],
    :MIRAIDON      => [0, -8],
    :WALKINGWAKE   => [10, 0],
    #---------------------------------------------------------------------------
    # Forms
    :CHARIZARD_1   => [16, 0],     # Mega Charizard X
    :BEEDRILL_1    => [-6, 0],    # Mega Beedrill
    :SCEPTILE_1    => [0, 8],      # Mega Sceptile
    :BLAZIKEN_1    => [24, 0],     # Mega Blaziken
    :KYOGRE_1      => [0, -6],     # Primal Kyogre
    :RAYQUAZA_1    => [6, 0],      # Mega Rayquaza
    :MINIOR_7      => [-16, -28],  # Red Core Minior
    :MINIOR_8      => [-16, -28],  # Orange Core Minior
    :MINIOR_9      => [-16, -28],  # Yellow Core Minior
    :MINIOR_10     => [-16, -28],  # Green Core Minior
    :MINIOR_11     => [-16, -28],  # Blue Core Minior
    :MINIOR_12     => [-16, -28],  # Indigo Core Minior
    :MINIOR_13     => [-16, -28],  # Violet Core Minior
    :NECROZMA_1    => [10, 0],     # Dusk Mane Necrozma
    :CINDERACE_1   => [4, 12],     # Gigantamax Cinderace
    :BASCULEGION_1 => [6, -6],     # Female Basculegion
  }
end
