module GameData
  class Trainer
    attr_reader :id
    attr_reader :trainer_type
    attr_reader :real_name
    attr_reader :version
    attr_reader :items
    attr_reader :real_lose_text
    attr_reader :real_lose_text_f
    attr_reader :pokemon
    attr_reader :pbs_file_suffix

    DATA = {}
    DATA_FILENAME = "trainers.dat"
    PBS_BASE_FILENAME = "trainers"

    # "Pokemon" is specially mentioned in def compile_trainers and def
    # write_trainers, and acts as a subheading for a particular Pokémon.
    SCHEMA = {
      "SectionName" => [:id,             "esU", :TrainerType],
      "Items"       => [:items,          "*e", :Item],
      "LoseText"    => [:real_lose_text, "q"],
      "LoseText_F"  => [:real_lose_text_f, "q"],
      "Pokemon"     => [:pokemon,        "ev", :Species]   # Species, level
    }
    # This schema is for definable properties of individual Pokémon (apart from
    # species and level which are above).
    SUB_SCHEMA = {
      "Form"         => [:form,            "u"],
      "Name"         => [:real_name,       "s"],
      "Moves"        => [:moves,           "*e", :Move],
      "Ability"      => [:ability,         "e", :Ability],
      "AbilityIndex" => [:ability_index,   "u"],
      "Item"         => [:item,            "e", :Item],
      "Gender"       => [:gender,          "e", {"M" => 0, "m" => 0, "Male" => 0, "male" => 0, "0" => 0,
                                                 "F" => 1, "f" => 1, "Female" => 1, "female" => 1, "1" => 1}],
      "Nature"       => [:nature,          "e", :Nature],
      "IV"           => [:iv,              "uUUUUU"],
      "EV"           => [:ev,              "uUUUUU"],
      "Happiness"    => [:happiness,       "u"],
      "Shiny"        => [:shininess,       "b"],
      "SuperShiny"   => [:super_shininess, "b"],
      "Shadow"       => [:shadowness,      "b"],
      "Ball"         => [:poke_ball,       "e", :Item]
    }

    extend ClassMethodsSymbols
    include InstanceMethods

    def self.sub_schema
      return SUB_SCHEMA
    end

    # @param tr_type [Symbol, String]
    # @param tr_name [String]
    # @param tr_version [Integer, nil]
    # @return [Boolean] whether the given other is defined as a self
    def self.exists?(tr_type, tr_name, tr_version = 0)
      validate tr_type => [Symbol, String]
      validate tr_name => [String]
      key = [tr_type.to_sym, tr_name, tr_version]
      return !self::DATA[key].nil?
    end

    # @param tr_type [Symbol, String]
    # @param tr_name [String]
    # @param tr_version [Integer, nil]
    # @return [self]
    def self.get(tr_type, tr_name, tr_version = 0)
      validate tr_type => [Symbol, String]
      validate tr_name => [String]
      key = [tr_type.to_sym, tr_name, tr_version]
      raise "Unknown trainer #{tr_type} #{tr_name} #{tr_version}." unless self::DATA.has_key?(key)
      return self::DATA[key]
    end

    # @param tr_type [Symbol, String]
    # @param tr_name [String]
    # @param tr_version [Integer, nil]
    # @return [self, nil]
    def self.try_get(tr_type, tr_name, tr_version = 0)
      validate tr_type => [Symbol, String]
      validate tr_name => [String]
      key = [tr_type.to_sym, tr_name, tr_version]
      return (self::DATA.has_key?(key)) ? self::DATA[key] : nil
    end

    def initialize(hash)
      @id                = hash[:id]
      @trainer_type      = hash[:trainer_type]
      @real_name         = hash[:real_name]        || ""
      @version           = hash[:version]          || 0
      @items             = hash[:items]            || []
      @real_lose_text    = hash[:real_lose_text]   || "..."
      @real_lose_text_f  = hash[:real_lose_text_f] || @real_lose_text 
      @pokemon           = hash[:pokemon]          || []
      @pokemon.each do |pkmn|
        GameData::Stat.each_main do |s|
          pkmn[:iv][s.id] ||= 0 if pkmn[:iv]
          pkmn[:ev][s.id] ||= 0 if pkmn[:ev]
        end
      end
      @pbs_file_suffix = hash[:pbs_file_suffix] || ""
    end

    # @return [String] the translated name of this trainer
    def name
      return pbGetMessageFromHash(MessageTypes::TRAINER_NAMES, @real_name)
    end

    # @return [String] the translated in-battle lose message of this trainer
    def lose_text
      speech = $player&.female? ? MessageTypes::TRAINER_SPEECHES_LOSE_F : MessageTypes::TRAINER_SPEECHES_LOSE
      text = $player&.female? && !nil_or_empty?(@real_lose_text_f) ? @real_lose_text_f : @real_lose_text
      return pbGetMessageFromHash(speech, text)
    end

    # Creates a battle-ready version of a trainer's data.
    # @return [Array] all information about a trainer in a usable form
    def to_trainer
      # Determine trainer's name
      tr_name = self.name
      Settings::RIVAL_NAMES.each do |rival|
        next if rival[0] != @trainer_type || !$game_variables[rival[1]].is_a?(String)
        tr_name = $game_variables[rival[1]]
        break
      end
      # Create trainer object
      trainer = NPCTrainer.new(tr_name, @trainer_type, @version)
      trainer.id        = $player.make_foreign_ID
      trainer.items     = @items.clone
      trainer.lose_text = self.lose_text
      # Create each Pokémon owned by the trainer
      @pokemon.each do |pkmn_data|
        species = GameData::Species.get(pkmn_data[:species]).species
        pkmn = Pokemon.new(species, pkmn_data[:level], trainer, false)
        trainer.party.push(pkmn)
        # Set Pokémon's properties if defined
        if pkmn_data[:form]
          pkmn.forced_form = pkmn_data[:form] if MultipleForms.hasFunction?(species, "getForm")
          pkmn.form_simple = pkmn_data[:form]
        end
        pkmn.time_form_set = pbGetTimeNow.to_i   # To allow Furfrou/Hoopa alternate forms
        pkmn.item = pkmn_data[:item]
        if pkmn_data[:moves] && pkmn_data[:moves].length > 0
          pkmn_data[:moves].each { |move| pkmn.learn_move(move) }
        else
          pkmn.reset_moves
        end
        pkmn.ability_index = pkmn_data[:ability_index] || 0
        pkmn.ability = pkmn_data[:ability]
        pkmn.gender = pkmn_data[:gender] || ((trainer.male?) ? 0 : 1)
        pkmn.shiny = (pkmn_data[:shininess]) ? true : false
        pkmn.super_shiny = (pkmn_data[:super_shininess]) ? true : false
        if pkmn_data[:nature]
          pkmn.nature = pkmn_data[:nature]
        else   # Make the nature random but consistent for the same species used by the same trainer type
          species_num = GameData::Species.keys.index(species) || 1
          tr_type_num = GameData::TrainerType.keys.index(@trainer_type) || 1
          idx = (species_num + tr_type_num) % GameData::Nature.count
          pkmn.nature = GameData::Nature.get(GameData::Nature.keys[idx]).id
        end
        GameData::Stat.each_main do |s|
          if pkmn_data[:iv]
            pkmn.iv[s.id] = pkmn_data[:iv][s.id]
          else
            pkmn.iv[s.id] = [pkmn_data[:level] / 2, Pokemon::IV_STAT_LIMIT].min
          end
          if pkmn_data[:ev]
            pkmn.ev[s.id] = pkmn_data[:ev][s.id]
          else
            pkmn.ev[s.id] = [pkmn_data[:level] * 3 / 2, Pokemon::EV_LIMIT / 6].min
          end
        end
        pkmn.happiness = pkmn_data[:happiness] if pkmn_data[:happiness]
        if !nil_or_empty?(pkmn_data[:real_name])
          pkmn.name = pbGetMessageFromHash(MessageTypes::POKEMON_NICKNAMES, pkmn_data[:real_name])
        end
        if pkmn_data[:shadowness]
          pkmn.makeShadow
          pkmn.shiny = false
        end
        pkmn.poke_ball = pkmn_data[:poke_ball] if pkmn_data[:poke_ball]
        pkmn.form   # Called just to recalculate it in case a defined property has changed it, e.g. gender for Espurr
        pkmn.reset_moves if !pkmn_data[:moves] || pkmn_data[:moves].empty?   # In case form changed
        pkmn.calc_stats
      end
      return trainer
    end

    alias __orig__get_property_for_PBS get_property_for_PBS unless method_defined?(:__orig__get_property_for_PBS)
    def get_property_for_PBS(key, index = 0)
      ret = __orig__get_property_for_PBS(key)
      case key
      when "SectionName"
        ret = [@trainer_type, @real_name] if @version == 0
      when "Pokemon"
        ret = [@pokemon[index][:species], @pokemon[index][:level]]
      end
      return ret
    end

    def get_pokemon_property_for_PBS(key, index = 0)
      return [@pokemon[index][:species], @pokemon[index][:level]] if key == "Pokemon"
      ret = @pokemon[index][SUB_SCHEMA[key][0]]
      ret = nil if ret == false || (ret.is_a?(Array) && ret.length == 0) || ret == ""
      case key
      when "Gender"
        ret = ["male", "female"][ret] if ret
      when "IV", "EV"
        if ret
          new_ret = []
          GameData::Stat.each_main do |s|
            new_ret[s.pbs_order] = ret[s.id] if s.pbs_order >= 0
          end
          ret = new_ret
        end
      when "Shiny"
        ret = nil if @pokemon[index][:super_shininess]
      end
      return ret
    end
  end
end
