module GameData
  class Habitat
    attr_reader :id
    attr_reader :real_name

    DATA = {}

    extend ClassMethodsSymbols
    include InstanceMethods

    def self.load; end
    def self.save; end

    def initialize(hash)
      @id        = hash[:id]
      @real_name = hash[:name] || "Sin nombre"
    end

    # @return [String] the translated name of this habitat
    def name
      return _INTL(@real_name)
    end
  end
end

#===============================================================================

GameData::Habitat.register({
  :id   => :None,
  :name => _INTL("Ninguno")
})

GameData::Habitat.register({
  :id   => :Grassland,
  :name => _INTL("Pradera")
})

GameData::Habitat.register({
  :id   => :Forest,
  :name => _INTL("Bosque")
})

GameData::Habitat.register({
  :id   => :WatersEdge,
  :name => _INTL("Agua dulce")
})

GameData::Habitat.register({
  :id   => :Sea,
  :name => _INTL("Agua salada")
})

GameData::Habitat.register({
  :id   => :Cave,
  :name => _INTL("Cueva")
})

GameData::Habitat.register({
  :id   => :Mountain,
  :name => _INTL("Montaña")
})

GameData::Habitat.register({
  :id   => :RoughTerrain,
  :name => _INTL("Campo")
})

GameData::Habitat.register({
  :id   => :Urban,
  :name => _INTL("Ciudad")
})

GameData::Habitat.register({
  :id   => :Rare,
  :name => _INTL("Raros")
})

