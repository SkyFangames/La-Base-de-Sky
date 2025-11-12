#===============================================================================
# Damage calculation refactoring.
#===============================================================================
# Breaks up and refactors code related to damage calculation to be more easily 
# edited by other plugins to add their own effects. 
#===============================================================================
class Battle::Move
  #-----------------------------------------------------------------------------
  # Calculates damage multipliers from global abilities.
  #-----------------------------------------------------------------------------
  def pbCalcDamageMults_Global(user, target, numTargets, type, baseDmg, multipliers)
    if (@battle.pbCheckGlobalAbility(:DARKAURA) && type == :DARK) ||
       (@battle.pbCheckGlobalAbility(:FAIRYAURA) && type == :FAIRY)
      if @battle.pbCheckGlobalAbility(:AURABREAK)
        multipliers[:power_multiplier] *= 3 / 4.0
      else
        multipliers[:power_multiplier] *= 4 / 3.0
      end
    end
    [:TABLETSOFRUIN, :SWORDOFRUIN, :VESSELOFRUIN, :BEADSOFRUIN].each_with_index do |ability, i|
      next if !@battle.pbCheckGlobalAbility(ability)
      category = (i < 2) ? physicalMove? : specialMove?
      category = !category if i.odd? && @battle.field.effects[PBEffects::WonderRoom] > 0
      if i.even? && !user.hasActiveAbility?(ability)
        multipliers[:attack_multiplier] *= 0.75 if category
      elsif i.odd? && !target.hasActiveAbility?(ability)
        multipliers[:defense_multiplier] *= 0.75 if category
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Calculates damage multipliers from abilities.
  #-----------------------------------------------------------------------------
  def pbCalcDamageMults_Abilities(user, target, numTargets, type, baseDmg, multipliers)
    if user.abilityActive?
      Battle::AbilityEffects.triggerDamageCalcFromUser(
        user.ability, user, target, self, multipliers, baseDmg, type
      )
    end
    if !@battle.moldBreaker
      user.allAllies.each do |b|
        next if !b.abilityActive?
        Battle::AbilityEffects.triggerDamageCalcFromAlly(
          b.ability, user, target, self, multipliers, baseDmg, type
        )
      end
      if target.abilityActive?
        Battle::AbilityEffects.triggerDamageCalcFromTarget(
          target.ability, user, target, self, multipliers, baseDmg, type
        )
      end
    end
    if target.abilityActive?
      Battle::AbilityEffects.triggerDamageCalcFromTargetNonIgnorable(
        target.ability, user, target, self, multipliers, baseDmg, type
      )
    end
    if !@battle.moldBreaker
      target.allAllies.each do |b|
        next if !b.abilityActive?
        Battle::AbilityEffects.triggerDamageCalcFromTargetAlly(
          b.ability, user, target, self, multipliers, baseDmg, type
        )
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Calculates damage multipliers from items.
  #-----------------------------------------------------------------------------
  def pbCalcDamageMults_Items(user, target, numTargets, type, baseDmg, multipliers)
    if user.itemActive?
      Battle::ItemEffects.triggerDamageCalcFromUser(
        user.item, user, target, self, multipliers, baseDmg, type
      )
    end
    if target.itemActive?
      Battle::ItemEffects.triggerDamageCalcFromTarget(
        target.item, user, target, self, multipliers, baseDmg, type
      )
    end
  end
  
  #-----------------------------------------------------------------------------
  # Calculates damage multipliers from other sources.
  #-----------------------------------------------------------------------------
  def pbCalcDamageMults_Other(user, target, numTargets, type, baseDmg, multipliers)
    if user.effects[PBEffects::MeFirst]
      multipliers[:power_multiplier] *= 1.5
    end
    if user.effects[PBEffects::HelpingHand] && !self.is_a?(Battle::Move::Confusion)
      multipliers[:power_multiplier] *= 1.5
    end
    if user.effects[PBEffects::Charge] > 0 && type == :ELECTRIC
      multipliers[:power_multiplier] *= 2
    end
  end
  
  #-----------------------------------------------------------------------------
  # Calculates damage multipliers from field effects and terrain.
  #-----------------------------------------------------------------------------
  def pbCalcDamageMults_Field(user, target, numTargets, type, baseDmg, multipliers)
    # Mud Sport
    if type == :ELECTRIC
      if @battle.allBattlers.any? { |b| b.effects[PBEffects::MudSport] }
        multipliers[:power_multiplier] /= 3
      end
      if @battle.field.effects[PBEffects::MudSportField] > 0
        multipliers[:power_multiplier] /= 3
      end
    end
    # Water Sport
    if type == :FIRE
      if @battle.allBattlers.any? { |b| b.effects[PBEffects::WaterSport] }
        multipliers[:power_multiplier] /= 3
      end
      if @battle.field.effects[PBEffects::WaterSportField] > 0
        multipliers[:power_multiplier] /= 3
      end
    end
    # Terrain moves
    terrain_multiplier = (Settings::MECHANICS_GENERATION >= 8) ? 1.3 : 1.5
    case @battle.field.terrain
    when :Electric
      if type == :ELECTRIC
        multipliers[:power_multiplier] *= terrain_multiplier if user.affectedByTerrain?
      elsif @function_code == "IncreasePowerInElectricTerrain"
        multipliers[:power_multiplier] *= 1.5 if user.affectedByTerrain?
      end
    when :Grassy
      multipliers[:power_multiplier] *= terrain_multiplier if type == :GRASS && user.affectedByTerrain?
    when :Psychic
      multipliers[:power_multiplier] *= terrain_multiplier if type == :PSYCHIC && user.affectedByTerrain?
    when :Misty
      multipliers[:power_multiplier] /= 2 if type == :DRAGON && target.affectedByTerrain?
    end
  end
  
  #-----------------------------------------------------------------------------
  # Calculates damage multipliers from badges.
  #-----------------------------------------------------------------------------
  def pbCalcDamageMults_Badges(user, target, numTargets, type, baseDmg, multipliers)
    if @battle.internalBattle
      if user.pbOwnedByPlayer?
        if physicalMove? && @battle.pbPlayer.badge_count >= Settings::NUM_BADGES_BOOST_ATTACK
          multipliers[:attack_multiplier] *= 1.1
        elsif specialMove? && @battle.pbPlayer.badge_count >= Settings::NUM_BADGES_BOOST_SPATK
          multipliers[:attack_multiplier] *= 1.1
        end
      end
      if target.pbOwnedByPlayer?
        if physicalMove? && @battle.pbPlayer.badge_count >= Settings::NUM_BADGES_BOOST_DEFENSE
          multipliers[:defense_multiplier] *= 1.1
        elsif specialMove? && @battle.pbPlayer.badge_count >= Settings::NUM_BADGES_BOOST_SPDEF
          multipliers[:defense_multiplier] *= 1.1
        end
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Calculates damage multipliers from weather.
  #-----------------------------------------------------------------------------
  def pbCalcDamageMults_Weather(user, target, numTargets, type, baseDmg, multipliers)
    case user.effectiveWeather
    when :Sun, :HarshSun
      case type
      when :FIRE
        multipliers[:final_damage_multiplier] *= 1.5
      when :WATER
        if @function_code == "IncreasePowerInSunWeather"
          multipliers[:final_damage_multiplier] *= 1.5
        else
          multipliers[:final_damage_multiplier] /= 2
        end
      end
    when :Rain, :HeavyRain
      case type
      when :FIRE
        multipliers[:final_damage_multiplier] /= 2
      when :WATER
        multipliers[:final_damage_multiplier] *= 1.5
      end
    when :Sandstorm
      if target.pbHasType?(:ROCK) && specialMove? && @function_code != "UseTargetDefenseInsteadOfTargetSpDef"
        multipliers[:defense_multiplier] *= 1.5
      end
    when :Hail
      if defined?(Settings::HAIL_WEATHER_TYPE) && Settings::HAIL_WEATHER_TYPE > 0 && 
         target.pbHasType?(:ICE) && (physicalMove? || @function_code == "UseTargetDefenseInsteadOfTargetSpDef")
        multipliers[:defense_multiplier] *= 1.5
      end
    when :ShadowSky
      multipliers[:final_damage_multiplier] *= 1.5 if type == :SHADOW
    end
  end
  
  #-----------------------------------------------------------------------------
  # Calculates damage multipliers from random effects.
  #-----------------------------------------------------------------------------
  def pbCalcDamageMults_Random(user, target, numTargets, type, baseDmg, multipliers)
    # Critical hits
    if target.damageState.critical
      if Settings::NEW_CRITICAL_HIT_RATE_MECHANICS
        multipliers[:final_damage_multiplier] *= 1.5
      else
        multipliers[:final_damage_multiplier] *= 2
      end
    end
    # Random variance
    if !self.is_a?(Battle::Move::Confusion)
      random = 85 + @battle.pbRandom(16)
      multipliers[:final_damage_multiplier] *= random / 100.0
    end
  end
  
  #-----------------------------------------------------------------------------
  # Calculates damage multipliers based on typing.
  #-----------------------------------------------------------------------------
  def pbCalcDamageMults_Type(user, target, numTargets, type, baseDmg, multipliers)
    # STAB
    if type && user.pbHasType?(type)
      if user.hasActiveAbility?(:ADAPTABILITY)
        multipliers[:final_damage_multiplier] *= 2
      else
        multipliers[:final_damage_multiplier] *= 1.5
      end
    end
    # Type effectiveness
    multipliers[:final_damage_multiplier] *= target.damageState.typeMod
  end
  
  #-----------------------------------------------------------------------------
  # Calculates damage multipliers from status conditions.
  #-----------------------------------------------------------------------------
  def pbCalcDamageMults_Status(user, target, numTargets, type, baseDmg, multipliers)
    if user.status == :BURN && physicalMove? && damageReducedByBurn? &&
       !user.hasActiveAbility?(:GUTS)
      multipliers[:final_damage_multiplier] /= 2
    end
    if user.status == :FROSTBITE && specialMove?
      multipliers[:final_damage_multiplier] /= 2
    end
    if target.status == :DROWSY
      multipliers[:final_damage_multiplier] *= 4 / 3.0
    end
  end
  
  #-----------------------------------------------------------------------------
  # Calculates damage multipliers from Reflect/Light Screen/etc.
  #-----------------------------------------------------------------------------
  def pbCalcDamageMults_Screens(user, target, numTargets, type, baseDmg, multipliers)
    if !ignoresReflect? && !target.damageState.critical &&
       !user.hasActiveAbility?(:INFILTRATOR)
      if target.pbOwnSide.effects[PBEffects::AuroraVeil] > 0
        if @battle.pbSideBattlerCount(target) > 1
          multipliers[:final_damage_multiplier] *= 2 / 3.0
        else
          multipliers[:final_damage_multiplier] /= 2
        end
      elsif target.pbOwnSide.effects[PBEffects::Reflect] > 0 && physicalMove?
        if @battle.pbSideBattlerCount(target) > 1
          multipliers[:final_damage_multiplier] *= 2 / 3.0
        else
          multipliers[:final_damage_multiplier] /= 2
        end
      elsif target.pbOwnSide.effects[PBEffects::LightScreen] > 0 && specialMove?
        if @battle.pbSideBattlerCount(target) > 1
          multipliers[:final_damage_multiplier] *= 2 / 3.0
        else
          multipliers[:final_damage_multiplier] /= 2
        end
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Total damage multiplier calculation.
  #-----------------------------------------------------------------------------
  def pbCalcDamageMultipliers(user, target, numTargets, type, baseDmg, multipliers)
    args = [user, target, numTargets, type, baseDmg]
    pbCalcDamageMults_Global(*args, multipliers)
    pbCalcDamageMults_Abilities(*args, multipliers)
    pbCalcDamageMults_Items(*args, multipliers)
    if user.effects[PBEffects::ParentalBond] == 1
      multipliers[:power_multiplier] /= (Settings::MECHANICS_GENERATION >= 7) ? 4 : 2
    end
    pbCalcDamageMults_Other(*args, multipliers)
    pbCalcDamageMults_Field(*args, multipliers)
    pbCalcDamageMults_Badges(*args, multipliers)
    multipliers[:final_damage_multiplier] *= 0.75 if numTargets > 1
    pbCalcDamageMults_Weather(*args, multipliers)
    pbCalcDamageMults_Random(*args, multipliers)
    pbCalcDamageMults_Type(*args, multipliers)
    pbCalcDamageMults_Status(*args, multipliers)
    pbCalcDamageMults_Screens(*args, multipliers)
    if target.effects[PBEffects::Minimize] && tramplesMinimize?
      multipliers[:final_damage_multiplier] *= 2
    end
    if defined?(PBEffects::GlaiveRush) && target.effects[PBEffects::GlaiveRush] > 0
      multipliers[:final_damage_multiplier] *= 2 
    end
    multipliers[:power_multiplier] = pbBaseDamageMultiplier(multipliers[:power_multiplier], user, target)
    multipliers[:final_damage_multiplier] = pbModifyDamage(multipliers[:final_damage_multiplier], user, target)
  end
  
  #-----------------------------------------------------------------------------
  # Damage calculation.
  #-----------------------------------------------------------------------------
  def pbCalcDamage(user, target, numTargets = 1)
    return if statusMove?
    if target.damageState.disguise || target.damageState.iceFace
      target.damageState.calcDamage = 1
      return
    end
    max_stage = Battle::Battler::STAT_STAGE_MAXIMUM
    stageMul = Battle::Battler::STAT_STAGE_MULTIPLIERS
    stageDiv = Battle::Battler::STAT_STAGE_DIVISORS
    type = @calcType
    target.damageState.critical = pbIsCritical?(user, target)
    baseDmg = pbBaseDamage(@power, user, target)
    baseDmg = pbBaseDamageTera(baseDmg, user, type)
    atk, atkStage = pbGetAttackStats(user, target)
    if !target.hasActiveAbility?(:UNAWARE) || @battle.moldBreaker
      atkStage = max_stage if target.damageState.critical && atkStage < max_stage
      atk = (atk.to_f * stageMul[atkStage] / stageDiv[atkStage]).floor
    end
    defense, defStage = pbGetDefenseStats(user, target)
    if !user.hasActiveAbility?(:UNAWARE)
      defStage = max_stage if target.damageState.critical && defStage > max_stage
      defense = (defense.to_f * stageMul[defStage] / stageDiv[defStage]).floor
    end
    multipliers = {
      :power_multiplier        => 1.0,
      :attack_multiplier       => 1.0,
      :defense_multiplier      => 1.0,
      :final_damage_multiplier => 1.0
    }
    pbCalcDamageMultipliers(user, target, numTargets, type, baseDmg, multipliers)
    baseDmg = [(baseDmg * multipliers[:power_multiplier]).round, 1].max
    atk     = [(atk     * multipliers[:attack_multiplier]).round, 1].max
    defense = [(defense * multipliers[:defense_multiplier]).round, 1].max
    damage  = ((((2.0 * user.level / 5) + 2).floor * baseDmg * atk / defense).floor / 50).floor + 2
    damage  = [(damage * multipliers[:final_damage_multiplier]).round, 1].max
    target.damageState.calcDamage = damage
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to set HP thresholds that a battler's HP cannot fall below.
  #-----------------------------------------------------------------------------
  alias dx_pbReduceDamage pbReduceDamage
  def pbReduceDamage(user, target)
    dx_pbReduceDamage(user, target)
    return if target.damageState.disguise || target.damageState.iceFace
    damage = target.damageState.hpLost
    if damage > 1
      target.stopBoostedHPScaling = true
      return if target.damageState.substitute
      return if !target.damageThreshold
      thresh = (target.totalhp * (target.damageThreshold / 100.0)).round
      thresh = 1 if thresh < 1
      if target.hp > thresh
        if damage > target.hp - thresh
          new_damage = target.hp - thresh
        end
      else 
        new_damage = 0
      end
      return if !new_damage
      if damage > new_damage && new_damage >= 0
        target.damageState.hpLost       = new_damage
        target.damageState.totalHPLost -= damage
        target.damageState.totalHPLost += new_damage
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Allows the "HighCriticalHitRate" flag to add more than 1 crit stage.
  #-----------------------------------------------------------------------------
  def critical_hit_bonus
    @flags.each do |flag|
      next if !flag.include?("HighCriticalHitRate")
      stage = flag.split("_")[1]
      return (stage) ? stage.to_i : 1
    end
    return 0
  end
  
  #-----------------------------------------------------------------------------
  # Additional sources of critical hit modifications.
  #-----------------------------------------------------------------------------
  def crit_stage_bonuses(user)
    bonus = 0
    bonus += critical_hit_bonus
    bonus += user.effects[PBEffects::FocusEnergy]
    bonus += 1 if @id == :SPACIALREND && user.isSpecies?(:PALKIA) && user.form == 1
    bonus += 1 if user.inHyperMode? && @type == :SHADOW
    return bonus
  end
  
  #-----------------------------------------------------------------------------
  # Edited for critical hit immunity and new crit boosters.
  #-----------------------------------------------------------------------------
  def pbIsCritical?(user, target)
    return false if target.pokemon.immunities.include?(:CRITICALHIT)
    return false if target.pbOwnSide.effects[PBEffects::LuckyChant] > 0
    c = 0
    if c >= 0 && user.abilityActive?
      c = Battle::AbilityEffects.triggerCriticalCalcFromUser(user.ability, user, target, c)
    end
    if c >= 0 && target.abilityActive? && !@battle.moldBreaker
      c = Battle::AbilityEffects.triggerCriticalCalcFromTarget(target.ability, user, target, c)
    end
    if c >= 0 && user.itemActive?
      c = Battle::ItemEffects.triggerCriticalCalcFromUser(user.item, user, target, c)
    end
    if c >= 0 && target.itemActive?
      c = Battle::ItemEffects.triggerCriticalCalcFromTarget(target.item, user, target, c)
    end
    return false if c < 0
    case pbCritialOverride(user, target)
    when 1  then return true
    when -1 then return false
    end
    return true if c > 50
    return true if user.effects[PBEffects::LaserFocus] > 0
    c += crit_stage_bonuses(user)
    ratios = CRITICAL_HIT_RATIOS
    c = ratios.length - 1 if c >= ratios.length
    return true if ratios[c] == 1
    r = @battle.pbRandom(ratios[c])
    return true if r == 0
    if r == 1 && Settings::AFFECTION_EFFECTS && @battle.internalBattle &&
       user.pbOwnedByPlayer? && user.affection_level == 5 && !target.mega?
      target.damageState.affection_critical = true
      return true
    end
    return false
  end
end


#===============================================================================
# AI damage calculation refactoring.
#===============================================================================
class Battle::AI::AIMove
  #-----------------------------------------------------------------------------
  # Calculates the user's attack stat.
  #-----------------------------------------------------------------------------
  def calc_user_attack(user, target, is_critical, max_stage, stage_mul, stage_div)
    if ["CategoryDependsOnHigherDamagePoisonTarget",
        "CategoryDependsOnHigherDamageIgnoreTargetAbility",
        "CategoryDependsOnHigherDamageTera",
        "TerapagosCategoryDependsOnHigherDamage"].include?(function_code)
      @move.pbOnStartUse(user.battler, [target.battler])
    end
    atk, atk_stage = @move.pbGetAttackStats(user.battler, target.battler)
    if !target.has_active_ability?(:UNAWARE) || @ai.battle.moldBreaker
      atk_stage = max_stage if is_critical && atk_stage < max_stage
      atk = (atk.to_f * stage_mul[atk_stage] / stage_div[atk_stage]).floor
    end
    return atk
  end
  
  #-----------------------------------------------------------------------------
  # Calculates the target's defense stat.
  #-----------------------------------------------------------------------------
  def calc_target_defense(user, target, is_critical, max_stage, stage_mul, stage_div)
    defense, def_stage = @move.pbGetDefenseStats(user.battler, target.battler)
    if !user.has_active_ability?(:UNAWARE) || @ai.battle.moldBreaker
      def_stage = max_stage if is_critical && def_stage > max_stage
      defense = (defense.to_f * stage_mul[def_stage] / stage_div[def_stage]).floor
    end
    return defense
  end
  
  #-----------------------------------------------------------------------------
  # Calculates damage multipliers from global abilities.
  #-----------------------------------------------------------------------------
  def calc_global_ability_mults(user, target, base_dmg, calc_type, is_critical, multipliers)
    if @ai.trainer.medium_skill? &&
       ((@ai.battle.pbCheckGlobalAbility(:DARKAURA) && calc_type == :DARK) ||
        (@ai.battle.pbCheckGlobalAbility(:FAIRYAURA) && calc_type == :FAIRY))
      if @ai.battle.pbCheckGlobalAbility(:AURABREAK)
        multipliers[:power_multiplier] *= 3 / 4.0
      else
        multipliers[:power_multiplier] *= 4 / 3.0
      end
    end
    if @ai.trainer.medium_skill?
      [:TABLETSOFRUIN, :SWORDOFRUIN, :VESSELOFRUIN, :BEADSOFRUIN].each_with_index do |ability, i|
        next if !@ai.battle.pbCheckGlobalAbility(ability)
        category = (i < 2) ? physicalMove?(calc_type) : specialMove?(calc_type)
        category = !category if i.odd? && @ai.battle.field.effects[PBEffects::WonderRoom] > 0
        mult = (i.even?) ? multipliers[:attack_multiplier] : multipliers[:defense_multiplier]
        mult *= 0.75 if !user.has_active_ability?(ability) && category
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Calculates damage multipliers from abilities.
  #-----------------------------------------------------------------------------
  def calc_ability_mults(user, target, base_dmg, calc_type, is_critical, multipliers)
    if user.ability_active?
      case user.ability_id
      when :AERILATE, :GALVANIZE, :PIXILATE, :REFRIGERATE
        multipliers[:power_multiplier] *= 1.2 if type == :NORMAL   # NOTE: Not calc_type.
      when :ANALYTIC
        if rough_priority(user) <= 0
          user_faster = false
          @ai.each_battler do |b, i|
            user_faster = (i != user.index && user.faster_than?(b))
            break if user_faster
          end
          multipliers[:power_multiplier] *= 1.3 if !user_faster
        end
      when :NEUROFORCE
        if Effectiveness.super_effective_type?(calc_type, *target.pbTypes(true))
          multipliers[:final_damage_multiplier] *= 1.25
        end
      when :NORMALIZE
        multipliers[:power_multiplier] *= 1.2 if Settings::MECHANICS_GENERATION >= 7
      when :SNIPER
        multipliers[:final_damage_multiplier] *= 1.5 if is_critical
      when :STAKEOUT
        # NOTE: Can't predict whether the target will switch out this round.
      when :TINTEDLENS
        if Effectiveness.resistant_type?(calc_type, *target.pbTypes(true))
          multipliers[:final_damage_multiplier] *= 2
        end
      else
        Battle::AbilityEffects.triggerDamageCalcFromUser(
          user.ability, user.battler, target.battler, @move, multipliers, base_dmg, calc_type
        )
      end
    end
    if !@ai.battle.moldBreaker
      user.battler.allAllies.each do |b|
        next if !b.abilityActive?
        Battle::AbilityEffects.triggerDamageCalcFromAlly(
          b.ability, user.battler, target.battler, @move, multipliers, base_dmg, calc_type
        )
      end
      if target.ability_active?
        case target.ability_id
        when :FILTER, :SOLIDROCK
          if Effectiveness.super_effective_type?(calc_type, *target.pbTypes(true))
            multipliers[:final_damage_multiplier] *= 0.75
          end
        else
          Battle::AbilityEffects.triggerDamageCalcFromTarget(
            target.ability, user.battler, target.battler, @move, multipliers, base_dmg, calc_type
          )
        end
      end
    end
    if target.ability_active?
      Battle::AbilityEffects.triggerDamageCalcFromTargetNonIgnorable(
        target.ability, user.battler, target.battler, @move, multipliers, base_dmg, calc_type
      )
    end
    if !@ai.battle.moldBreaker
      target.battler.allAllies.each do |b|
        next if !b.abilityActive?
        Battle::AbilityEffects.triggerDamageCalcFromTargetAlly(
          b.ability, user.battler, target.battler, @move, multipliers, base_dmg, calc_type
        )
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Calculates damage multipliers from items.
  #-----------------------------------------------------------------------------
  def calc_item_mults(user, target, base_dmg, calc_type, is_critical, multipliers)
    if user.item_active?
      case user.item_id
      when :EXPERTBELT
        if Effectiveness.super_effective_type?(calc_type, *target.pbTypes(true))
          multipliers[:final_damage_multiplier] *= 1.2
        end
      when :LIFEORB
        multipliers[:final_damage_multiplier] *= 1.3
      else
        Battle::ItemEffects.triggerDamageCalcFromUser(
          user.item, user.battler, target.battler, @move, multipliers, base_dmg, calc_type
        )
        user.effects[PBEffects::GemConsumed] = nil   # Untrigger consuming of Gems
      end
    end
    if target.item_active? && target.item && !target.item.is_berry?
      Battle::ItemEffects.triggerDamageCalcFromTarget(
        target.item, user.battler, target.battler, @move, multipliers, base_dmg, calc_type
      )
    end
  end
  
  #-----------------------------------------------------------------------------
  # Calculates damage multipliers from other sources.
  #-----------------------------------------------------------------------------
  def calc_other_mults(user, target, base_dmg, calc_type, is_critical, multipliers)
    # Me First - n/a because can't predict the move Me First will use
    # Helping Hand - n/a
    # Charge
    if @ai.trainer.medium_skill? &&
       user.effects[PBEffects::Charge] > 0 && calc_type == :ELECTRIC
      multipliers[:power_multiplier] *= 2
    end
  end
  
  #-----------------------------------------------------------------------------
  # Calculates damage multipliers from field effects and terrain.
  #-----------------------------------------------------------------------------
  def calc_field_mults(user, target, base_dmg, calc_type, is_critical, multipliers)
    if @ai.trainer.medium_skill?
      case calc_type
      when :ELECTRIC
        if @ai.battle.allBattlers.any? { |b| b.effects[PBEffects::MudSport] }
          multipliers[:power_multiplier] /= 3
        end
        if @ai.battle.field.effects[PBEffects::MudSportField] > 0
          multipliers[:power_multiplier] /= 3
        end
      when :FIRE
        if @ai.battle.allBattlers.any? { |b| b.effects[PBEffects::WaterSport] }
          multipliers[:power_multiplier] /= 3
        end
        if @ai.battle.field.effects[PBEffects::WaterSportField] > 0
          multipliers[:power_multiplier] /= 3
        end
      end
    end
    # Terrain moves
    if @ai.trainer.medium_skill?
      terrain_multiplier = (Settings::MECHANICS_GENERATION >= 8) ? 1.3 : 1.5
      case @ai.battle.field.terrain
      when :Electric
        if calc_type == :ELECTRIC
          multipliers[:power_multiplier] *= terrain_multiplier if user.battler.affectedByTerrain?
        elsif function_code == "IncreasePowerInElectricTerrain"
          multipliers[:power_multiplier] *= 1.5 if user_battler.affectedByTerrain?
        end
      when :Grassy
        multipliers[:power_multiplier] *= terrain_multiplier if calc_type == :GRASS && user.battler.affectedByTerrain?
      when :Psychic
        multipliers[:power_multiplier] *= terrain_multiplier if calc_type == :PSYCHIC && user.battler.affectedByTerrain?
      when :Misty
        multipliers[:power_multiplier] /= 2 if calc_type == :DRAGON && target.battler.affectedByTerrain?
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Calculates damage multipliers from badges.
  #-----------------------------------------------------------------------------
  def calc_badge_mults(user, target, base_dmg, calc_type, is_critical, multipliers)
    if @ai.trainer.high_skill? && @ai.battle.internalBattle && target.battler.pbOwnedByPlayer?
      if physicalMove?(calc_type) && @ai.battle.pbPlayer.badge_count >= Settings::NUM_BADGES_BOOST_DEFENSE
        multipliers[:defense_multiplier] *= 1.1
      elsif specialMove?(calc_type) && @ai.battle.pbPlayer.badge_count >= Settings::NUM_BADGES_BOOST_SPDEF
        multipliers[:defense_multiplier] *= 1.1
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Calculates damage multipliers from weather.
  #-----------------------------------------------------------------------------
  def calc_weather_mults(user, target, base_dmg, calc_type, is_critical, multipliers)
    if @ai.trainer.medium_skill?
      case user.battler.effectiveWeather
      when :Sun, :HarshSun
        case calc_type
        when :FIRE
          multipliers[:final_damage_multiplier] *= 1.5
        when :WATER
          if function_code == "IncreasePowerInSunWeather"
            multipliers[:final_damage_multiplier] *= 1.5
          else
            multipliers[:final_damage_multiplier] /= 2
          end
        end
      when :Rain, :HeavyRain
        case calc_type
        when :FIRE
          multipliers[:final_damage_multiplier] /= 2
        when :WATER
          multipliers[:final_damage_multiplier] *= 1.5
        end
      when :Sandstorm
        if target.has_type?(:ROCK) && specialMove?(calc_type) &&
           function_code != "UseTargetDefenseInsteadOfTargetSpDef"
          multipliers[:defense_multiplier] *= 1.5
        end
      when :Hail
        if PluginManager.installed?("Generation 9 Pack") && 
           Settings::HAIL_WEATHER_TYPE > 0 && target.pbHasType?(:ICE) &&
           (physicalMove?(calc_type) || function_code == "UseTargetDefenseInsteadOfTargetSpDef")
          multipliers[:defense_multiplier] *= 1.5
        end
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Calculates damage multipliers from random effects.
  #-----------------------------------------------------------------------------
  def calc_random_mults(user, target, base_dmg, calc_type, is_critical, multipliers)
    # Critical hits
    if is_critical
      if Settings::NEW_CRITICAL_HIT_RATE_MECHANICS
        multipliers[:final_damage_multiplier] *= 1.5
      else
        multipliers[:final_damage_multiplier] *= 2
      end
    end
    # Random variance - n/a
  end
  
  #-----------------------------------------------------------------------------
  # Calculates damage multipliers based on typing.
  #-----------------------------------------------------------------------------
  def calc_type_mults(user, target, base_dmg, calc_type, is_critical, multipliers)
    if calc_type && user.has_type?(calc_type)
      if user.has_active_ability?(:ADAPTABILITY)
        multipliers[:final_damage_multiplier] *= 2
      else
        multipliers[:final_damage_multiplier] *= 1.5
      end
    end
    # Type effectiveness
    typemod = target.effectiveness_of_type_against_battler(calc_type, user, @move)
    multipliers[:final_damage_multiplier] *= typemod
  end
  
  #-----------------------------------------------------------------------------
  # Calculates damage multipliers from status conditions.
  #-----------------------------------------------------------------------------
  def calc_status_condition_mults(user, target, base_dmg, calc_type, is_critical, multipliers)
    if @ai.trainer.high_skill? 
      case user.status
      when :BURN
        if physicalMove?(calc_type) && @move.damageReducedByBurn? && !user.has_active_ability?(:GUTS)
          multipliers[:final_damage_multiplier] /= 2
        end
      when :FROSTBITE
        if specialMove?(calc_type)
          multipliers[:final_damage_multiplier] /= 2
        end
      end
      case target.status
      when :DROWSY
        multipliers[:final_damage_multiplier] *= 4 / 3.0
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Calculates damage multipliers from Reflect/Light Screen/etc.
  #-----------------------------------------------------------------------------
  def calc_screen_mults(user, target, base_dmg, calc_type, is_critical, multipliers)
    if @ai.trainer.medium_skill? && !@move.ignoresReflect? && !is_critical &&
       !user.has_active_ability?(:INFILTRATOR)
      if target.pbOwnSide.effects[PBEffects::AuroraVeil] > 0
        if @ai.battle.pbSideBattlerCount(target.battler) > 1
          multipliers[:final_damage_multiplier] *= 2 / 3.0
        else
          multipliers[:final_damage_multiplier] /= 2
        end
      elsif target.pbOwnSide.effects[PBEffects::Reflect] > 0 && physicalMove?(calc_type)
        if @ai.battle.pbSideBattlerCount(target.battler) > 1
          multipliers[:final_damage_multiplier] *= 2 / 3.0
        else
          multipliers[:final_damage_multiplier] /= 2
        end
      elsif target.pbOwnSide.effects[PBEffects::LightScreen] > 0 && specialMove?(calc_type)
        if @ai.battle.pbSideBattlerCount(target.battler) > 1
          multipliers[:final_damage_multiplier] *= 2 / 3.0
        else
          multipliers[:final_damage_multiplier] /= 2
        end
      end
    end
  end

  #-----------------------------------------------------------------------------
  # Full damage calculation.
  #-----------------------------------------------------------------------------
  def rough_damage
    base_dmg = base_power
    return base_dmg if @move.is_a?(Battle::Move::FixedDamageMove)
    max_stage = Battle::Battler::STAT_STAGE_MAXIMUM
    stage_mul = Battle::Battler::STAT_STAGE_MULTIPLIERS
    stage_div = Battle::Battler::STAT_STAGE_DIVISORS
    user = @ai.user
    target = @ai.target
    calc_type = rough_type
    crit_stage = rough_critical_hit_stage
    is_critical = crit_stage >= Battle::Move::CRITICAL_HIT_RATIOS.length ||
                  Battle::Move::CRITICAL_HIT_RATIOS[crit_stage] <= 2
    args = [user, target, is_critical, max_stage, stage_mul, stage_div]
    ##### Calculate attack and defense stats #####
    atk = calc_user_attack(*args)
    defense = calc_target_defense(*args)
    ##### Calculate all multiplier effects #####
    args = [user, target, base_dmg, calc_type, is_critical]
    multipliers = {
      :power_multiplier        => 1.0,
      :attack_multiplier       => 1.0,
      :defense_multiplier      => 1.0,
      :final_damage_multiplier => 1.0
    }
    ##### Abilities and Items #####
    calc_global_ability_mults(*args, multipliers)
    calc_ability_mults(*args, multipliers)
    calc_item_mults(*args, multipliers)
    if user.has_active_ability?(:PARENTALBOND)
      multipliers[:power_multiplier] *= (Settings::MECHANICS_GENERATION >= 7) ? 1.25 : 1.5
    end
    ##### Field effects, Terrain, Badge boosts and miscellaneous effects #####
    calc_other_mults(*args, multipliers)
    calc_field_mults(*args, multipliers)
    calc_badge_mults(*args, multipliers)
    if @ai.trainer.high_skill? && targets_multiple_battlers?
      multipliers[:final_damage_multiplier] *= 0.75
    end
    ##### Weather, critical hits, STAB, type effectiveness, and statuses #####
    calc_weather_mults(*args, multipliers)
    calc_random_mults(*args, multipliers)
    calc_type_mults(*args, multipliers)
    calc_status_condition_mults(*args, multipliers)
    ##### Reflect/Light Screen/Aurora Veil, Minimize, and Glaive Rush #####
    calc_screen_mults(*args, multipliers)
    if @ai.trainer.medium_skill?
      if target.effects[PBEffects::Minimize] && @move.tramplesMinimize?
        multipliers[:final_damage_multiplier] *= 2
      end
      if defined?(PBEffects::GlaiveRush) && target.effects[PBEffects::GlaiveRush] > 0
        multipliers[:final_damage_multiplier] *= 2
      end
    end
    ##### Main damage calculation #####
    base_dmg = [(base_dmg * multipliers[:power_multiplier]).round, 1].max
    atk      = [(atk      * multipliers[:attack_multiplier]).round, 1].max
    defense  = [(defense  * multipliers[:defense_multiplier]).round, 1].max
    damage   = ((((2.0 * user.level / 5) + 2).floor * base_dmg * atk / defense).floor / 50).floor + 2
    damage   = [(damage * multipliers[:final_damage_multiplier]).round, 1].max
    ret = damage.floor
    ret = target.hp - 1 if @move.nonLethal?(user.battler, target.battler) && ret >= target.hp
    return ret
  end
  
  #-----------------------------------------------------------------------------
  # Full critical hit chance calculation.
  #-----------------------------------------------------------------------------
  def rough_critical_hit_stage
    user = @ai.user
    user_battler = user.battler
    target = @ai.target
    target_battler = target.battler
    return -1 if target_battler.pokemon.immunities.include?(:CRITICALHIT)
    return -1 if target_battler.pbOwnSide.effects[PBEffects::LuckyChant] > 0
    crit_stage = 0
    if user.ability_active?
      crit_stage = Battle::AbilityEffects.triggerCriticalCalcFromUser(user_battler.ability,
         user_battler, target_battler, crit_stage)
      return -1 if crit_stage < 0
    end
    if !@ai.battle.moldBreaker && target.ability_active?
      crit_stage = Battle::AbilityEffects.triggerCriticalCalcFromTarget(target_battler.ability,
         user_battler, target_battler, crit_stage)
      return -1 if crit_stage < 0
    end
    if user.item_active?
      crit_stage = Battle::ItemEffects.triggerCriticalCalcFromUser(user_battler.item,
         user_battler, target_battler, crit_stage)
      return -1 if crit_stage < 0
    end
    if target.item_active?
      crit_stage = Battle::ItemEffects.triggerCriticalCalcFromTarget(user_battler.item,
         user_battler, target_battler, crit_stage)
      return -1 if crit_stage < 0
    end
    case @move.pbCritialOverride(user_battler, target_battler)
    when 1  then return 99
    when -1 then return -1
    end
    return 99 if crit_stage > 50   # Merciless
    return 99 if user_battler.effects[PBEffects::LaserFocus] > 0
    crit_stage += @move.crit_stage_bonuses(user_battler)
    crit_stage = [crit_stage, Battle::Move::CRITICAL_HIT_RATIOS.length - 1].min
    return crit_stage
  end
end