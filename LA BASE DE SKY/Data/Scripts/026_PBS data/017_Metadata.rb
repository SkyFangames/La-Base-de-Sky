module GameData
  class Metadata
    attr_reader :id
    attr_reader :start_money
    attr_reader :start_item_storage
    attr_reader :home
    attr_reader :real_storage_creator
    attr_reader :wild_battle_BGM
    attr_reader :trainer_battle_BGM
    attr_reader :wild_victory_BGM
    attr_reader :trainer_victory_BGM
    attr_reader :wild_capture_ME
    attr_reader :surf_BGM
    attr_reader :bicycle_BGM
    attr_reader :pbs_file_suffix

    DATA = {}
    DATA_FILENAME = "metadata.dat"
    PBS_BASE_FILENAME = "metadata"

    SCHEMA = {
      "SectionName"       => [:id,                   "u"],
      "StartMoney"        => [:start_money,          "u"],
      "StartItemStorage"  => [:start_item_storage,   "*e", :Item],
      "Home"              => [:home,                 "vuuu"],
      "StorageCreator"    => [:real_storage_creator, "s"],
      "WildBattleBGM"     => [:wild_battle_BGM,      "s"],
      "TrainerBattleBGM"  => [:trainer_battle_BGM,   "s"],
      "WildVictoryBGM"    => [:wild_victory_BGM,     "s"],
      "TrainerVictoryBGM" => [:trainer_victory_BGM,  "s"],
      "WildCaptureME"     => [:wild_capture_ME,      "s"],
      "SurfBGM"           => [:surf_BGM,             "s"],
      "BicycleBGM"        => [:bicycle_BGM,          "s"]
    }

    extend ClassMethodsIDNumbers
    include InstanceMethods

    def self.editor_properties
      return [
        ["StartMoney",        LimitProperty.new(Settings::MAX_MONEY), _INTL("La cantidad de dinero con la que el jugador comienza el juego.")],
        ["StartItemStorage",  GameDataPoolProperty.new(:Item),        _INTL("Objetos que ya están en el PC del jugador al comienzo del juego.")],
        ["Home",              MapCoordsFacingProperty, _INTL("ID del mapa y coordenadas X/Y de dónde va el jugador después de una pérdida si no se visitó ningún Centro Pokémon.")],
        ["StorageCreator",    StringProperty,          _INTL("Nombre del creador del Sistema de Almacenamiento Pokémon (la opción de almacenamiento se llama \"PC de XXX\").")],
        ["WildBattleBGM",     BGMProperty,             _INTL("Música de fondo predeterminada para combates de Pokémon salvajes.")],
        ["TrainerBattleBGM",  BGMProperty,             _INTL("Música de fondo predeterminada para los combates de entrenadores.")],
        ["WildVictoryBGM",    BGMProperty,             _INTL("Música de fondo predeterminada que se reproduce después de ganar un combate de Pokémon salvajes.")],
        ["TrainerVictoryBGM", BGMProperty,             _INTL("Música de fondo predeterminada que se reproduce después de ganar un combate de entrenador.")],
        ["WildCaptureME",     MEProperty,              _INTL("Efecto musical predeterminado que se reproduce después de atrapar un Pokémon.")],
        ["SurfBGM",           BGMProperty,             _INTL("Música de fondo reproducida mientras surfeas.")],
        ["BicycleBGM",        BGMProperty,             _INTL("Música de fondo reproducida mientras montas en bicicleta.")]
      ]
    end

    def self.get
      return DATA[0]
    end

    def initialize(hash)
      @id                   = hash[:id]                 || 0
      @start_money          = hash[:start_money]        || 3000
      @start_item_storage   = hash[:start_item_storage] || []
      @home                 = hash[:home]
      @real_storage_creator = hash[:real_storage_creator]
      @wild_battle_BGM      = hash[:wild_battle_BGM]
      @trainer_battle_BGM   = hash[:trainer_battle_BGM]
      @wild_victory_BGM     = hash[:wild_victory_BGM]
      @trainer_victory_BGM  = hash[:trainer_victory_BGM]
      @wild_capture_ME      = hash[:wild_capture_ME]
      @surf_BGM             = hash[:surf_BGM]
      @bicycle_BGM          = hash[:bicycle_BGM]
      @pbs_file_suffix      = hash[:pbs_file_suffix]    || ""
    end

    # @return [String] the translated name of the Pokémon Storage creator
    def storage_creator
      ret = pbGetMessageFromHash(MessageTypes::STORAGE_CREATOR_NAME, @real_storage_creator)
      return nil_or_empty?(ret) ? _INTL("Bill") : ret
    end
  end
end
