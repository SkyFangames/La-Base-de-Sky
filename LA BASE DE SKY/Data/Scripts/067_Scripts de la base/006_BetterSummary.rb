#===============================================================================
# CREDITOS
# DPertierra
#===============================================================================
class PokemonSummary_Scene
  def pbStartScene(party, partyindex, inbattle = false, page=1)
      @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
      @viewport.z = 99999
      @party      = party
      @partyindex = partyindex
      @pokemon    = @party[@partyindex]
      @inbattle   = inbattle
      @page = page
      @typebitmap    = AnimatedBitmap.new(_INTL("Graphics/UI/types"))
      @markingbitmap = AnimatedBitmap.new("Graphics/UI/Summary/markings")
      @sprites = {}
      @sprites["background"] = IconSprite.new(0, 0, @viewport)
      @sprites["pokemon"] = PokemonSprite.new(@viewport)
      @sprites["pokemon"].setOffset(PictureOrigin::CENTER)
      @sprites["pokemon"].x = 104
      @sprites["pokemon"].y = 206
      @sprites["pokemon"].setPokemonBitmap(@pokemon)
      @sprites["pokeicon"] = PokemonIconSprite.new(@pokemon, @viewport)
      @sprites["pokeicon"].setOffset(PictureOrigin::CENTER)
      @sprites["pokeicon"].x       = 46
      @sprites["pokeicon"].y       = 92
      @sprites["pokeicon"].visible = false
      @sprites["itemicon"] = ItemIconSprite.new(30, 320, @pokemon.item_id, @viewport)
      @sprites["itemicon"].blankzero = true
      @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
      pbSetSystemFont(@sprites["overlay"].bitmap)
      @sprites["movepresel"] = MoveSelectionSprite.new(@viewport)
      @sprites["movepresel"].visible     = false
      @sprites["movepresel"].preselected = true
      @sprites["movesel"] = MoveSelectionSprite.new(@viewport)
      @sprites["movesel"].visible = false
      @sprites["ribbonpresel"] = RibbonSelectionSprite.new(@viewport)
      @sprites["ribbonpresel"].visible     = false
      @sprites["ribbonpresel"].preselected = true
      @sprites["ribbonsel"] = RibbonSelectionSprite.new(@viewport)
      @sprites["ribbonsel"].visible = false
      @sprites["uparrow"] = AnimatedSprite.new("Graphics/UI/up_arrow", 8, 28, 40, 2, @viewport)
      @sprites["uparrow"].x = 350
      @sprites["uparrow"].y = 56
      @sprites["uparrow"].play
      @sprites["uparrow"].visible = false
      @sprites["downarrow"] = AnimatedSprite.new("Graphics/UI/down_arrow", 8, 28, 40, 2, @viewport)
      @sprites["downarrow"].x = 350
      @sprites["downarrow"].y = 260
      @sprites["downarrow"].play
      @sprites["downarrow"].visible = false
      @sprites["markingbg"] = IconSprite.new(260, 88, @viewport)
      @sprites["markingbg"].setBitmap("Graphics/UI/Summary/overlay_marking")
      @sprites["markingbg"].visible = false
      @sprites["markingoverlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
      @sprites["markingoverlay"].visible = false
      pbSetSystemFont(@sprites["markingoverlay"].bitmap)
      @sprites["markingsel"] = IconSprite.new(0, 0, @viewport)
      @sprites["markingsel"].setBitmap("Graphics/UI/Summary/cursor_marking")
      @sprites["markingsel"].src_rect.height = @sprites["markingsel"].bitmap.height / 2
      @sprites["markingsel"].visible = false
      @sprites["messagebox"] = Window_AdvancedTextPokemon.new("")
      @sprites["messagebox"].viewport       = @viewport
      @sprites["messagebox"].visible        = false
      @sprites["messagebox"].letterbyletter = true
      pbBottomLeftLines(@sprites["messagebox"], 2)
      @nationalDexList = [:NONE]
      GameData::Species.each_species { |s| @nationalDexList.push(s.species) }
      drawPage(@page)
      pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def drawPageOneEgg
      @sprites["itemicon"].item = @pokemon.item_id
      overlay = @sprites["overlay"].bitmap
      overlay.clear
      base   = Color.new(248, 248, 248)
      shadow = Color.new(104, 104, 104)
      # Set background image
      @sprites["background"].setBitmap("Graphics/UI/Summary/bg_egg")
      imagepos = []
      # Show the Poké Ball containing the Pokémon
      ballimage = sprintf("Graphics/UI/Summary/icon_ball_%s", @pokemon.poke_ball)
      imagepos.push([ballimage, 14, 60])
      # Draw all images
      pbDrawImagePositions(overlay, imagepos)
      # Write various bits of text
      textpos = [
      [_INTL("NOTAS ENTRENADOR"), 26, 22, :left, base, shadow],
      [@pokemon.name, 46, 68, :left, base, shadow],
      [_INTL("Objeto"), 66, 324, :left, base, shadow]
      ]
      # Write the held item's name
      if @pokemon.hasItem?
          textpos.push([@pokemon.item.name, 16, 358, :left, Color.new(64, 64, 64), Color.new(176, 176, 176)])
      else
          textpos.push([_INTL("Ninguno"), 16, 358, :left, Color.new(192, 200, 208), Color.new(208, 216, 224)])
      end
      # Draw all text
      pbDrawTextPositions(overlay, textpos)
      red_text_tag = shadowc3tag(RED_TEXT_BASE, RED_TEXT_SHADOW)
      black_text_tag = shadowc3tag(BLACK_TEXT_BASE, BLACK_TEXT_SHADOW)
      memo = ""
      # Write date received
      if @pokemon.timeReceived
      date  = @pokemon.timeReceived.day
      month = pbGetMonthName(@pokemon.timeReceived.mon)
      year  = @pokemon.timeReceived.year
      memo += black_text_tag + _INTL("{1} {2}, {3}", date, month, year) + "\n"
      end
      # Write map name egg was received on
      mapname = pbGetMapNameFromId(@pokemon.obtain_map)
      mapname = @pokemon.obtain_text if @pokemon.obtain_text && !@pokemon.obtain_text.empty?
      if mapname && mapname != ""
      mapname = red_text_tag + mapname + black_text_tag
      memo += black_text_tag + _INTL("Un misterioso huevo recibido en {1}.", mapname) + "\n"
      else
      memo += black_text_tag + _INTL("Un huevo misterioso de un Pokémon.") + "\n"
      end
      memo += "\n"   # Empty line
      # Write Egg Watch blurb
      if !MOSTRAR_PASOS_HUEVO
          #memo += black_text_tag + _INTL("\"El huevo eclosionará...\"") + "\n"
          eggstate = _INTL("Parece que va a tardar un buen rato en eclosionar.")
          eggstate = _INTL("¿Qué eclosionará de esto? No parece estar cerca de eclosionar.") if @pokemon.steps_to_hatch < 10_200
          eggstate = _INTL("Parece moverse ocasionalmente. Puede estar cerca de eclosionar.") if @pokemon.steps_to_hatch < 2550
          eggstate = _INTL("¡Se escuchan sonido desde dentro! ¡eclosionará pronto!") if @pokemon.steps_to_hatch < 1275
          memo += black_text_tag + eggstate
      else
          memo += black_text_tag + _INTL("Faltan {1} pasos para que el huevo eclosione.", @pokemon.steps_to_hatch)
      end
      # Draw all text
      drawFormattedTextEx(overlay, 232, 86, 268, memo)
      # Draw the Pokémon's markings
      drawMarkings(overlay, 84, 292)
  end

  def drawPageFourSelecting(move_to_learn)
      overlay = @sprites["overlay"].bitmap
      overlay.clear
      base   = Color.new(248, 248, 248)
      shadow = Color.new(104, 104, 104)
      moveBase   = Color.new(64, 64, 64)
      moveShadow = Color.new(176, 176, 176)
      ppBase   = [moveBase,                # More than 1/2 of total PP
                  Color.new(248, 192, 0),    # 1/2 of total PP or less
                  Color.new(248, 136, 32),   # 1/4 of total PP or less
                  Color.new(248, 72, 72)]    # Zero PP
      ppShadow = [moveShadow,             # More than 1/2 of total PP
                  Color.new(144, 104, 0),   # 1/2 of total PP or less
                  Color.new(144, 72, 24),   # 1/4 of total PP or less
                  Color.new(136, 48, 48)]   # Zero PP
      # Set background image
      if move_to_learn
        @sprites["background"].setBitmap("Graphics/UI/Summary/bg_learnmove")
      else
        @sprites["background"].setBitmap("Graphics/UI/Summary/bg_movedetail")
      end
      # Write various bits of text
      textpos = [
        [_INTL("MOVIMIENTOS"), 26, 22, :left, base, shadow],
        [_INTL("CATEGORÍA"), 20, 128, :left, base, shadow],
        [_INTL("POTENCIA"), 20, 160, :left, base, shadow],
        [_INTL("PRECISIÓN"), 20, 192, :left, base, shadow],
        
      ]
      textpos.push([_INTL("DATOS"), 92, 81, :left, base, shadow]) if move_to_learn
      imagepos = []
      # Write move names, types and PP amounts for each known move
      yPos = 104
      yPos -= 76 if move_to_learn
      limit = (move_to_learn) ? Pokemon::MAX_MOVES + 1 : Pokemon::MAX_MOVES
      limit.times do |i|
        move = @pokemon.moves[i]
        if i == Pokemon::MAX_MOVES
          move = move_to_learn
          yPos += 20
        end
        if move
          type_number = GameData::Type.get(move.display_type(@pokemon)).icon_position
          imagepos.push([_INTL("Graphics/UI/types"), 248, yPos - 4, 0, type_number * 28, 64, 28])
          textpos.push([move.name, 316, yPos, :left, moveBase, moveShadow])
          if move.total_pp > 0
            textpos.push([_INTL("PP"), 342, yPos + 32, :left, moveBase, moveShadow])
            ppfraction = 0
            if move.pp == 0
              ppfraction = 3
            elsif move.pp * 4 <= move.total_pp
              ppfraction = 2
            elsif move.pp * 2 <= move.total_pp
              ppfraction = 1
            end
            textpos.push([sprintf("%d/%d", move.pp, move.total_pp), 460, yPos + 32, :right,
                          ppBase[ppfraction], ppShadow[ppfraction]])
          end
        else
          textpos.push(["-", 316, yPos, :left, moveBase, moveShadow])
          textpos.push(["--", 442, yPos + 32, :right, moveBase, moveShadow])
        end
        yPos += 64
        imagepos.push([_INTL("Graphics/UI/BetterMoveSummary/recuadro"), 85, 76]) if move_to_learn
        imagepos.push([_INTL("Graphics/UI/BetterMoveSummary/help_actionkey"), 165, 79]) if move_to_learn
        # Draw all text and images
        pbDrawImagePositions(overlay, imagepos)
        pbDrawTextPositions(overlay, textpos)
      end
    end
    
    def pbChooseMoveToForget(move_to_learn)
        new_move = (move_to_learn) ? Pokemon::Move.new(move_to_learn) : nil
        selmove = 0
        maxmove = (new_move) ? Pokemon::MAX_MOVES : Pokemon::MAX_MOVES - 1
        loop do
          Graphics.update
          Input.update
          pbUpdate
          if Input.trigger?(Input::BACK)
            selmove = Pokemon::MAX_MOVES
            pbPlayCloseMenuSE if new_move
            break
          elsif Input.trigger?(Input::USE)
            pbPlayDecisionSE
            break
          elsif Input.trigger?(Input::ACTION)
            newScene = PokemonSummary_Scene.new
            newScreen = PokemonSummaryScreen.new(newScene)
            newScreen.pbStartScreen(@party, @partyindex, 3)
          elsif Input.trigger?(Input::UP)
            selmove -= 1
            selmove = maxmove if selmove < 0
            if selmove < Pokemon::MAX_MOVES && selmove >= @pokemon.numMoves
              selmove = @pokemon.numMoves - 1
            end
            @sprites["movesel"].index = selmove
            selected_move = (selmove == Pokemon::MAX_MOVES) ? new_move : @pokemon.moves[selmove]
            drawSelectedMove(new_move, selected_move)
          elsif Input.trigger?(Input::DOWN)
            selmove += 1
            selmove = 0 if selmove > maxmove
            if selmove < Pokemon::MAX_MOVES && selmove >= @pokemon.numMoves
              selmove = (new_move) ? maxmove : 0
            end
            @sprites["movesel"].index = selmove
            selected_move = (selmove == Pokemon::MAX_MOVES) ? new_move : @pokemon.moves[selmove]
            drawSelectedMove(new_move, selected_move)
          end
        end
        return (selmove == Pokemon::MAX_MOVES) ? -1 : selmove
      end

      if !PluginManager.installed?("Modular UI Scenes")
        def pbScene
          @pokemon.play_cry
          loop do
            Graphics.update
            Input.update
            pbUpdate
            dorefresh = false
            if Input.trigger?(Input::ACTION)
              pbSEStop
              @pokemon.play_cry
            elsif Input.trigger?(Input::SPECIAL)
              pbPlayDecisionSE
              showAbilityDescription(@pokemon)
            elsif Input.trigger?(Input::BACK)
              pbPlayCloseMenuSE
              break
            elsif Input.trigger?(Input::USE)
              if @page == 4
                pbPlayDecisionSE
                pbMoveSelection
                dorefresh = true
              elsif @page == 5
                pbPlayDecisionSE
                pbRibbonSelection
                dorefresh = true
              elsif !@inbattle
                pbPlayDecisionSE
                dorefresh = pbOptions
              end
            elsif Input.trigger?(Input::UP) && @partyindex > 0
              oldindex = @partyindex
              pbGoToPrevious
              if @partyindex != oldindex
                pbChangePokemon
                @ribbonOffset = 0
                dorefresh = true
              end
            elsif Input.trigger?(Input::DOWN) && @partyindex < @party.length - 1
              oldindex = @partyindex
              pbGoToNext
              if @partyindex != oldindex
                pbChangePokemon
                @ribbonOffset = 0
                dorefresh = true
              end
            elsif Input.trigger?(Input::LEFT) && !@pokemon.egg?
              oldpage = @page
              @page -= 1
              @page = 1 if @page < 1
              @page = 5 if @page > 5
              if @page != oldpage   # Move to next page
                pbSEPlay("GUI summary change page")
                @ribbonOffset = 0
                dorefresh = true
              end
            elsif Input.trigger?(Input::RIGHT) && !@pokemon.egg?
              oldpage = @page
              @page += 1
              @page = 1 if @page < 1
              @page = 5 if @page > 5
              if @page != oldpage   # Move to next page
                pbSEPlay("GUI summary change page")
                @ribbonOffset = 0
                dorefresh = true
              end
            end
            drawPage(@page) if dorefresh
          end
          return @partyindex
        end
      end 


      def showAbilityDescription(pokemon)
        overlay=@sprites["overlay"].bitmap
        overlay.clear
        @sprites["background"].setBitmap("Graphics/UI/Summary/bgability_extender")
        imagepos=[]
        ballimage = sprintf("Graphics/UI/Summary/icon_ball_%s", @pokemon.poke_ball)
        imagepos.push([ballimage,14,60,0,0,-1,-1])
        pbDrawImagePositions(overlay,imagepos)
        base=Color.new(248,248,248)
        shadow=Color.new(176,176,176)
        shadow2=Color.new(104,104,104)
        statshadows=[]
        pbSetSystemFont(overlay)
        abilityname=pokemon.ability.name
        abilitydesc=pokemon.ability.description
        pokename=@pokemon.name
        #textos
        textpos=[
           [_INTL("INFORMACIÓN"),26,22,0,base,shadow2],
           [pokename,46,68,0,base,shadow2],
           [pokemon.level.to_s,46, 98, 0, Color.new(64, 64, 64), Color.new(176, 176, 176)],
           [_INTL("Habilidad:"),230,22,0,base,shadow2],
           [abilityname,336,22,0,base,shadow2],
           [_INTL("Objeto"), 66, 324, 0, base, shadow2]
          ] 
        if @pokemon.hasItem?
          textpos.push([@pokemon.item.name, 16, 358, 0, Color.new(64, 64, 64), Color.new(176, 176, 176)])
        else
          textpos.push([_INTL("Ninguno"), 16, 358, 0, Color.new(192, 200, 208), Color.new(208, 216, 224)])
        end
        if @pokemon.male?
          textpos.push([_INTL("♂"), 178, 68, 0, Color.new(24, 112, 216), Color.new(136, 168, 208)])
        elsif @pokemon.female?
          textpos.push([_INTL("♀"), 178, 68, 0, Color.new(248, 56, 32), Color.new(224, 152, 144)])
        end
        # Draw all text
        pbDrawTextPositions(overlay, textpos)
        # Draw the Pokémon's markings
        drawMarkings(overlay, 84, 292)
        pbDrawTextPositions(overlay,textpos)
        drawTextEx(overlay,240,85,230,10,abilitydesc,Color.new(64,64,64),shadow)  
        loop do
          Graphics.update
          Input.update
          pbUpdate
          if Input.trigger?(Input::BACK)
            Input.update
            if PluginManager.installed?("Modular UI Scenes")
              drawPage(:page_skills) 
            else
              drawPage(3)
            end
            break
          elsif Input.trigger?(Input::SPECIAL)
            Input.update
            if PluginManager.installed?("Modular UI Scenes")
              drawPage(:page_skills) 
            else
              drawPage(3)
            end
            break
          end
        end
      end
end

class PokemonSummaryScreen
    def pbStartScreen(party, partyindex, page=1)
        @scene.pbStartScene(party, partyindex, @inbattle, page)
        ret = @scene.pbScene
        @scene.pbEndScene
        return ret
    end
end
