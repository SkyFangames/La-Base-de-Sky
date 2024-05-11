#===============================================================================
# CREDITOS
# Dr.Doom76
# Website      = https://reliccastle.com/resources/1417/
#===============================================================================
# Added to track whether Pokemon has already recieved IV boost due to Trading Charm.
class Pokemon
  attr_accessor :tradingCharmStatsIncreased
  
  def tradingCharmStatsIncreased?
	  if @tradingCharmStatsIncreased.nil?
	  @tradingCharmStatsIncreased = false
	  return tradingCharmStatsIncreased
	  end
  end
end

def pbChoosePokemonForTradePC(wanted)
variableNumber = 1
nameVarNumber = 2
  wanted = GameData::Species.get(wanted).species
  @chosen = pbChooseTradablePokemonPC(variableNumber, nameVarNumber, wanted, proc { |pkmn, wanted_species|
  })
end

def pbChooseTradablePokemonPC(variableNumber, nameVarNumber, wanted, ableProc = nil, allowIneligible = false)
  chosen = -1
  variableNumber = 1
  nameVarNumber = 2
  pbFadeOutIn {
    scene = PokemonStorageScene.new
    screen = PokemonStorageScreen.new(scene, $PokemonStorage)
    chosen = screen.pbChoosePokemonFromPC(wanted, proc { |pkmn|
    })
  }
  pbSet(variableNumber, chosen)
  if chosen.nil?
    # No Pokémon was chosen, so reset the variables and do not proceed with the trade
    pbSet(nameVarNumber, "")
    pbSet(variableNumber, -1) # Set an indicator for no selection
  else
    # A Pokémon was chosen, so proceed with the trade
    pbSet(nameVarNumber, $PokemonStorage[chosen[0], chosen[1]])
    pbSet(variableNumber, chosen) # Store the chosen Pokémon's index in the PC box
  end
end


def pbStartTradePC(newpoke, nickname = nil, trainerName = nil, trainerGender = 0)
storageLoc = 2
$PokemonStorage[storageLoc[0], storageLoc[1]] = pbGet(2)
  myPokemon = $PokemonStorage[storageLoc[0], storageLoc[1]]  
  $stats.trade_count += 1 
  yourPokemon = nil
  resetmoves = true
  trainerName ||= $game_map.events[@event_id].name
  if newpoke.is_a?(Pokemon)
    newpoke.owner = Pokemon::Owner.new_foreign(trainerName, trainerGender)
    yourPokemon = newpoke
    resetmoves = false
  else
    species_data = GameData::Species.try_get(newpoke)
    raise _INTL("La especie {1} no existe.", newpoke) if !species_data
    yourPokemon = Pokemon.new(species_data.id, myPokemon.level)
    yourPokemon.owner = Pokemon::Owner.new_foreign(trainerName, trainerGender)
  end
  yourPokemon.name          = nickname
  yourPokemon.obtain_method = 2   # traded
  yourPokemon.reset_moves if resetmoves
  yourPokemon.record_first_moves

		if PluginManager.installed?("Charms Case")
        tradingCharmIV = CharmCaseSettings::TRADING_CHARM_IV
          if $player.activeCharm?(:TRADINGCHARM)
            unless yourPokemon.tradingCharmStatsIncreased
              GameData::Stat.each_main do |s|
                stat_id = s.id
                # Adds 5 IVs to each stat.
                yourPokemon.iv[stat_id] = [yourPokemon.iv[stat_id] + tradingCharmIV, 31].min if yourPokemon.iv[stat_id]
              end
              # Set the attribute to track the stat increase
              yourPokemon.tradingCharmStatsIncreased = true
			end
            if rand(100) < CharmCaseSettings::TRADING_CHARM_SHINY
              yourPokemon.shiny = true
            end
		  end
		end
		
  pbFadeOutInWithMusic {
    evo = PokemonTrade_Scene.new
    evo.pbStartScreen(myPokemon, yourPokemon, $player.name, trainerName)
    evo.pbTrade
    evo.pbEndScreen
  }
   $PokemonStorage[storageLoc[0]][storageLoc[1]] = yourPokemon
end

# Modified pbChoosePokemon method
class PokemonStorageScreen
  def pbChoosePokemonFromPC(wanted, ableProc)
    $game_temp.in_storage = true
    @heldpkmn = nil
    @scene.pbStartBox(self, 0)
    retval = nil
    loop do
      selected = @scene.pbSelectBox(@storage.party)
      if selected && selected[0] == -3   # Close box
        if pbConfirm(_INTL("¿Salir del PC?"))
          pbSEPlay("PC close")
          break
        end
        next
      end
      if selected.nil?
        next if pbConfirm(_INTL("¿Continuar operaciones?"))
        break
      elsif selected[0] == -4   # Box name
        pbBoxCommands
      else
        pokemon = @storage[selected[0], selected[1]]
        next if !pokemon
        commands = [
          _INTL("Intercambiar"),
          _INTL("Datos"),
        ]
        commands.push(_INTL("Debug")) if $DEBUG
        commands.push(_INTL("Cancelar"))
        helptext = _INTL("Has elegido a {1}.", pokemon.name)
        command = pbShowCommands(helptext, commands)
        case command
        when 0   # Select
          if pokemon.species == wanted
            retval = selected
            break
          else
            pbMessage(_INTL("¡Este no es el Pokémon que estoy buscando!"))
          end
        when 1 # Summary
          pbSummary(selected, nil)
        when 2
          if $DEBUG
            pbPokemonDebug(pokemon, selected)
          end
        end
      end
    end
    @scene.pbCloseBox
    $game_temp.in_storage = false
    return retval
  end
end



