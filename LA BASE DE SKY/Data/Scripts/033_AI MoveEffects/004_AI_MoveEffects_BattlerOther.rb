#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("SleepTarget",
  proc { |move, user, target, ai, battle|
    next move.statusMove? && !target.battler.pbCanSleep?(user.battler, false, move.move)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("SleepTarget",
  proc { |score, move, user, target, ai, battle|
    useless_score = (move.statusMove?) ? Battle::AI::MOVE_USELESS_SCORE : score
    next useless_score if target.effects[PBEffects::Yawn] > 0   # Target is going to fall asleep anyway
    # No score modifier if the sleep will be removed immediately
    next useless_score if target.has_active_item?([:CHESTOBERRY, :LUMBERRY])
    next useless_score if target.faster_than?(user) &&
                          target.has_active_ability?(:HYDRATION) &&
                          [:Rain, :HeavyRain].include?(target.battler.effectiveWeather)
    if target.battler.pbCanSleep?(user.battler, false, move.move)
      add_effect = move.get_score_change_for_additional_effect(user, target)
      next useless_score if add_effect == -999   # Additional effect will be negated
      score += add_effect
      # Inherent preference
      score += 15
      # Prefer if the user or an ally has a move/ability that is better if the target is asleep
      ai.each_same_side_battler(user.side) do |b, i|
        score += 5 if b.has_move_with_function?("DoublePowerIfTargetAsleepCureTarget",
                                                "DoublePowerIfTargetStatusProblem",
                                                "HealUserByHalfOfDamageDoneIfTargetAsleep",
                                                "StartDamageTargetEachTurnIfTargetAsleep")
        score += 10 if b.has_active_ability?(:BADDREAMS)
      end
      # Don't prefer if target benefits from having the sleep status problem
      # NOTE: The target's Guts/Quick Feet will benefit from the target being
      #       asleep, but the target won't (usually) be able to make use of
      #       them, so they're not worth considering.
      score -= 10 if target.has_active_ability?(:EARLYBIRD)
      score -= 8 if target.has_active_ability?(:MARVELSCALE)
      # Don't prefer if target has a move it can use while asleep
      score -= 8 if target.check_for_move { |m| m.usableWhenAsleep? }
      # Don't prefer if the target can heal itself (or be healed by an ally)
      if target.has_active_ability?(:SHEDSKIN)
        score -= 8
      elsif target.has_active_ability?(:HYDRATION) &&
            [:Rain, :HeavyRain].include?(target.battler.effectiveWeather)
        score -= 15
      end
      ai.each_same_side_battler(target.side) do |b, i|
        score -= 8 if i != target.index && b.has_active_ability?(:HEALER)
      end
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureCheck.add("SleepTargetIfUserDarkrai",
  proc { |move, user, ai, battle|
    next !user.battler.isSpecies?(:DARKRAI) && user.effects[PBEffects::TransformSpecies] != :DARKRAI
  }
)
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("SleepTargetIfUserDarkrai",
  proc { |move, user, target, ai, battle|
    next move.statusMove? && !target.battler.pbCanSleep?(user.battler, false, move.move)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy("SleepTarget",
                                                        "SleepTargetIfUserDarkrai")

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy("SleepTarget",
                                                        "SleepTargetChangeUserMeloettaForm")

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("SleepTargetNextTurn",
  proc { |move, user, target, ai, battle|
    next true if target.effects[PBEffects::Yawn] > 0
    next true if !target.battler.pbCanSleep?(user.battler, false, move.move)
    next false
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy("SleepTarget",
                                                        "SleepTargetNextTurn")

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("PoisonTarget",
  proc { |move, user, target, ai, battle|
    next move.statusMove? && !target.battler.pbCanPoison?(user.battler, false, move.move)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("PoisonTarget",
  proc { |score, move, user, target, ai, battle|
    useless_score = (move.statusMove?) ? Battle::AI::MOVE_USELESS_SCORE : score
    next useless_score if target.has_active_ability?(:POISONHEAL)
    # No score modifier if the poisoning will be removed immediately
    next useless_score if target.has_active_item?([:PECHABERRY, :LUMBERRY])
    next useless_score if target.faster_than?(user) &&
                          target.has_active_ability?(:HYDRATION) &&
                          [:Rain, :HeavyRain].include?(target.battler.effectiveWeather)
    if target.battler.pbCanPoison?(user.battler, false, move.move)
      add_effect = move.get_score_change_for_additional_effect(user, target)
      next useless_score if add_effect == -999   # Additional effect will be negated
      score += add_effect
      # Inherent preference
      score += 15
      # Prefer if the target is at high HP
      if ai.trainer.has_skill_flag?("HPAware")
        score += 15 * target.hp / target.totalhp
      end
      # Prefer if the user or an ally has a move/ability that is better if the target is poisoned
      ai.each_same_side_battler(user.side) do |b, i|
        score += 5 if b.has_move_with_function?("DoublePowerIfTargetPoisoned",
                                                "DoublePowerIfTargetStatusProblem")
        score += 10 if b.has_active_ability?(:MERCILESS)
      end
      # Don't prefer if target benefits from having the poison status problem
      score -= 8 if target.has_active_ability?([:GUTS, :MARVELSCALE, :QUICKFEET, :TOXICBOOST])
      score -= 25 if target.has_active_ability?(:POISONHEAL)
      score -= 20 if target.has_active_ability?(:SYNCHRONIZE) &&
                     user.battler.pbCanPoisonSynchronize?(target.battler)
      score -= 5 if target.has_move_with_function?("DoublePowerIfUserPoisonedBurnedParalyzed",
                                                   "CureUserBurnPoisonParalysis")
      score -= 15 if target.check_for_move { |m|
        m.function_code == "GiveUserStatusToTarget" && user.battler.pbCanPoison?(target.battler, false, m)
      }
      # Don't prefer if the target won't take damage from the poison
      score -= 20 if !target.battler.takesIndirectDamage?
      # Don't prefer if the target can heal itself (or be healed by an ally)
      if target.has_active_ability?(:SHEDSKIN)
        score -= 8
      elsif target.has_active_ability?(:HYDRATION) &&
            [:Rain, :HeavyRain].include?(target.battler.effectiveWeather)
        score -= 15
      end
      ai.each_same_side_battler(target.side) do |b, i|
        score -= 8 if i != target.index && b.has_active_ability?(:HEALER)
      end
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("PoisonTargetLowerTargetSpeed1",
  proc { |move, user, target, ai, battle|
    next !target.battler.pbCanPoison?(user.battler, false, move.move) &&
         !target.battler.pbCanLowerStatStage?(:SPEED, user.battler, move.move)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("PoisonTargetLowerTargetSpeed1",
  proc { |score, move, user, target, ai, battle|
    poison_score = Battle::AI::Handlers.apply_move_effect_against_target_score("PoisonTarget",
       0, move, user, target, ai, battle)
    score += poison_score if poison_score != Battle::AI::MOVE_USELESS_SCORE
    score = ai.get_score_for_target_stat_drop(score, target, move.move.statDown, false)
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.copy("PoisonTarget",
                                                         "BadPoisonTarget")
Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy("PoisonTarget",
                                                        "BadPoisonTarget")

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("ParalyzeTarget",
  proc { |move, user, target, ai, battle|
    next move.statusMove? && !target.battler.pbCanParalyze?(user.battler, false, move.move)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("ParalyzeTarget",
  proc { |score, move, user, target, ai, battle|
    useless_score = (move.statusMove?) ? Battle::AI::MOVE_USELESS_SCORE : score
    # No score modifier if the paralysis will be removed immediately
    next useless_score if target.has_active_item?([:CHERIBERRY, :LUMBERRY])
    next useless_score if target.faster_than?(user) &&
                          target.has_active_ability?(:HYDRATION) &&
                          [:Rain, :HeavyRain].include?(target.battler.effectiveWeather)
    if target.battler.pbCanParalyze?(user.battler, false, move.move)
      add_effect = move.get_score_change_for_additional_effect(user, target)
      next useless_score if add_effect == -999   # Additional effect will be negated
      score += add_effect
      # Inherent preference (because of the chance of full paralysis)
      score += 10
      # Prefer if the target is faster than the user but will become slower if
      # paralysed
      if target.faster_than?(user)
        user_speed = user.rough_stat(:SPEED)
        target_speed = target.rough_stat(:SPEED)
        score += 15 if target_speed < user_speed * ((Settings::MECHANICS_GENERATION >= 7) ? 2 : 4)
      end
      # Prefer if the target is confused or infatuated, to compound the turn skipping
      score += 7 if target.effects[PBEffects::Confusion] > 1
      score += 7 if target.effects[PBEffects::Attract] >= 0
      # Prefer if the user or an ally has a move/ability that is better if the target is paralysed
      ai.each_same_side_battler(user.side) do |b, i|
        score += 5 if b.has_move_with_function?("DoublePowerIfTargetParalyzedCureTarget",
                                                "DoublePowerIfTargetStatusProblem")
      end
      # Don't prefer if target benefits from having the paralysis status problem
      score -= 8 if target.has_active_ability?([:GUTS, :MARVELSCALE, :QUICKFEET])
      score -= 20 if target.has_active_ability?(:SYNCHRONIZE) &&
                     user.battler.pbCanParalyzeSynchronize?(target.battler)
      score -= 5 if target.has_move_with_function?("DoublePowerIfUserPoisonedBurnedParalyzed",
                                                   "CureUserBurnPoisonParalysis")
      score -= 15 if target.check_for_move { |m|
        m.function_code == "GiveUserStatusToTarget" && user.battler.pbCanParalyze?(target.battler, false, m)
      }
      # Don't prefer if the target can heal itself (or be healed by an ally)
      if target.has_active_ability?(:SHEDSKIN)
        score -= 8
      elsif target.has_active_ability?(:HYDRATION) &&
            [:Rain, :HeavyRain].include?(target.battler.effectiveWeather)
        score -= 15
      end
      ai.each_same_side_battler(target.side) do |b, i|
        score -= 8 if i != target.index && b.has_active_ability?(:HEALER)
      end
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("ParalyzeTargetIfNotTypeImmune",
  proc { |move, user, target, ai, battle|
    eff = target.effectiveness_of_type_against_battler(move.rough_type, user, move)
    next true if Effectiveness.ineffective?(eff)
    next true if move.statusMove? && !target.battler.pbCanParalyze?(user.battler, false, move.move)
    next false
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy("ParalyzeTarget",
                                                        "ParalyzeTargetIfNotTypeImmune")

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy("ParalyzeTarget",
                                                        "ParalyzeTargetAlwaysHitsInRainHitsTargetInSky")

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("ParalyzeFlinchTarget",
  proc { |score, move, user, target, ai, battle|
    paralyze_score = Battle::AI::Handlers.apply_move_effect_against_target_score("ParalyzeTarget",
       0, move, user, target, ai, battle)
    flinch_score = Battle::AI::Handlers.apply_move_effect_against_target_score("FlinchTarget",
       0, move, user, target, ai, battle)
    if paralyze_score == Battle::AI::MOVE_USELESS_SCORE &&
       flinch_score == Battle::AI::MOVE_USELESS_SCORE
      next Battle::AI::MOVE_USELESS_SCORE
    end
    score += paralyze_score if paralyze_score != Battle::AI::MOVE_USELESS_SCORE
    score += flinch_score if flinch_score != Battle::AI::MOVE_USELESS_SCORE
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("BurnTarget",
  proc { |move, user, target, ai, battle|
    next move.statusMove? && !target.battler.pbCanBurn?(user.battler, false, move.move)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("BurnTarget",
  proc { |score, move, user, target, ai, battle|
    useless_score = (move.statusMove?) ? Battle::AI::MOVE_USELESS_SCORE : score
    # No score modifier if the burn will be removed immediately
    next useless_score if target.has_active_item?([:RAWSTBERRY, :LUMBERRY])
    next useless_score if target.faster_than?(user) &&
                          target.has_active_ability?(:HYDRATION) &&
                          [:Rain, :HeavyRain].include?(target.battler.effectiveWeather)
    if target.battler.pbCanBurn?(user.battler, false, move.move)
      add_effect = move.get_score_change_for_additional_effect(user, target)
      next useless_score if add_effect == -999   # Additional effect will be negated
      score += add_effect
      # Inherent preference
      score += 15
      # Prefer if the target knows any physical moves that will be weaked by a burn
      if !target.has_active_ability?(:GUTS) && target.check_for_move { |m| m.physicalMove? }
        score += 8
        score += 8 if !target.check_for_move { |m| m.specialMove? }
      end
      # Prefer if the user or an ally has a move/ability that is better if the target is burned
      ai.each_same_side_battler(user.side) do |b, i|
        score += 5 if b.has_move_with_function?("DoublePowerIfTargetStatusProblem")
      end
      # Don't prefer if target benefits from having the burn status problem
      score -= 8 if target.has_active_ability?([:FLAREBOOST, :GUTS, :MARVELSCALE, :QUICKFEET])
      score -= 5 if target.has_active_ability?(:HEATPROOF)
      score -= 20 if target.has_active_ability?(:SYNCHRONIZE) &&
                     user.battler.pbCanBurnSynchronize?(target.battler)
      score -= 5 if target.has_move_with_function?("DoublePowerIfUserPoisonedBurnedParalyzed",
                                                   "CureUserBurnPoisonParalysis")
      score -= 15 if target.check_for_move { |m|
        m.function_code == "GiveUserStatusToTarget" && user.battler.pbCanBurn?(target.battler, false, m)
      }
      # Don't prefer if the target won't take damage from the burn
      score -= 20 if !target.battler.takesIndirectDamage?
      # Don't prefer if the target can heal itself (or be healed by an ally)
      if target.has_active_ability?(:SHEDSKIN)
        score -= 8
      elsif target.has_active_ability?(:HYDRATION) &&
            [:Rain, :HeavyRain].include?(target.battler.effectiveWeather)
        score -= 15
      end
      ai.each_same_side_battler(target.side) do |b, i|
        score -= 8 if i != target.index && b.has_active_ability?(:HEALER)
      end
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
# BurnTargetIfTargetStatsRaisedThisTurn

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("BurnFlinchTarget",
  proc { |score, move, user, target, ai, battle|
    burn_score = Battle::AI::Handlers.apply_move_effect_against_target_score("BurnTarget",
       0, move, user, target, ai, battle)
    flinch_score = Battle::AI::Handlers.apply_move_effect_against_target_score("FlinchTarget",
       0, move, user, target, ai, battle)
    if burn_score == Battle::AI::MOVE_USELESS_SCORE &&
       flinch_score == Battle::AI::MOVE_USELESS_SCORE
      next Battle::AI::MOVE_USELESS_SCORE
    end
    score += burn_score if burn_score != Battle::AI::MOVE_USELESS_SCORE
    score += flinch_score if flinch_score != Battle::AI::MOVE_USELESS_SCORE
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("FreezeTarget",
  proc { |move, user, target, ai, battle|
    next move.statusMove? && !target.battler.pbCanFreeze?(user.battler, false, move.move)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("FreezeTarget",
  proc { |score, move, user, target, ai, battle|
    useless_score = (move.statusMove?) ? Battle::AI::MOVE_USELESS_SCORE : score
    # No score modifier if the freeze will be removed immediately
    next useless_score if target.has_active_item?([:ASPEARBERRY, :LUMBERRY])
    next useless_score if target.faster_than?(user) &&
                          target.has_active_ability?(:HYDRATION) &&
                          [:Rain, :HeavyRain].include?(target.battler.effectiveWeather)
    if target.battler.pbCanFreeze?(user.battler, false, move.move)
      add_effect = move.get_score_change_for_additional_effect(user, target)
      next useless_score if add_effect == -999   # Additional effect will be negated
      score += add_effect
      # Inherent preference
      score += 15
      # Prefer if the user or an ally has a move/ability that is better if the target is frozen
      ai.each_same_side_battler(user.side) do |b, i|
        score += 5 if b.has_move_with_function?("DoublePowerIfTargetStatusProblem")
      end
      # Don't prefer if target benefits from having the frozen status problem
      # NOTE: The target's Guts/Quick Feet will benefit from the target being
      #       frozen, but the target won't be able to make use of them, so
      #       they're not worth considering.
      score -= 8 if target.has_active_ability?(:MARVELSCALE)
      # Don't prefer if the target knows a move that can thaw it
      score -= 15 if target.check_for_move { |m| m.thawsUser? }
      # Don't prefer if the target can heal itself (or be healed by an ally)
      if target.has_active_ability?(:SHEDSKIN)
        score -= 8
      elsif target.has_active_ability?(:HYDRATION) &&
            [:Rain, :HeavyRain].include?(target.battler.effectiveWeather)
        score -= 15
      end
      ai.each_same_side_battler(target.side) do |b, i|
        score -= 8 if i != target.index && b.has_active_ability?(:HEALER)
      end
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy("FreezeTarget",
                                                        "FreezeTargetSuperEffectiveAgainstWater")

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy("FreezeTarget",
                                                        "FreezeTargetAlwaysHitsInHail")

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("FreezeFlinchTarget",
  proc { |score, move, user, target, ai, battle|
    freeze_score = Battle::AI::Handlers.apply_move_effect_against_target_score("FreezeTarget",
       0, move, user, target, ai, battle)
    flinch_score = Battle::AI::Handlers.apply_move_effect_against_target_score("FlinchTarget",
       0, move, user, target, ai, battle)
    if freeze_score == Battle::AI::MOVE_USELESS_SCORE &&
       flinch_score == Battle::AI::MOVE_USELESS_SCORE
      next Battle::AI::MOVE_USELESS_SCORE
    end
    score += freeze_score if freeze_score != Battle::AI::MOVE_USELESS_SCORE
    score += flinch_score if flinch_score != Battle::AI::MOVE_USELESS_SCORE
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("ParalyzeBurnOrFreezeTarget",
  proc { |score, move, user, target, ai, battle|
    # No score modifier if the status problem will be removed immediately
    next score if target.has_active_item?(:LUMBERRY)
    next score if target.faster_than?(user) &&
                  target.has_active_ability?(:HYDRATION) &&
                  [:Rain, :HeavyRain].include?(target.battler.effectiveWeather)
    # Scores for the possible effects
    ["ParalyzeTarget", "BurnTarget", "FreezeTarget"].each do |function_code|
      effect_score = Battle::AI::Handlers.apply_move_effect_against_target_score(function_code,
         0, move, user, target, ai, battle)
      score += effect_score / 3 if effect_score != Battle::AI::MOVE_USELESS_SCORE
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureCheck.add("GiveUserStatusToTarget",
  proc { |move, user, ai, battle|
    next user.status == :NONE
  }
)
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("GiveUserStatusToTarget",
  proc { |move, user, target, ai, battle|
    next !target.battler.pbCanInflictStatus?(user.status, user.battler, false, move.move)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("GiveUserStatusToTarget",
  proc { |score, move, user, target, ai, battle|
    # Curing the user's status problem
    score += 15 if !user.wants_status_problem?(user.status)
    # Giving the target a status problem
    function_code = {
      :SLEEP     => "SleepTarget",
      :PARALYSIS => "ParalyzeTarget",
      :POISON    => "PoisonTarget",
      :BURN      => "BurnTarget",
      :FROZEN    => "FreezeTarget"
    }[user.status]
    if function_code
      new_score = Battle::AI::Handlers.apply_move_effect_against_target_score(function_code,
         score, move, user, target, ai, battle)
      next new_score if new_score != Battle::AI::MOVE_USELESS_SCORE
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureCheck.add("CureUserBurnPoisonParalysis",
  proc { |move, user, ai, battle|
    next ![:BURN, :POISON, :PARALYSIS].include?(user.status)
  }
)
Battle::AI::Handlers::MoveEffectScore.add("CureUserBurnPoisonParalysis",
  proc { |score, move, user, ai, battle|
    next Battle::AI::MOVE_USELESS_SCORE if user.wants_status_problem?(user.status)
    next score + 20
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureCheck.add("CureUserPartyStatus",
  proc { |move, user, ai, battle|
    next battle.pbParty(user.index).none? { |pkmn| pkmn&.able? && pkmn.status != :NONE }
  }
)
Battle::AI::Handlers::MoveEffectScore.add("CureUserPartyStatus",
  proc { |score, move, user, ai, battle|
    score = Battle::AI::MOVE_BASE_SCORE   # Ignore the scores for each targeted battler calculated earlier
    battle.pbParty(user.index).each do |pkmn|
      next if !pkmn || pkmn.status == :NONE
      next if pkmn.status == :SLEEP && pkmn.statusCount == 1   # About to wake up
      score += 12
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("CureTargetBurn",
  proc { |score, move, user, target, ai, battle|
    add_effect = move.get_score_change_for_additional_effect(user, target)
    next score if add_effect == -999   # Additional effect will be negated
    if target.status == :BURN
      score -= add_effect
      if target.wants_status_problem?(:BURN)
        score += 15
      else
        score -= 10
      end
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureCheck.add("StartUserSideImmunityToInflictedStatus",
  proc { |move, user, ai, battle|
    next user.pbOwnSide.effects[PBEffects::Safeguard] > 0
  }
)
Battle::AI::Handlers::MoveEffectScore.add("StartUserSideImmunityToInflictedStatus",
  proc { |score, move, user, ai, battle|
    # Not worth it if Misty Terrain is already safeguarding all user side battlers
    if battle.field.terrain == :Misty &&
       (battle.field.terrainDuration > 1 || battle.field.terrainDuration < 0)
      already_immune = true
      ai.each_same_side_battler(user.side) do |b, i|
        already_immune = false if !b.battler.affectedByTerrain?
      end
      next Battle::AI::MOVE_USELESS_SCORE if already_immune
    end
    # Tends to be wasteful if the foe just has one Pokémon left
    next score - 20 if battle.pbAbleNonActiveCount(user.idxOpposingSide) == 0
    # Prefer for each user side battler
    ai.each_same_side_battler(user.side) { |b, i| score += 15 }
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("FlinchTarget",
  proc { |score, move, user, target, ai, battle|
    next score if target.faster_than?(user) || target.effects[PBEffects::Substitute] > 0
    next score if target.has_active_ability?(:INNERFOCUS) && !battle.moldBreaker
    add_effect = move.get_score_change_for_additional_effect(user, target)
    next score if add_effect == -999   # Additional effect will be negated
    score += add_effect
    # Inherent preference
    score += 15
    # Prefer if the target is paralysed, confused or infatuated, to compound the
    # turn skipping
    score += 8 if target.status == :PARALYSIS ||
                  target.effects[PBEffects::Confusion] > 1 ||
                  target.effects[PBEffects::Attract] >= 0
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy("FlinchTarget",
                                                        "FlinchTargetFailsIfUserNotAsleep")

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureCheck.add("FlinchTargetFailsIfNotUserFirstTurn",
  proc { |move, user, ai, battle|
    next user.turnCount > 0
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy("FlinchTarget",
                                                        "FlinchTargetFailsIfNotUserFirstTurn")

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveBasePower.add("FlinchTargetDoublePowerIfTargetInSky",
  proc { |power, move, user, target, ai, battle|
    next move.move.pbBaseDamage(power, user.battler, target.battler)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy("FlinchTarget",
                                                        "FlinchTargetDoublePowerIfTargetInSky")

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("ConfuseTarget",
  proc { |move, user, target, ai, battle|
    next move.statusMove? && !target.battler.pbCanConfuse?(user.battler, false, move.move)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("ConfuseTarget",
  proc { |score, move, user, target, ai, battle|
    # No score modifier if the status problem will be removed immediately
    next score if target.has_active_item?(:PERSIMBERRY)
    if target.battler.pbCanConfuse?(user.battler, false, move.move)
      add_effect = move.get_score_change_for_additional_effect(user, target)
      next score if add_effect == -999   # Additional effect will be negated
      score += add_effect
      # Inherent preference
      score += 10
      # Prefer if the target is at high HP
      if ai.trainer.has_skill_flag?("HPAware")
        score += 20 * target.hp / target.totalhp
      end
      # Prefer if the target is paralysed or infatuated, to compound the turn skipping
      score += 8 if target.status == :PARALYSIS || target.effects[PBEffects::Attract] >= 0
      # Don't prefer if target benefits from being confused
      score -= 15 if target.has_active_ability?(:TANGLEDFEET)
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy("ConfuseTarget",
                                                        "ConfuseTargetAlwaysHitsInRainHitsTargetInSky")

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("AttractTarget",
  proc { |move, user, target, ai, battle|
    next move.statusMove? && !target.battler.pbCanAttract?(user.battler, false)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("AttractTarget",
  proc { |score, move, user, target, ai, battle|
    if target.battler.pbCanAttract?(user.battler, false)
      add_effect = move.get_score_change_for_additional_effect(user, target)
      next score if add_effect == -999   # Additional effect will be negated
      score += add_effect
      # Inherent preference
      score += 15
      # Prefer if the target is paralysed or confused, to compound the turn skipping
      score += 8 if target.status == :PARALYSIS || target.effects[PBEffects::Confusion] > 1
      # Don't prefer if the target can infatuate the user because of this move
      score -= 15 if target.has_active_item?(:DESTINYKNOT) &&
                     user.battler.pbCanAttract?(target.battler, false)
      # Don't prefer if the user has another way to infatuate the target
      score -= 15 if move.statusMove? && user.has_active_ability?(:CUTECHARM)
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureCheck.add("SetUserTypesBasedOnEnvironment",
  proc { |move, user, ai, battle|
    next true if !user.battler.canChangeType?
    new_type = nil
    terr_types = Battle::Move::SetUserTypesBasedOnEnvironment::TERRAIN_TYPES
    terr_type = terr_types[battle.field.terrain]
    if terr_type && GameData::Type.exists?(terr_type)
      new_type = terr_type
    else
      env_types = Battle::Move::SetUserTypesBasedOnEnvironment::ENVIRONMENT_TYPES
      new_type = env_types[battle.environment] || :NORMAL
      new_type = :NORMAL if !GameData::Type.exists?(new_type)
    end
    next !GameData::Type.exists?(new_type) || !user.battler.pbHasOtherType?(new_type)
  }
)
Battle::AI::Handlers::MoveEffectScore.add("SetUserTypesBasedOnEnvironment",
  proc { |score, move, user, ai, battle|
    # Determine the new type
    new_type = nil
    terr_types = Battle::Move::SetUserTypesBasedOnEnvironment::TERRAIN_TYPES
    terr_type = terr_types[battle.field.terrain]
    if terr_type && GameData::Type.exists?(terr_type)
      new_type = terr_type
    else
      env_types = Battle::Move::SetUserTypesBasedOnEnvironment::ENVIRONMENT_TYPES
      new_type = env_types[battle.environment] || :NORMAL
      new_type = :NORMAL if !GameData::Type.exists?(new_type)
    end
    # Check if any user's moves will get STAB because of the type change
    score += 14 if user.has_damaging_move_of_type?(new_type)
    # Check if any user's moves will lose STAB because of the type change
    user.pbTypes(true).each do |type|
      next if type == new_type
      score -= 14 if user.has_damaging_move_of_type?(type)
    end
    # NOTE: Other things could be considered, like the foes' moves'
    #       effectivenesses against the current and new user's type(s), and
    #       which set of STAB is more beneficial. However, I'm keeping this
    #       simple because, if you know this move, you probably want to use it
    #       just because.
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("SetUserTypesToResistLastAttack",
  proc { |move, user, target, ai, battle|
    next true if !user.battler.canChangeType?
    next true if !target.battler.lastMoveUsed || !target.battler.lastMoveUsedType ||
                 GameData::Type.get(target.battler.lastMoveUsedType).pseudo_type
    has_possible_type = false
    GameData::Type.each do |t|
      next if t.pseudo_type || user.has_type?(t.id) ||
              !Effectiveness.resistant_type?(target.battler.lastMoveUsedType, t.id)
      has_possible_type = true
      break
    end
    next !has_possible_type
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("SetUserTypesToResistLastAttack",
  proc { |score, move, user, target, ai, battle|
    effectiveness = user.effectiveness_of_type_against_battler(target.battler.lastMoveUsedType, target)
    if Effectiveness.ineffective?(effectiveness)
      next Battle::AI::MOVE_USELESS_SCORE
    elsif Effectiveness.super_effective?(effectiveness)
      score += 15
    elsif Effectiveness.normal?(effectiveness)
      score += 10
    else   # Not very effective
      score += 5
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("SetUserTypesToTargetTypes",
  proc { |move, user, target, ai, battle|
    next true if !user.battler.canChangeType?
    next true if target.pbTypes(true).empty?
    next true if user.pbTypes == target.pbTypes &&
                 user.effects[PBEffects::ExtraType] == target.effects[PBEffects::ExtraType]
    next false
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureCheck.add("SetUserTypesToUserMoveType",
  proc { |move, user, ai, battle|
    next true if !user.battler.canChangeType?
    has_possible_type = false
    user.battler.eachMoveWithIndex do |m, i|
      break if Settings::MECHANICS_GENERATION >= 6 && i > 0
      next if GameData::Type.get(m.type).pseudo_type
      next if user.has_type?(m.type)
      has_possible_type = true
      break
    end
    next !has_possible_type
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("SetUserTypesToUserMoveType",
  proc { |score, move, user, target, ai, battle|
    possible_types = []
    user.battler.eachMoveWithIndex do |m, i|
      break if Settings::MECHANICS_GENERATION >= 6 && i > 0
      next if GameData::Type.get(m.type).pseudo_type
      next if user.has_type?(m.type)
      possible_types.push(m.type)
    end
    # Check if any user's moves will get STAB because of the type change
    possible_types.each do |type|
      next if !user.has_damaging_move_of_type?(type)
      score += 14
      break
    end
    # NOTE: Other things could be considered, like the foes' moves'
    #       effectivenesses against the current and new user's type(s), and
    #       whether any of the user's moves will lose STAB because of the type
    #       change (and if so, which set of STAB is more beneficial). However,
    #       I'm keeping this simple because, if you know this move, you probably
    #       want to use it just because.
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("SetTargetTypesToPsychic",
  proc { |move, user, target, ai, battle|
    next move.move.pbFailsAgainstTarget?(user.battler, target.battler, false)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("SetTargetTypesToPsychic",
  proc { |score, move, user, target, ai, battle|
    # Prefer if target's foes know damaging moves that are super-effective
    # against Psychic, and don't prefer if they know damaging moves that are
    # ineffective against Psychic
    ai.each_foe_battler(target.side) do |b, i|
      b.battler.eachMove do |m|
        next if !m.damagingMove?
        effectiveness = Effectiveness.calculate(m.pbCalcType(b.battler), :PSYCHIC)
        if Effectiveness.super_effective?(effectiveness)
          score += 10
        elsif Effectiveness.ineffective?(effectiveness)
          score -= 10
        end
      end
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.copy("SetTargetTypesToPsychic",
                                                         "SetTargetTypesToWater")
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("SetTargetTypesToWater",
  proc { |score, move, user, target, ai, battle|
    # Prefer if target's foes know damaging moves that are super-effective
    # against Water, and don't prefer if they know damaging moves that are
    # ineffective against Water
    ai.each_foe_battler(target.side) do |b, i|
      b.battler.eachMove do |m|
        next if !m.damagingMove?
        effectiveness = Effectiveness.calculate(m.pbCalcType(b.battler), :WATER)
        if Effectiveness.super_effective?(effectiveness)
          score += 10
        elsif Effectiveness.ineffective?(effectiveness)
          score -= 10
        end
      end
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.copy("SetTargetTypesToWater",
                                                         "AddGhostTypeToTarget")
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("AddGhostTypeToTarget",
  proc { |score, move, user, target, ai, battle|
    # Prefer/don't prefer depending on the effectiveness of the target's foes'
    # damaging moves against the added type
    ai.each_foe_battler(target.side) do |b, i|
      b.battler.eachMove do |m|
        next if !m.damagingMove?
        effectiveness = Effectiveness.calculate(m.pbCalcType(b.battler), :GHOST)
        if Effectiveness.super_effective?(effectiveness)
          score += 10
        elsif Effectiveness.not_very_effective?(effectiveness)
          score -= 5
        elsif Effectiveness.ineffective?(effectiveness)
          score -= 10
        end
      end
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.copy("AddGhostTypeToTarget",
                                                         "AddGrassTypeToTarget")
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("AddGrassTypeToTarget",
  proc { |score, move, user, target, ai, battle|
    # Prefer/don't prefer depending on the effectiveness of the target's foes'
    # damaging moves against the added type
    ai.each_foe_battler(target.side) do |b, i|
      b.battler.eachMove do |m|
        next if !m.damagingMove?
        effectiveness = Effectiveness.calculate(m.pbCalcType(b.battler), :GRASS)
        if Effectiveness.super_effective?(effectiveness)
          score += 10
        elsif Effectiveness.not_very_effective?(effectiveness)
          score -= 5
        elsif Effectiveness.ineffective?(effectiveness)
          score -= 10
        end
      end
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureCheck.add("UserLosesFireType",
  proc { |move, user, ai, battle|
    next !user.has_type?(:FIRE)
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("SetTargetAbilityToSimple",
  proc { |move, user, target, ai, battle|
    next true if !GameData::Ability.exists?(:SIMPLE)
    next move.move.pbFailsAgainstTarget?(user.battler, target.battler, false)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("SetTargetAbilityToSimple",
  proc { |score, move, user, target, ai, battle|
    next Battle::AI::MOVE_USELESS_SCORE if !target.ability_active?
    old_ability_rating = target.wants_ability?(target.ability_id)
    new_ability_rating = target.wants_ability?(:SIMPLE)
    side_mult = (target.opposes?(user)) ? 1 : -1
    if old_ability_rating > new_ability_rating
      score += 5 * side_mult * [old_ability_rating - new_ability_rating, 3].max
    elsif old_ability_rating < new_ability_rating
      score -= 5 * side_mult * [new_ability_rating - old_ability_rating, 3].max
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("SetTargetAbilityToInsomnia",
  proc { |move, user, target, ai, battle|
    next true if !GameData::Ability.exists?(:INSOMNIA)
    next move.move.pbFailsAgainstTarget?(user.battler, target.battler, false)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("SetTargetAbilityToInsomnia",
  proc { |score, move, user, target, ai, battle|
    next Battle::AI::MOVE_USELESS_SCORE if !target.ability_active?
    old_ability_rating = target.wants_ability?(target.ability_id)
    new_ability_rating = target.wants_ability?(:INSOMNIA)
    side_mult = (target.opposes?(user)) ? 1 : -1
    if old_ability_rating > new_ability_rating
      score += 5 * side_mult * [old_ability_rating - new_ability_rating, 3].max
    elsif old_ability_rating < new_ability_rating
      score -= 5 * side_mult * [new_ability_rating - old_ability_rating, 3].max
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("SetUserAbilityToTargetAbility",
  proc { |move, user, target, ai, battle|
    next true if user.battler.unstoppableAbility?
    next move.move.pbFailsAgainstTarget?(user.battler, target.battler, false)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("SetUserAbilityToTargetAbility",
  proc { |score, move, user, target, ai, battle|
    next Battle::AI::MOVE_USELESS_SCORE if !user.ability_active?
    old_ability_rating = user.wants_ability?(user.ability_id)
    new_ability_rating = user.wants_ability?(target.ability_id)
    if old_ability_rating > new_ability_rating
      score += 5 * [old_ability_rating - new_ability_rating, 3].max
    elsif old_ability_rating < new_ability_rating
      score -= 5 * [new_ability_rating - old_ability_rating, 3].max
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("SetTargetAbilityToUserAbility",
  proc { |move, user, target, ai, battle|
    next true if !user.ability || user.ability_id == target.ability_id
    next true if user.battler.ungainableAbility? ||
                 [:POWEROFALCHEMY, :RECEIVER, :TRACE].include?(user.ability_id)
    next move.move.pbFailsAgainstTarget?(user.battler, target.battler, false)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("SetTargetAbilityToUserAbility",
  proc { |score, move, user, target, ai, battle|
    next Battle::AI::MOVE_USELESS_SCORE if !target.ability_active?
    old_ability_rating = target.wants_ability?(target.ability_id)
    new_ability_rating = target.wants_ability?(user.ability_id)
    side_mult = (target.opposes?(user)) ? 1 : -1
    if old_ability_rating > new_ability_rating
      score += 5 * side_mult * [old_ability_rating - new_ability_rating, 3].max
    elsif old_ability_rating < new_ability_rating
      score -= 5 * side_mult * [new_ability_rating - old_ability_rating, 3].max
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("UserTargetSwapAbilities",
  proc { |move, user, target, ai, battle|
    next true if !user.ability || user.battler.unstoppableAbility? ||
                 user.battler.ungainableAbility? || user.ability_id == :WONDERGUARD
    next move.move.pbFailsAgainstTarget?(user.battler, target.battler, false)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("UserTargetSwapAbilities",
  proc { |score, move, user, target, ai, battle|
    next Battle::AI::MOVE_USELESS_SCORE if !user.ability_active? && !target.ability_active?
    old_user_ability_rating = user.wants_ability?(user.ability_id)
    new_user_ability_rating = user.wants_ability?(target.ability_id)
    user_diff = new_user_ability_rating - old_user_ability_rating
    user_diff = 0 if !user.ability_active?
    old_target_ability_rating = target.wants_ability?(target.ability_id)
    new_target_ability_rating = target.wants_ability?(user.ability_id)
    target_diff = new_target_ability_rating - old_target_ability_rating
    target_diff = 0 if !target.ability_active?
    side_mult = (target.opposes?(user)) ? 1 : -1
    if user_diff > target_diff
      score += 5 * side_mult * [user_diff - target_diff, 3].max
    elsif target_diff < user_diff
      score -= 5 * side_mult * [target_diff - user_diff, 3].max
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("NegateTargetAbility",
  proc { |move, user, target, ai, battle|
    next move.move.pbFailsAgainstTarget?(user.battler, target.battler, false)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("NegateTargetAbility",
  proc { |score, move, user, target, ai, battle|
    next Battle::AI::MOVE_USELESS_SCORE if !target.ability_active?
    target_ability_rating = target.wants_ability?(target.ability_id)
    side_mult = (target.opposes?(user)) ? 1 : -1
    if target_ability_rating > 0
      score += 5 * side_mult * [target_ability_rating, 3].max
    elsif target_ability_rating < 0
      score -= 5 * side_mult * [target_ability_rating.abs, 3].max
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("NegateTargetAbilityIfTargetActed",
  proc { |score, move, user, target, ai, battle|
    next score if target.effects[PBEffects::Substitute] > 0
    next score if target.battler.unstoppableAbility? || !target.ability_active?
    next score if user.faster_than?(target)
    target_ability_rating = target.wants_ability?(target.ability_id)
    side_mult = (target.opposes?(user)) ? 1 : -1
    if target_ability_rating > 0
      score += 5 * side_mult * [target_ability_rating, 3].max
    elsif target_ability_rating < 0
      score -= 5 * side_mult * [target_ability_rating.abs, 3].max
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
# IgnoreTargetAbility

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureCheck.add("StartUserAirborne",
  proc { |move, user, ai, battle|
    next true if user.has_active_item?(:IRONBALL)
    next true if user.effects[PBEffects::Ingrain] ||
                 user.effects[PBEffects::SmackDown] ||
                 user.effects[PBEffects::MagnetRise] > 0
    next false
  }
)
Battle::AI::Handlers::MoveEffectScore.add("StartUserAirborne",
  proc { |score, move, user, ai, battle|
    # Move is useless if user is already airborne
    if user.has_type?(:FLYING) ||
       user.has_active_ability?(:LEVITATE) ||
       user.has_active_item?(:AIRBALLOON) ||
       user.effects[PBEffects::Telekinesis] > 0
      next Battle::AI::MOVE_USELESS_SCORE
    end
    # Prefer if any foes have damaging Ground-type moves that do 1x or more
    # damage to the user
    ai.each_foe_battler(user.side) do |b, i|
      next if !b.has_damaging_move_of_type?(:GROUND)
      next if Effectiveness.resistant?(user.effectiveness_of_type_against_battler(:GROUND, b))
      score += 10
    end
    # Don't prefer if terrain exists (which the user will no longer be affected by)
    if ai.trainer.medium_skill?
      score -= 8 if battle.field.terrain != :None
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("StartTargetAirborneAndAlwaysHitByMoves",
  proc { |move, user, target, ai, battle|
    next true if target.has_active_item?(:IRONBALL)
    next move.move.pbFailsAgainstTarget?(user.battler, target.battler, false)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("StartTargetAirborneAndAlwaysHitByMoves",
  proc { |score, move, user, target, ai, battle|
    # Move is useless if the target is already airborne
    if target.has_type?(:FLYING) ||
       target.has_active_ability?(:LEVITATE) ||
       target.has_active_item?(:AIRBALLOON)
      next Battle::AI::MOVE_USELESS_SCORE
    end
    # Prefer if any allies have moves with accuracy < 90%
    # Don't prefer if any allies have damaging Ground-type moves that do 1x or
    # more damage to the target
    ai.each_foe_battler(target.side) do |b, i|
      b.battler.eachMove do |m|
        acc = m.accuracy
        acc = m.pbBaseAccuracy(b.battler, target.battler) if ai.trainer.medium_skill?
        score += 5 if acc < 90 && acc != 0
        score += 5 if acc <= 50 && acc != 0
      end
      next if !b.has_damaging_move_of_type?(:GROUND)
      next if Effectiveness.resistant?(target.effectiveness_of_type_against_battler(:GROUND, b))
      score -= 7
    end
    # Prefer if terrain exists (which the target will no longer be affected by)
    if ai.trainer.medium_skill?
      score += 8 if battle.field.terrain != :None
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
# HitsTargetInSky

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("HitsTargetInSkyGroundsTarget",
  proc { |score, move, user, target, ai, battle|
    next score if target.effects[PBEffects::Substitute] > 0
    if !target.battler.airborne?
      next score if target.faster_than?(user) ||
                    !target.battler.inTwoTurnAttack?("TwoTurnAttackInvulnerableInSky",
                                                     "TwoTurnAttackInvulnerableInSkyParalyzeTarget")
    end
    # Prefer if the target is airborne
    score += 10
    # Prefer if any allies have damaging Ground-type moves
    ai.each_foe_battler(target.side) do |b, i|
      score += 8 if b.has_damaging_move_of_type?(:GROUND)
    end
    # Don't prefer if terrain exists (which the target will become affected by)
    if ai.trainer.medium_skill?
      score -= 8 if battle.field.terrain != :None
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureCheck.add("StartGravity",
  proc { |move, user, ai, battle|
    next battle.field.effects[PBEffects::Gravity] > 0
  }
)
Battle::AI::Handlers::MoveEffectScore.add("StartGravity",
  proc { |score, move, user, ai, battle|
    ai.each_battler do |b, i|
      # Prefer grounding airborne foes, don't prefer grounding airborne allies
      # Prefer making allies affected by terrain, don't prefer making foes
      # affected by terrain
      if b.battler.airborne?
        score_change = 10
        if ai.trainer.medium_skill?
          score_change -= 8 if battle.field.terrain != :None
        end
        score += (user.opposes?(b)) ? score_change : -score_change
        # Prefer if allies have any damaging Ground moves they'll be able to use
        # on a grounded foe, and vice versa
        ai.each_foe_battler(b.side) do |b2, j|
          next if !b2.has_damaging_move_of_type?(:GROUND)
          score += (user.opposes?(b2)) ? -8 : 8
        end
      end
      # Prefer ending Sky Drop being used on allies, don't prefer ending Sky
      # Drop being used on foes
      if b.effects[PBEffects::SkyDrop] >= 0
        score += (user.opposes?(b)) ? -8 : 8
      end
      # Gravity raises accuracy of all moves; prefer if the user/ally has low
      # accuracy moves, don't prefer if foes have any
      if b.check_for_move { |m| m.accuracy < 85 }
        score += (user.opposes?(b)) ? -8 : 8
      end
      # Prefer stopping foes' sky-based attacks, don't prefer stopping allies'
      # sky-based attacks
      if user.faster_than?(b) &&
         b.battler.inTwoTurnAttack?("TwoTurnAttackInvulnerableInSky",
                                    "TwoTurnAttackInvulnerableInSkyParalyzeTarget",
                                    "TwoTurnAttackInvulnerableInSkyTargetCannotAct")
        score += (user.opposes?(b)) ? 10 : -10
      end
    end
    next score
  }
)

#===============================================================================
#
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("TransformUserIntoTarget",
  proc { |move, user, target, ai, battle|
    next true if user.effects[PBEffects::Transform]
    next true if target.effects[PBEffects::Transform] ||
                 target.effects[PBEffects::Illusion]
    next false
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("TransformUserIntoTarget",
  proc { |score, move, user, target, ai, battle|
    next score - 5
  }
)

#===============================================================================
# SleepTarget
#===============================================================================
# Add score modifier for Infernal Parade
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("SleepTarget",
  proc { |score, move, user, target, ai, battle|
    useless_score = (move.statusMove?) ? Battle::AI::MOVE_USELESS_SCORE : score
    next useless_score if target.effects[PBEffects::Yawn] > 0   # Target is going to fall asleep anyway
    # No score modifier if the sleep will be removed immediately
    next useless_score if target.has_active_item?([:CHESTOBERRY, :LUMBERRY])
    next useless_score if target.faster_than?(user) &&
                          target.has_active_ability?(:HYDRATION) &&
                          [:Rain, :HeavyRain].include?(target.battler.effectiveWeather)
    if target.battler.pbCanSleep?(user.battler, false, move.move)
      add_effect = move.get_score_change_for_additional_effect(user, target)
      next useless_score if add_effect == -999   # Additional effect will be negated
      score += add_effect
      # Inherent preference
      score += 15
      # Prefer if the user or an ally has a move/ability that is better if the target is asleep
      ai.each_same_side_battler(user.side) do |b, i|
        score += 5 if b.has_move_with_function?("DoublePowerIfTargetAsleepCureTarget",
                                                "DoublePowerIfTargetStatusProblem",
                                                "HealUserByHalfOfDamageDoneIfTargetAsleep",
                                                "StartDamageTargetEachTurnIfTargetAsleep")
        score += 10 if b.has_active_ability?(:BADDREAMS)
      end
      # Don't prefer if target benefits from having the sleep status problem
      # NOTE: The target's Guts/Quick Feet will benefit from the target being
      #       asleep, but the target won't (usually) be able to make use of
      #       them, so they're not worth considering.
      score -= 10 if target.has_active_ability?(:EARLYBIRD)
      score -= 8 if target.has_active_ability?(:MARVELSCALE)
      # Don't prefer if target has a move it can use while asleep
      score -= 8 if target.check_for_move { |m| m.usableWhenAsleep? }
      # Don't prefer if the target can heal itself (or be healed by an ally)
      if target.has_active_ability?(:SHEDSKIN)
        score -= 8
      elsif target.has_active_ability?(:HYDRATION) &&
            [:Rain, :HeavyRain].include?(target.battler.effectiveWeather)
        score -= 15
      end
      ai.each_same_side_battler(target.side) do |b, i|
        score -= 8 if i != target.index && b.has_active_ability?(:HEALER)
      end
    end
    next score
  }
)

#===============================================================================
# PoisonTarget
#===============================================================================
# Add score modifier for Barb Barrage and Infernal Parade
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("PoisonTarget",
  proc { |score, move, user, target, ai, battle|
    useless_score = (move.statusMove?) ? Battle::AI::MOVE_USELESS_SCORE : score
    next useless_score if target.has_active_ability?(:POISONHEAL)
    # No score modifier if the poisoning will be removed immediately
    next useless_score if target.has_active_item?([:PECHABERRY, :LUMBERRY])
    next useless_score if target.faster_than?(user) &&
                          target.has_active_ability?(:HYDRATION) &&
                          [:Rain, :HeavyRain].include?(target.battler.effectiveWeather)
    if target.battler.pbCanPoison?(user.battler, false, move.move)
      add_effect = move.get_score_change_for_additional_effect(user, target)
      next useless_score if add_effect == -999   # Additional effect will be negated
      score += add_effect
      # Inherent preference
      score += 15
      # Prefer if the target is at high HP
      if ai.trainer.has_skill_flag?("HPAware")
        score += 15 * target.hp / target.totalhp
      end
      # Prefer if the user or an ally has a move/ability that is better if the target is poisoned
      ai.each_same_side_battler(user.side) do |b, i|
        score += 5 if b.has_move_with_function?("DoublePowerIfTargetPoisoned",
                                                "DoublePowerIfTargetStatusProblem",
                                                "DoublePowerIfTargetPoisonedPoisonTarget",
                                                "DoublePowerIfTargetStatusProblemBurnTarget")
        score += 10 if b.has_active_ability?(:MERCILESS)
      end
      # Don't prefer if target benefits from having the poison status problem
      score -= 8 if target.has_active_ability?([:GUTS, :MARVELSCALE, :QUICKFEET, :TOXICBOOST])
      score -= 25 if target.has_active_ability?(:POISONHEAL)
      score -= 20 if target.has_active_ability?(:SYNCHRONIZE) &&
                     user.battler.pbCanPoisonSynchronize?(target.battler)
      score -= 5 if target.has_move_with_function?("DoublePowerIfUserPoisonedBurnedParalyzed",
                                                   "CureUserBurnPoisonParalysis")
      score -= 15 if target.check_for_move { |m|
        m.function_code == "GiveUserStatusToTarget" && user.battler.pbCanPoison?(target.battler, false, m)
      }
      # Don't prefer if the target won't take damage from the poison
      score -= 20 if !target.battler.takesIndirectDamage?
      # Don't prefer if the target can heal itself (or be healed by an ally)
      if target.has_active_ability?(:SHEDSKIN)
        score -= 8
      elsif target.has_active_ability?(:HYDRATION) &&
            [:Rain, :HeavyRain].include?(target.battler.effectiveWeather)
        score -= 15
      end
      ai.each_same_side_battler(target.side) do |b, i|
        score -= 8 if i != target.index && b.has_active_ability?(:HEALER)
      end
    end
    next score
  }
)

#===============================================================================
# ParalyzeTarget
#===============================================================================
# Add score modifier for Infernal Parade
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("ParalyzeTarget",
  proc { |score, move, user, target, ai, battle|
    useless_score = (move.statusMove?) ? Battle::AI::MOVE_USELESS_SCORE : score
    # No score modifier if the paralysis will be removed immediately
    next useless_score if target.has_active_item?([:CHERIBERRY, :LUMBERRY])
    next useless_score if target.faster_than?(user) &&
                          target.has_active_ability?(:HYDRATION) &&
                          [:Rain, :HeavyRain].include?(target.battler.effectiveWeather)
    if target.battler.pbCanParalyze?(user.battler, false, move.move)
      add_effect = move.get_score_change_for_additional_effect(user, target)
      next useless_score if add_effect == -999   # Additional effect will be negated
      score += add_effect
      # Inherent preference (because of the chance of full paralysis)
      score += 10
      # Prefer if the target is faster than the user but will become slower if
      # paralysed
      if target.faster_than?(user)
        user_speed = user.rough_stat(:SPEED)
        target_speed = target.rough_stat(:SPEED)
        score += 15 if target_speed < user_speed * ((Settings::MECHANICS_GENERATION >= 7) ? 2 : 4)
      end
      # Prefer if the target is confused or infatuated, to compound the turn skipping
      score += 7 if target.effects[PBEffects::Confusion] > 1
      score += 7 if target.effects[PBEffects::Attract] >= 0
      # Prefer if the user or an ally has a move/ability that is better if the target is paralysed
      ai.each_same_side_battler(user.side) do |b, i|
        score += 5 if b.has_move_with_function?("DoublePowerIfTargetParalyzedCureTarget",
                                                "DoublePowerIfTargetStatusProblem",
                                                "DoublePowerIfTargetStatusProblemBurnTarget")
      end
      # Don't prefer if target benefits from having the paralysis status problem
      score -= 8 if target.has_active_ability?([:GUTS, :MARVELSCALE, :QUICKFEET])
      score -= 20 if target.has_active_ability?(:SYNCHRONIZE) &&
                     user.battler.pbCanParalyzeSynchronize?(target.battler)
      score -= 5 if target.has_move_with_function?("DoublePowerIfUserPoisonedBurnedParalyzed",
                                                   "CureUserBurnPoisonParalysis")
      score -= 15 if target.check_for_move { |m|
        m.function_code == "GiveUserStatusToTarget" && user.battler.pbCanParalyze?(target.battler, false, m)
      }
      # Don't prefer if the target can heal itself (or be healed by an ally)
      if target.has_active_ability?(:SHEDSKIN)
        score -= 8
      elsif target.has_active_ability?(:HYDRATION) &&
            [:Rain, :HeavyRain].include?(target.battler.effectiveWeather)
        score -= 15
      end
      ai.each_same_side_battler(target.side) do |b, i|
        score -= 8 if i != target.index && b.has_active_ability?(:HEALER)
      end
    end
    next score
  }
)

#===============================================================================
# BurnTarget
#===============================================================================
# Add score modifier for Infernal Parade
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("BurnTarget",
  proc { |score, move, user, target, ai, battle|
    useless_score = (move.statusMove?) ? Battle::AI::MOVE_USELESS_SCORE : score
    # No score modifier if the burn will be removed immediately
    next useless_score if target.has_active_item?([:RAWSTBERRY, :LUMBERRY])
    next useless_score if target.faster_than?(user) &&
                          target.has_active_ability?(:HYDRATION) &&
                          [:Rain, :HeavyRain].include?(target.battler.effectiveWeather)
    if target.battler.pbCanBurn?(user.battler, false, move.move)
      add_effect = move.get_score_change_for_additional_effect(user, target)
      next useless_score if add_effect == -999   # Additional effect will be negated
      score += add_effect
      # Inherent preference
      score += 15
      # Prefer if the target knows any physical moves that will be weaked by a burn
      if !target.has_active_ability?(:GUTS) && target.check_for_move { |m| m.physicalMove? }
        score += 8
        score += 8 if !target.check_for_move { |m| m.specialMove? }
      end
      # Prefer if the user or an ally has a move/ability that is better if the target is burned
      ai.each_same_side_battler(user.side) do |b, i|
        score += 5 if b.has_move_with_function?("DoublePowerIfTargetStatusProblem",
                                                "DoublePowerIfTargetStatusProblemBurnTarget")
      end
      # Don't prefer if target benefits from having the burn status problem
      score -= 8 if target.has_active_ability?([:FLAREBOOST, :GUTS, :MARVELSCALE, :QUICKFEET])
      score -= 5 if target.has_active_ability?(:HEATPROOF)
      score -= 20 if target.has_active_ability?(:SYNCHRONIZE) &&
                     user.battler.pbCanBurnSynchronize?(target.battler)
      score -= 5 if target.has_move_with_function?("DoublePowerIfUserPoisonedBurnedParalyzed",
                                                   "CureUserBurnPoisonParalysis")
      score -= 15 if target.check_for_move { |m|
        m.function_code == "GiveUserStatusToTarget" && user.battler.pbCanBurn?(target.battler, false, m)
      }
      # Don't prefer if the target won't take damage from the burn
      score -= 20 if !target.battler.takesIndirectDamage?
      # Don't prefer if the target can heal itself (or be healed by an ally)
      if target.has_active_ability?(:SHEDSKIN)
        score -= 8
      elsif target.has_active_ability?(:HYDRATION) &&
            [:Rain, :HeavyRain].include?(target.battler.effectiveWeather)
        score -= 15
      end
      ai.each_same_side_battler(target.side) do |b, i|
        score -= 8 if i != target.index && b.has_active_ability?(:HEALER)
      end
    end
    next score
  }
)

#===============================================================================
# FreezeTarget
#===============================================================================
# Add score modifier for Infernal Parade
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("FreezeTarget",
  proc { |score, move, user, target, ai, battle|
    useless_score = (move.statusMove?) ? Battle::AI::MOVE_USELESS_SCORE : score
    # No score modifier if the freeze will be removed immediately
    next useless_score if target.has_active_item?([:ASPEARBERRY, :LUMBERRY])
    next useless_score if target.faster_than?(user) &&
                          target.has_active_ability?(:HYDRATION) &&
                          [:Rain, :HeavyRain].include?(target.battler.effectiveWeather)
    if target.battler.pbCanFreeze?(user.battler, false, move.move)
      add_effect = move.get_score_change_for_additional_effect(user, target)
      next useless_score if add_effect == -999   # Additional effect will be negated
      score += add_effect
      # Inherent preference
      score += 15
      # Prefer if the user or an ally has a move/ability that is better if the target is frozen
      ai.each_same_side_battler(user.side) do |b, i|
        score += 5 if b.has_move_with_function?("DoublePowerIfTargetStatusProblem",
                                                "DoublePowerIfTargetStatusProblemBurnTarget")
      end
      # Don't prefer if target benefits from having the frozen status problem
      # NOTE: The target's Guts/Quick Feet will benefit from the target being
      #       frozen, but the target won't be able to make use of them, so
      #       they're not worth considering.
      score -= 8 if target.has_active_ability?(:MARVELSCALE)
      # Don't prefer if the target knows a move that can thaw it
      score -= 15 if target.check_for_move { |m| m.thawsUser? }
      # Don't prefer if the target can heal itself (or be healed by an ally)
      if target.has_active_ability?(:SHEDSKIN)
        score -= 8
      elsif target.has_active_ability?(:HYDRATION) &&
            [:Rain, :HeavyRain].include?(target.battler.effectiveWeather)
        score -= 15
      end
      ai.each_same_side_battler(target.side) do |b, i|
        score -= 8 if i != target.index && b.has_active_ability?(:HEALER)
      end
    end
    next score
  }
)

#===============================================================================
# Roar, Whirlwind
#===============================================================================
# Add score modifier for Zero to Hero
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("SwitchOutTargetStatusMove",
  proc { |score, move, user, target, ai, battle|
    # Ends the battle - generally don't prefer (don't want to end the battle too easily)
    next score - 10 if target.wild?
    # Switches the target out
    next Battle::AI::MOVE_USELESS_SCORE if target.effects[PBEffects::PerishSong] > 0
    # Don't prefer if target is at low HP and could be knocked out instead
    if ai.trainer.has_skill_flag?("HPAware")
      score -= 10 if target.hp <= target.totalhp / 3
    end
    # Consider the target's stat stages
    if target.stages.any? { |key, val| val >= 2 }
      score += 15
    elsif target.stages.any? { |key, val| val < 0 }
      score -= 15
    end
    # Consider the target's end of round damage/healing
    eor_damage = target.rough_end_of_round_damage
    score -= 15 if eor_damage > 0
    score += 15 if eor_damage < 0
    # Prefer if the target's side has entry hazards on it
    score += 10 if target.pbOwnSide.effects[PBEffects::Spikes] > 0
    score += 10 if target.pbOwnSide.effects[PBEffects::ToxicSpikes] > 0
    score += 10 if target.pbOwnSide.effects[PBEffects::StealthRock]
    # Don't prefer if the target switching out will change its form
    score -= 20 if target.has_active_ability?(:ZEROTOHERO) && target.battler.form == 0
    next score
  }
)

#===============================================================================
# Teleport (Gen 8+)
#===============================================================================
# Add score modifier for Zero to Hero
Battle::AI::Handlers::MoveEffectScore.add("SwitchOutUserStatusMove",
  proc { |score, move, user, ai, battle|
    # Wild Pokémon run from battle - generally don't prefer (don't want to end the battle too easily)
    next score - 20 if user.wild?
    # Trainer-owned Pokémon switch out
    if ai.trainer.has_skill_flag?("ReserveLastPokemon") && battle.pbTeamAbleNonActiveCount(user.index) == 1
      next Battle::AI::MOVE_USELESS_SCORE   # Don't switch in ace
    end
    # Prefer if the user switching out will lose a negative effect
    score += 20 if user.effects[PBEffects::PerishSong] > 0
    score += 10 if user.effects[PBEffects::Confusion] > 1
    score += 10 if user.effects[PBEffects::Attract] >= 0
    # Prefer if the user switching out will change its form
    score += 20 if user.has_active_ability?(:ZEROTOHERO) && user.battler.form == 0
    # Consider the user's stat stages
    if user.stages.any? { |key, val| val >= 2 }
      score -= 15
    elsif user.stages.any? { |key, val| val < 0 }
      score += 10
    end
    # Consider the user's end of round damage/healing
    eor_damage = user.rough_end_of_round_damage
    score += 15 if eor_damage > 0
    score -= 15 if eor_damage < 0
    # Prefer if the user doesn't have any damaging moves
    score += 10 if !user.check_for_move { |m| m.damagingMove? }
    # Don't prefer if the user's side has entry hazards on it
    score -= 10 if user.pbOwnSide.effects[PBEffects::Spikes] > 0
    score -= 10 if user.pbOwnSide.effects[PBEffects::ToxicSpikes] > 0
    score -= 10 if user.pbOwnSide.effects[PBEffects::StealthRock]
    next score
  }
)

#===============================================================================
# Flip Turn, U-turn, Volt Switch
#===============================================================================
# Add score modifier for Zero to Hero
Battle::AI::Handlers::MoveEffectScore.add("SwitchOutUserDamagingMove",
  proc { |score, move, user, ai, battle|
    next score if !battle.pbCanChooseNonActive?(user.index)
    # Don't want to switch in ace
    score -= 20 if ai.trainer.has_skill_flag?("ReserveLastPokemon") &&
                   battle.pbTeamAbleNonActiveCount(user.index) == 1
    # Prefer if the user switching out will lose a negative effect
    score += 20 if user.effects[PBEffects::PerishSong] > 0
    score += 10 if user.effects[PBEffects::Confusion] > 1
    score += 10 if user.effects[PBEffects::Attract] >= 0
    # Prefer if the user switching out will change its form
    score += 20 if user.has_active_ability?(:ZEROTOHERO) && user.battler.form == 0
    # Consider the user's stat stages
    if user.stages.any? { |key, val| val >= 2 }
      score -= 15
    elsif user.stages.any? { |key, val| val < 0 }
      score += 10
    end
    # Consider the user's end of round damage/healing
    eor_damage = user.rough_end_of_round_damage
    score += 15 if eor_damage > 0
    score -= 15 if eor_damage < 0
    # Don't prefer if the user's side has entry hazards on it
    score -= 10 if user.pbOwnSide.effects[PBEffects::Spikes] > 0
    score -= 10 if user.pbOwnSide.effects[PBEffects::ToxicSpikes] > 0
    score -= 10 if user.pbOwnSide.effects[PBEffects::StealthRock]
    next score
  }
)
#===============================================================================
# Parting Shot
#===============================================================================
# Add score modifier for Zero to Hero
Battle::AI::Handlers::MoveEffectScore.add("LowerTargetAtkSpAtk1SwitchOutUser",
  proc { |score, move, user, ai, battle|
    next score if !battle.pbCanChooseNonActive?(user.index)
    # Prefer if the user switching out will change its form
    score += 20 if user.has_active_ability?(:ZEROTOHERO) && user.battler.form == 0
    next score
  }
)
#===============================================================================
# Baton Pass
#===============================================================================
# Add score modifier for Zero to Hero
Battle::AI::Handlers::MoveEffectScore.add("SwitchOutUserPassOnEffects",
  proc { |score, move, user, ai, battle|
    # Don't want to switch in ace
    score -= 20 if ai.trainer.has_skill_flag?("ReserveLastPokemon") &&
                   battle.pbTeamAbleNonActiveCount(user.index) == 1
    # Don't prefer if the user will pass on a negative effect
    score -= 10 if user.effects[PBEffects::Confusion] > 1
    score -= 15 if user.effects[PBEffects::Curse]
    score -= 10 if user.effects[PBEffects::Embargo] > 1
    score -= 15 if user.effects[PBEffects::GastroAcid]
    score -= 10 if user.effects[PBEffects::HealBlock] > 1
    score -= 10 if user.effects[PBEffects::LeechSeed] >= 0
    score -= 20 if user.effects[PBEffects::PerishSong] > 0
    # Prefer if the user will pass on a positive effect
    score += 10 if user.effects[PBEffects::AquaRing]
    score += 10 if user.effects[PBEffects::FocusEnergy] > 0
    score += 10 if user.effects[PBEffects::Ingrain]
    score += 8 if user.effects[PBEffects::MagnetRise] > 1
    score += 10 if user.effects[PBEffects::Substitute] > 0
    # Consider the user's stat stages
    if user.stages.any? { |key, val| val >= 4 }
      score += 25
    elsif user.stages.any? { |key, val| val >= 2 }
      score += 15
    elsif user.stages.any? { |key, val| val < 0 }
      score -= 15
    end
    # Consider the user's end of round damage/healing
    eor_damage = user.rough_end_of_round_damage
    score += 15 if eor_damage > 0
    score -= 15 if eor_damage < 0
    # Prefer if the user doesn't have any damaging moves
    score += 15 if !user.check_for_move { |m| m.damagingMove? }
    # Don't prefer if the user's side has entry hazards on it
    score -= 10 if user.pbOwnSide.effects[PBEffects::Spikes] > 0
    score -= 10 if user.pbOwnSide.effects[PBEffects::ToxicSpikes] > 0
    score -= 10 if user.pbOwnSide.effects[PBEffects::StealthRock]
    # Prefer if the user switching out will change its form
    score += 20 if user.has_active_ability?(:ZEROTOHERO) && user.battler.form == 0
    next score
  }
)

#===============================================================================
# Circle Throw, Dragon Tail
#===============================================================================
# Add score modifier for Guard Dog and Zero to Hero
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("SwitchOutTargetDamagingMove",
  proc { |score, move, user, target, ai, battle|
    next score if target.wild?
    # No score modification if the target can't be made to switch out
    next score if !battle.moldBreaker && target.has_active_ability?([:SUCTIONCUPS,:GUARDDOG])
    next score if target.effects[PBEffects::Ingrain]
    # No score modification if the target can't be replaced
    can_switch = false
    battle.eachInTeamFromBattlerIndex(target.index) do |_pkmn, i|
      can_switch = battle.pbCanSwitchIn?(target.index, i)
      break if can_switch
    end
    next score if !can_switch
    # Not score modification if the target has a Substitute
    next score if target.effects[PBEffects::Substitute] > 0
    # Don't want to switch out the target if it will faint from Perish Song
    score -= 20 if target.effects[PBEffects::PerishSong] > 0
    # Consider the target's stat stages
    if target.stages.any? { |key, val| val >= 2 }
      score += 15
    elsif target.stages.any? { |key, val| val < 0 }
      score -= 15
    end
    # Consider the target's end of round damage/healing
    eor_damage = target.rough_end_of_round_damage
    score -= 15 if eor_damage > 0
    score += 15 if eor_damage < 0
    # Prefer if the target's side has entry hazards on it
    score += 10 if target.pbOwnSide.effects[PBEffects::Spikes] > 0
    score += 10 if target.pbOwnSide.effects[PBEffects::ToxicSpikes] > 0
    score += 10 if target.pbOwnSide.effects[PBEffects::StealthRock]
    # Don't prefer if the target switching out will change its form
    score -= 20 if target.has_active_ability?(:ZEROTOHERO) && target.battler.form == 0
    next score
  }
)

#===============================================================================
# Protect
#===============================================================================
# Add score modifier for Glaive Rush
Battle::AI::Handlers::MoveEffectScore.add("ProtectUser",
  proc { |score, move, user, ai, battle|
    # Useless if the success chance is 25% or lower
    next Battle::AI::MOVE_USELESS_SCORE if user.effects[PBEffects::ProtectRate] >= 4
    # Score changes for each foe
    useless = true
    ai.each_foe_battler(user.side) do |b, i|
      next if !b.can_attack?
      next if !b.check_for_move { |m| m.canProtectAgainst? }
      next if b.has_active_ability?(:UNSEENFIST) && b.check_for_move { |m| m.contactMove? }
      useless = false
      # General preference
      score += 7
      # Prefer if the foe is in the middle of using a two turn attack
      score += 15 if b.effects[PBEffects::TwoTurnAttack] &&
                     GameData::Move.get(b.effects[PBEffects::TwoTurnAttack]).flags.any? { |f| f[/^CanProtect$/i] }
      # Prefer if foe takes EOR damage, don't prefer if they have EOR healing
      b_eor_damage = b.rough_end_of_round_damage
      if b_eor_damage > 0
        score += 8
      elsif b_eor_damage < 0
        score -= 8
      end
    end
    next Battle::AI::MOVE_USELESS_SCORE if useless
    # Prefer if the user has EOR healing, don't prefer if they take EOR damage
    user_eor_damage = user.rough_end_of_round_damage
    if user_eor_damage >= user.hp
      next Battle::AI::MOVE_USELESS_SCORE
    elsif user_eor_damage > 0
      score -= 8
    elsif user_eor_damage < 0
      score += 8
    end
    # Don't prefer if the user used a protection move last turn, making this one
    # less likely to work
    score -= (user.effects[PBEffects::ProtectRate] - 1) * ((Settings::MECHANICS_GENERATION >= 6) ? 15 : 10)
    # Prefer if the user used Glaive Rush last turn
    score += 20 if user.effects[PBEffects::GlaiveRush] > 0
    next score
  }
)

#===============================================================================
# Baneful Bunker
#===============================================================================
# Add score modifier for Glaive Rush
Battle::AI::Handlers::MoveEffectScore.add("ProtectUserBanefulBunker",
  proc { |score, move, user, ai, battle|
    # Useless if the success chance is 25% or lower
    next Battle::AI::MOVE_USELESS_SCORE if user.effects[PBEffects::ProtectRate] >= 4
    # Score changes for each foe
    useless = true
    ai.each_foe_battler(user.side) do |b, i|
      next if !b.can_attack?
      next if !b.check_for_move { |m| m.canProtectAgainst? }
      next if b.has_active_ability?(:UNSEENFIST) && b.check_for_move { |m| m.contactMove? }
      useless = false
      # General preference
      score += 7
      # Prefer if the foe is likely to be poisoned by this move
      if b.check_for_move { |m| m.contactMove? }
        poison_score = Battle::AI::Handlers.apply_move_effect_against_target_score("PoisonTarget",
           0, move, user, b, ai, battle)
        if poison_score != Battle::AI::MOVE_USELESS_SCORE
          score += poison_score / 2   # Halved because we don't know what move b will use
        end
      end
      # Prefer if the foe is in the middle of using a two turn attack
      score += 15 if b.effects[PBEffects::TwoTurnAttack] &&
                     GameData::Move.get(b.effects[PBEffects::TwoTurnAttack]).flags.any? { |f| f[/^CanProtect$/i] }
      # Prefer if foe takes EOR damage, don't prefer if they have EOR healing
      b_eor_damage = b.rough_end_of_round_damage
      if b_eor_damage > 0
        score += 8
      elsif b_eor_damage < 0
        score -= 8
      end
    end
    next Battle::AI::MOVE_USELESS_SCORE if useless
    # Prefer if the user has EOR healing, don't prefer if they take EOR damage
    user_eor_damage = user.rough_end_of_round_damage
    if user_eor_damage >= user.hp
      next Battle::AI::MOVE_USELESS_SCORE
    elsif user_eor_damage > 0
      score -= 8
    elsif user_eor_damage < 0
      score += 8
    end
    # Don't prefer if the user used a protection move last turn, making this one
    # less likely to work
    score -= (user.effects[PBEffects::ProtectRate] - 1) * ((Settings::MECHANICS_GENERATION >= 6) ? 15 : 10)
    # Prefer if the user used Glaive Rush last turn
    score += 20 if user.effects[PBEffects::GlaiveRush] > 0
    next score
  }
)

#===============================================================================
# King Shield
#===============================================================================
# Add score modifier for Glaive Rush
Battle::AI::Handlers::MoveEffectScore.add("ProtectUserFromDamagingMovesKingsShield",
  proc { |score, move, user, ai, battle|
    # Useless if the success chance is 25% or lower
    next Battle::AI::MOVE_USELESS_SCORE if user.effects[PBEffects::ProtectRate] >= 4
    # Score changes for each foe
    useless = true
    ai.each_foe_battler(user.side) do |b, i|
      next if !b.can_attack?
      next if !b.check_for_move { |m| m.damagingMove? && m.canProtectAgainst? }
      next if b.has_active_ability?(:UNSEENFIST) && b.check_for_move { |m| m.contactMove? }
      useless = false
      # General preference
      score += 7
      # Prefer if the foe's Attack can be lowered by this move
      if b.battler.affectedByContactEffect? && b.check_for_move { |m| m.contactMove? }
        drop_score = ai.get_score_for_target_stat_drop(
           0, b, [:ATTACK, (Settings::MECHANICS_GENERATION >= 8) ? 1 : 2], false)
        score += drop_score / 2   # Halved because we don't know what move b will use
      end
      # Prefer if the foe is in the middle of using a two turn attack
      score += 15 if b.effects[PBEffects::TwoTurnAttack] &&
                     GameData::Move.get(b.effects[PBEffects::TwoTurnAttack]).flags.any? { |f| f[/^CanProtect$/i] }
      # Prefer if foe takes EOR damage, don't prefer if they have EOR healing
      b_eor_damage = b.rough_end_of_round_damage
      if b_eor_damage > 0
        score += 8
      elsif b_eor_damage < 0
        score -= 8
      end
    end
    next Battle::AI::MOVE_USELESS_SCORE if useless
    # Prefer if the user has EOR healing, don't prefer if they take EOR damage
    user_eor_damage = user.rough_end_of_round_damage
    if user_eor_damage >= user.hp
      next Battle::AI::MOVE_USELESS_SCORE
    elsif user_eor_damage > 0
      score -= 8
    elsif user_eor_damage < 0
      score += 8
    end
    # Don't prefer if the user used a protection move last turn, making this one
    # less likely to work
    score -= (user.effects[PBEffects::ProtectRate] - 1) * ((Settings::MECHANICS_GENERATION >= 6) ? 15 : 10)
    # Aegislash
    score += 10 if user.battler.isSpecies?(:AEGISLASH) && user.battler.form == 1 &&
                   user.ability == :STANCECHANGE
    # Prefer if the user used Glaive Rush last turn
    score += 20 if user.effects[PBEffects::GlaiveRush] > 0
    next score
  }
)

#===============================================================================
# Obstruct
#===============================================================================
# Add score modifier for Glaive Rush
Battle::AI::Handlers::MoveEffectScore.add("ProtectUserFromDamagingMovesObstruct",
  proc { |score, move, user, ai, battle|
    # Useless if the success chance is 25% or lower
    next Battle::AI::MOVE_USELESS_SCORE if user.effects[PBEffects::ProtectRate] >= 4
    # Score changes for each foe
    useless = true
    ai.each_foe_battler(user.side) do |b, i|
      next if !b.can_attack?
      next if !b.check_for_move { |m| m.damagingMove? && m.canProtectAgainst? }
      next if b.has_active_ability?(:UNSEENFIST) && b.check_for_move { |m| m.contactMove? }
      useless = false
      # General preference
      score += 7
      # Prefer if the foe's Attack can be lowered by this move
      if b.battler.affectedByContactEffect? && b.check_for_move { |m| m.contactMove? }
        drop_score = ai.get_score_for_target_stat_drop(0, b, [:DEFENSE, 2], false)
        score += drop_score / 2   # Halved because we don't know what move b will use
      end
      # Prefer if the foe is in the middle of using a two turn attack
      score += 15 if b.effects[PBEffects::TwoTurnAttack] &&
                     GameData::Move.get(b.effects[PBEffects::TwoTurnAttack]).flags.any? { |f| f[/^CanProtect$/i] }
      # Prefer if foe takes EOR damage, don't prefer if they have EOR healing
      b_eor_damage = b.rough_end_of_round_damage
      if b_eor_damage > 0
        score += 8
      elsif b_eor_damage < 0
        score -= 8
      end
    end
    next Battle::AI::MOVE_USELESS_SCORE if useless
    # Prefer if the user has EOR healing, don't prefer if they take EOR damage
    user_eor_damage = user.rough_end_of_round_damage
    if user_eor_damage >= user.hp
      next Battle::AI::MOVE_USELESS_SCORE
    elsif user_eor_damage > 0
      score -= 8
    elsif user_eor_damage < 0
      score += 8
    end
    # Don't prefer if the user used a protection move last turn, making this one
    # less likely to work
    score -= (user.effects[PBEffects::ProtectRate] - 1) * ((Settings::MECHANICS_GENERATION >= 6) ? 15 : 10)
    # Prefer if the user used Glaive Rush last turn
    score += 20 if user.effects[PBEffects::GlaiveRush] > 0
    next score
  }
)

#===============================================================================
# Spiky Shield
#===============================================================================
# Add score modifier for Glaive Rush
Battle::AI::Handlers::MoveEffectScore.add("ProtectUserFromTargetingMovesSpikyShield",
  proc { |score, move, user, ai, battle|
    # Useless if the success chance is 25% or lower
    next Battle::AI::MOVE_USELESS_SCORE if user.effects[PBEffects::ProtectRate] >= 4
    # Score changes for each foe
    useless = true
    ai.each_foe_battler(user.side) do |b, i|
      next if !b.can_attack?
      next if !b.check_for_move { |m| m.canProtectAgainst? }
      next if b.has_active_ability?(:UNSEENFIST) && b.check_for_move { |m| m.contactMove? }
      useless = false
      # General preference
      score += 7
      # Prefer if this move will deal damage
      if b.battler.affectedByContactEffect? && b.check_for_move { |m| m.contactMove? }
        score += 5
      end
      # Prefer if the foe is in the middle of using a two turn attack
      score += 15 if b.effects[PBEffects::TwoTurnAttack] &&
                     GameData::Move.get(b.effects[PBEffects::TwoTurnAttack]).flags.any? { |f| f[/^CanProtect$/i] }
      # Prefer if foe takes EOR damage, don't prefer if they have EOR healing
      b_eor_damage = b.rough_end_of_round_damage
      if b_eor_damage > 0
        score += 8
      elsif b_eor_damage < 0
        score -= 8
      end
    end
    next Battle::AI::MOVE_USELESS_SCORE if useless
    # Prefer if the user has EOR healing, don't prefer if they take EOR damage
    user_eor_damage = user.rough_end_of_round_damage
    if user_eor_damage >= user.hp
      next Battle::AI::MOVE_USELESS_SCORE
    elsif user_eor_damage > 0
      score -= 8
    elsif user_eor_damage < 0
      score += 8
    end
    # Don't prefer if the user used a protection move last turn, making this one
    # less likely to work
    score -= (user.effects[PBEffects::ProtectRate] - 1) * ((Settings::MECHANICS_GENERATION >= 6) ? 15 : 10)
    # Prefer if the user used Glaive Rush last turn
    score += 20 if user.effects[PBEffects::GlaiveRush] > 0
    next score
  }
)

#===============================================================================
# Quick Guard
#===============================================================================
# Add score modifier for Glaive Rush
Battle::AI::Handlers::MoveEffectScore.add("ProtectUserSideFromPriorityMoves",
  proc { |score, move, user, ai, battle|
    # Useless if the success chance is 25% or lower
    next Battle::AI::MOVE_USELESS_SCORE if user.effects[PBEffects::ProtectRate] >= 4
    # Score changes for each foe
    useless = true
    ai.each_foe_battler(user.side) do |b, i|
      next if !b.can_attack?
      next if !b.check_for_move { |m| m.pbPriority(b.battler) > 0 && m.canProtectAgainst? }
      useless = false
      # General preference
      score += 7
      # Prefer if foe takes EOR damage, don't prefer if they have EOR healing
      b_eor_damage = b.rough_end_of_round_damage
      if b_eor_damage > 0
        score += 8
      elsif b_eor_damage < 0
        score -= 8
      end
    end
    next Battle::AI::MOVE_USELESS_SCORE if useless
    # Prefer if the user has EOR healing, don't prefer if they take EOR damage
    user_eor_damage = user.rough_end_of_round_damage
    if user_eor_damage >= user.hp
      next Battle::AI::MOVE_USELESS_SCORE
    elsif user_eor_damage > 0
      score -= 8
    elsif user_eor_damage < 0
      score += 8
    end
    # Don't prefer if the user used a protection move last turn, making this one
    # less likely to work
    score -= (user.effects[PBEffects::ProtectRate] - 1) * ((Settings::MECHANICS_GENERATION >= 6) ? 15 : 10)
    # Prefer if the user used Glaive Rush last turn
    score += 10 if user.effects[PBEffects::GlaiveRush] > 0
    next score
  }
)

#===============================================================================
# Wide Guard
#===============================================================================
# Add score modifier for Glaive Rush
Battle::AI::Handlers::MoveEffectScore.add("ProtectUserSideFromMultiTargetDamagingMoves",
  proc { |score, move, user, ai, battle|
    # Useless if the success chance is 25% or lower
    next Battle::AI::MOVE_USELESS_SCORE if user.effects[PBEffects::ProtectRate] >= 4
    # Score changes for each foe
    useless = true
    ai.each_battler do |b, i|
      next if b.index == user.index || !b.can_attack?
      next if !b.check_for_move { |m| (Settings::MECHANICS_GENERATION >= 7 || move.damagingMove?) &&
                                      m.pbTarget(b.battler).num_targets > 1 }
      useless = false
      # General preference
      score += 7
      # Prefer if foe takes EOR damage, don't prefer if they have EOR healing
      b_eor_damage = b.rough_end_of_round_damage
      if b_eor_damage > 0
        score += (b.opposes?(user)) ? 8 : -8
      elsif b_eor_damage < 0
        score -= (b.opposes?(user)) ? 8 : -8
      end
    end
    next Battle::AI::MOVE_USELESS_SCORE if useless
    # Prefer if the user has EOR healing, don't prefer if they take EOR damage
    user_eor_damage = user.rough_end_of_round_damage
    if user_eor_damage >= user.hp
      next Battle::AI::MOVE_USELESS_SCORE
    elsif user_eor_damage > 0
      score -= 8
    elsif user_eor_damage < 0
      score += 8
    end
    # Don't prefer if the user used a protection move last turn, making this one
    # less likely to work
    score -= (user.effects[PBEffects::ProtectRate] - 1) * ((Settings::MECHANICS_GENERATION >= 6) ? 15 : 10)
    # Prefer if the user used Glaive Rush last turn
    score += 20 if user.effects[PBEffects::GlaiveRush] > 0
    next score
  }
)
#===============================================================================
# Wake-Up Slap
#===============================================================================
# Add Drowsy as a sleep
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("DoublePowerIfTargetAsleepCureTarget",
  proc { |score, move, user, target, ai, battle|
    if [:SLEEP, :DROWSY].include?(target.status) && target.statusCount > 1   # Will cure status
      if target.wants_status_problem?(target.status)
        score += 15
      else
        score -= 10
      end
    end
    next score
  }
)

#===============================================================================
# Rest
#===============================================================================
# Adds failure check with the Purifying Salt ability.
Battle::AI::Handlers::MoveFailureCheck.add("HealUserFullyAndFallAsleep",
  proc { |move, user, ai, battle|
    next true if user.battler.hasActiveAbility?(:PURIFYINGSALT)
    next true if !user.battler.canHeal?
    next true if user.battler.asleep?
    next true if !user.battler.pbCanSleep?(user.battler, false, move.move, true)
    next false
  }
)

#===============================================================================
# Ally Switch
#===============================================================================
# Allows Ally Switch to function like it does in Gen 9 if MECHANICS_GENERATION >= 9.
Battle::AI::Handlers::MoveFailureCheck.add("UserSwapsPositionsWithAlly",
  proc { |move, user, ai, battle|
    next true if Settings::MECHANICS_GENERATION >= 9 && user.effects[PBEffects::AllySwitch]
    num_targets = 0
    idxUserOwner = battle.pbGetOwnerIndexFromBattlerIndex(user.index)
    ai.each_ally(user.side) do |b, i|
      next if battle.pbGetOwnerIndexFromBattlerIndex(b.index) != idxUserOwner
      next if !b.battler.near?(user.battler)
      num_targets += 1
    end
    next num_targets != 1
  }
)

#===============================================================================
# Entrainment 
#===============================================================================
# Add target's Ability Shield check
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("SetTargetAbilityToUserAbility",
  proc { |move, user, target, ai, battle|
    next true if target.battler.hasActiveItem?(:ABILITYSHIELD)
    next true if !user.ability || user.ability_id == target.ability_id
    next true if user.battler.ungainableAbility? ||
                 [:POWEROFALCHEMY, :RECEIVER, :TRACE].include?(user.ability_id)
    next move.move.pbFailsAgainstTarget?(user.battler, target.battler, false)
  }
)

#===============================================================================
# Skill Swap
#===============================================================================
# Adds Ability Shield immunity. Fails if user is holding an Ability Shield.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("UserTargetSwapAbilities",
  proc { |move, user, target, ai, battle|
    next true if user.battler.hasActiveItem?(:ABILITYSHIELD)
    next true if !user.ability || user.battler.unstoppableAbility? ||
                 user.battler.ungainableAbility? || user.ability_id == :WONDERGUARD
    next move.move.pbFailsAgainstTarget?(user.battler, target.battler, false)
  }
)

#===============================================================================
# OHKO moves
#===============================================================================
# Add Glaive Rush to score modifier
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("OHKO",
  proc { |score, move, user, target, ai, battle|
    # Don't prefer if the target has less HP and user has a non-OHKO damaging move
    if ai.trainer.has_skill_flag?("HPAware")
      if user.check_for_move { |m| m.damagingMove? && !m.is_a?(Battle::Move::OHKO) }
        score -= 12 if target.hp <= target.totalhp / 2
        score -= 8 if target.hp <= target.totalhp / 4
      end
    end
    score += 20 if target.effects[PBEffects::GlaiveRush] > 0
    next score
  }
)

Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy("OHKO",
                                                        "OHKOIce")

Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy("OHKO",
                                                        "OHKOHitsUndergroundTarget")

#===============================================================================
# Judgment
#===============================================================================
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("TypeDependsOnUserPlate",
proc { |score, move, user, target, ai, battle|
    # Prefer if the user has Legend Plate
    score += 20 if user.battler.hasLegendPlateJudgment?
    next score
  }
)

#===============================================================================
# Raging Bull
#===============================================================================
Battle::AI::Handlers::MoveEffectScore.copy("RemoveScreens",
                                           "TypeIsUserSecondTypeRemoveScreens")

#===============================================================================
# Silk Trap
#===============================================================================
Battle::AI::Handlers::MoveEffectScore.add("ProtectUserFromDamagingMovesSilkTrap",
  proc { |score, move, user, ai, battle|
    # Useless if the success chance is 25% or lower
    next Battle::AI::MOVE_USELESS_SCORE if user.effects[PBEffects::ProtectRate] >= 4
    # Score changes for each foe
    useless = true
    ai.each_foe_battler(user.side) do |b, i|
      next if !b.can_attack?
      next if !b.check_for_move { |m| m.damagingMove? && m.canProtectAgainst? }
      next if b.has_active_ability?(:UNSEENFIST) && b.check_for_move { |m| m.contactMove? }
      useless = false
      # General preference
      score += 7
      # Prefer if the foe's Speed can be lowered by this move
      if b.battler.affectedByContactEffect? && b.check_for_move { |m| m.contactMove? }
        drop_score = ai.get_score_for_target_stat_drop(0, b, [:SPEED, 1], false)
        score += drop_score / 2   # Halved because we don't know what move b will use
      end
      # Prefer if the foe is in the middle of using a two turn attack
      score += 15 if b.effects[PBEffects::TwoTurnAttack] &&
                     GameData::Move.get(b.effects[PBEffects::TwoTurnAttack]).flags.any? { |f| f[/^CanProtect$/i] }
      # Prefer if foe takes EOR damage, don't prefer if they have EOR healing
      b_eor_damage = b.rough_end_of_round_damage
      if b_eor_damage > 0
        score += 8
      elsif b_eor_damage < 0
        score -= 8
      end
    end
    next Battle::AI::MOVE_USELESS_SCORE if useless
    # Prefer if the user has EOR healing, don't prefer if they take EOR damage
    user_eor_damage = user.rough_end_of_round_damage
    if user_eor_damage >= user.hp
      next Battle::AI::MOVE_USELESS_SCORE
    elsif user_eor_damage > 0
      score -= 8
    elsif user_eor_damage < 0
      score += 8
    end
    # Don't prefer if the user used a protection move last turn, making this one
    # less likely to work
    score -= (user.effects[PBEffects::ProtectRate] - 1) * ((Settings::MECHANICS_GENERATION >= 6) ? 15 : 10)
    # Prefer if the user used Glaive Rush last turn
    score += 20 if user.effects[PBEffects::GlaiveRush] > 0
    next score
  }
)

#===============================================================================
# Blazing Torque
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.copy("BurnTarget","StarmobileBurnTarget")
Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy("BurnTarget","StarmobileBurnTarget")

#===============================================================================
# Combat Torque
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.copy("ParalyzeTarget","StarmobileParalyzeTarget")
Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy("ParalyzeTarget","StarmobileParalyzeTarget")

#===============================================================================
# Magical Torque
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.copy("ConfuseTarget","StarmobileConfuseTarget")
Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy("ConfuseTarget","StarmobileConfuseTarget")

#===============================================================================
# Noxious Torque
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.copy("PoisonTarget","StarmobilePoisonTarget")
Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy("PoisonTarget","StarmobilePoisonTarget")

#===============================================================================
# Wicked Torque
#===============================================================================
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.copy("SleepTarget","StarmobileSleepTarget")
Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy("SleepTarget","StarmobileSleepTarget")

