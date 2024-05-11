module GameData
  class Environment
    attr_reader :id
    attr_reader :real_name
    attr_reader :battle_base

    DATA = {}

    extend ClassMethodsSymbols
    include InstanceMethods

    def self.load; end
    def self.save; end

    def initialize(hash)
      @id          = hash[:id]
      @real_name   = hash[:name] || "Sin nombre"
      @battle_base = hash[:battle_base]
    end

    # @return [String] the translated name of this environment
    def name
      return _INTL(@real_name)
    end
  end
end

#===============================================================================

GameData::Environment.register({
  :id   => :None,
  :name => _INTL("Ninguno")
})

GameData::Environment.register({
  :id          => :Grass,
  :name        => _INTL("Hierba"),
  :battle_base => "grass"
})

GameData::Environment.register({
  :id          => :TallGrass,
  :name        => _INTL("Hierba alta"),
  :battle_base => "grass"
})

GameData::Environment.register({
  :id          => :MovingWater,
  :name        => _INTL("Agua móvil"),
  :battle_base => "water"
})

GameData::Environment.register({
  :id          => :StillWater,
  :name        => _INTL("Agua estática"),
  :battle_base => "water"
})

GameData::Environment.register({
  :id          => :Puddle,
  :name        => _INTL("Charco"),
  :battle_base => "puddle"
})

GameData::Environment.register({
  :id   => :Underwater,
  :name => _INTL("Submarino")
})

GameData::Environment.register({
  :id   => :Cave,
  :name => _INTL("Cueva")
})

GameData::Environment.register({
  :id   => :Rock,
  :name => _INTL("Roca")
})

GameData::Environment.register({
  :id          => :Sand,
  :name        => _INTL("Arena"),
  :battle_base => "sand"
})

GameData::Environment.register({
  :id   => :Forest,
  :name => _INTL("Bosque")
})

GameData::Environment.register({
  :id          => :ForestGrass,
  :name        => _INTL("Hierba de bosque"),
  :battle_base => "grass"
})

GameData::Environment.register({
  :id   => :Snow,
  :name => _INTL("Nieve")
})

GameData::Environment.register({
  :id          => :Ice,
  :name        => _INTL("Hielo"),
  :battle_base => "ice"
})

GameData::Environment.register({
  :id   => :Volcano,
  :name => _INTL("Volcán")
})

GameData::Environment.register({
  :id   => :Graveyard,
  :name => _INTL("Cementerio")
})

GameData::Environment.register({
  :id   => :Sky,
  :name => _INTL("Cielo")
})

GameData::Environment.register({
  :id   => :Space,
  :name => _INTL("Espacio")
})

GameData::Environment.register({
  :id   => :UltraSpace,
  :name => _INTL("Ultraespacio")
})

