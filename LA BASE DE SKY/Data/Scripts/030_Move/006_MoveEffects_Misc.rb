#===============================================================================
# No additional effect.
#===============================================================================
class Battle::Move::None < Battle::Move
end

#===============================================================================
# Does absolutely nothing. Shows a special message. (Celebrate)
#===============================================================================
class Battle::Move::DoesNothingCongratulations < Battle::Move
  def pbEffectGeneral(user)
    if user.wild?
      @battle.pbDisplay(_INTL("¡Felicidades de {1}!", user.pbThis(true)))
    else
      @battle.pbDisplay(_INTL("¡Felicidades, {1}!", @battle.pbGetOwnerName(user.index)))
    end
  end
end

#===============================================================================
# Does absolutely nothing. (Hold Hands)
#===============================================================================
class Battle::Move::DoesNothingFailsIfNoAlly < Battle::Move
  def ignoresSubstitute?(user); return true; end

  def pbMoveFailed?(user, targets)
    if user.allAllies.length == 0
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    return false
  end
end

#===============================================================================
# Does absolutely nothing. (Splash)
#===============================================================================
class Battle::Move::DoesNothingUnusableInGravity < Battle::Move
  def unusableInGravity?; return true; end

  def pbEffectGeneral(user)
    @battle.pbDisplay(_INTL("¡Pero no tuvo ningún efecto!"))
  end
end

#===============================================================================
# Scatters coins that the player picks up after winning the battle. (Pay Day)
# NOTE: In Gen 6+, if the user levels up after this move is used, the amount of
#       money picked up depends on the user's new level rather than its level
#       when it used the move. I think this is silly, so I haven't coded this
#       effect.
#===============================================================================
class Battle::Move::AddMoneyGainedFromBattle < Battle::Move
  def pbEffectGeneral(user)
    if user.pbOwnedByPlayer?
      @battle.field.effects[PBEffects::PayDay] += 5 * user.level
    end
    @battle.pbDisplay(_INTL("¡Hay monedas por todas partes!"))
  end
end

#===============================================================================
# Doubles the prize money the player gets after winning the battle. (Happy Hour)
#===============================================================================
class Battle::Move::DoubleMoneyGainedFromBattle < Battle::Move
  def pbEffectGeneral(user)
    @battle.field.effects[PBEffects::HappyHour] = true if !user.opposes?
    @battle.pbDisplay(_INTL("¡La felicidad se respira en el aire!"))
  end
end

#===============================================================================
# Fails if this isn't the user's first turn. (First Impression)
#===============================================================================
class Battle::Move::FailsIfNotUserFirstTurn < Battle::Move
  def pbMoveFailed?(user, targets)
    if user.turnCount > 1
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    return false
  end
end

#===============================================================================
# Fails unless user has already used all other moves it knows. (Last Resort)
#===============================================================================
class Battle::Move::FailsIfUserHasUnusedMove < Battle::Move
  def pbFailsAgainstTarget?(user, target, show_message)
    hasThisMove = false
    hasOtherMoves = false
    hasUnusedMoves = false
    user.eachMove do |m|
      hasThisMove    = true if m.id == @id
      hasOtherMoves  = true if m.id != @id
      hasUnusedMoves = true if m.id != @id && !user.movesUsed.include?(m.id)
    end
    if !hasThisMove || !hasOtherMoves || hasUnusedMoves
      @battle.pbDisplay(_INTL("¡Pero ha fallado!")) if show_message
      return true
    end
    return false
  end
end

#===============================================================================
# Fails unless user has consumed a berry at some point. (Belch)
#===============================================================================
class Battle::Move::FailsIfUserNotConsumedBerry < Battle::Move
  def pbCanChooseMove?(user, commandPhase, showMessages)
    if !user.belched?
      if showMessages
        msg = _INTL("¡{1} debe comerse una baya equipada para poder eructar!", user.pbThis)
        (commandPhase) ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
      end
      return false
    end
    return true
  end

  def pbMoveFailed?(user, targets)
    if !user.belched?
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    return false
  end
end

#===============================================================================
# Fails if the target is not holding an item, or if the target is affected by
# Magic Room/Klutz. (Poltergeist)
#===============================================================================
class Battle::Move::FailsIfTargetHasNoItem < Battle::Move
  def pbFailsAgainstTarget?(user, target, show_message)
    if !target.item || !target.itemActive?
      @battle.pbDisplay(_INTL("¡Pero ha fallado!")) if show_message
      return true
    end
    @battle.pbDisplay(_INTL("¡{1} es atacado por {2}!", target.pbThis, target.itemName))
    return false
  end
end

#===============================================================================
# Only damages Pokémon that share a type with the user. (Synchronoise)
#===============================================================================
class Battle::Move::FailsUnlessTargetSharesTypeWithUser < Battle::Move
  def pbFailsAgainstTarget?(user, target, show_message)
    userTypes = user.pbTypes(true)
    targetTypes = target.pbTypes(true)
    sharesType = false
    userTypes.each do |t|
      next if !targetTypes.include?(t)
      sharesType = true
      break
    end
    if !sharesType
      @battle.pbDisplay(_INTL("No afecta a {1}...", target.pbThis)) if show_message
      return true
    end
    return false
  end
end

#===============================================================================
# Fails if user was hit by a damaging move this round. (Focus Punch)
#===============================================================================
class Battle::Move::FailsIfUserDamagedThisTurn < Battle::Move
  def pbDisplayChargeMessage(user)
    user.effects[PBEffects::FocusPunch] = true
    @battle.pbCommonAnimation("FocusPunch", user)
    @battle.pbDisplay(_INTL("¡{1} está reforzando su concentración!", user.pbThis))
  end

  def pbDisplayUseMessage(user)
    super if !user.effects[PBEffects::FocusPunch] || !user.tookMoveDamageThisRound
  end

  def pbMoveFailed?(user, targets)
    if user.effects[PBEffects::FocusPunch] && user.tookMoveDamageThisRound
      @battle.pbDisplay(_INTL("¡{1} perdió la concentración y no pudo atacar!", user.pbThis))
      return true
    end
    return false
  end
end

#===============================================================================
# Fails if the target didn't choose a damaging move to use this round, or has
# already moved. (Sucker Punch)
#===============================================================================
class Battle::Move::FailsIfTargetActed < Battle::Move
  def pbFailsAgainstTarget?(user, target, show_message)
    if @battle.choices[target.index][0] != :UseMove
      @battle.pbDisplay(_INTL("¡Pero ha fallado!")) if show_message
      return true
    end
    oppMove = @battle.choices[target.index][2]
    if !oppMove ||
       (oppMove.function_code != "UseMoveTargetIsAboutToUse" &&
       (target.movedThisRound? || oppMove.statusMove?))
      @battle.pbDisplay(_INTL("¡Pero ha fallado!")) if show_message
      return true
    end
    return false
  end
end

#===============================================================================
# If attack misses, user takes crash damage of 1/2 of max HP.
# (High Jump Kick, Jump Kick)
#===============================================================================
class Battle::Move::CrashDamageIfFailsUnusableInGravity < Battle::Move
  def recoilMove?;        return true; end
  def unusableInGravity?; return true; end

  def pbCrashDamage(user)
    return if !user.takesIndirectDamage?
    @battle.pbDisplay(_INTL("¡{1} ha fallado y se ha caído al suelo!", user.pbThis))
    @battle.scene.pbDamageAnimation(user)
    user.pbReduceHP(user.totalhp / 2, false)
    user.pbItemHPHealCheck
    user.pbFaint if user.fainted?
  end
end

#===============================================================================
# Starts sunny weather. (Sunny Day)
#===============================================================================
class Battle::Move::StartSunWeather < Battle::Move::WeatherMove
  def initialize(battle, move)
    super
    @weatherType = :Sun
  end
end

#===============================================================================
# Starts rainy weather. (Rain Dance)
#===============================================================================
class Battle::Move::StartRainWeather < Battle::Move::WeatherMove
  def initialize(battle, move)
    super
    @weatherType = :Rain
  end
end

#===============================================================================
# Starts sandstorm weather. (Sandstorm)
#===============================================================================
class Battle::Move::StartSandstormWeather < Battle::Move::WeatherMove
  def initialize(battle, move)
    super
    @weatherType = :Sandstorm
  end
end

#===============================================================================
# Starts hail weather. (Hail)
#===============================================================================
class Battle::Move::StartHailWeather < Battle::Move::WeatherMove
  def initialize(battle, move)
    super
    @weatherType = :Hail
  end
end

#===============================================================================
# For 5 rounds, creates an electric terrain which boosts Electric-type moves and
# prevents Pokémon from falling asleep. Affects non-airborne Pokémon only.
# (Electric Terrain)
#===============================================================================
class Battle::Move::StartElectricTerrain < Battle::Move
  def pbMoveFailed?(user, targets)
    if @battle.field.terrain == :Electric
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    @battle.pbStartTerrain(user, :Electric)
  end
end

#===============================================================================
# For 5 rounds, creates a grassy terrain which boosts Grass-type moves and heals
# Pokémon at the end of each round. Affects non-airborne Pokémon only.
# (Grassy Terrain)
#===============================================================================
class Battle::Move::StartGrassyTerrain < Battle::Move
  def pbMoveFailed?(user, targets)
    if @battle.field.terrain == :Grassy
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    @battle.pbStartTerrain(user, :Grassy)
  end
end

#===============================================================================
# For 5 rounds, creates a misty terrain which weakens Dragon-type moves and
# protects Pokémon from status problems. Affects non-airborne Pokémon only.
# (Misty Terrain)
#===============================================================================
class Battle::Move::StartMistyTerrain < Battle::Move
  def pbMoveFailed?(user, targets)
    if @battle.field.terrain == :Misty
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    @battle.pbStartTerrain(user, :Misty)
  end
end

#===============================================================================
# For 5 rounds, creates a psychic terrain which boosts Psychic-type moves and
# prevents Pokémon from being hit by >0 priority moves. Affects non-airborne
# Pokémon only. (Psychic Terrain)
#===============================================================================
class Battle::Move::StartPsychicTerrain < Battle::Move
  def pbMoveFailed?(user, targets)
    if @battle.field.terrain == :Psychic
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    @battle.pbStartTerrain(user, :Psychic)
  end
end

#===============================================================================
# Removes the current terrain. Fails if there is no terrain in effect.
# (Steel Roller)
#===============================================================================
class Battle::Move::RemoveTerrain < Battle::Move
  def pbMoveFailed?(user, targets)
    if @battle.field.terrain == :None
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    case @battle.field.terrain
    when :Electric
      @battle.pbDisplay(_INTL("El campo de corriente eléctrica ha desaparecido."))
    when :Grassy
      @battle.pbDisplay(_INTL("La hierba ha desaparecido."))
    when :Misty
      @battle.pbDisplay(_INTL("La niebla se ha disipado."))
    when :Psychic
      @battle.pbDisplay(_INTL("Ha desaparecido la extraña sensación que se percibía en el terreno de combate."))
    end
    @battle.field.terrain = :None
  end
end

#===============================================================================
# Entry hazard. Lays spikes on the opposing side (max. 3 layers). (Spikes)
#===============================================================================
class Battle::Move::AddSpikesToFoeSide < Battle::Move
  def canMagicCoat?; return true; end

  def pbMoveFailed?(user, targets)
    if user.pbOpposingSide.effects[PBEffects::Spikes] >= 3
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    user.pbOpposingSide.effects[PBEffects::Spikes] += 1
    @battle.pbDisplay(_INTL("¡{1} está rodeado de púas!",
                            user.pbOpposingTeam(true)))
  end
end

#===============================================================================
# Entry hazard. Lays poison spikes on the opposing side (max. 2 layers).
# (Toxic Spikes)
#===============================================================================
class Battle::Move::AddToxicSpikesToFoeSide < Battle::Move
  def canMagicCoat?; return true; end

  def pbMoveFailed?(user, targets)
    if user.pbOpposingSide.effects[PBEffects::ToxicSpikes] >= 2
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    user.pbOpposingSide.effects[PBEffects::ToxicSpikes] += 1
    @battle.pbDisplay(_INTL("¡{1} está rodeado de púas tóxicas!",
                            user.pbOpposingTeam(true)))
  end
end

#===============================================================================
# Entry hazard. Lays stealth rocks on the opposing side. (Stealth Rock)
#===============================================================================
class Battle::Move::AddStealthRocksToFoeSide < Battle::Move
  def canMagicCoat?; return true; end

  def pbMoveFailed?(user, targets)
    if user.pbOpposingSide.effects[PBEffects::StealthRock]
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    user.pbOpposingSide.effects[PBEffects::StealthRock] = true
    @battle.pbDisplay(_INTL("¡{1} está rodeado de piedras puntiagudas!",
                            user.pbOpposingTeam(true)))
  end
end

#===============================================================================
# Entry hazard. Lays stealth rocks on the opposing side. (Sticky Web)
#===============================================================================
class Battle::Move::AddStickyWebToFoeSide < Battle::Move
  def canMagicCoat?; return true; end

  def pbMoveFailed?(user, targets)
    if user.pbOpposingSide.effects[PBEffects::StickyWeb]
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    user.pbOpposingSide.effects[PBEffects::StickyWeb] = true
    @battle.pbDisplay(_INTL("¡Una red viscosa se extiende a los pies de {1}!",
                            user.pbOpposingTeam(true)))
  end
end

#===============================================================================
# All effects that apply to one side of the field are swapped to the opposite
# side. (Court Change)
#===============================================================================
class Battle::Move::SwapSideEffects < Battle::Move
  attr_reader :number_effects, :boolean_effects

  def initialize(battle, move)
    super
    @number_effects = [
      PBEffects::AuroraVeil,
      PBEffects::LightScreen,
      PBEffects::Mist,
      PBEffects::Rainbow,
      PBEffects::Reflect,
      PBEffects::Safeguard,
      PBEffects::SeaOfFire,
      PBEffects::Spikes,
      PBEffects::Swamp,
      PBEffects::Tailwind,
      PBEffects::ToxicSpikes
    ]
    @boolean_effects = [
      PBEffects::StealthRock,
      PBEffects::StickyWeb
    ]
  end

  def pbMoveFailed?(user, targets)
    has_effect = false
    2.times do |side|
      effects = @battle.sides[side].effects
      @number_effects.each do |e|
        next if effects[e] == 0
        has_effect = true
        break
      end
      break if has_effect
      @boolean_effects.each do |e|
        next if !effects[e]
        has_effect = true
        break
      end
      break if has_effect
    end
    if !has_effect
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    side0 = @battle.sides[0]
    side1 = @battle.sides[1]
    @number_effects.each do |e|
      side0.effects[e], side1.effects[e] = side1.effects[e], side0.effects[e]
    end
    @boolean_effects.each do |e|
      side0.effects[e], side1.effects[e] = side1.effects[e], side0.effects[e]
    end
    @battle.pbDisplay(_INTL("¡{1} ha intercambiado los efectos del campo de combate!", user.pbThis))
  end
end

#===============================================================================
# User turns 1/4 of max HP into a substitute. (Substitute)
#===============================================================================
class Battle::Move::UserMakeSubstitute < Battle::Move
  def canSnatch?; return true; end

  def pbMoveFailed?(user, targets)
    if user.effects[PBEffects::Substitute] > 0
      @battle.pbDisplay(_INTL("¡{1} ya tiene un sustituto!", user.pbThis))
      return true
    end
    @subLife = [user.totalhp / 4, 1].max
    if user.hp <= @subLife
      @battle.pbDisplay(_INTL("¡Está demasiado débil para crear un sustituto!"))
      return true
    end
    return false
  end

  def pbOnStartUse(user, targets)
    user.pbReduceHP(@subLife, false, false)
    user.pbItemHPHealCheck
  end

  def pbEffectGeneral(user)
    user.effects[PBEffects::Trapping]     = 0
    user.effects[PBEffects::TrappingMove] = nil
    user.effects[PBEffects::Substitute]   = @subLife
    @battle.pbDisplay(_INTL("¡{1} ha creado un sustituto!", user.pbThis))
  end
end

#===============================================================================
# Removes trapping moves, entry hazards and Leech Seed on user/user's side.
# Raises user's Speed by 1 stage (Gen 8+). (Rapid Spin)
#===============================================================================
class Battle::Move::RemoveUserBindingAndEntryHazards < Battle::Move::StatUpMove
  def initialize(battle, move)
    super
    @statUp = [:SPEED, 1]
  end

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

  def pbAdditionalEffect(user, target)
    super if Settings::MECHANICS_GENERATION >= 8
  end
end

#===============================================================================
# Attacks 2 rounds in the future. (Doom Desire, Future Sight)
#===============================================================================
class Battle::Move::AttackTwoTurnsLater < Battle::Move
  def targetsPosition?; return true; end

  # Stops damage being dealt in the setting-up turn.
  def pbDamagingMove?
    return false if !@battle.futureSight
    return super
  end

  def pbAccuracyCheck(user, target)
    return true if !@battle.futureSight
    return super
  end

  def pbDisplayUseMessage(user)
    super if !@battle.futureSight
  end

  def pbFailsAgainstTarget?(user, target, show_message)
    if !@battle.futureSight &&
       @battle.positions[target.index].effects[PBEffects::FutureSightCounter] > 0
      @battle.pbDisplay(_INTL("¡Pero ha fallado!")) if show_message
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user, target)
    return if @battle.futureSight   # Attack is hitting
    effects = @battle.positions[target.index].effects
    effects[PBEffects::FutureSightCounter]        = 3
    effects[PBEffects::FutureSightMove]           = @id
    effects[PBEffects::FutureSightUserIndex]      = user.index
    effects[PBEffects::FutureSightUserPartyIndex] = user.pokemonIndex
    if @id == :DOOMDESIRE
      @battle.pbDisplay(_INTL("¡{1} ha sido alcanzado por Deseo Oculto!", user.pbThis))
    else
      @battle.pbDisplay(_INTL("¡{1} ha sido alcanzado por Premonición!", user.pbThis))
    end
  end

  def pbShowAnimation(id, user, targets, hitNum = 0, showAnimation = true)
    hitNum = 1 if !@battle.futureSight   # Charging anim
    super
  end
end

#===============================================================================
# User switches places with its ally. (Ally Switch)
#===============================================================================
class Battle::Move::UserSwapsPositionsWithAlly < Battle::Move
  def pbChangeUsageCounters(user, specialUsage)
    oldVal = user.effects[PBEffects::ProtectRate]
    super
    user.effects[PBEffects::ProtectRate] = oldVal
  end
  
  def pbMoveFailed?(user, targets)
    if Settings::MECHANICS_GENERATION >= 9
      if user.effects[PBEffects::AllySwitch]
        user.effects[PBEffects::ProtectRate] = 1
        @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
        return true
      end
      if user.effects[PBEffects::ProtectRate] > 1 &&
         @battle.pbRandom(user.effects[PBEffects::ProtectRate]) != 0
        user.effects[PBEffects::ProtectRate] = 1
        @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
        return true
      end
    end
    numTargets = 0
    @idxAlly = -1
    idxUserOwner = @battle.pbGetOwnerIndexFromBattlerIndex(user.index)
    user.allAllies.each do |b|
      next if @battle.pbGetOwnerIndexFromBattlerIndex(b.index) != idxUserOwner
      next if !b.near?(user)
      numTargets += 1
      @idxAlly = b.index
    end
    if numTargets != 1
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    if Settings::MECHANICS_GENERATION >= 9
      user.effects[PBEffects::AllySwitch] = true
      user.effects[PBEffects::ProtectRate] *= 3
    end
    idxA = user.index
    idxB = @idxAlly
    if @battle.pbSwapBattlers(idxA, idxB)
      @battle.pbDisplay(_INTL("¡{1} y {2} han intercambiado sus posiciones!",
                              @battle.battlers[idxB].pbThis, @battle.battlers[idxA].pbThis(true)))
      [idxA, idxB].each { |idx| @battle.pbEffectsOnBattlerEnteringPosition(@battle.battlers[idx]) }
    end
  end
end

#===============================================================================
# If a Pokémon makes contact with the user before it uses this move, the
# attacker is burned. (Beak Blast)
#===============================================================================
class Battle::Move::BurnAttackerBeforeUserActs < Battle::Move
  def pbDisplayChargeMessage(user)
    user.effects[PBEffects::BeakBlast] = true
    @battle.pbCommonAnimation("BeakBlast", user)
    @battle.pbDisplay(_INTL("¡{1} empieza a calentar su pico!", user.pbThis))
  end
end

#===============================================================================
# Salt Cure
#===============================================================================
# Target will lose 1/4 of max HP at end of each round, or 1/8th if Water or Steel.
#-------------------------------------------------------------------------------
class Battle::Move::StartSaltCureTarget < Battle::Move
  def canMagicCoat?; return true; end

  def pbFailsAgainstTarget?(user, target, show_message)
    return false if damagingMove?
    if target.effects[PBEffects::SaltCure]
      @battle.pbDisplay(_INTL("¡Pero ha fallado!")) if show_message
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user, target)
    return if damagingMove?
    target.effects[PBEffects::SaltCure] = true
    @battle.pbDisplay(_INTL("¡{1} sufre de salazón!", target.pbThis))
  end

  def pbAdditionalEffect(user, target)
    return if target.damageState.substitute
    target.effects[PBEffects::SaltCure] = true
    @battle.pbDisplay(_INTL("¡{1} sufre de salazón!", target.pbThis))
  end
end


#===============================================================================
# Ice Spinner
#===============================================================================
# Removes the current terrain.
#-------------------------------------------------------------------------------
class Battle::Move::RemoveTerrainIceSpinner < Battle::Move
  def pbEffectGeneral(user)
    return if @battle.field.terrain == :None
    case @battle.field.terrain
    when :Electric
      @battle.pbDisplay(_INTL("El campo de corriente eléctrica ha desaparecido."))
    when :Grassy
      @battle.pbDisplay(_INTL("La hierba ha desaparecido."))
    when :Misty
      @battle.pbDisplay(_INTL("La niebla se ha disipado."))
    when :Psychic
      @battle.pbDisplay(_INTL("Ha desaparecido la extraña sensación que se percibía en el terreno de combate."))
    end
    @battle.field.terrain = :None
    @battle.allBattlers.each { |battler| battler.pbAbilityOnTerrainChange }
  end
end


#===============================================================================
# Doodle
#===============================================================================
# User and all allies copy the target's ability.
#-------------------------------------------------------------------------------
class Battle::Move::SetUserAlliesAbilityToTargetAbility < Battle::Move
  def ignoresSubstitute?(user); return true; end
  
  def pbMoveFailed?(user, targets)
    @battle.allSameSideBattlers(user.index).each do |b|
      next if !b.unstoppableAbility?
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    if user.hasActiveItem?(:ABILITYSHIELD)
      @battle.pbDisplay(_INTL("La habilidad de {1} está protegida por los efectos de su Escudo Habilidad!",user.pbThis))
      return true
    end
    return false
  end

  def pbFailsAgainstTarget?(user, target, show_message)
    if !target.ability || user.ability == target.ability
      @battle.pbDisplay(_INTL("¡Pero ha fallado!")) if show_message
      return true
    end
    if target.uncopyableAbility?
      @battle.pbDisplay(_INTL("¡Pero ha fallado!")) if show_message
      return true
    end
    return false
  end
  
  def pbEffectAgainstTarget(user, target)
    @battle.allSameSideBattlers(user).each do |b|
	  next if b.ability == target.ability
      if b.hasActiveItem?(:ABILITYSHIELD)
        @battle.pbDisplay(_INTL("{1}'s Ability is protected by the effects of its Ability Shield!", b.pbThis))
      else
        @battle.pbShowAbilitySplash(b, true, false)
        oldAbil = b.ability
        b.ability = target.ability
        @battle.pbReplaceAbilitySplash(b)
        @battle.pbDisplay(_INTL("{1} copied {2}'s {3}!",
                            user.pbThis, target.pbThis(true), target.abilityName))
        @battle.pbHideAbilitySplash(b)
        b.pbOnLosingAbility(oldAbil)
        b.pbTriggerAbilityOnGainingIt
      end
    end
  end
end

#===============================================================================
# Revival Blessing
#===============================================================================
# Revive one fainted Pokemon from party with up to 1/2 its total HP.
#-------------------------------------------------------------------------------
class Battle::Move::RevivePokemonHalfHP < Battle::Move
  def healingMove?; return true; end
  
  def pbMoveFailed?(user, targets)
    @numFainted = 0
    user.battle.pbParty(user.idxOwnSide).each { |b| @numFainted += 1 if b.fainted? }
    if @numFainted == 0
      @battle.pbDisplay(_INTL("¡Pero ha fallado!"))
      return true
    end
    return false
  end
  
  def pbEndOfMoveUsageEffect(user, targets, numHits, switchedBattlers)
    return if user.fainted? || @numFainted == 0
    @battle.pbReviveInParty(user.index)
  end
end

#===============================================================================
# Fickle Beam
#===============================================================================
# Has a 30% chance to deal double damage.
#-------------------------------------------------------------------------------
class Battle::Move::RandomlyDealsDoubleDamage < Battle::Move
  def pbOnStartUse(user, targets)
    @allOutAttack = (@battle.pbRandom(100) < 30)
    if @allOutAttack
      @battle.pbDisplay(_INTL("¡{1} va con todo por este ataque!", user.pbThis))
    end
  end

  def pbBaseDamage(baseDmg, user, target)
    return (@allOutAttack) ? baseDmg * 2 : baseDmg
  end
  
  def pbShowAnimation(id, user, targets, hitNum = 0, showAnimation = true)
    hitNum = 1 if @allOutAttack
    super
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
    @battle.pbDisplay(_INTL("Spikes were scattered all around {1}'s feet!", user.pbOpposingTeam(true)))
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
    @battle.pbDisplay(_INTL("Pointed stones float in the air around {1}!", user.pbOpposingTeam(true)))
  end
end