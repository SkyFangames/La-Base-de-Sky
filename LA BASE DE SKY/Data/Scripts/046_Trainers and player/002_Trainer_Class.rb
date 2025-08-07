#===============================================================================
# Basic trainer class (use a child class rather than this one)
#===============================================================================
class Trainer
  attr_accessor :trainer_type
  attr_accessor :name
  attr_accessor :id
  attr_accessor :language
  attr_accessor :party

  def inspect
    str = super.chop
    party_str = @party.map { |pkmn| pkmn.species_data.species }.inspect
    str << sprintf(" %s @party=%s>", self.full_name, party_str)
    return str
  end

  def full_name
    return _INTL("{1} {2}", trainer_type_name, @name)
  end

  #=============================================================================

  # Portion of the ID which is visible on the Trainer Card
  def public_ID(id = nil)
    return id ? id & 0xFFFF : @id & 0xFFFF
  end

  # Other portion of the ID
  def secret_ID(id = nil)
    return id ? id >> 16 : @id >> 16
  end

  # Random ID other than this Trainer's ID
  def make_foreign_ID
    loop do
      ret = rand(2**16) | (rand(2**16) << 16)
      return ret if ret != @id
    end
    return 0
  end

  #=============================================================================

  def trainer_type_name; return GameData::TrainerType.get(self.trainer_type).name;            end
  def base_money;        return GameData::TrainerType.get(self.trainer_type).base_money;      end
  def gender;            return GameData::TrainerType.get(self.trainer_type).gender;          end
  def male?;             return GameData::TrainerType.get(self.trainer_type).male?;           end
  def female?;           return GameData::TrainerType.get(self.trainer_type).female?;         end
  def skill_level;       return GameData::TrainerType.get(self.trainer_type).skill_level;     end
  def flags;             return GameData::TrainerType.get(self.trainer_type).flags;           end
  def has_flag?(flag);   return GameData::TrainerType.get(self.trainer_type).has_flag?(flag); end

  #=============================================================================

  def pokemon_party
    return @party.find_all { |pkmn| pkmn && !pkmn.egg? }
  end

  def able_party
    return @party.find_all { |pkmn| pkmn && !pkmn.egg? && !pkmn.fainted? }
  end

  def party_count
    return @party.length
  end

  def pokemon_count
    ret = 0
    @party.each { |pkmn| ret += 1 if pkmn && !pkmn.egg? }
    return ret
  end

  def able_pokemon_count
    ret = 0
    @party.each { |pkmn| ret += 1 if pkmn && !pkmn.egg? && !pkmn.fainted? }
    return ret
  end

  def party_full?
    return party_count >= Settings::MAX_PARTY_SIZE
  end

  # Returns true if there are no usable Pokémon in the player's party.
  def all_fainted?
    return able_pokemon_count == 0
  end

  def first_party
    return @party.first
  end

  def first_pokemon
    return pokemon_party.first
  end

  def first_able_pokemon
    return able_party.first
  end

  def first_able_pokemon?(species)
    return false unless GameData::Species.exists?(species)
    pkmn = first_able_pokemon
    return pkmn.isSpecies?(species)
  end

  def last_party
    return (@party.length > 0) ? @party[@party.length - 1] : nil
  end

  def last_pokemon
    pkmn = pokemon_party
    return (pkmn.length > 0) ? pkmn[pkmn.length - 1] : nil
  end

  def last_able_pokemon
    pkmn = able_party
    return (pkmn.length > 0) ? pkmn[pkmn.length - 1] : nil
  end

  def remove_pokemon_at_index(index)
    return false if index < 0 || index >= party_count
    have_able = false
    @party.each_with_index do |pkmn, i|
      have_able = true if i != index && pkmn.able?
      break if have_able
    end
    return false if !have_able
    @party.delete_at(index)
    return true
  end

  # Deletes all Pokémon of the given type from the trainer's party.
  def delete_type_from_party(type)
    return unless GameData::Type.exists?(type)

    type = GameData::Type.get(type).id
    @party.delete_if { |pkmn| pkmn&.hasType?(type) && @party.length > 1 }
  end

  # Deletes all Pokemon of the given type from the trainer's PC.
  def delete_type_from_pc(type)
    return unless GameData::Type.exists?(type)

    type = GameData::Type.get(type).id
    (-1...$PokemonStorage.maxBoxes).each do |i|
      $PokemonStorage.maxPokemon(i).times do |j|
        pkmn = $PokemonStorage[i][j]
        next if pkmn.nil?

        $PokemonStorage.pbDelete(i, j) if pkmn.hasType?(type)
      end
    end
  end

  # Deletes all Pokemon of the given species from the trainer's party.
  # You may also specify a particular form it should be.
  def delete_species_from_party(species, form = -1)
    @party.delete_if { |pkmn| !pkmn.egg? && pkmn.isSpecies?(species) && (form.negative? || pkmn.form == form) && @party.length > 1 }
  end

  # Deletes all Pokemon of the given species from the trainer's PC.
  # You may also specify a particular form it should be.
  def delete_species_from_pc(species, form = -1)
    (-1...$PokemonStorage.maxBoxes).each do |i|
      $PokemonStorage.maxPokemon(i).times do |j|
        pkmn = $PokemonStorage[i][j]
        next if pkmn.nil?

        if !pkmn.egg? && pkmn.isSpecies?(species) && (form.negative? || pkmn.form == form)
          $PokemonStorage.pbDelete(i, j)
        end
      end
    end
  end


  # Checks whether the trainer would still have an unfainted Pokémon if the
  # Pokémon given by _index_ were removed from the party.
  def has_other_able_pokemon?(index)
    @party.each_with_index { |pkmn, i| return true if i != index && pkmn.able? }
    return false
  end

  # Returns true if there is a Pokémon of the given species in the trainer's
  # party. You may also specify a particular form it should be.
  def has_species?(species, form = -1, exclude_form = -1, check_pc = false)
    # Check party first
    party_result = pokemon_party.any? { |pkmn| pkmn&.isSpecies?(species) && (form < 0 || pkmn.form == form) && (exclude_form < 0 || pkmn.form != exclude_form) }
    return true if party_result
    
    # If not found in party and check_pc is true, check PC storage
    if check_pc && $PokemonStorage
      (0...$PokemonStorage.maxBoxes).each do |i|
        $PokemonStorage.maxPokemon(i).times do |j|
          pkmn = $PokemonStorage[i, j]
          if pkmn && pkmn.isSpecies?(species) && (form < 0 || pkmn.form == form) && (exclude_form < 0 || pkmn.form != exclude_form)
            return true
          end
        end
      end
    end
    
    return false
  end
  # Returns whether there is a fatefully met Pokémon of the given species in the
  # trainer's party.
  def has_fateful_species?(species)
    return pokemon_party.any? { |pkmn| pkmn&.isSpecies?(species) && pkmn.obtain_method == 4 }
  end

  # Returns whether there is a Pokémon with the given type in the trainer's
  # party. excluded_pokemon is an array of Pokemon objects to ignore.
  def has_pokemon_of_type?(type, excluded_pokemon = [])
    return false unless GameData::Type.exists?(type)
    type = GameData::Type.get(type).id
    return pokemon_party.any? { |pkmn| pkmn&.hasType?(type) && !excluded_pokemon.include?(pkmn) }
  end

  def find_pokemon_of_type(type, all = false)
    return false unless GameData::Type.exists?(type)

    type = GameData::Type.get(type).id
    all ? pokemon_party.find_all { |p| p&.hasType?(type) } : pokemon_party.find { |p| p&.hasType?(type) }
  end

  def has_pokemon_with_ability?(ability)
    return false unless GameData::Ability.exists?(ability)
    return pokemon_party.any? { |pkmn| pkmn&.hasAbility?(ability) }
  end

  def find_pokemon_with_ability(ability, all = false)
    return false unless GameData::Ability.exists?(ability)
    return all ? pokemon_party.find_all { |pkmn| pkmn&.hasAbility?(ability) } : pokemon_party.find { |pkmn| pkmn&.hasAbility?(ability) }
  end

  # Checks whether any Pokémon in the party knows the given move, and returns
  # the first Pokémon it finds with that move, or nil if no Pokémon has that move.
  def get_pokemon_with_move(move)
    pokemon_party.each { |pkmn| return pkmn if pkmn.hasMove?(move) }
    return nil
  end


  # Checks whether any Pokemon in the party can learn the given move, and
  # returns the first Pokemon it finds with that move, or nil if no Pokemon
  # can learn that move.
  def get_pokemon_can_learn_move(move)
    pokemon_party.each { |pkmn| return pkmn if pkmn.compatible_with_move?(move) }
    return nil
  end

  # Fully heal all Pokémon in the party.
  def heal_party
    @party.each { |pkmn| pkmn.heal }
  end

  # status: el status que se desea asignar, puede ser un GameData::Status, un String o un Symbol
  # status_count: a cuántos Pokémon se les aplicará el status
  # probability: la probalidad de que se le asigne el status entre 1% y 100%
  # in_order: Si se asignará el status a los Pokémon de acuerdo a su posición en el equipo o si se seleccionará uno aleatorio
  def give_status_party_pokemon(status, status_count = 1, probability = 25, in_order = true)
    return if !GameData::Status.exists?(status) || able_pokemon_count < 1 || status_count < 1
    probability = [[probability, 1].max, 100].min
    
    able_party_aux = able_party
    count = 0
    
    if in_order || status_count >= able_party_aux.length
      able_party_aux.each do |pokemon|
        break if count >= status_count
        next unless pokemon.can_get_status?(status) && rand(100) < probability
        pokemon.status = status
        count += 1 
      end
    else
      while count < status_count && !able_party_aux.empty?
        pokemon = able_party_aux.sample
        able_party_aux.delete(pokemon)
        next unless pokemon&.can_get_status?(status) && rand(100) < probability
        pokemon.status = status
        count += 1
      end
    end
  end

  # Este metodo inicia un combate contra un NPC con tu mismo equipo.
  def battle_self(trainer_name, trainer_type)
    clone = NPCTrainer.new(trainer_name, trainer_type)
    clone.party = Marshal.load(Marshal.dump($player.party))
    # En caso de quererle dar items al rival como el mega aro seria
    clone.items = [:MEGARING] if $bag.has?(:MEGARING)
    TrainerBattle.start(clone)
  end

  #=============================================================================

  def initialize(name, trainer_type)
    @trainer_type = GameData::TrainerType.get(trainer_type).id
    @name         = name
    @id           = rand(2**16) | (rand(2**16) << 16)
    @language     = pbGetLanguage
    @party        = []
  end
end

#===============================================================================
# Trainer class for NPC trainers
#===============================================================================
class NPCTrainer < Trainer
  attr_accessor :version
  attr_accessor :items
  attr_accessor :lose_text
  attr_accessor :win_text

  def initialize(name, trainer_type, version = 0)
    super(name, trainer_type)
    @version   = version
    @items     = []
    @lose_text = nil
    @win_text  = nil
  end
end
