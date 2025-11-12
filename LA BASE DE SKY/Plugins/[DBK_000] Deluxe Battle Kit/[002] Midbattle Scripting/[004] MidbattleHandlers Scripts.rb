#===============================================================================
# Hardcoded Midbattle Scripts
#===============================================================================
# You may add Midbattle Handlers here to create custom battle scripts you can
# call on. Unlike other methods of creating battle scripts, you can use these
# handlers to freely hardcode what you specifically want to happen in battle
# instead of the other methods which require specific values to be inputted.
#
# This method requires fairly solid scripting knowledge, so it isn't recommended
# for inexperienced users. As with other methods of calling midbattle scripts,
# you may do so by setting up the "midbattleScript" battle rule.
#
# 	For example:  
#   setBattleRule("midbattleScript", :demo_capture_tutorial)
#
#   *Note that the symbol entered must be the same as the symbol that appears as
#    the second argument in each of the handlers below. This may be named whatever
#    you wish.
#-------------------------------------------------------------------------------

################################################################################
# Demo scenario vs. wild Rotom that shifts forms.
################################################################################

MidbattleHandlers.add(:midbattle_scripts, :demo_wild_rotom,
  proc { |battle, idxBattler, idxTarget, trigger|
    foe = battle.battlers[1]
    logname = _INTL("{1} ({2})", foe.pbThis(true), foe.index)
    case trigger
    #---------------------------------------------------------------------------
    # The player's Poke Balls are disabled at the start of the first round.
    when "RoundStartCommand_1_foe"
      PBDebug.log("[Midbattle Script] '#{trigger}' triggered by #{logname}...")
      battle.pbDisplayPaused(_INTL("{1} emitió un poderoso pulso magnético!", foe.pbThis))
      battle.pbAnimation(:CHARGE, foe, foe)
      pbSEPlay("Anim/Paralyze3")
      battle.pbDisplayPaused(_INTL("¡Tus Poké Ball se cortocircuitaron!\n¡No pueden ser utilizadas en esta batalla!"))
      battle.disablePokeBalls = true
      PBDebug.log("[Midbattle Script] '#{trigger}' effects ended")
    #---------------------------------------------------------------------------
    # After taking Super Effective damage, the opponent changes form each round.
    when "RoundEnd_foe"
      next if !battle.pbTriggerActivated?("TargetWeakToMove_foe")
      PBDebug.log("[Midbattle Script] '#{trigger}' triggered by #{logname}...")
      battle.pbAnimation(:NIGHTMARE, foe.pbDirectOpposing(true), foe)
      form = battle.pbRandom(1..5)
      foe.pbSimpleFormChange(form, _INTL("{1} poseyó un nuevo aparato!", foe.pbThis))
      foe.pbRecoverHP(foe.totalhp / 4)
      foe.pbCureAttract
      foe.pbCureConfusion
      foe.pbCureStatus
      if foe.ability_id != :MOTORDRIVE
        battle.pbShowAbilitySplash(foe, true, false)
        foe.ability = :MOTORDRIVE
        battle.pbReplaceAbilitySplash(foe)
        battle.pbDisplay(_INTL("¡{1} adquirió {2}!", foe.pbThis, foe.abilityName))
        battle.pbHideAbilitySplash(foe)
      end
      if foe.item_id != :CELLBATTERY
        foe.item = :CELLBATTERY
        battle.pbDisplay(_INTL("¡{1} se equipó una {2} que encontró en el electrodoméstico!", foe.pbThis, foe.itemName))
      end
      PBDebug.log("[Midbattle Script] '#{trigger}' effects ended")
    #---------------------------------------------------------------------------
    # Opponent gains various effects when its HP falls to 50% or lower.
    when "TargetHPHalf_foe"
      next if battle.pbTriggerActivated?(trigger)
      PBDebug.log("[Midbattle Script] '#{trigger}' triggered by #{logname}...")
      battle.pbAnimation(:CHARGE, foe, foe)
      if foe.effects[PBEffects::Charge] <= 0
        foe.effects[PBEffects::Charge] = 5
        battle.pbDisplay(_INTL("¡{1} comenzó a cargar energía!", foe.pbThis))
      end
      if foe.effects[PBEffects::MagnetRise] <= 0
        foe.effects[PBEffects::MagnetRise] = 5
        battle.pbDisplay(_INTL("¡{1} levitó con electromagnetismo!", foe.pbThis))
      end
      battle.pbStartTerrain(foe, :Electric)
      PBDebug.log("[Midbattle Script] '#{trigger}' effects ended")
    #---------------------------------------------------------------------------
    # Opponent paralyzes the player's Pokemon when taking Super Effective damage.
    when "UserMoveEffective_player"
      PBDebug.log("[Midbattle Script] '#{trigger}' triggered by #{logname}...")
      battle.pbDisplayPaused(_INTL("¡{1} emitió un pulso eléctrico por desesperación!", foe.pbThis))
      battler = battle.battlers[idxBattler]
      if battler.pbCanInflictStatus?(:PARALYSIS, foe, true)
        battler.pbInflictStatus(:PARALYSIS)
      end
      PBDebug.log("[Midbattle Script] '#{trigger}' effects ended")
    end
  }
)


################################################################################
# Demo scenario vs. Rocket Grunt in a collapsing cave.
################################################################################

MidbattleHandlers.add(:midbattle_scripts, :demo_collapsing_cave,
  proc { |battle, idxBattler, idxTarget, trigger|
    scene = battle.scene
    battler = battle.battlers[idxBattler]
    logname = _INTL("{1} ({2})", battler.pbThis(true), battler.index)
    case trigger
    #---------------------------------------------------------------------------
    # Introduction text explaining the event.
    when "RoundStartCommand_1_foe"
      PBDebug.log("[Midbattle Script] '#{trigger}' triggered by #{logname}...")
      pbSEPlay("Mining collapse")
      battle.pbDisplayPaused(_INTL("¡El techo de la cueva comienza a derrumbarse a tu alrededor!"))
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("¡No voy a dejarte escapar!"))
      battle.pbDisplayPaused(_INTL("No me importa si toda esta cueva se derrumba sobre ambos... ¡jaja!"))
      scene.pbForceEndSpeech
      battle.pbDisplayPaused(_INTL("¡Derrota a tu oponente antes de que se acabe el tiempo!"))      
      PBDebug.log("[Midbattle Script] '#{trigger}' effects ended")
    #---------------------------------------------------------------------------
    # Repeated end-of-round text.
    when "RoundEnd_player"
      PBDebug.log("[Midbattle Script] '#{trigger}' triggered by #{logname}...")
      pbSEPlay("Mining collapse")
      battle.pbDisplayPaused(_INTL("¡La cueva sigue derrumbándose a tu alrededor!"))
      PBDebug.log("[Midbattle Script] '#{trigger}' effects ended")
    #---------------------------------------------------------------------------
    # Player's Pokemon is struck by falling rock, dealing damage & causing confusion.
    when "RoundEnd_2_player"
      PBDebug.log("[Midbattle Script] '#{trigger}' triggered by #{logname}...")
      battle.pbDisplayPaused(_INTL("¡{1} fue golpeado en la cabeza por una roca que caía!", battler.pbThis))
      battle.pbAnimation(:ROCKSMASH, battler.pbDirectOpposing(true), battler)
      old_hp = battler.hp
      battler.hp -= (battler.totalhp / 4).round
      scene.pbHitAndHPLossAnimation([[battler, old_hp, 0]])
      if battler.fainted?
        battler.pbFaint(true)
      elsif battler.pbCanConfuse?(battler, false)
        battler.pbConfuse
      end
    #---------------------------------------------------------------------------
    # Warning message.
    when "RoundEnd_3_player"
      battle.pbDisplayPaused(_INTL("¡Te estás quedando sin tiempo!"))
      battle.pbDisplayPaused(_INTL("¡Necesitas escapar inmediatamente!"))      
    #---------------------------------------------------------------------------
    # Player runs out of time and is forced to forfeit.
    when "RoundEnd_4_player"
      battle.pbDisplayPaused(_INTL("¡Fallaste en derrotar a tu oponente a tiempo!"))
      scene.pbRecall(idxBattler)
      battle.pbDisplayPaused(_INTL("¡Te viste obligado/a a huir de la batalla!"))      
      pbSEPlay("Battle flee")
      battle.decision = 3
    #---------------------------------------------------------------------------
    # Opponent's Pokemon stands its ground when its HP is low.
    when "LastTargetHPLow_foe"
      next if battle.pbTriggerActivated?(trigger)
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("¡Mi {1} nunca se rendirá!", battler.name))
      scene.pbForceEndSpeech
      battle.pbAnimation(:BULKUP, battler, battler)
      battler.displayPokemon.play_cry
      battler.pbRecoverHP(battler.totalhp / 2)
      battle.pbDisplayPaused(_INTL("¡{1} está defendiendo su posición!", battler.pbThis))      
      showAnim = true
      [:DEFENSE, :SPECIAL_DEFENSE].each do |stat|
        next if !battler.pbCanRaiseStatStage?(stat, battler)
        battler.pbRaiseStatStage(stat, 2, battler, showAnim)
        showAnim = false
      end
      PBDebug.log("[Midbattle Script] '#{trigger}' effects ended")
    #---------------------------------------------------------------------------
    # Opponent mocks the player when forfeiting the match.
    when "BattleEndForfeit"
      PBDebug.log("[Midbattle Script] '#{trigger}' triggered by #{logname}...")
      scene.pbStartSpeech(1)
      battle.pbDisplayPaused(_INTL("Ja, ja... ¡nunca saldrás con vida!"))
      PBDebug.log("[Midbattle Script] '#{trigger}' effects ended")
    end
  }
)


#===============================================================================
# Global Midbattle Scripts
#===============================================================================
# Global midbattle scripts are always active and will affect all battles as long
# as the conditions for the scripts are met. These are not set in a battle rule,
# and are instead triggered passively in any battle.
#-------------------------------------------------------------------------------

################################################################################
# Used for wild Mega battles.
################################################################################

MidbattleHandlers.add(:midbattle_global, :wild_mega_battle,
  proc { |battle, idxBattler, idxTarget, trigger|
    next if !battle.wildBattle?
    next if battle.wildBattleMode != :mega
    foe = battle.battlers[1]
    next if !foe.wild?
    logname = _INTL("{1} ({2})", foe.pbThis, foe.index)
    case trigger
    #---------------------------------------------------------------------------
    # Mega Evolves wild battler immediately at the start of the first round.
    when "RoundStartCommand_1_foe"
      if battle.pbCanMegaEvolve?(foe.index)
        PBDebug.log("[Midbattle Global] #{logname} will Mega Evolve")
        battle.pbMegaEvolve(foe.index)
        battle.disablePokeBalls = true
        battle.sosBattle = false if defined?(battle.sosBattle)
        battle.totemBattle = nil if defined?(battle.totemBattle)
        foe.damageThreshold = 20
      else
        battle.wildBattleMode = nil
      end
    #---------------------------------------------------------------------------
    # Un-Mega Evolves wild battler once damage cap is reached.
    when "BattlerReachedHPCap_foe"
      PBDebug.log("[Midbattle Global] #{logname} damage cap reached")
      foe.unMega
      battle.disablePokeBalls = false
      battle.pbDisplayPaused(_INTL("¡La Megaevolución de {1} se desvaneció!\n¡Ahora puede ser capturado!", foe.pbThis))
    #---------------------------------------------------------------------------
    # Tracks player's win count.
    when "BattleEndWin"
      if battle.wildBattleMode == :mega
        $stats.wild_mega_battles_won += 1
      end
    end
  }
)


################################################################################
# Plays low HP music when the player's Pokemon reach critical health.
################################################################################

MidbattleHandlers.add(:midbattle_global, :low_hp_music,
  proc { |battle, idxBattler, idxTarget, trigger|
    next if !Settings::PLAY_LOW_HP_MUSIC
    battler = battle.battlers[idxBattler]
    next if !battler || !battler.pbOwnedByPlayer?
    track = battle.pbGetBattleLowHealthBGM
    next if !track.is_a?(RPG::AudioFile)
    playingBGM = battle.playing_bgm
    case trigger
    #---------------------------------------------------------------------------
    # Restores original BGM when HP is restored to healthy.
    when "BattlerHPRecovered_player"
      next if playingBGM != track.name
      next if battle.pbAnyBattlerLowHP?(idxBattler)
      battle.pbResumeBattleBGM
      PBDebug.log("[Midbattle Global] low HP music ended")
    #---------------------------------------------------------------------------
    # Restores original BGM when battler is fainted.
    when "BattlerHPReduced_player"
      next if playingBGM != track.name
	    next if battle.pbAnyBattlerLowHP?(idxBattler)
      next if !battler.fainted?
      battle.pbResumeBattleBGM
      PBDebug.log("[Midbattle Global] low HP music ended")
    #---------------------------------------------------------------------------
    # Plays low HP music when HP is critical.
    when "BattlerHPCritical_player"
      next if playingBGM == track.name
      battle.pbPauseAndPlayBGM(track)
      PBDebug.log("[Midbattle Global] low HP music begins")
    #---------------------------------------------------------------------------
    # Restores original BGM when sending out a healthy Pokemon.
    # Plays low HP music when sending out a Pokemon with critical HP.
    when "AfterSendOut_player"
      if battle.pbAnyBattlerLowHP?(idxBattler)
        next if playingBGM == track.name
        battle.pbPauseAndPlayBGM(track)
        PBDebug.log("[Midbattle Global] low HP music begins")
      elsif playingBGM == track.name
        battle.pbResumeBattleBGM
        PBDebug.log("[Midbattle Global] low HP music ended")
      end
    end
  }
)