#===============================================================================
# Party menu text colors.
#===============================================================================
class Window_CommandPokemonColor < Window_CommandPokemon
  #-----------------------------------------------------------------------------
  # Stores the text colors for each color symbol. The first color in each array
  # corresponds to the base color, and the second color is for the shadow.
  #-----------------------------------------------------------------------------
  TEXT_COLOR_KEY = {
    :Red    => [Color.new(232,  32,  16), Color.new(248, 168, 184)],
    :Blue   => [Color.new(  0,  80, 160), Color.new(128, 192, 240)],
    :Green  => [Color.new( 96, 176,  72), Color.new(174, 208, 144)],
    :Orange => [Color.new(236,  88,   0), Color.new(255, 170,  51)],
    :Purple => [Color.new(149,  33, 246), Color.new(255, 161, 326)],
    :Gray   => [Color.new(184, 184, 184), Color.new( 96,  96,  96)]
  }

  #-----------------------------------------------------------------------------
  # Sets the text color for each menu option.
  #-----------------------------------------------------------------------------
  def drawItem(index, _count, rect)
    pbSetSystemFont(self.contents) if @starting
    rect = drawCursor(index, rect)
    if @colorKey[index].is_a?(Symbol)
      base   = TEXT_COLOR_KEY[@colorKey[index]][0]
      shadow = TEXT_COLOR_KEY[@colorKey[index]][1]
    else
      base   = self.baseColor
      shadow = self.shadowColor
    end
    pbDrawShadowText(self.contents, rect.x, rect.y + (self.contents.text_offset_y || 0),
                     rect.width, rect.height, @commands[index], base, shadow)
  end
end


#-------------------------------------------------------------------------------
# Rewrites the party screen menu commands to allow for different text colors.
#-------------------------------------------------------------------------------
class PokemonPartyScreen
  def pbPokemonScreen
    ret = nil
    can_access_storage = false
    if ($player.has_box_link || $bag.has?(:POKEMONBOXLINK)) &&
       !$game_switches[Settings::DISABLE_BOX_LINK_SWITCH] &&
       !$game_map.metadata&.has_flag?("DisableBoxLink")
      can_access_storage = true
    end
    @scene.pbStartScene(@party,
                        (@party.length > 1) ? _INTL("Elige un Pokémon.") : _INTL("Elige un Pokémon o cancela."),
                        nil, false, can_access_storage)
    loop do
      @scene.pbSetHelpText((@party.length > 1) ? _INTL("Elige un Pokémon.") : _INTL("Elige un Pokémon o cancela."))
      party_idx = @scene.pbChoosePokemon(false, -1, 1)
      break if (party_idx.is_a?(Numeric) && party_idx < 0) || (party_idx.is_a?(Array) && party_idx[1] < 0)
      if party_idx.is_a?(Array) && party_idx[0] == 1
        @scene.pbSetHelpText(_INTL("¿Mover a dónde?"))
        old_party_idx = party_idx[1]
        party_idx = @scene.pbChoosePokemon(true, -1, 2)
        pbSwitch(old_party_idx, party_idx) if party_idx >= 0 && party_idx != old_party_idx
        next
      end
      pkmn = @party[party_idx]
      command_list = []
      commands = []
      show_field_moves = true
      MenuHandlers.each_available(:party_menu, self, @party, party_idx) do |option, hash, name|
        show_field_moves = false if hash["field_skill"]
        if hash["text_color"] && hash["text_color"].is_a?(Symbol)
          command_list.push([name, hash["text_color"]])
        else
          command_list.push(name)
        end
        commands.push(hash)
      end
      command_list.push(_INTL("Cancelar"))
      if !pkmn.egg? && show_field_moves
        insert_index = ($DEBUG) ? 2 : 1
        pkmn.moves.each_with_index do |move, i|
          next if !HiddenMoveHandlers.hasHandler(move.id) &&
                  ![:MILKDRINK, :SOFTBOILED].include?(move.id)
          command_list.insert(insert_index, [move.name, :Blue])
          commands.insert(insert_index, i)
          insert_index += 1
        end
      end
      choice = @scene.pbShowCommands(_INTL("¿Qué hacer con {1}?", pkmn.name), command_list)
      next if choice < 0 || choice >= commands.length
      case commands[choice]
      when Hash
        if commands[choice]["field_skill"]
          ret = commands[choice]["effect"].call(self, @party, party_idx)
          break if !ret.nil?
        else
          commands[choice]["effect"].call(self, @party, party_idx)
        end
      when Integer
        move = pkmn.moves[commands[choice]]
        if [:MILKDRINK, :SOFTBOILED].include?(move.id)
          amt = [(pkmn.totalhp / 5).floor, 1].max
          if pkmn.hp <= amt
            pbDisplay(_INTL("No tiene suficientes PS..."))
            next
          end
          @scene.pbSetHelpText(_INTL("¿Usar en que Pokémon?"))
          old_party_idx = party_idx
          loop do
            @scene.pbPreSelect(old_party_idx)
            party_idx = @scene.pbChoosePokemon(true, party_idx)
            break if party_idx < 0
            newpkmn = @party[party_idx]
            movename = move.name
            if party_idx == old_party_idx
              pbDisplay(_INTL("¡{1} no puede usar {2} en si mismo!", pkmn.name, movename))
            elsif newpkmn.egg?
              pbDisplay(_INTL("¡{1} no puede ser usado en un huevo!", movename))
            elsif newpkmn.fainted? || newpkmn.hp == newpkmn.totalhp
              pbDisplay(_INTL("{1} no puede ser usado en ese Pokémon.", movename))
            else
              pkmn.hp -= amt
              hpgain = pbItemRestoreHP(newpkmn, amt)
              @scene.pbDisplay(_INTL("Los PS de {1} fueron restaurados en {2} puntos.", newpkmn.name, hpgain))
              pbRefresh
            end
            break if pkmn.hp <= amt
          end
          @scene.pbSelect(old_party_idx)
          pbRefresh
        elsif pbCanUseHiddenMove?(pkmn, move.id)
          if pbConfirmUseHiddenMove(pkmn, move.id)
            @scene.pbEndScene
            if move.id == :FLY
              scene = PokemonRegionMap_Scene.new(-1, false)
              screen = PokemonRegionMapScreen.new(scene)
              ret = screen.pbStartFlyScreen
              if ret
                $game_temp.fly_destination = ret
                return [pkmn, move.id]
              end
              @scene.pbStartScene(
                @party, (@party.length > 1) ? _INTL("Elige un Pokémon.") : _INTL("Elige un Pokémon o cancela.")
              )
              next
            end
            return [pkmn, move.id]
          end
        end
      end
    end
    @scene.pbEndScene
    return ret
  end
end