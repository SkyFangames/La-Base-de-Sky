#===============================================================================
#
#===============================================================================
module Battle::AbilityEffects
  SpeedCalc                        = AbilityHandlerHash.new
  WeightCalc                       = AbilityHandlerHash.new
  # Battler's HP/stat changed
  OnHPDroppedBelowHalf             = AbilityHandlerHash.new
  # Battler's status problem
  StatusCheckNonIgnorable          = AbilityHandlerHash.new   # Comatose
  StatusImmunity                   = AbilityHandlerHash.new
  StatusImmunityNonIgnorable       = AbilityHandlerHash.new
  StatusImmunityFromAlly           = AbilityHandlerHash.new
  OnStatusInflicted                = AbilityHandlerHash.new   # Synchronize
  StatusCure                       = AbilityHandlerHash.new
  # Battler's stat stages
  StatLossImmunity                 = AbilityHandlerHash.new
  StatLossImmunityNonIgnorable     = AbilityHandlerHash.new   # Full Metal Body
  StatLossImmunityFromAlly         = AbilityHandlerHash.new   # Flower Veil
  OnStatGain                       = AbilityHandlerHash.new   # None!
  OnStatLoss                       = AbilityHandlerHash.new
  # Priority and turn order
  PriorityChange                   = AbilityHandlerHash.new
  PriorityBracketChange            = AbilityHandlerHash.new   # Stall
  PriorityBracketUse               = AbilityHandlerHash.new   # None!
  # Move usage failures
  OnFlinch                         = AbilityHandlerHash.new   # Steadfast
  MoveBlocking                     = AbilityHandlerHash.new
  MoveImmunity                     = AbilityHandlerHash.new
  # Move usage
  ModifyMoveBaseType               = AbilityHandlerHash.new
  # Accuracy calculation
  AccuracyCalcFromUser             = AbilityHandlerHash.new
  AccuracyCalcFromAlly             = AbilityHandlerHash.new   # Victory Star
  AccuracyCalcFromTarget           = AbilityHandlerHash.new
  # Damage calculation
  DamageCalcFromUser               = AbilityHandlerHash.new
  DamageCalcFromAlly               = AbilityHandlerHash.new
  DamageCalcFromTarget             = AbilityHandlerHash.new
  DamageCalcFromTargetNonIgnorable = AbilityHandlerHash.new
  DamageCalcFromTargetAlly         = AbilityHandlerHash.new
  CriticalCalcFromUser             = AbilityHandlerHash.new
  CriticalCalcFromTarget           = AbilityHandlerHash.new
  # Upon a move hitting a target
  OnBeingHit                       = AbilityHandlerHash.new
  OnDealingHit                     = AbilityHandlerHash.new   # Poison Touch
  # Abilities that trigger at the end of using a move
  OnEndOfUsingMove                 = AbilityHandlerHash.new
  AfterMoveUseFromTarget           = AbilityHandlerHash.new
  # End Of Round
  EndOfRoundWeather                = AbilityHandlerHash.new
  EndOfRoundHealing                = AbilityHandlerHash.new
  EndOfRoundEffect                 = AbilityHandlerHash.new
  EndOfRoundGainItem               = AbilityHandlerHash.new
  # Switching and fainting
  CertainSwitching                 = AbilityHandlerHash.new   # None!
  TrappingByTarget                 = AbilityHandlerHash.new
  OnSwitchIn                       = AbilityHandlerHash.new
  OnSwitchOut                      = AbilityHandlerHash.new
  ChangeOnBattlerFainting          = AbilityHandlerHash.new
  OnBattlerFainting                = AbilityHandlerHash.new   # Soul-Heart
  OnTerrainChange                  = AbilityHandlerHash.new   # Mimicry
  OnIntimidated                    = AbilityHandlerHash.new   # Rattled (Gen 8)
  # Running from battle
  CertainEscapeFromBattle          = AbilityHandlerHash.new   # Run Away
  
  OnTypeChange            = AbilityHandlerHash.new  # Protean, Libero
  OnOpposingStatGain      = AbilityHandlerHash.new  # Opportunist
  ModifyTypeEffectiveness = AbilityHandlerHash.new  # Tera Shell (damage)
  OnMoveSuccessCheck      = AbilityHandlerHash.new  # Tera Shell (display)
  OnInflictingStatus      = AbilityHandlerHash.new  # Poison Puppeteer

  #=============================================================================

  def self.trigger(hash, *args, ret: false)
    new_ret = hash.trigger(*args)
    return (!new_ret.nil?) ? new_ret : ret
  end

  #=============================================================================

  def self.triggerSpeedCalc(ability, battler, mult)
    return trigger(SpeedCalc, ability, battler, mult, ret: mult)
  end

  def self.triggerWeightCalc(ability, battler, weight)
    return trigger(WeightCalc, ability, battler, weight, ret: weight)
  end

  #=============================================================================

  def self.triggerOnHPDroppedBelowHalf(ability, user, move_user, battle)
    return trigger(OnHPDroppedBelowHalf, ability, user, move_user, battle)
  end

  #=============================================================================

  def self.triggerStatusCheckNonIgnorable(ability, battler, status)
    return trigger(StatusCheckNonIgnorable, ability, battler, status)
  end

  def self.triggerStatusImmunity(ability, battler, status)
    return trigger(StatusImmunity, ability, battler, status)
  end

  def self.triggerStatusImmunityNonIgnorable(ability, battler, status)
    return trigger(StatusImmunityNonIgnorable, ability, battler, status)
  end

  def self.triggerStatusImmunityFromAlly(ability, battler, status)
    return trigger(StatusImmunityFromAlly, ability, battler, status)
  end

  def self.triggerOnStatusInflicted(ability, battler, user, status)
    OnInflictingStatus.trigger(user.ability, user, battler, status) if user && user.abilityActive? # Poison Puppeteer
    OnStatusInflicted.trigger(ability, battler, user, status)
  end

  def self.triggerStatusCure(ability, battler)
    return trigger(StatusCure, ability, battler)
  end

  #=============================================================================

  def self.triggerStatLossImmunity(ability, battler, stat, battle, show_messages)
    return trigger(StatLossImmunity, ability, battler, stat, battle, show_messages)
  end

  def self.triggerStatLossImmunityNonIgnorable(ability, battler, stat, battle, show_messages)
    return trigger(StatLossImmunityNonIgnorable, ability, battler, stat, battle, show_messages)
  end

  def self.triggerStatLossImmunityFromAlly(ability, bearer, battler, stat, battle, show_messages)
    return trigger(StatLossImmunityFromAlly, ability, bearer, battler, stat, battle, show_messages)
  end

  def self.triggerOnStatGain(ability, battler, stat, user)
    OnStatGain.trigger(ability, battler, stat, user)
  end

  def self.triggerOnStatLoss(ability, battler, stat, user)
    OnStatLoss.trigger(ability, battler, stat, user)
  end

  #=============================================================================

  def self.triggerPriorityChange(ability, battler, move, priority)
    return trigger(PriorityChange, ability, battler, move, priority, ret: priority)
  end

  def self.triggerPriorityBracketChange(ability, battler, battle)
    return trigger(PriorityBracketChange, ability, battler, battle, ret: 0)
  end

  def self.triggerPriorityBracketUse(ability, battler, battle)
    PriorityBracketUse.trigger(ability, battler, battle)
  end

  #=============================================================================

  def self.triggerOnFlinch(ability, battler, battle)
    OnFlinch.trigger(ability, battler, battle)
  end

  def self.triggerMoveBlocking(ability, bearer, user, targets, move, battle)
    return trigger(MoveBlocking, ability, bearer, user, targets, move, battle)
  end

  def self.triggerMoveImmunity(ability, user, target, move, type, battle, show_message)
    return trigger(MoveImmunity, ability, user, target, move, type, battle, show_message)
  end

  #=============================================================================

  def self.triggerModifyMoveBaseType(ability, user, move, type)
    return trigger(ModifyMoveBaseType, ability, user, move, type, ret: type)
  end

  #=============================================================================

  def self.triggerAccuracyCalcFromUser(ability, mods, user, target, move, type)
    AccuracyCalcFromUser.trigger(ability, mods, user, target, move, type)
  end

  def self.triggerAccuracyCalcFromAlly(ability, mods, user, target, move, type)
    AccuracyCalcFromAlly.trigger(ability, mods, user, target, move, type)
  end

  def self.triggerAccuracyCalcFromTarget(ability, mods, user, target, move, type)
    AccuracyCalcFromTarget.trigger(ability, mods, user, target, move, type)
  end

  #=============================================================================

  def self.triggerDamageCalcFromUser(ability, user, target, move, mults, power, type)
    DamageCalcFromUser.trigger(ability, user, target, move, mults, power, type)
  end

  def self.triggerDamageCalcFromAlly(ability, user, target, move, mults, power, type)
    DamageCalcFromAlly.trigger(ability, user, target, move, mults, power, type)
  end

  def self.triggerDamageCalcFromTarget(ability, user, target, move, mults, power, type)
    DamageCalcFromTarget.trigger(ability, user, target, move, mults, power, type)
  end

  def self.triggerDamageCalcFromTargetNonIgnorable(ability, user, target, move, mults, power, type)
    DamageCalcFromTargetNonIgnorable.trigger(ability, user, target, move, mults, power, type)
  end

  def self.triggerDamageCalcFromTargetAlly(ability, user, target, move, mults, power, type)
    DamageCalcFromTargetAlly.trigger(ability, user, target, move, mults, power, type)
  end

  def self.triggerCriticalCalcFromUser(ability, user, target, crit_stage)
    return trigger(CriticalCalcFromUser, ability, user, target, crit_stage, ret: crit_stage)
  end

  def self.triggerCriticalCalcFromTarget(ability, user, target, crit_stage)
    return trigger(CriticalCalcFromTarget, ability, user, target, crit_stage, ret: crit_stage)
  end

  #=============================================================================

  def self.triggerOnBeingHit(ability, user, target, move, battle)
    OnBeingHit.trigger(ability, user, target, move, battle)
  end

  def self.triggerOnDealingHit(ability, user, target, move, battle)
    OnDealingHit.trigger(ability, user, target, move, battle)
  end

  #=============================================================================

  def self.triggerOnEndOfUsingMove(ability, user, targets, move, battle)
    OnEndOfUsingMove.trigger(ability, user, targets, move, battle)
  end

  def self.triggerAfterMoveUseFromTarget(ability, target, user, move, switched_battlers, battle)
    AfterMoveUseFromTarget.trigger(ability, target, user, move, switched_battlers, battle)
  end

  #=============================================================================

  def self.triggerEndOfRoundWeather(ability, weather, battler, battle)
    EndOfRoundWeather.trigger(ability, weather, battler, battle)
  end

  def self.triggerEndOfRoundHealing(ability, battler, battle)
    EndOfRoundHealing.trigger(ability, battler, battle)
  end

  def self.triggerEndOfRoundEffect(ability, battler, battle)
    EndOfRoundEffect.trigger(ability, battler, battle)
  end

  def self.triggerEndOfRoundGainItem(ability, battler, battle)
    EndOfRoundGainItem.trigger(ability, battler, battle)
  end

  #=============================================================================

  def self.triggerCertainSwitching(ability, switcher, battle)
    return trigger(CertainSwitching, ability, switcher, battle)
  end

  def self.triggerTrappingByTarget(ability, switcher, bearer, battle)
    return trigger(TrappingByTarget, ability, switcher, bearer, battle)
  end

  def self.triggerOnSwitchIn(ability, battler, battle, switch_in = false)
    OnSwitchIn.trigger(ability, battler, battle, switch_in)
    battle.allSameSideBattlers(battler.index).each do |b|
      next if !b.hasActiveAbility?(:COMMANDER)
      next if b.effects[PBEffects::Commander]
      OnSwitchIn.trigger(b.ability, b, battle, switch_in)	  
    end
  end
  
  def self.triggerOnTypeChange(ability, battler, type)
    OnTypeChange.trigger(ability, battler, type)
  end
  
  def self.triggerOnOpposingStatGain(ability, battler, battle, statUps)
    OnOpposingStatGain.trigger(ability, battler, battle, statUps)
  end

  def self.triggerOnSwitchOut(ability, battler, end_of_battle)
    OnSwitchOut.trigger(ability, battler, end_of_battle)
  end
  
  def self.triggerModifyTypeEffectiveness(ability, user, target, move, battle, effectiveness)
    return trigger(ModifyTypeEffectiveness, ability, user, target, move, battle, effectiveness, ret: effectiveness)
  end
  
  def self.triggerOnMoveSuccessCheck(ability, user, target, move, battle)
    OnMoveSuccessCheck.trigger(ability, user, target, move, battle)
  end

  def self.triggerChangeOnBattlerFainting(ability, battler, fainted, battle)
    ChangeOnBattlerFainting.trigger(ability, battler, fainted, battle)
  end

  def self.triggerOnBattlerFainting(ability, battler, fainted, battle)
    OnBattlerFainting.trigger(ability, battler, fainted, battle)
  end

  def self.triggerOnTerrainChange(ability, battler, battle, ability_changed)
    OnTerrainChange.trigger(ability, battler, battle, ability_changed)
  end
  
  def self.triggerOnInflictingStatus(ability, battler, user, status)
    OnInflictingStatus.trigger(ability, battler, user, status)
  end

  def self.triggerOnIntimidated(ability, battler, battle)
    OnIntimidated.trigger(ability, battler, battle)
  end

  #=============================================================================

  def self.triggerCertainEscapeFromBattle(ability, battler)
    return trigger(CertainEscapeFromBattle, ability, battler)
  end
end

#===============================================================================
# SpeedCalc handlers
#===============================================================================

Battle::AbilityEffects::SpeedCalc.add(:CHLOROPHYLL,
  proc { |ability, battler, mult|
    next mult * 2 if [:Sun, :HarshSun].include?(battler.effectiveWeather)
  }
)

Battle::AbilityEffects::SpeedCalc.add(:PROTOSYNTHESIS,
  proc { |ability, battler, mult, ret|
    next mult if battler.effects[PBEffects::Transform]
    next mult * 1.5 if battler.effects[PBEffects::ParadoxStat] == :SPEED
  }
)

Battle::AbilityEffects::SpeedCalc.copy(:PROTOSYNTHESIS, :QUARKDRIVE)

Battle::AbilityEffects::SpeedCalc.add(:QUICKFEET,
  proc { |ability, battler, mult|
    next mult * 1.5 if battler.pbHasAnyStatus?
  }
)

Battle::AbilityEffects::SpeedCalc.add(:SANDRUSH,
  proc { |ability, battler, mult|
    next mult * 2 if [:Sandstorm].include?(battler.effectiveWeather)
  }
)

Battle::AbilityEffects::SpeedCalc.add(:SLOWSTART,
  proc { |ability, battler, mult|
    next mult / 2 if battler.effects[PBEffects::SlowStart] > 0
  }
)

Battle::AbilityEffects::SpeedCalc.add(:SLUSHRUSH,
  proc { |ability, battler, mult|
    next mult * 2 if [:Hail].include?(battler.effectiveWeather)
  }
)

Battle::AbilityEffects::SpeedCalc.add(:SURGESURFER,
  proc { |ability, battler, mult|
    next mult * 2 if battler.battle.field.terrain == :Electric
  }
)

Battle::AbilityEffects::SpeedCalc.add(:SWIFTSWIM,
  proc { |ability, battler, mult|
    next mult * 2 if [:Rain, :HeavyRain].include?(battler.effectiveWeather)
  }
)

Battle::AbilityEffects::SpeedCalc.add(:UNBURDEN,
  proc { |ability, battler, mult|
    next mult * 2 if battler.effects[PBEffects::Unburden] && !battler.item
  }
)

#===============================================================================
# WeightCalcy handlers
#===============================================================================

Battle::AbilityEffects::WeightCalc.add(:HEAVYMETAL,
  proc { |ability, battler, w|
    next w * 2
  }
)

Battle::AbilityEffects::WeightCalc.add(:LIGHTMETAL,
  proc { |ability, battler, w|
    next [w / 2, 1].max
  }
)

#===============================================================================
# OnHPDroppedBelowHalf handlers
#===============================================================================

Battle::AbilityEffects::OnHPDroppedBelowHalf.add(:EMERGENCYEXIT,
  proc { |ability, battler, move_user, battle|
    next false if battler.effects[PBEffects::SkyDrop] >= 0 ||
                  battler.inTwoTurnAttack?("TwoTurnAttackInvulnerableInSkyTargetCannotAct")   # Sky Drop
    # In wild battles
    if battle.wildBattle?
      next false if battler.opposes? && battle.pbSideBattlerCount(battler.index) > 1
      next false if !battle.pbCanRun?(battler.index)
      battle.pbShowAbilitySplash(battler, true)
      battle.pbHideAbilitySplash(battler)
      pbSEPlay("Battle flee")
      battle.pbDisplay(_INTL("¡{1} ha huido!", battler.pbThis))
      battle.decision = 3   # Escaped
      next true
    end
    # In trainer battles
    next false if battle.pbAllFainted?(battler.idxOpposingSide)
    next false if !battle.pbCanSwitchOut?(battler.index)   # Battler can't switch out
    next false if !battle.pbCanChooseNonActive?(battler.index)   # No Pokémon can switch in
    battle.pbShowAbilitySplash(battler, true)
    battle.pbHideAbilitySplash(battler)
    if !Battle::Scene::USE_ABILITY_SPLASH
      battle.pbDisplay(_INTL("¡La habilidad {2} de {1} se ha activado!", battler.pbThis, battler.abilityName))
    end
    battle.pbDisplay(_INTL("¡{1} regresó con {2}!",
       battler.pbThis, battle.pbGetOwnerName(battler.index)))
    if battle.endOfRound   # Just switch out
      battle.scene.pbRecall(battler.index) if !battler.fainted?
      battler.pbAbilitiesOnSwitchOut   # Inc. primordial weather check
      next true
    end
    newPkmn = battle.pbGetReplacementPokemonIndex(battler.index)   # Owner chooses
    next false if newPkmn < 0   # Shouldn't ever do this
    battle.pbRecallAndReplace(battler.index, newPkmn)
    battle.pbClearChoice(battler.index)   # Replacement Pokémon does nothing this round
    battle.moldBreaker = false if move_user && battler.index == move_user.index
    battle.pbOnBattlerEnteringBattle(battler.index)
    next true
  }
)

Battle::AbilityEffects::OnHPDroppedBelowHalf.copy(:EMERGENCYEXIT, :WIMPOUT)

#===============================================================================
# StatusCheckNonIgnorable handlers
#===============================================================================

Battle::AbilityEffects::StatusCheckNonIgnorable.add(:COMATOSE,
  proc { |ability, battler, status|
    next false if !battler.isSpecies?(:KOMALA)
    next true if status.nil? || status == :SLEEP
  }
)

#===============================================================================
# StatusImmunity handlers
#===============================================================================

Battle::AbilityEffects::StatusImmunity.add(:FLOWERVEIL,
  proc { |ability, battler, status|
    next true if battler.pbHasType?(:GRASS)
  }
)

Battle::AbilityEffects::StatusImmunity.add(:IMMUNITY,
  proc { |ability, battler, status|
    next true if status == :POISON
  }
)

Battle::AbilityEffects::StatusImmunity.copy(:IMMUNITY, :PASTELVEIL)

Battle::AbilityEffects::StatusImmunity.add(:INSOMNIA,
  proc { |ability, battler, status|
    next true if status == :SLEEP
  }
)

Battle::AbilityEffects::StatusImmunity.copy(:INSOMNIA, :SWEETVEIL, :VITALSPIRIT)

Battle::AbilityEffects::StatusImmunity.add(:LEAFGUARD,
  proc { |ability, battler, status|
    next true if [:Sun, :HarshSun].include?(battler.effectiveWeather)
  }
)

Battle::AbilityEffects::StatusImmunity.add(:LIMBER,
  proc { |ability, battler, status|
    next true if status == :PARALYSIS
  }
)

Battle::AbilityEffects::StatusImmunity.add(:MAGMAARMOR,
  proc { |ability, battler, status|
    next true if status == :FROZEN
  }
)

Battle::AbilityEffects::StatusImmunity.add(:PURIFYINGSALT,
  proc { |ability, battler, status|
    next true
  }
)


Battle::AbilityEffects::StatusImmunity.add(:WATERVEIL,
  proc { |ability, battler, status|
    next true if status == :BURN
  }
)

Battle::AbilityEffects::StatusCure.copy(:WATERVEIL, :WATERBUBBLE, :THERMALEXCHANGE)

#===============================================================================
# StatusImmunityNonIgnorable handlers
#===============================================================================

Battle::AbilityEffects::StatusImmunityNonIgnorable.add(:COMATOSE,
  proc { |ability, battler, status|
    next true if battler.isSpecies?(:KOMALA)
  }
)

Battle::AbilityEffects::StatusImmunityNonIgnorable.add(:SHIELDSDOWN,
  proc { |ability, battler, status|
    next true if battler.isSpecies?(:MINIOR) && battler.form < 7
  }
)

#===============================================================================
# StatusImmunityFromAlly handlers
#===============================================================================

Battle::AbilityEffects::StatusImmunityFromAlly.add(:FLOWERVEIL,
  proc { |ability, battler, status|
    next true if battler.pbHasType?(:GRASS)
  }
)

Battle::AbilityEffects::StatusImmunityFromAlly.add(:PASTELVEIL,
  proc { |ability, battler, status|
    next true if status == :POISON
  }
)

Battle::AbilityEffects::StatusImmunityFromAlly.add(:SWEETVEIL,
  proc { |ability, battler, status|
    next true if status == :SLEEP
  }
)

#===============================================================================
# OnStatusInflicted handlers
#===============================================================================

Battle::AbilityEffects::OnStatusInflicted.add(:SYNCHRONIZE,
  proc { |ability, battler, user, status|
    next if !user || user.index == battler.index
    case status
    when :POISON
      if user.pbCanPoisonSynchronize?(battler)
        battler.battle.pbShowAbilitySplash(battler)
        msg = nil
        if !Battle::Scene::USE_ABILITY_SPLASH
          msg = _INTL("¡La habilidad {2} de {1} envenenó a {3}!", battler.pbThis, battler.abilityName, user.pbThis(true))
        end
        user.pbPoison(nil, msg, (battler.statusCount > 0))
        battler.battle.pbHideAbilitySplash(battler)
      end
    when :BURN
      if user.pbCanBurnSynchronize?(battler)
        battler.battle.pbShowAbilitySplash(battler)
        msg = nil
        if !Battle::Scene::USE_ABILITY_SPLASH
          msg = _INTL("¡La habilidad {2} de {1} quemó a {3}!", battler.pbThis, battler.abilityName, user.pbThis(true))
        end
        user.pbBurn(nil, msg)
        battler.battle.pbHideAbilitySplash(battler)
      end
    when :PARALYSIS
      if user.pbCanParalyzeSynchronize?(battler)
        battler.battle.pbShowAbilitySplash(battler)
        msg = nil
        if !Battle::Scene::USE_ABILITY_SPLASH
          msg = _INTL("¡La habilidad {2} de {1} paralizó a {3}! ¡Quizás no se pueda mover!",
             battler.pbThis, battler.abilityName, user.pbThis(true))
        end
        user.pbParalyze(nil, msg)
        battler.battle.pbHideAbilitySplash(battler)
      end
    when :FROSTBITE
      if user.pbCanSynchronizeStatus?(:FROZEN, battler)
        battler.battle.pbShowAbilitySplash(battler)
        msg = nil
        if !Battle::Scene::USE_ABILITY_SPLASH
          msg = _INTL("¡{2} de {1} heló a {3}!", battler.pbThis, battler.abilityName, user.pbThis(true))
        end
        user.pbFreeze(nil, msg)
        battler.battle.pbHideAbilitySplash(battler)
      end
    end
  }
)

#===============================================================================
# StatusCure handlers
#===============================================================================

Battle::AbilityEffects::StatusCure.add(:IMMUNITY,
  proc { |ability, battler|
    next if battler.status != :POISON
    battler.battle.pbShowAbilitySplash(battler)
    battler.pbCureStatus(Battle::Scene::USE_ABILITY_SPLASH)
    if !Battle::Scene::USE_ABILITY_SPLASH
      battler.battle.pbDisplay(_INTL("¡La habilidad {2} de {1} curó el envenenamiento!", battler.pbThis, battler.abilityName))
    end
    battler.battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::StatusCure.copy(:IMMUNITY, :PASTELVEIL)

Battle::AbilityEffects::StatusCure.add(:INSOMNIA,
  proc { |ability, battler|
    next if battler.status != :SLEEP
    battler.battle.pbShowAbilitySplash(battler)
    battler.pbCureStatus(Battle::Scene::USE_ABILITY_SPLASH)
    if !Battle::Scene::USE_ABILITY_SPLASH
      battler.battle.pbDisplay(_INTL("¡La habilidad {2} de {1} lo despertó!", battler.pbThis, battler.abilityName))
    end
    battler.battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::StatusCure.copy(:INSOMNIA, :VITALSPIRIT)

Battle::AbilityEffects::StatusCure.add(:LIMBER,
  proc { |ability, battler|
    next if battler.status != :PARALYSIS
    battler.battle.pbShowAbilitySplash(battler)
    battler.pbCureStatus(Battle::Scene::USE_ABILITY_SPLASH)
    if !Battle::Scene::USE_ABILITY_SPLASH
      battler.battle.pbDisplay(_INTL("¡La habilidad {2} de {1} curó su parálisis!", battler.pbThis, battler.abilityName))
    end
    battler.battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::StatusCure.add(:MAGMAARMOR,
  proc { |ability, battler|
    next if ![:FROZEN, :FROSTBITE].include?(battler.status)
    battler.battle.pbShowAbilitySplash(battler)
    battler.pbCureStatus(Battle::Scene::USE_ABILITY_SPLASH)
    if !Battle::Scene::USE_ABILITY_SPLASH
      battler.battle.pbDisplay(_INTL("¡La habilidad {2} de {1} lo descongeló!", battler.pbThis, battler.abilityName))
    end
    battler.battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::StatusCure.add(:OBLIVIOUS,
  proc { |ability, battler|
    next if battler.effects[PBEffects::Attract] < 0 &&
            (battler.effects[PBEffects::Taunt] == 0 || Settings::MECHANICS_GENERATION <= 5)
    battler.battle.pbShowAbilitySplash(battler)
    if battler.effects[PBEffects::Attract] >= 0
      battler.pbCureAttract
      if Battle::Scene::USE_ABILITY_SPLASH
        battler.battle.pbDisplay(_INTL("{1} dejó de estar enamorado.", battler.pbThis))
      else
        battler.battle.pbDisplay(_INTL("¡La habilidad {2} de {1} lo desenamoró!",
           battler.pbThis, battler.abilityName))
      end
    end
    if battler.effects[PBEffects::Taunt] > 0 && Settings::MECHANICS_GENERATION >= 6
      battler.effects[PBEffects::Taunt] = 0
      if Battle::Scene::USE_ABILITY_SPLASH
        battler.battle.pbDisplay(_INTL("¡El efecto de Mofa sobre {1} desapareció!", battler.pbThis))
      else
        battler.battle.pbDisplay(_INTL("¡La habilidad {2} de {1} eliminó el efecto de Mofa!",
           battler.pbThis, battler.abilityName))
      end
    end
    battler.battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::StatusCure.add(:OWNTEMPO,
  proc { |ability, battler|
    next if battler.effects[PBEffects::Confusion] == 0
    battler.battle.pbShowAbilitySplash(battler)
    battler.pbCureConfusion
    if Battle::Scene::USE_ABILITY_SPLASH
      battler.battle.pbDisplay(_INTL("{1} dejó de estar confuso.", battler.pbThis))
    else
      battler.battle.pbDisplay(_INTL("¡La habilidad {2} de {1} lo sacó de su confusión!",
         battler.pbThis, battler.abilityName))
    end
    battler.battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::StatusCure.add(:WATERVEIL,
  proc { |ability, battler|
    next if battler.status != :BURN
    battler.battle.pbShowAbilitySplash(battler)
    battler.pbCureStatus(Battle::Scene::USE_ABILITY_SPLASH)
    if !Battle::Scene::USE_ABILITY_SPLASH
      battler.battle.pbDisplay(_INTL("¡La habilidad {2} de {1} curó la quemadura!", battler.pbThis, battler.abilityName))
    end
    battler.battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::StatusCure.copy(:WATERVEIL, :WATERBUBBLE)

#===============================================================================
# StatLossImmunity handlers
#===============================================================================

Battle::AbilityEffects::StatLossImmunity.add(:BIGPECKS,
  proc { |ability, battler, stat, battle, showMessages|
    next false if stat != :DEFENSE
    if showMessages
      battle.pbShowAbilitySplash(battler)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("¡{1} de {2} no puede ser bajado!", battler.pbThis, GameData::Stat.get(stat).name))
      else
        battle.pbDisplay(_INTL("¡La habilidad {2} de {1} evita la bajada de {3}!", battler.pbThis,
           battler.abilityName, GameData::Stat.get(stat).name))
      end
      battle.pbHideAbilitySplash(battler)
    end
    next true
  }
)

Battle::AbilityEffects::StatLossImmunity.add(:CLEARBODY,
  proc { |ability, battler, stat, battle, showMessages|
    if showMessages
      battle.pbShowAbilitySplash(battler)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("¡Las estadísticas de {1} no pueden ser bajadas!", battler.pbThis))
      else
        battle.pbDisplay(_INTL("¡La habilidad {2} de {1} evita la bajada de estadísticas!", battler.pbThis, battler.abilityName))
      end
      battle.pbHideAbilitySplash(battler)
    end
    next true
  }
)

Battle::AbilityEffects::StatLossImmunity.copy(:CLEARBODY, :WHITESMOKE)

Battle::AbilityEffects::StatLossImmunity.add(:FLOWERVEIL,
  proc { |ability, battler, stat, battle, showMessages|
    next false if !battler.pbHasType?(:GRASS)
    if showMessages
      battle.pbShowAbilitySplash(battler)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("¡Las estadísticas de {1} no pueden ser bajadas!", battler.pbThis))
      else
        battle.pbDisplay(_INTL("¡La habilidad {2} de {1} evita la bajada de estadísticas!", battler.pbThis, battler.abilityName))
      end
      battle.pbHideAbilitySplash(battler)
    end
    next true
  }
)

Battle::AbilityEffects::StatLossImmunity.add(:HYPERCUTTER,
  proc { |ability, battler, stat, battle, showMessages|
    next false if stat != :ATTACK
    if showMessages
      battle.pbShowAbilitySplash(battler)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("¡{1} de {2} no puede ser bajado!", battler.pbThis, GameData::Stat.get(stat).name))
      else
        battle.pbDisplay(_INTL("¡La habilidad {2} de {1} evita la bajada de {3}!", battler.pbThis,
           battler.abilityName, GameData::Stat.get(stat).name))
      end
      battle.pbHideAbilitySplash(battler)
    end
    next true
  }
)

Battle::AbilityEffects::StatLossImmunity.add(:KEENEYE,
  proc { |ability, battler, stat, battle, showMessages|
    next false if stat != :ACCURACY
    if showMessages
      battle.pbShowAbilitySplash(battler)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("¡{1} de {2} no puede ser bajado!", battler.pbThis, GameData::Stat.get(stat).name))
      else
        battle.pbDisplay(_INTL("¡La habilidad {2} de {1} evita la bajada de {3}!", battler.pbThis,
           battler.abilityName, GameData::Stat.get(stat).name))
      end
      battle.pbHideAbilitySplash(battler)
    end
    next true
  }
)

Battle::AbilityEffects::StatLossImmunity.copy(:KEENEYE, :MINDSEYE)

#===============================================================================
# StatLossImmunityNonIgnorable handlers
#===============================================================================

Battle::AbilityEffects::StatLossImmunityNonIgnorable.add(:FULLMETALBODY,
  proc { |ability, battler, stat, battle, showMessages|
    if showMessages
      battle.pbShowAbilitySplash(battler)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("¡Las estadísticas de {1} no pueden ser bajadas!", battler.pbThis))
      else
        battle.pbDisplay(_INTL("¡La habilidad {2} de {1} evita la bajada de estadísticas!", battler.pbThis, battler.abilityName))
      end
      battle.pbHideAbilitySplash(battler)
    end
    next true
  }
)

#===============================================================================
# StatLossImmunityFromAlly handlers
#===============================================================================

Battle::AbilityEffects::StatLossImmunityFromAlly.add(:FLOWERVEIL,
  proc { |ability, bearer, battler, stat, battle, showMessages|
    next false if !battler.pbHasType?(:GRASS)
    if showMessages
      battle.pbShowAbilitySplash(bearer)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("¡Las estadísticas de {1} no pueden ser bajadas!", battler.pbThis))
      else
        battle.pbDisplay(_INTL("¡La habilidad {2} de {1} evita la bajada de estadísticas de {3}!",
           bearer.pbThis, bearer.abilityName, battler.pbThis(true)))
      end
      battle.pbHideAbilitySplash(bearer)
    end
    next true
  }
)

#===============================================================================
# OnStatGain handlers
#===============================================================================

# There aren't any!

#===============================================================================
# OnStatLoss handlers
#===============================================================================

Battle::AbilityEffects::OnStatLoss.add(:COMPETITIVE,
  proc { |ability, battler, stat, user|
    next if user && !user.opposes?(battler)
    battler.pbRaiseStatStageByAbility(:SPECIAL_ATTACK, 2, battler)
  }
)

Battle::AbilityEffects::OnStatLoss.add(:DEFIANT,
  proc { |ability, battler, stat, user|
    next if user && !user.opposes?(battler)
    battler.pbRaiseStatStageByAbility(:ATTACK, 2, battler)
  }
)

#===============================================================================
# PriorityChange handlers
#===============================================================================

Battle::AbilityEffects::PriorityChange.add(:GALEWINGS,
  proc { |ability, battler, move, pri|
    next pri + 1 if (Settings::MECHANICS_GENERATION <= 6 || battler.hp == battler.totalhp) &&
                    move.type == :FLYING
  }
)

Battle::AbilityEffects::PriorityChange.add(:PRANKSTER,
  proc { |ability, battler, move, pri|
    if move.statusMove?
      battler.effects[PBEffects::Prankster] = true
      next pri + 1
    end
  }
)

Battle::AbilityEffects::PriorityChange.add(:TRIAGE,
  proc { |ability, battler, move, pri|
    next pri + 3 if move.healingMove?
  }
)

#===============================================================================
# PriorityBracketChange handlers
#===============================================================================

Battle::AbilityEffects::PriorityBracketChange.add(:MYCELIUMMIGHT,
  proc { |ability, battler, battle|
    choices = battle.choices[battler.index]
    if choices[0] == :UseMove
      next -1 if choices[2].statusMove?
    end
  }
)

Battle::AbilityEffects::PriorityBracketChange.add(:QUICKDRAW,
  proc { |ability, battler, battle|
    next 1 if battle.pbRandom(100) < 30
  }
)

Battle::AbilityEffects::PriorityBracketChange.add(:STALL,
  proc { |ability, battler, battle|
    next -1
  }
)

#===============================================================================
# PriorityBracketUse handlers
#===============================================================================

Battle::AbilityEffects::PriorityBracketUse.add(:QUICKDRAW,
  proc { |ability, battler, battle|
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("¡La habilidad {2} de {1} hizó que se mueva más rápido!", battler.abilityName, battler.pbThis(true)))
    battle.pbHideAbilitySplash(battler)
  }
)

#===============================================================================
# OnFlinch handlers
#===============================================================================

Battle::AbilityEffects::OnFlinch.add(:STEADFAST,
  proc { |ability, battler, battle|
    battler.pbRaiseStatStageByAbility(:SPEED, 1, battler)
  }
)

#===============================================================================
# MoveBlocking handlers
#===============================================================================

Battle::AbilityEffects::MoveBlocking.add(:DAZZLING,
  proc { |ability, bearer, user, targets, move, battle|
    next false if battle.choices[user.index][4] <= 0
    next false if !bearer.opposes?(user)
    ret = false
    targets.each { |b| ret = true if b.opposes?(user) }
    next ret
  }
)

Battle::AbilityEffects::MoveBlocking.copy(:DAZZLING, :QUEENLYMAJESTY, :ARMORTAIL)

#===============================================================================
# MoveImmunity handlers
#===============================================================================

Battle::AbilityEffects::MoveImmunity.add(:BULLETPROOF,
  proc { |ability, user, target, move, type, battle, show_message|
    next false if !move.bombMove?
    if show_message
      battle.pbShowAbilitySplash(target)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("No afecta a...", target.pbThis(true)))
      else
        battle.pbDisplay(_INTL("¡La habilidad {2} de {1} hizo {3} poco eficaz!",
           target.pbThis, target.abilityName, move.name))
      end
      battle.pbHideAbilitySplash(target)
    end
    next true
  }
)

Battle::AbilityEffects::MoveImmunity.add(:COMMANDER,
  proc { |ability, user, target, move, type, battle, show_message|
    next false if !target.isCommander?
    battle.pbDisplay(_INTL("¡{1} esquivó el ataque!", target.pbThis)) if show_message
    next true
  }
)

Battle::AbilityEffects::MoveImmunity.add(:EARTHEATER,
  proc { |ability, user, target, move, type, battle, show_message|
    next target.pbMoveImmunityHealingAbility(user, move, type, :GROUND, show_message)
  }
)

Battle::AbilityEffects::MoveImmunity.add(:FLASHFIRE,
  proc { |ability, user, target, move, type, battle, show_message|
    next false if user.index == target.index
    next false if type != :FIRE
    if show_message
      battle.pbShowAbilitySplash(target)
      if !target.effects[PBEffects::FlashFire]
        target.effects[PBEffects::FlashFire] = true
        if Battle::Scene::USE_ABILITY_SPLASH
          battle.pbDisplay(_INTL("¡El poder de los ataques de tipo Fuego de {1} aumentó!", target.pbThis(true)))
        else
          battle.pbDisplay(_INTL("El poder de los ataques de tipo Fuego de {1} aumentó por su habilidad {2}!",
             target.pbThis(true), target.abilityName))
        end
      elsif Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("No afecta a {1}...", target.pbThis(true)))
      else
        battle.pbDisplay(_INTL("¡La habilidad {2} de {1} hizo {3} poco eficaz!",
                               target.pbThis, target.abilityName, move.name))
      end
      battle.pbHideAbilitySplash(target)
    end
    next true
  }
)

Battle::AbilityEffects::MoveImmunity.add(:GOODASGOLD,
  proc { |ability, user, target, move, type, battle, show_message|
    next false if !move.statusMove?
    next false if user.index == target.index
    if show_message
      battle.pbShowAbilitySplash(target)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("No afecta a {1}...", target.pbThis(true)))
      else
        battle.pbDisplay(_INTL("{2} de {1} bloquea {3}!",
           target.pbThis, target.abilityName, move.name))
      end
      battle.pbHideAbilitySplash(target)
    end
    next true
  }
)

Battle::AbilityEffects::MoveImmunity.add(:LIGHTNINGROD,
  proc { |ability, user, target, move, type, battle, show_message|
    next target.pbMoveImmunityStatRaisingAbility(user, move, type,
       :ELECTRIC, :SPECIAL_ATTACK, 1, show_message)
  }
)

Battle::AbilityEffects::MoveImmunity.add(:MOTORDRIVE,
  proc { |ability, user, target, move, type, battle, show_message|
    next target.pbMoveImmunityStatRaisingAbility(user, move, type,
       :ELECTRIC, :SPEED, 1, show_message)
  }
)

Battle::AbilityEffects::MoveImmunity.add(:SAPSIPPER,
  proc { |ability, user, target, move, type, battle, show_message|
    next target.pbMoveImmunityStatRaisingAbility(user, move, type,
       :GRASS, :ATTACK, 1, show_message)
  }
)

Battle::AbilityEffects::MoveImmunity.add(:SOUNDPROOF,
  proc { |ability, user, target, move, type, battle, show_message|
    next false if !move.soundMove?
    next false if Settings::MECHANICS_GENERATION >= 8 && user.index == target.index
    if show_message
      battle.pbShowAbilitySplash(target)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("No afecta a {1}......", target.pbThis(true)))
      else
        battle.pbDisplay(_INTL("¡La habilidad {2} de {1} bloqueó {3}!", target.pbThis, target.abilityName, move.name))
      end
      battle.pbHideAbilitySplash(target)
    end
    next true
  }
)

Battle::AbilityEffects::MoveImmunity.add(:STORMDRAIN,
  proc { |ability, user, target, move, type, battle, show_message|
    next target.pbMoveImmunityStatRaisingAbility(user, move, type,
       :WATER, :SPECIAL_ATTACK, 1, show_message)
  }
)

Battle::AbilityEffects::MoveImmunity.add(:TELEPATHY,
  proc { |ability, user, target, move, type, battle, show_message|
    next false if move.statusMove?
    next false if user.index == target.index || target.opposes?(user)
    if show_message
      battle.pbShowAbilitySplash(target)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("¡{1} esquiva ataques de su Pokémon aliado!", target.pbThis(true)))
      else
        battle.pbDisplay(_INTL("¡{1} esquiva ataques de su Pokémon aliado con la habilidad {2}!",
           target.pbThis, target.abilityName))
      end
      battle.pbHideAbilitySplash(target)
    end
    next true
  }
)

Battle::AbilityEffects::MoveImmunity.add(:VOLTABSORB,
  proc { |ability, user, target, move, type, battle, show_message|
    next target.pbMoveImmunityHealingAbility(user, move, type, :ELECTRIC, show_message)
  }
)

Battle::AbilityEffects::MoveImmunity.add(:WATERABSORB,
  proc { |ability, user, target, move, type, battle, show_message|
    next target.pbMoveImmunityHealingAbility(user, move, type, :WATER, show_message)
  }
)

Battle::AbilityEffects::MoveImmunity.copy(:WATERABSORB, :DRYSKIN)

Battle::AbilityEffects::MoveImmunity.add(:WELLBAKEDBODY,
  proc { |ability, user, target, move, type, battle, show_message|
    next target.pbMoveImmunityStatRaisingAbility(user, move, type, :FIRE, :DEFENSE, 2, show_message)
  }
)

Battle::AbilityEffects::MoveImmunity.add(:WINDRIDER,
  proc { |ability, user, target, move, type, battle, show_message|
    next false if !move.windMove?
    next false if user.index == target.index
    if show_message
      battle.pbShowAbilitySplash(target)
      if target.pbCanRaiseStatStage?(:ATTACK, user, move)
        if Battle::Scene::USE_ABILITY_SPLASH
          target.pbRaiseStatStage(:ATTACK, 1, user)
        else
          target.pbRaiseStatStageByCause(:ATTACK, 1, user, target.abilityName)
        end
      elsif Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("It doesn't affect {1}...", target.pbThis(true)))
      else
        battle.pbDisplay(_INTL("{1}'s {2} made {3} ineffective!", target.pbThis, target.abilityName, move.name))
      end
      battle.pbHideAbilitySplash(target)
    end
    next true
  }
)

Battle::AbilityEffects::MoveImmunity.add(:WONDERGUARD,
  proc { |ability, user, target, move, type, battle, show_message|
    next false if move.statusMove?
    next false if !type || Effectiveness.super_effective?(target.damageState.typeMod)
    if show_message
      battle.pbShowAbilitySplash(target)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("No afecta a {1}...", target.pbThis(true)))
      else
        battle.pbDisplay(_INTL("¡{1} evitó daño con la habilidad {2}!", target.pbThis, target.abilityName))
      end
      battle.pbHideAbilitySplash(target)
    end
    next true
  }
)

#===============================================================================
# ModifyMoveBaseType handlers
#===============================================================================

Battle::AbilityEffects::ModifyMoveBaseType.add(:AERILATE,
  proc { |ability, user, move, type|
    next if type != :NORMAL || !GameData::Type.exists?(:FLYING)
    move.powerBoost = true
    next :FLYING
  }
)

Battle::AbilityEffects::ModifyMoveBaseType.add(:GALVANIZE,
  proc { |ability, user, move, type|
    next if type != :NORMAL || !GameData::Type.exists?(:ELECTRIC)
    move.powerBoost = true
    next :ELECTRIC
  }
)

Battle::AbilityEffects::ModifyMoveBaseType.add(:LIQUIDVOICE,
  proc { |ability, user, move, type|
    next :WATER if GameData::Type.exists?(:WATER) && move.soundMove?
  }
)

Battle::AbilityEffects::ModifyMoveBaseType.add(:NORMALIZE,
  proc { |ability, user, move, type|
    next if !GameData::Type.exists?(:NORMAL)
    move.powerBoost = true if Settings::MECHANICS_GENERATION >= 7
    next :NORMAL
  }
)

Battle::AbilityEffects::ModifyMoveBaseType.add(:PIXILATE,
  proc { |ability, user, move, type|
    next if type != :NORMAL || !GameData::Type.exists?(:FAIRY)
    move.powerBoost = true
    next :FAIRY
  }
)

Battle::AbilityEffects::ModifyMoveBaseType.add(:REFRIGERATE,
  proc { |ability, user, move, type|
    next if type != :NORMAL || !GameData::Type.exists?(:ICE)
    move.powerBoost = true
    next :ICE
  }
)

#===============================================================================
# AccuracyCalcFromUser handlers
#===============================================================================

Battle::AbilityEffects::AccuracyCalcFromUser.add(:COMPOUNDEYES,
  proc { |ability, mods, user, target, move, type|
    mods[:accuracy_multiplier] *= 1.3
  }
)

Battle::AbilityEffects::AccuracyCalcFromUser.add(:HUSTLE,
  proc { |ability, mods, user, target, move, type|
    mods[:accuracy_multiplier] *= 0.8 if move.physicalMove?
  }
)

Battle::AbilityEffects::AccuracyCalcFromUser.add(:KEENEYE,
  proc { |ability, mods, user, target, move, type|
    mods[:evasion_stage] = 0 if mods[:evasion_stage] > 0 && Settings::MECHANICS_GENERATION >= 6
  }
)

Battle::AbilityEffects::AccuracyCalcFromUser.copy(:KEENEYE, :MINDSEYE)

Battle::AbilityEffects::AccuracyCalcFromUser.add(:NOGUARD,
  proc { |ability, mods, user, target, move, type|
    mods[:base_accuracy] = 0
  }
)

Battle::AbilityEffects::AccuracyCalcFromUser.add(:UNAWARE,
  proc { |ability, mods, user, target, move, type|
    mods[:evasion_stage] = 0 if move.damagingMove?
  }
)

Battle::AbilityEffects::AccuracyCalcFromUser.add(:VICTORYSTAR,
  proc { |ability, mods, user, target, move, type|
    mods[:accuracy_multiplier] *= 1.1
  }
)

#===============================================================================
# AccuracyCalcFromAlly handlers
#===============================================================================

Battle::AbilityEffects::AccuracyCalcFromAlly.add(:VICTORYSTAR,
  proc { |ability, mods, user, target, move, type|
    mods[:accuracy_multiplier] *= 1.1
  }
)

#===============================================================================
# AccuracyCalcFromTarget handlers
#===============================================================================

Battle::AbilityEffects::AccuracyCalcFromTarget.add(:LIGHTNINGROD,
  proc { |ability, mods, user, target, move, type|
    mods[:base_accuracy] = 0 if type == :ELECTRIC
  }
)

Battle::AbilityEffects::AccuracyCalcFromTarget.add(:NOGUARD,
  proc { |ability, mods, user, target, move, type|
    mods[:base_accuracy] = 0
  }
)

Battle::AbilityEffects::AccuracyCalcFromTarget.add(:SANDVEIL,
  proc { |ability, mods, user, target, move, type|
    mods[:evasion_multiplier] *= 1.25 if target.effectiveWeather == :Sandstorm
  }
)

Battle::AbilityEffects::AccuracyCalcFromTarget.add(:SNOWCLOAK,
  proc { |ability, mods, user, target, move, type|
    mods[:evasion_multiplier] *= 1.25 if target.effectiveWeather == :Hail
  }
)

Battle::AbilityEffects::AccuracyCalcFromTarget.add(:STORMDRAIN,
  proc { |ability, mods, user, target, move, type|
    mods[:base_accuracy] = 0 if type == :WATER
  }
)

Battle::AbilityEffects::AccuracyCalcFromTarget.add(:TANGLEDFEET,
  proc { |ability, mods, user, target, move, type|
    mods[:accuracy_multiplier] /= 2 if target.effects[PBEffects::Confusion] > 0
  }
)

Battle::AbilityEffects::AccuracyCalcFromTarget.add(:UNAWARE,
  proc { |ability, mods, user, target, move, type|
    mods[:accuracy_stage] = 0 if move.damagingMove?
  }
)

Battle::AbilityEffects::AccuracyCalcFromTarget.add(:WONDERSKIN,
  proc { |ability, mods, user, target, move, type|
    if move.statusMove? && user.opposes?(target) && mods[:base_accuracy] > 50
      mods[:base_accuracy] = 50
    end
  }
)

#===============================================================================
# DamageCalcFromUser handlers
#===============================================================================

Battle::AbilityEffects::DamageCalcFromUser.add(:AERILATE,
  proc { |ability, user, target, move, mults, power, type|
    mults[:power_multiplier] *= 1.2 if move.powerBoost
  }
)

#===============================================================================
# Rocky Payload
#===============================================================================
Battle::AbilityEffects::DamageCalcFromUser.add(:ROCKYPAYLOAD,
  proc { |ability, user, target, move, mults, baseDmg, type|
    mults[:attack_multiplier] *= 1.5 if type == :ROCK
  }
)

#===============================================================================
# Sharpness
#===============================================================================
Battle::AbilityEffects::DamageCalcFromUser.add(:SHARPNESS,
  proc { |ability, user, target, move, mults, baseDmg, type|
    mults[:power_multiplier] *= 1.5 if move.slicingMove?
  }
)

#===============================================================================
# Supreme Overlord
#===============================================================================
Battle::AbilityEffects::DamageCalcFromUser.add(:SUPREMEOVERLORD,
  proc { |ability, user, target, move, mults, baseDmg, type|
    bonus = user.effects[PBEffects::SupremeOverlord]
    next if bonus <= 0
    mults[:power_multiplier] *= (1 + (0.1 * bonus))
  }
)


Battle::AbilityEffects::DamageCalcFromUser.copy(:AERILATE, :GALVANIZE, :NORMALIZE, :PIXILATE, :REFRIGERATE)

Battle::AbilityEffects::DamageCalcFromUser.add(:ANALYTIC,
  proc { |ability, user, target, move, mults, power, type|
    # NOTE: In the official games, if another battler faints earlier in the
    #       round but it would have moved after the user, then Analytic does not
    #       power up the move. However, this makes the determination so much
    #       more complicated (involving pbPriority and counting or not counting
    #       speed/priority modifiers depending on which Generation's mechanics
    #       are being used), so I'm choosing to ignore it. The effect is thus:
    #       "power up the move if all other battlers on the field right now have
    #       already moved".
    if move.pbMoveFailedLastInRound?(user, false)
      mults[:power_multiplier] *= 1.3
    end
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:BLAZE,
  proc { |ability, user, target, move, mults, power, type|
    if user.hp <= user.totalhp / 3 && type == :FIRE
      mults[:attack_multiplier] *= 1.5
    end
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:DEFEATIST,
  proc { |ability, user, target, move, mults, power, type|
    mults[:attack_multiplier] /= 2 if user.hp <= user.totalhp / 2
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:DRAGONSMAW,
  proc { |ability, user, target, move, mults, power, type|
    mults[:attack_multiplier] *= 1.5 if type == :DRAGON
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:FLAREBOOST,
  proc { |ability, user, target, move, mults, power, type|
    mults[:power_multiplier] *= 1.5 if user.burned? && move.specialMove?
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:FLASHFIRE,
  proc { |ability, user, target, move, mults, power, type|
    if user.effects[PBEffects::FlashFire] && type == :FIRE
      mults[:attack_multiplier] *= 1.5
    end
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:FLOWERGIFT,
  proc { |ability, user, target, move, mults, power, type|
    if move.physicalMove? && [:Sun, :HarshSun].include?(user.effectiveWeather)
      mults[:attack_multiplier] *= 1.5
    end
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:GORILLATACTICS,
  proc { |ability, user, target, move, mults, power, type|
    mults[:attack_multiplier] *= 1.5 if move.physicalMove?
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:GUTS,
  proc { |ability, user, target, move, mults, power, type|
    if user.pbHasAnyStatus? && move.physicalMove?
      mults[:attack_multiplier] *= 1.5
    end
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:HADRONENGINE,
  proc { |ability, user, target, move, mults, baseDmg, type|
    mults[:attack_multiplier] *= 4 / 3.0 if move.specialMove? && user.battle.field.terrain == :Electric
  }
)


Battle::AbilityEffects::DamageCalcFromUser.add(:HUGEPOWER,
  proc { |ability, user, target, move, mults, power, type|
    mults[:attack_multiplier] *= 2 if move.physicalMove?
  }
)

Battle::AbilityEffects::DamageCalcFromUser.copy(:HUGEPOWER, :PUREPOWER)

Battle::AbilityEffects::DamageCalcFromUser.add(:HUSTLE,
  proc { |ability, user, target, move, mults, power, type|
    mults[:attack_multiplier] *= 1.5 if move.physicalMove?
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:IRONFIST,
  proc { |ability, user, target, move, mults, power, type|
    mults[:power_multiplier] *= 1.2 if move.punchingMove?
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:MEGALAUNCHER,
  proc { |ability, user, target, move, mults, power, type|
    mults[:power_multiplier] *= 1.5 if move.pulseMove?
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:MINUS,
  proc { |ability, user, target, move, mults, power, type|
    next if !move.specialMove?
    if user.allAllies.any? { |b| b.hasActiveAbility?([:MINUS, :PLUS]) }
      mults[:attack_multiplier] *= 1.5
    end
  }
)

Battle::AbilityEffects::DamageCalcFromUser.copy(:MINUS, :PLUS)

Battle::AbilityEffects::DamageCalcFromUser.add(:NEUROFORCE,
  proc { |ability, user, target, move, mults, power, type|
    if Effectiveness.super_effective?(target.damageState.typeMod)
      mults[:final_damage_multiplier] *= 1.25
    end
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:ORICHALCUMPULSE,
  proc { |ability, user, target, move, mults, baseDmg, type|
    mults[:attack_multiplier] *= 4 / 3.0 if move.physicalMove? && [:Sun, :HarshSun].include?(user.effectiveWeather)
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:OVERGROW,
  proc { |ability, user, target, move, mults, power, type|
    if user.hp <= user.totalhp / 3 && type == :GRASS
      mults[:attack_multiplier] *= 1.5
    end
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:PROTOSYNTHESIS,
  proc { |ability, user, target, move, mults, baseDmg, type|
    next if user.effects[PBEffects::Transform]
    stat = user.effects[PBEffects::ParadoxStat]
    mults[:attack_multiplier] *= 1.3 if move.physicalMove? && stat == :ATTACK
    mults[:attack_multiplier] *= 1.3 if move.specialMove?  && stat == :SPECIAL_ATTACK
  }
)

Battle::AbilityEffects::DamageCalcFromUser.copy(:PROTOSYNTHESIS, :QUARKDRIVE)

Battle::AbilityEffects::DamageCalcFromUser.add(:PUNKROCK,
  proc { |ability, user, target, move, mults, power, type|
    mults[:attack_multiplier] *= 1.3 if move.soundMove?
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:RECKLESS,
  proc { |ability, user, target, move, mults, power, type|
    mults[:power_multiplier] *= 1.2 if move.recoilMove?
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:RIVALRY,
  proc { |ability, user, target, move, mults, power, type|
    if user.gender != 2 && target.gender != 2
      if user.gender == target.gender
        mults[:power_multiplier] *= 1.25
      else
        mults[:power_multiplier] *= 0.75
      end
    end
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:SANDFORCE,
  proc { |ability, user, target, move, mults, power, type|
    if user.effectiveWeather == :Sandstorm &&
       [:ROCK, :GROUND, :STEEL].include?(type)
      mults[:power_multiplier] *= 1.3
    end
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:SHEERFORCE,
  proc { |ability, user, target, move, mults, power, type|
    mults[:power_multiplier] *= 1.3 if move.addlEffect > 0
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:SLOWSTART,
  proc { |ability, user, target, move, mults, power, type|
    mults[:attack_multiplier] /= 2 if user.effects[PBEffects::SlowStart] > 0 && move.physicalMove?
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:SNIPER,
  proc { |ability, user, target, move, mults, power, type|
    mults[:final_damage_multiplier] *= 1.5 if target.damageState.critical
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:SOLARPOWER,
  proc { |ability, user, target, move, mults, power, type|
    if move.specialMove? && [:Sun, :HarshSun].include?(user.effectiveWeather)
      mults[:attack_multiplier] *= 1.5
    end
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:STAKEOUT,
  proc { |ability, user, target, move, mults, power, type|
    mults[:attack_multiplier] *= 2 if target.battle.choices[target.index][0] == :SwitchOut
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:STEELWORKER,
  proc { |ability, user, target, move, mults, power, type|
    mults[:attack_multiplier] *= 1.5 if type == :STEEL
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:STEELYSPIRIT,
  proc { |ability, user, target, move, mults, power, type|
    mults[:final_damage_multiplier] *= 1.5 if type == :STEEL
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:STRONGJAW,
  proc { |ability, user, target, move, mults, power, type|
    mults[:power_multiplier] *= 1.5 if move.bitingMove?
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:SWARM,
  proc { |ability, user, target, move, mults, power, type|
    if user.hp <= user.totalhp / 3 && type == :BUG
      mults[:attack_multiplier] *= 1.5
    end
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:TECHNICIAN,
  proc { |ability, user, target, move, mults, power, type|
    if user.index != target.index && move && move.function_code != "Struggle" &&
       power * mults[:power_multiplier] <= 60
      mults[:power_multiplier] *= 1.5
    end
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:TINTEDLENS,
  proc { |ability, user, target, move, mults, power, type|
    mults[:final_damage_multiplier] *= 2 if Effectiveness.resistant?(target.damageState.typeMod)
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:TORRENT,
  proc { |ability, user, target, move, mults, power, type|
    if user.hp <= user.totalhp / 3 && type == :WATER
      mults[:attack_multiplier] *= 1.5
    end
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:TOUGHCLAWS,
  proc { |ability, user, target, move, mults, power, type|
    mults[:power_multiplier] *= 4 / 3.0 if move.contactMove?
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:TOXICBOOST,
  proc { |ability, user, target, move, mults, power, type|
    if user.poisoned? && move.physicalMove?
      mults[:power_multiplier] *= 1.5
    end
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:TRANSISTOR,
  proc { |ability, user, target, move, mults, power, type|
    mults[:attack_multiplier] *= 1.5 if type == :ELECTRIC
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:WATERBUBBLE,
  proc { |ability, user, target, move, mults, power, type|
    mults[:attack_multiplier] *= 2 if type == :WATER
  }
)

#===============================================================================
# DamageCalcFromAlly handlers
#===============================================================================

Battle::AbilityEffects::DamageCalcFromAlly.add(:BATTERY,
  proc { |ability, user, target, move, mults, power, type|
    next if !move.specialMove?
    mults[:final_damage_multiplier] *= 1.3
  }
)

Battle::AbilityEffects::DamageCalcFromAlly.add(:FLOWERGIFT,
  proc { |ability, user, target, move, mults, power, type|
    if move.physicalMove? && [:Sun, :HarshSun].include?(user.effectiveWeather)
      mults[:attack_multiplier] *= 1.5
    end
  }
)

Battle::AbilityEffects::DamageCalcFromAlly.add(:POWERSPOT,
  proc { |ability, user, target, move, mults, power, type|
    mults[:final_damage_multiplier] *= 1.3
  }
)

Battle::AbilityEffects::DamageCalcFromAlly.add(:STEELYSPIRIT,
  proc { |ability, user, target, move, mults, power, type|
    mults[:final_damage_multiplier] *= 1.5 if type == :STEEL
  }
)

#===============================================================================
# DamageCalcFromTarget handlers
#===============================================================================

Battle::AbilityEffects::DamageCalcFromTarget.add(:DRYSKIN,
  proc { |ability, user, target, move, mults, power, type|
    mults[:power_multiplier] *= 1.25 if type == :FIRE
  }
)

Battle::AbilityEffects::DamageCalcFromTarget.add(:FILTER,
  proc { |ability, user, target, move, mults, power, type|
    if Effectiveness.super_effective?(target.damageState.typeMod)
      mults[:final_damage_multiplier] *= 0.75
    end
  }
)

Battle::AbilityEffects::DamageCalcFromTarget.copy(:FILTER, :SOLIDROCK)

Battle::AbilityEffects::DamageCalcFromTarget.add(:FLOWERGIFT,
  proc { |ability, user, target, move, mults, power, type|
    if move.specialMove? && [:Sun, :HarshSun].include?(target.effectiveWeather)
      mults[:defense_multiplier] *= 1.5
    end
  }
)

Battle::AbilityEffects::DamageCalcFromTarget.add(:FLUFFY,
  proc { |ability, user, target, move, mults, power, type|
    mults[:final_damage_multiplier] *= 2 if move.calcType == :FIRE
    mults[:final_damage_multiplier] /= 2 if move.pbContactMove?(user)
  }
)

Battle::AbilityEffects::DamageCalcFromTarget.add(:FURCOAT,
  proc { |ability, user, target, move, mults, power, type|
    mults[:defense_multiplier] *= 2 if move.physicalMove? ||
                                       move.function_code == "UseTargetDefenseInsteadOfTargetSpDef"   # Psyshock
  }
)

Battle::AbilityEffects::DamageCalcFromTarget.add(:GRASSPELT,
  proc { |ability, user, target, move, mults, power, type|
    mults[:defense_multiplier] *= 1.5 if user.battle.field.terrain == :Grassy
  }
)

Battle::AbilityEffects::DamageCalcFromTarget.add(:HEATPROOF,
  proc { |ability, user, target, move, mults, power, type|
    mults[:power_multiplier] /= 2 if type == :FIRE
  }
)

Battle::AbilityEffects::DamageCalcFromTarget.add(:ICESCALES,
  proc { |ability, user, target, move, mults, power, type|
    mults[:final_damage_multiplier] /= 2 if move.specialMove?
  }
)

Battle::AbilityEffects::DamageCalcFromTarget.add(:MARVELSCALE,
  proc { |ability, user, target, move, mults, power, type|
    if target.pbHasAnyStatus? && move.physicalMove?
      mults[:defense_multiplier] *= 1.5
    end
  }
)

Battle::AbilityEffects::DamageCalcFromTarget.add(:MULTISCALE,
  proc { |ability, user, target, move, mults, power, type|
    mults[:final_damage_multiplier] /= 2 if target.hp == target.totalhp
  }
)

Battle::AbilityEffects::DamageCalcFromTarget.add(:PROTOSYNTHESIS,
  proc { |ability, user, target, move, mults, baseDmg, type|
    next if target.effects[PBEffects::Transform]
    stat = target.effects[PBEffects::ParadoxStat]
    mults[:defense_multiplier] *= 1.3 if move.physicalMove? && stat == :DEFENSE
    mults[:defense_multiplier] *= 1.3 if move.specialMove?  && stat == :SPECIAL_DEFENSE
  }
)

Battle::AbilityEffects::DamageCalcFromTarget.copy(:PROTOSYNTHESIS, :QUARKDRIVE)

Battle::AbilityEffects::DamageCalcFromTarget.add(:PUNKROCK,
  proc { |ability, user, target, move, mults, power, type|
    mults[:final_damage_multiplier] /= 2 if move.soundMove?
  }
)

Battle::AbilityEffects::DamageCalcFromTarget.add(:THICKFAT,
  proc { |ability, user, target, move, mults, power, type|
    mults[:power_multiplier] /= 2 if [:FIRE, :ICE].include?(type)
  }
)

Battle::AbilityEffects::DamageCalcFromTarget.add(:PURIFYINGSALT,
  proc { |ability, user, target, move, mults, baseDmg, type|
    mults[:attack_multiplier] /= 2 if type == :GHOST
  }
)

Battle::AbilityEffects::DamageCalcFromTarget.add(:WATERBUBBLE,
  proc { |ability, user, target, move, mults, power, type|
    mults[:final_damage_multiplier] /= 2 if type == :FIRE
  }
)

#===============================================================================
# DamageCalcFromTargetNonIgnorable handlers
#===============================================================================

Battle::AbilityEffects::DamageCalcFromTargetNonIgnorable.add(:PRISMARMOR,
  proc { |ability, user, target, move, mults, power, type|
    if Effectiveness.super_effective?(target.damageState.typeMod)
      mults[:final_damage_multiplier] *= 0.75
    end
  }
)

Battle::AbilityEffects::DamageCalcFromTargetNonIgnorable.add(:SHADOWSHIELD,
  proc { |ability, user, target, move, mults, power, type|
    mults[:final_damage_multiplier] /= 2 if target.hp == target.totalhp
  }
)

#===============================================================================
# DamageCalcFromTargetAlly handlers
#===============================================================================

Battle::AbilityEffects::DamageCalcFromTargetAlly.add(:FLOWERGIFT,
  proc { |ability, user, target, move, mults, power, type|
    if move.specialMove? && [:Sun, :HarshSun].include?(target.effectiveWeather)
      mults[:defense_multiplier] *= 1.5
    end
  }
)

Battle::AbilityEffects::DamageCalcFromTargetAlly.add(:FRIENDGUARD,
  proc { |ability, user, target, move, mults, power, type|
    mults[:final_damage_multiplier] *= 0.75
  }
)

#===============================================================================
# CriticalCalcFromUser handlers
#===============================================================================

Battle::AbilityEffects::CriticalCalcFromUser.add(:MERCILESS,
  proc { |ability, user, target, c|
    next 99 if target.poisoned?
  }
)

Battle::AbilityEffects::CriticalCalcFromUser.add(:SUPERLUCK,
  proc { |ability, user, target, c|
    next c + 1
  }
)

#===============================================================================
# CriticalCalcFromTarget handlers
#===============================================================================

Battle::AbilityEffects::CriticalCalcFromTarget.add(:BATTLEARMOR,
  proc { |ability, user, target, c|
    next -1
  }
)

Battle::AbilityEffects::CriticalCalcFromTarget.copy(:BATTLEARMOR, :SHELLARMOR)

#===============================================================================
# OnBeingHit handlers
#===============================================================================

Battle::AbilityEffects::OnBeingHit.add(:AFTERMATH,
  proc { |ability, user, target, move, battle|
    next if !target.fainted?
    next if !move.pbContactMove?(user)
    battle.pbShowAbilitySplash(target)
    if !battle.moldBreaker
      dampBattler = battle.pbCheckGlobalAbility(:DAMP)
      if dampBattler
        battle.pbShowAbilitySplash(dampBattler)
        if Battle::Scene::USE_ABILITY_SPLASH
          battle.pbDisplay(_INTL("¡{1} no puede usar la habilidad {2}!", target.pbThis, target.abilityName))
        else
          battle.pbDisplay(_INTL("{1} no puede usar la habilidad {2} por la habilidad {4} de {3}!",
             target.pbThis, target.abilityName, dampBattler.pbThis(true), dampBattler.abilityName))
        end
        battle.pbHideAbilitySplash(dampBattler)
        battle.pbHideAbilitySplash(target)
        next
      end
    end
    if user.takesIndirectDamage?(Battle::Scene::USE_ABILITY_SPLASH) &&
       user.affectedByContactEffect?(Battle::Scene::USE_ABILITY_SPLASH)
      battle.scene.pbDamageAnimation(user)
      user.pbReduceHP(user.totalhp / 4, false)
      battle.pbDisplay(_INTL("¡{1} fue atrapado en las consecuencias!", user.pbThis))
    end
    battle.pbHideAbilitySplash(target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:ANGERPOINT,
  proc { |ability, user, target, move, battle|
    next if !target.damageState.critical
    next if !target.pbCanRaiseStatStage?(:ATTACK, target)
    battle.pbShowAbilitySplash(target)
    target.stages[:ATTACK] = Battle::Battler::STAT_STAGE_MAXIMUM
    target.statsRaisedThisRound = true
    battle.pbCommonAnimation("StatUp", target)
    if Battle::Scene::USE_ABILITY_SPLASH
      battle.pbDisplay(_INTL("¡{1} subió al máximo su {2}!", target.pbThis, GameData::Stat.get(:ATTACK).name))
    else
      battle.pbDisplay(_INTL("¡La habilidad {1} de {2} subió al máximo su {3}!",
         target.pbThis, target.abilityName, GameData::Stat.get(:ATTACK).name))
    end
    battle.pbHideAbilitySplash(target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:COTTONDOWN,
  proc { |ability, user, target, move, battle|
    next if battle.allBattlers.none? { |b| b.index != target.index && b.pbCanLowerStatStage?(:SPEED, target) }
    battle.pbShowAbilitySplash(target)
    battle.allBattlers.each do |b|
      b.pbLowerStatStageByAbility(:SPEED, 1, target, false) if b.index != target.index
    end
    battle.pbHideAbilitySplash(target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:CURSEDBODY,
  proc { |ability, user, target, move, battle|
    next if user.fainted?
    next if user.effects[PBEffects::Disable] > 0
    regularMove = nil
    user.eachMove do |m|
      next if m.id != user.lastRegularMoveUsed
      regularMove = m
      break
    end
    next if !regularMove || (regularMove.pp == 0 && regularMove.total_pp > 0)
    next if battle.pbRandom(100) >= 30
    battle.pbShowAbilitySplash(target)
    if !move.pbMoveFailedAromaVeil?(target, user, Battle::Scene::USE_ABILITY_SPLASH)
      user.effects[PBEffects::Disable]     = 3
      user.effects[PBEffects::DisableMove] = regularMove.id
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("¡{1} de {2} fue deshabilitado!", user.pbThis, regularMove.name))
      else
        battle.pbDisplay(_INTL("¡{1} de {2} fue deshabilitado por la habilidad {4} de {3}!",
           user.pbThis, regularMove.name, target.pbThis(true), target.abilityName))
      end
      battle.pbHideAbilitySplash(target)
      user.pbItemStatusCureCheck
    end
    battle.pbHideAbilitySplash(target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:CUTECHARM,
  proc { |ability, user, target, move, battle|
    next if target.fainted?
    next if !move.pbContactMove?(user)
    next if battle.pbRandom(100) >= 30
    battle.pbShowAbilitySplash(target)
    if user.pbCanAttract?(target, Battle::Scene::USE_ABILITY_SPLASH) &&
       user.affectedByContactEffect?(Battle::Scene::USE_ABILITY_SPLASH)
      msg = nil
      if !Battle::Scene::USE_ABILITY_SPLASH
        msg = _INTL("¡{1} de {2} hizo que {3} se enamorara!", target.pbThis,
           target.abilityName, user.pbThis(true))
      end
      user.pbAttract(target, msg)
    end
    battle.pbHideAbilitySplash(target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:EFFECTSPORE,
  proc { |ability, user, target, move, battle|
    # NOTE: This ability has a 30% chance of triggering, not a 30% chance of
    #       inflicting a status condition. It can try (and fail) to inflict a
    #       status condition that the user is immune to.
    next if !move.pbContactMove?(user)
    next if battle.pbRandom(100) >= 30
    r = battle.pbRandom(3)
    next if r == 0 && user.asleep?
    next if r == 1 && user.poisoned?
    next if r == 2 && user.paralyzed?
    battle.pbShowAbilitySplash(target)
    if user.affectedByPowder?(Battle::Scene::USE_ABILITY_SPLASH) &&
       user.affectedByContactEffect?(Battle::Scene::USE_ABILITY_SPLASH)
      case r
      when 0
        if user.pbCanSleep?(target, Battle::Scene::USE_ABILITY_SPLASH)
          msg = nil
          if !Battle::Scene::USE_ABILITY_SPLASH
            msg = _INTL("¡{1} de {2} durmió a {3}!", target.pbThis,
               target.abilityName, user.pbThis(true))
          end
          user.pbSleep(msg)
        end
      when 1
        if user.pbCanPoison?(target, Battle::Scene::USE_ABILITY_SPLASH)
          msg = nil
          if !Battle::Scene::USE_ABILITY_SPLASH
            msg = _INTL("¡{1} de {2} envenenó ad {3}!", target.pbThis,
               target.abilityName, user.pbThis(true))
          end
          user.pbPoison(target, msg)
        end
      when 2
        if user.pbCanParalyze?(target, Battle::Scene::USE_ABILITY_SPLASH)
          msg = nil
          if !Battle::Scene::USE_ABILITY_SPLASH
            msg = _INTL("¡{1} de {2} paralizó a {3}! ¡Quizás no se pueda mover!",
               target.pbThis, target.abilityName, user.pbThis(true))
          end
          user.pbParalyze(target, msg)
        end
      end
    end
    battle.pbHideAbilitySplash(target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:ELECTROMORPHOSIS,
  proc { |ability, user, target, move, battle|
    next if target.fainted?
    next if target.effects[PBEffects::Charge] > 0
    battle.pbShowAbilitySplash(target)
    target.effects[PBEffects::Charge] = 2
    battle.pbDisplay(_INTL("¡Ser golpeado por {1} cargó a {2} de poder!", move.name, target.pbThis(true)))
    battle.pbHideAbilitySplash(target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:FLAMEBODY,
  proc { |ability, user, target, move, battle|
    next if !move.pbContactMove?(user)
    next if user.burned? || battle.pbRandom(100) >= 30
    battle.pbShowAbilitySplash(target)
    if user.pbCanBurn?(target, Battle::Scene::USE_ABILITY_SPLASH) &&
       user.affectedByContactEffect?(Battle::Scene::USE_ABILITY_SPLASH)
      msg = nil
      if !Battle::Scene::USE_ABILITY_SPLASH
        msg = _INTL("¡{1} de {2} quemó a {3}!", target.pbThis, target.abilityName, user.pbThis(true))
      end
      user.pbBurn(target, msg)
    end
    battle.pbHideAbilitySplash(target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:GOOEY,
  proc { |ability, user, target, move, battle|
    next if !move.pbContactMove?(user)
    user.pbLowerStatStageByAbility(:SPEED, 1, target, true, true)
  }
)

Battle::AbilityEffects::OnBeingHit.copy(:GOOEY, :TANGLINGHAIR)

Battle::AbilityEffects::OnBeingHit.add(:ILLUSION,
  proc { |ability, user, target, move, battle|
    # NOTE: This intentionally doesn't show the ability splash.
    next if !target.effects[PBEffects::Illusion]
    target.effects[PBEffects::Illusion] = nil
    battle.scene.pbChangePokemon(target, target.pokemon)
    battle.pbDisplay(_INTL("{1}'s illusion wore off!", target.pbThis))
    battle.pbSetSeen(target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:INNARDSOUT,
  proc { |ability, user, target, move, battle|
    next if !target.fainted? || user.dummy
    battle.pbShowAbilitySplash(target)
    if user.takesIndirectDamage?(Battle::Scene::USE_ABILITY_SPLASH)
      battle.scene.pbDamageAnimation(user)
      user.pbReduceHP(target.damageState.hpLost, false)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("¡{1} sufrió daño!", user.pbThis))
      else
        battle.pbDisplay(_INTL("¡{1} sufrió daño por parte de la habilidad {3} de {2}!", user.pbThis,
           target.pbThis(true), target.abilityName))
      end
    end
    battle.pbHideAbilitySplash(target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:IRONBARBS,
  proc { |ability, user, target, move, battle|
    next if !move.pbContactMove?(user)
    battle.pbShowAbilitySplash(target)
    if user.takesIndirectDamage?(Battle::Scene::USE_ABILITY_SPLASH) &&
       user.affectedByContactEffect?(Battle::Scene::USE_ABILITY_SPLASH)
      battle.scene.pbDamageAnimation(user)
      user.pbReduceHP(user.totalhp / 8, false)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("¡{1} sufrió daño!", user.pbThis))
      else
        battle.pbDisplay(_INTL("¡{1} sufrió daño por parte de la habilidad {3} de {2}!", user.pbThis,
           target.pbThis(true), target.abilityName))
      end
    end
    battle.pbHideAbilitySplash(target)
  }
)

Battle::AbilityEffects::OnBeingHit.copy(:IRONBARBS, :ROUGHSKIN)

Battle::AbilityEffects::OnBeingHit.add(:JUSTIFIED,
  proc { |ability, user, target, move, battle|
    next if move.calcType != :DARK
    target.pbRaiseStatStageByAbility(:ATTACK, 1, target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:MUMMY,
  proc { |ability, user, target, move, battle|
    next if !move.pbContactMove?(user)
    next if user.fainted?
    next if user.unstoppableAbility? || user.ability == ability
    next if [:MUMMY, :LINGERINGAROMA].include?(user.ability)
    oldAbil = nil
    battle.pbShowAbilitySplash(target) if user.opposes?(target)
    if user.affectedByContactEffect?(Battle::Scene::USE_ABILITY_SPLASH)
      oldAbil = user.ability
      battle.pbShowAbilitySplash(user, true, false) if user.opposes?(target)
      user.ability = ability
      battle.pbReplaceAbilitySplash(user) if user.opposes?(target)
      if Battle::Scene::USE_ABILITY_SPLASH
        case ability
        when :MUMMY
          msg = _INTL("¡La habilidad de {1} se convirtió en {2}!", user.pbThis, user.abilityName)
        when :LINGERINGAROMA
          msg = _INTL("Un olor persistente se aferra a {1}!", user.pbThis(true))
        end
        battle.pbDisplay(msg)
      else
        battle.pbDisplay(_INTL("¡La habilidad de {1} se convirtió en {2} por {3}!",
           user.pbThis, user.abilityName, target.pbThis(true)))
      end
      battle.pbHideAbilitySplash(user) if user.opposes?(target)
    end
    battle.pbHideAbilitySplash(target) if user.opposes?(target)
    user.pbOnLosingAbility(oldAbil)
    user.pbTriggerAbilityOnGainingIt
  }
)

Battle::AbilityEffects::OnBeingHit.copy(:MUMMY, :LINGERINGAROMA)

Battle::AbilityEffects::OnBeingHit.add(:PERISHBODY,
  proc { |ability, user, target, move, battle|
    next if !move.pbContactMove?(user)
    next if user.fainted?
    next if user.effects[PBEffects::PerishSong] > 0 || target.effects[PBEffects::PerishSong] > 0
    battle.pbShowAbilitySplash(target)
    if user.affectedByContactEffect?(Battle::Scene::USE_ABILITY_SPLASH)
      user.effects[PBEffects::PerishSong] = 4
      user.effects[PBEffects::PerishSongUser] = target.index
      target.effects[PBEffects::PerishSong] = 4
      target.effects[PBEffects::PerishSongUser] = target.index
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("¡Ambos Pokémon se debilitarán en tres turnos!"))
      else
        battle.pbDisplay(_INTL("¡Ambos Pokémon se debilitarán en tres turnos por la habilidad {2} de {1}!",
           target.pbThis(true), target.abilityName))
      end
    end
    battle.pbHideAbilitySplash(target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:POISONPOINT,
  proc { |ability, user, target, move, battle|
    next if !move.pbContactMove?(user)
    next if user.poisoned? || battle.pbRandom(100) >= 30
    battle.pbShowAbilitySplash(target)
    if user.pbCanPoison?(target, Battle::Scene::USE_ABILITY_SPLASH) &&
       user.affectedByContactEffect?(Battle::Scene::USE_ABILITY_SPLASH)
      msg = nil
      if !Battle::Scene::USE_ABILITY_SPLASH
        msg = _INTL("¡La habilidad {2} de {1} envenenó a {3}!", target.pbThis, target.abilityName, user.pbThis(true))
      end
      user.pbPoison(target, msg)
    end
    battle.pbHideAbilitySplash(target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:RATTLED,
  proc { |ability, user, target, move, battle|
    next if ![:BUG, :DARK, :GHOST].include?(move.calcType)
    target.pbRaiseStatStageByAbility(:SPEED, 1, target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:SANDSPIT,
  proc { |ability, user, target, move, battle|
    battle.pbStartWeatherAbility(:Sandstorm, target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:SEEDSOWER,
  proc { |ability, user, target, move, battle|
    next if !move.damagingMove?
    next if battle.field.terrain == :Grassy
    battle.pbShowAbilitySplash(target)
    battle.pbStartTerrain(target, :Grassy)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:STAMINA,
  proc { |ability, user, target, move, battle|
    target.pbRaiseStatStageByAbility(:DEFENSE, 1, target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:STATIC,
  proc { |ability, user, target, move, battle|
    next if !move.pbContactMove?(user)
    next if user.paralyzed? || (battle.pbRandom(100) >= 30)
    battle.pbShowAbilitySplash(target)
    if user.pbCanParalyze?(target, Battle::Scene::USE_ABILITY_SPLASH) &&
       user.affectedByContactEffect?(Battle::Scene::USE_ABILITY_SPLASH)
      msg = nil
      if !Battle::Scene::USE_ABILITY_SPLASH
        msg = _INTL("¡La habilidad {2} de {1} paralizó a {3}! ¡Quizás no pueda moverse!",
           target.pbThis, target.abilityName, user.pbThis(true))
      end
      user.pbParalyze(target, msg)
    end
    battle.pbHideAbilitySplash(target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:THERMALEXCHANGE,
  proc { |ability, user, target, move, battle|
    next if move.calcType != :FIRE
    target.pbRaiseStatStageByAbility(:ATTACK, 1, target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:TOXICDEBRIS,
  proc { |ability, user, target, move, battle|
    next if !move.physicalMove?
    next if target.damageState.substitute
    next if target.pbOpposingSide.effects[PBEffects::ToxicSpikes] >= 2
    battle.pbShowAbilitySplash(target)
    target.pbOpposingSide.effects[PBEffects::ToxicSpikes] += 1
    battle.pbAnimation(:TOXICSPIKES, target, target.pbDirectOpposing)
    battle.pbDisplay(_INTL("Puás tóxicas se esparcieron en el suelo alrededor de {1}!", target.pbOpposingTeam(true)))
    battle.pbHideAbilitySplash(target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:WANDERINGSPIRIT,
  proc { |ability, user, target, move, battle|
    next if !move.pbContactMove?(user)
    next if user.ungainableAbility? || [:RECEIVER, :WONDERGUARD].include?(user.ability_id)
    next if user.uncopyableAbility?
    next if user.hasActiveItem?(:ABILITYSHIELD) || target.hasActiveItem?(:ABILITYSHIELD)
    oldUserAbil   = nil
    oldTargetAbil = nil
    battle.pbShowAbilitySplash(target) if user.opposes?(target)
    if user.affectedByContactEffect?(Battle::Scene::USE_ABILITY_SPLASH)
      battle.pbShowAbilitySplash(user, true, false) if user.opposes?(target)
      oldUserAbil   = user.ability
      oldTargetAbil = target.ability
      user.ability   = oldTargetAbil
      target.ability = oldUserAbil
      if user.opposes?(target)
        battle.pbReplaceAbilitySplash(user)
        battle.pbReplaceAbilitySplash(target)
      end
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("¡{1} ha cambiado habilidades con {2}!", target.pbThis, user.pbThis(true)))
      else
        battle.pbDisplay(_INTL("¡{1} combió su habilidad {2} con la habilidad {4} de {3}!",
           target.pbThis, user.abilityName, user.pbThis(true), target.abilityName))
      end
      if user.opposes?(target)
        battle.pbHideAbilitySplash(user)
        battle.pbHideAbilitySplash(target)
      end
    end
    battle.pbHideAbilitySplash(target) if user.opposes?(target)
    user.pbOnLosingAbility(oldUserAbil)
    target.pbOnLosingAbility(oldTargetAbil)
    user.pbTriggerAbilityOnGainingIt
    target.pbTriggerAbilityOnGainingIt
  }
)

Battle::AbilityEffects::OnBeingHit.add(:WATERCOMPACTION,
  proc { |ability, user, target, move, battle|
    next if move.calcType != :WATER
    target.pbRaiseStatStageByAbility(:DEFENSE, 2, target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:WEAKARMOR,
  proc { |ability, user, target, move, battle|
    next if !move.physicalMove?
    next if !target.pbCanLowerStatStage?(:DEFENSE, target) &&
            !target.pbCanRaiseStatStage?(:SPEED, target)
    battle.pbShowAbilitySplash(target)
    target.pbLowerStatStageByAbility(:DEFENSE, 1, target, false)
    target.pbRaiseStatStageByAbility(:SPEED,
       (Settings::MECHANICS_GENERATION >= 7) ? 2 : 1, target, false)
    battle.pbHideAbilitySplash(target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:WINDPOWER,
  proc { |ability, user, target, move, battle|
    next if !move.windMove?
    next if target.effects[PBEffects::Charge] > 0
    battle.pbShowAbilitySplash(target)
    target.effects[PBEffects::Charge] = 2
    battle.pbDisplay(_INTL("¡Ser golpeado por {1} cargó a {2} de poder!", move.name, target.pbThis(true)))
    battle.pbHideAbilitySplash(target)
  }
)

#===============================================================================
# OnDealingHit handlers
#===============================================================================

Battle::AbilityEffects::OnDealingHit.add(:POISONTOUCH,
  proc { |ability, user, target, move, battle|
    next if !move.contactMove?
    next if battle.pbRandom(100) >= 30
    next if target.hasActiveItem?(:COVERTCLOAK)
    battle.pbShowAbilitySplash(user)
    if target.hasActiveAbility?(:SHIELDDUST) && !battle.moldBreaker
      battle.pbShowAbilitySplash(target)
      if !Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("¡{1} no se ve afectado!", target.pbThis))
      end
      battle.pbHideAbilitySplash(target)
    elsif target.pbCanPoison?(user, Battle::Scene::USE_ABILITY_SPLASH)
      msg = nil
      if !Battle::Scene::USE_ABILITY_SPLASH
        msg = _INTL("¡La habilidad {2} de {1} envenenó a {3}!", user.pbThis, user.abilityName, target.pbThis(true))
      end
      target.pbPoison(user, msg)
    end
    battle.pbHideAbilitySplash(user)
  }
)

Battle::AbilityEffects::OnDealingHit.add(:TOXICCHAIN,
  proc { |ability, user, target, move, battle|
    next if battle.pbRandom(100) >= 30
    next if target.hasActiveItem?(:COVERTCLOAK)
    battle.pbShowAbilitySplash(user)
    if target.hasActiveAbility?(:SHIELDDUST) && !battle.moldBreaker
      battle.pbShowAbilitySplash(target)
      if !Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("¡{1} no se ve afectado!", target.pbThis))
      end
      battle.pbHideAbilitySplash(target)
    elsif target.pbCanPoison?(user, Battle::Scene::USE_ABILITY_SPLASH)
      msg = nil
      if !Battle::Scene::USE_ABILITY_SPLASH
        msg = _INTL("¡{1} fue gravemente envenenado!", target.pbThis)
      end
      target.pbPoison(user, msg, true)
    end
    battle.pbHideAbilitySplash(user)
  }
)
#===============================================================================
# OnEndOfUsingMove handlers
#===============================================================================

#===============================================================================
# Battle Bond
#===============================================================================
# Gen 9+ version that boosts stats instead of becoming Ash-Greninja.
#-------------------------------------------------------------------------------
Battle::AbilityEffects::OnEndOfUsingMove.add(:BATTLEBOND,
  proc { |ability, user, targets, move, battle|
    next if Settings::MECHANICS_GENERATION < 9
    next if user.fainted? || battle.pbAllFainted?(user.idxOpposingSide)
    next if !user.isSpecies?(:GRENINJA) || user.effects[PBEffects::Transform]
    next if battle.battleBond[user.index & 1][user.pokemonIndex]
    numFainted = 0
    targets.each { |b| numFainted += 1 if b.damageState.fainted }
    next if numFainted == 0
    battle.pbShowAbilitySplash(user)
    battle.battleBond[user.index & 1][user.pokemonIndex] = true
    battle.pbDisplay(_INTL("¡{1} se cargó completamente por el lazo con su entrenador!", user.pbThis))
    battle.pbHideAbilitySplash(user)
    showAnim = true
    [:ATTACK, :SPECIAL_ATTACK, :SPEED].each do |stat|
      next if !user.pbCanRaiseStatStage?(stat, user)
      if user.pbRaiseStatStage(stat, 1, user, showAnim)
        showAnim = false
      end
    end
    battle.pbDisplay(_INTL("¡Las características de {1} no pueden subir más!", user.pbThis)) if showAnim
  }
)


Battle::AbilityEffects::OnEndOfUsingMove.add(:BEASTBOOST,
  proc { |ability, user, targets, move, battle|
    next if battle.pbAllFainted?(user.idxOpposingSide)
    numFainted = 0
    targets.each { |b| numFainted += 1 if b.damageState.fainted }
    next if numFainted == 0
    userStats = user.plainStats
    highestStatValue = 0
    userStats.each_value { |value| highestStatValue = value if highestStatValue < value }
    GameData::Stat.each_main_battle do |s|
      next if userStats[s.id] < highestStatValue
      if user.pbCanRaiseStatStage?(s.id, user)
        user.pbRaiseStatStageByAbility(s.id, numFainted, user)
      end
      break
    end
  }
)

Battle::AbilityEffects::OnEndOfUsingMove.add(:CHILLINGNEIGH,
  proc { |ability, user, targets, move, battle|
    next if battle.pbAllFainted?(user.idxOpposingSide)
    numFainted = 0
    targets.each { |b| numFainted += 1 if b.damageState.fainted }
    next if numFainted == 0 || !user.pbCanRaiseStatStage?(:ATTACK, user)
    user.ability_id = :CHILLINGNEIGH   # So the As One abilities can just copy this
    user.pbRaiseStatStageByAbility(:ATTACK, 1, user)
    user.ability_id = ability
  }
)

Battle::AbilityEffects::OnEndOfUsingMove.copy(:CHILLINGNEIGH, :ASONECHILLINGNEIGH)

Battle::AbilityEffects::OnEndOfUsingMove.add(:GRIMNEIGH,
  proc { |ability, user, targets, move, battle|
    next if battle.pbAllFainted?(user.idxOpposingSide)
    numFainted = 0
    targets.each { |b| numFainted += 1 if b.damageState.fainted }
    next if numFainted == 0 || !user.pbCanRaiseStatStage?(:SPECIAL_ATTACK, user)
    user.ability_id = :GRIMNEIGH   # So the As One abilities can just copy this
    user.pbRaiseStatStageByAbility(:SPECIAL_ATTACK, 1, user)
    user.ability_id = ability
  }
)

Battle::AbilityEffects::OnEndOfUsingMove.copy(:GRIMNEIGH, :ASONEGRIMNEIGH)

Battle::AbilityEffects::OnEndOfUsingMove.add(:MAGICIAN,
  proc { |ability, user, targets, move, battle|
    next if battle.futureSight
    next if !move.pbDamagingMove?
    next if user.item
    next if user.wild?
    targets.each do |b|
      next if b.damageState.unaffected || b.damageState.substitute
      next if !b.item
      next if b.unlosableItem?(b.item) || user.unlosableItem?(b.item)
      battle.pbShowAbilitySplash(user)
      if b.hasActiveAbility?(:STICKYHOLD)
        battle.pbShowAbilitySplash(b) if user.opposes?(b)
        if Battle::Scene::USE_ABILITY_SPLASH
          battle.pbDisplay(_INTL("¡El objeto de {1} no puede ser robado!", b.pbThis))
        end
        battle.pbHideAbilitySplash(b) if user.opposes?(b)
        next
      end
      user.item = b.item
      b.item = nil
      b.effects[PBEffects::Unburden] = true if b.hasActiveAbility?(:UNBURDEN)
      if battle.wildBattle? && !user.initialItem && user.item == b.initialItem
        user.setInitialItem(user.item)
        b.setInitialItem(nil)
      end
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("¡{1} robó {2} de {3}!", user.pbThis,
           b.pbThis(true), user.itemName))
      else
        battle.pbDisplay(_INTL("¡{1} robó {2} de {3} con la habilidad {4}!", user.pbThis,
           b.pbThis(true), user.itemName, user.abilityName))
      end
      battle.pbHideAbilitySplash(user)
      user.pbHeldItemTriggerCheck
      break
    end
  }
)

Battle::AbilityEffects::OnEndOfUsingMove.add(:MOXIE,
  proc { |ability, user, targets, move, battle|
    next if battle.pbAllFainted?(user.idxOpposingSide)
    numFainted = 0
    targets.each { |b| numFainted += 1 if b.damageState.fainted }
    next if numFainted == 0 || !user.pbCanRaiseStatStage?(:ATTACK, user)
    user.pbRaiseStatStageByAbility(:ATTACK, numFainted, user)
  }
)

#===============================================================================
# AfterMoveUseFromTarget handlers
#===============================================================================

Battle::AbilityEffects::AfterMoveUseFromTarget.add(:ANGERSHELL,
  proc { |ability, target, user, move, switched_battlers, battle|
    next if !move.damagingMove?
    next if !target.droppedBelowHalfHP
    showAnim = true
    battle.pbShowAbilitySplash(target)
    [:ATTACK, :SPECIAL_ATTACK, :SPEED].each do |stat|
      next if !target.pbCanRaiseStatStage?(stat, user, nil, true)
      if target.pbRaiseStatStage(stat, 1, user, showAnim)
        showAnim = false
      end
    end
    showAnim = true
    [:DEFENSE, :SPECIAL_DEFENSE].each do |stat|
      next if !target.pbCanLowerStatStage?(stat, user, nil, true)
      if target.pbLowerStatStage(stat, 1, user, showAnim)
        showAnim = false
      end
    end
    battle.pbHideAbilitySplash(target)
  }
)

Battle::AbilityEffects::AfterMoveUseFromTarget.add(:BERSERK,
  proc { |ability, target, user, move, switched_battlers, battle|
    next if !move.damagingMove?
    next if !target.droppedBelowHalfHP
    next if !target.pbCanRaiseStatStage?(:SPECIAL_ATTACK, target)
    target.pbRaiseStatStageByAbility(:SPECIAL_ATTACK, 1, target)
  }
)

Battle::AbilityEffects::AfterMoveUseFromTarget.add(:COLORCHANGE,
  proc { |ability, target, user, move, switched_battlers, battle|
    next if target.damageState.calcDamage == 0 || target.damageState.substitute
    next if !move.calcType || GameData::Type.get(move.calcType).pseudo_type
    next if target.pbHasType?(move.calcType) && !target.pbHasOtherType?(move.calcType)
    typeName = GameData::Type.get(move.calcType).name
    battle.pbShowAbilitySplash(target)
    target.pbChangeTypes(move.calcType)
    battle.pbDisplay(_INTL("¡El tipo de {1} cambió a tipo {2} por su habilidad {3}!",
       target.pbThis, typeName, target.abilityName))
    battle.pbHideAbilitySplash(target)
  }
)

Battle::AbilityEffects::AfterMoveUseFromTarget.add(:PICKPOCKET,
  proc { |ability, target, user, move, switched_battlers, battle|
    # NOTE: According to Bulbapedia, this can still trigger to steal the user's
    #       item even if it was switched out by a Red Card. That doesn't make
    #       sense, so this code doesn't do it.
    next if target.wild?
    next if switched_battlers.include?(user.index)   # User was switched out
    next if !move.contactMove?
    next if user.effects[PBEffects::Substitute] > 0 || target.damageState.substitute
    next if target.item || !user.item
    next if user.unlosableItem?(user.item) || target.unlosableItem?(user.item)
    battle.pbShowAbilitySplash(target)
    if user.hasActiveAbility?(:STICKYHOLD)
      battle.pbShowAbilitySplash(user) if target.opposes?(user)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("¡El objeto de {1} no puede ser robado!", user.pbThis))
      end
      battle.pbHideAbilitySplash(user) if target.opposes?(user)
      battle.pbHideAbilitySplash(target)
      next
    end
    target.item = user.item
    user.item = nil
    user.effects[PBEffects::Unburden] = true if user.hasActiveAbility?(:UNBURDEN)
    if battle.wildBattle? && !target.initialItem && target.item == user.initialItem
      target.setInitialItem(target.item)
      user.setInitialItem(nil)
    end
    battle.pbDisplay(_INTL("¡{1} robó {2} de {3}!", target.pbThis,
       user.pbThis(true), target.itemName))
    battle.pbHideAbilitySplash(target)
    target.pbHeldItemTriggerCheck
  }
)

#===============================================================================
# EndOfRoundWeather handlers
#===============================================================================

Battle::AbilityEffects::EndOfRoundWeather.add(:DRYSKIN,
  proc { |ability, weather, battler, battle|
    case weather
    when :Sun, :HarshSun
      if battler.takesIndirectDamage?
        battle.pbShowAbilitySplash(battler)
        battle.scene.pbDamageAnimation(battler)
        battler.pbReduceHP(battler.totalhp / 8, false)
        battle.pbDisplay(_INTL("¡{1} fue herido por la luz solar!", battler.pbThis))
        battle.pbHideAbilitySplash(battler)
        battler.pbItemHPHealCheck
      end
    when :Rain, :HeavyRain
      next if !battler.canHeal?
      battle.pbShowAbilitySplash(battler)
      battler.pbRecoverHP(battler.totalhp / 8)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("Los PS de {1} han sido restaurados.", battler.pbThis))
      else
        battle.pbDisplay(_INTL("La habilidad {2} de {1} restauró sus PS.", battler.pbThis, battler.abilityName))
      end
      battle.pbHideAbilitySplash(battler)
    end
  }
)

Battle::AbilityEffects::EndOfRoundWeather.add(:ICEBODY,
  proc { |ability, weather, battler, battle|
    next unless weather == :Hail
    next if !battler.canHeal?
    battle.pbShowAbilitySplash(battler)
    battler.pbRecoverHP(battler.totalhp / 16)
    if Battle::Scene::USE_ABILITY_SPLASH
      battle.pbDisplay(_INTL("Los PS de {1} han sido restaurados.", battler.pbThis))
    else
      battle.pbDisplay(_INTL("La habilidad {2} de {1} restauró sus PS.", battler.pbThis, battler.abilityName))
    end
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::EndOfRoundWeather.add(:ICEFACE,
  proc { |ability, weather, battler, battle|
    next if weather != :Hail
    next if !battler.canRestoreIceFace || battler.form != 1
    battle.pbShowAbilitySplash(battler)
    if !Battle::Scene::USE_ABILITY_SPLASH
      battle.pbDisplay(_INTL("¡La habilidad {2} de {1} se activó!", battler.pbThis, battler.abilityName))
    end
    battler.pbChangeForm(0, _INTL("¡{1} se transformó!", battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::EndOfRoundWeather.add(:RAINDISH,
  proc { |ability, weather, battler, battle|
    next if ![:Rain, :HeavyRain].include?(weather)
    next if !battler.canHeal?
    battle.pbShowAbilitySplash(battler)
    battler.pbRecoverHP(battler.totalhp / 16)
    if Battle::Scene::USE_ABILITY_SPLASH
      battle.pbDisplay(_INTL("Los PS de {1} han sido restaurados.", battler.pbThis))
    else
      battle.pbDisplay(_INTL("La habilidad {2} de {1} restauró sus PS.", battler.pbThis, battler.abilityName))
    end
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::EndOfRoundWeather.add(:SOLARPOWER,
  proc { |ability, weather, battler, battle|
    next if ![:Sun, :HarshSun].include?(weather)
    next if !battler.takesIndirectDamage?
    battle.pbShowAbilitySplash(battler)
    battle.scene.pbDamageAnimation(battler)
    battler.pbReduceHP(battler.totalhp / 8, false)
    battle.pbDisplay(_INTL("¡{1} fue herido por la luz solar!", battler.pbThis))
    battle.pbHideAbilitySplash(battler)
    battler.pbItemHPHealCheck
  }
)

#===============================================================================
# EndOfRoundHealing handlers
#===============================================================================

Battle::AbilityEffects::EndOfRoundHealing.add(:HEALER,
  proc { |ability, battler, battle|
    next if battle.pbRandom(100) >= 30
    battler.allAllies.each do |b|
      next if b.status == :NONE
      battle.pbShowAbilitySplash(battler)
      oldStatus = b.status
      b.pbCureStatus(Battle::Scene::USE_ABILITY_SPLASH)
      if !Battle::Scene::USE_ABILITY_SPLASH
        case oldStatus
        when :SLEEP
          battle.pbDisplay(_INTL("¡La habilidad {2} de {1} despertó a su compañero!", battler.pbThis, battler.abilityName))
        when :POISON
          battle.pbDisplay(_INTL("¡La habilidad {2} de {1} curó el envenamiento de su compañero!", battler.pbThis, battler.abilityName))
        when :BURN
          battle.pbDisplay(_INTL("¡La habilidad {2} de {1} curó la quemadura de su compañero!", battler.pbThis, battler.abilityName))
        when :PARALYSIS
          battle.pbDisplay(_INTL("¡La habilidad {2} de {1} curó la parálisis de su compañero!", battler.pbThis, battler.abilityName))
        when :FROZEN
          battle.pbDisplay(_INTL("¡La habilidad {2} de {1} descongelo a su compañero!", battler.pbThis, battler.abilityName))
        when :FROSTBITE
          battle.pbDisplay(_INTL("¡La habilidad {2} de {1} descongelo a su compañero!", battler.pbThis, battler.abilityName))
        end
      end
      battle.pbHideAbilitySplash(battler)
    end
  }
)

Battle::AbilityEffects::EndOfRoundHealing.add(:HYDRATION,
  proc { |ability, battler, battle|
    next if battler.status == :NONE
    next if ![:Rain, :HeavyRain].include?(battler.effectiveWeather)
    battle.pbShowAbilitySplash(battler)
    oldStatus = battler.status
    battler.pbCureStatus(Battle::Scene::USE_ABILITY_SPLASH)
    if !Battle::Scene::USE_ABILITY_SPLASH
      case oldStatus
      when :SLEEP
        battle.pbDisplay(_INTL("¡La habilidad {2} de {1} le despertó!", battler.pbThis, battler.abilityName))
      when :POISON
        battle.pbDisplay(_INTL("¡La habilidad {2} de {1} curó su envenamiento!", battler.pbThis, battler.abilityName))
      when :BURN
        battle.pbDisplay(_INTL("¡La habilidad {2} de {1} curó su quemadura!", battler.pbThis, battler.abilityName))
      when :PARALYSIS
        battle.pbDisplay(_INTL("¡La habilidad {2} de {1} curó su parálisis!", battler.pbThis, battler.abilityName))
      when :FROZEN
        battle.pbDisplay(_INTL("¡La habilidad {2} de {1} le descongeló!", battler.pbThis, battler.abilityName))
      when :FROSTBITE
        battle.pbDisplay(_INTL("¡La habilidad {2} de {1} le descongeló!", battler.pbThis, battler.abilityName))
      end
    end
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::EndOfRoundHealing.add(:SHEDSKIN,
  proc { |ability, battler, battle|
    next if battler.status == :NONE
    next unless battle.pbRandom(100) < 30
    battle.pbShowAbilitySplash(battler)
    oldStatus = battler.status
    battler.pbCureStatus(Battle::Scene::USE_ABILITY_SPLASH)
    if !Battle::Scene::USE_ABILITY_SPLASH
      case oldStatus
      when :SLEEP
        battle.pbDisplay(_INTL("¡La habilidad {2} de {1} le despertó!", battler.pbThis, battler.abilityName))
      when :POISON
        battle.pbDisplay(_INTL("¡La habilidad {2} de {1} curó su envenamiento!", battler.pbThis, battler.abilityName))
      when :BURN
        battle.pbDisplay(_INTL("¡La habilidad {2} de {1} curó su quemadura!", battler.pbThis, battler.abilityName))
      when :PARALYSIS
        battle.pbDisplay(_INTL("¡La habilidad {2} de {1} curó su parálisis!", battler.pbThis, battler.abilityName))
      when :FROZEN
        battle.pbDisplay(_INTL("¡La habilidad {2} de {1} le descongeló!", battler.pbThis, battler.abilityName))
      when :FROSTBITE
        battle.pbDisplay(_INTL("¡La habilidad {2} de {1} le descongeló!", battler.pbThis, battler.abilityName))
      end
    end
    battle.pbHideAbilitySplash(battler)
  }
)

#===============================================================================
# EndOfRoundEffect handlers
#===============================================================================

Battle::AbilityEffects::EndOfRoundEffect.add(:BADDREAMS,
  proc { |ability, battler, battle|
    battle.allOtherSideBattlers(battler.index).each do |b|
      next if !b.near?(battler) || !b.asleep?
      battle.pbShowAbilitySplash(battler)
      next if !b.takesIndirectDamage?(Battle::Scene::USE_ABILITY_SPLASH)
      b.pbTakeEffectDamage(b.totalhp / 8) do |hp_lost|
        if Battle::Scene::USE_ABILITY_SPLASH
          battle.pbDisplay(_INTL("¡{1} está inmerso en un sueño agitado!", b.pbThis))
        else
          battle.pbDisplay(_INTL("{1} está inmerso en un sueño agitado debido a {3} de {2}!",
             b.pbThis, battler.pbThis(true), battler.abilityName))
        end
        battle.pbHideAbilitySplash(battler)
      end
    end
  }
)

Battle::AbilityEffects::EndOfRoundEffect.add(:CUDCHEW,
  proc { |ability, battler, battle|
    next if battler.item
    next if !battler.recycleItem || !GameData::Item.get(battler.recycleItem).is_berry?
    case battler.effects[PBEffects::CudChew]
    when 0 # End round after eat berry
      battler.effects[PBEffects::CudChew] += 1
    else # next turn after eat berry
      battler.effects[PBEffects::CudChew] = 0
      battle.pbShowAbilitySplash(battler, true)
      battle.pbHideAbilitySplash(battler)
      battler.pbHeldItemTriggerCheck(battler.recycleItem, true)
      battler.setRecycleItem(nil)
    end
  }
)

Battle::AbilityEffects::EndOfRoundEffect.add(:MOODY,
  proc { |ability, battler, battle|
    randomUp = []
    randomDown = []
    if Settings::MECHANICS_GENERATION >= 8
      GameData::Stat.each_main_battle do |s|
        randomUp.push(s.id) if battler.pbCanRaiseStatStage?(s.id, battler)
        randomDown.push(s.id) if battler.pbCanLowerStatStage?(s.id, battler)
      end
    else
      GameData::Stat.each_battle do |s|
        randomUp.push(s.id) if battler.pbCanRaiseStatStage?(s.id, battler)
        randomDown.push(s.id) if battler.pbCanLowerStatStage?(s.id, battler)
      end
    end
    next if randomUp.length == 0 && randomDown.length == 0
    battle.pbShowAbilitySplash(battler)
    if randomUp.length > 0
      r = battle.pbRandom(randomUp.length)
      battler.pbRaiseStatStageByAbility(randomUp[r], 2, battler, false)
      randomDown.delete(randomUp[r])
    end
    if randomDown.length > 0
      r = battle.pbRandom(randomDown.length)
      battler.pbLowerStatStageByAbility(randomDown[r], 1, battler, false)
    end
    battle.pbHideAbilitySplash(battler)
    battler.pbItemStatRestoreCheck if randomDown.length > 0
    battler.pbItemOnStatDropped
  }
)

Battle::AbilityEffects::EndOfRoundEffect.add(:SPEEDBOOST,
  proc { |ability, battler, battle|
    # A Pokémon's turnCount is 0 if it became active after the beginning of a
    # round
    if battler.turnCount > 0 && battle.choices[battler.index][0] != :Run &&
       battler.pbCanRaiseStatStage?(:SPEED, battler)
      battler.pbRaiseStatStageByAbility(:SPEED, 1, battler)
    end
  }
)

#===============================================================================
# EndOfRoundGainItem handlers
#===============================================================================

Battle::AbilityEffects::EndOfRoundGainItem.add(:BALLFETCH,
  proc { |ability, battler, battle|
    next if battler.item
    next if battle.first_poke_ball.nil?
    battle.pbShowAbilitySplash(battler)
    battler.item = battle.first_poke_ball
    battler.setInitialItem(battler.item) if !battler.initialItem
    battle.first_poke_ball = nil
    battle.pbDisplay(_INTL("¡{1} ha recuperado la {2} lanzada!", battler.pbThis, battler.itemName))
    battle.pbHideAbilitySplash(battler)
    battler.pbHeldItemTriggerCheck
  }
)

Battle::AbilityEffects::EndOfRoundGainItem.add(:HARVEST,
  proc { |ability, battler, battle|
    next if battler.item
    next if !battler.recycleItem || !GameData::Item.get(battler.recycleItem).is_berry?
    if ![:Sun, :HarshSun].include?(battler.effectiveWeather)
      next unless battle.pbRandom(100) < 50
    end
    battle.pbShowAbilitySplash(battler)
    battler.item = battler.recycleItem
    battler.setRecycleItem(nil)
    battler.setInitialItem(battler.item) if !battler.initialItem
    battle.pbDisplay(_INTL("¡{1}ha cosechado una baya {2}!", battler.pbThis, battler.itemName))
    battle.pbHideAbilitySplash(battler)
    battler.pbHeldItemTriggerCheck
  }
)

Battle::AbilityEffects::EndOfRoundGainItem.add(:PICKUP,
  proc { |ability, battler, battle|
    next if battler.item
    foundItem = nil
    fromBattler = nil
    use = 0
    battle.allBattlers.each do |b|
      next if b.index == battler.index
      next if b.effects[PBEffects::PickupUse] <= use
      foundItem   = b.effects[PBEffects::PickupItem]
      fromBattler = b
      use         = b.effects[PBEffects::PickupUse]
    end
    next if !foundItem
    battle.pbShowAbilitySplash(battler)
    battler.item = foundItem
    fromBattler.effects[PBEffects::PickupItem] = nil
    fromBattler.effects[PBEffects::PickupUse]  = 0
    fromBattler.setRecycleItem(nil) if fromBattler.recycleItem == foundItem
    if battle.wildBattle? && !battler.initialItem && fromBattler.initialItem == foundItem
      battler.setInitialItem(foundItem)
      fromBattler.setInitialItem(nil)
    end
    battle.pbDisplay(_INTL("¡{1} ha encontrado un {2}!", battler.pbThis, battler.itemName))
    battle.pbHideAbilitySplash(battler)
    battler.pbHeldItemTriggerCheck
  }
)

#===============================================================================
# CertainSwitching handlers
#===============================================================================

# There aren't any!

#===============================================================================
# TrappingByTarget handlers
#===============================================================================

Battle::AbilityEffects::TrappingByTarget.add(:ARENATRAP,
  proc { |ability, switcher, bearer, battle|
    next true if !switcher.airborne?
  }
)

Battle::AbilityEffects::TrappingByTarget.add(:MAGNETPULL,
  proc { |ability, switcher, bearer, battle|
    next true if switcher.pbHasType?(:STEEL)
  }
)

Battle::AbilityEffects::TrappingByTarget.add(:SHADOWTAG,
  proc { |ability, switcher, bearer, battle|
    next true if !switcher.hasActiveAbility?(:SHADOWTAG)
  }
)

#===============================================================================
# OnSwitchIn handlers
#===============================================================================

Battle::AbilityEffects::OnSwitchIn.add(:AIRLOCK,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler)
    if !Battle::Scene::USE_ABILITY_SPLASH
      battle.pbDisplay(_INTL("¡{1} tiene {2}!", battler.pbThis, battler.abilityName))
    end
    battle.pbDisplay(_INTL("El tiempo atmosférico ya no ejerce ninguna influencia."))
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.copy(:AIRLOCK, :CLOUDNINE)

Battle::AbilityEffects::OnSwitchIn.add(:ANTICIPATION,
  proc { |ability, battler, battle, switch_in|
    next if !battler.pbOwnedByPlayer?
    battlerTypes = battler.pbTypes(true)
    types = battlerTypes
    found = false
    battle.allOtherSideBattlers(battler.index).each do |b|
      b.eachMove do |m|
        next if m.statusMove?
        if types.length > 0
          moveType = m.type
          if Settings::MECHANICS_GENERATION >= 6 && m.function_code == "TypeDependsOnUserIVs"   # Hidden Power
            moveType = pbHiddenPower(b.pokemon)[0]
          end
          eff = Effectiveness.calculate(moveType, *types)
          next if Effectiveness.ineffective?(eff)
          next if !Effectiveness.super_effective?(eff) &&
                  !["OHKO", "OHKOIce", "OHKOHitsUndergroundTarget"].include?(m.function_code)
        elsif !["OHKO", "OHKOIce", "OHKOHitsUndergroundTarget"].include?(m.function_code)
          next
        end
        found = true
        break
      end
      break if found
    end
    if found
      battle.pbShowAbilitySplash(battler)
      battle.pbDisplay(_INTL("¡{1} se ha estremecido!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
    end
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:ASONECHILLINGNEIGH,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("¡{1} tiene dos habilidades!", battler.pbThis))
    battle.pbHideAbilitySplash(battler)
    battler.ability_id = :UNNERVE
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("¡{1} está muy nervioso y no puede comer bayas!", battler.pbOpposingTeam))
    battle.pbHideAbilitySplash(battler)
    battler.ability_id = ability
  }
)

Battle::AbilityEffects::OnSwitchIn.copy(:ASONECHILLINGNEIGH, :ASONEGRIMNEIGH)

Battle::AbilityEffects::OnSwitchIn.add(:AURABREAK,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("¡{1} ha invertido todas las auras!", battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:COMATOSE,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("¡{1} está sumido en un profundo letargo!", battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:COMMANDER,
  proc { |ability, battler, battle, switch_in|
    next if battler.effects[PBEffects::Commander]
    next if defined?(battler.dynamax?) && battler.dynamax?
    showAnim = true
    battler.allAllies.each{|b|
      next if !b || !b.near?(battler) || b.fainted?
      next if !b.isSpecies?(:DONDOZO)
      next if b.effects[PBEffects::Commander]
      next if defined?(b.dynamax?) && b.dynamax?
      battle.pbShowAbilitySplash(battler)
      battle.pbClearChoice(battler.index)
      battle.pbDisplay(_INTL("{1} entra en la boca de {2}!", battler.pbThis, b.pbThis(true)))
      battle.scene.sprites["pokemon_#{battler.index}"].visible = false
      b.effects[PBEffects::Commander] = [battler.index, battler.form]
      battler.effects[PBEffects::Commander] = [b.index]
      [:ATTACK, :DEFENSE, :SPECIAL_ATTACK, :SPECIAL_DEFENSE, :SPEED].each do |stat|
        next if !b.pbCanRaiseStatStage?(stat, b)
        if b.pbRaiseStatStage(stat, 2, b, showAnim)
          showAnim = false
        end
      end
      battle.pbHideAbilitySplash(battler)
      break
    }
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:COSTAR,
  proc { |ability, battler, battle, switch_in|
    battler.allAllies.each do |b|
      next if b.index == battler.index
      next if !b.hasAlteredStatStages? && b.effects[PBEffects::FocusEnergy] == 0
      battle.pbShowAbilitySplash(battler)
      battler.effects[PBEffects::FocusEnergy] = b.effects[PBEffects::FocusEnergy]
      GameData::Stat.each_battle { |stat| battler.stages[stat.id] = b.stages[stat.id] }
      battle.pbDisplay(_INTL("¡{1} copió los cambios de características de {2}!", battler.pbThis, b.pbThis(true)))
      battle.pbHideAbilitySplash(battler)
      break
    end
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:CURIOUSMEDICINE,
  proc { |ability, battler, battle, switch_in|
    next if battler.allAllies.none? { |b| b.hasAlteredStatStages? }
    battle.pbShowAbilitySplash(battler)
    battler.allAllies.each do |b|
      next if !b.hasAlteredStatStages?
      b.pbResetStatStages
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("¡Los cambios en las características de {1} han sido restaurados!", b.pbThis))
      else
        battle.pbDisplay(_INTL("¡Los cambios en las características de {1} han sido restaurados gracias a {3} de {2}!",
           b.pbThis, battler.pbThis(true), battler.abilityName))
      end
    end
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:DARKAURA,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("¡{1} irradia un aura oscura!", battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:DAUNTLESSSHIELD,
  proc { |ability, battler, battle, switch_in|
    next if Settings::MECHANICS_GENERATION >= 9 && battler.ability_triggered?
    battler.pbRaiseStatStageByAbility(:DEFENSE, 1, battler)
    battle.pbSetAbilityTrigger(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:DELTASTREAM,
  proc { |ability, battler, battle, switch_in|
    battle.pbStartWeatherAbility(:StrongWinds, battler, true)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:DESOLATELAND,
  proc { |ability, battler, battle, switch_in|
    battle.pbStartWeatherAbility(:HarshSun, battler, true)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:DOWNLOAD,
  proc { |ability, battler, battle, switch_in|
    oDef = oSpDef = 0
    battle.allOtherSideBattlers(battler.index).each do |b|
      oDef   += b.defense
      oSpDef += b.spdef
    end
    stat = (oDef < oSpDef) ? :ATTACK : :SPECIAL_ATTACK
    battler.pbRaiseStatStageByAbility(stat, 1, battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:DRIZZLE,
  proc { |ability, battler, battle, switch_in|
    battle.pbStartWeatherAbility(:Rain, battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:DROUGHT,
  proc { |ability, battler, battle, switch_in|
    battle.pbStartWeatherAbility(:Sun, battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:ELECTRICSURGE,
  proc { |ability, battler, battle, switch_in|
    next if battle.field.terrain == :Electric
    battle.pbShowAbilitySplash(battler)
    battle.pbStartTerrain(battler, :Electric)
    # NOTE: The ability splash is hidden again in def pbStartTerrain.
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:EMBODYASPECT,
  proc { |ability, battler, battle, switch_in|
    next if !battler.isSpecies?(:OGERPON)
    next if battler.effects[PBEffects::OneUseAbility] == ability
    mask = GameData::Species.get(:OGERPON).form_name
    battle.pbDisplay(_INTL("¡La {1} usada por {2} brilló fuertemente!", mask, battler.pbThis(true)))
    battler.pbRaiseStatStageByAbility(:SPEED, 1, battler)
    battler.effects[PBEffects::OneUseAbility] = ability
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:EMBODYASPECT_1,
  proc { |ability, battler, battle, switch_in|
    next if !battler.isSpecies?(:OGERPON)
    next if battler.effects[PBEffects::OneUseAbility] == ability
    mask = GameData::Species.get(:OGERPON_1).form_name
    battle.pbDisplay(_INTL("¡La {1} usada por {2} brilló fuertemente!", mask, battler.pbThis(true)))
    battler.pbRaiseStatStageByAbility(:SPECIAL_DEFENSE, 1, battler)
    battler.effects[PBEffects::OneUseAbility] = ability
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:EMBODYASPECT_2,
  proc { |ability, battler, battle, switch_in|
    next if !battler.isSpecies?(:OGERPON)
    next if battler.effects[PBEffects::OneUseAbility] == ability
    mask = GameData::Species.get(:OGERPON_2).form_name
    battle.pbDisplay(_INTL("¡La {1} usada por {2} brilló fuertemente!", mask, battler.pbThis(true)))
    battler.pbRaiseStatStageByAbility(:ATTACK, 1, battler)
    battler.effects[PBEffects::OneUseAbility] = ability
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:EMBODYASPECT_3,
  proc { |ability, battler, battle, switch_in|
    next if !battler.isSpecies?(:OGERPON)
    next if battler.effects[PBEffects::OneUseAbility] == ability
    mask = GameData::Species.get(:OGERPON_3).form_name
    battle.pbDisplay(_INTL("¡La {1} usada por {2} brilló fuertemente!", mask, battler.pbThis(true)))
    battler.pbRaiseStatStageByAbility(:DEFENSE, 1, battler)
    battler.effects[PBEffects::OneUseAbility] = ability
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:FAIRYAURA,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("¡{1} irradia un aura feérica!", battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:FOREWARN,
  proc { |ability, battler, battle, switch_in|
    next if !battler.pbOwnedByPlayer?
    highestPower = 0
    forewarnMoves = []
    battle.allOtherSideBattlers(battler.index).each do |b|
      b.eachMove do |m|
        power = m.power
        power = 160 if ["OHKO", "OHKOIce", "OHKOHitsUndergroundTarget"].include?(m.function_code)
        power = 150 if ["PowerHigherWithUserHP"].include?(m.function_code)    # Eruption
        # Counter, Mirror Coat, Metal Burst
        power = 120 if ["CounterPhysicalDamage",
                        "CounterSpecialDamage",
                        "CounterDamagePlusHalf"].include?(m.function_code)
        # Sonic Boom, Dragon Rage, Night Shade, Endeavor, Psywave,
        # Return, Frustration, Crush Grip, Gyro Ball, Hidden Power,
        # Natural Gift, Trump Card, Flail, Grass Knot
        power = 80 if ["FixedDamage20",
                       "FixedDamage40",
                       "FixedDamageUserLevel",
                       "LowerTargetHPToUserHP",
                       "FixedDamageUserLevelRandom",
                       "PowerHigherWithUserHappiness",
                       "PowerLowerWithUserHappiness",
                       "PowerHigherWithUserHP",
                       "PowerHigherWithTargetFasterThanUser",
                       "TypeAndPowerDependOnUserBerry",
                       "PowerHigherWithLessPP",
                       "PowerLowerWithUserHP",
                       "PowerHigherWithTargetWeight"].include?(m.function_code)
        power = 80 if Settings::MECHANICS_GENERATION <= 5 && m.function_code == "TypeDependsOnUserIVs"
        next if power < highestPower
        forewarnMoves = [] if power > highestPower
        forewarnMoves.push(m.name)
        highestPower = power
      end
    end
    if forewarnMoves.length > 0
      battle.pbShowAbilitySplash(battler)
      forewarnMoveName = forewarnMoves[battle.pbRandom(forewarnMoves.length)]
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("¡Se ha detectado el movimiento {2} de {1}!",
          battler.pbThis, forewarnMoveName))
      else
        battle.pbDisplay(_INTL("¡Alerta de {1} ha detectado el movimiento {2}!",
          battler.pbThis, forewarnMoveName))
      end
      battle.pbHideAbilitySplash(battler)
    end
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:FRISK,
  proc { |ability, battler, battle, switch_in|
    next if !battler.pbOwnedByPlayer?
    foes = battle.allOtherSideBattlers(battler.index).select { |b| b.item }
    if foes.length > 0
      battle.pbShowAbilitySplash(battler)
      if Settings::MECHANICS_GENERATION >= 6
        foes.each do |b|
          battle.pbDisplay(_INTL("{1} ha cacheado a {2} y ha hallado {3}!",
             battler.pbThis, b.pbThis(true), b.itemName))
        end
      else
        foe = foes[battle.pbRandom(foes.length)]
        battle.pbDisplay(_INTL("¡{1} ha cacheado al rival y ha hallado {2}!",
           battler.pbThis, foe.itemName))
      end
      battle.pbHideAbilitySplash(battler)
    end
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:GRASSYSURGE,
  proc { |ability, battler, battle, switch_in|
    next if battle.field.terrain == :Grassy
    battle.pbShowAbilitySplash(battler)
    battle.pbStartTerrain(battler, :Grassy)
    # NOTE: The ability splash is hidden again in def pbStartTerrain.
  }
)


Battle::AbilityEffects::OnSwitchIn.add(:HADRONENGINE,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler)
    if battle.field.terrain == :Electric
      battle.pbDisplay(_INTL("¡{1} usó el Terreno Eléctrico para energizar su motor futurista!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
    else
      battle.pbStartTerrain(battler, :Electric)
      battle.pbDisplay(_INTL("¡{1} Electrificó el terreno, para energizar su motor futurista!", battler.pbThis))
    end
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:HOSPITALITY,
  proc { |ability, battler, battle, switch_in|
    next if battler.allAllies.none? { |b| b.hp < b.totalhp }
    battle.pbShowAbilitySplash(battler)
    battler.allAllies.each do |b|
      next if b.hp == b.totalhp
	    amt = (b.totalhp / 4).floor
      b.pbRecoverHP(amt)
      battle.pbDisplay(_INTL("{1} bebió todo el matcha que {2} preparó!", b.pbThis, battler.pbThis(true)))
    end
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:ICEFACE,
  proc { |ability, battler, battle, switch_in|
    next if !battler.isSpecies?(:EISCUE) || battler.form != 1
    next if battler.effectiveWeather != :Hail
    battle.pbShowAbilitySplash(battler)
    if !Battle::Scene::USE_ABILITY_SPLASH
      battle.pbDisplay(_INTL("¡La habilidad {2} de {1} se ha activado!", battler.pbThis, battler.abilityName))
    end
    battler.pbChangeForm(0, _INTL("¡{1} se ha transformado!", battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:IMPOSTER,
  proc { |ability, battler, battle, switch_in|
    next if !switch_in || battler.effects[PBEffects::Transform]
    choice = battler.pbDirectOpposing
    next if choice.fainted?
    next if choice.effects[PBEffects::Transform] ||
            choice.effects[PBEffects::Illusion] ||
            choice.effects[PBEffects::Substitute] > 0 ||
            choice.effects[PBEffects::SkyDrop] >= 0 ||
            choice.semiInvulnerable?
    battle.pbShowAbilitySplash(battler, true)
    battle.pbHideAbilitySplash(battler)
    battle.pbAnimation(:TRANSFORM, battler, choice)
    battle.scene.pbChangePokemon(battler, choice.pokemon)
    battler.pbTransform(choice)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:INTIMIDATE,
  proc { |ability, battler, battle, switch_in|
    next if battler.effects[PBEffects::OneUseAbility] == ability
    battle.pbShowAbilitySplash(battler)
    battle.allOtherSideBattlers(battler.index).each do |b|
      next if !b.near?(battler)
      check_item = true
      if b.hasActiveAbility?([:CONTRARY, :GUARDDOG])
        check_item = false if b.statStageAtMax?(:ATTACK)
      elsif b.statStageAtMin?(:ATTACK)
        check_item = false
      end
      check_ability = b.pbLowerAttackStatStageIntimidate(battler)
      b.pbAbilitiesOnIntimidated if check_ability
      b.pbItemOnIntimidatedCheck if check_item
    end
    battle.pbHideAbilitySplash(battler)
    battler.effects[PBEffects::OneUseAbility] = ability
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:INTREPIDSWORD,
  proc { |ability, battler, battle, switch_in|
    next if Settings::MECHANICS_GENERATION >= 9 && battler.ability_triggered?
    battler.pbRaiseStatStageByAbility(:ATTACK, 1, battler)
    battle.pbSetAbilityTrigger(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:MIMICRY,
  proc { |ability, battler, battle, switch_in|
    next if battle.field.terrain == :None
    Battle::AbilityEffects.triggerOnTerrainChange(ability, battler, battle, false)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:MISTYSURGE,
  proc { |ability, battler, battle, switch_in|
    next if battle.field.terrain == :Misty
    battle.pbShowAbilitySplash(battler)
    battle.pbStartTerrain(battler, :Misty)
    # NOTE: The ability splash is hidden again in def pbStartTerrain.
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:MOLDBREAKER,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("¡{1} ha usado Rompemoldes!", battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:NEUTRALIZINGGAS,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler, true)
    battle.pbHideAbilitySplash(battler)
    battle.pbDisplay(_INTL("¡Un gas reactivo se propaga por toda la zona!"))
    battle.allBattlers.each do |b|
      if b.hasActiveItem?(:ABILITYSHIELD)
        itemname = GameData::Item.get(target.item).name
        @battle.pbDisplay(_INTL("La habilidad de {1} está protegida por los efectos de su {2}!",b.pbThis,itemname))
        next
      end
      # Slow Start - end all turn counts
      b.effects[PBEffects::SlowStart] = 0
      # Truant - let b move on its first turn after Neutralizing Gas disappears
      b.effects[PBEffects::Truant] = false
      # Gorilla Tactics - end choice lock
      if !b.hasActiveItem?([:CHOICEBAND, :CHOICESPECS, :CHOICESCARF])
        b.effects[PBEffects::ChoiceBand] = nil
      end
      # Illusion - end illusions
      if b.effects[PBEffects::Illusion]
        b.effects[PBEffects::Illusion] = nil
        if !b.effects[PBEffects::Transform]
          battle.scene.pbChangePokemon(b, b.pokemon)
          battle.pbDisplay(_INTL("¡{2} de {1} se disipó!", b.pbThis, b.abilityName))
          battle.pbSetSeen(b)
        end
      end
    end
    # Trigger items upon Unnerve being negated
    battler.ability_id = nil   # Allows checking if Unnerve was active before
    had_unnerve = battle.pbCheckGlobalAbility([:UNNERVE, :ASONECHILLINGNEIGH, :ASONEGRIMNEIGH])
    battler.ability_id = :NEUTRALIZINGGAS
    if had_unnerve && !battle.pbCheckGlobalAbility([:UNNERVE, :ASONECHILLINGNEIGH, :ASONEGRIMNEIGH])
      battle.allBattlers.each { |b| b.pbItemsOnUnnerveEnding }
    end
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:ORICHALCUMPULSE,
  proc { |ability, battler, battle, switch_in|
    if [:Sun, :HarshSun].include?(battler.effectiveWeather)
      battle.pbShowAbilitySplash(battler)
      battle.pbDisplay(_INTL("¡{1} absorbió luz solar, incrementando su ataque!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
    else
      battle.pbStartWeatherAbility(:Sun, battler)
      battle.pbDisplay(_INTL("¡{1} invocó el sol, incrementando su ataque!", battler.pbThis))
    end
  }
)


Battle::AbilityEffects::OnSwitchIn.add(:PASTELVEIL,
  proc { |ability, battler, battle, switch_in|
    next if battler.allAllies.none? { |b| b.status == :POISON }
    battle.pbShowAbilitySplash(battler)
    battler.allAllies.each do |b|
      next if b.status != :POISON
      b.pbCureStatus(Battle::Scene::USE_ABILITY_SPLASH)
      if !Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("¡La habilidad {2} de {1} curó el envenenamiento de {3}!",
           battler.pbThis, battler.abilityName, b.pbThis(true)))
      end
    end
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:PRESSURE,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("¡{1} ejerce presión!", battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:PRIMORDIALSEA,
  proc { |ability, battler, battle, switch_in|
    battle.pbStartWeatherAbility(:HeavyRain, battler, true)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:PROTOSYNTHESIS,
  proc { |ability, battler, battle, switch_in|
    next if battler.effects[PBEffects::Transform]
    case ability
    when :PROTOSYNTHESIS then field_check = [:Sun, :HarshSun].include?(battle.field.weather)
    when :QUARKDRIVE     then field_check = battle.field.terrain == :Electric
    end
    if !field_check && !battler.effects[PBEffects::BoosterEnergy] && battler.effects[PBEffects::ParadoxStat]
      battle.pbDisplay(_INTL("¡Los efectos de {2} de {1} se disiparon!", battler.pbThis(true), battler.abilityName))
      battler.effects[PBEffects::ParadoxStat] = nil
    end
    next if battler.effects[PBEffects::ParadoxStat]
    next if !field_check && battler.item != :BOOSTERENERGY
    highestStat = nil
    highestStatVal = 0
    stageMul = [2, 2, 2, 2, 2, 2, 2, 3, 4, 5, 6, 7, 8]
    stageDiv = [8, 7, 6, 5, 4, 3, 2, 2, 2, 2, 2, 2, 2]
    battler.plainStats.each do |stat, val|
      stage = battler.stages[stat] + 6
      realStat = (val.to_f * stageMul[stage] / stageDiv[stage]).floor
      if realStat > highestStatVal
        highestStatVal = realStat 
        highestStat = stat
      end
    end
    if highestStat
      battle.pbShowAbilitySplash(battler)
      if field_check
        case ability
        when :PROTOSYNTHESIS then cause = "sol"
        when :QUARKDRIVE     then cause = "Terreno Eléctrico"
        end
        battle.pbDisplay(_INTL("El #{cause} activó {2} de {1}!", battler.pbThis(true), battler.abilityName))
      elsif battler.item_id == :BOOSTERENERGY
        battler.effects[PBEffects::BoosterEnergy] = true
        battle.pbDisplay(_INTL("{1} usó un {2} para activar su {3}!", battler.pbThis, battler.itemName, battler.abilityName))
        battler.pbHeldItemTriggered(battler.item)
      end
      if [:ATTACK, :SPATK].include?(highestStat)
        conector = 'El'
      elsif [:DEFENSE, :SPDEF, :SPEED].include?(highestStat)
        conector = 'La'
      else
        conector = 'El'
      end
      battler.effects[PBEffects::ParadoxStat] = highestStat
      battle.pbDisplay(_INTL("¡#{conector} {2} de {1} subió!", battler.pbThis, GameData::Stat.get(highestStat).name))
      battle.pbHideAbilitySplash(battler)
    end
  }
)

Battle::AbilityEffects::OnSwitchIn.copy(:PROTOSYNTHESIS, :QUARKDRIVE)


Battle::AbilityEffects::OnSwitchIn.add(:PSYCHICSURGE,
  proc { |ability, battler, battle, switch_in|
    next if battle.field.terrain == :Psychic
    battle.pbShowAbilitySplash(battler)
    battle.pbStartTerrain(battler, :Psychic)
    # NOTE: The ability splash is hidden again in def pbStartTerrain.
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:SANDSTREAM,
  proc { |ability, battler, battle, switch_in|
    battle.pbStartWeatherAbility(:Sandstorm, battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:SCREENCLEANER,
  proc { |ability, battler, battle, switch_in|
    next if battler.pbOwnSide.effects[PBEffects::AuroraVeil] == 0 &&
            battler.pbOwnSide.effects[PBEffects::LightScreen] == 0 &&
            battler.pbOwnSide.effects[PBEffects::Reflect] == 0 &&
            battler.pbOpposingSide.effects[PBEffects::AuroraVeil] == 0 &&
            battler.pbOpposingSide.effects[PBEffects::LightScreen] == 0 &&
            battler.pbOpposingSide.effects[PBEffects::Reflect] == 0
    battle.pbShowAbilitySplash(battler)
    if battler.pbOpposingSide.effects[PBEffects::AuroraVeil] > 0
      battler.pbOpposingSide.effects[PBEffects::AuroraVeil] = 0
      battle.pbDisplay(_INTL("¡El efecto de Velo Aurora en el {1} se ha disipado!", battler.pbOpposingTeam))
    end
    if battler.pbOpposingSide.effects[PBEffects::LightScreen] > 0
      battler.pbOpposingSide.effects[PBEffects::LightScreen] = 0
      battle.pbDisplay(_INTL("¡El efecto de Pantalla de Luz en el {1} se ha disipado!", battler.pbOpposingTeam))
    end
    if battler.pbOpposingSide.effects[PBEffects::Reflect] > 0
      battler.pbOpposingSide.effects[PBEffects::Reflect] = 0
      battle.pbDisplay(_INTL("¡El efecto de Reflejo en el {1} se ha disipado!", battler.pbOpposingTeam))
    end
    if battler.pbOwnSide.effects[PBEffects::AuroraVeil] > 0
      battler.pbOwnSide.effects[PBEffects::AuroraVeil] = 0
      battle.pbDisplay(_INTL("¡El efecto de Velo Aurora en el {1} se ha disipado!", battler.pbTeam))
    end
    if battler.pbOwnSide.effects[PBEffects::LightScreen] > 0
      battler.pbOwnSide.effects[PBEffects::LightScreen] = 0
      battle.pbDisplay(_INTL("¡El efecto de Pantalla de Luz en el {1} se ha disipado!", battler.pbTeam))
    end
    if battler.pbOwnSide.effects[PBEffects::Reflect] > 0
      battler.pbOwnSide.effects[PBEffects::Reflect] = 0
      battle.pbDisplay(_INTL("¡El efecto de Reflejo en el {1} se ha disipado!", battler.pbTeam))
    end
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:SLOWSTART,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler)
    battler.effects[PBEffects::SlowStart] = 5
    if Battle::Scene::USE_ABILITY_SPLASH
      battle.pbDisplay(_INTL("¡{1} no rinde todo lo que podría!", battler.pbThis))
    else
      battle.pbDisplay(_INTL("¡{1} no rinde todo lo que podría por su habilidad {2}!",
         battler.pbThis, battler.abilityName))
    end
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:SNOWWARNING,
  proc { |ability, battler, battle, switch_in|
    battle.pbStartWeatherAbility(:Hail, battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:SUPERSWEETSYRUP,
  proc { |ability, battler, battle, switch_in|
    next if battler.ability_triggered?
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("¡La cubierta de caramelo de {1} emana un aroma super dulce!", battler.pbThis))
    battle.allOtherSideBattlers(battler.index).each do |b|
      next if !b.near?(battler) || b.fainted?
      if b.itemActive? && !b.hasActiveAbility?(:CONTRARY) && b.effects[PBEffects::Substitute] == 0
        next if Battle::ItemEffects.triggerStatLossImmunity(b.item, b, :EVASION, battle, true)
      end
      b.pbLowerStatStageByAbility(:EVASION, 1, battler, false)
    end
    battle.pbHideAbilitySplash(battler)
    battle.pbSetAbilityTrigger(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:SUPREMEOVERLORD,
  proc { |ability, battler, battle, switch_in|
    numFainted = [5, battler.num_fainted_allies].min
    next if numFainted <= 0
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("¡{1} ganó la fuerza de sus aliados caídos!", battler.pbThis))
    battler.effects[PBEffects::SupremeOverlord] = numFainted
    battle.pbHideAbilitySplash(battler)
  }
)


Battle::AbilityEffects::OnSwitchIn.add(:TABLETSOFRUIN,
  proc { |ability, battler, battle, switch_in|
    case ability
    when :TABLETSOFRUIN 
      stat_name = GameData::Stat.get(:ATTACK).name
      conector = 'el'
    when :SWORDOFRUIN  
      stat_name = GameData::Stat.get(:DEFENSE).name
      conector = 'la'
    when :VESSELOFRUIN 
      stat_name = GameData::Stat.get(:SPECIAL_ATTACK).name
      conector = 'el'
    when :BEADSOFRUIN   
      stat_name = GameData::Stat.get(:SPECIAL_DEFENSE).name
      conector = 'la'
    end
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("{2} de {1} redujo {4} {3} de todos los Pokémon a su alrededor!", battler.pbThis, battler.abilityName, stat_name, conector))
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.copy(:TABLETSOFRUIN, :SWORDOFRUIN, :VESSELOFRUIN, :BEADSOFRUIN)


Battle::AbilityEffects::OnSwitchIn.add(:TERAFORMZERO,
  proc { |ability, battler, battle, switch_in|
    next if battler.ability_triggered?
    battle.pbSetAbilityTrigger(battler)
    weather = battle.field.weather
    terrain = battle.field.terrain
    next if weather == :None && terrain == :None
    showSplash = false
    if weather != :None && battle.field.defaultWeather == :None
	  showSplash = true
      battle.pbShowAbilitySplash(battler)
      battle.field.weather = :None
      battle.field.weatherDuration = 0
      case weather
      when :Sun         then battle.pbDisplay(_INTL("El sol vuelve a brillar como siempre."))
      when :Rain        then battle.pbDisplay(_INTL("Ha dejado de llover."))
      when :Sandstorm   then battle.pbDisplay(_INTL("La tormenta de arena ha amainado."))
      when :Hail
        case Settings::HAIL_WEATHER_TYPE
        when 0 then battle.pbDisplay(_INTL("Ha dejado de granizar."))
        when 1 then battle.pbDisplay(_INTL("Ha dejado de nevar."))
        when 2 then battle.pbDisplay(_INTL("Ha dejado de granizar."))
        end
      when :HarshSun    then battle.pbDisplay(_INTL("¡El sol vuelve a brillar como siempre.!"))
      when :HeavyRain   then battle.pbDisplay(_INTL("Ha dejado de llover."))
      when :StrongWinds then battle.pbDisplay(_INTL("¡Las misteriosas turbulencias han amainado!"))
      else
        battle.pbDisplay(_INTL("El clima volvió a la normalidad."))
      end
    end
    if terrain != :None && battle.field.defaultTerrain == :None
      battle.pbShowAbilitySplash(battler) if !showSplash
      battle.field.terrain = :None
      battle.field.terrainDuration = 0
      case terrain
      when :Electric then battle.pbDisplay(_INTL("El campo de corriente eléctrica ha desaparecido."))
      when :Grassy   then battle.pbDisplay(_INTL("La hierba ha desaparecido."))
      when :Psychic  then battle.pbDisplay(_INTL("La niebla se ha disipado."))
      when :Misty    then battle.pbDisplay(_INTL("Ha desaparecido la extraña sensación que se percibía en el terreno de combate."))
      else
        battle.pbDisplay(_INTL("El terreno de batalla volvió a la normalidad."))
      end
    end
    next if !showSplash
    battle.pbHideAbilitySplash(battler)
    battle.allBattlers.each { |b| b.pbCheckFormOnWeatherChange }
    battle.allBattlers.each { |b| b.pbAbilityOnTerrainChange }
    battle.allBattlers.each { |b| b.pbItemTerrainStatBoostCheck }
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:TERAVOLT,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("¡{1} desprende un aura chisporroteante!", battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:TURBOBLAZE,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("¡{1} desprende un aura llameante!", battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:UNNERVE,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("¡{1} está muy nervioso y no puede comer bayas!", battler.pbOpposingTeam))
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:WINDRIDER,
  proc { |ability, battler, battle, switch_in|
    next if battler.pbOwnSide.effects[PBEffects::Tailwind] <= 0
    next if !battler.pbCanRaiseStatStage?(:ATTACK, battler)
    battler.pbRaiseStatStageByAbility(:ATTACK, 1, battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:ZEROTOHERO,
  proc { |ability, battler, battle, switch_in|
    next if !battler.isSpecies?(:PALAFIN)
    next if battler.form == 0 || battler.ability_triggered?
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("¡{1} sufrió una transformación heroíca!", battler.pbThis))
    battle.pbHideAbilitySplash(battler)
    battle.pbSetAbilityTrigger(battler)
  }
)

#===============================================================================
# OnSwitchOut handlers
#===============================================================================

Battle::AbilityEffects::OnSwitchOut.add(:IMMUNITY,
  proc { |ability, battler, endOfBattle|
    next if battler.status != :POISON
    PBDebug.log("[Ability triggered] #{battler.pbThis}'s #{battler.abilityName}")
    battler.status = :NONE
  }
)

Battle::AbilityEffects::OnSwitchOut.add(:INSOMNIA,
  proc { |ability, battler, endOfBattle|
    next if battler.status != :SLEEP
    PBDebug.log("[Ability triggered] #{battler.pbThis}'s #{battler.abilityName}")
    battler.status = :NONE
  }
)

Battle::AbilityEffects::OnSwitchOut.copy(:INSOMNIA, :VITALSPIRIT)

Battle::AbilityEffects::OnSwitchOut.add(:LIMBER,
  proc { |ability, battler, endOfBattle|
    next if battler.status != :PARALYSIS
    PBDebug.log("[Ability triggered] #{battler.pbThis}'s #{battler.abilityName}")
    battler.status = :NONE
  }
)

Battle::AbilityEffects::OnSwitchOut.add(:MAGMAARMOR,
  proc { |ability, battler, endOfBattle|
    next if battler.status != :FROZEN
    PBDebug.log("[Ability triggered] #{battler.pbThis}'s #{battler.abilityName}")
    battler.status = :NONE
  }
)

Battle::AbilityEffects::OnSwitchOut.add(:NATURALCURE,
  proc { |ability, battler, endOfBattle|
    PBDebug.log("[Ability triggered] #{battler.pbThis}'s #{battler.abilityName}")
    battler.status = :NONE
  }
)

Battle::AbilityEffects::OnSwitchOut.add(:REGENERATOR,
  proc { |ability, battler, endOfBattle|
    next if endOfBattle
    PBDebug.log("[Ability triggered] #{battler.pbThis}'s #{battler.abilityName}")
    battler.pbRecoverHP(battler.totalhp / 3, false, false)
  }
)

Battle::AbilityEffects::OnSwitchOut.add(:WATERVEIL,
  proc { |ability, battler, endOfBattle|
    next if battler.status != :BURN
    PBDebug.log("[Ability triggered] #{battler.pbThis}'s #{battler.abilityName}")
    battler.status = :NONE
  }
)

Battle::AbilityEffects::OnSwitchOut.copy(:WATERVEIL, :WATERBUBBLE)

Battle::AbilityEffects::OnSwitchOut.add(:ZEROTOHERO,
  proc { |ability, battler, endOfBattle|
    next if !battler.isSpecies?(:PALAFIN)
    next if battler.form == 1 || endOfBattle
    PBDebug.log("[Ability triggered] #{battler.pbThis}'s #{battler.abilityName}")
    battler.pbChangeForm(1, "")
  }
)

#===============================================================================
# ChangeOnBattlerFainting handlers
#===============================================================================

Battle::AbilityEffects::ChangeOnBattlerFainting.add(:POWEROFALCHEMY,
  proc { |ability, battler, fainted, battle|
    next if battler.opposes?(fainted)
    next if fainted.ungainableAbility? ||
       [:POWEROFALCHEMY, :RECEIVER, :TRACE, :WONDERGUARD].include?(fainted.ability_id)
    next if fainted.uncopyableAbility?
    next if battler.hasActiveItem?(:ABILITYSHIELD)
    battle.pbShowAbilitySplash(battler, true)
    battler.ability = fainted.ability
    battle.pbReplaceAbilitySplash(battler)
    battle.pbDisplay(_INTL("¡El Pokémon ha recibido la habilidad {2} de {1}!", fainted.pbThis, fainted.abilityName))
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::ChangeOnBattlerFainting.copy(:POWEROFALCHEMY, :RECEIVER)

#===============================================================================
# OnBattlerFainting handlers
#===============================================================================

Battle::AbilityEffects::OnBattlerFainting.add(:SOULHEART,
  proc { |ability, battler, fainted, battle|
    battler.pbRaiseStatStageByAbility(:SPECIAL_ATTACK, 1, battler)
  }
)

#===============================================================================
# OnTerrainChange handlers
#===============================================================================

Battle::AbilityEffects::OnTerrainChange.add(:MIMICRY,
  proc { |ability, battler, battle, ability_changed|
    if battle.field.terrain == :None
      # Revert to original typing
      battle.pbShowAbilitySplash(battler)
      battler.pbResetTypes
      battle.pbDisplay(_INTL("¡{1} ha cambiado de nuevo a su tipo normal!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
    else
      # Change to new typing
      terrain_hash = {
        :Electric => :ELECTRIC,
        :Grassy   => :GRASS,
        :Misty    => :FAIRY,
        :Psychic  => :PSYCHIC
      }
      new_type = terrain_hash[battle.field.terrain]
      new_type_name = nil
      if new_type
        type_data = GameData::Type.try_get(new_type)
        new_type = nil if !type_data
        new_type_name = type_data.name if type_data
      end
      if new_type
        battle.pbShowAbilitySplash(battler)
        battler.pbChangeTypes(new_type)
        battle.pbDisplay(_INTL("¡El tipo de {1} cambió a tipo {2}!", battler.pbThis, new_type_name))
        battle.pbHideAbilitySplash(battler)
      end
    end
  }
)

Battle::AbilityEffects::OnTerrainChange.add(:QUARKDRIVE,
  proc { |ability, battler, battle, switch_in|
    Battle::AbilityEffects.triggerOnSwitchIn(ability, battler, battle, switch_in)
  }
)

#===============================================================================
# OnIntimidated handlers
#===============================================================================

Battle::AbilityEffects::OnIntimidated.add(:RATTLED,
  proc { |ability, battler, battle|
    next if Settings::MECHANICS_GENERATION < 8
    battler.pbRaiseStatStageByAbility(:SPEED, 1, battler)
  }
)

#===============================================================================
# CertainEscapeFromBattle handlers
#===============================================================================

Battle::AbilityEffects::CertainEscapeFromBattle.add(:RUNAWAY,
  proc { |ability, battler|
    next true
  }
)

#===============================================================================
# Protean, Libero
#===============================================================================
# Gen 9+ version that only triggers once per switch-in.
#-------------------------------------------------------------------------------
Battle::AbilityEffects::OnTypeChange.add(:PROTEAN,
  proc { |ability, battler, type|
    next if Settings::MECHANICS_GENERATION < 9
    next if GameData::Type.get(type).pseudo_type
    battler.effects[PBEffects::OneUseAbility] = ability
  }
)

Battle::AbilityEffects::OnTypeChange.copy(:PROTEAN, :LIBERO)


#===============================================================================
# Illuminate
#===============================================================================
# Gen 9+ version prevents loss of accuracy and ignores target's evasion bonuses.
#-------------------------------------------------------------------------------
if Settings::MECHANICS_GENERATION >= 9
  Battle::AbilityEffects::StatLossImmunity.copy(:KEENEYE, :ILLUMINATE)
  Battle::AbilityEffects::AccuracyCalcFromUser.copy(:KEENEYE, :ILLUMINATE)
end

#===============================================================================
# Transistor
#===============================================================================
# Gen 9+ version reduces power bonus from 50% to 30%
#-------------------------------------------------------------------------------
Battle::AbilityEffects::DamageCalcFromUser.add(:TRANSISTOR,
  proc { |ability, user, target, move, mults, power, type|
    bonus = (Settings::MECHANICS_GENERATION >= 9) ? 1.3 : 1.5
    mults[:attack_multiplier] *= bonus if type == :ELECTRIC
  }
)

#===============================================================================
# OnOpposingStatGain handlers
#===============================================================================
Battle::AbilityEffects::OnOpposingStatGain.add(:OPPORTUNIST,
  proc { |ability, battler, battle, statUps|
    showAnim = true
    battle.pbShowAbilitySplash(battler)
    statUps.each do |stat, increment|
	  next if !battler.pbCanRaiseStatStage?(stat, battler)
      if battler.pbRaiseStatStage(stat, increment, battler, showAnim)
        showAnim = false
      end
    end
    battle.pbDisplay(_INTL("¡Las características de {1} no pueden subir más!", user.pbThis)) if showAnim
    battle.pbHideAbilitySplash(battler)
    battler.pbItemOpposingStatGainCheck(statUps)
    # Mirror Herb can trigger off this ability.
    if !showAnim 
      opposingStatUps = battle.sideStatUps[battler.idxOwnSide]
      battle.allOtherSideBattlers(battler.index).each do |b|
        next if !b || b.fainted?
        if b.itemActive?
          b.pbItemOpposingStatGainCheck(opposingStatUps)
        end
      end
      opposingStatUps.clear
    end
  }
)

#===============================================================================
# ModifyTypeEffectiveness handlers
#===============================================================================
Battle::AbilityEffects::ModifyTypeEffectiveness.add(:TERASHELL,
  proc { |ability, user, target, move, battle, effectiveness|
    next if !move.damagingMove?
    next if user.hasMoldBreaker?
    next if target.hp < target.totalhp
    next if effectiveness < Effectiveness::NORMAL_EFFECTIVE_MULTIPLIER
    target.damageState.terashell = true
    next Effectiveness::NOT_VERY_EFFECTIVE_MULTIPLIER
  }
)

#===============================================================================
# OnMoveSuccessCheck handlers
#===============================================================================
Battle::AbilityEffects::OnMoveSuccessCheck.add(:TERASHELL,
  proc { |ability, user, target, move, battle|
    next if !target.damageState.terashell
    battle.pbShowAbilitySplash(target)
    battle.pbDisplay(_INTL("¡{1} hizo brillar su caparazón! Está distorsionando la tabla de tipos!", target.pbThis))
    battle.pbHideAbilitySplash(target)
  }
)

#===============================================================================
# OnInflictingStatus handlers
#===============================================================================
Battle::AbilityEffects::OnInflictingStatus.add(:POISONPUPPETEER,
  proc { |ability, user, battler, status|
    next if !user || user.index == battler.index
    next if status != :POISON
    next if battler.effects[PBEffects::Confusion] > 0
    user.battle.pbShowAbilitySplash(user)
    battler.pbConfuse if battler.pbCanConfuse?(user, false, nil)
    user.battle.pbHideAbilitySplash(user)
  }
)
