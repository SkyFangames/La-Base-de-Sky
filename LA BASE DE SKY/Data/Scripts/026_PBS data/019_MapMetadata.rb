module GameData
  class MapMetadata
    attr_reader :id
    attr_reader :real_name
    attr_reader :outdoor_map
    attr_reader :announce_location
    attr_reader :can_bicycle
    attr_reader :always_bicycle
    attr_reader :teleport_destination
    attr_reader :weather
    attr_reader :town_map_position
    attr_reader :dive_map_id
    attr_reader :dark_map
    attr_reader :safari_map
    attr_reader :snap_edges
    attr_reader :still_reflections
    attr_reader :random_dungeon
    attr_reader :battle_background
    attr_reader :wild_battle_BGM
    attr_reader :trainer_battle_BGM
    attr_reader :wild_victory_BGM
    attr_reader :trainer_victory_BGM
    attr_reader :wild_capture_ME
    attr_reader :town_map_size
    attr_reader :battle_environment
    attr_reader :flags
    attr_reader :pbs_file_suffix

    DATA = {}
    DATA_FILENAME = "map_metadata.dat"
    PBS_BASE_FILENAME = "map_metadata"

    SCHEMA = {
      "SectionName"       => [:id,                   "u"],
      "Name"              => [:real_name,            "s"],
      "Outdoor"           => [:outdoor_map,          "b"],
      "ShowArea"          => [:announce_location,    "b"],
      "Bicycle"           => [:can_bicycle,          "b"],
      "BicycleAlways"     => [:always_bicycle,       "b"],
      "HealingSpot"       => [:teleport_destination, "vuu"],
      "Weather"           => [:weather,              "eu", :Weather],
      "MapPosition"       => [:town_map_position,    "uuu"],
      "DiveMap"           => [:dive_map_id,          "v"],
      "DarkMap"           => [:dark_map,             "b"],
      "SafariMap"         => [:safari_map,           "b"],
      "SnapEdges"         => [:snap_edges,           "b"],
      "StillReflections"  => [:still_reflections,    "b"],
      "Dungeon"           => [:random_dungeon,       "b"],
      "BattleBack"        => [:battle_background,    "s"],
      "WildBattleBGM"     => [:wild_battle_BGM,      "s"],
      "TrainerBattleBGM"  => [:trainer_battle_BGM,   "s"],
      "WildVictoryBGM"    => [:wild_victory_BGM,     "s"],
      "TrainerVictoryBGM" => [:trainer_victory_BGM,  "s"],
      "WildCaptureME"     => [:wild_capture_ME,      "s"],
      "MapSize"           => [:town_map_size,        "us"],
      "Environment"       => [:battle_environment,   "e", :Environment],
      "Flags"             => [:flags,                "*s"]
    }

    extend ClassMethodsIDNumbers
    include InstanceMethods

    def self.editor_properties
      return [
        ["ID",                ReadOnlyProperty,        _INTL("ID de este mapa.")],
        ["Name",              StringProperty,          _INTL("El nombre del mapa, tal como lo ve el jugador. Puede ser diferente al nombre del mapa como se ve en RMXP.")],
        ["Outdoor",           BooleanProperty,         _INTL("Si su valor es true, este mapa es un mapa de exteriores y se coloreará según la hora del día.")],
        ["ShowArea",          BooleanProperty,         _INTL("Si su valor es true, el juego mostrará el nombre del mapa al ingresar.")],
        ["Bicycle",           BooleanProperty,         _INTL("Si su valor es true, la bicicleta se puede utilizar en este mapa.")],
        ["BicycleAlways",     BooleanProperty,         _INTL("Si su valor es true, la bicicleta se montará automáticamente en este mapa y no se podrá desmontar.")],
        ["HealingSpot",       MapCoordsProperty,       _INTL("ID del mapa de la ciudad de este Centro Pokémon y coordenadas X e Y de su entrada dentro de esa ciudad.")],
        ["Weather",           WeatherEffectProperty,   _INTL("Condiciones meteorológicas vigentes para este mapa.")],
        ["MapPosition",       RegionMapCoordsProperty, _INTL("Identifica el punto en el mapa regional para este mapa.")],
        ["DiveMap",           MapProperty,             _INTL("Especifica la capa submarina de este mapa. Úselo solo si este mapa tiene aguas profundas.")],
        ["DarkMap",           BooleanProperty,         _INTL("Si su valor es true, este mapa está oscuro y aparece un círculo de luz alrededor del jugador. Se puede utilizar Flash para ampliar el círculo.")],
        ["SafariMap",         BooleanProperty,         _INTL("Si su valor es true, este mapa es parte de la Zona Safari (tanto interior como exterior). No debe utilizarse en el mostrador de recepción.")],
        ["SnapEdges",         BooleanProperty,         _INTL("Si su valor es true, cuando el jugador se acerca al borde de este mapa, el juego no centra al jugador como de costumbre.")],
        ["StillReflections",  BooleanProperty,         _INTL("Si su valor es true, Los reflejos de los eventos y el jugador no se se extenderán horizontalmente.")],
        ["Dungeon",           BooleanProperty,         _INTL("Si su valor es true, este mapa tiene un diseño generado aleatoriamente. Consulta la wiki para obtener más información.")],
        ["BattleBack",        StringProperty,          _INTL("Archivos PNG llamados 'XXX_bg', 'XXX_base0', 'XXX_base1', 'XXX_message' en la carpeta Battlebacks, donde XXX es el valor de esta propiedad.")],
        ["WildBattleBGM",     BGMProperty,             _INTL("Música de fondo predeterminada para combates de Pokémon salvajes en este mapa.")],
        ["TrainerBattleBGM",  BGMProperty,             _INTL("Música de fondo predeterminada para los combates de entrenadores en este mapa.")],
        ["WildVictoryBGM",    BGMProperty,             _INTL("Música de fondo predeterminada reproducida después de ganar un combate de Pokémon salvajes en este mapa.")],
        ["TrainerVictoryBGM", BGMProperty,             _INTL("Música de fondo predeterminada reproducida después de ganar un combate de entrenador en este mapa.")],
        ["WildCaptureME",     MEProperty,              _INTL("Efecto musical predeterminado que se reproduce después de capturar un Pokémon salvaje en este mapa.")],
        ["MapSize",           MapSizeProperty,         _INTL("El ancho del mapa en los cuadrados del mapa de la ciudad y una cadena que indica qué cuadrados forman parte de este mapa.")],
        ["Environment",       GameDataProperty.new(:Environment), _INTL("El entorno de batalla predeterminado para los combates en este mapa.")],
        ["Flags",             StringListProperty,      _INTL("Palabras/frases que distinguen este mapa de otros.")]
      ]
    end

    def initialize(hash)
      @id                   = hash[:id]
      @real_name            = hash[:real_name]
      @outdoor_map          = hash[:outdoor_map]
      @announce_location    = hash[:announce_location]
      @can_bicycle          = hash[:can_bicycle]
      @always_bicycle       = hash[:always_bicycle]
      @teleport_destination = hash[:teleport_destination]
      @weather              = hash[:weather]
      @town_map_position    = hash[:town_map_position]
      @dive_map_id          = hash[:dive_map_id]
      @dark_map             = hash[:dark_map]
      @safari_map           = hash[:safari_map]
      @snap_edges           = hash[:snap_edges]
      @still_reflections    = hash[:still_reflections]
      @random_dungeon       = hash[:random_dungeon]
      @battle_background    = hash[:battle_background]
      @wild_battle_BGM      = hash[:wild_battle_BGM]
      @trainer_battle_BGM   = hash[:trainer_battle_BGM]
      @wild_victory_BGM     = hash[:wild_victory_BGM]
      @trainer_victory_BGM  = hash[:trainer_victory_BGM]
      @wild_capture_ME      = hash[:wild_capture_ME]
      @town_map_size        = hash[:town_map_size]
      @battle_environment   = hash[:battle_environment]
      @flags                = hash[:flags]           || []
      @pbs_file_suffix      = hash[:pbs_file_suffix] || ""
    end

    # @return [String] the translated name of this map
    def name
      ret = pbGetMessageFromHash(MessageTypes::MAP_NAMES, @real_name)
      ret = pbGetBasicMapNameFromId(@id) if nil_or_empty?(ret)
      ret.gsub!(/\\PN/, $player.name) if $player
      return ret
    end

    def has_flag?(flag)
      return @flags.any? { |f| f.downcase == flag.downcase }
    end

    alias __orig__get_property_for_PBS get_property_for_PBS unless method_defined?(:__orig__get_property_for_PBS)
    def get_property_for_PBS(key)
      key = "SectionName" if key == "ID"
      return __orig__get_property_for_PBS(key)
    end
  end
end

