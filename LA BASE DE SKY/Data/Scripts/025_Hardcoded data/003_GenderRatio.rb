# If a Pokémon's gender ratio is none of :AlwaysMale, :AlwaysFemale or
# :Genderless, then it will choose a random number between 0 and 255 inclusive,
# and compare it to the @female_chance. If the random number is lower than this
# chance, it will be female; otherwise, it will be male.
module GameData
  class GenderRatio
    attr_reader :id
    attr_reader :real_name
    attr_reader :female_chance

    DATA = {}

    extend ClassMethodsSymbols
    include InstanceMethods

    def self.load; end
    def self.save; end

    def initialize(hash)
      @id            = hash[:id]
      @real_name     = hash[:name] || "Sin nombre"
      @female_chance = hash[:female_chance]
    end

    # @return [String] the translated name of this gender ratio
    def name
      return _INTL(@real_name)
    end

    # @return [Boolean] whether a Pokémon with this gender ratio can only ever
    #   be a single gender
    def single_gendered?
      return @female_chance.nil?
    end
  end
end

#===============================================================================

GameData::GenderRatio.register({
  :id            => :AlwaysMale,
  :name          => _INTL("Siempre Macho")
})

GameData::GenderRatio.register({
  :id            => :AlwaysFemale,
  :name          => _INTL("Siempre Hembra")
})

GameData::GenderRatio.register({
  :id            => :Genderless,
  :name          => _INTL("Sin Género")
})

GameData::GenderRatio.register({
  :id            => :FemaleOneEighth,
  :name          => _INTL("Hembra 1 de cada 8"),
  :female_chance => 32
})

GameData::GenderRatio.register({
  :id            => :Female25Percent,
  :name          => _INTL("25% Hembra"),
  :female_chance => 64
})

GameData::GenderRatio.register({
  :id            => :Female50Percent,
  :name          => _INTL("50% Hembra"),
  :female_chance => 128
})

GameData::GenderRatio.register({
  :id            => :Female75Percent,
  :name          => _INTL("75% Hembra"),
  :female_chance => 192
})

GameData::GenderRatio.register({
  :id            => :FemaleSevenEighths,
  :name          => _INTL("Hembra 7 de cada 8"),
  :female_chance => 224
})

