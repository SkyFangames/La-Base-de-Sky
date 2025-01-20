class Battle::Move
  attr_reader   :battle
  attr_reader   :realMove
  attr_accessor :id
  attr_reader   :name
  attr_reader   :function_code
  attr_reader   :power
  attr_reader   :type
  attr_reader   :category
  attr_reader   :accuracy
  attr_accessor :pp
  attr_writer   :total_pp
  attr_reader   :addlEffect
  attr_reader   :target
  attr_reader   :priority
  attr_reader   :flags
  attr_accessor :calcType
  attr_accessor :powerBoost
  attr_accessor :snatched

  CRITICAL_HIT_RATIOS = (Settings::NEW_CRITICAL_HIT_RATE_MECHANICS) ? [24, 8, 2, 1] : [16, 8, 4, 3, 2]

  def to_int; return @id; end

  # @deprecated This method is slated to be removed in v22.
  def baseDamage
    Deprecation.warn_method("baseDamage", "v22", "power")
    return @power
  end

  #=============================================================================
  # Creating a move
  #=============================================================================
  def initialize(battle, move)
    @battle        = battle
    @realMove      = move
    @id            = move.id
    @name          = move.name   # Get the move's name
    # Get data on the move
    @function_code = move.function_code
    @power         = move.power
    @type          = move.type
    @category      = move.category
    @accuracy      = move.accuracy
    @pp            = move.pp   # Can be changed with Mimic/Transform
    @target        = move.target
    @priority      = move.priority
    @flags         = move.flags.clone
    @addlEffect    = move.effect_chance
    @powerBoost    = false   # For Aerilate, Pixilate, Refrigerate, Galvanize
    @snatched      = false
  end

  # This is the code actually used to generate a Battle::Move object. The
  # object generated is a subclass of this one which depends on the move's
  # function code.
  def self.from_pokemon_move(battle, move)
    validate move => Pokemon::Move
    code = move.function_code || "None"
    if code[/^\d/]   # Begins with a digit
      class_name = sprintf("Battle::Move::Effect%s", code)
    else
      class_name = sprintf("Battle::Move::%s", code)
    end
    if Object.const_defined?(class_name)
      return Object.const_get(class_name).new(battle, move)
    end
    return Battle::Move::Unimplemented.new(battle, move)
  end

  #=============================================================================
  # About the move
  #=============================================================================
  def pbTarget(_user); return GameData::Target.get(@target); end

  def total_pp
    return @total_pp if @total_pp && @total_pp > 0   # Usually undefined
    return @realMove.total_pp if @realMove
    return 0
  end

  # NOTE: This method is only ever called while using a move (and also by the
  #       AI), so using @calcType here is acceptable.
  def physicalMove?(thisType = nil)
    return (@category == 0) if Settings::MOVE_CATEGORY_PER_MOVE
    thisType ||= @calcType
    thisType ||= @type
    return true if !thisType
    return GameData::Type.get(thisType).physical?
  end

  # NOTE: This method is only ever called while using a move (and also by the
  #       AI), so using @calcType here is acceptable.
  def specialMove?(thisType = nil)
    return (@category == 1) if Settings::MOVE_CATEGORY_PER_MOVE
    thisType ||= @calcType
    thisType ||= @type
    return false if !thisType
    return GameData::Type.get(thisType).special?
  end

  def damagingMove?; return @category != 2; end
  def statusMove?;   return @category == 2; end

  def pbPriority(user); return @priority; end

  def usableWhenAsleep?;    return false; end
  def unusableInGravity?;   return false; end
  def healingMove?;         return false; end
  def recoilMove?;          return false; end
  def flinchingMove?;       return false; end
  def callsAnotherMove?;    return false; end
  # Whether the move can/will hit more than once in the same turn (including
  # Beat Up which may instead hit just once). Not the same as pbNumHits>1.
  def multiHitMove?;        return false; end
  def chargingTurnMove?;    return false; end
  def successCheckPerHit?;  return false; end
  def hitsFlyingTargets?;   return false; end
  def hitsDiggingTargets?;  return false; end
  def hitsDivingTargets?;   return false; end
  def ignoresReflect?;      return false; end   # For Brick Break
  def targetsPosition?;     return false; end   # For Future Sight/Doom Desire
  def cannotRedirect?;      return false; end   # For Snipe Shot
  def worksWithNoTargets?;  return false; end   # For Explosion
  def damageReducedByBurn?; return true;  end   # For Facade
  def triggersHyperMode?;   return false; end
  def canSnatch?;           return false; end
  def canMagicCoat?;        return false; end

  def contactMove?;       return @flags.any? { |f| f[/^Contact$/i] };             end
  def canProtectAgainst?; return @flags.any? { |f| f[/^CanProtect$/i] };          end
  def canMirrorMove?;     return @flags.any? { |f| f[/^CanMirrorMove$/i] };       end
  def thawsUser?;         return @flags.any? { |f| f[/^ThawsUser$/i] };           end
  def highCriticalRate?;  return @flags.any? { |f| f[/^HighCriticalHitRate$/i] }; end
  def bitingMove?;        return @flags.any? { |f| f[/^Biting$/i] };              end
  def punchingMove?;      return @flags.any? { |f| f[/^Punching$/i] };            end
  def kickingMove?;       return @flags.any? { |f| f[/^Kicking$/i] };             end
  def soundMove?;         return @flags.any? { |f| f[/^Sound$/i] };               end
  def powderMove?;        return @flags.any? { |f| f[/^Powder$/i] };              end
  def pulseMove?;         return @flags.any? { |f| f[/^Pulse$/i] };               end
  def bombMove?;          return @flags.any? { |f| f[/^Bomb$/i] };                end
  def danceMove?;         return @flags.any? { |f| f[/^Dance$/i] };               end
  # Causes perfect accuracy and double damage if target used Minimize. Perfect accuracy only with Gen 6+ mechanics.
  def tramplesMinimize?;  return @flags.any? { |f| f[/^TramplesMinimize$/i] };    end

  #-----------------------------------------------------------------------------
  # New move flags.
  #-----------------------------------------------------------------------------
  def windMove?;        return @flags.any? { |f| f[/^Wind$/i] };            end
  def slicingMove?;     return @flags.any? { |f| f[/^Slicing$/i] };         end
  def electrocuteUser?; return @flags.any? { |f| f[/^ElectrocuteUser$/i] }; end
    
    
  def nonLethal?(_user, _target); return false; end   # For False Swipe
  def preventsBattlerConsumingHealingBerry?(battler, targets); return false; end   # For Bug Bite/Pluck

    
    
    
  # user is the Pokémon using this move.
  def ignoresSubstitute?(user)
    if Settings::MECHANICS_GENERATION >= 6
      return true if soundMove?
      return true if user&.hasActiveAbility?(:INFILTRATOR)
    end
    return false
  end

  def display_type(battler)
    case @function_code
    when "TypeDependsOnUserMorpekoFormRaiseUserSpeed1"
      if battler.isSpecies?(:MORPEKO) || battler.effects[PBEffects::TransformSpecies] == :MORPEKO
        return pbBaseType(battler)
      end
    when "TypeDependsOnUserPlate", "TypeDependsOnUserMemory",
         "TypeDependsOnUserDrive", "TypeAndPowerDependOnUserBerry",
         "TypeIsUserFirstType", "TypeAndPowerDependOnWeather",
         "TypeAndPowerDependOnTerrain",
         "TypeIsUserSecondType",              # Ivy Cudgel
         "TypeIsUserSecondTypeRemoveScreens"  # Raging Bull
      return pbBaseType(battler) if Settings::SHOW_MODIFIED_MOVE_PROPERTIES
    end
    return @realMove.display_type(battler.pokemon)
  end

  def display_damage(battler)
    if Settings::SHOW_MODIFIED_MOVE_PROPERTIES
      case @function_code
      when "TypeAndPowerDependOnUserBerry"
        return pbNaturalGiftBaseDamage(battler.item_id)
      when "TypeAndPowerDependOnWeather", "TypeAndPowerDependOnTerrain",
          "PowerHigherWithUserHP", "PowerLowerWithUserHP",
          "PowerHigherWithUserHappiness", "PowerLowerWithUserHappiness",
          "PowerHigherWithUserPositiveStatStages", "PowerDependsOnUserStockpile"
        return pbBaseType(@power, battler, nil)
      end
    end
    return @realMove.display_damage(battler.pokemon)
  end

  def display_power(battler)
    if Settings::SHOW_MODIFIED_MOVE_PROPERTIES
      case @function_code
      when "TypeAndPowerDependOnUserBerry"
        return pbNaturalGiftBaseDamage(battler.item_id)
      when "TypeAndPowerDependOnWeather", "TypeAndPowerDependOnTerrain",
           "PowerHigherWithUserHP", "PowerLowerWithUserHP",
           "PowerHigherWithUserHappiness", "PowerLowerWithUserHappiness",
           "PowerHigherWithUserPositiveStatStages", "PowerDependsOnUserStockpile"
        return pbBaseType(@power, battler, nil)
      end
    end
    return @realMove.display_power(battler.pokemon)
  end

  def display_category(battler)
    if Settings::SHOW_MODIFIED_MOVE_PROPERTIES
      case @function_code
      when "CategoryDependsOnHigherDamageIgnoreTargetAbility"
        pbOnStartUse(user, nil)
        return @calcCategory
      end
    end
    return @realMove.display_category(battler.pokemon)
  end

  def display_accuracy(battler); return @realMove.display_accuracy(battler.pokemon); end
end

