module GameData
  class PlayerMetadata
    attr_reader :id
    attr_reader :trainer_type
    attr_reader :walk_charset
    attr_reader :home
    attr_reader :pbs_file_suffix

    DATA = {}
    DATA_FILENAME = "player_metadata.dat"

    SCHEMA = {
      "SectionName"     => [:id,                "u"],
      "TrainerType"     => [:trainer_type,      "e", :TrainerType],
      "WalkCharset"     => [:walk_charset,      "s"],
      "RunCharset"      => [:run_charset,       "s"],
      "CycleCharset"    => [:cycle_charset,     "s"],
      "SurfCharset"     => [:surf_charset,      "s"],
      "DiveCharset"     => [:dive_charset,      "s"],
      "FishCharset"     => [:fish_charset,      "s"],
      "SurfFishCharset" => [:surf_fish_charset, "s"],
      "Home"            => [:home,              "vuuu"]
    }

    extend ClassMethodsIDNumbers
    include InstanceMethods

    def self.editor_properties
      return [
        ["ID",              ReadOnlyProperty,        _INTL("ID de este jugador.")],
        ["TrainerType",     TrainerTypeProperty,     _INTL("Tipo de entrenador de este jugador.")],
        ["WalkCharset",     CharacterProperty,       _INTL("Sprites usados mientras el jugador está quieto o caminando.")],
        ["RunCharset",      CharacterProperty,       _INTL("Sprites usados mientras el jugador está corriendo. Utiliza el sprite de caminar (WalkCharset) si no está definido.")],
        ["CycleCharset",    CharacterProperty,       _INTL("Sprites usados mientras el jugador está montado en bici. Utiliza el sprite de correr (RunCharset) si no está definido.")],
        ["SurfCharset",     CharacterProperty,       _INTL("Sprites usados mientras el jugador está surfeando. Utiliza el sprite de montar en bici (CycleCharset) si no está definido.")],
        ["DiveCharset",     CharacterProperty,       _INTL("Sprites usados mientras el jugador está haciendo buceo.Utiliza el sprite de surfear (SurfCharset) si no está definido.")],
        ["FishCharset",     CharacterProperty,       _INTL("Sprites usados mientras el jugador está pescando. Utiliza el sprite de caminar (WalkCharset) si no está definido.")],
        ["SurfFishCharset", CharacterProperty,       _INTL("Sprites usados mientras el jugador está pescando mientras surfea. Utiliza el sprite de pescar (FishCharset) si no está definido.")],
        ["Home",            MapCoordsFacingProperty, _INTL("ID del mapa y coordenadas X/Y de dónde va el jugador después de una pérdida si no se visitó ningún Centro Pokémon.")]
      ]
    end

    # @param player_id [Integer]
    # @return [self, nil]
    def self.get(player_id = 1)
      validate player_id => Integer
      return self::DATA[player_id] if self::DATA.has_key?(player_id)
      return self::DATA[1]
    end

    def initialize(hash)
      @id                = hash[:id]
      @trainer_type      = hash[:trainer_type]
      @walk_charset      = hash[:walk_charset]
      @run_charset       = hash[:run_charset]
      @cycle_charset     = hash[:cycle_charset]
      @surf_charset      = hash[:surf_charset]
      @dive_charset      = hash[:dive_charset]
      @fish_charset      = hash[:fish_charset]
      @surf_fish_charset = hash[:surf_fish_charset]
      @home              = hash[:home]
      @pbs_file_suffix   = hash[:pbs_file_suffix] || ""
    end

    def run_charset
      return @run_charset || @walk_charset
    end

    def cycle_charset
      return @cycle_charset || run_charset
    end

    def surf_charset
      return @surf_charset || cycle_charset
    end

    def dive_charset
      return @dive_charset || surf_charset
    end

    def fish_charset
      return @fish_charset || @walk_charset
    end

    def surf_fish_charset
      return @surf_fish_charset || fish_charset
    end

    alias __orig__get_property_for_PBS get_property_for_PBS unless method_defined?(:__orig__get_property_for_PBS)
    def get_property_for_PBS(key)
      key = "SectionName" if key == "ID"
      return __orig__get_property_for_PBS(key)
    end
  end
end
