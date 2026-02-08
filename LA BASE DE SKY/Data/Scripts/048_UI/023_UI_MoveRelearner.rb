#===============================================================================
# Scene class for handling appearance of the screen
#===============================================================================
class MoveRelearner_Scene
  VISIBLEMOVES = 4
  # Layout constants
  POKEICON_X = 320
  POKEICON_Y = 84
  BACKGROUND_Y = 78
  CURSOR_SRC_Y = 72
  CURSOR_SRC_W = 258
  CURSOR_SRC_H = 72
  OVERLAY_WIDTH = Graphics.width
  OVERLAY_HEIGHT = Graphics.height
  COMMAND_LINE_HEIGHT = 32
  TYPE_ICON_W = 64
  TYPE_ICON_H = 28
  TYPE_ICON_Y = 70
  TYPE_SINGLE_X = 400
  TYPE_BASE_X = 366
  TYPE_X_SPACING = 70
  TITLE_X = 16
  TITLE_Y = 14
  TYPE_IMAGE_X = 12
  TYPE_IMAGE_Y_OFFSET = -4
  MOVE_ROW_START_Y = 88
  MOVE_ROW_HEIGHT = 64
  MOVE_NAME_X = 80
  PP_LABEL_X = 112
  PP_LABEL_Y_OFFSET = 32
  PP_VALUE_X = 230
  CURSOR_BASE_Y = 78
  CATEGORY_X = 272
  CATEGORY_Y = 120
  POWER_X = 468
  POWER_Y = 152
  ACCURACY_X = 468
  ACCURACY_Y = 184
  CATEGORY_IMAGE_X = 436
  CATEGORY_IMAGE_Y = 116
  NEXT_BTN_X = 48
  PREV_BTN_X = 134
  BUTTONS_Y = 350
  BUTTON_SRC_X_NEXT = 0
  BUTTON_SRC_X_PREV = 76
  BUTTON_W = 76
  BUTTON_H = 32
  DESCRIPTION_X = 272
  DESCRIPTION_Y = 216
  DESCRIPTION_WIDTH = 230
  DESCRIPTION_LINES = 5

  def pbDisplay(msg, brief = false)
    UIHelper.pbDisplay(@sprites["msgwindow"], msg, brief) { pbUpdate }
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
    @sprites["pokeicon"].x = POKEICON_X
    @sprites["pokeicon"].y = POKEICON_Y
    @sprites["background"] = IconSprite.new(0, 0, @viewport)
    @sprites["background"].setBitmap("Graphics/UI/Move Reminder/cursor")
    @sprites["background"].y = BACKGROUND_Y
    @sprites["background"].src_rect = Rect.new(0, CURSOR_SRC_Y, CURSOR_SRC_W, CURSOR_SRC_H)
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @sprites["commands"] = Window_CommandPokemon.new(moveCommands, COMMAND_LINE_HEIGHT)
    @sprites["commands"].height = COMMAND_LINE_HEIGHT * (VISIBLEMOVES + 1)
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
      type_rect = Rect.new(0, type_number * TYPE_ICON_H, TYPE_ICON_W, TYPE_ICON_H)
      type_x = (@pokemon.types.length == 1) ? TYPE_SINGLE_X : TYPE_BASE_X + (TYPE_X_SPACING * i)
      overlay.blt(type_x, TYPE_ICON_Y, @typebitmap.bitmap, type_rect)
    end
    textpos = [
      [_INTL("¿Enseñar qué movimiento?"), TITLE_X, TITLE_Y, :left, Color.new(88, 88, 80), Color.new(168, 184, 184)]
    ]
    imagepos = []
    yPos = MOVE_ROW_START_Y
    VISIBLEMOVES.times do |i|
      moveobject = @moves[@sprites["commands"].top_item + i]
      if moveobject
        moveData = GameData::Move.get(moveobject)
        type_number = GameData::Type.get(moveData.display_type(@pokemon)).icon_position
        imagepos.push([_INTL("Graphics/UI/types"), TYPE_IMAGE_X, yPos + TYPE_IMAGE_Y_OFFSET, 0, type_number * TYPE_ICON_H, TYPE_ICON_W, TYPE_ICON_H])
        textpos.push([moveData.name, MOVE_NAME_X, yPos, :left, Color.new(248, 248, 248), Color.black])
        textpos.push([_INTL("PP"), PP_LABEL_X, yPos + PP_LABEL_Y_OFFSET, :left, Color.new(64, 64, 64), Color.new(176, 176, 176)])
        if moveData.total_pp > 0
          textpos.push([moveData.total_pp.to_s + "/" + moveData.total_pp.to_s, PP_VALUE_X, yPos + PP_LABEL_Y_OFFSET, :right,
                        Color.new(64, 64, 64), Color.new(176, 176, 176)])
        else
          textpos.push(["--", PP_VALUE_X, yPos + PP_LABEL_Y_OFFSET, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)])
        end
      end
      yPos += MOVE_ROW_HEIGHT
    end
    imagepos.push(["Graphics/UI/Move Reminder/cursor",
                   0, CURSOR_BASE_Y + ((@sprites["commands"].index - @sprites["commands"].top_item) * MOVE_ROW_HEIGHT),
                   0, 0, CURSOR_SRC_W, CURSOR_SRC_H])
    selMoveData = GameData::Move.get(@moves[@sprites["commands"].index])
    power = selMoveData.display_damage(@pokemon)
    category = selMoveData.display_category(@pokemon)
    accuracy = selMoveData.display_accuracy(@pokemon)
    textpos.push([_INTL("CATEGORÍA"), CATEGORY_X, CATEGORY_Y, :left, Color.new(248, 248, 248), Color.black])
    textpos.push([_INTL("POTENCIA"), CATEGORY_X, POWER_Y, :left, Color.new(248, 248, 248), Color.black])
    textpos.push([power <= 1 ? power == 1 ? "???" : "---" : power.to_s, POWER_X, POWER_Y, :center,
                  Color.new(64, 64, 64), Color.new(176, 176, 176)])
    textpos.push([_INTL("PRECISIÓN"), CATEGORY_X, ACCURACY_Y, :left, Color.new(248, 248, 248), Color.black])
    textpos.push([accuracy == 0 ? "---" : "#{accuracy}%", ACCURACY_X, ACCURACY_Y, :center,
                  Color.new(64, 64, 64), Color.new(176, 176, 176)])
    pbDrawTextPositions(overlay, textpos)
    imagepos.push(["Graphics/UI/category", CATEGORY_IMAGE_X, CATEGORY_IMAGE_Y, 0, category * TYPE_ICON_H, TYPE_ICON_W, TYPE_ICON_H])
    if @sprites["commands"].index < @moves.length - 1
      imagepos.push(["Graphics/UI/Move Reminder/buttons", NEXT_BTN_X, BUTTONS_Y, BUTTON_SRC_X_NEXT, 0, BUTTON_W, BUTTON_H])
    end
    if @sprites["commands"].index > 0
      imagepos.push(["Graphics/UI/Move Reminder/buttons", PREV_BTN_X, BUTTONS_Y, BUTTON_SRC_X_PREV, 0, BUTTON_W, BUTTON_H])
    end
    pbDrawImagePositions(overlay, imagepos)
    drawTextEx(overlay, DESCRIPTION_X, DESCRIPTION_Y, DESCRIPTION_WIDTH, DESCRIPTION_LINES, selMoveData.description,
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
          @sprites["background"].y = CURSOR_BASE_Y + ((@sprites["commands"].index - @sprites["commands"].top_item) * MOVE_ROW_HEIGHT)
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
class MoveRelearnerScreen
  def initialize(scene)
    @scene = scene
  end

  def pbGetRelearnableMoves(pkmn)
    return [] if !pkmn || pkmn.egg? || pkmn.shadowPokemon?
    move_data = []
    seen_moves = []
    pkmn.getMoveList.each do |m|
      next if m[0] > pkmn.level || pkmn.hasMove?(m[1])
      move_to_add = m.is_a?(GameData::Move) ? m.id : m[1]
      if !seen_moves.include?(move_to_add)
        seen_moves << move_to_add
        origin = if m[0] == -1
          "Evol."
        elsif m[0] == 0
          "Nv. 1"
        else
          "Nv. #{m[0]}"
        end
        move_data << {move: move_to_add, origin: origin}
      end
    end
    if Settings::MOVE_RELEARNER_CAN_TEACH_MORE_MOVES && pkmn.first_moves
      first_move_data = []
      pkmn.first_moves.each do |i|
        if !seen_moves.include?(i) && !pkmn.hasMove?(i)
          seen_moves << i
          first_move_data << {move: i, origin: "Nv. 1"}
        end
      end
      move_data = first_move_data + move_data
    end
    if Settings::SHOW_MTS_MOS_IN_MOVE_RELEARNER
      tms = pbGetTMMoves(pkmn)
      tms.each do |tm|
        if !seen_moves.include?(tm[0])
          seen_moves << tm[0]
          move_data << {move: tm[0], origin: tm[1]}
        end
      end
    end
    return move_data
  end

  def pbStartScreen(pkmn)
    moves = pbGetRelearnableMoves(pkmn)
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

#===============================================================================
#
#===============================================================================
def pbRelearnMoveScreen(pkmn)
  retval = true
  pbFadeOutIn do
    scene = MoveRelearner_Scene.new
    screen = MoveRelearnerScreen.new(scene)
    retval = screen.pbStartScreen(pkmn)
  end
  return retval
end

