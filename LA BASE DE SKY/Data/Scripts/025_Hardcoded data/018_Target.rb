# NOTE: If adding a new target, you will need to add code in several places to
#       make them work properly:
#         - def pbFindTargets
#         - def pbMoveCanTarget?
#         - def pbCreateTargetTexts
#         - def pbFirstTarget
#         - def pbTargetsMultiple?
module GameData
  class Target
    attr_reader :id
    attr_reader :real_name
    attr_reader :num_targets        # 0, 1 or 2 (meaning 2+)
    attr_reader :targets_foe        # Is able to target one or more foes
    attr_reader :targets_all        # Crafty Shield can't protect from these moves
    attr_reader :affects_foe_side   # Pressure also affects these moves
    attr_reader :long_range         # Hits non-adjacent targets

    DATA = {}

    extend ClassMethodsSymbols
    include InstanceMethods

    def self.load; end
    def self.save; end

    def initialize(hash)
      @id               = hash[:id]
      @real_name        = hash[:name]             || "Sin nombre"
      @num_targets      = hash[:num_targets]      || 0
      @targets_foe      = hash[:targets_foe]      || false
      @targets_all      = hash[:targets_all]      || false
      @affects_foe_side = hash[:affects_foe_side] || false
      @long_range       = hash[:long_range]       || false
    end

    # @return [String] the translated name of this target
    def name
      return _INTL(@real_name)
    end

    def can_choose_distant_target?
      return @num_targets == 1 && @long_range
    end

    def can_target_one_foe?
      return @num_targets == 1 && @targets_foe
    end
  end
end

#===============================================================================

# Bide, Counter, Metal Burst, Mirror Coat (calculate a target)
GameData::Target.register({
  :id               => :None,
  :name             => _INTL("Ninguno")
})

GameData::Target.register({
  :id               => :User,
  :name             => _INTL("Usuario")
})

# Aromatic Mist, Helping Hand, Hold Hands
GameData::Target.register({
  :id               => :NearAlly,
  :name             => _INTL("Aliado Cercano"),
  :num_targets      => 1
})

# Acupressure
GameData::Target.register({
  :id               => :UserOrNearAlly,
  :name             => _INTL("Usuario o Aliado Cercano"),
  :num_targets      => 1
})

# Coaching
GameData::Target.register({
  :id               => :AllAllies,
  :name             => _INTL("Todos los Aliados"),
  :num_targets      => 2,
  :targets_all      => true,
  :long_range       => true
})

# Aromatherapy, Gear Up, Heal Bell, Life Dew, Magnetic Flux, Howl (in Gen 8+)
GameData::Target.register({
  :id               => :UserAndAllies,
  :name             => _INTL("Usuario y Aliados"),
  :num_targets      => 2,
  :long_range       => true
})

# Me First
GameData::Target.register({
  :id               => :NearFoe,
  :name             => _INTL("Rival Cercano"),
  :num_targets      => 1,
  :targets_foe      => true
})

# Petal Dance, Outrage, Struggle, Thrash, Uproar
GameData::Target.register({
  :id               => :RandomNearFoe,
  :name             => _INTL("Rival Cercano al Azar"),
  :num_targets      => 1,
  :targets_foe      => true
})

GameData::Target.register({
  :id               => :AllNearFoes,
  :name             => _INTL("Todos los Rivales Cercanos"),
  :num_targets      => 2,
  :targets_foe      => true
})

# For throwing a Poké Ball
GameData::Target.register({
  :id               => :Foe,
  :name             => _INTL("Rival"),
  :num_targets      => 1,
  :targets_foe      => true,
  :long_range       => true
})

# Unused
GameData::Target.register({
  :id               => :AllFoes,
  :name             => _INTL("Todos los Rivales"),
  :num_targets      => 2,
  :targets_foe      => true,
  :long_range       => true
})

GameData::Target.register({
  :id               => :NearOther,
  :name             => _INTL("Combatiente Cercano"),
  :num_targets      => 1,
  :targets_foe      => true
})

GameData::Target.register({
  :id               => :AllNearOthers,
  :name             => _INTL("Todos los Combatientes Cercanos"),
  :num_targets      => 2,
  :targets_foe      => true
})

# Most Flying-type moves, pulse moves (hits non-near targets)
GameData::Target.register({
  :id               => :Other,
  :name             => _INTL("Otros"),
  :num_targets      => 1,
  :targets_foe      => true,
  :long_range       => true
})

# Flower Shield, Perish Song, Rototiller, Teatime
GameData::Target.register({
  :id               => :AllBattlers,
  :name             => _INTL("Todos los Combatientes"),
  :num_targets      => 2,
  :targets_foe      => true,
  :targets_all      => true,
  :long_range       => true
})

GameData::Target.register({
  :id               => :UserSide,
  :name             => _INTL("Bando del Usuario")
})

# Entry hazards
GameData::Target.register({
  :id               => :FoeSide,
  :name             => _INTL("Bando Rival"),
  :affects_foe_side => true
})

GameData::Target.register({
  :id               => :BothSides,
  :name             => _INTL("Ambos Bandos"),
  :affects_foe_side => true
})

