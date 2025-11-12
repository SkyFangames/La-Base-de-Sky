#===============================================================================
# Midbattle Scripts
#===============================================================================
# This module stores all custom battle scripts that can be called upon with the
# battle rule "midbattleScript" if you don't want to input the entire script in
# the event script itself, due to it being too long or if you just find it neater
# this way.
#
# Note that when calling one of the scripts here, you do so in the event by
# setting the constant you defined here as a battle rule.
#
# 	For example:  
#   setBattleRule("midbattleScript", :DEMO_SPEECH)
#
#   *Note that a semi-colon is required in front of the constant when called, 
#    but not when defined below.
#-------------------------------------------------------------------------------
module MidbattleScripts
  #-----------------------------------------------------------------------------
  # Demo for displaying each of the main triggers and when they activate.
  #-----------------------------------------------------------------------------
  DEMO_SPEECH = {
    #---------------------------------------------------------------------------
    # Round phases
    "RoundStartCommand_foe" => "Trigger: 'RoundStartCommand'\n({2}, {1})",
    "RoundStartAttack_foe"  => "Trigger: 'RoundStartAttack'\n({2}, {1})",
    "RoundEnd_foe"          => "Trigger: 'RoundEnd'\n({2}, {1})",
    #---------------------------------------------------------------------------
    # Battler turns
    "TurnStart_foe"         => "Trigger: 'TurnStart'\n({2}, {1})",
    "TurnEnd_foe"           => "Trigger: 'TurnEnd'\n({2}, {1})",
    #---------------------------------------------------------------------------
    # Item usage
    "BeforeItemUse"         => "Trigger: 'BeforeItemUse'\n({2}, {1})",
    "AfterItemUse"          => "Trigger: 'AfterItemUse'\n({2}, {1})",
    #---------------------------------------------------------------------------
    # Wild capture
    "BeforeCapture"         => "Trigger: 'BeforeCapture'\n({2}, {1})",
    "AfterCapture"          => "Trigger: 'AfterCapture'\n({2}, {1})",
    "FailedCapture"         => "Trigger: 'FailedCapture'\n({2}, {1})",
    #---------------------------------------------------------------------------
    # Switching
    "BeforeSwitchOut"       => "Trigger: 'BeforeSwitchOut'\n({2}, {1})",
    "BeforeSwitchIn"        => "Trigger: 'BeforeSwitchIn'\n({2}, {1})",
    "BeforeLastSwitchIn"    => "Trigger: 'BeforeLastSwitchIn'\n({2}, {1})",
    "AfterSwitchIn"         => "Trigger: 'AfterSwitchIn'\n({2}, {1})",
    "AfterLastSwitchIn"     => "Trigger: 'AfterLastSwitchIn'\n({2}, {1})",
    "AfterSendOut"          => "Trigger: 'AfterSendOut'\n({2}, {1})",
    "AfterLastSendOut"      => "Trigger: 'AfterLastSendOut'\n({2}, {1})",
    #---------------------------------------------------------------------------
    # Megas & Primals
    "BeforeMegaEvolution"   => "Trigger: 'BeforeMegaEvolution'\n({2}, {1})",
    "AfterMegaEvolution"    => "Trigger: 'AfterMegaEvolution'\n({2}, {1})",
    "BeforePrimalReversion" => "Trigger: 'BeforePrimalReversion'\n({2}, {1})",
    "AfterPrimalReversion"  => "Trigger: 'AfterPrimalReversion'\n({2}, {1})",
    #---------------------------------------------------------------------------
    # Move usage
    "BeforeMove"            => "Trigger: 'BeforeMove'\n({2}, {1})",
    "BeforeDamagingMove"    => "Trigger: 'BeforeDamagingMove'\n({2}, {1})",
    "BeforePhysicalMove"    => "Trigger: 'BeforePhysicalMove'\n({2}, {1})",
    "BeforeSpecialMove"     => "Trigger: 'BeforeSpecialMove'\n({2}, {1})",
    "BeforeStatusMove"      => "Trigger: 'BeforeStatusMove'\n({2}, {1})",
    "AfterMove"             => "Trigger: 'AfterMove'\n({2}, {1})",
    "AfterDamagingMove"     => "Trigger: 'AfterDamagingMove'\n({2}, {1})",
    "AfterPhysicalMove"     => "Trigger: 'AfterPhysicalMove'\n({2}, {1})",
    "AfterSpecialMove"      => "Trigger: 'AfterSpecialMove'\n({2}, {1})",
    "AfterStatusMove"       => "Trigger: 'AfterStatusMove'\n({2}, {1})",
    #---------------------------------------------------------------------------
    # Damage results
    "UserDealtDamage"       => "Trigger: 'UserDealtDamage'\n({2}, {1})",
    "UserDamagedSub"        => "Trigger: 'UserDamagedSub'\n({2}, {1})",
    "UserBrokeSub"          => "Trigger: 'UserBrokeSub'\n({2}, {1})",
    "UserDealtCriticalHit"  => "Trigger: 'UserDealtCriticalHit'\n({2}, {1})",
    "UserMoveEffective"     => "Trigger: 'UserMoveEffective'\n({2}, {1})",
    "UserMoveResisted"      => "Trigger: 'UserMoveResisted'\n({2}, {1})",
    "UserMoveNegated"       => "Trigger: 'UserMoveNegated'\n({2}, {1})",
    "UserMoveDodged"        => "Trigger: 'UserMoveDodged'\n({2}, {1})",
    "UserHPHalf"            => "Trigger: 'UserHPHalf'\n({2}, {1})",
    "UserHPLow"             => "Trigger: 'UserHPLow'\n({2}, {1})",
    "LastUserHPHalf"        => "Trigger: 'LastUserHPHalf'\n({2}, {1})",
    "LastUserHPLow"         => "Trigger: 'LastUserHPLow'\n({2}, {1})",
    "TargetTookDamage"      => "Trigger: 'TargetTookDamage'\n({2}, {1})",
    "TargetSubDamaged"      => "Trigger: 'TargetSubDamaged'\n({2}, {1})",
    "TargetSubBroken"       => "Trigger: 'TargetSubBroken'\n({2}, {1})",
    "TargetTookCriticalHit" => "Trigger: 'TargetTookCriticalHit'\n({2}, {1})",
    "TargetWeakToMove"      => "Trigger: 'TargetWeakToMove'\n({2}, {1})",
    "TargetResistedMove"    => "Trigger: 'TargetResistedMove'\n({2}, {1})",
    "TargetNegatedMove"     => "Trigger: 'TargetNegatedMove'\n({2}, {1})",
    "TargetDodgedMove"      => "Trigger: 'TargetDodgedMove'\n({2}, {1})",
    "TargetHPHalf"          => "Trigger: 'TargetHPHalf'\n({2}, {1})",
    "TargetHPLow"           => "Trigger: 'TargetHPLow'\n({2}, {1})",
    "LastTargetHPHalf"      => "Trigger: 'LastTargetHPHalf'\n({2}, {1})",
    "LastTargetHPLow"       => "Trigger: 'LastTargetHPLow'\n({2}, {1})",
    #---------------------------------------------------------------------------
    # Battler condition
    "BattlerHPRecovered"    => "Trigger: 'BattlerHPRecovered'\n({2}, {1})",
    "BattlerHPFull"         => "Trigger: 'BattlerHPFull'\n({2}, {1})",
    "BattlerHPReduced"      => "Trigger: 'BattlerHPReduced'\n({2}, {1})",
    "BattlerHPCritical"     => "Trigger: 'BattlerHPCritical'\n({2}, {1})",
    "BattlerFainted"        => "Trigger: 'BattlerFainted'\n({2}, {1})",
    "LastBattlerFainted"    => "Trigger: 'LastBattlerFainted'\n({2}, {1})",
    "BattlerReachedHPCap"   => "Trigger: 'BattlerReachedHPCap'\n({2}, {1})",
    "BattlerStatusChange"   => "Trigger: 'BattlerStatusChange'\n({2}, {1})",
    "BattlerStatusCured"    => "Trigger: 'BattlerStatusCured'\n({2}, {1})",
    "BattlerConfusionStart" => "Trigger: 'BattlerConfusionStart'\n({2}, {1})",
    "BattlerConfusionEnd"   => "Trigger: 'BattlerConfusionEnd'\n({2}, {1})",
    "BattlerAttractStart"   => "Trigger: 'BattlerAttractStart'\n({2}, {1})",
    "BattlerAttractEnd"     => "Trigger: 'BattlerAttractEnd'\n({2}, {1})",
    "BattlerStatRaised"     => "Trigger: 'BattlerStatRaised'\n({2}, {1})",
    "BattlerStatLowered"    => "Trigger: 'BattlerStatLowered'\n({2}, {1})",
    "BattlerMoveZeroPP"     => "Trigger: 'BattlerMoveZeroPP'\n({2}, {1})",
    #---------------------------------------------------------------------------
    # End of effects
    "WeatherEnded"          => "Trigger: 'WeatherEnded'\n({2}, {1})",
    "TerrainEnded"          => "Trigger: 'TerrainEnded'\n({2}, {1})",
    "FieldEffectEnded"      => "Trigger: 'FieldEffectEnded'\n({2}, {1})",
    "TeamEffectEnded"       => "Trigger: 'TeamEffectEnded'\n({2}, {1})",
    "BattlerEffectEnded"    => "Trigger: 'BattlerEffectEnded'\n({2}, {1})",
    #---------------------------------------------------------------------------
    # End of battle
    "BattleEnd"             => "Trigger: 'BattleEnd'\n({2}, {1})",
    "BattleEndWin"          => "Trigger: 'BattleEndWin'\n({2}, {1})",
    "BattleEndLoss"         => "Trigger: 'BattleEndLoss'\n({2}, {1})",
    "BattleEndDraw"         => "Trigger: 'BattleEndDraw'\n({2}, {1})",
    "BattleEndForfeit"      => "Trigger: 'BattleEndForfeit'\n({2}, {1})",
    "BattleEndRun"          => "Trigger: 'BattleEndRun'\n({2}, {1})",
    "BattleEndFled"         => "Trigger: 'BattleEndFled'\n({2}, {1})",
    "BattleEndCapture"      => "Trigger: 'BattleEndCapture'\n({2}, {1})"
  } 
  
  #-----------------------------------------------------------------------------
  # Demo trainer speech when triggering Mega Evolution.
  #-----------------------------------------------------------------------------
  DEMO_MEGA_EVOLUTION = {
    "BeforeMegaEvolution_foe"           => "¡Vamos, {1}!\n¡Vamos a arrasar con la Megaevolución!",
    "AfterMegaEvolution_GYARADOS_foe"   => "¡Contempla la serpiente de las profundidades más oscuras!",
    "AfterMegaEvolution_GENGAR_foe"     => "¡Buena suerte escapando de ESTA pesadilla!",
    "AfterMegaEvolution_KANGASKHAN_foe" => "¡Padre e hijo luchan como uno solo!",
    "AfterMegaEvolution_AERODACTYL_foe" => "¡Prepárate para mi bestia prehistórica!",
    "AfterMegaEvolution_FIRE_foe"       => "¡Fuego máximo!",
    "AfterMegaEvolution_ELECTRIC_foe"   => "¡Prepárate para una poderosa fuerza de la naturaleza!",
    "AfterMegaEvolution_BUG_foe"        => "¡Mi poderoso insecto ha emergido de su capullo!"
  }
  
  #-----------------------------------------------------------------------------
  # Demo trainer speech when triggering Primal Reversion.
  #-----------------------------------------------------------------------------
  DEMO_PRIMAL_REVERSION = {
    "BeforePrimalReversion_foe"        => "¡Prepárate para una fuerza antigua más allá de la imaginación!",
    "AfterPrimalReversion_KYOGRE_foe"  => "¡{1}!\n¡Deja que los mares broten de tu poderosa presencia!",
    "AfterPrimalReversion_GROUDON_foe" => "¡{1}!\n¡Deja que la tierra se resquebraje bajo tu poderosa presencia!",
    "AfterPrimalReversion_WATER_foe"   => "¡Inunda el mundo con tu majestuosidad!",
    "AfterPrimalReversion_GROUND_foe"  => "¡Destroza el mundo con tu majestuosidad!"

  }
  
  
################################################################################
# Example demo of a generic capture tutorial battle.
################################################################################

  #-----------------------------------------------------------------------------
  # Suggested Battle Rules:
  #-----------------------------------------------------------------------------
  #   "autoBattle"
  #   "alwaysCapture"
  #   "tutorialCapture"
  #   "tempPlayer"
  #   "tempParty"
  #   "noExp"
  #-----------------------------------------------------------------------------
  
  DEMO_CAPTURE_TUTORIAL = {
    #---------------------------------------------------------------------------
    # General speech events.
    #---------------------------------------------------------------------------
    "RoundStartCommand_player"  => "¡Ey! ¡Un Pokémon salvaje!\n¡Presta atención ahora! Te mostraré cómo capturar uno para ti mismo!",
    "BeforeDamagingMove_player" => ["¡Debilitar a un Pokémon en batalla los hace mucho más fáciles de atrapar!",
                                    "¡Pero ten cuidado! ¡No querrás derrotarlos por completo!\n¡Perderás tu oportunidad si lo haces!",
                                    "Intentemos infligir algo de daño.\n¡Ve por ellos, {1}!"],
    "BattlerStatusChange_foe"   => [:Opposing, "¡Siempre es una buena idea infligir condiciones de estado como el Sueño o la Parálisis!",
                                    "¡Esto realmente ayudará a mejorar tus probabilidades de capturar al Pokémon!"],

    #---------------------------------------------------------------------------
    # Turn 1 - Uses a status move on the opponent, if possible.
    #---------------------------------------------------------------------------
    "TurnStart_player" => {
      "useMove"      => "Status_foe",
      "setBattler"   => :Opposing,
      "battlerHPCap" => -1
    },
    #---------------------------------------------------------------------------
    # Continuous - Checks if the wild Pokemon's HP is low. If so, initiates the
    #              capture sequence.
    #---------------------------------------------------------------------------
    "RoundEnd_player_repeat" => {
      "ignoreUntil" => ["TargetTookDamage_foe", "RoundEnd_player_2"],
      "speech_A"    => "¡El Pokémon está débil!\n¡Es el momento de lanzar una Poké Ball!",
      "useItem"     => :POKEBALL,
      "speech_B"    => "¡Muy bien, así es como se hace!"
    }
  }
  
  
################################################################################
# Demo scenario vs. wild Rotom that shifts forms.
################################################################################
  
  DEMO_WILD_ROTOM = {
    #---------------------------------------------------------------------------
    # Turn 1 - Disables Poke Balls from being used.
    #---------------------------------------------------------------------------
    "RoundStartCommand_1_foe" => {
      "text_A"       => "{1} emited a powerful magnetic pulse!",
      "playAnim"     => [:CHARGE, :Self, :Self],
      "playSE"       => "Anim/Paralyze3",
      "text_B"       => "¡Tus Poké Ball se cortocircuitaron!\n¡No se pueden usar en esta batalla!",
      "disableBalls" => true
    },
    #---------------------------------------------------------------------------
    # Continuous - Shifts into random form, heals HP/status, and gains new item/ability.
    #---------------------------------------------------------------------------
    "RoundEnd_foe_repeat" => {
      "ignoreUntil"    => "TargetWeakToMove_foe",
      "playAnim"       => [:NIGHTMARE, :Opposing, :Self],
      "battlerForm"    => [:Random, "¡{1} ha poseído un nuevo electrodoméstico!"],
      "battlerHP"      => 4,
      "battlerStatus"  => :NONE,
      "battlerAbility" => [:MOTORDRIVE, true],
      "battlerItem"    => [:CELLBATTERY, "¡{1} equipó una Batería Celular que encontró en el electrodoméstico!"]
      
    },
    #---------------------------------------------------------------------------
    # When Rotom's HP drops to 50% or lower, applies Charge, Magnet Rise, and Electric Terrain.
    #---------------------------------------------------------------------------
    "TargetHPHalf_foe" => {
	  "playAnim"       => [:CHARGE, :Self, :Self],
      "battlerEffects" => [
        [:Charge,     5, "¡{1} comenzó a cargar poder!"],
        [:MagnetRise, 5, "¡{1} se elevó con electromagnetismo!"],        
      ],
      "changeTerrain"  => :Electric
    },
    #---------------------------------------------------------------------------
    # Player's Pokemon becomes paralyzed after dealing supereffective damage. 
    #---------------------------------------------------------------------------
    "UserMoveEffective_player_repeat" => {
      "text" => [:Opposing, "¡{1} emitió un pulso eléctrico por desesperación!"],
      "battlerStatus" => [:PARALYSIS, true]
    }
  }
  

################################################################################
# Demo scenario vs. Rocket Grunt in a collapsing cave.
################################################################################  
  
  #-----------------------------------------------------------------------------
  # Suggested Battle Rules:
  #-----------------------------------------------------------------------------
  #   "noMoney"
  #   "canLose"
  #-----------------------------------------------------------------------------
  
  DEMO_COLLAPSING_CAVE = {
    #---------------------------------------------------------------------------
    # Turn 1 - Battle intro.
    #---------------------------------------------------------------------------
    "RoundStartCommand_1_foe" => {
      "playSE"  => "Mining collapse",
      "text_A"  => "¡El techo de la cueva comienza a derrumbarse a tu alrededor!",
      "speech"  => ["¡No voy a dejarte escapar!", "¡No me importa si esta cueva se derrumba sobre los dos... jaja!"],
      "text_B"  => "¡Derrota a tu oponente antes de que se acabe el tiempo!",      
    },
    #---------------------------------------------------------------------------
    # Continuous - Text event at the end of each turn.
    #---------------------------------------------------------------------------
    "RoundEnd_player_repeat" => {
      "playSE" => "Mining collapse",
      "text"   => "¡La cueva sigue derrumbándose a tu alrededor!",
    },
    #---------------------------------------------------------------------------
    # Turn 2 - Player's Pokemon takes damage and becomes confused.
    #---------------------------------------------------------------------------
    "RoundEnd_2_player" => {
      "text"          => "¡{1} fue golpeado en la cabeza por una roca que cayó!",
      "playAnim"      => [:ROCKSMASH, :Opposing, :Self],
      "battlerHP"     => -4,
      "battlerStatus" => :CONFUSED
    },
    #---------------------------------------------------------------------------
    # Turn 3 - Text event.
    #---------------------------------------------------------------------------
    "RoundEnd_3_player" => {
      "text" => ["¡Te estás quedando sin tiempo!", "¡Necesitas escapar inmediatamente!"],
    },
    #---------------------------------------------------------------------------
    # Turn 4 - Battle prematurely ends in a loss.
    #---------------------------------------------------------------------------
    "RoundEnd_4_player" => {
      "text_A"    => "¡No has logrado derrotar a tu oponente a tiempo!",
      "playAnim"  => ["Recall", :Self],
      "text_B"    => "¡Te has visto obligado a huir de la batalla!",      
      "playSE"    => "Battle flee",
      "endBattle" => 3
    },
    #---------------------------------------------------------------------------
    # Opponent's final Pokemon is healed and increases its defenses when HP is low.
    #---------------------------------------------------------------------------
    "LastTargetHPLow_foe" => {
      "speech"       => "¡Mi {1} nunca se rendirá!",
      "endSpeech"    => true,
      "playAnim"     => [:BULKUP, :Self],
      "playCry"      => :Self,
      "battlerHP"    => [2, "¡{1} está defendiendo su posición!"],
      "battlerStats" => [:DEFENSE, 2, :SPECIAL_DEFENSE, 2]
    },
    #---------------------------------------------------------------------------
    # Speech event upon losing the battle.
    #---------------------------------------------------------------------------
    "BattleEndForfeit" => "Ja, ja... ¡nunca saldrás con vida de aquí!",
  }
  
  
################################################################################
# Demo scenario vs. Battle Quizmaster.
################################################################################ 
  
  #-----------------------------------------------------------------------------
  # Suggested Battle Rules:
  #-----------------------------------------------------------------------------
  #   "canLose"
  #   "noExp"
  #   "noMoney"
  #-----------------------------------------------------------------------------
  
  DEMO_BATTLE_QUIZMASTER = {
    #---------------------------------------------------------------------------
    # Intro speech event.
    #---------------------------------------------------------------------------
    "RoundStartCommand_1_foe" => {
      "speech_A" => ["¡Bienvenidos a otro episodio de Pokémon Battle Quiz!",
               "¡El programa donde los entrenadores deben luchar con Pokémon y preguntas al mismo tiempo!",
               "¡Ganas un punto cada vez que respondes correctamente a una pregunta, y un punto extra si derrotas a un Pokémon!",
               "¡Si puedes alcanzar seis puntos en seis turnos, ganas un premio!",
               "¿Está nuestro nuevo retador preparado para la tarea? ¡Hagamos ruido para \\PN!"],
      "playSE"   => "Anim/Applause", 
      "speech_B" => "¡Ahora, \\PN!\n¡Comencemos!",
    },
    #---------------------------------------------------------------------------
    # Speech events.
    #---------------------------------------------------------------------------
    "Variable_1" => {
      "playSE" => "Pkmn move learnt",
      "speech" => "¡Te has ganado tu primer punto!\n¡Mantén la vista en el premio!",
    },
    "Variable_2" => {
      "playSE" => "Pkmn move learnt",
      "speech" => "¡Dos puntos, no está mal!\n¿Podrá nuestro nuevo retador seguir así?",
    },
    "Variable_3" => {
      "playSE" => "Pkmn move learnt",
      "speech" => "¡Has reclamado tu tercer punto!\n¡Estás que ardes! ¡Sigue así, chaval!",
    },
    "Variable_4" => {
      "playSE" => "Pkmn move learnt",
      "speech" => "¡Cuatro puntos en el marcador!\n¿Crees que tienes lo necesario para ganar?",
    },
    "Variable_5" => {
      "playSE" => "Pkmn move learnt",
      "speech" => "¡Solo falta un punto más!\n¿Podrá nuestra futura estrella lograr una partida perfecta?",
    },
    "BattleEndLoss" => "Buen intento, chaval. ¡Pasemos al siguiente retador!",
    #---------------------------------------------------------------------------
    # Automatically ends the battle as a win if enough points have been earned.
    #---------------------------------------------------------------------------
    "VariableOver_5" => {
      "playSE_A"  => "Pkmn move learnt",
      "speech"    => ["¡Y ahí lo tienen, gente! ¡El punto número seis!",
                      "¿Sabes lo que eso significa? ¡Parece que tenemos un ganador!",
                      "¡Aplausos para nuestro nuevo As de Batalla en el Quiz - \\PN!"],
      "playSE_B"  => "Anim/Applause",
      "text"      => "¡Te inclinas graciosamente ante el público y recibes un estallido de aplausos!",
      "endBattle" => 1
    },
    #---------------------------------------------------------------------------
    # Continuous - Adds a bonus point whenever the opponent's Pokemon is KO'd.
    #---------------------------------------------------------------------------
    "BattlerFainted_foe_repeat" => {
      "addVariable" => 1
    },
    #---------------------------------------------------------------------------
    # Continuous - Opponent's final Pokemon always Endures damaging moves.
    #---------------------------------------------------------------------------
    "BeforeDamagingMove_player_repeat" => {
      "ignoreUntil"    => "AfterLastSwitchIn_foe",
      "setBattler"     => :Opposing,
      "battlerEffects" => [:Endure, true]
    },
    #---------------------------------------------------------------------------
    # Turn 1 - Multiple choice question (Region).
    #---------------------------------------------------------------------------
    "RoundEnd_1_foe" => {
      "playSE"     => "Voltorb Flip gain coins",
      "setChoices" => [:region, 3, {
                        "Kalos" => "¡Ay, eso es un fallo, amigo!",
                        "Johto" => "¡Cerca! Bueno, al menos geográficamente hablando...",
                        "Kanto" => "¡Ah, el buen Kanto!\n¡Qué clásico! ¡Correcto!",
                        "Galar" => "¡A menos que seas el Campeón Leon, eso es incorrecto!\n¡Me temo que NO estás teniendo un tiempo de campeón!"
                      }],
      "speech"     => ["¡Hora de nuestra primera pregunta!",
                      "¿En qué región los nuevos entrenadores suelen tener la opción de seleccionar a Charmander como su primer Pokémon?", :Choices]
    },
    "ChoiceRight_region" => {
      "addVariable"  => 1,
      "playSE"       => "Anim/Applause",
      "text"         => "¡La multitud aplaudió cortésmente para ti!",
      "setBattler"   => :Opposing,
      "battlerStats" => [:ACCURACY, 1]
    },
    "ChoiceWrong_region" => {
      "setBattler"     => :Opposing,
      "battlerStats"   => [:ACCURACY, -2],
      "battlerEffects" => [:NoRetreat, true, "{1} ¡se puso nervioso!\n¡Ya no podrá escapar!"]
    },
    #---------------------------------------------------------------------------
    # Turn 2 - Multiple choice question (Poke Ball).
    #---------------------------------------------------------------------------
    "RoundEnd_2_foe" => {
      "playSE"     => "Voltorb Flip gain coins",
      "setChoices" => [:pokeball, 4, {
                        "Rapid Ball"  => "Quizás fuiste un poco rápido para responder, ¡porque me temo que eso es incorrecto!",
                        "Amor Ball"  => "Lo siento por romperte el corazón, ¡pero eso es incorrecto!",
                        "Veloz Ball" => "¡Ah, eres alguien ingenioso...\n¡Pero desafortunadamente, no lo suficientemente rápido! ¡Estás incorrecto!",
                        "Heavy Ball" => "¡Ni siquiera una Heavy Ball podría contener ese enorme cerebro tuyo! ¡Estás correcto!"
                      }],
      "speech"     => ["¡Es hora de nuestra segunda pregunta!",
                      "¿Qué tipo de Poké Ball sería más efectiva si se lanzara en el primer turno a un Metagross salvaje?", :Choices]
    },
    "ChoiceRight_pokeball" => {
      "addVariable" => 1,
      "playSE"      => "Anim/Applause",
      "text"        => "¡La multitud empezó a animarte para que ganaras!",
      "setBattler"  => :Opposing,
      "teamEffects" => [:LuckyChant, 5, "¡El Canto de la Suerte protege a {1} de los golpes críticos!"]
    },
    "ChoiceWrong_pokeball" => {
      "setBattler"   => :Opposing,
      "battlerMoves" => [:SPLASH, :METRONOME, nil, nil],
      "text"         => "¡{1} se sintió avergonzado y olvidó sus movimientos!"
    },

    #---------------------------------------------------------------------------
    # Turn 3 - Branching path question.
    #---------------------------------------------------------------------------
    "RoundEnd_3_foe" => {
      "setChoices" => [:topic, nil, "Battling", "Evolution", "Breeding"],
      "speech"     => ["¡Ah, hemos llegado a nuestra ronda comodín!",
                      "Esta vez, puedes elegir uno de tres temas relacionados con Pokémon.",
                      "Nuestro Quiz-A-Tron 3000 generará entonces una pregunta difícil relacionada con el tema que elijas.",
                      "Esta será una pregunta simple de sí o no, ¡pero valdrá dos puntos, así que elige sabiamente!",
                      "Entonces, ¿qué tema será?", :Choices,
                      "¡Elección interesante!",
                      "Veamos qué nos ofrece nuestro Quiz-A-Tron!"],
      "endSpeech"  => true,
      "playSE"     => "PC Access",
      "text"       => "El Quiz-A-Tron 3000 emite pitidos y zumbidos mientras imprime una pregunta."
    },
    #---------------------------------------------------------------------------
    # Branch 1 - Multiple choice question (Battle).
    #---------------------------------------------------------------------------
    "Choice_topic_1" => {
      "playSE"     => "Voltorb Flip gain coins",
      "setChoices" => [:battling, 2, {
                        "Sí" => "Lo siento. Supongo que no todos pueden tener un Don Natural para los concursos...",
                        "No"  => "¡Hey, parece que tienes un Don Natural para esto!"
                      }],
      "speech"     => ["¡Hora de la pregunta!",
                      "¿El movimiento Naturaleza Cambiante se convertiría en un movimiento de tipo Hielo si el usuario tiene equipada una Baya Ziuela?", :Choices]
    },
    "ChoiceRight_battling" => {
      "addVariable"  => 2,
      "playSE"       => "Anim/Applause",
      "text"         => "¡La multitud rugió de emoción!",
      "setBattler"   => :Opposing,
      "battlerHP"    => [1, "{1} ¡se llenó de energía con los vítores de la multitud!"],
      "battlerStats" => [:ATTACK, 1, :SPECIAL_ATTACK, 1]
    },
    "ChoiceWrong_battling" => {
      "setBattler"   => :Opposing,
      "text"         => "{1} se desanimó por el silencio de la multitud...",
      "battlerStats" => [:ATTACK, -2, :SPECIAL_ATTACK, -2]
    },
    #---------------------------------------------------------------------------
    # Branch 2 - Multiple choice question (Evolution).
    #---------------------------------------------------------------------------
    "Choice_topic_2" => {
      "playSE"     => "Voltorb Flip gain coins",
      "setChoices" => [:evolution, 1, {
                        "Sí"  => "¡Era crucial que acertaras esa pregunta! ¡Buen trabajo!",
                        "No"  => "¡Oh no! Deberías haber pensado esa pregunta de manera más crítica..."
                      }],
      "speech"     => ["¡Hora de la pregunta!",
                       "¿Sería útil de alguna manera tener un objeto Puerro para ayudar a evolucionar a un Farfetch'd de Galar?", :Choices]
    },
    "ChoiceRight_evolution" => {
      "addVariable"  => 2,
      "playSE"       => "Anim/Applause",
      "text"         => "¡La multitud rugió de emoción!",
      "setBattler"   => :Opposing,
      "battlerHP"    => [1, "{1} ¡se llenó de energía con los vítores de la multitud!"],
      "battlerStats" => [:SPEED, 1, :EVASION, 1]
    },
    "ChoiceWrong_evolution" => {
      "setBattler"   => :Opposing,
      "text"         => "{1} se desanimó por el silencio de la multitud...",
      "battlerStats" => [:SPEED, -2, :EVASION, -2]
    },
    #---------------------------------------------------------------------------
    # Branch 3 - Multiple choice question (Breeding).
    #---------------------------------------------------------------------------
    "Choice_topic_3" => {
      "playSE"     => "Voltorb Flip gain coins",
      "setChoices" => [:breeding, 1, {
                        "Sí"  => "¡Vaya! ¡Respondiste a esa pregunta sin despeinarte!",
                        "No"  => "¡Ay! Parece que te dejaste vencer por esa pregunta..."
	                    }],
      "speech"     => ["¡Hora de la pregunta!",
                       "¿Es capaz Illumise de producir huevos de una especie diferente a la suya?", :Choices]
    },
    "ChoiceRight_breeding" => {
      "addVariable"  => 2,
      "playSE"       => "Anim/Applause",
      "text"         => "¡La multitud rugió de emoción!",
      "setBattler"   => :Opposing,
      "battlerHP"    => [1, "¡{1} se llenó de energía con los vítores de la multitud!"],
      "battlerStats" => [:DEFENSE, 1, :SPECIAL_DEFENSE, 1]
    },
    "ChoiceWrong_breeding" => {
      "setBattler"   => :Opposing,
      "text"         => "{1} se desanimó por el silencio de la multitud...",
      "battlerStats" => [:DEFENSE, -2, :SPECIAL_DEFENSE, -2]
    },
    #---------------------------------------------------------------------------
    # Turn 4 - Final question. 
    #---------------------------------------------------------------------------
    "RoundEnd_4_foe" => {
      "speech_A"   => ["¡Me temo que hemos llegado a nuestra última ronda de preguntas!",
                       "¿Podrá nuestro retador ganar aquí?\n¡Vamos a averiguarlo!"],
      "playSE"     => "Voltorb Flip gain coins",
      "setChoices" => [:final, 1, {
                        "Pulsa la tecla Cntrl"     => "¡Sí, es Ctrl! ¡Lo has conseguido!\n¡Oye, debes ser un profesional en esto!",
                        "Pulsa la tecla Shift"     => "¡Cerca! ¡Mantener pulsado Shift solo volverá a compilar los complementos!\n¡La tecla correcta es Ctrl!",
                        "Sujetar tu cara y llorar" => "¿Eh? Vamos, no es tan difícil... Simplemente mantén pulsada la tecla Ctrl.",
                        "Preguntarle a alguien"    => "Bueno, ahora no tendrás que hacerlo, porque la respuesta es 'Mantén pulsada la tecla Ctrl'."
                      }],
      "speech_B"   => ["Aquí está, la pregunta final:",
                      "Cuando cargas Pokémon Essentials en modo Debug y la ventana del juego está en foco, ¿cómo activas manualmente el juego para que se vuelva a compilar?", :Choices]
   },
    "ChoiceRight_final" => {
      "addVariable" => 1,
      "playSE"      => "Anim/Applause",
      "text"        => "¡La multitud te ovacionó de pie!"
    },
    "ChoiceWrong_final" => {
      "text"       => "Puedes escuchar murmullos decepcionados de la multitud...",
      "setBattler" => :Opposing,
      "battlerHP"  => [0, "{1} se desmayó de vergüenza..."]
    },
    #---------------------------------------------------------------------------
    # Turn 6 - Ends the battle as a loss if not enough points have been earned.
    #---------------------------------------------------------------------------
    "RoundEnd_6_foe" => {
      "playSE_A"   => "Slots stop",
      "speech_A"   => ["¡Oh no! Ese sonido significa que hemos llegado al final de nuestro juego...",
                       "Nuestro retador \\PN mostró mucho potencial, pero se quedó un poco corto al final.",
                       "Pero aún así, ¡nos divertimos, ¿verdad, amigos?"], 
      "playSE_B"   => "Anim/Aplausos",
      "speech_B"   => "¡Así es! Bueno, ¡eso es todo por hoy!\n¡Haz una reverencia, \\PN! ¡Tú y tus Pokémon lucharon con fuerza!",
      "text"       => "Te inclinas torpemente ante el público mientras el personal comienza a dirigirte fuera del escenario...",
      "endBattle"  => 2
    }
  }
end