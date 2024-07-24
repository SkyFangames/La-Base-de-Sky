#-------------------------------------------------------------------------------
# Habilidades
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Override game switch logic to randomize data when value changed
#-------------------------------------------------------------------------------
class Game_Switches
  alias __randomize__set_switch []= unless method_defined?(:__randomize__set_switch)
  def []=(switch_id, value)
    old_value = self[switch_id]
    ret = __randomize__set_switch(switch_id, value)
    if (switch_id == RandomizedChallenge::ABILITY_RANDOMIZER_SWITCH ||
      switch_id == RandomizedChallenge::ABILITY_SEMI_RANDOMIZER_SWITCH) &&
      value != old_value
      RandomizedChallenge::Ability.reset_randomized_data
    end
    return ret
  end
end

#-------------------------------------------------------------------------------
# Main module to handle radomization of abilities
#-------------------------------------------------------------------------------

module RandomizedChallenge::Ability
  #-----------------------------------------------------------------------------
  # Load randomized ability based on species data
  #-----------------------------------------------------------------------------
  def self.get(key, default, hidden = false)
    # Load default data when switch is off
    return default if !$game_switches || !$game_switches[RandomizedChallenge::ABILITY_RANDOMIZER_SWITCH]
    # Load randomized data if exists
    all_abils = self.get_randomized_data
    ret = all_abils[key]
    return ret[hidden ? :hidden : :base] if GameData::Species.exists?(key) && ret.is_a?(Hash)
    return default
  end
  #-----------------------------------------------------------------------------
  # Load all randomized abilities
  #-----------------------------------------------------------------------------
  def self.get_randomized_data
    $randomized_data = {} if !$randomized_data
    if !$randomized_data[:abilities].is_a?(Hash)
      $randomized_data[:abilities] = {}
      keys = GameData::Ability::DATA.keys.clone
      shuffle_keys = keys.clone
      5.times { shuffle_keys.shuffle! }
      # Delete blacklisted abilities
      RandomizedChallenge::ABILITY_EXCLUSIONS.each do |a|
        shuffle_keys.delete(a)
      end
      if $game_switches[RandomizedChallenge::ABILITY_SEMI_RANDOMIZER_SWITCH]
        # Assign shuffled abilties to respective species
        GameData::Species.each do |sp_data|
          key = sp_data.id
          next if $randomized_data[:abilities][key].is_a?(Hash)
          first_species = sp_data.get_first_evo
          if $randomized_data[:abilities][first_species].is_a?(Hash)
            abil_hash = $randomized_data[:abilities][first_species]
          else
            $randomized_data[:abilities][key] = { :base => [], :hidden => [] }
            sp_data.real_abilities.each_with_index do |abil, i|
              $randomized_data[:abilities][key][:base][i] = shuffle_keys.sample
            end
            sp_data.real_hidden_abilities.each_with_index do |abil, i|
              $randomized_data[:abilities][key][:hidden][i] = shuffle_keys.sample
            end
            abil_hash = $randomized_data[:abilities][key]
          end
          if !$randomized_data[:abilities][key].is_a?(Hash)
            $randomized_data[:abilities][key] = { :base => [], :hidden => [] }
            sp_data.real_abilities.each_with_index do |abil, i|
              $randomized_data[:abilities][key][:base][i] = shuffle_keys.sample
            end
            sp_data.real_hidden_abilities.each_with_index do |abil, i|
              $randomized_data[:abilities][key][:hidden][i] = shuffle_keys.sample
            end
          end
          sp_data.get_evolutionary_line.each do |pkmn|
            next if $randomized_data[:abilities][pkmn].is_a?(Hash)
            $randomized_data[:abilities][pkmn] = { :base => [], :hidden => [] }
            $randomized_data[:abilities][pkmn][:base] = abil_hash[:base].clone
            $randomized_data[:abilities][pkmn][:hidden] = abil_hash[:hidden].clone
          end
        end
      elsif 1 > 100 # Change the condition here to be whatever
        # Shuffle abilities but keep blacklisted abilities unshuffled
        shuffle_keys.each_with_index do |abil, i|
          next if !RandomizedChallenge::ABILITY_EXCLUSIONS.include?(abil)
          abil = shuffle_keys.delete_at(i)
          shuffle_keys.insert(keys.index(abil), abil)
        end
        abil_hash = {}
        keys.each_with_index do |key, idx|
          abil_hash[key] = key
          next if RandomizedChallenge::ABILITY_EXCLUSIONS.include?(key)
          abil_hash[key] = shuffle_keys[idx]
        end
        # Assign shuffled abilties to respective species
        GameData::Species.each do |sp_data|
          key = sp_data.id
          $randomized_data[:abilities][key] = { :base => [], :hidden => [] }
          sp_data.real_abilities.each_with_index do |abil, i|
            $randomized_data[:abilities][key][:base][i] = abil_hash[abil]
          end
          sp_data.real_hidden_abilities.each_with_index do |abil, i|
            $randomized_data[:abilities][key][:hidden][i] = abil_hash[abil]
          end
        end
      else
        # Assign random abilities to each species
        GameData::Species.each do |sp_data|
          key = sp_data.id
          $randomized_data[:abilities][key] = { :base => [], :hidden => [] }
          sp_data.real_abilities.each_with_index do |abil, i|
            $randomized_data[:abilities][key][:base][i] = shuffle_keys.sample
          end
          sp_data.real_hidden_abilities.each_with_index do |abil, i|
            $randomized_data[:abilities][key][:hidden][i] = shuffle_keys.sample
          end
        end
      end
    end
    return $randomized_data[:abilities]
  end
  #-----------------------------------------------------------------------------
  # Reset randomized data
  #-----------------------------------------------------------------------------
  def self.reset_randomized_data
    # Clear randomized data
    $randomized_data[:abilities] = nil
    self.get_randomized_data
    # Unrandomize / Rerandomize player Pokemon abilities
    pbEachPokemon do |pkmn, _|
      old_idx = pkmn.ability_index
      pkmn.ability_index = nil
      pkmn.ability_index = old_idx
    end
  end
  #-----------------------------------------------------------------------------
end


#-------------------------------------------------------------------------------
# Overriding Species GameData to load new abilities
#-------------------------------------------------------------------------------
module GameData
  class Species

    # Get abilities for species with Randomizer overrides
    def abilities; return RandomizedChallenge::Ability.get(@id, @abilities); end

    # Get hidden abilities for species with Randomizer overrides
    def hidden_abilities; return RandomizedChallenge::Ability.get(@id, @hidden_abilities, true); end
    
    # Get abilities for species without Randomizer overrides
    def real_abilities; return @abilities; end

    # Get hidden abilities for species without Randomizer overrides
    def real_hidden_abilities; return @hidden_abilities; end


    # utility function to get the first species in the evolutionary line
    def get_first_evo
      prev = GameData::Species.get(@id).get_previous_evo
      return @id if prev == @id
      return GameData::Species.get(prev).get_previous_evo
    end

    # utility function to get the previous species in the evolutionary line
    def get_previous_evo
      return @id if @evolutions.length == 0
      @evolutions.each { |evo| return GameData::Species.get_species_form(evo[0], @form).id if evo[3] }   # Get prevolution
      return @id
    end

    # utility function to get every evolution after defined species
    def get_next_evos
      evo = GameData::Species.get(@id).get_evolutions
      all = []
      return [@id] if evo.length < 1
      evo.each do |arr|
        all += [GameData::Species.get_species_form(arr[0], @form).id]
        all += GameData::Species.get_species_form(arr[0], @form).get_next_evos
      end
      return all.uniq
    end

    # utility function to get all species inside an evolutionary line
    def get_evolutionary_line
      sp = get_first_evo
      return ([sp] + GameData::Species.get(sp).get_next_evos).uniq
    end

  end
end


#-------------------------------------------------------------------------------
# Save Data for randomized data, so it doesn't change on save reload
#-------------------------------------------------------------------------------
SaveData.register(:randomized_data) do
  save_value { $randomized_data }
  load_value { |value| $randomized_data = value }
  new_game_value { Hash.new }
end