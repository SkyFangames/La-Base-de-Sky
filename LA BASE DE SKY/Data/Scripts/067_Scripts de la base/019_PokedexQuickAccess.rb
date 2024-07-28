#===============================================================================
# CREDITOS
# DPertierra
#===============================================================================
MenuHandlers.add(:party_menu, :pokedex, {
    "name"      => _INTL("Pokédex"),
    "order"     => 60,
    "condition" => proc { next $player.has_pokedex && $player.pokedex.accessible_dexes.length > 0 },
    "effect"    => proc { |screen, party, party_idx|
      openPokedexOnPokemon(party[party_idx].species)
    }
})

def openPokedexOnPokemon(species)
    region = -1
    if Settings::USE_CURRENT_REGION_DEX
        region = pbGetCurrentRegion
        region = -1 if region >= $player.pokedex.dexes_count - 1
    else
        region = $PokemonGlobal.pokedexDex   # National Dex -1, regional Dexes 0, 1, etc.
    end
    pokedexScene = PokemonPokedexInfo_Scene.new
    pokedexScreen = PokemonPokedexInfoScreen.new(pokedexScene)
    dexlist, index = pbGetDexList(species)
    pokedexScreen.pbStartScreen(dexlist, index, region)
end

def pbGetPokedexRegion
  if Settings::USE_CURRENT_REGION_DEX
    region = pbGetCurrentRegion
    region = -1 if region >= $player.pokedex.dexes_count - 1
    return region
  else
    return $PokemonGlobal.pokedexDex   # National Dex -1, regional Dexes 0, 1, etc.
  end
end

def pbGetDexList(species_to_find = nil)
  region = pbGetPokedexRegion
  regionalSpecies = pbAllRegionalSpecies(region)
  if !regionalSpecies || regionalSpecies.length == 0
    # If no Regional Dex defined for the given region, use the National Pokédex
    regionalSpecies = []
    GameData::Species.each_species { |s| regionalSpecies.push(s.id) }
  end
  shift = Settings::DEXES_WITH_OFFSETS.include?(region)
  dexlist = []
  index = 1
  regionalSpecies.each_with_index do |species, i|
    next if !species
    # next if !pbCanAddForModeList?($PokemonGlobal.pokedexMode, species)
    _gender, form, _shiny = $player.pokedex.last_form_seen(species)
    species_data = GameData::Species.get_species_form(species, form)
    index = i if species_to_find == species
    dexlist.push({
      :species => species,
      :name    => species_data.name,
      :height  => species_data.height,
      :weight  => species_data.weight,
      :number  => i + 1,
      :shift   => shift,
      :types   => species_data.types,
      :color   => species_data.color,
      :shape   => species_data.shape
    })
  end
  return dexlist, index
end

class PokemonStorageScreen
  def pbStartScreen(command)
      $game_temp.in_storage = true
      @heldpkmn = nil
      case command
      when 0   # Organise
        @scene.pbStartBox(self, command)
        loop do
          selected = @scene.pbSelectBox(@storage.party)
          if selected.nil?
            if pbHeldPokemon
              pbDisplay(_INTL("¡Estás sosteniendo un Pokémon!"))
              next
            elsif @scene.grabber.carrying
              pbDisplay(_INTL("¡Estás sosteniendo un Pokémon!"))
              next
            end
            next if pbConfirm(_INTL("¿Desea hacer más operaciones?"))
            break
          elsif selected[0] == -3   # Close box
            if pbHeldPokemon
              pbDisplay(_INTL("¡Estás sosteniendo unPokémon!"))
              next
            elsif @scene.grabber.carrying
              pbDisplay(_INTL("¡Estás sosteniendo un Pokémon!"))
              next
            end
            if pbConfirm(_INTL("¿Desea salir de la caja?"))
              pbSEPlay("PC close")
              break
            end
            next
          elsif selected[0] == -4   # Box name
            if @scene.grabber.carrying && CAN_BOX_POUR
                if pbPour(selected)
                  @scene.grabber.carrying = false
                  @scene.grabber.clear
                  @scene.release_tension
                end
            else
              pbBoxCommands
            end
          else
            pokemon = @storage[selected[0], selected[1]]
            heldpoke = pbHeldPokemon
            next if !pokemon && !heldpoke && !@scene.grabber.carrying
            if @scene.quickswap
              if @heldpkmn
                (pokemon) ? pbSwap(selected) : pbPlace(selected)
              else
                pbHold(selected)
              end
            elsif @scene.multi
              if !@scene.grabber.carrying
                if @scene.grabber.holding_anything?
                  @scene.grabber.carrying = true
                  # Gathers held mons data in @carried_mons in the grabber
                  @scene.grabber.pack_up(@storage, selected[0])
                  # Deletes mon off storage
                  pbHold_Multi(selected)
                  @scene.start_tension
                  # Moves the hand to mock pivot position
                  @scene.quick_change(@scene.grabber.mock_pivot)
                  selected[1] = @scene.grabber.mock_pivot
                else
                  # Start tension here
                  @scene.grabber.setPivot(selected[1])
                  @scene.grabber.do_with(selected[1])
                  @scene.do_green
                  @scene.set_tension
                end
              else
                # Drop Off If Possible
                if @scene.grabber.place_with_positions(@storage, selected[0], selected[1])
                  pbPlace_Multi(selected)
                  # @scene.grabber.get_new_carried_mons
                  @scene.grabber.carrying = false
                  @scene.grabber.clear
                  @scene.release_tension
                else
                  next
                end
              end
            else
              commands = []
              cmdMove     = -1
              cmdSummary  = -1
              cmdWithdraw = -1
              cmdItem     = -1
              cmdMark     = -1
              cmdRelease  = -1
              cmdPokedex  = -1
              cmdDebug    = -1
              if heldpoke
                helptext = _INTL("{1} está seleccionado.", heldpoke.name)
                commands[cmdMove = commands.length] = (pokemon) ? _INTL("Cambiar") : _INTL("Dejar")
              elsif pokemon
                helptext = _INTL("{1} está seleccionado.", pokemon.name)
                commands[cmdMove = commands.length] = _INTL("Mover")
              end
              commands[cmdSummary = commands.length]  = _INTL("Datos")
              commands[cmdWithdraw = commands.length] = (selected[0] == -1) ? _INTL("Dejar") : _INTL("Sacar")
              commands[cmdItem = commands.length]     = _INTL("Objeto")
              commands[cmdMark = commands.length]     = _INTL("Marcas")
              commands[cmdRelease = commands.length]  = _INTL("Liberar")
              commands[cmdPokedex = commands.length]  = _INTL("Pokédex")
              commands[cmdDebug = commands.length]    = _INTL("Debug") if $DEBUG
              commands[commands.length]               = _INTL("Cancelar")
              command = pbShowCommands(helptext, commands)
              if cmdMove >= 0 && command == cmdMove   # Move/Shift/Place
                if @heldpkmn
                  (pokemon) ? pbSwap(selected) : pbPlace(selected)
                else
                  pbHold(selected)
                end
              elsif cmdSummary >= 0 && command == cmdSummary   # Summary
                pbSummary(selected, @heldpkmn)
              elsif cmdWithdraw >= 0 && command == cmdWithdraw   # Store/Withdraw
                (selected[0] == -1) ? pbStore(selected, @heldpkmn) : pbWithdraw(selected, @heldpkmn)
              elsif cmdItem >= 0 && command == cmdItem   # Item
                pbItem(selected, @heldpkmn)
              elsif cmdMark >= 0 && command == cmdMark   # Mark
                pbMark(selected, @heldpkmn)
              elsif cmdRelease >= 0 && command == cmdRelease   # Release
                pbRelease(selected, @heldpkmn)
              elsif cmdPokedex >= 0 && command == cmdPokedex    # Pokédex
                  openPokedexOnPokemon(pokemon.species) if pokemon
                  openPokedexOnPokemon(@heldpkmn.species) if !pokemon && @heldpkmn
              elsif cmdDebug >= 0 && command == cmdDebug   # Debug
                pbPokemonDebug((@heldpkmn) ? @heldpkmn : pokemon, selected, heldpoke)
              end
            end
          end
        end
        @scene.pbCloseBox
      when 1   # Withdraw
        @scene.pbStartBox(self, command)
        loop do
          selected = @scene.pbSelectBox(@storage.party)
          if selected.nil?
            next if pbConfirm(_INTL("¿Desea hacer más operaciones?"))
            break
          else
            case selected[0]
            when -2   # Party Pokémon
              pbDisplay(_INTL("¿Cuál tomarás?"))
              next
            when -3   # Close box
              if pbConfirm(_INTL("¿Desea salir de la caja?"))
                pbSEPlay("PC close")
                break
              end
              next
            when -4   # Box name
              pbBoxCommands
              next
            end
            pokemon = @storage[selected[0], selected[1]]
            next if !pokemon
            command = pbShowCommands(_INTL("{1} está seleccionado.", pokemon.name),
                                     [_INTL("Retirar"),
                                      _INTL("Datos"),
                                      _INTL("Marcas"),
                                      _INTL("Liberar"),
                                      _INTL("Pokédex"),
                                      _INTL("Cancelar")])
            case command
              when 0 then pbWithdraw(selected, nil)
              when 1 then pbSummary(selected, nil)
              when 2 then pbMark(selected, nil)
              when 3 then pbRelease(selected, nil)
              when 4 then openPokedexOnPokemon(pokemon.species)
            end
          end
        end
        @scene.pbCloseBox
      when 2   # Deposit
        @scene.pbStartBox(self, command)
        loop do
          selected = @scene.pbSelectParty(@storage.party)
          if selected == -3   # Close box
            if pbConfirm(_INTL("¿Desea salir de la caja?"))
              pbSEPlay("PC close")
              break
            end
            next
          elsif selected < 0
            next if pbConfirm(_INTL("¿Desea hacer más operaciones?"))
            break
          else
            pokemon = @storage[-1, selected]
            next if !pokemon
            command = pbShowCommands(_INTL("{1} está seleccionado.", pokemon.name),
                                     [_INTL("Dejar"),
                                      _INTL("Datos"),
                                      _INTL("Marcas"),
                                      _INTL("Liberar"),
                                      _INTL("Pokédex"),
                                      _INTL("Cancelar")])
            case command
              when 0 then pbStore([-1, selected], nil)
              when 1 then pbSummary([-1, selected], nil)
              when 2 then pbMark([-1, selected], nil)
              when 3 then pbRelease([-1, selected], nil)
              when 4 then openPokedexOnPokemon(pokemon.species)
            end
          end
        end
        @scene.pbCloseBox
      when 3
        @scene.pbStartBox(self, command)
        @scene.pbCloseBox
      end
      $game_temp.in_storage = false
  end
end
