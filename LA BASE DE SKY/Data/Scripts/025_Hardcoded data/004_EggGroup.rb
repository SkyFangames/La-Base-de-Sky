module GameData
  class EggGroup
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

    # @return [String] el nombre traducido del grupo huevo
    def name
      return _INTL(@real_name)
    end
  end
end

#===============================================================================

GameData::EggGroup.register({
  :id   => :Undiscovered,
  :name => _INTL("Desconocido")
})

GameData::EggGroup.register({
  :id   => :Monster,
  :name => _INTL("Monstruo")
})

GameData::EggGroup.register({
  :id   => :Water1,
  :name => _INTL("Agua 1")
})

GameData::EggGroup.register({
  :id   => :Bug,
  :name => _INTL("Bicho")
})

GameData::EggGroup.register({
  :id   => :Flying,
  :name => _INTL("Volador")
})

GameData::EggGroup.register({
  :id   => :Field,
  :name => _INTL("Campo")
})

GameData::EggGroup.register({
  :id   => :Fairy,
  :name => _INTL("Hada")
})

GameData::EggGroup.register({
  :id   => :Grass,
  :name => _INTL("Planta")
})

GameData::EggGroup.register({
  :id   => :Humanlike,
  :name => _INTL("Humanoide")
})

GameData::EggGroup.register({
  :id   => :Water3,
  :name => _INTL("Agua 3")
})

GameData::EggGroup.register({
  :id   => :Mineral,
  :name => _INTL("Mineral")
})

GameData::EggGroup.register({
  :id   => :Amorphous,
  :name => _INTL("Amorfo")
})

GameData::EggGroup.register({
  :id   => :Water2,
  :name => _INTL("Agua 2")
})

GameData::EggGroup.register({
  :id   => :Ditto,
  :name => _INTL("Ditto")
})

GameData::EggGroup.register({
  :id   => :Dragon,
  :name => _INTL("Dragón")
})

