################################################################################
#
# General move scores
#
################################################################################

#===============================================================================
# Choice Items
#===============================================================================
# Considers whether the selected move is a Z-Move/Dynamax move.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::GeneralMoveScore.add(:good_move_for_choice_item,
  proc { |score, move, user, ai, battle|
    next score if move.move.powerMove?
    next score if !ai.trainer.medium_skill?
    next score if !user.has_active_item?([:CHOICEBAND, :CHOICESPECS, :CHOICESCARF]) &&
                  !user.has_active_ability?(:GORILLATACTICS)
    old_score = score
    if move.statusMove? && move.function_code != "UserTargetSwapItems"
      score -= 25
      PBDebug.log_score_change(score - old_score, "don't want to be Choiced into a status move")
      next score
    end
    move_type = move.rough_type
    GameData::Type.each do |type_data|
      score -= 8 if type_data.immunities.include?(move_type)
    end
    if move.accuracy > 0
      score -= (0.4 * (100 - move.accuracy)).to_i
    end
    score -= 10 if move.move.pp <= 5
    PBDebug.log_score_change(score - old_score, "move is less suitable to be Choiced into")
    next score
  }
)

#===============================================================================
# KO'ing targets that have used Destiny Bond or Grudge.
#===============================================================================
# Considers whether the user is immune to Destiny Bond/Grudge effects.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::GeneralMoveAgainstTargetScore.add(:knocking_out_a_destiny_bonder_or_grudger,
  proc { |score, move, user, target, ai, battle|
    if (ai.trainer.has_skill_flag?("HPAware") || ai.trainer.high_skill?) && move.damagingMove? &&
       (target.effects[PBEffects::DestinyBond] || target.effects[PBEffects::Grudge])
      priority = move.rough_priority(user)
      if priority > 0 || (priority == 0 && user.faster_than?(target))
        if move.rough_damage > target.hp * 1.1
          old_score = score
          if target.effects[PBEffects::DestinyBond]
            next score if user.battler.dynamax?
            next score if user.battler.pokemon.immunities.include?(:OHKO)
            score -= 20
            score -= 10 if battle.pbAbleNonActiveCount(user.idxOwnSide) == 0
            PBDebug.log_score_change(score - old_score, "don't want to KO the Destiny Bonding target")
          elsif target.effects[PBEffects::Grudge]
            next score if user.battler.pokemon.immunities.include?(:PPLOSS)
            score -= 15
            score -= 7 if battle.pbAbleNonActiveCount(user.idxOwnSide) == 0
            PBDebug.log_score_change(score - old_score, "don't want to KO the Grudge-using target")
          end
        end
      end
    end
    next score
  }
)

#===============================================================================
# External flinching effects.
#===============================================================================
# Considers whether the target is immune to flinch.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::GeneralMoveAgainstTargetScore.add(:external_flinching_effects,
  proc { |score, move, user, target, ai, battle|
    if ai.trainer.medium_skill? && move.damagingMove? && !move.move.flinchingMove? &&
       user.faster_than?(target) && target.effects[PBEffects::Substitute] == 0
      if user.has_active_item?([:KINGSROCK, :RAZORFANG]) ||
         user.has_active_ability?(:STENCH)
        flinchImmune = (
          target.battler.dynamax? ||
          target.battler.pokemon.immunities.include?(:FLINCH) ||
          (target.has_active_ability?([:INNERFOCUS, :SHIELDDUST]) && !battle.moldBreaker)
        )
        if !flinchImmune
          old_score = score
          score += 8
          score += 5 if move.move.multiHitMove?
          PBDebug.log_score_change(score - old_score, "added chance to cause flinching")
        end
      end
    end
    next score
  }
)


################################################################################
#
# Move effect scores
#
################################################################################

#===============================================================================
# Endeavor
#===============================================================================
# Considers battler's non-boosted HP.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("LowerTargetHPToUserHP",
  proc { |move, user, target, ai, battle|
    next user.battler.real_hp >= target.battler.real_hp
  }
)

#===============================================================================
# Pain Split
#===============================================================================
# Considers battler's non-boosted HP.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("UserTargetAverageHP",
  proc { |score, move, user, target, ai, battle|
    user_hp = user.battler.real_hp
    targ_hp = target.battler.real_hp
    next Battle::AI::MOVE_USELESS_SCORE if user_hp >= targ_hp
    mult = (user_hp + targ_hp) / (2.0 * user_hp)
    score += (10 * mult).to_i if mult >= 1.2
    next score
  }
)

#===============================================================================
# Grass Knot, Low Kick, Heavy Slam, etc.
#===============================================================================
# Considers Raid boss immunity.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("PowerHigherWithTargetWeight",
  proc { |move, user, target, ai, battle|
    next move.move.pbFailsAgainstTarget?(user.battler, target.battler, false)
  }
)

Battle::AI::Handlers::MoveFailureAgainstTargetCheck.copy("PowerHigherWithTargetWeight",
                                                         "PowerHigherWithUserHeavierThanTarget")

#===============================================================================
# Mimic, Sketch
#===============================================================================
# Considers whether or not the last used move was a Z-Move/Dynamax move.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("ReplaceMoveThisBattleWithTargetLastMoveUsed",
  proc { |move, user, target, ai, battle|
    next false if !user.faster_than?(target)
    last_move_data = GameData::Move.try_get(target.battler.lastRegularMoveUsed)
    next true if !last_move_data || last_move_data.powerMove? ||
                 user.battler.pbHasMove?(target.battler.lastRegularMoveUsed) ||
                 move.move.moveBlacklist.include?(last_move_data.function_code) ||
                 last_move_data.type == :SHADOW
    next false
  }
)

#===============================================================================
# Spite
#===============================================================================
# Considers whether the target has boss immunity.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("LowerPPOfTargetLastMoveBy4",
  proc { |move, user, target, ai, battle|
    next true if target.battler.pokemon.immunities.include?(:PPLOSS)
    next !target.check_for_move { |m| m.id == target.battler.lastRegularMoveUsed }
  }
)

#===============================================================================
# Eerie Spell
#===============================================================================
# Considers whether the target has boss immunity.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("LowerPPOfTargetLastMoveBy3",
  proc { |score, move, user, target, ai, battle|
    add_effect = move.get_score_change_for_additional_effect(user, target)
    next score if add_effect == -999
    next score if target.battler.pokemon.immunities.include?(:PPLOSS)
    if user.faster_than?(target)
      last_move = target.battler.pbGetMoveWithID(target.battler.lastRegularMoveUsed)
      if last_move && last_move.total_pp > 0
        score += add_effect
        next score + 20 if last_move.pp <= 3
        next score + 10 if last_move.pp <= 5
        next score - 10 if last_move.pp > 9
      end
    end
    next score
  }
)

#===============================================================================
# Encore
#===============================================================================
# Considers Dynamax immunity and whether the target's last move was a Z-Move.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("DisableTargetUsingDifferentMove",
  proc { |move, user, target, ai, battle|
    next true if target.battler.dynamax?
    next true if defined?(lastMoveUsedIsZMove) && target.battler.lastMoveUsedIsZMove
    next true if target.effects[PBEffects::Encore] > 0
    next true if !target.battler.lastRegularMoveUsed ||
                 !GameData::Move.exists?(target.battler.lastRegularMoveUsed) ||
                 move.move.moveBlacklist.include?(GameData::Move.get(target.battler.lastRegularMoveUsed).function_code)
    next true if target.effects[PBEffects::ShellTrap]
    next true if move.move.pbMoveFailedAromaVeil?(user.battler, target.battler, false)
    will_fail = true
    next !target.check_for_move { |m| m.id == target.battler.lastRegularMoveUsed }
  }
)

#===============================================================================
# Throat Chop
#===============================================================================
# Considers whether the target has boss immunity.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("DisableTargetSoundMoves",
  proc { |score, move, user, target, ai, battle|
    next score if target.effects[PBEffects::ThroatChop] > 1
    next score if !target.check_for_move { |m| m.soundMove? }
    next score if target.battler.pokemon.immunities.include?(:DISABLE)
    add_effect = move.get_score_change_for_additional_effect(user, target)
    next score if add_effect == -999
    score += add_effect
    score += 8
    next score
  }
)

#===============================================================================
# Transform
#===============================================================================
# Considers various immunities.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("TransformUserIntoTarget",
  proc { |move, user, target, ai, battle|
    next true if user.effects[PBEffects::Transform]
    next true if target.effects[PBEffects::Transform] ||
                 target.effects[PBEffects::Illusion]
    next true if user.battler.pokemon.immunities.include?(:TRANSFORM)
    next true if target.battler.pokemon.immunities.include?(:TRANSFORM)
    next true if user.battler.tera? && user.battler.tera_form?
    next true if target.battler.tera? && target.battler.tera_form?
    next true if user.battler.dynamax? && !target.battler.dynamax_able?
    next false
  }
)

#===============================================================================
# Horn Drill, Guillotine, Fissure, Sheer Cold
#===============================================================================
# Considers whether the target is Dynamaxed or has boss immunity.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("OHKO",
  proc { |move, user, target, ai, battle|
    next true if target.level > user.level
    next true if !battle.moldBreaker && target.has_active_ability?(:STURDY)
    next true if target.battler.pokemon.immunities.include?(:OHKO)
    next true if target.battler.dynamax?
    next false
  }
)

#===============================================================================
# Curse
#===============================================================================
# Considers whether the user has boss immunity.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveFailureCheck.add("CurseTargetOrLowerUserSpd1RaiseUserAtkDef1",
  proc { |move, user, ai, battle|
    if user.has_type?(:GHOST) || (move.rough_type == :GHOST && user.has_active_ability?([:LIBERO, :PROTEAN]))
      user_hp = user.battler.real_hp
      total_hp = user.battler.real_totalhp
      next true if user.battler.pokemon.immunities.include?(:SELFKO) && user_hp <= total_hp / 2
      next false
    end
    will_fail = true
    (move.move.statUp.length / 2).times do |i|
      next if !user.battler.pbCanRaiseStatStage?(move.move.statUp[i * 2], user.battler, move.move)
      will_fail = false
      break
    end
    (move.move.statDown.length / 2).times do |i|
      next if !user.battler.pbCanLowerStatStage?(move.move.statDown[i * 2], user.battler, move.move)
      will_fail = false
      break
    end
    next will_fail
  }
)

#===============================================================================
# Steel Beam
#===============================================================================
# Considers whether the user has boss immunity.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveFailureCheck.add("UserLosesHalfOfTotalHP",
  proc { |move, user, ai, battle|
    user_hp = user.battler.real_hp
    total_hp = user.battler.real_totalhp
    next user.battler.pokemon.immunities.include?(:SELFKO) && 
         user.battler.takesIndirectDamage? && user_hp <= total_hp / 2
  }
)

#===============================================================================
# Mind Blown, Self-Destruct, Explosion, Misty Explosion
#===============================================================================
# Considers whether the user has boss immunity.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveFailureCheck.add("UserLosesHalfOfTotalHPExplosive",
  proc { |move, user, ai, battle|
    next true if !battle.moldBreaker && battle.pbCheckGlobalAbility(:DAMP)
    case function_code
    when "UserLosesHalfOfTotalHPExplosive"
      user_hp = user.battler.real_hp
      total_hp = user.battler.real_totalhp
      next true if user.battler.pokemon.immunities.include?(:SELFKO) && 
                   user.battler.takesIndirectDamage? && user_hp <= total_hp / 2
    end
    next user.battler.pokemon.immunities.include?(:SELFKO)
  }
)

#===============================================================================
# Final Gambit, Memento
#===============================================================================
# Considers whether the user has boss immunity.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveFailureCheck.add("UserFaintsFixedDamageUserHP",
  proc { |move, user, ai, battle|
    next user.battler.pokemon.immunities.include?(:SELFKO)
  }
)
Battle::AI::Handlers::MoveFailureCheck.copy("UserFaintsFixedDamageUserHP",
                                            "UserFaintsLowerTargetAtkSpAtk2")


#===============================================================================
# Perish Song
#===============================================================================
# Considers whether the target has boss immunity, or if the user is a Raid boss.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("StartPerishCountsForAllBattlers",
  proc { |move, user, target, ai, battle|
    next true if target.effects[PBEffects::PerishSong] > 0
    next true if user.battler.isRaidBoss? || target.battler.isRaidBoss?
    next true if target.battler.pokemon.immunities.include?(:OHKO)
    next false if !target.ability_active?
    next Battle::AbilityEffects.triggerMoveImmunity(target.ability, user.battler, target.battler,
                                                    move.move, move.rough_type, battle, false)
  }
)

#===============================================================================
# Destiny Bond
#===============================================================================
# Considers whether the user is a Raid boss.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveFailureCheck.add("AttackerFaintsIfUserFaints",
  proc { |move, user, ai, battle|
    next true if user.battler.isRaidBoss?
    next Settings::MECHANICS_GENERATION >= 7 && user.effects[PBEffects::DestinyBondPrevious]
  }
)

#===============================================================================
# Substitute
#===============================================================================
# Considers whether the user is a Raid boss.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveFailureCheck.add("UserMakeSubstitute",
  proc { |move, user, ai, battle|
    next true if user.effects[PBEffects::Substitute] > 0
    next true if user.battler.isRaidBoss?
    next user.hp <= [user.totalhp / 4, 1].max
  }
)

#===============================================================================
# Pluck, Bug Bite
#===============================================================================
# Considers whether the target is a Raid boss.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("UserConsumeTargetBerry",
  proc { |score, move, user, target, ai, battle|
    next score if target.battler.isRaidBoss?
    next score if !target.item || !target.item.is_berry?
    next score if user.battler.unlosableItem?(target.item)
    next score if target.effects[PBEffects::Substitute] > 0
    next score if target.has_active_ability?(:STICKYHOLD) && !battle.moldBreaker
    score += user.get_score_change_for_consuming_item(target.item_id)
    if ai.trainer.medium_skill?
      score += 8 if user.battler.canHeal? && user.hp < user.totalhp / 2 &&
                    user.has_active_ability?(:CHEEKPOUCH)
      score += 5 if !user.battler.belched? && user.has_move_with_function?("FailsIfUserNotConsumedBerry")
      score -= 5 if target.has_active_ability?(:UNBURDEN)
    end
    item_preference = target.wants_item?(target.item_id)
    no_item_preference = target.wants_item?(:NONE)
    score -= (no_item_preference - item_preference) * 3
    next score
  }
)

#===============================================================================
# Incinerate
#===============================================================================
# Considers whether the target is a Raid boss.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("DestroyTargetBerryOrGem",
  proc { |score, move, user, target, ai, battle|
    next score if target.battler.isRaidBoss?
    next score if !target.item || (!target.item.is_berry? &&
                  !(Settings::MECHANICS_GENERATION >= 6 && target.item.is_gem?))
    next score if user.battler.unlosableItem?(target.item)
    next score if target.effects[PBEffects::Substitute] > 0
    next score if target.has_active_ability?(:STICKYHOLD) && !battle.moldBreaker
    next score if !target.item_active?
    item_preference = target.wants_item?(target.item_id)
    no_item_preference = target.wants_item?(:NONE)
    score -= (no_item_preference - item_preference) * 4
    next score
  }
)

#===============================================================================
# Teleport (Gen 7-)
#===============================================================================
# Considers whether the user has boss immunity.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveFailureCheck.add("FleeFromBattle",
  proc { |move, user, ai, battle|
    next true if user.battler.pokemon.immunities.include?(:ESCAPE)
    next !battle.pbCanRun?(user.index) || (user.wild? && user.battler.allAllies.length > 0)
  }
)

#===============================================================================
# Teleport (Gen 8+)
#===============================================================================
# Considers whether the user has boss immunity.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveFailureCheck.add("SwitchOutUserStatusMove",
  proc { |move, user, ai, battle|
    if user.wild?
      next true if user.battler.pokemon.immunities.include?(:ESCAPE)
      next !battle.pbCanRun?(user.index) || user.battler.allAllies.length > 0
    end
    next !battle.pbCanChooseNonActive?(user.index)
  }
)

#===============================================================================
# Dragon Tail, Circle Throw
#===============================================================================
# Considers whether the target is Dynamaxed or has boss immunity.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("SwitchOutTargetDamagingMove",
  proc { |score, move, user, target, ai, battle|
    next score if target.wild?
    next score if !battle.moldBreaker && target.has_active_ability?(:SUCTIONCUPS)
    next score if target.effects[PBEffects::Ingrain]
    next score if target.battler.dynamax?
    next score if target.battler.pokemon.immunities.include?(:ESCAPE)
    can_switch = false
    battle.eachInTeamFromBattlerIndex(target.index) do |_pkmn, i|
      can_switch = battle.pbCanSwitchIn?(target.index, i)
      break if can_switch
    end
    next score if !can_switch
    next score if target.effects[PBEffects::Substitute] > 0
    score -= 20 if target.effects[PBEffects::PerishSong] > 0
    if target.stages.any? { |key, val| val >= 2 }
      score += 15
    elsif target.stages.any? { |key, val| val < 0 }
      score -= 15
    end
    eor_damage = target.rough_end_of_round_damage
    score -= 15 if eor_damage > 0
    score += 15 if eor_damage < 0
    score += 10 if target.pbOwnSide.effects[PBEffects::Spikes] > 0
    score += 10 if target.pbOwnSide.effects[PBEffects::ToxicSpikes] > 0
    score += 10 if target.pbOwnSide.effects[PBEffects::StealthRock]
    next score
  }
)

#===============================================================================
# Fly, Dig, Dive, Bounce, Shadow Force, Phantom Force, Sky Drop
#===============================================================================
# Considers whether the user is a Raid boss.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("TwoTurnAttack",
  proc { |score, move, user, target, ai, battle|
    next score if user.battler.isRaidBoss?
    next score if user.has_active_item?(:POWERHERB)
    next Battle::AI::MOVE_USELESS_SCORE if user.has_active_ability?(:TRUANT)
    next Battle::AI::MOVE_USELESS_SCORE if user.rough_end_of_round_damage >= user.hp
    score -= 10
    if ai.trainer.has_skill_flag?("HPAware")
      score -= 10 if user.hp < user.totalhp / 2
    end
    if ai.trainer.high_skill? && !(user.has_active_ability?(:UNSEENFIST) && move.move.contactMove?)
      has_protect_move = false
      if move.pbTarget(user).num_targets > 1 &&
         (Settings::MECHANICS_GENERATION >= 7 || move.damagingMove?)
        if target.has_move_with_function?("ProtectUserSideFromMultiTargetDamagingMoves")
          has_protect_move = true
        end
      end
      if move.move.canProtectAgainst?
        if target.has_move_with_function?("ProtectUser",
                                          "ProtectUserFromTargetingMovesSpikyShield",
                                          "ProtectUserBanefulBunker")
          has_protect_move = true
        end
        if move.damagingMove?
          if target.has_move_with_function?("ProtectUserFromDamagingMovesKingsShield",
                                            "ProtectUserFromDamagingMovesObstruct")
            has_protect_move = true
          end
        end
        if move.rough_priority(user) > 0
          if target.has_move_with_function?("ProtectUserSideFromPriorityMoves")
            has_protect_move = true
          end
        end
      end
      score -= 20 if has_protect_move
    end
    next score
  }
)

#===============================================================================
# Sky Drop
#===============================================================================
# Considers whether the target is Dynamaxed or has boss immunity.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("TwoTurnAttackInvulnerableInSkyTargetCannotAct",
  proc { |move, user, target, ai, battle|
    next true if !target.opposes?(user)
    next true if target.effects[PBEffects::Substitute] > 0 && !move.move.ignoresSubstitute?(user.battler)
    next true if target.has_type?(:FLYING)
    next true if Settings::MECHANICS_GENERATION >= 6 && target.battler.pbWeight >= 2000
    next true if target.battler.semiInvulnerable? || target.effects[PBEffects::SkyDrop] >= 0
    next true if target.battler.dynamax? || target.battler.isRaidBoss?
    next false
  }
)