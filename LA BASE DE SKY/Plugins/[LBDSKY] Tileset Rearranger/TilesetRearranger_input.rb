#===============================================================================
#
#===============================================================================
class TilesetRearranger
  def update_mode_input
    case @mode
    when :swap, :cut_insert, :erase
      if @selected_x < 0   # Start selecting tiles
        if Input.trigger?(Input::USE)
          @selected_x = @x
          @selected_y = @y
          draw_help_text
        end
      elsif @selected_width == 0   # Finish selecting tiles
        if !Input.press?(Input::USE)
          sel_x = [@x, @selected_x].min
          @selected_width = [@x, @selected_x].max - sel_x + 1
          @selected_x = sel_x
          sel_y = [@y, @selected_y].min
          @selected_height = [@y, @selected_y].max - sel_y + 1
          @selected_y = sel_y
          case @mode
          when :swap, :cut_insert
            # Reposition cursor
            @x = @selected_x
            @y = @selected_y
            draw_cursor
            draw_tile_selection
          when :erase
            add_to_history
            clear_unused_tiles_in_area(@selected_x, @selected_y, @selected_width, @selected_height)
            clear_selection
            draw_tileset
          end
          draw_help_text
        end
      elsif @mode == :swap   # Finish swapping tiles
        if Input.trigger?(Input::USE)
          if swap_tiles
            clear_selection
            draw_tileset
            draw_help_text
          end
        end
      elsif @mode == :cut_insert   # Finish inserting tiles
        if can_insert_cut_tiles?
          if Input.trigger?(Input::USE)
            add_to_history
            (TILES_PER_ROW * @selected_height).times { @tile_ID_map.insert(@y * TILES_PER_ROW, -1) }
            @height += @selected_height
            @selected_y += @selected_height if @selected_y >= @y
            @x = @selected_x
            if swap_tiles(false)
              ensure_cursor_and_tileset_on_screen
              clear_selection
              draw_tileset
              draw_title_text
              draw_help_text
            end
          end
        end
      end
    when :move_row
      if @selected_y < 0   # Start selecting rows
        if Input.trigger?(Input::USE)
          @selected_y = @y
          draw_help_text
        end
      elsif @selected_height == 0   # Finish selecting rows
        if !Input.press?(Input::USE)
          sel_y = [@y, @selected_y].min
          @selected_height = [@y, @selected_y].max - sel_y + 1
          @selected_y = sel_y
          @y = @selected_y
          draw_cursor
          draw_tile_selection
          draw_help_text
        end
      else   # Finish moving rows
        if Input.trigger?(Input::USE)
          if @y < @selected_y || @y > @selected_y + @selected_height
            add_to_history
            cut_tiles = []
            (@selected_height * TILES_PER_ROW).times do
              cut_tiles.push(@tile_ID_map.slice!(@selected_y * TILES_PER_ROW))
            end
            @y -= @selected_height if @y > @selected_y
            @tile_ID_map.insert(@y * TILES_PER_ROW, cut_tiles).flatten!
          end
          clear_selection
          draw_tileset
          draw_help_text
        end
      end
    when :add_row
      if Input.trigger?(Input::USE)
        add_to_history
        TILES_PER_ROW.times { @tile_ID_map.insert(@y * TILES_PER_ROW, -1) }
        @height += 1
        draw_tileset
        draw_cursor
        draw_title_text
        draw_help_text
      end
    when :delete_row
      if Input.trigger?(Input::USE) && @height > 1
        add_to_history
        if clear_unused_tiles_in_area(0, @y, TILES_PER_ROW, 1)
          TILES_PER_ROW.times { @tile_ID_map.delete_at(@y * TILES_PER_ROW) }
          @height -= 1
          ensure_cursor_and_tileset_on_screen
        end
        draw_tileset
        draw_cursor
        draw_title_text
        draw_help_text
      end
    end
  end

  def update
    if Input.repeat?(Input::UP)
      update_cursor_position(0, Input.press?(Input::CTRL) ? -2 : -1)
    elsif Input.repeat?(Input::DOWN)
      update_cursor_position(0, Input.press?(Input::CTRL) ? 2 : 1)
    elsif Input.repeat?(Input::LEFT) && [:swap, :cut_insert, :erase].include?(@mode)
      update_cursor_position(Input.press?(Input::CTRL) ? -2 : -1, 0)
    elsif Input.repeat?(Input::RIGHT) && [:swap, :cut_insert, :erase].include?(@mode)
      update_cursor_position(Input.press?(Input::CTRL) ? 2 : 1, 0)
    elsif Input.repeat?(Input::JUMPUP)
      update_cursor_position(0, -NUM_ROWS_VISIBLE / 2, true)
    elsif Input.repeat?(Input::JUMPDOWN)
      update_cursor_position(0, NUM_ROWS_VISIBLE / 2, true)
    elsif Input.trigger?(Input::AUX1)   # Undo
      pop_from_history
    elsif Input.trigger?(Input::AUX2)   # Redo
      pop_from_future_history
    elsif Input.trigger?(Input::BACK)   # X: Cancel
      if [:swap, :cut_insert].include?(@mode) && @selected_width > 0
        clear_selection
        draw_help_text
      elsif @mode == :move_row && @selected_height > 0
        clear_selection
        draw_help_text
      elsif ![:swap, :cut_insert, :erase].include?(@mode) || @selected_x < 0
        save_tileset if pbConfirmMessageSerious(_INTL("Save changes?"))
        return false if pbConfirmMessage(_INTL("Exit from the editor?"))
      end
    elsif Input.trigger?(Input::ACTION)   # Z: Toggle mode
      if [:swap, :cut_insert].include?(@mode) && @selected_width > 0
        @swap_mode = (@swap_mode == :swap) ? :cut_insert : :swap
        @mode = @swap_mode
        ensure_cursor_and_tileset_on_screen
        draw_cursor
        draw_title_text
        draw_help_text
      elsif @selected_x < 0 && @selected_y < 0   # Can't toggle mode while selecting tiles
        @mode = {
          :swap       => :move_row,
          :cut_insert => :move_row,
          :move_row   => :add_row,
          :add_row    => :erase,
          :erase      => :delete_row,
          :delete_row => @swap_mode,
        }[@mode]
        ensure_cursor_and_tileset_on_screen
        clear_selection
        draw_title_text
        draw_help_text
      end
    elsif Input.trigger?(Input::SPECIAL)   # D: Open menu
      open_menu if @selected_x < 0 && @selected_y < 0
    else
      update_mode_input
    end
    return true
  end
end
