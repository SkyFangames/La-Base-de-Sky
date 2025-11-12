################################################################################
#
# Items
#
################################################################################

#===============================================================================
# Berry Juice
#===============================================================================
# Healing isn't scaled down while HP is boosted.
#-------------------------------------------------------------------------------
Battle::ItemEffects::HPHeal.add(:BERRYJUICE,
  proc { |item, battler, battle, forced|
    next false if !battler.canHeal?
    next false if !forced && battler.hp > battler.totalhp / 2
    itemName = GameData::Item.get(item).name
    PBDebug.log("[Item triggered] Forced consuming of #{itemName}") if forced
    battle.pbCommonAnimation("UseItem", battler) if !forced
    battler.stopBoostedHPScaling = true
    battler.pbRecoverHP(20)
    if forced
      battle.pbDisplay(_INTL("{1} ha recuperado sus PS.", battler.pbThis))
    else
      battle.pbDisplay(_INTL("¡{1} recuperó PS gracias a {2}!", battler.pbThis, itemName))
    end
    next true
  }
)

#===============================================================================
# Oran Berry
#===============================================================================
# Healing isn't scaled down while HP is boosted.
#-------------------------------------------------------------------------------
Battle::ItemEffects::HPHeal.add(:ORANBERRY,
  proc { |item, battler, battle, forced|
    next false if !battler.canHeal?
    next false if !forced && !battler.canConsumePinchBerry?(false)
    amt = 10
    ripening = false
    if battler.hasActiveAbility?(:RIPEN)
      battle.pbShowAbilitySplash(battler, forced)
      amt *= 2
      ripening = true
    end
    battle.pbCommonAnimation("EatBerry", battler) if !forced
    battle.pbHideAbilitySplash(battler) if ripening
    battler.stopBoostedHPScaling = true
    battler.pbRecoverHP(amt)
    itemName = GameData::Item.get(item).name
    if forced
      PBDebug.log("[Item triggered] Forced consuming of #{itemName}")
      battle.pbDisplay(_INTL("{1} ha recuperado PS.", battler.pbThis))
    else
      battle.pbDisplay(_INTL("¡{1} recuperó unos pocos PS gracias a {2}!", battler.pbThis, itemName))
    end
    next true
  }
)

#===============================================================================
# Shell Bell
#===============================================================================
# Healing isn't scaled down while HP is boosted.
#-------------------------------------------------------------------------------
Battle::ItemEffects::AfterMoveUseFromUser.add(:SHELLBELL,
  proc { |item, user, targets, move, numHits, battle|
    next if !user.canHeal?
    totalDamage = 0
    targets.each { |b| totalDamage += b.damageState.totalHPLost }
    next if totalDamage <= 0
    user.stopBoostedHPScaling = true
    user.pbRecoverHP(totalDamage / 8)
    battle.pbDisplay(_INTL("¡{1} recuperó unos pocos PS gracias a {2}!",
       user.pbThis, user.itemName))
  }
)

#===============================================================================
# Choice Band, Choice Scarf
#===============================================================================
# Damage bonuses are not applied to power moves (Z-Moves, Dynamax Moves).
#-------------------------------------------------------------------------------
Battle::ItemEffects::DamageCalcFromUser.add(:CHOICEBAND,
  proc { |item, user, target, move, mults, baseDmg, type|
    mults[:power_multiplier] *= 1.5 if move.physicalMove? && !move.powerMove?
  }
)

Battle::ItemEffects::DamageCalcFromUser.add(:CHOICESPECS,
  proc { |item, user, target, move, mults, baseDmg, type|
    mults[:power_multiplier] *= 1.5 if move.specialMove? && !move.powerMove?
  }
)


################################################################################
#
# Abilities
#
################################################################################

#===============================================================================
# Gorilla Tactics
#===============================================================================
# Damage bonus is not applied to power moves (Z-Moves, Dynamax Moves).
#-------------------------------------------------------------------------------
Battle::AbilityEffects::DamageCalcFromUser.add(:GORILLATACTICS,
  proc { |ability, user, target, move, mults, baseDmg, type|
    mults[:attack_multiplier] *= 1.5 if move.physicalMove? && !move.powerMove?
  }
)

#===============================================================================
# Imposter
#===============================================================================
# Fails to trigger on certain Dynamax/Terastal forms, or on boss immunities.
# Saves data for Transform target prior to transforming.
#-------------------------------------------------------------------------------
Battle::AbilityEffects::OnSwitchIn.add(:IMPOSTER,
  proc { |ability, battler, battle, switch_in|
    next if !switch_in || battler.effects[PBEffects::Transform]
    next if battler.tera? && battler.tera_type == :STELLAR
    choice = battler.pbDirectOpposing
    next if choice.fainted?
    next if choice.effects[PBEffects::Transform] ||
            choice.effects[PBEffects::Illusion] ||
            choice.effects[PBEffects::Substitute] > 0 ||
            choice.effects[PBEffects::SkyDrop] >= 0 ||
            choice.semiInvulnerable?
    next if choice.pokemon.immunities.include?(:TRANSFORM)
    next if battler.pokemon.immunities.include?(:TRANSFORM)
    next if choice.tera? && choice.tera_form?
    next if battler.tera? && battler.tera_form?
    next if battler.dynamax? && !choice.dynamax_able?
    battle.pbShowAbilitySplash(battler, true)
    battle.pbHideAbilitySplash(battler)
    battle.scene.pbAnimateSubstitute(battler, :hide)
    battler.effects[PBEffects::TransformPokemon] = choice.pokemon
    battle.pbAnimation(:TRANSFORM, battler, choice)
    battler.battlerSprite.prepare_mosaic = true if defined?(battler.battlerSprite)
    battle.scene.pbChangePokemon(battler, choice.pokemon)
    battler.pbTransform(choice)
    battle.scene.pbAnimateSubstitute(battler, :show)
  }
)

#===============================================================================
# Forewarn
#===============================================================================
# Checks the target's base moves instead if any exist.
#-------------------------------------------------------------------------------
Battle::AbilityEffects::OnSwitchIn.add(:FOREWARN,
  proc { |ability, battler, battle, switch_in|
    next if !battler.pbOwnedByPlayer?
    highestPower = 0
    forewarnMoves = []
    battle.allOtherSideBattlers(battler.index).each do |b|
      b.eachMoveWithIndex do |m, i|
        m = b.baseMoves[i] if b.baseMoves[i]
        power = m.power
        power = 160 if ["OHKO", "OHKOIce", "OHKOHitsUndergroundTarget"].include?(m.function_code)
        power = 150 if ["PowerHigherWithUserHP"].include?(m.function_code)
        power = 120 if ["CounterPhysicalDamage",
                        "CounterSpecialDamage",
                        "CounterDamagePlusHalf"].include?(m.function_code)
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
        battle.pbDisplay(_INTL("¡{1} ha sido alertado por {2}!",
          battler.pbThis, forewarnMoveName))
      else
        battle.pbDisplay(_INTL("¡Alerta de {1} detectó {2}!",
          battler.pbThis, forewarnMoveName))
      end
      battle.pbHideAbilitySplash(battler)
    end
  }
)

#===============================================================================
# Innards Out
#===============================================================================
# Damage isn't scaled down if the attacker has boosted HP.
#-------------------------------------------------------------------------------
Battle::AbilityEffects::OnBeingHit.add(:INNARDSOUT,
  proc { |ability, user, target, move, battle|
    next if !target.fainted? || user.dummy
    battle.pbShowAbilitySplash(target)
    if user.takesIndirectDamage?(Battle::Scene::USE_ABILITY_SPLASH)
      battle.scene.pbDamageAnimation(user)
      user.stopBoostedHPScaling = true
      user.pbReduceHP(target.damageState.hpLost, false)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("¡{1} se ha hecho daño!", user.pbThis))
      else
        battle.pbDisplay(_INTL("¡{1} ha isdo dañado por {3} de {2}!", user.pbThis,
           target.pbThis(true), target.abilityName))
      end
    end
    battle.pbHideAbilitySplash(target)
  }
)

#===============================================================================
# Color Change
#===============================================================================
# Type cannot be changed if the user's type is unchangable.
#-------------------------------------------------------------------------------
Battle::AbilityEffects::AfterMoveUseFromTarget.add(:COLORCHANGE,
  proc { |ability, target, user, move, switched_battlers, battle|
    next if !target.canChangeType? || move.calcType == :STELLAR
    next if target.damageState.calcDamage == 0 || target.damageState.substitute
    next if !move.calcType || GameData::Type.get(move.calcType).pseudo_type
    next if target.pbHasType?(move.calcType) && !target.pbHasOtherType?(move.calcType)
    typeName = GameData::Type.get(move.calcType).name
    battle.pbShowAbilitySplash(target)
    target.pbChangeTypes(move.calcType)
    battle.pbDisplay(_INTL("¡El tipo de {1} cambió a {2} debido a su {3}!",
       target.pbThis, typeName, target.abilityName))
    battle.pbHideAbilitySplash(target)
  }
)

#===============================================================================
# Mimicry
#===============================================================================
# Type cannot be changed if the user's type is unchangable.
#-------------------------------------------------------------------------------
Battle::AbilityEffects::OnTerrainChange.add(:MIMICRY,
  proc { |ability, battler, battle, ability_changed|
    next if !battler.canChangeType?
    if battle.field.terrain == :None
      battle.pbShowAbilitySplash(battler)
      battler.pbResetTypes
      battle.pbDisplay(_INTL("¡{1} ha recuperado su tipo!", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
    else
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
        battle.pbDisplay(_INTL("¡El tipo de {1} cambió a {2}!", battler.pbThis, new_type_name))
        battle.pbHideAbilitySplash(battler)
      end
    end
  }
)


################################################################################
#
# Moves
#
################################################################################

#===============================================================================
# Endeavor
#===============================================================================
# Damage dealt is based on the user/target's non-boosted HP.
#-------------------------------------------------------------------------------
class Battle::Move::LowerTargetHPToUserHP < Battle::Move::FixedDamageMove
  def pbFixedDamage(user, target)
    return target.real_hp - user.real_hp
  end
end

#===============================================================================
# Super Fang, Nature's Madness, etc.
#===============================================================================
# Fails when used on a Raid boss.
# Damage dealt is based on the target's non-boosted HP.
#-------------------------------------------------------------------------------
class Battle::Move::FixedDamageHalfTargetHP < Battle::Move::FixedDamageMove
  def pbFailsAgainstTarget?(user, target, show_message)
    if target.isRaidBoss?
      @battle.pbDisplay(_INTL("¡Pero falló!")) if show_message
      return true
    end
    return false
  end
  
  def pbFixedDamage(user, target)
    return (target.real_hp / 2.0).round
  end
end

#===============================================================================
# Pain Split
#===============================================================================
# Changes to HP is based on user/target's non-boosted HP.
#-------------------------------------------------------------------------------
class Battle::Move::UserTargetAverageHP < Battle::Move
  def pbEffectAgainstTarget(user,target)
    newHP = (user.real_hp + target.real_hp) / 2
    if user.real_hp > newHP
	  user.stopBoostedHPScaling = true
	  user.pbReduceHP(user.real_hp - newHP, false, false)
    elsif user.real_hp < newHP
	  user.stopBoostedHPScaling = true
	  user.pbRecoverHP(newHP - user.real_hp, false)
    end
    if target.real_hp > newHP
	  target.stopBoostedHPScaling = true
	  target.pbReduceHP(target.real_hp - newHP, false, false)
    elsif target.real_hp < newHP
	  target.stopBoostedHPScaling = true
	  target.pbRecoverHP(newHP - target.real_hp, false)
    end
    @battle.pbDisplay(_INTL("¡Los combatientes comparten su daño!"))
    user.pbItemHPHealCheck
    target.pbItemHPHealCheck
  end
end

#===============================================================================
# Crush Grip, Wring Out
#===============================================================================
# Damage dealt is based on the target's non-boosted HP.
#-------------------------------------------------------------------------------
class Battle::Move::PowerHigherWithTargetHP < Battle::Move
  def pbBaseDamage(baseDmg, user, target)
    return [120 * target.real_hp / target.real_totalhp, 1].max
  end
end

#===============================================================================
# Hard Press
#===============================================================================
# Damage dealt is based on the target's non-boosted HP.
#-------------------------------------------------------------------------------
class Battle::Move::PowerHigherWithTargetHP100PowerRange < Battle::Move
  def pbBaseDamage(baseDmg, user, target)
    return [100 * target.real_hp / target.real_totalhp, 1].max
  end
end

#===============================================================================
# Recoil moves
#===============================================================================
# Recoil damage isn't scaled down if the user has boosted HP.
#-------------------------------------------------------------------------------
class Battle::Move::RecoilMove < Battle::Move
  def pbEffectAfterAllHits(user, target)
    return if target.damageState.unaffected
    return if !user.takesIndirectDamage?
    return if user.hasActiveAbility?(:ROCKHEAD)
    amt = pbRecoilDamage(user, target)
    amt = 1 if amt < 1
    user.stopBoostedHPScaling = true
    user.pbReduceHP(amt, false)
    @battle.pbDisplay(_INTL("¡{1} se ha dañado por el retroceso!", user.pbThis))
    user.pbItemHPHealCheck
  end
end

#===============================================================================
# Strength Sap
#===============================================================================
# Healing isn't scaled down when the user has boosted HP.
#-------------------------------------------------------------------------------
class Battle::Move::HealUserByTargetAttackLowerTargetAttack1 < Battle::Move
  alias dx_pbEffectAgainstTarget pbEffectAgainstTarget
  def pbEffectAgainstTarget(user, target)
    user.stopBoostedHPScaling = true
    dx_pbEffectAgainstTarget(user, target)
    user.stopBoostedHPScaling = false
  end
end

#===============================================================================
# Mimic
#===============================================================================
# Move fails when attempting to Mimic a power move (Z-Move/Dynamax Move).
# Records mimicked move as a new base move to revert to if necessary.
#-------------------------------------------------------------------------------
class Battle::Move::ReplaceMoveThisBattleWithTargetLastMoveUsed < Battle::Move
  def pbFailsAgainstTarget?(user, target, show_message)
    lastMoveData = GameData::Move.try_get(target.lastRegularMoveUsed)
    if !lastMoveData || lastMoveData.powerMove? ||
       user.pbHasMove?(target.lastRegularMoveUsed) ||
       @moveBlacklist.include?(lastMoveData.function_code) ||
       lastMoveData.type == :SHADOW
      @battle.pbDisplay(_INTL("¡Pero falló!")) if show_message
      return true
    end
    return false
  end
  
  def pbEffectAgainstTarget(user, target)
    user.eachMoveWithIndex do |m, i|
      next if m.id != @id
      newMove = Pokemon::Move.new(target.lastRegularMoveUsed)
      user.moves[i] = Battle::Move.from_pokemon_move(@battle, newMove)
      user.baseMoves[i] = user.moves[i] if !user.baseMoves.empty?
      @battle.pbDisplay(_INTL("¡{1} aprendió {2}!", user.pbThis, newMove.name))
      user.pbCheckFormOnMovesetChange
      break
    end
  end
end

#===============================================================================
# Sketch
#===============================================================================
# Move fails when attempting to Sketch a power move (Z-Move/Dynamax Move).
#-------------------------------------------------------------------------------
class Battle::Move::ReplaceMoveWithTargetLastMoveUsed < Battle::Move
  def pbFailsAgainstTarget?(user, target, show_message)
    lastMoveData = GameData::Move.try_get(target.lastRegularMoveUsed)
    if !lastMoveData || lastMoveData.powerMove? ||
       user.pbHasMove?(target.lastRegularMoveUsed) ||
       @moveBlacklist.include?(lastMoveData.function_code) ||
       lastMoveData.type == :SHADOW
      @battle.pbDisplay(_INTL("¡Pero falló!")) if show_message
      return true
    end
    return false
  end
end

#===============================================================================
# Me First
#===============================================================================
# Move fails when attempting to copy a target's power move (Z-Move/Dynamax Move).
#-------------------------------------------------------------------------------
class Battle::Move::UseMoveTargetIsAboutToUse < Battle::Move
  def pbFailsAgainstTarget?(user, target, show_message)
    return true if pbMoveFailedTargetAlreadyMoved?(target, show_message)
    oppMove = @battle.choices[target.index][2]
    if !oppMove || oppMove.statusMove? || oppMove.powerMove? || @moveBlacklist.include?(oppMove.function)
      @battle.pbDisplay(_INTL("¡Pero falló!")) if show_message
      return true
    end
    return false
  end
end

#===============================================================================
# Spite
#===============================================================================
# Reduced PP of a move is properly applied to the base move as well, if any.
#-------------------------------------------------------------------------------
class Battle::Move::LowerPPOfTargetLastMoveBy4 < Battle::Move
  def pbFailsAgainstTarget?(user, target, show_message)
    if !target.lastRegularMoveUsed || target.pokemon.immunities.include?(:PPLOSS)
      @battle.pbDisplay(_INTL("¡Pero falló!")) if show_message
      return true
    end
    if target.powerMoveIndex >= 0
      last_move = target.moves[target.powerMoveIndex]
    else
      last_move = target.pbGetMoveWithID(target.lastRegularMoveUsed)
    end
    if !last_move || last_move.pp == 0 || last_move.total_pp <= 0
      @battle.pbDisplay(_INTL("¡Pero falló!")) if show_message
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user, target)
    showMsg = false
    if target.powerMoveIndex >= 0
      last_move = target.moves[target.powerMoveIndex]
      if target.dynamax?
        base_move = target.baseMoves[target.powerMoveIndex]
        if base_move && base_move.pp > 0
          reduction = [4, base_move.pp].min
          target.pbSetPP(base_move, base_move.pp - reduction)
          move_name = base_move.name
          showMsg = true
        end
      end
    else
      last_move = target.pbGetMoveWithID(target.lastRegularMoveUsed)
    end
    if last_move && last_move.pp > 0
      reduction = [4, last_move.pp].min
      target.pbSetPP(last_move, last_move.pp - reduction)
      showMsg = true
    end
    move_name = last_move.name if !move_name
    @battle.pbDisplay(_INTL("¡Ha reducido los PP de {2} de {1} en {3}!",
                            target.pbThis(true), move_name, reduction))
  end
end

#===============================================================================
# Eerie Spell
#===============================================================================
# Reduced PP of a move is properly applied to the base move as well, if any.
#-------------------------------------------------------------------------------
class Battle::Move::LowerPPOfTargetLastMoveBy3 < Battle::Move
  def pbAdditionalEffect(user, target)
    return if target.fainted? || target.damageState.substitute
    return if target.pokemon.immunities.include?(:PPLOSS)
    return if !target.lastRegularMoveUsed
    showMsg = false
    if target.powerMoveIndex >= 0
      last_move = target.moves[target.powerMoveIndex]
      if target.dynamax?
        base_move = target.baseMoves[target.powerMoveIndex]
        if base_move && base_move.pp > 0
          reduction = [3, base_move.pp].min
          target.pbSetPP(base_move, base_move.pp - reduction)
          move_name = base_move.name
          showMsg = true
        end
      end
    else
      last_move = target.pbGetMoveWithID(target.lastRegularMoveUsed)
    end
    if last_move && last_move.pp > 0
      reduction = [3, last_move.pp].min
      target.pbSetPP(last_move, last_move.pp - reduction)
      showMsg = true
    end
    move_name = last_move.name if !move_name
    @battle.pbDisplay(_INTL("¡Ha reducido los PP de {2} de {1} en {3}!",
                            target.pbThis(true), move_name, reduction))
  end
end

#===============================================================================
# Throat Chop
#===============================================================================
# Fails to apply effect on targets with boss immunity.
#-------------------------------------------------------------------------------
class Battle::Move::DisableTargetSoundMoves < Battle::Move
  alias dx_pbAdditionalEffect pbAdditionalEffect
  def pbAdditionalEffect(user, target)
    return if !target.fainted? && target.pokemon.immunities.include?(:DISABLE)
    dx_pbAdditionalEffect(user, target)
  end
end

#===============================================================================
# Transform
#===============================================================================
# Fails on users or targets with boss immunity.
# Fails if the user or target is in a Terastal form.
# Fails if the user is Dynamaxed and the target is unable to be Dynamaxed.
# Saves data for Transform target prior to transforming.
#-------------------------------------------------------------------------------
class Battle::Move::TransformUserIntoTarget < Battle::Move
  alias dx_pbMoveFailed? pbMoveFailed?
  def pbMoveFailed?(user, targets)
    if user.tera_form? || (user.tera? && user.tera_type == :STELLAR)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return true
    end
    if user.pokemon.immunities.include?(:TRANSFORM)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return true
    end
    return dx_pbMoveFailed?(user, targets)
  end

  alias dx_pbFailsAgainstTarget? pbFailsAgainstTarget?
  def pbFailsAgainstTarget?(user, target, show_message)
    if target.pokemon.immunities.include?(:TRANSFORM)
      @battle.pbDisplay(_INTL("¡{1} es inmune a ser copiado!", target.pbThis)) if show_message
      return true
    end
    if user.dynamax? && !target.dynamax_able?
      @battle.pbDisplay(_INTL("¡Pero falló!")) if show_message
      return true
    end
    if target.tera_form?
      @battle.pbDisplay(_INTL("¡Pero falló!")) if show_message
      return true
    end
    return dx_pbFailsAgainstTarget?(user, target, show_message)
  end
  
  alias dx_pbEffectAgainstTarget pbEffectAgainstTarget
  def pbEffectAgainstTarget(user, target)
    @battle.scene.pbAnimateSubstitute(user, :hide)
    dx_pbEffectAgainstTarget(user, target)
  end
  
  def pbShowAnimation(id, user, targets, hitNum = 0, showAnimation = true)
    super
    user.effects[PBEffects::TransformPokemon] = targets[0].pokemon
    user.battlerSprite.prepare_mosaic = true if defined?(user.battlerSprite)
    @battle.scene.pbChangePokemon(user, targets[0].pokemon)
    @battle.scene.pbAnimateSubstitute(user, :show)
  end
end

#===============================================================================
# Horn Drill, Guillotine
#===============================================================================
# Fails on targets with boss immunity or Dynamax.
#-------------------------------------------------------------------------------
class Battle::Move::OHKO < Battle::Move::FixedDamageMove
  alias dx_pbFailsAgainstTarget? pbFailsAgainstTarget?
  def pbFailsAgainstTarget?(user, target, show_message)
    if target.pokemon.immunities.include?(:OHKO)
      @battle.pbDisplay(_INTL("¡{1} es inmune a ataques de KO directo!", target.pbThis)) if show_message
      return true
    end
    if target.dynamax?
      @battle.pbDisplay(_INTL("¡No afecta a {1}!", target.pbThis)) if show_message
      return true
    end
    return dx_pbFailsAgainstTarget?(user, target, show_message)
  end
end

#===============================================================================
# Sheer Cold
#===============================================================================
# Fails on targets with boss immunity or Dynamax.
#-------------------------------------------------------------------------------
class Battle::Move::OHKOIce < Battle::Move::OHKO
  def pbFailsAgainstTarget?(user, target, show_message)
    if target.pbHasType?(:ICE)
      @battle.pbDisplay(_INTL("¡Pero falló!")) if show_message
      return true
    end
    return super
  end
end

#===============================================================================
# Fissure
#===============================================================================
# Fails on targets with boss immunity or Dynamax.
#-------------------------------------------------------------------------------
class Battle::Move::OHKOHitsUndergroundTarget < Battle::Move::OHKO
  alias dx_pbFailsAgainstTarget? pbFailsAgainstTarget?
  def pbFailsAgainstTarget?(user, target, show_message)
    return super
  end
end

#===============================================================================
# Curse
#===============================================================================
# Fails when used by those with boss immunity when the move would KO the user.
#-------------------------------------------------------------------------------
class Battle::Move::CurseTargetOrLowerUserSpd1RaiseUserAtkDef1 < Battle::Move
  alias dx_pbMoveFailed? pbMoveFailed?
  def pbMoveFailed?(user, targets)
    if user.pokemon.immunities.include?(:SELFKO) && 
       user.pbHasType?(:GHOST) && user.real_hp <= user.real_totalhp / 2
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return true
    end
    return dx_pbMoveFailed?(user,targets)
  end
end

#===============================================================================
# Steel Beam
#===============================================================================
# Fails when used by those with boss immunity when the move would KO the user.
#-------------------------------------------------------------------------------
class Battle::Move::UserLosesHalfOfTotalHP < Battle::Move
  def pbMoveFailed?(user, targets)
    if user.pokemon.immunities.include?(:SELFKO) && 
       user.takesIndirectDamage? && user.real_hp <= user.real_totalhp / 2
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return true
    end
    return false
  end
end

#===============================================================================
# Mind Blown
#===============================================================================
# Fails when used by those with boss immunity when the move would KO the user.
#-------------------------------------------------------------------------------
class Battle::Move::UserLosesHalfOfTotalHPExplosive < Battle::Move
  alias dx_pbMoveFailed? pbMoveFailed?
  def pbMoveFailed?(user, targets)
    if user.pokemon.immunities.include?(:SELFKO) && 
       user.takesIndirectDamage? && user.real_hp <= user.real_totalhp / 2
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return true
    end
    return dx_pbMoveFailed?(user,targets)
  end
end

#===============================================================================
# Self-Destruct, Explosion, Misty Explosion
#===============================================================================
# Fails when used by those with boss immunity. Ensures fainting even with boosted HP.
#-------------------------------------------------------------------------------
class Battle::Move::UserFaintsExplosive < Battle::Move
  alias dx_pbMoveFailed? pbMoveFailed?
  def pbMoveFailed?(user, targets)
    if user.pokemon.immunities.include?(:SELFKO)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return true
    end
    return dx_pbMoveFailed?(user,targets)
  end
  
  def pbSelfKO(user)
    return if user.fainted?
    user.stopBoostedHPScaling = true
    user.pbReduceHP(user.hp, false)
    user.pbItemHPHealCheck
  end
end

#===============================================================================
# Final Gambit
#===============================================================================
# Fails when used by those with boss immunity. Ensures fainting even with boosted HP.
#-------------------------------------------------------------------------------
class Battle::Move::UserFaintsFixedDamageUserHP < Battle::Move::FixedDamageMove
  def pbMoveFailed?(user, targets)
    if user.pokemon.immunities.include?(:SELFKO)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return true
    end
    return false
  end
  
  def pbSelfKO(user)
    return if user.fainted?
    user.stopBoostedHPScaling = true
    user.pbReduceHP(user.hp, false)
    user.pbItemHPHealCheck
  end
end

#===============================================================================
# Memento
#===============================================================================
# Fails when used by those with boss immunity. Ensures fainting even with boosted HP.
#-------------------------------------------------------------------------------
class Battle::Move::UserFaintsLowerTargetAtkSpAtk2 < Battle::Move::TargetMultiStatDownMove
  def pbMoveFailed?(user, targets)
    if user.pokemon.immunities.include?(:SELFKO)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return true
    end
    return false
  end
  
  def pbSelfKO(user)
    return if user.fainted?
    user.stopBoostedHPScaling = true
    user.pbReduceHP(user.hp, false)
    user.pbItemHPHealCheck
  end
end

#===============================================================================
# Healing Wish
#===============================================================================
# Fails when used by those with boss immunity. Ensures fainting even with boosted HP.
#-------------------------------------------------------------------------------
class Battle::Move::UserFaintsHealAndCureReplacement < Battle::Move
  alias dx_pbMoveFailed? pbMoveFailed?
  def pbMoveFailed?(user, targets)
    if user.pokemon.immunities.include?(:SELFKO)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return true
    end
    return dx_pbMoveFailed?(user,targets)
  end

  def pbSelfKO(user)
    return if user.fainted?
    user.stopBoostedHPScaling = true
    user.pbReduceHP(user.hp, false)
    user.pbItemHPHealCheck
    @battle.positions[user.index].effects[PBEffects::HealingWish] = true
  end
end

#===============================================================================
# Lunar Dance
#===============================================================================
# Fails when used by those with boss immunity. Ensures fainting even with boosted HP.
#-------------------------------------------------------------------------------
class Battle::Move::UserFaintsHealAndCureReplacementRestorePP < Battle::Move
  alias dx_pbMoveFailed? pbMoveFailed?
  def pbMoveFailed?(user, targets)
    if user.pokemon.immunities.include?(:SELFKO)
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return true
    end
    return dx_pbMoveFailed?(user,targets)
  end

  def pbSelfKO(user)
    return if user.fainted?
    user.stopBoostedHPScaling = true
    user.pbReduceHP(user.hp, false)
    user.pbItemHPHealCheck
    @battle.positions[user.index].effects[PBEffects::LunarDance] = true
  end
end

#===============================================================================
# Perish Song
#===============================================================================
# Fails on targets with boss immunity, or if used while a Raid boss is on the field.
#-------------------------------------------------------------------------------
class Battle::Move::StartPerishCountsForAllBattlers < Battle::Move
  def pbMoveFailed?(user, targets)
    if user.isRaidBoss? || user.pbDirectOpposing.isRaidBoss?
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return true
    end
    failed = true
    targets.each do |b|
      next if b.effects[PBEffects::PerishSong] > 0
      next if b.pokemon.immunities.include?(:OHKO)
      failed = false
      break
    end
    if failed
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return true
    end
    return false
  end

  def pbFailsAgainstTarget?(user, target, show_message)
    return true if target.effects[PBEffects::PerishSong] > 0
    return true if target.pokemon.immunities.include?(:OHKO)
    return false
  end
end

#===============================================================================
# Destiny Bond
#===============================================================================
# Fails when used by a Raid boss.
#-------------------------------------------------------------------------------
class Battle::Move::AttackerFaintsIfUserFaints < Battle::Move
  alias dx_pbMoveFailed? pbMoveFailed?
  def pbMoveFailed?(user, targets)
    if user.isRaidBoss?
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return true
    end
    return dx_pbMoveFailed?(user, targets)
  end
end

#===============================================================================
# Substitute
#===============================================================================
# Fails when used by a Raid boss. Sacrificed HP isn't scaled down for boosted HP. 
#-------------------------------------------------------------------------------
class Battle::Move::UserMakeSubstitute < Battle::Move
  alias dx_pbMoveFailed? pbMoveFailed?
  def pbMoveFailed?(user, targets)
    if user.isRaidBoss?
      @battle.pbDisplay(_INTL("¡Pero falló!"))
      return true
    end
    return dx_pbMoveFailed?(user, targets)
  end
  
  def pbOnStartUse(user, targets)
    user.stopBoostedHPScaling = true
    user.pbReduceHP(@subLife, false, false)
    user.pbItemHPHealCheck
  end
end

#===============================================================================
# Pluck, Bug Bite
#===============================================================================
# Effect fails when used on a Raid boss.
#-------------------------------------------------------------------------------
class Battle::Move::UserConsumeTargetBerry < Battle::Move
  def pbEffectAfterAllHits(user, target)
    return if user.fainted? || target.fainted?
    return if target.damageState.unaffected || target.damageState.substitute || target.isRaidBoss?
    return if !target.item || !target.item.is_berry? || target.unlosableItem?(target.item)
    return if target.hasActiveAbility?(:STICKYHOLD) && !@battle.moldBreaker
    item = target.item
    itemName = target.itemName
    user.setBelched
    target.pbRemoveItem
    if defined?(target.stolenItemData) && target.initialItem == item
      @battle.initialItems[target.index & 1][target.pokemonIndex] = nil
    end
    @battle.pbDisplay(_INTL("¡{1} robó y se comió la {2}!", user.pbThis, itemName))
    user.pbHeldItemTriggerCheck(item.id, false)
    user.pbSymbiosis
  end
end

#===============================================================================
# Incinerate
#===============================================================================
# Effect fails when used on a Raid boss.
#-------------------------------------------------------------------------------
class Battle::Move::DestroyTargetBerryOrGem < Battle::Move
  def pbEffectWhenDealingDamage(user, target)
    return if target.damageState.substitute || target.damageState.berryWeakened || target.isRaidBoss?
    return if !target.item || (!target.item.is_berry? &&
              !(Settings::MECHANICS_GENERATION >= 6 && target.item.is_gem?))
    return if target.unlosableItem?(target.item)
    return if target.hasActiveAbility?(:STICKYHOLD) && !@battle.moldBreaker
    item_name = target.itemName
    target.pbRemoveItem
    @battle.pbDisplay(_INTL("{1}'s {2} was incinerated!", target.pbThis, item_name))
  end
end

#===============================================================================
# Roar, Whirlwind
#===============================================================================
# Fails to work on Dynamax targets or those with boss immunity.
#-------------------------------------------------------------------------------
class Battle::Move::SwitchOutTargetStatusMove < Battle::Move
  alias dx_pbFailsAgainstTarget? pbFailsAgainstTarget?
  def pbFailsAgainstTarget?(user, target, show_message)
    if target.dynamax? || target.isRaidBoss? || target.pokemon.immunities.include?(:ESCAPE)
      @battle.pbDisplay(_INTL("¡Pero falló!")) if show_message
      return true
    end
    return dx_pbFailsAgainstTarget?(user, target, show_message)
  end
end

#===============================================================================
# Dragon Tail, Circle Throw
#===============================================================================
# Forced flee fails to work on Dynamax targets or those with boss immunity.
#-------------------------------------------------------------------------------
class Battle::Move::SwitchOutTargetDamagingMove < Battle::Move
  alias dx_pbEffectAgainstTarget pbEffectAgainstTarget
  def pbEffectAgainstTarget(user, target)
    return if target.dynamax? || target.isRaidBoss? || target.pokemon.immunities.include?(:ESCAPE)
    dx_pbEffectAgainstTarget(user, target)
  end
end

#===============================================================================
# Fly, Dig, Dive, Bounce, Shadow Force, Phantom Force, Sky Drop
#===============================================================================
# Raid bosses skip charge turn of moves that make them semi-invulnerable.
#-------------------------------------------------------------------------------
class Battle::Move::TwoTurnMove < Battle::Move 
  def pbIsChargingTurn?(user)
    @powerHerb = false
    @chargingTurn = false
    @damagingTurn = true
    if !user.effects[PBEffects::TwoTurnAttack]
      if user.isRaidBoss? && [
        "TwoTurnAttackInvulnerableInSky",
        "TwoTurnAttackInvulnerableUnderground",
        "TwoTurnAttackInvulnerableUnderwater",
        "TwoTurnAttackInvulnerableInSkyParalyzeTarget",
        "TwoTurnAttackInvulnerableRemoveProtections",
        "TwoTurnAttackInvulnerableInSkyTargetCannotAct"].include?(@function_code)
        @damagingTurn = true
      else
        @powerHerb = user.hasActiveItem?(:POWERHERB)
        @chargingTurn = true
        @damagingTurn = @powerHerb
      end
    end
    return !@damagingTurn
  end
end

#===============================================================================
# Sky Drop
#===============================================================================
# Fails to work on Dynamax targets or if a Raid Boss is on the field.
#-------------------------------------------------------------------------------
class Battle::Move::TwoTurnAttackInvulnerableInSkyTargetCannotAct < Battle::Move::TwoTurnMove
  alias dx_pbFailsAgainstTarget? pbFailsAgainstTarget?
  def pbFailsAgainstTarget?(user, target, show_message)
    if target.dynamax? || target.isRaidBoss?
      @battle.pbDisplay(_INTL("¡Pero falló!")) if show_message
      return true
    end
    return dx_pbFailsAgainstTarget?(user, target, show_message)
  end
end