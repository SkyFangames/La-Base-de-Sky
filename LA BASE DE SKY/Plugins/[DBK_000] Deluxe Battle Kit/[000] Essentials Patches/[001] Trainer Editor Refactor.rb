#===============================================================================
# Restructures the trainer Pokemon editor so that plugins may add new properties.
#===============================================================================
module TrainerPokemonProperty
  #-----------------------------------------------------------------------------
  # Returns initial settings and associated keys for a trainer's Pokemon.
  #-----------------------------------------------------------------------------
  def self.editor_settings(initsetting)
    initsetting = {:species => nil, :level => 10} if !initsetting
    oldsetting = [
      initsetting[:species],
      initsetting[:level],
      initsetting[:real_name],
      initsetting[:form],
      initsetting[:gender],
      initsetting[:shininess],
      initsetting[:super_shininess],
      initsetting[:shadowness]
    ]
    keys = [
      :species, :level, :real_name, :form, :gender, 
      :shininess, :super_shininess, :shadowness
    ]
    Pokemon::MAX_MOVES.times do |i|
      oldsetting.push((initsetting[:moves]) ? initsetting[:moves][i] : nil)
      keys.push(:moves)
    end
    oldsetting.concat([
      initsetting[:ability],
      initsetting[:ability_index],
      initsetting[:item],
      initsetting[:nature],
      initsetting[:iv],
      initsetting[:ev],
      initsetting[:happiness],
      initsetting[:poke_ball]
    ])
    keys.push(
      :ability, :ability_index, :item, :nature,
      :iv, :ev, :happiness, :poke_ball
    )
    return oldsetting, keys
  end
  
  #-----------------------------------------------------------------------------
  # Returns all of the editor properties for a trainer's Pokemon.
  #-----------------------------------------------------------------------------
  def self.editor_properties(oldsetting)
    max_level = GameData::GrowthRate.max_level
    properties = [
      [_INTL("Species"),    SpeciesProperty,                     _INTL("Species of the Pokémon.")],
      [_INTL("Level"),      NonzeroLimitProperty.new(max_level), _INTL("Level of the Pokémon (1-{1}).", max_level)],
      [_INTL("Name"),       StringProperty,                      _INTL("Nickname of the Pokémon.")],
      [_INTL("Form"),       LimitProperty2.new(999),             _INTL("Form of the Pokémon.")],
      [_INTL("Gender"),     GenderProperty,                      _INTL("Gender of the Pokémon.")],
      [_INTL("Shiny"),      BooleanProperty2,                    _INTL("If set to true, the Pokémon is a different-colored Pokémon.")],
      [_INTL("SuperShiny"), BooleanProperty2,                    _INTL("Whether the Pokémon is super shiny (shiny with a special shininess animation).")],
      [_INTL("Shadow"),     BooleanProperty2,                    _INTL("If set to true, the Pokémon is a Shadow Pokémon.")]
    ]
    Pokemon::MAX_MOVES.times do |i|
      properties.push([_INTL("Move {1}", i + 1),
                       MovePropertyForSpecies.new(oldsetting), _INTL("A move known by the Pokémon. Leave all moves blank (use Z key to delete) for a wild moveset.")])
    end
    properties.concat([
      [_INTL("Ability"),       AbilityProperty,                         _INTL("Ability of the Pokémon. Overrides the ability index.")],
      [_INTL("Ability index"), LimitProperty2.new(99),                  _INTL("Ability index. 0=first ability, 1=second ability, 2+=hidden ability.")],
      [_INTL("Held item"),     ItemProperty,                            _INTL("Item held by the Pokémon.")],
      [_INTL("Nature"),        GameDataProperty.new(:Nature),           _INTL("Nature of the Pokémon.")],
      [_INTL("IVs"),           IVsProperty.new(Pokemon::IV_STAT_LIMIT), _INTL("Individual values for each of the Pokémon's stats.")],
      [_INTL("EVs"),           EVsProperty.new(Pokemon::EV_STAT_LIMIT), _INTL("Effort values for each of the Pokémon's stats.")],
      [_INTL("Happiness"),     LimitProperty2.new(255),                 _INTL("Happiness of the Pokémon (0-255).")],
      [_INTL("Poké Ball"),     BallProperty.new(oldsetting),            _INTL("The kind of Poké Ball the Pokémon is kept in.")]
    ])
    return properties
  end
  
  #-----------------------------------------------------------------------------
  # Rewritten editor for trainer's Pokemon.
  #-----------------------------------------------------------------------------
  def self.set(settingname, initsetting)
    oldsetting, keys = self.editor_settings(initsetting)
    pkmn_properties = self.editor_properties(oldsetting)
    pbPropertyList(settingname, oldsetting, pkmn_properties, false)
    return nil if !oldsetting[0]
    ret = {}
    keys.each_with_index do |key, i|
      case key
      when :moves
        ret[key] = [] if !ret[key]
        ret[key].push(oldsetting[i])
      else
        ret[key] = oldsetting[i]
      end
    end
    ret[:moves].uniq!
    ret[:moves].compact!
    return ret
  end
end

#===============================================================================
# Fix for partner trainers not inheriting inventories set in PBS data.
#===============================================================================
module BattleCreationHelperMethods
  module_function
  
  def set_up_player_trainers(foe_party)
    trainer_array = [$player]
    ally_items    = []
    pokemon_array = $player.party
    party_starts  = [0]
    if partner_can_participate?(foe_party)
      ally = NPCTrainer.new($PokemonGlobal.partner[1], $PokemonGlobal.partner[0])
      ally.id    = $PokemonGlobal.partner[2]
      ally.party = $PokemonGlobal.partner[3]
      ally_items[1] = $PokemonGlobal.partner[4].clone
      trainer_array.push(ally)
      pokemon_array = []
      $player.party.each { |pkmn| pokemon_array.push(pkmn) }
      party_starts.push(pokemon_array.length)
      ally.party.each { |pkmn| pokemon_array.push(pkmn) }
      setBattleRule("double") if $game_temp.battle_rules["size"].nil?
    end
    return trainer_array, ally_items, pokemon_array, party_starts
  end
end

def pbRegisterPartner(tr_type, tr_name, tr_id = 0)
  tr_type = GameData::TrainerType.get(tr_type).id
  pbCancelVehicles
  trainer = pbLoadTrainer(tr_type, tr_name, tr_id)
  EventHandlers.trigger(:on_trainer_load, trainer)
  trainer.party.each do |i|
    i.owner = Pokemon::Owner.new_from_trainer(trainer)
    i.calc_stats
  end
  $PokemonGlobal.partner = [tr_type, tr_name, trainer.id, trainer.party, trainer.items]
end