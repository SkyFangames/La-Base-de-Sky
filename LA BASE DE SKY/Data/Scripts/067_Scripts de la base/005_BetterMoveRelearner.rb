#===============================================================================
# CREDITOS
# DPertierra
#===============================================================================
class MoveRelearner_Scene
    def pbStartScene(pokemon, moves)
        @pokemon = pokemon
        @moves = moves
        moveCommands = []
        moves.each { |m| moveCommands.push(GameData::Move.get(m[0]).name) }
        # Create sprite hash
        @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
        @viewport.z = 99999
        @sprites = {}
        addBackgroundPlane(@sprites, "bg", "Move Reminder/bg", @viewport)
        @sprites["pokeicon"] = PokemonIconSprite.new(@pokemon, @viewport)
        @sprites["pokeicon"].setOffset(PictureOrigin::CENTER)
        @sprites["pokeicon"].x = 320
        @sprites["pokeicon"].y = 84
        @sprites["background"] = IconSprite.new(0, 0, @viewport)
        @sprites["background"].setBitmap("Graphics/UI/Move Reminder/cursor")
        @sprites["background"].y = 78
        @sprites["background"].src_rect = Rect.new(0, 72, 258, 72)
        @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
        pbSetSystemFont(@sprites["overlay"].bitmap)
        @sprites["commands"] = Window_CommandPokemon.new(moveCommands, 32)
        @sprites["commands"].height = 32 * (VISIBLEMOVES + 1)
        @sprites["commands"].visible = false
        @sprites["msgwindow"] = Window_AdvancedTextPokemon.new("")
        @sprites["msgwindow"].visible = false
        @sprites["msgwindow"].viewport = @viewport
        @typebitmap = AnimatedBitmap.new(_INTL("Graphics/UI/types"))
        pbDrawMoveList
        pbDeactivateWindows(@sprites)
        # Fade in all sprites
        pbFadeInAndShow(@sprites) { pbUpdate }
      end
    
      def pbDrawMoveList
        overlay = @sprites["overlay"].bitmap
        overlay.clear
        @pokemon.types.each_with_index do |type, i|
          type_number = GameData::Type.get(type).icon_position
          type_rect = Rect.new(0, type_number * 28, 64, 28)
          type_x = (@pokemon.types.length == 1) ? 400 : 366 + (70 * i)
          overlay.blt(type_x, 70, @typebitmap.bitmap, type_rect)
        end
        textpos = [
          [_INTL("¿Enseñar qué movimiento?"), 16, 14, :left, Color.new(88, 88, 80), Color.new(168, 184, 184)]
        ]
        imagepos = []
        yPos = 88
        VISIBLEMOVES.times do |i|
          moveobject = @moves[@sprites["commands"].top_item + i]
          if moveobject
            moveData = GameData::Move.get(moveobject[0])
            type_number = GameData::Type.get(moveData.display_type(@pokemon)).icon_position
            imagepos.push([_INTL("Graphics/UI/types"), 12, yPos - 4, 0, type_number * 28, 64, 28])
            textpos.push([moveData.name, 80, yPos, :left, Color.new(248, 248, 248), Color.black])
            textpos.push([moveobject[1], 0, yPos+32, :left, Color.new(248, 248, 248), Color.black]) if moveobject[1]
            textpos.push([_INTL("PP"), 112, yPos + 32, :left, Color.new(64, 64, 64), Color.new(176, 176, 176)])
            if moveData.total_pp > 0
              textpos.push([moveData.total_pp.to_s + "/" + moveData.total_pp.to_s, 230, yPos + 32, :right,
                            Color.new(64, 64, 64), Color.new(176, 176, 176)])
            else
              textpos.push(["--", 230, yPos + 32, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)])
            end
          end
          yPos += 64
        end
        imagepos.push(["Graphics/UI/Move Reminder/cursor",
                       0, 78 + ((@sprites["commands"].index - @sprites["commands"].top_item) * 64),
                       0, 0, 258, 72])
        selMoveData = GameData::Move.get(@moves[@sprites["commands"].index][0])
        power = selMoveData.display_damage(@pokemon)
        category = selMoveData.display_category(@pokemon)
        accuracy = selMoveData.display_accuracy(@pokemon)
        textpos.push([_INTL("CATEGORÍA"), 272, 120, :left, Color.new(248, 248, 248), Color.black])
        textpos.push([_INTL("PODER"), 272, 152, :left, Color.new(248, 248, 248), Color.black])
        textpos.push([power <= 1 ? power == 1 ? "???" : "---" : power.to_s, 468, 152, :center,
                      Color.new(64, 64, 64), Color.new(176, 176, 176)])
        textpos.push([_INTL("PRECISIÓN"), 272, 184, :left, Color.new(248, 248, 248), Color.black])
        textpos.push([accuracy == 0 ? "---" : "#{accuracy}%", 468, 184, :center,
                      Color.new(64, 64, 64), Color.new(176, 176, 176)])
        pbDrawTextPositions(overlay, textpos)
        imagepos.push(["Graphics/UI/category", 436, 116, 0, category * 28, 64, 28])
        if @sprites["commands"].index < @moves.length - 1
          imagepos.push(["Graphics/UI/Move Reminder/buttons", 48, 350, 0, 0, 76, 32])
        end
        if @sprites["commands"].index > 0
          imagepos.push(["Graphics/UI/Move Reminder/buttons", 134, 350, 76, 0, 76, 32])
        end
        pbDrawImagePositions(overlay, imagepos)
        drawTextEx(overlay, 272, 216, 230, 5, selMoveData.description,
                   Color.new(64, 64, 64), Color.new(176, 176, 176))
      end
end

class MoveRelearnerScreen
    alias pbCustomGetRelearnableMoves pbGetRelearnableMoves
    def pbGetRelearnableMoves(pokemon)
        moves = pbCustomGetRelearnableMoves(pokemon)
        moves = moves | [] # Remove duplicates
        new_moves = []
        for move in moves
          new_moves.push([move, nil])
        end
        return new_moves if !Settings::SHOW_MTS_MOS_IN_MOVE_RELEARNER
        tm_moves = pbGetTMMoves(pokemon) 
        
        for tm in tm_moves
            if !moves.include?(tm[0])
                new_moves.push([tm[0], tm[1]])
            end
        end
        return new_moves
    end

    def pbStartScreen(pkmn)
        moves = pbGetRelearnableMoves(pkmn)
        return false if moves.length < 1 
        @scene.pbStartScene(pkmn, moves)
        loop do
          move = @scene.pbChooseMove
          if move
            if @scene.pbConfirm(_INTL("¿Enseñar {1}?", GameData::Move.get(move[0]).name))
              if pbLearnMove(pkmn, move[0])
                $stats.moves_taught_by_reminder += 1
                @scene.pbEndScene
                pbRelearnMoveScreen(pkmn) if !Settings::CLOSE_MOVE_RELEARNER_AFTER_TEACHING_MOVE
                return true
              end
            end
          elsif @scene.pbConfirm(_INTL("¿Prefieres que {1} no aprenda un movimiento nuevo?", pkmn.name))
            @scene.pbEndScene
            return false
          end
        end
    end
end

def pbGetTMMoves(pokemon)
    tmmoves = []
    for item_aux in $bag.pockets[4]
      item = GameData::Item.get(item_aux[0])
      if item.is_machine?
        machine = item.move
        tmorhm = item.is_HM? ? "MO" : "MT"
        if pokemon.compatible_with_move?(machine) && !pokemon.hasMove?(machine)
          tmmoves.push([machine, tmorhm])
        end
      end
    end
    return tmmoves
end
