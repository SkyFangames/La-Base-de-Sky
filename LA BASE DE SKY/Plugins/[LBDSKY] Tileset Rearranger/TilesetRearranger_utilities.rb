#===============================================================================
#
#===============================================================================
class TilesetRearranger
  def areas_overlap?
    return false if @mode != :swap || @selected_x < 0 || @selected_width == 0
    return false if @x + @selected_width <= @selected_x
    return false if @selected_x + @selected_width <= @x
    return false if @y + @selected_height <= @selected_y
    return false if @selected_y + @selected_height <= @y
    return true
  end

  def can_swap_areas?
    return true if !areas_overlap?
    return true if @x == @selected_x || @y == @selected_y
    return false
  end

  def can_insert_cut_tiles?
    return false if @mode != :cut_insert
    return false if @y > @selected_y && @y < @selected_y + @selected_height
    return true
  end

  def reset_positionings
    @all_positionings ||= []
    @x = 0
    @y = 0
    @top_y = 0
  end

  def save_positionings
    return if !@tileset_id || @tileset_id <= 0
    @all_positionings[@tileset_id] = [@x, @y, @top_y]
  end

  def load_positionings
    @all_positionings[@tileset_id] ||= [0, 0, 0]
    @x, @y, @top_y = @all_positionings[@tileset_id]
  end

  def clear_selection(screen_start = false)
    @selected_x = -1
    @selected_y = -1
    @selected_width = 0
    @selected_height = 0
    if !screen_start
      draw_cursor
      draw_tile_selection
    end
  end

  def clear_history
    @history = []
    @future_history = []
  end

  def add_to_history(by_redo = false)
    @history.push([@tile_ID_map.clone, @height])
    @history.shift if @history.length > HISTORY_LENGTH
    @future_history.clear if !by_redo
  end

  def pop_from_history
    return if @history.length == 0
    add_to_future_history
    last_state = @history.pop
    @tile_ID_map = last_state[0]
    @height = last_state[1]
    ensure_cursor_and_tileset_on_screen
    clear_selection
    draw_tileset
    draw_title_text
    draw_help_text
  end

  def add_to_future_history
    @future_history.push([@tile_ID_map.clone, @height])
  end

  def pop_from_future_history
    return if @future_history.length == 0
    add_to_history(true)
    last_state = @future_history.pop
    @tile_ID_map = last_state[0]
    @height = last_state[1]
    ensure_cursor_and_tileset_on_screen
    clear_selection
    draw_tileset
    draw_title_text
    draw_help_text
  end

  # For use with mode :swap only.
  def swap_tiles(record_history = true)
    if @x == @selected_x && @y == @selected_y
      # Areas are in the same place; just cancel the swap
      return true
    elsif !areas_overlap?
      # Areas do not overlap at all; simply swap each tile in turn
      add_to_history if record_history
      for j in 0...@selected_height
        for i in 0...@selected_width
          offset = j * TILES_PER_ROW + i
          first_idx = @y * TILES_PER_ROW + @x + offset
          second_idx = @selected_y * TILES_PER_ROW + @selected_x + offset
          @tile_ID_map[first_idx], @tile_ID_map[second_idx] = @tile_ID_map[second_idx], @tile_ID_map[first_idx]
        end
      end
      return true
    elsif @x == @selected_x   # Areas are aligned vertically
      add_to_history if record_history
      min_y = [@y, @selected_y].min
      max_y = (@y > @selected_y) ? @y + @selected_height : @selected_y + @selected_height
      total_height = max_y - min_y
      # Put affected tiles in a temp array with x and y reversed
      temp_array = []
      for i in 0...@selected_width
        for j in min_y...max_y
          idx = j * TILES_PER_ROW + @x + i
          temp_array.push(@tile_ID_map[idx])
        end
      end
      # Swap tiles round
      for j in 0...@selected_width   # For each row in turn
        row_start_idx = j * total_height
        cut_tiles = []
        @selected_height.times do
          cut_tiles.push(temp_array.slice!(row_start_idx + [@selected_y - @y, 0].max))
        end
        temp_array.insert(row_start_idx + [@y - @selected_y, 0].max, cut_tiles).flatten!
      end
      # Put the temp array back into the main array
      counter = 0
      for i in 0...@selected_width
        for j in min_y...max_y
          idx = j * TILES_PER_ROW + @x + i
          @tile_ID_map[idx] = temp_array[counter]
          counter += 1
        end
      end
      return true
    elsif @y == @selected_y   # Areas are aligned horizontally
      add_to_history if record_history
      for j in 0...@selected_height   # For each row in turn
        row_start_idx = (@selected_y + j) * TILES_PER_ROW
        cut_tiles = []
        @selected_width.times do
          cut_tiles.push(@tile_ID_map.slice!(row_start_idx + @selected_x))
        end
        @tile_ID_map.insert(row_start_idx + @x, cut_tiles).flatten!
      end
      return true
    end
    return false
  end

  def clear_unused_tiles_in_area(start_x, start_y, width, height)
    ret = true
    for yy in 0...height
      y_offset = (start_y + yy) * TILES_PER_ROW
      for xx in 0...width
        position_id = y_offset + start_x + xx
        tile_id = @tile_ID_map[position_id]
        if tile_id && tile_id > 0 && @used_ids[TILESET_START_ID + tile_id]
          ret = false
          next
        end
        @tile_ID_map[position_id] = -1
      end
    end
    draw_tileset
    return ret
  end

  #-----------------------------------------------------------------------------

  def ensure_cursor_and_tileset_on_screen
    # Ensure cursor position is within tileset
    if (@mode == :cut_insert && @selected_width > 0) ||
       (@mode == :move_row && @selected_height > 0) ||
       @mode == :add_row
      @y = @y.clamp(0, @height)
    else
      @y = @y.clamp(0, @height - 1)
    end
    # Ensure bottom of cursor isn't below the bottom of the screen
    plus_height = 0
    plus_height = @selected_height - 1 if @mode == :swap && @selected_height > 0
    @top_y = @y - NUM_ROWS_VISIBLE + plus_height + 1 if @y + plus_height >= @top_y + NUM_ROWS_VISIBLE
    # Ensure top of cursor isn't above the top of the screen
    @top_y = @y if @top_y > @y
    # Ensure tileset touches the top/bottom of the screen
    @top_y = @height - NUM_ROWS_VISIBLE if @top_y > @height - NUM_ROWS_VISIBLE
    @top_y = 0 if @top_y < 0
  end

  def update_cursor_position(x_offset, y_offset, centre_after = false)
    old_x = @x
    old_y = @y
    old_top_y = @top_y
    if x_offset != 0
      @x += x_offset
      @x = @x.clamp(0, TILES_PER_ROW - 1)
      if @mode == :swap && @selected_width > 0
        @x = @x.clamp(0, TILES_PER_ROW - @selected_width)
      end
    end
    if y_offset != 0
      @y += y_offset
      if [:swap, :cut_insert, :move_row].include?(@mode)
        if @selected_height > 0
          @y = @y.clamp(0, @height - @selected_height) if @mode == :swap
        elsif @selected_x >= 0 || @selected_y > 0
          @y = @y.clamp(@selected_y - MAX_SELECTION_HEIGHT + 1, @selected_y + MAX_SELECTION_HEIGHT - 1)
        end
      end
      @top_y = @y - (NUM_ROWS_VISIBLE / 2) if centre_after
      ensure_cursor_and_tileset_on_screen
    end
    draw_tileset if @top_y != old_top_y
    if @x != old_x || @y != old_y
      draw_cursor
      draw_help_text
    end
  end
end
