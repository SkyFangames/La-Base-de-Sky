# These are in-battle terrain effects caused by moves like Electric Terrain.
module GameData
  class BattleTerrain
    attr_reader :id
    attr_reader :real_name
    attr_reader :animation

    DATA = {}

    extend ClassMethodsSymbols
    include InstanceMethods

    def self.load; end
    def self.save; end

    def initialize(hash)
      @id        = hash[:id]
      @real_name = hash[:name] || "Sin nombre"
      @animation = hash[:animation]
    end

    # @return [String] the translated name of this battle terrain
    def name
      return _INTL(@real_name)
    end
  end
end

#===============================================================================

GameData::BattleTerrain.register({
  :id   => :None,
  :name => _INTL("Ninguno")
})

GameData::BattleTerrain.register({
  :id        => :Electric,
  :name      => _INTL("Eléctrico"),
  :animation => "ElectricTerrain"
})

GameData::BattleTerrain.register({
  :id        => :Grassy,
  :name      => _INTL("de Planta"),
  :animation => "GrassyTerrain"
})

GameData::BattleTerrain.register({
  :id        => :Misty,
  :name      => _INTL("de Niebla"),
  :animation => "MistyTerrain"
})

GameData::BattleTerrain.register({
  :id        => :Psychic,
  :name      => _INTL("Psíquico"),
  :animation => "PsychicTerrain"
})

