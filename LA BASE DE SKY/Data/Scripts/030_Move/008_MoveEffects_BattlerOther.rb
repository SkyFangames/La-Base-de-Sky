#===============================================================================
# Puts the target to sleep.
#===============================================================================
class Battle::Move::SleepTarget < Battle::Move
  def canMagicCoat?; return true; end

  def pbFailsAgainstTarget?(user, target, show_message)
    return false if damagingMove?
    return !target.pbCanSleep?(user, show_message, self)
  end

  def pbEffectAgainstTarget(user, target)
    return if damagingMove?
    target.pbSleep
  end

  def pbAdditionalEffect(user, target)
    return if target.damageState.substitute
    target.pbSleep if target.pbCanSleep?(user, false, self)
  end
end

#===============================================================================
# Puts the target to sleep. Fails if user is not Darkrai. (Dark Void (Gen 7+))
#===============================================================================
class Battle::Move::SleepTargetIfUserDarkrai < Battle::Move::SleepTarget
  def pbMoveFailed?(user, targets)
    if !user.isSpecies?(:DARKRAI) && user.effects[PBEffects::TransformSpecies] != :DARKRAI
      @battle.pbDisplay(_INTL("¡Pero {1} no puede usar el movimiento!", user.pbThis))
      return true
    end
    return false
  end
end

#===============================================================================
# Puts the target to sleep. Changes the user's form if the user is Meloetta.
# (Relic Song)
#===============================================================================
class Battle::Move::SleepTargetChangeUserMeloettaForm < Battle::Move::SleepTarget
  def pbEndOfMoveUsageEffect(user, targets, numHits, switchedBattlers)
    return if numHits == 0
    return if user.fainted? || user.effects[PBEffects::Transform]
    return if !user.isSpecies?(:MELOETTA)
    return if user.hasActiveAbility?(:SHEERFORCE) && @addlEffect > 0
    newForm = (user.form + 1) % 2
    user.pbChangeForm(newForm, _INTL("¡{1} se transformó!", user.pbThis))
  end
end

#===============================================================================
# Makes the target drowsy; it falls asleep at the end of the next turn. (Yawn)
#===============================================================================
class Battle::Move::SleepTargetNextTurn < Battle::Move
  def canMagicCoat?; return true; end

  def pbFailsAgainstTarget?(user, target, show_message)
    if target.effects[PBEffects::Yawn] > 0
      @battle.pbDisplay(_INTL("¡Pero ha fallado!")) if show_message
      return true
    end
    return true if !target.pbCanSleep?(user, true, self)
    return false
  end

  def pbEffectAgainstTarget(user, target)
    target.effects[PBEffects::Yawn] = 2
    @battle.pbDisplay(_INTL("{1} adormeció al {2}!", user.pbThis, target.pbThis(true)))
  end
end

#===============================================================================
# Poisons the target.
#===============================================================================
class Battle::Move::PoisonTarget < Battle::Move
  def canMagicCoat?; return true; end

  def initialize(battle, move)
    super
    @toxic = false
  end

  def pbFailsAgainstTarget?(user, target, show_message)
    return false if damagingMove?
    return !target.pbCanPoison?(user, show_message, self)
  end

  def pbEffectAgainstTarget(user, target)
    return if damagingMove?
    target.pbPoison(user, nil, @toxic)
  end

  def pbAdditionalEffect(user, target)
    return if target.damageState.substitute
    target.pbPoison(user, nil, @toxic) if target.pbCanPoison?(user, false, self)
  end
end

#===============================================================================
# Poisons the target and decreases its Speed by 1 stage. (Toxic Thread)
#===============================================================================
class Battle::Move::PoisonTargetLowerTargetSpeed1 < Battle::Move
  attr_reader :statDown

  def initialize(battle, move)
    super
    @statDown = [:SPEED, 1]
  end

  def canMagicCoat?; return true; end

  def pbFailsAgainstTarget?(user, target, show_message)
    if !target.pbCanPoison?(user, false, self) &&
       !target.pbCanLowerStatStage?(@statDown[0], user, self)
      @battle.pbDisplay(_INTL("¡Pero ha fallado!")) if show_message
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user, target)
    target.pbPoison(user) if target.pbCanPoison?(user, false, self)
    if target.pbCanLowerStatStage?(@statDown[0], user, self)
      target.pbLowerStatStage(@statDown[0], @statDown[1], user)
    end
  end
end

#===============================================================================
# Badly poisons the target. (Poison Fang, Toxic)
#===============================================================================
class Battle::Move::BadPoisonTarget < Battle::Move::PoisonTarget
  def initialize(battle, move)
    super
    @toxic = true
  end

  def pbOverrideSuccessCheckPerHit(user, target)
    return (Settings::MORE_TYPE_EFFECTS && statusMove? && user.pbHasType?(:POISON))
  end
end

#===============================================================================
# Paralyzes the target.
#===============================================================================
class Battle::Move::ParalyzeTarget < Battle::Move
  def canMagicCoat?; return true; end

  def pbFailsAgainstTarget?(user, target, show_message)
    return false if damagingMove?
    return !target.pbCanParalyze?(user, show_message, self)
  end

  def pbEffectAgainstTarget(user, target)
    return if damagingMove?
    target.pbParalyze(user)
  end

  def pbAdditionalEffect(user, target)
    return if target.damageState.substitute
    target.pbParalyze(user) if target.pbCanParalyze?(user, false, self)
  end
end

#===============================================================================
# Paralyzes the target. Doesn't affect target if move's type has no effect on
# it. (Thunder Wave)
#===============================================================================
class Battle::Move::ParalyzeTargetIfNotTypeImmune < Battle::Move::ParalyzeTarget
  def pbFailsAgainstTarget?(user, target, show_message)
    if Effectiveness.ineffective?(target.damageState.typeMod)
      @battle.pbDisplay(_INTL("No afecta a {1}...", target.pbThis(true))) if show_message
      return true
    end
    return super
  end
end

#===============================================================================
# Paralyzes the target. Accuracy perfect in rain, 50% in sunshine. Hits some
# semi-invulnerable targets. (Thunder)
#===============================================================================
class Battle::Move::ParalyzeTargetAlwaysHitsInRainHitsTargetInSky < Battle::Move::ParalyzeTarget
  def hitsFlyingTargets?; return true; end

  def pbBaseAccuracy(user, target)
    case target.effectiveWeather
    when :Sun, :HarshSun
      return 50
    when :Rain, :HeavyRain
      return 0
    end
    return super
  end
end

#===============================================================================
# Paralyzes the target. May cause the target to flinch. (Thunder Fang)
#===============================================================================
class Battle::Move::ParalyzeFlinchTarget < Battle::Move
  def flinchingMove?; return true; end

  def pbAdditionalEffect(user, target)
    return if target.damageState.substitute
    chance = pbAdditionalEffectChance(user, target, 10)
    return if chance == 0
    if target.pbCanParalyze?(user, false, self) && @battle.pbRandom(100) < chance
      target.pbParalyze(user)
    end
    target.pbFlinch(user) if @battle.pbRandom(100) < chance
  end
end

#===============================================================================
# Burns the target.
#===============================================================================
class Battle::Move::BurnTarget < Battle::Move
  def canMagicCoat?; return true; end

  def pbFailsAgainstTarget?(user, target, show_message)
    return false if damagingMove?
    return !target.pbCanBurn?(user, show_message, self)
  end

  def pbEffectAgainstTarget(user, target)
    return if damagingMove?
    target.pbBurn(user)
  end

  def pbAdditionalEffect(user, target)
    return if target.damageState.substitute
    target.pbBurn(user) if target.pbCanBurn?(user, false, self)
  end
end

#===============================================================================
# Frostbites the target.
#===============================================================================
class Battle::Move::FrostbiteTarget < Battle::Move
  def canMagicCoat?; return true; end

  def pbFailsAgainstTarget?(user, target, show_message)
    return false if damagingMove?
    return !target.pbCanFrostbite?(user, show_message, self)
  end

  def pbEffectAgainstTarget(user, target)
    return if damagingMove?
    target.pbFrostbite(user)
  end

  def pbAdditionalEffect(user, target)
    return if target.damageState.substitute
    target.pbFrostbite(user) if target.pbCanFrostbite?(user, false, self)
  end
end

#===============================================================================
# Burns the target if any of its stats were increased this round.
# (Burning Jealousy)
#===============================================================================
class Battle::Move::BurnTargetIfTargetStatsRaisedThisTurn < Battle::Move::BurnTarget
  def pbAdditionalEffect(user, target)
    super if target.statsRaisedThisRound
  end
end

#===============================================================================
# Burns the target. May cause the target to flinch. (Fire Fang)
#===============================================================================
class Battle::Move::BurnFlinchTarget < Battle::Move
  def flinchingMove?; return true; end

  def pbAdditionalEffect(user, target)
    return if target.damageState.substitute
    chance = pbAdditionalEffectChance(user, target, 10)
    return if chance == 0
    if target.pbCanBurn?(user, false, self) && @battle.pbRandom(100) < chance
      target.pbBurn(user)
    end
    target.pbFlinch(user) if @battle.pbRandom(100) < chance
  end
end

#===============================================================================
# Freezes the target.
#===============================================================================
class Battle::Move::FreezeTarget < Battle::Move
  def canMagicCoat?; return true; end

  def pbFailsAgainstTarget?(user, target, show_message)
    return false if damagingMove?
    return !target.pbCanFreeze?(user, show_message, self)
  end

  def pbEffectAgainstTarget(user, target)
    return if damagingMove?
    target.pbFreeze
  end

  def pbAdditionalEffect(user, target)
    return if target.damageState.substitute
    target.pbFreeze if target.pbCanFreeze?(user, false, self)
  end
end

#===============================================================================
# Freezes the target. Effectiveness against Water-type is 2x. (Freeze-Dry)
#===============================================================================
class Battle::Move::FreezeTargetSuperEffectiveAgainstWater < Battle::Move::FreezeTarget
  def pbCalcTypeModSingle(moveType, defType, user, target)
    return Effectiveness::SUPER_EFFECTIVE_MULTIPLIER if defType == :WATER
    return super
  end
end

#===============================================================================
# Freezes the target. Accuracy perfect in hail. (Blizzard)
#===============================================================================
class Battle::Move::FreezeTargetAlwaysHitsInHail < Battle::Move::FreezeTarget
  def pbBaseAccuracy(user, target)
    return 0 if target.effectiveWeather == :Hail
    return super
  end
end

#===============================================================================
# Freezes the target. May cause the target to flinch. (Ice Fang)
#===============================================================================
class Battle::Move::FreezeFlinchTarget < Battle::Move
  def flinchingMove?; return true; end

  def pbAdditionalEffect(user, target)
    return if target.damageState.substitute
    chance = pbAdditionalEffectChance(user, target, 10)
    return if chance == 0
    if target.pbCanFreeze?(user, false, self) && @battle.pbRandom(100) < chance
      target.pbFreeze
    end
    target.pbFlinch(user) if @battle.pbRandom(100) < chance
  end
end

#===============================================================================
# Burns, freezes or paralyzes the target. (Tri Attack)
#===============================================================================
class Battle::Move::ParalyzeBurnOrFreezeTarget < Battle::Move
  def pbAdditionalEffect(user, target)
    return if target.damageState.substitute
    case @battle.pbRandom(3)
    when 0 then target.pbBurn(user) if target.pbCanBurn?(user, false, self)
    when 1 then target.pbFreeze if target.pbCanFreeze?(user, false, self)
    when 2 then target.pbParalyze(user) if target.pbCanParalyze?(user, false, self)
    end
  end
end

#===============================================================================
# User passes its status problem to the target. (Psycho Shift)
#===============================================================================
class Battle::Move::GiveUserStatusToTarget < Battle::Move
  def pbMoveFailed?(user, targets)
    if user.status == :NONE
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    return false
  end

  def pbFailsAgainstTarget?(user, target, show_message)
    if !target.pbCanInflictStatus?(user.status, user, false, self)
      @battle.pbDisplay(_INTL("¡Pero ha fallado!")) if show_message
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user, target)
    msg = ""
    case user.status
    when :SLEEP
      target.pbSleep
      msg = _INTL("{1} se despertó.", user.pbThis)
    when :POISON
      target.pbPoison(user, nil, user.statusCount != 0)
      msg = _INTL("{1} fue curado del envenenamiento.", user.pbThis)
    when :BURN
      target.pbBurn(user)
      msg = _INTL("La quemadura de {1} fue curada.", user.pbThis)
    when :PARALYSIS
      target.pbParalyze(user)
      msg = _INTL("{1} fue curado de la parálisis.", user.pbThis)
    when :FROZEN
      target.pbFreeze
      msg = _INTL("{1} se descongeló.", user.pbThis)
    when :FROSTBITE
      target.pbFreeze
      msg = _INTL("{1} se descongeló.", user.pbThis)
    end
    if msg != ""
      user.pbCureStatus(false)
      @battle.pbDisplay(msg)
    end
  end
end

#===============================================================================
# Cures user of burn, poison and paralysis. (Refresh)
#===============================================================================
class Battle::Move::CureUserBurnPoisonParalysis < Battle::Move
  def canSnatch?; return true; end

  def pbMoveFailed?(user, targets)
    if ![:BURN, :POISON, :PARALYSIS].include?(user.status)
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    old_status = user.status
    user.pbCureStatus(false)
    case old_status
    when :BURN
      @battle.pbDisplay(_INTL("La quemadura de {1} fue curada.", user.pbThis))
    when :POISON
      @battle.pbDisplay(_INTL("{1} fue curado del envenenamiento.", user.pbThis))
    when :PARALYSIS
      @battle.pbDisplay(_INTL("{1} fue curado de la parálisis.", user.pbThis))
    end
  end
end

# El mensaje oficial es "El estado de {1} regresó a la normalidad"

#===============================================================================
# Cures all party Pokémon of permanent status problems. (Aromatherapy, Heal Bell)
#===============================================================================
# NOTE: In Gen 5, this move should have a target of UserSide, while in Gen 6+ it
#       should have a target of UserAndAllies. This is because, in Gen 5, this
#       move shouldn't call def pbSuccessCheckAgainstTarget for each Pokémon
#       currently in battle that will be affected by this move (i.e. allies
#       aren't protected by their substitute/ability/etc., but they are in Gen
#       6+). We achieve this by not targeting any battlers in Gen 5, since
#       pbSuccessCheckAgainstTarget is only called for targeted battlers.
class Battle::Move::CureUserPartyStatus < Battle::Move
  def canSnatch?;          return true; end
  def worksWithNoTargets?; return true; end

  def pbMoveFailed?(user, targets)
    has_effect = @battle.allSameSideBattlers(user).any? { |b| b.status != :NONE }
    if !has_effect
      has_effect = @battle.pbParty(user.index).any? { |pkmn| pkmn&.able? && pkmn.status != :NONE }
    end
    if !has_effect
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    return false
  end

  def pbFailsAgainstTarget?(user, target, show_message)
    return target.status == :NONE
  end

  def pbAromatherapyHeal(pkmn, battler = nil)
    oldStatus = (battler) ? battler.status : pkmn.status
    curedName = (battler) ? battler.pbThis : pkmn.name
    if battler
      battler.pbCureStatus(false)
    else
      pkmn.status      = :NONE
      pkmn.statusCount = 0
    end
    case oldStatus
    when :SLEEP
      @battle.pbDisplay(_INTL("{1} se despertó.", curedName))
    when :POISON
      @battle.pbDisplay(_INTL("{1} fue curado del envenenamiento.", curedName))
    when :BURN
      @battle.pbDisplay(_INTL("La quemadura de {1} fue curada.", curedName))
    when :PARALYSIS
      @battle.pbDisplay(_INTL("{1} fue curado de la parálisis.", curedName))
    when :FROZEN
      @battle.pbDisplay(_INTL("{1} se descongeló.", curedName))
    when :FROSTBITE
      @battle.pbDisplay(_INTL("{1} se descongeló.", curedName))
    end
  end

  def pbEffectAgainstTarget(user, target)
    # Cure all Pokémon in battle on the user's side.
    pbAromatherapyHeal(target.pokemon, target)
  end

  def pbEffectGeneral(user)
    # Cure all Pokémon in battle on the user's side. For the benefit of the Gen
    # 5 version of this move, to make Pokémon out in battle get cured first.
    if pbTarget(user) == :UserSide
      @battle.allSameSideBattlers(user).each do |b|
        pbAromatherapyHeal(b.pokemon, b) if b.status != :NONE
      end
    end
    # Cure all Pokémon in the user's and partner trainer's party.
    # NOTE: This intentionally affects the partner trainer's inactive Pokémon
    #       too.
    @battle.pbParty(user.index).each_with_index do |pkmn, i|
      next if !pkmn || !pkmn.able? || pkmn.status == :NONE
      next if @battle.pbFindBattler(i, user)   # Skip Pokémon in battle
      pbAromatherapyHeal(pkmn)
    end
  end

  def pbShowAnimation(id, user, targets, hitNum = 0, showAnimation = true)
    super
    case @id
    when :AROMATHERAPY
      @battle.pbDisplay(_INTL("¡Un balsámico aroma impregnó la zona!"))
    when :HEALBELL
      @battle.pbDisplay(_INTL("¡Ha repicado una campana!"))
    end
  end
end

#===============================================================================
# Cures the target's burn. (Sparkling Aria)
#===============================================================================
class Battle::Move::CureTargetBurn < Battle::Move
  def pbAdditionalEffect(user, target)
    return if target.fainted? || target.damageState.substitute
    return if target.status != :BURN
    target.pbCureStatus
  end
end

#===============================================================================
# Safeguards the user's side from being inflicted with status problems.
# (Safeguard)
#===============================================================================
class Battle::Move::StartUserSideImmunityToInflictedStatus < Battle::Move
  def canSnatch?; return true; end

  def pbMoveFailed?(user, targets)
    if user.pbOwnSide.effects[PBEffects::Safeguard] > 0
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    user.pbOwnSide.effects[PBEffects::Safeguard] = 5
    @battle.pbDisplay(_INTL("¡{1} se protegió con Velo Sagrado!", user.pbTeam))
  end
end

#===============================================================================
# Causes the target to flinch.
#===============================================================================
class Battle::Move::FlinchTarget < Battle::Move
  def flinchingMove?; return true; end

  def pbEffectAgainstTarget(user, target)
    return if damagingMove?
    target.pbFlinch(user)
  end

  def pbAdditionalEffect(user, target)
    return if target.damageState.substitute
    target.pbFlinch(user)
  end
end

#===============================================================================
# Causes the target to flinch. Fails if the user is not asleep. (Snore)
#===============================================================================
class Battle::Move::FlinchTargetFailsIfUserNotAsleep < Battle::Move::FlinchTarget
  def usableWhenAsleep?; return true; end

  def pbMoveFailed?(user, targets)
    if !user.asleep?
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    return false
  end
end

#===============================================================================
# Causes the target to flinch. Fails if this isn't the user's first turn.
# (Fake Out)
#===============================================================================
class Battle::Move::FlinchTargetFailsIfNotUserFirstTurn < Battle::Move::FlinchTarget
  def pbMoveFailed?(user, targets)
    if user.turnCount > 1
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    return false
  end
end

#===============================================================================
# Power is doubled if the target is using Bounce, Fly or Sky Drop. Hits some
# semi-invulnerable targets. May make the target flinch. (Twister)
#===============================================================================
class Battle::Move::FlinchTargetDoublePowerIfTargetInSky < Battle::Move::FlinchTarget
  def hitsFlyingTargets?; return true; end

  def pbBaseDamage(baseDmg, user, target)
    baseDmg *= 2 if target.inTwoTurnAttack?("TwoTurnAttackInvulnerableInSky",
                                            "TwoTurnAttackInvulnerableInSkyParalyzeTarget",
                                            "TwoTurnAttackInvulnerableInSkyTargetCannotAct") ||
                    target.effects[PBEffects::SkyDrop] >= 0
    return baseDmg
  end
end

#===============================================================================
# Confuses the target.
#===============================================================================
class Battle::Move::ConfuseTarget < Battle::Move
  def canMagicCoat?; return true; end

  def pbFailsAgainstTarget?(user, target, show_message)
    return false if damagingMove?
    return !target.pbCanConfuse?(user, show_message, self)
  end

  def pbEffectAgainstTarget(user, target)
    return if damagingMove?
    target.pbConfuse
  end

  def pbAdditionalEffect(user, target)
    return if target.damageState.substitute
    return if !target.pbCanConfuse?(user, false, self)
    target.pbConfuse
  end
end

#===============================================================================
# Confuses the target. Accuracy perfect in rain, 50% in sunshine. Hits some
# semi-invulnerable targets. (Hurricane)
#===============================================================================
class Battle::Move::ConfuseTargetAlwaysHitsInRainHitsTargetInSky < Battle::Move::ConfuseTarget
  def hitsFlyingTargets?; return true; end

  def pbBaseAccuracy(user, target)
    case target.effectiveWeather
    when :Sun, :HarshSun
      return 50
    when :Rain, :HeavyRain
      return 0
    end
    return super
  end
end

#===============================================================================
# Attracts the target. (Attract)
#===============================================================================
class Battle::Move::AttractTarget < Battle::Move
  def ignoresSubstitute?(user); return true; end
  def canMagicCoat?; return true; end

  def pbFailsAgainstTarget?(user, target, show_message)
    return false if damagingMove?
    return true if !target.pbCanAttract?(user, show_message)
    return false
  end

  def pbEffectAgainstTarget(user, target)
    return if damagingMove?
    target.pbAttract(user)
  end

  def pbAdditionalEffect(user, target)
    return if target.damageState.substitute
    target.pbAttract(user) if target.pbCanAttract?(user, false)
  end
end

#===============================================================================
# Changes user's type depending on the environment. (Camouflage)
#===============================================================================
class Battle::Move::SetUserTypesBasedOnEnvironment < Battle::Move
  TERRAIN_TYPES = {
    :Electric => :ELECTRIC,
    :Grassy   => :GRASS,
    :Misty    => :FAIRY,
    :Psychic  => :PSYCHIC
  }
  ENVIRONMENT_TYPES = {
    :None        => :NORMAL,
    :Grass       => :GRASS,
    :TallGrass   => :GRASS,
    :MovingWater => :WATER,
    :StillWater  => :WATER,
    :Puddle      => :WATER,
    :Underwater  => :WATER,
    :Cave        => :ROCK,
    :Rock        => :GROUND,
    :Sand        => :GROUND,
    :Forest      => :BUG,
    :ForestGrass => :BUG,
    :Snow        => :ICE,
    :Ice         => :ICE,
    :Volcano     => :FIRE,
    :Graveyard   => :GHOST,
    :Sky         => :FLYING,
    :Space       => :DRAGON,
    :UltraSpace  => :PSYCHIC
  }

  def canSnatch?; return true; end

  def pbMoveFailed?(user, targets)
    if !user.canChangeType?
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    @newType = :NORMAL
    terr_type = TERRAIN_TYPES[@battle.field.terrain]
    if terr_type && GameData::Type.exists?(terr_type)
      @newType = terr_type
    else
      @newType = ENVIRONMENT_TYPES[@battle.environment] || :NORMAL
      @newType = :NORMAL if !GameData::Type.exists?(@newType)
    end
    if !GameData::Type.exists?(@newType) || !user.pbHasOtherType?(@newType)
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    user.pbChangeTypes(@newType)
    typeName = GameData::Type.get(@newType).name
    @battle.pbDisplay(_INTL("{1} ha cambiado a tipo {2}!", user.pbThis, typeName))
  end
end

#===============================================================================
# Changes user's type to a random one that resists/is immune to the last move
# used by the target. (Conversion 2)
#===============================================================================
class Battle::Move::SetUserTypesToResistLastAttack < Battle::Move
  def ignoresSubstitute?(user); return true; end

  def pbMoveFailed?(user, targets)
    if !user.canChangeType?
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    return false
  end

  def pbFailsAgainstTarget?(user, target, show_message)
    if !target.lastMoveUsed || !target.lastMoveUsedType ||
       GameData::Type.get(target.lastMoveUsedType).pseudo_type
      @battle.pbDisplay(_INTL("¡Pero ha fallado!")) if show_message
      return true
    end
    @newTypes = []
    GameData::Type.each do |t|
      next if t.pseudo_type || user.pbHasType?(t.id) ||
              !Effectiveness.resistant_type?(target.lastMoveUsedType, t.id)
      @newTypes.push(t.id)
    end
    if @newTypes.length == 0
      @battle.pbDisplay(_INTL("¡Pero ha fallado!")) if show_message
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    newType = @newTypes[@battle.pbRandom(@newTypes.length)]
    user.pbChangeTypes(newType)
    typeName = GameData::Type.get(newType).name
    @battle.pbDisplay(_INTL("{1} ha cambiado a tipo {2}!", user.pbThis, typeName))
  end
end

#===============================================================================
# User copies target's types. (Reflect Type)
#===============================================================================
class Battle::Move::SetUserTypesToTargetTypes < Battle::Move
  def ignoresSubstitute?(user); return true; end

  def pbMoveFailed?(user, targets)
    if !user.canChangeType?
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    return false
  end

  def pbFailsAgainstTarget?(user, target, show_message)
    newTypes = target.pbTypes(true)
    if newTypes.length == 0   # Target has no type to copy
      @battle.pbDisplay(_INTL("¡Pero ha fallado!")) if show_message
      return true
    end
    if user.pbTypes == target.pbTypes &&
       user.effects[PBEffects::ExtraType] == target.effects[PBEffects::ExtraType]
      @battle.pbDisplay(_INTL("¡Pero ha fallado!")) if show_message
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user, target)
    user.pbChangeTypes(target)
    @battle.pbDisplay(_INTL("¡{1} ahora es del mismo tipo que el {2}!",
                            user.pbThis, target.pbThis(true)))
  end
end

#===============================================================================
# Changes user's type to that of a random user's move, except a type the user
# already has (even partially), OR changes to the user's first move's type.
# (Conversion)
#===============================================================================
class Battle::Move::SetUserTypesToUserMoveType < Battle::Move
  def canSnatch?; return true; end

  def pbMoveFailed?(user, targets)
    if !user.canChangeType?
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    userTypes = user.pbTypes(true)
    @newTypes = []
    user.eachMoveWithIndex do |m, i|
      break if Settings::MECHANICS_GENERATION >= 6 && i > 0
      next if GameData::Type.get(m.type).pseudo_type
      next if userTypes.include?(m.type)
      @newTypes.push(m.type) if !@newTypes.include?(m.type)
    end
    if @newTypes.length == 0
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    newType = @newTypes[@battle.pbRandom(@newTypes.length)]
    user.pbChangeTypes(newType)
    typeName = GameData::Type.get(newType).name
    @battle.pbDisplay(_INTL("¡{1} ha cambiado al tipo {2}!", user.pbThis, typeName))
  end
end

#===============================================================================
# The target's types become Psychic. (Magic Powder)
#===============================================================================
class Battle::Move::SetTargetTypesToPsychic < Battle::Move
  def canMagicCoat?; return true; end

  def pbFailsAgainstTarget?(user, target, show_message)
    if !target.canChangeType? || !GameData::Type.exists?(:PSYCHIC) ||
       !target.pbHasOtherType?(:PSYCHIC)
      @battle.pbDisplay(_INTL("¡Pero ha fallado!")) if show_message
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user, target)
    target.pbChangeTypes(:PSYCHIC)
    typeName = GameData::Type.get(:PSYCHIC).name
    @battle.pbDisplay(_INTL("¡{1} ha cambiado a tipo {2}!", target.pbThis, typeName))
  end
end

#===============================================================================
# Target becomes Water type. (Soak)
#===============================================================================
class Battle::Move::SetTargetTypesToWater < Battle::Move
  def canMagicCoat?; return true; end

  def pbFailsAgainstTarget?(user, target, show_message)
    if !target.canChangeType? || !GameData::Type.exists?(:WATER) ||
       !target.pbHasOtherType?(:WATER)
      @battle.pbDisplay(_INTL("¡Pero ha fallado!")) if show_message
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user, target)
    target.pbChangeTypes(:WATER)
    typeName = GameData::Type.get(:WATER).name
    @battle.pbDisplay(_INTL("¡{1} ha cambiado a tipo {2}!", target.pbThis, typeName))
  end
end

#===============================================================================
# Gives target the Ghost type. (Trick-or-Treat)
#===============================================================================
class Battle::Move::AddGhostTypeToTarget < Battle::Move
  def canMagicCoat?; return true; end

  def pbFailsAgainstTarget?(user, target, show_message)
    if !target.canChangeType? || !GameData::Type.exists?(:GHOST) || target.pbHasType?(:GHOST)
      @battle.pbDisplay(_INTL("¡Pero ha fallado!")) if show_message
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user, target)
    target.effects[PBEffects::ExtraType] = :GHOST
    typeName = GameData::Type.get(:GHOST).name
    @battle.pbDisplay(_INTL("¡{1} ha cambiado a tipo {2}!", target.pbThis, typeName))
  end
end

#===============================================================================
# Gives target the Grass type. (Forest's Curse)
#===============================================================================
class Battle::Move::AddGrassTypeToTarget < Battle::Move
  def canMagicCoat?; return true; end

  def pbFailsAgainstTarget?(user, target, show_message)
    if !target.canChangeType? || !GameData::Type.exists?(:GRASS) || target.pbHasType?(:GRASS)
      @battle.pbDisplay(_INTL("¡Pero ha fallado!")) if show_message
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user, target)
    target.effects[PBEffects::ExtraType] = :GRASS
    typeName = GameData::Type.get(:GRASS).name
    @battle.pbDisplay(_INTL("¡{1} ha cambiado a tipo {2}!", target.pbThis, typeName))
  end
end

#===============================================================================
# User loses their Fire type. Fails if user is not Fire-type. (Burn Up)
#===============================================================================
class Battle::Move::UserLosesFireType < Battle::Move
  def pbMoveFailed?(user, targets)
    if !user.pbHasType?(:FIRE)
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    return false
  end

  def pbEffectAfterAllHits(user, target)
    if !user.effects[PBEffects::BurnUp]
      user.effects[PBEffects::BurnUp] = true
      @battle.pbDisplay(_INTL("¡El fuego interior de {1} se ha extinguido!", user.pbThis))
    end
  end
end

#===============================================================================
# Target's ability becomes Simple. (Simple Beam)
#===============================================================================
class Battle::Move::SetTargetAbilityToSimple < Battle::Move
  def canMagicCoat?; return true; end

  def pbMoveFailed?(user, targets)
    if !GameData::Ability.exists?(:SIMPLE)
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    return false
  end

  def pbFailsAgainstTarget?(user, target, show_message)
    if target.unstoppableAbility? || [:TRUANT, :SIMPLE].include?(target.ability_id)
      @battle.pbDisplay(_INTL("¡Pero ha fallado!")) if show_message
      return true
    end
    ret = false
    if !ret && target.hasActiveItem?(:ABILITYSHIELD)
      @battle.pbDisplay(_INTL("¡La habilidad de {1} está protegida por los efectos del Escudo Habilidad!", target.pbThis)) if show_message
      return true
    end
    return ret
  end

  def pbEffectAgainstTarget(user, target)
    @battle.pbShowAbilitySplash(target, true, false)
    oldAbil = target.ability
    target.ability = :SIMPLE
    @battle.pbReplaceAbilitySplash(target)
    @battle.pbDisplay(_INTL("¡La habilidad de {1} ha cambiado a {2}!", target.pbThis, target.abilityName))
    @battle.pbHideAbilitySplash(target)
    target.pbOnLosingAbility(oldAbil)
    target.pbTriggerAbilityOnGainingIt
  end
end

#===============================================================================
# Target's ability becomes Insomnia. (Worry Seed)
#===============================================================================
class Battle::Move::SetTargetAbilityToInsomnia < Battle::Move
  def canMagicCoat?; return true; end

  def pbMoveFailed?(user, targets)
    if !GameData::Ability.exists?(:INSOMNIA)
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    return false
  end

  def pbFailsAgainstTarget?(user, target, show_message)
    if target.unstoppableAbility? || [:TRUANT, :INSOMNIA].include?(target.ability_id)
      @battle.pbDisplay(_INTL("¡Pero ha fallado!")) if show_message
      return true
    end
    if target.hasActiveItem?(:ABILITYSHIELD)
      @battle.pbDisplay(_INTL("¡La habilidad de {1} está protegida por los efectos del Escudo Habilidad!", target.pbThis)) if show_message
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user, target)
    @battle.pbShowAbilitySplash(target, true, false)
    oldAbil = target.ability
    target.ability = :INSOMNIA
    @battle.pbReplaceAbilitySplash(target)
    @battle.pbDisplay(_INTL("¡El {1} adquirió {2}!", target.pbThis, target.abilityName))
    @battle.pbHideAbilitySplash(target)
    target.pbOnLosingAbility(oldAbil)
    target.pbTriggerAbilityOnGainingIt
  end
end

#===============================================================================
# User copies target's ability. (Role Play)
#===============================================================================
class Battle::Move::SetUserAbilityToTargetAbility < Battle::Move
  def ignoresSubstitute?(user); return true; end

  def pbMoveFailed?(user, targets)
    if user.hasActiveItem?(:ABILITYSHIELD)
      @battle.pbDisplay(_INTL("¡La habilidad de {1} está protegida por los efectos del Escudo Habilidad!", user.pbThis))
      return true
    end
    if user.unstoppableAbility?
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    return false
  end

  def pbFailsAgainstTarget?(user, target, show_message)
    if !target.ability || user.ability == target.ability
      @battle.pbDisplay(_INTL("¡Pero ha fallado!")) if show_message
      return true
    end
    if target.ungainableAbility? ||
       [:POWEROFALCHEMY, :RECEIVER, :TRACE, :WONDERGUARD].include?(target.ability_id)
      @battle.pbDisplay(_INTL("¡Pero ha fallado!")) if show_message
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user, target)
    @battle.pbShowAbilitySplash(user, true, false)
    oldAbil = user.ability
    user.ability = target.ability
    @battle.pbReplaceAbilitySplash(user)
    @battle.pbDisplay(_INTL("¡{1} copió {2} del {3}!",
                            user.pbThis, target.pbThis(true), target.abilityName))
    @battle.pbHideAbilitySplash(user)
    user.pbOnLosingAbility(oldAbil)
    user.pbTriggerAbilityOnGainingIt
  end
end

#===============================================================================
# Target copies user's ability. (Entrainment)
#===============================================================================
class Battle::Move::SetTargetAbilityToUserAbility < Battle::Move
  def canMagicCoat?; return true; end

  def pbMoveFailed?(user, targets)
    if !user.ability
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    if user.ungainableAbility? ||
       [:POWEROFALCHEMY, :RECEIVER, :TRACE].include?(user.ability_id)
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    return false
  end

  def pbFailsAgainstTarget?(user, target, show_message)
    if target.unstoppableAbility? || target.ability == :TRUANT
      @battle.pbDisplay(_INTL("¡Pero ha fallado!")) if show_message
      return true
    end
    if target.hasActiveItem?(:ABILITYSHIELD)
      @battle.pbDisplay(_INTL("¡La habilidad de {1} está protegida por los efectos del Escudo Habilidad!", target.pbThis)) if show_message
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user, target)
    @battle.pbShowAbilitySplash(target, true, false)
    oldAbil = target.ability
    target.ability = user.ability
    @battle.pbReplaceAbilitySplash(target)
    @battle.pbDisplay(_INTL("¡La habilidad de {1} ha cambiado a {2}!", target.pbThis, target.abilityName))
    @battle.pbHideAbilitySplash(target)
    target.pbOnLosingAbility(oldAbil)
    target.pbTriggerAbilityOnGainingIt
  end
end

#===============================================================================
# User and target swap abilities. (Skill Swap)
#===============================================================================
class Battle::Move::UserTargetSwapAbilities < Battle::Move
  def ignoresSubstitute?(user); return true; end

  def pbMoveFailed?(user, targets)
    if user.hasActiveItem?(:ABILITYSHIELD)
      @battle.pbDisplay(_INTL("¡La habilidad de {1} está protegida por los efectos del Escudo Habilidad!", user.pbThis))
      return true
    end
    
    if !user.ability
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    if user.unstoppableAbility?
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    if user.ungainableAbility? || user.ability == :WONDERGUARD
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    return false
  end

  def pbFailsAgainstTarget?(user, target, show_message)
    if !target.ability ||
       (user.ability == target.ability && Settings::MECHANICS_GENERATION <= 5)
      @battle.pbDisplay(_INTL("¡Pero ha fallado!")) if show_message
      return true
    end
    if target.unstoppableAbility?
      @battle.pbDisplay(_INTL("¡Pero ha fallado!")) if show_message
      return true
    end
    if target.ungainableAbility? || target.ability == :WONDERGUARD
      @battle.pbDisplay(_INTL("¡Pero ha fallado!")) if show_message
      return true
    end
    if target.hasActiveItem?(:ABILITYSHIELD)
      @battle.pbDisplay(_INTL("¡La habilidad de {1} está protegida por los efectos del Escudo Habilidad!", target.pbThis)) if show_message
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user, target)
    if user.opposes?(target)
      @battle.pbShowAbilitySplash(user, false, false)
      @battle.pbShowAbilitySplash(target, true, false)
    end
    oldUserAbil   = user.ability
    oldTargetAbil = target.ability
    user.ability   = oldTargetAbil
    target.ability = oldUserAbil
    if user.opposes?(target)
      @battle.pbReplaceAbilitySplash(user)
      @battle.pbReplaceAbilitySplash(target)
    end
    if Battle::Scene::USE_ABILITY_SPLASH
      @battle.pbDisplay(_INTL("¡{1} ha intercambiado su habilidad con la de su objetivo!", user.pbThis))
    else
      @battle.pbDisplay(_INTL("{1} ha intercambiado su Habilidad {2} con la Habilidad {3} de su objetivo!",
                              user.pbThis, target.abilityName, user.abilityName))
    end
    if user.opposes?(target)
      @battle.pbHideAbilitySplash(user)
      @battle.pbHideAbilitySplash(target)
    end
    user.pbOnLosingAbility(oldUserAbil)
    target.pbOnLosingAbility(oldTargetAbil)
    user.pbTriggerAbilityOnGainingIt
    target.pbTriggerAbilityOnGainingIt
  end
end

#===============================================================================
# Target's ability is negated. (Gastro Acid)
#===============================================================================
class Battle::Move::NegateTargetAbility < Battle::Move
  def canMagicCoat?; return true; end

  def pbFailsAgainstTarget?(user, target, show_message)
    if target.unstoppableAbility? || target.effects[PBEffects::GastroAcid]
      @battle.pbDisplay(_INTL("¡Pero ha fallado!")) if show_message
      return true
    end
    if target.hasActiveItem?(:ABILITYSHIELD)
      @battle.pbDisplay(_INTL("¡La habilidad de {1} está protegida por los efectos del Escudo Habilidad!", target.pbThis)) if show_message
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user, target)
    target.effects[PBEffects::GastroAcid] = true
    target.effects[PBEffects::Truant]     = false
    @battle.pbDisplay(_INTL("¡Se ha anulado la Habilidad del {1}!", target.pbThis))
    target.pbOnLosingAbility(target.ability, true)
  end
end

#===============================================================================
# Negates the target's ability while it remains on the field, if it has already
# performed its action this round. (Core Enforcer)
#===============================================================================
class Battle::Move::NegateTargetAbilityIfTargetActed < Battle::Move
  def pbEffectAgainstTarget(user, target)
    return if target.hasActiveItem?(:ABILITYSHIELD)
    return if target.damageState.substitute || target.effects[PBEffects::GastroAcid]
    return if target.unstoppableAbility?
    return if @battle.choices[target.index][0] != :UseItem &&
              !((@battle.choices[target.index][0] == :UseMove ||
              @battle.choices[target.index][0] == :Shift) && target.movedThisRound?)
    target.effects[PBEffects::GastroAcid] = true
    target.effects[PBEffects::Truant]     = false
    @battle.pbDisplay(_INTL("¡Se ha anulado la Habilidad del {1}!", target.pbThis))
    target.pbOnLosingAbility(target.ability, true)
  end
end

#===============================================================================
# Ignores all abilities that alter this move's success or damage.
# (Moongeist Beam, Sunsteel Strike)
#===============================================================================
class Battle::Move::IgnoreTargetAbility < Battle::Move
  def pbChangeUsageCounters(user, specialUsage)
    super
    @battle.moldBreaker = true if !specialUsage
  end
  
  def pbOnStartUse(user, targets)
    if @battle.moldBreaker && targets[0].hasActiveItem?(:ABILITYSHIELD)
      @battle.moldBreaker = false
    end
  end
end

#===============================================================================
# For 5 rounds, user becomes airborne. (Magnet Rise)
#===============================================================================
class Battle::Move::StartUserAirborne < Battle::Move
  def unusableInGravity?; return true; end
  def canSnatch?;         return true; end

  def pbMoveFailed?(user, targets)
    if user.effects[PBEffects::Ingrain] ||
       user.effects[PBEffects::SmackDown] ||
       user.effects[PBEffects::MagnetRise] > 0
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    user.effects[PBEffects::MagnetRise] = 5
    @battle.pbDisplay(_INTL("{1} levita con electromagnetismo!", user.pbThis))
  end
end

#===============================================================================
# For 3 rounds, target becomes airborne and can always be hit. (Telekinesis)
#===============================================================================
class Battle::Move::StartTargetAirborneAndAlwaysHitByMoves < Battle::Move
  def unusableInGravity?; return true; end
  def canMagicCoat?;      return true; end

  def pbFailsAgainstTarget?(user, target, show_message)
    if target.effects[PBEffects::Ingrain] ||
       target.effects[PBEffects::SmackDown] ||
       target.effects[PBEffects::Telekinesis] > 0
      @battle.pbDisplay(_INTL("¡Pero ha fallado!")) if show_message
      return true
    end
    if target.isSpecies?(:DIGLETT) ||
       target.isSpecies?(:DUGTRIO) ||
       target.isSpecies?(:SANDYGAST) ||
       target.isSpecies?(:PALOSSAND) ||
       (target.isSpecies?(:GENGAR) && target.mega?)
      @battle.pbDisplay(_INTL("¡Pero ha fallado!")) if show_message
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user, target)
    target.effects[PBEffects::Telekinesis] = 3
    @battle.pbDisplay(_INTL("¡{1} ha sido lanzado por los aires!", target.pbThis))
  end
end

#===============================================================================
# Hits airborne semi-invulnerable targets. (Sky Uppercut)
#===============================================================================
class Battle::Move::HitsTargetInSky < Battle::Move
  def hitsFlyingTargets?; return true; end
end

#===============================================================================
# Grounds the target while it remains active. Hits some semi-invulnerable
# targets. (Smack Down, Thousand Arrows)
#===============================================================================
class Battle::Move::HitsTargetInSkyGroundsTarget < Battle::Move
  def hitsFlyingTargets?; return true; end

  def pbCalcTypeModSingle(moveType, defType, user, target)
    return Effectiveness::NORMAL_EFFECTIVE_MULTIPLIER if moveType == :GROUND && defType == :FLYING
    return super
  end

  def pbEffectAfterAllHits(user, target)
    return if target.fainted?
    return if target.damageState.unaffected || target.damageState.substitute
    return if target.inTwoTurnAttack?("TwoTurnAttackInvulnerableInSkyTargetCannotAct") ||
              target.effects[PBEffects::SkyDrop] >= 0   # Sky Drop
    return if !target.airborne? && !target.inTwoTurnAttack?("TwoTurnAttackInvulnerableInSky",
                                                            "TwoTurnAttackInvulnerableInSkyParalyzeTarget")
    target.effects[PBEffects::SmackDown] = true
    if target.inTwoTurnAttack?("TwoTurnAttackInvulnerableInSky",
                               "TwoTurnAttackInvulnerableInSkyParalyzeTarget")   # NOTE: Not Sky Drop.
      target.effects[PBEffects::TwoTurnAttack] = nil
      @battle.pbClearChoice(target.index) if !target.movedThisRound?
    end
    target.effects[PBEffects::MagnetRise]  = 0
    target.effects[PBEffects::Telekinesis] = 0
    @battle.pbDisplay(_INTL("¡{1} ha sido derribado!", target.pbThis))
  end
end

#===============================================================================
# For 5 rounds, increases gravity on the field. Pokémon cannot become airborne.
# (Gravity)
#===============================================================================
class Battle::Move::StartGravity < Battle::Move
  def pbMoveFailed?(user, targets)
    if @battle.field.effects[PBEffects::Gravity] > 0
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    @battle.field.effects[PBEffects::Gravity] = 5
    @battle.pbDisplay(_INTL("¡La gravedad se ha incrementado!"))
    @battle.allBattlers.each do |b|
      showMessage = false
      if b.inTwoTurnAttack?("TwoTurnAttackInvulnerableInSky",
                            "TwoTurnAttackInvulnerableInSkyParalyzeTarget",
                            "TwoTurnAttackInvulnerableInSkyTargetCannotAct")
        b.effects[PBEffects::TwoTurnAttack] = nil
        @battle.pbClearChoice(b.index) if !b.movedThisRound?
        showMessage = true
      end
      if b.effects[PBEffects::MagnetRise] > 0 ||
         b.effects[PBEffects::Telekinesis] > 0 ||
         b.effects[PBEffects::SkyDrop] >= 0
        b.effects[PBEffects::MagnetRise]  = 0
        b.effects[PBEffects::Telekinesis] = 0
        b.effects[PBEffects::SkyDrop]     = -1
        showMessage = true
      end
      if showMessage
        @battle.pbDisplay(_INTL("¡{1} no ha podido mantenerse en el aire por la gravedad!", b.pbThis))
      end
    end
  end
end

#===============================================================================
# User transforms into the target. (Transform)
#===============================================================================
class Battle::Move::TransformUserIntoTarget < Battle::Move
  def pbMoveFailed?(user, targets)
    if user.effects[PBEffects::Transform]
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    return false
  end

  def pbFailsAgainstTarget?(user, target, show_message)
    if target.effects[PBEffects::Transform] ||
       target.effects[PBEffects::Illusion]
      @battle.pbDisplay(_INTL("¡Pero ha fallado!")) if show_message
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user, target)
    user.pbTransform(target)
  end

  def pbShowAnimation(id, user, targets, hitNum = 0, showAnimation = true)
    super
    @battle.scene.pbChangePokemon(user, targets[0].pokemon)
  end
end

#===============================================================================
# Axe Kick
#===============================================================================
# If attack misses, user takes crash damage of 1/2 of max HP. May cause confusion.
#-------------------------------------------------------------------------------
class Battle::Move::CrashDamageIfFailsConfuseTarget < Battle::Move::ConfuseTarget
  def recoilMove?; return true; end
  
  def pbCrashDamage(user)
    return if !user.takesIndirectDamage?
    @battle.pbDisplay(_INTL("¡{1} ha fallado y se ha caído al suelo!", user.pbThis))
    @battle.scene.pbDamageAnimation(user)
    user.pbReduceHP((user.totalhp / 2), false)
    user.pbItemHPHealCheck
    user.pbFaint if user.fainted?
  end
end

#===============================================================================
# Mortal Spin
#===============================================================================
# Removes trapping moves, entry hazards and Leech Seed on user/user's side.
# Poisons the target.
#-------------------------------------------------------------------------------
class Battle::Move::RemoveUserBindingAndEntryHazardsPoisonTarget < Battle::Move::PoisonTarget
  def pbEffectAfterAllHits(user, target)
    return if user.fainted? || target.damageState.unaffected
    if user.effects[PBEffects::Trapping] > 0
      trapMove = GameData::Move.get(user.effects[PBEffects::TrappingMove]).name
      trapUser = @battle.battlers[user.effects[PBEffects::TrappingUser]]
      @battle.pbDisplay(_INTL("¡{1} se liberó de {2} de {3}!", user.pbThis, trapUser.pbThis(true), trapMove))
      user.effects[PBEffects::Trapping]     = 0
      user.effects[PBEffects::TrappingMove] = nil
      user.effects[PBEffects::TrappingUser] = -1
    end
    if user.effects[PBEffects::LeechSeed] >= 0
      user.effects[PBEffects::LeechSeed] = -1
      @battle.pbDisplay(_INTL("¡{1} se curó de la drenadoras!", user.pbThis))
    end
    if user.pbOwnSide.effects[PBEffects::StealthRock]
      user.pbOwnSide.effects[PBEffects::StealthRock] = false
      @battle.pbDisplay(_INTL("Las piedras puntiagudas lanzadas a {1} han desaparecido.", user.pbTeam))
    end
    if defined?(PBEffects::Steelsurge) && user.pbOwnSide.effects[PBEffects::Steelsurge]
      user.pbOwnSide.effects[PBEffects::Steelsurge] = false
      @battle.pbDisplay(_INTL("¡{1} eliminó las púas metalicas!", user.pbThis))
    end
    if user.pbOwnSide.effects[PBEffects::Spikes] > 0
      user.pbOwnSide.effects[PBEffects::Spikes] = 0
      @battle.pbDisplay(_INTL("Las púas lanzadas a {1} han desaparecido.", user.pbTeam))
    end
    if user.pbOwnSide.effects[PBEffects::ToxicSpikes] > 0
      user.pbOwnSide.effects[PBEffects::ToxicSpikes] = 0
      @battle.pbDisplay(_INTL("Las púas tóxicas lanzadas a {1} han desaparecido.", user.pbTeam))
    end
    if user.pbOwnSide.effects[PBEffects::StickyWeb]
      user.pbOwnSide.effects[PBEffects::StickyWeb] = false
      @battle.pbDisplay(_INTL("La red viscosa lanzada a {1} ha desaparecido.", user.pbTeam))
    end
  end
end



#===============================================================================
# Dire Claw
#===============================================================================
# May paralyze, poison or put the target to sleep.
#-------------------------------------------------------------------------------
class Battle::Move::PoisonParalyzeOrSleepTarget < Battle::Move
  def pbAdditionalEffect(user, target)
    return if target.damageState.substitute
    case @battle.pbRandom(3)
    when 0 then target.pbSleep          if target.pbCanSleep?(user, false, self)
    when 1 then target.pbPoison(user)   if target.pbCanPoison?(user, false, self)
    when 2 then target.pbParalyze(user) if target.pbCanParalyze?(user, false, self)
    end
  end
end

#===============================================================================
# Barb Barrage
#===============================================================================
# Power is doubled if the target is poisoned. May poison the target.
#-------------------------------------------------------------------------------
class Battle::Move::DoublePowerIfTargetPoisonedPoisonTarget < Battle::Move::PoisonTarget
  def pbBaseDamage(baseDmg, user, target)
    if target.poisoned? &&
       (target.effects[PBEffects::Substitute] == 0 || ignoresSubstitute?(user))
      baseDmg *= 2
    end
    return baseDmg
  end
end

#===============================================================================
# Infernal Parade
#===============================================================================
# Power is doubled if the target has a status condition. May burn the target.
#-------------------------------------------------------------------------------
class Battle::Move::DoublePowerIfTargetStatusProblemBurnTarget < Battle::Move::BurnTarget
  def pbBaseDamage(baseDmg, user, target)
    if target.pbHasAnyStatus? &&
       (target.effects[PBEffects::Substitute] == 0 || ignoresSubstitute?(user))
      baseDmg *= 2
    end
    return baseDmg
  end
end

#===============================================================================
# Ceaseless Edge (Gen 9+)
#===============================================================================
# Lays spikes on the opposing side if damage was dealt (max. 3 layers).
#-------------------------------------------------------------------------------
class Battle::Move::DamageTargetAddSpikesToFoeSide < Battle::Move
  def pbEffectWhenDealingDamage(user, target)
    return if target.pbOwnSide.effects[PBEffects::Spikes] == 3
    target.pbOwnSide.effects[PBEffects::Spikes] += 1
    @battle.pbAnimation(:SPIKES, user, target)
    @battle.pbDisplay(_INTL("¡Se espacieron púas alrededor de {1}!", user.pbOpposingTeam(true)))
  end
end

#===============================================================================
# Stone Axe (Gen 9+)
#===============================================================================
# Lays stealth rocks on the opposing side if damage was dealt.
#-------------------------------------------------------------------------------
class Battle::Move::DamageTargetAddStealthRocksToFoeSide < Battle::Move
  def pbEffectWhenDealingDamage(user, target)
    return if target.pbOwnSide.effects[PBEffects::StealthRock]
    target.pbOwnSide.effects[PBEffects::StealthRock] = true
    @battle.pbAnimation(:STEALTHROCK, user, target)
    @battle.pbDisplay(_INTL("¡Rocas puntiagudas flotan en el aire alrededor de {1}!", user.pbOpposingTeam(true)))
  end
end

#===============================================================================
# Gigaton Hammer, Blood Moon
#===============================================================================
# This move becomes unselectable if you try to use it on consecutive turns.
#-------------------------------------------------------------------------------
class Battle::Move::CantSelectConsecutiveTurns < Battle::Move
  def pbEffectWhenDealingDamage(user, target)
    user.effects[PBEffects::SuccessiveMove] = @id
  end
end

#===============================================================================
# Double Shock
#===============================================================================
# User loses their Electric type. Fails if user is not Electric-type.
#-------------------------------------------------------------------------------
class Battle::Move::UserLosesElectricType < Battle::Move
  def pbMoveFailed?(user, targets)
    if !user.pbHasType?(:ELECTRIC)
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    return false
  end

  def pbEffectAfterAllHits(user, target)
    if !user.effects[PBEffects::DoubleShock]
      user.effects[PBEffects::DoubleShock] = true
      @battle.pbDisplay(_INTL("¡{1} ha usado toda su electricidad!", user.pbThis))
    end
  end
end

#===============================================================================
# Alluring Voice
#===============================================================================
# Confuse the target if the target's stats have been raised this turn.
#-------------------------------------------------------------------------------
class Battle::Move::ConfuseTargetIfTargetStatsRaisedThisTurn < Battle::Move::ConfuseTarget
  def pbAdditionalEffect(user, target)
    super if target.statsRaisedThisRound
  end
end

#===============================================================================
# Blazing Torque
#===============================================================================
# Burns the target.
#-------------------------------------------------------------------------------
class Battle::Move::StarmobileBurnTarget < Battle::Move::BurnTarget
end

#===============================================================================
# Noxious Torque
#===============================================================================
# Poisons the target.
#-------------------------------------------------------------------------------
class Battle::Move::StarmobilePoisonTarget < Battle::Move::PoisonTarget
end

#===============================================================================
# Combat Torque
#===============================================================================
# Paralyzes the target.
#-------------------------------------------------------------------------------
class Battle::Move::StarmobileParalyzeTarget < Battle::Move::ParalyzeTarget
end

#===============================================================================
# Wicked Torque
#===============================================================================
# Puts the target to sleep.
#-------------------------------------------------------------------------------
class Battle::Move::StarmobileSleepTarget < Battle::Move::SleepTarget
end

#===============================================================================
# Magical Torque
#===============================================================================
# Confuses the target.
#-------------------------------------------------------------------------------
class Battle::Move::StarmobileConfuseTarget < Battle::Move::ConfuseTarget
end
