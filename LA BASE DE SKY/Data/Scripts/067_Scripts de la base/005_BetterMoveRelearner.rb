#===============================================================================
#
#===============================================================================
class UI::MoveReminderCursor < IconSprite
  attr_accessor :top_index

  CURSOR_WIDTH     = 258
  CURSOR_HEIGHT    = 72
  CURSOR_THICKNESS = 6

  def initialize(viewport = nil)
    super(0, 0, viewport)
    setBitmap("Graphics/UI/Move Reminder/cursor")
    self.src_rect = Rect.new(0, 0, CURSOR_WIDTH, CURSOR_HEIGHT)
    self.z = 1600
    @bg_sprite = IconSprite.new(x, y, viewport)
    @bg_sprite.setBitmap("Graphics/UI/Move Reminder/cursor")
    @bg_sprite.src_rect = Rect.new(0, CURSOR_HEIGHT, CURSOR_WIDTH, CURSOR_HEIGHT)
    @top_index = 0
    self.index = 0
  end

  def dispose
    @bg_sprite.dispose
    @bg_sprite = nil
    super
  end

  def index=(value)
    @index = value
    refresh_position
  end

  def visible=(value)
    super
    @bg_sprite.visible = value
  end

  def refresh_position
    return if @index < 0
    self.x = UI::MoveReminderVisuals::MOVE_LIST_X
    self.y = UI::MoveReminderVisuals::MOVE_LIST_Y - CURSOR_THICKNESS
    self.y += (@index - @top_index) * UI::MoveReminderVisuals::MOVE_LIST_SPACING
    @bg_sprite.x = self.x
    @bg_sprite.y = self.y
  end
end

#===============================================================================
#
#===============================================================================
class UI::MoveReminderVisuals < UI::BaseVisuals
  attr_reader :index

  GRAPHICS_FOLDER   = "Move Reminder/"   # Subfolder in Graphics/UI
  TEXT_COLOR_THEMES = {   # These color themes are added to @sprites[:overlay]
    :default => [Color.new(248, 248, 248), Color.new(0, 0, 0)],   # Base and shadow colour
    :white   => [Color.new(248, 248, 248), Color.new(0, 0, 0)],
    :black   => [Color.new(64, 64, 64), Color.new(176, 176, 176)],
    :header  => [Color.new(88, 88, 80), Color.new(168, 184, 184)]
  }
  MOVE_LIST_X       = 0
  MOVE_LIST_Y       = 84
  MOVE_LIST_SPACING = 64    # Y distance between top of two adjacent move areas
  VISIBLE_MOVES     = 4

  def initialize(pokemon, moves)
    @pokemon   = pokemon
    @moves     = moves
    @top_index = 0
    @index     = 0
    super()
    refresh_cursor
  end

  def initialize_bitmaps
    @bitmaps[:types]   = AnimatedBitmap.new(UI_FOLDER + _INTL("types"))
    @bitmaps[:buttons] = AnimatedBitmap.new(graphics_folder + "buttons")
  end

  def initialize_sprites
    # Pokémon icon
    @sprites[:pokemon_icon] = PokemonIconSprite.new(@pokemon, @viewport)
    @sprites[:pokemon_icon].setOffset(PictureOrigin::CENTER)
    @sprites[:pokemon_icon].x = 314
    @sprites[:pokemon_icon].y = 84
    @sprites[:pokemon_icon].z = 200
    # Cursor
    @sprites[:cursor] = UI::MoveReminderCursor.new(@viewport)
  end

  #-----------------------------------------------------------------------------

  def moves=(move_list)
    @moves = move_list
    @index = @moves.length - 1 if @index >= @moves.length
    refresh_on_index_changed(@index)
    @cursor.visible = false if @moves.empty?
    refresh
  end

  #-----------------------------------------------------------------------------

  def refresh_overlay
    super
    draw_header
    draw_pokemon_type_icons(396, 70, 6)
    draw_moves_list
    draw_move_properties
    draw_buttons
  end

  def draw_header
    draw_text(_INTL("¿Enseñar movimiento?"), 16, 14, theme: :header)
  end

  # x and y are the top left corner of the type icon if there is only one type.
  def draw_pokemon_type_icons(x, y, spacing)
    @pokemon.types.each_with_index do |type, i|
      type_number = GameData::Type.get(type).icon_position
      offset = ((@pokemon.types.length - 1) * (GameData::Type::ICON_SIZE[0] + spacing) / 2)
      offset = (offset / 2) * 2
      type_x = x - offset + ((GameData::Type::ICON_SIZE[0] + spacing) * i)
      draw_image(@bitmaps[:types], type_x, y,
                 0, type_number * GameData::Type::ICON_SIZE[1], *GameData::Type::ICON_SIZE)
    end
  end

  def draw_moves_list
    VISIBLE_MOVES.times do |i|
      move = @moves[@top_index + i]
      next if move.nil?
      draw_move_in_list(move, MOVE_LIST_X, MOVE_LIST_Y + (i * MOVE_LIST_SPACING))
    end
  end

  def draw_move_in_list(move, x, y)
    move_data = GameData::Move.get(move[0])

    # Draw move type icon
    type_number = GameData::Type.get(move_data.display_type(@pokemon)).icon_position
    draw_image(@bitmaps[:types], x + 8, y + 1,
                0, type_number * GameData::Type::ICON_SIZE[1], *GameData::Type::ICON_SIZE)

    # Draw move name
    move_name = move_data.name
    move_name = crop_text(move_name, 230)
    draw_text(move_name, x + 76, y + 6)

    # Draw if move is a TM or HM
    draw_text(move[1], x + 10, y + 36) if move[1]

    # Draw PP text
    if move_data.total_pp > 0
      draw_text(_INTL("PP"), x + 150, y + 38, theme: :black)
      draw_text(sprintf("%d/%d", move_data.total_pp, move_data.total_pp), x + 240, y + 38, align: :right, theme: :black)
    end
  end

  def draw_move_properties
    move = @moves[@index]
    move_data = GameData::Move.get(move[0])
    # Power
    draw_text(_INTL("POTENCIA"), 278, 120)
    power_text = move_data.display_power(@pokemon)
    power_text = "---" if power_text == 0   # Status move
    power_text = "???" if power_text == 1   # Variable power move
    draw_text(power_text, 480, 120, align: :right, theme: :black)
    # Accuracy
    draw_text(_INTL("PRECISIÓN"), 278, 152)
    accuracy = move_data.display_accuracy(@pokemon)
    if accuracy == 0
      draw_text("---", 480, 152, align: :right, theme: :black)
    else
      draw_text(accuracy, 480, 152, align: :right, theme: :black)
      draw_text("%", 480, 152, theme: :black)
    end

    # Draw move category
    draw_text(_INTL("CATEGORÍA"), 278, 184)
    draw_image(UI_FOLDER + "category", 455, 178,
               0, move_data.display_category(@pokemon) * GameData::Move::CATEGORY_ICON_SIZE[1], *GameData::Move::CATEGORY_ICON_SIZE)

    # Description
    draw_paragraph_text(move_data.description, 275, 215, 246, 6, theme: :black)
  end

  def draw_buttons
    draw_image(@bitmaps[:buttons], 44, 350, 0, 0, 76, 32) if @top_index < @moves.length - VISIBLE_MOVES
    draw_image(@bitmaps[:buttons], 132, 350, 76, 0, 76, 32) if @top_index > 0
  end

  #-----------------------------------------------------------------------------

  def refresh_cursor
    @sprites[:cursor].top_index = @top_index
    @sprites[:cursor].index = @index
  end

  def refresh_on_index_changed(old_index)
    pbPlayCursorSE
    # Change @top_index to keep @index in the middle of the visible list (or as
    # close to it as possible)
    middle_range_top = (VISIBLE_MOVES / 2) - ((VISIBLE_MOVES + 1) % 2)
    middle_range_bottom = VISIBLE_MOVES / 2
    if @index < @top_index + middle_range_top
      @top_index = @index - middle_range_top
    elsif @index > @top_index + middle_range_bottom
      @top_index = @index - middle_range_bottom
    end
    @top_index = @top_index.clamp(0, [@moves.length - VISIBLE_MOVES, 0].max)
    refresh_cursor
    refresh
  end

  #-----------------------------------------------------------------------------

  def update_input
    # Check for movement to a new move
    update_cursor_movement
    # Check for interaction
    if Input.trigger?(Input::USE)
      return update_interaction(Input::USE)
    elsif Input.trigger?(Input::BACK)
      return update_interaction(Input::BACK)
    elsif Input.trigger?(Input::ACTION)
      return update_interaction(Input::ACTION)
    end
    return nil
  end

  def update_cursor_movement
    # Check for movement to a new move
    if Input.repeat?(Input::UP)
      @index -= 1
      if Input.trigger?(Input::UP)
        @index = @moves.length - 1 if @index < 0   # Wrap around
      else
        @index = 0 if @index < 0
      end
    elsif Input.repeat?(Input::DOWN)
      @index += 1
      if Input.trigger?(Input::DOWN)
        @index = 0 if @index >= @moves.length   # Wrap around
      else
        @index = @moves.length - 1 if @index >= @moves.length
      end
    elsif Input.repeat?(Input::JUMPUP)
      @index -= VISIBLE_MOVES
      @index = 0 if @index < 0
    elsif Input.repeat?(Input::JUMPDOWN)
      @index += VISIBLE_MOVES
      @index = @moves.length - 1 if @index >= @moves.length
    end
    return false
  end

  def update_interaction(input)
    case input
    when Input::USE
      pbPlayDecisionSE
      return :learn
    when Input::BACK
      pbPlayCloseMenuSE
      return :quit
    end
    return nil
  end
end

#===============================================================================
#
#===============================================================================
class UI::MoveReminder < UI::BaseScreen
  attr_reader :pokemon

  SCREEN_ID = :move_reminder_screen

  # mode is either :normal or :single.
  def initialize(pokemon, mode: :normal)
    @pokemon = pokemon
    @mode = mode
    @moves = []
    generate_move_list
    super()
  end

  def initialize_visuals
    @visuals = UI::MoveReminderVisuals.new(@pokemon, @moves)
  end

  #-----------------------------------------------------------------------------

  def generate_move_list
    @moves = []
    return if !@pokemon || @pokemon.egg? || @pokemon.shadowPokemon?
    @pokemon.getMoveList.each do |move|
      next if move[0] > @pokemon.level || @pokemon.hasMove?(move[1])
      @moves.push(move[1]) if !@moves.include?(move[1])
    end
    if Settings::MOVE_RELEARNER_CAN_TEACH_MORE_MOVES && @pokemon.first_moves
      first_moves = []
      @pokemon.first_moves.each do |move|
        first_moves.push(move) if !@moves.include?(move) && !@pokemon.hasMove?(move)
      end
      @moves = first_moves + @moves   # List first moves before level-up moves
    end
    @moves = @moves | []   # remove duplicates

    new_moves = []
    for move in @moves
      new_moves.push([move, nil])
    end
    @moves = new_moves
    if Settings::SHOW_MTS_MOS_IN_MOVE_RELEARNER
      tms = pbGetTMMoves(@pokemon)
      for tm in tms
        if !@moves.include?(tm[0])
            new_moves.push([tm[0], tm[1]])
        end
      end
    end
    @moves = new_moves
  end

  def refresh_move_list
    generate_move_list
    @visuals.moves = @moves
  end

  #-----------------------------------------------------------------------------

  def move
    return @moves[self.index]
  end

  #-----------------------------------------------------------------------------

  def main
    return if @disposed
    start_screen
    loop do
      on_start_main_loop
      command = @visuals.navigate
      break if command == :quit && (@mode == @normal ||
               show_confirm_message(_INTL("¿Prefieres que {1} no aprenda un movimiento nuevo?", @pokemon.name)))
      perform_action(command)
      if @moves.empty?
        show_message(_INTL("No hay más movimientos para que {1} aprenda.", @pokemon.name))
        break
      end
      if @disposed
        @result = true
        break
      end
    end
    end_screen
    return @result
  end
end

#===============================================================================
# Actions that can be triggered in the Move Reminder screen.
#===============================================================================
UIActionHandlers.add(UI::MoveReminder::SCREEN_ID, :learn, {
  :effect => proc { |screen|
    # move Array len 2
    # Possible values
    # [:MOVE_ID, nil]
    # [:MOVE_ID, "TM"]
    # [:MOVE_ID, "HM"]
    move = screen.move
    if screen.show_confirm_message(_INTL("¿Enseñar {1}?", GameData::Move.get(move[0]).name))
      is_machine = move[1] ? true : false
      if pbLearnMove(screen.pokemon, move[0], false, is_machine)
        $stats.moves_taught_by_reminder += 1 if !is_machine
        $stats.moves_taught_by_item += 1 if is_machine
        if screen.mode == :normal
          screen.refresh_move_list
        else
          screen.end_screen
        end
      end
    end
  }
})

#===============================================================================
#
#===============================================================================
def pbRelearnMoveScreen(pkmn)
  ret = true
  pbFadeOutIn do
    ret = UI::MoveReminder.new(pkmn, mode: :single).main
  end
  return ret
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
