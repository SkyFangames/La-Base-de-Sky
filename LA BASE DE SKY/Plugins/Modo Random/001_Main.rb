#***********************************************************
# - MAIN -
#***********************************************************

class PokemonGlobalMetadata
  attr_accessor :tmCompatibilityRandom
  attr_accessor :randomMoves
  attr_accessor :randomGens
  attr_accessor :enable_random_moves
  attr_accessor :progressive_random
  attr_accessor :enable_random_tm_compat
  attr_accessor :enable_random_evolutions
  attr_accessor :enable_random_evolutions_similar_bst
  attr_accessor :enable_random_abilities
end
  
def are_random_moves_on()
  return $PokemonGlobal.enable_random_moves ? true : false
end

def toggle_random_moves()
  $PokemonGlobal.enable_random_moves = RandomizedChallenge::RANDOM_MOVES_DEFAULT_VALUE if $PokemonGlobal.enable_random_moves == nil
  $PokemonGlobal.enable_random_moves = !$PokemonGlobal.enable_random_moves
end

def is_random_tm_compat_on()
  return $PokemonGlobal.enable_random_tm_compat ? true : false
end

def toggle_random_tm_compat()
  $PokemonGlobal.enable_random_tm_compat = !$PokemonGlobal.enable_random_tm_compat
end

def is_progressive_random_on()
  return $PokemonGlobal.progressive_random ? true : false
end

def toggle_progressive_random()
  $PokemonGlobal.progressive_random = !$PokemonGlobal.progressive_random
end

def are_random_evolutions_on()
  return $PokemonGlobal.enable_random_evolutions ? true : false
end

def toggle_random_evolutions()
  $PokemonGlobal.enable_random_evolutions = !$PokemonGlobal.enable_random_evolutions
end

def are_random_evolutions_similar_bst_on()
  return $PokemonGlobal.enable_random_evolutions_similar_bst ? true : false
end

def toggle_random_evolutions_similar_bst()
  $PokemonGlobal.enable_random_evolutions_similar_bst = !$PokemonGlobal.enable_random_evolutions_similar_bst
end

def set_random_gens(gens = [])
  $PokemonGlobal.randomGens = Array(gens)
end

def add_or_remove_random_gen(gen = nil)
  return if !gen
  $PokemonGlobal.randomGens = [] if !$PokemonGlobal.randomGens
  if !$PokemonGlobal.randomGens.include?(gen)
    $PokemonGlobal.randomGens.push(gen)
  else
    $PokemonGlobal.randomGens.delete(gen)
  end
end

def get_random_gens()
  return $PokemonGlobal.randomGens ? $PokemonGlobal.randomGens : []
end
  
def enable_random 
  return if !$game_switches
  $PokemonGlobal.enable_random_moves = RandomizedChallenge::RANDOM_MOVES_DEFAULT_VALUE if $PokemonGlobal.enable_random_moves == nil
  $PokemonGlobal.progressive_random = RandomizedChallenge::PROGRESSIVE_RANDOM_DEFAULT_VALUE if $PokemonGlobal.progressive_random == nil
  $PokemonGlobal.enable_random_tm_compat = RandomizedChallenge::RANDOM_TM_COMPAT_DEFAULT_VALUE if $PokemonGlobal.enable_random_tm_compat == nil
  $PokemonGlobal.enable_random_evolutions = RandomizedChallenge::RANDOM_EVOLUTIONS_DEFAULT_VALUE if $PokemonGlobal.enable_random_evolutions == nil
  $PokemonGlobal.enable_random_evolutions_similar_bst = RandomizedChallenge::RANDOM_EVOLUTIONS_SIMILAR_BST_DEFAULT_VALUE if $PokemonGlobal.enable_random_evolutions_similar_bst == nil

  if RandomizedChallenge::TIPO_DE_RANDOM_DE_HABILIDADES == :FULLRANDOM
    $game_switches[RandomizedChallenge::ABILITY_RANDOMIZER_SWITCH] = true
  elsif RandomizedChallenge::TIPO_DE_RANDOM_DE_HABILIDADES == :MAPABILITIES
    $game_switches[RandomizedChallenge::ABILITY_RANDOMIZER_SWITCH] = true
    $game_switches[RandomizedChallenge::ABILITY_SWAP_RANDOMIZER_SWITCH] = true
  elsif RandomizedChallenge::TIPO_DE_RANDOM_DE_HABILIDADES == :SAMEINEVOLUTION
    $game_switches[RandomizedChallenge::ABILITY_RANDOMIZER_SWITCH] = true
    $game_switches[RandomizedChallenge::ABILITY_SEMI_RANDOMIZER_SWITCH] = true
  end
  generarInicialesRandom
  $game_switches[RandomizedChallenge::Switch] = true
end

def disable_random
  $game_switches[RandomizedChallenge::Switch] = false
  $game_switches[RandomizedChallenge::ABILITY_RANDOMIZER_SWITCH] = false
  $game_switches[RandomizedChallenge::ABILITY_SWAP_RANDOMIZER_SWITCH] = false
  $game_switches[RandomizedChallenge::ABILITY_SEMI_RANDOMIZER_SWITCH] = false

end

# BST máximo y mínimo de los Pokémon del Randomizado en base a cada medalla
# del jugador.
# Si necesitas más medallas o usar otro BST, puedes editarlo aquí.
def getMaxBSTCap()
    return 400 if $player.badge_count <= 1
    return 440 if $player.badge_count <= 2
    return 480 if $player.badge_count <= 3
    return 520 if $player.badge_count <= 4
    return 560 if $player.badge_count <= 5
    return 600 if $player.badge_count <= 6
    return 800 if $player.badge_count <= 7
    return 800 if $player.badge_count <= 8
end

def getMinBSTCap()
    return 440 if $player.badge_count > 6
    return 425 if $player.badge_count > 5
    return 400 if $player.badge_count > 4
    return 375 if $player.badge_count > 3
    return 350 if $player.badge_count > 2
    return 0
end

class Pokemon

  alias randomized_init initialize

  def getRandomSpecies
      species_num = rand(GameData::Species.species_count - 1) + 1
      count = 1
      GameData::Species.each_species do |species| 
        if count == species_num
            return species
        end
        count += 1
      end
  end
  
  def compare_bst(bst)
    return false if !$PokemonGlobal.progressive_random
    return bst > getMaxBSTCap() || bst < getMinBSTCap()
  end

  def initialize(species,level, owner = $player,withMoves=true, recheck_form = true)
    if $game_switches && $game_switches[RandomizedChallenge::Switch]
      species = RandomizedChallenge::WhiteListedPokemon.shuffle[0]
      if RandomizedChallenge::WhiteListedPokemon.length == 0
        species = getRandomSpecies()
        bst = species.base_stats.values.sum 
        previous_species = GameData::Species.get(species.get_previous_species)
        $PokemonGlobal.randomGens = [] if !$PokemonGlobal.randomGens
        while !species || RandomizedChallenge::BlackListedPokemon.include?(species.species) || compare_bst(bst) || ( $PokemonGlobal.randomGens.length > 0 && !$PokemonGlobal.randomGens.include?(species.generation) &&  !$PokemonGlobal.randomGens.include?(previous_species.generation) )
          species = getRandomSpecies()
          bst = species.base_stats.values.sum
          previous_species = GameData::Species.get(species.get_previous_species)
        end
      end
    end
    randomized_init(species, level, owner, withMoves, recheck_form)
  end

  def getRandomMove
      move_num = rand(GameData::Move.count - 1) + 1
      count = 1
      GameData::Move.each do |move| 
        if count == move_num
            return move
        end
        count += 1
      end
  end

  alias random_getMoveList getMoveList
  def getMoveList
      moves = random_getMoveList
      if ($game_switches && $game_switches[RandomizedChallenge::Switch])
          $PokemonGlobal.randomMoves = {} if !$PokemonGlobal.randomMoves
          if !$PokemonGlobal.randomMoves[@species]
              $PokemonGlobal.randomMoves[@species] = []
          else
              return $PokemonGlobal.randomMoves[@species]
          end
          for item in moves
              level = item[0]
              move = getRandomMove() 
              if $player.badge_count < 3
                  movedata = GameData::Move.get(move.id)
                  moveExists = $PokemonGlobal.randomMoves[@species].detect{ |elem| elem[1] == (move) }
                  while movedata.power > 70 || RandomizedChallenge::MOVEBLACKLIST.include?(move) || moveExists
                    move = getRandomMove()
                    movedata = GameData::Move.get(move.id)
                    moveExists = $PokemonGlobal.randomMoves[@species].detect{ |elem| elem[1] == (move) }
                  end
              else
                  #Usar blacklist en el recordador.
                  moveExists = $PokemonGlobal.randomMoves[@species].detect{ |elem| elem[1] == (move) }
                  while RandomizedChallenge::MOVEBLACKLIST.include?(move) || !move || moveExists 
                    move= getRandomMove() 
                    moveExists = $PokemonGlobal.randomMoves[@species].detect{ |elem| elem[1] == (move) }
                  end
              end
              $PokemonGlobal.randomMoves[@species].push([level,move])
          end
          moves = $PokemonGlobal.randomMoves[@species]
      end
      return moves
  end

  alias compatible_with_move_random? compatible_with_move? 
  def compatible_with_move?(move_id)
    if ($game_switches && !$game_switches[RandomizedChallenge::Switch]) || !is_random_tm_compat_on()
      return compatible_with_move_random?(move_id) 
    end

    #RAND Compatibility #TM
    if !$PokemonGlobal.tmCompatibilityRandom
      $PokemonGlobal.tmCompatibilityRandom = {}
    end
    if $PokemonGlobal.tmCompatibilityRandom && $PokemonGlobal.tmCompatibilityRandom[self.species] && $PokemonGlobal.tmCompatibilityRandom[self.species].detect {|item| item[0]==move_id }
      return $PokemonGlobal.tmCompatibilityRandom[self.species].any? {|item| item[0]==move_id && item[1] == true }
    elsif !$PokemonGlobal.tmCompatibilityRandom[self.species]
      $PokemonGlobal.tmCompatibilityRandom[self.species] = []
      if rand(2) == 1
        $PokemonGlobal.tmCompatibilityRandom[self.species].push([move_id, true])
        return true
      else
        $PokemonGlobal.tmCompatibilityRandom[self.species].push([move_id, false])
        return false
      end
    else
      if rand(2) == 1
        $PokemonGlobal.tmCompatibilityRandom[self.species].push([move_id, true])
        return true
      else
        $PokemonGlobal.tmCompatibilityRandom[self.species].push([move_id, false])
        return false
      end
    end

  end

  def get_random_evo(current_species, new_species)
    species_list = []
    GameData::Species.each_species do |species| 
      species_list.push(species)
    end
    species_list.shuffle!
    return species_list[0] if !are_random_evolutions_similar_bst_on()
    new_species_bst_min = GameData::Species.get(new_species).base_stats.values.sum * 0.9
    new_species_bst_max = GameData::Species.get(new_species).base_stats.values.sum * 1.1
    species_list.each do |species|
      species_bst = GameData::Species.get(species).base_stats.values.sum
      return species if species_bst >= new_species_bst_min && species_bst <= new_species_bst_max
    end
  end

  def check_evolution_internal
    return nil if egg? || shadowPokemon?
    return nil if hasItem?(:EVERSTONE)
    return nil if hasAbility?(:BATTLEBOND)
    species_data.get_evolutions(true).each do |evo|   # [new_species, method, parameter, boolean]
      next if evo[3]   # Prevolution
      random_evo = are_random_evolutions_on() ? get_random_evo(self, evo[0]) : evo[0]
      ret = yield self, random_evo, evo[1], evo[2]   # pkmn, new_species, method, parameter
      return ret if ret
    end
    return nil
  end  
end
  

class PokemonEvolutionScene
  alias pbEvolutionSuccess_random pbEvolutionSuccess
  def pbEvolutionSuccess
    previous_level = @pokemon.level 
    pbEvolutionSuccess_random
    @pokemon.form = GameData::Species.get(@pokemon.species).base_form
    @pokemon.level = previous_level if are_random_evolutions_on && @pokemon.level != previous_level
  end
end


#********************************************************
# STARTERS RANDOMIZADOS CON DOS ETAPAS EVOLUTIVAS
#********************************************************

def generarInicialesRandom()
  inicial_1 = RandomizedChallenge::ListaStartersRandomizado.shuffle[0]
  
  inicial_2 = inicial_1
  loop do
    inicial_2 = RandomizedChallenge::ListaStartersRandomizado.shuffle[0]
    break if (inicial_1 != inicial_2)
  end
  
  inicial_3 = inicial_1
  loop do
    inicial_3 = RandomizedChallenge::ListaStartersRandomizado.shuffle[0]
    break if (inicial_1 != inicial_3) && (inicial_2 != inicial_3)
  end
  
  $game_variables[803] = inicial_1
  $game_variables[804] = inicial_2
  $game_variables[805] = inicial_3
end