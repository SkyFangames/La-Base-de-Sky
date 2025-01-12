# Tutor de Movimientos Huevo
# por Skyflyer
# Para ver su uso, mira el NPC de ejemplo del mapa 12 (Condiminio Lugano).


class Pokemon
    def get_egg_moves_full()
        especie = self.species_data
        return especie.egg_moves if !especie.egg_moves.empty?
        prevo = especie.get_previous_species
        return GameData::Species.get_species_form(prevo, especie.form).get_egg_moves if prevo != especie.species
        return especie.egg_moves
    end

    def can_learn_egg_move?
        return false if egg? || shadowPokemon?
        return !get_egg_moves_full().empty?
    end
end



#===============================================================================
# Scene class for handling appearance of the screen
#===============================================================================
class EggMoveLearner_Scene
    VISIBLEMOVES = 4
  
    def pbDisplay(msg, brief = false)
      UIHelper.pbDisplay(@sprites["msgwindow"], msg, brief) { pbUpdate }
    end
  
    def pbConfirm(msg)
      UIHelper.pbConfirm(@sprites["msgwindow"], msg) { pbUpdate }
    end
    
    def pbConfirm(msg)
      UIHelper.pbConfirm(@sprites["msgwindow"], msg) { pbUpdate }
    end
  
    def pbUpdate
      pbUpdateSpriteHash(@sprites)
    end
  
    def pbStartScene(pokemon, moves)
      @pokemon = pokemon
      @moves = moves
      moveCommands = []
      moves.each { |m| moveCommands.push(GameData::Move.get(m).name) }
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
        [_INTL("¿Enseñar qué movimiento?"), 16, 20, :left, Color.new(248, 248, 248), Color.new(104, 104, 104)]
      ]
      imagepos = []
      yPos = 88
      VISIBLEMOVES.times do |i|
        moveobject = @moves[@sprites["commands"].top_item + i]
        if moveobject
          moveData = GameData::Move.get(moveobject)
          type_number = GameData::Type.get(moveData.display_type(@pokemon)).icon_position
          imagepos.push([_INTL("Graphics/UI/types"), 12, yPos - 4, 0, type_number * 28, 64, 28])
          textpos.push([moveData.name, 80, yPos, :left, Color.new(64, 64, 64), Color.new(176, 176, 176)])
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
      selMoveData = GameData::Move.get(@moves[@sprites["commands"].index])
      power = selMoveData.display_damage(@pokemon)
      category = selMoveData.display_category(@pokemon)
      accuracy = selMoveData.display_accuracy(@pokemon)
      textpos.push([_INTL("CATEGORÍA"), 272, 120, :left,  Color.new(64, 64, 64), Color.new(176, 176, 176)])
      textpos.push([_INTL("POTENCIA"), 272, 152, :left,  Color.new(64, 64, 64), Color.new(176, 176, 176)])
      textpos.push([power <= 1 ? power == 1 ? "???" : "---" : power.to_s, 468, 152, :center,
                    Color.new(64, 64, 64), Color.new(176, 176, 176)])
      textpos.push([_INTL("PRECISIÓN"), 272, 184, :left, Color.new(64, 64, 64), Color.new(176, 176, 176)])
      textpos.push([accuracy == 0 ? "---" : "#{accuracy}%", 468, 184, :center,
                    Color.new(64, 64, 64), Color.new(176, 176, 176)])
      pbDrawTextPositions(overlay, textpos)
      imagepos.push(["Graphics/UI/category", 436, 116, 0, category * 28, 64, 28])
      if @sprites["commands"].index < @moves.length - 1
        imagepos.push(["Graphics/UI/Move Reminder/buttons", 48+26, 350+42, 0, 0, 76, 32])
      end
      if @sprites["commands"].index > 0
        imagepos.push(["Graphics/UI/Move Reminder/buttons", 134+26, 350+42, 76, 0, 76, 32])
      end
      pbDrawImagePositions(overlay, imagepos)
      drawTextEx(overlay, 272, 216, 230, 5, selMoveData.description,
                 Color.new(64, 64, 64), Color.new(176, 176, 176))
    end
  
    # Processes the scene
    def pbChooseMove
      oldcmd = -1
      pbActivateWindow(@sprites, "commands") do
        loop do
          oldcmd = @sprites["commands"].index
          Graphics.update
          Input.update
          pbUpdate
          if @sprites["commands"].index != oldcmd
            @sprites["background"].x = 0
            @sprites["background"].y = 78 + ((@sprites["commands"].index - @sprites["commands"].top_item) * 64)
            pbDrawMoveList
          end
          if Input.trigger?(Input::BACK)
            return nil
          elsif Input.trigger?(Input::USE)
            return @moves[@sprites["commands"].index]
          end
        end
      end
    end
  
    # End the scene here
    def pbEndScene
      pbFadeOutAndHide(@sprites) { pbUpdate }
      pbDisposeSpriteHash(@sprites)
      @typebitmap.dispose
      @viewport.dispose
    end
end
  
#===============================================================================
# Screen class for handling game logic
#===============================================================================
class EggMoveLearnerScreen
  def initialize(scene)
    @scene = scene
  end

  def pbGetLearnableEggMoves(pkmn)
    return [] if !pkmn || pkmn.egg? || pkmn.shadowPokemon?
    return pkmn.get_egg_moves_full()
  end

  def pbStartScreen(pkmn)
    moves = pbGetLearnableEggMoves(pkmn)
    @scene.pbStartScene(pkmn, moves)
    loop do
      move = @scene.pbChooseMove
      if move
        if @scene.pbConfirm(_INTL("¿Enseñar {1}?", GameData::Move.get(move).name))
          if pbLearnMove(pkmn, move)
            $stats.moves_taught_by_reminder += 1
            @scene.pbEndScene
            return true
          end
        end
      elsif @scene.pbConfirm(_INTL("¿Dejar de enseñarle un movimiento a {1}?", pkmn.name))
        @scene.pbEndScene
        return false
      end
    end
  end
end
  


def pbLearnEggMoveScreen(pkmn)
    retval = true
    pbFadeOutIn do
      scene = EggMoveLearner_Scene.new
      screen = EggMoveLearnerScreen.new(scene)
      retval = screen.pbStartScreen(pkmn)
    end
    return retval
end
  