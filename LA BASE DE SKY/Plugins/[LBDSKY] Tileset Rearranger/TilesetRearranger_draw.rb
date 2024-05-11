#===============================================================================
#
#===============================================================================
class TilesetRearranger
  def draw_tile_onto_bitmap(bitmap, tile_x, tile_y, tile_id, background = false)
    if tile_id < 0
      bitmap.blt(tile_x, tile_y, @blank_tile_bitmap, Rect.new(0, 0, TILE_SIZE, TILE_SIZE))
    else
      bitmap.fill_rect(tile_x, tile_y, TILE_SIZE, TILE_SIZE, Color.new(255, 0, 255)) if background
      @tilehelper.bltTile(bitmap, tile_x, tile_y, tile_id)
    end
  end

  # Draws the tileset on the left.
  def draw_tileset
    @sprites["tileset"].bitmap.clear
    for yy in 0...NUM_ROWS_VISIBLE
      id_y_offset = (@top_y + yy) * TILES_PER_ROW
      for xx in 0...TILES_PER_ROW
        id = @tile_ID_map[id_y_offset + xx]
        break if !id
        tile_id = (id < 0) ? id : TILESET_START_ID + id
        draw_tile_onto_bitmap(@sprites["tileset"].bitmap, xx * TILE_SIZE, yy * TILE_SIZE, tile_id, true)
      end
    end
    draw_tileset_overlay
    draw_scroll_bar
  end

  # Draws "used tile" icon over tiles in use by a map.
  def draw_tileset_overlay
    star_rect = Rect.new(0, 0, TILE_SIZE, TILE_SIZE)
    for yy in 0...NUM_ROWS_VISIBLE
      id_y_offset = (@top_y + yy) * TILES_PER_ROW
      for xx in 0...TILES_PER_ROW
        id = @tile_ID_map[id_y_offset + xx]
        next if !id || id < 0
        if SHOW_LIKELY_BLANKS && @likely_blanks[id]
          @sprites["tileset"].bitmap.blt(xx * TILE_SIZE, yy * TILE_SIZE, @likely_blank_bitmap, star_rect)
        end
        if @used_ids[TILESET_START_ID + id]
          @sprites["tileset"].bitmap.blt(xx * TILE_SIZE, yy * TILE_SIZE, @star_bitmap, star_rect)
        end
      end
    end
  end

  def draw_scroll_bar
    bitmap = @sprites["scroll_bar"].bitmap
    bitmap.clear
    # Background line
    bitmap.fill_rect(bitmap.width / 2 - 2, 0, 4, SCREEN_HEIGHT, CURSOR_OUTLINE_COLOR)
    return if @height <= NUM_ROWS_VISIBLE
    # Slider
    slider_width = bitmap.width - 4
    slider_height = (SCREEN_HEIGHT * NUM_ROWS_VISIBLE.to_f / @height).round
    slider_height = 8 if slider_height < 8
    y_pos = ((SCREEN_HEIGHT - slider_height) * @top_y.to_f / (@height - NUM_ROWS_VISIBLE)).round
    bitmap.fill_rect((bitmap.width - slider_width) / 2,     y_pos,     slider_width,     slider_height,     CURSOR_OUTLINE_COLOR)
    bitmap.fill_rect((bitmap.width - slider_width) / 2 + 2, y_pos + 2, slider_width - 4, slider_height - 4, CURSOR_COLOR)
  end

  def draw_preselected_area_on_tileset(full_width = false)
    area_top_x = (full_width) ? 0 : @selected_x
    area_width = (full_width) ? TILES_PER_ROW : @selected_width
    pre_x = area_top_x * TILE_SIZE + TILESET_OFFSET_X
    pre_y = (@selected_y - @top_y) * TILE_SIZE + TILESET_OFFSET_Y
    pre_width = area_width * TILE_SIZE
    pre_height = @selected_height * TILE_SIZE
    bitmap = @sprites["cursor"].bitmap
    bitmap.fill_rect(pre_x,                 pre_y,                  pre_width, 4,  SELECTION_COLOR)
    bitmap.fill_rect(pre_x,                 pre_y,                  4, pre_height, SELECTION_COLOR)
    bitmap.fill_rect(pre_x,                 pre_y + pre_height - 4, pre_width, 4,  SELECTION_COLOR)
    bitmap.fill_rect(pre_x + pre_width - 4, pre_y,                  4, pre_height, SELECTION_COLOR)
  end

  def draw_box_cursor(full_width = false)
    cursor_top_x = (full_width) ? 0 : @x
    cursor_top_y = @y
    cursor_width = (full_width) ? TILES_PER_ROW : 1
    cursor_height = 1
    if @selected_x >= 0 || @selected_y >= 0
      if @selected_width > 0 || @selected_height > 0
        cursor_width = @selected_width if !full_width
        cursor_height = @selected_height
      else
        cursor_top_x = [@x, @selected_x].min if !full_width
        cursor_top_y = [@y, @selected_y].min
        cursor_width = [@x, @selected_x].max - [@x, @selected_x].min + 1 if !full_width
        cursor_height = [@y, @selected_y].max - [@y, @selected_y].min + 1
      end
    end
    cursor_x = cursor_top_x * TILE_SIZE + TILESET_OFFSET_X
    cursor_y = (cursor_top_y - @top_y) * TILE_SIZE + TILESET_OFFSET_Y
    cursor_width = cursor_width * TILE_SIZE
    cursor_height = cursor_height * TILE_SIZE
    bitmap = @sprites["cursor"].bitmap
    bitmap.fill_rect(cursor_x - 2,                cursor_y - 2,                 cursor_width + 4, 8,  CURSOR_OUTLINE_COLOR)
    bitmap.fill_rect(cursor_x - 2,                cursor_y - 2,                 8, cursor_height + 4, CURSOR_OUTLINE_COLOR)
    bitmap.fill_rect(cursor_x - 2,                cursor_y + cursor_height - 6, cursor_width + 4, 8,  CURSOR_OUTLINE_COLOR)
    bitmap.fill_rect(cursor_x + cursor_width - 6, cursor_y - 2,                 8, cursor_height + 4, CURSOR_OUTLINE_COLOR)
    bitmap.fill_rect(cursor_x,                    cursor_y,                     cursor_width, 4,      CURSOR_COLOR)
    bitmap.fill_rect(cursor_x,                    cursor_y,                     4, cursor_height,     CURSOR_COLOR)
    bitmap.fill_rect(cursor_x,                    cursor_y + cursor_height - 4, cursor_width, 4,      CURSOR_COLOR)
    bitmap.fill_rect(cursor_x + cursor_width - 4, cursor_y,                     4, cursor_height,     CURSOR_COLOR)
  end

  def draw_insert_row_cursor
    bitmap = @sprites["cursor"].bitmap
    cursor_y = TILESET_OFFSET_Y + (@y - @top_y) * TILE_SIZE
    bitmap.blt(TILESET_OFFSET_X - @arrow_bitmap.width - 2, cursor_y - @arrow_bitmap.height / 2, @arrow_bitmap,
               Rect.new(0, 0, @arrow_bitmap.width, @arrow_bitmap.height))
    bitmap.fill_rect(TILESET_OFFSET_X - 2, cursor_y - 4, TILESET_WIDTH + 4, 8, CURSOR_OUTLINE_COLOR)
    bitmap.fill_rect(TILESET_OFFSET_X,     cursor_y - 2, TILESET_WIDTH,     4, CURSOR_COLOR)
  end

  # Draws the cursor over the tileset. Also draws the selection area if there is one.
  def draw_cursor
    bitmap = @sprites["cursor"].bitmap
    bitmap.clear
    case @mode
    when :swap, :cut_insert, :erase
      draw_preselected_area_on_tileset if @selected_width > 0
      if @mode == :cut_insert && @selected_width > 0
        draw_insert_row_cursor
      else
        draw_box_cursor
      end
    when :move_row
      if @selected_height > 0
        draw_preselected_area_on_tileset(true)
        draw_insert_row_cursor
      else
        draw_box_cursor(true)
      end
    when :add_row
      draw_insert_row_cursor
    when :delete_row
      draw_box_cursor(true)
    end
  end

  # Draws basic instructions or a copy of the selected tiles on the right.
  def draw_tile_selection
    bitmap = @sprites["selection"].bitmap
    bitmap.clear
    case @mode
    when :swap, :cut_insert, :move_row
      if @selected_width == 0 && @selected_height == 0
        case @mode
        when :swap
          pbDrawTextPositions(bitmap, [
            [_INTL("Choose tile(s) to swap"), bitmap.width / 2, (bitmap.height / 2) - 10, 2,
             Color.new(248, 248, 248), Color.new(40, 40, 40)]
          ])
        when :cut_insert
          pbDrawTextPositions(bitmap, [
            [_INTL("Choose tile(s) to cut"), bitmap.width / 2, (bitmap.height / 2) - 10, 2,
             Color.new(248, 248, 248), Color.new(40, 40, 40)]
          ])
        when :move_row
          pbDrawTextPositions(bitmap, [
            [_INTL("Choose row(s) to move"), bitmap.width / 2, (bitmap.height / 2) - 10, 2,
             Color.new(248, 248, 248), Color.new(40, 40, 40)]
          ])
        end
      else
        # Draw selected tiles
        sel_x = (@mode == :move_row) ? 0 : @selected_x
        sel_width = (@mode == :move_row) ? TILES_PER_ROW : @selected_width
        tile_rect = Rect.new(0, 0, TILE_SIZE, TILE_SIZE)
        start_x = (bitmap.width - sel_width * TILE_SIZE) / 2
        start_y = (bitmap.height - @selected_height * TILE_SIZE) / 2
        for yy in 0...@selected_height
          id_y_offset = (@selected_y + yy) * TILES_PER_ROW
          for xx in 0...sel_width
            id = @tile_ID_map[id_y_offset + sel_x + xx]
            break if !id
            tile_id = (id < 0) ? id : TILESET_START_ID + id
            draw_tile_onto_bitmap(bitmap, xx * TILE_SIZE + start_x, yy * TILE_SIZE + start_y, tile_id, true)
          end
        end
        # Draw white box around selected tiles
        outline_width = sel_width * TILE_SIZE
        outline_height = @selected_height * TILE_SIZE
        bitmap.fill_rect(start_x - 1,             start_y - 1,              outline_width + 2, 1,  Color.new(255, 255, 255))
        bitmap.fill_rect(start_x - 1,             start_y - 1,              1, outline_height + 2, Color.new(255, 255, 255))
        bitmap.fill_rect(start_x - 1,             start_y + outline_height, outline_width + 2, 1,  Color.new(255, 255, 255))
        bitmap.fill_rect(start_x + outline_width, start_y - 1,              1, outline_height + 2, Color.new(255, 255, 255))
      end
    when :add_row
      pbDrawTextPositions(bitmap, [
        [_INTL("Insert new row"), bitmap.width / 2, (bitmap.height / 2) - 10, 2, Color.new(248, 248, 248), Color.new(40, 40, 40)]
      ])
    when :erase
      # Draw blank tile
      start_x = (bitmap.width - TILE_SIZE) / 2
      start_y = (bitmap.height - TILE_SIZE) / 2
      bitmap.blt(start_x, start_y, @blank_tile_bitmap, Rect.new(0, 0, @blank_tile_bitmap.width, @blank_tile_bitmap.height))
      # Draw white box around blank tile
      bitmap.fill_rect(start_x - 1,         start_y - 1,         TILE_SIZE + 2, 1, Color.new(255, 255, 255))
      bitmap.fill_rect(start_x - 1,         start_y - 1,         1, TILE_SIZE + 2, Color.new(255, 255, 255))
      bitmap.fill_rect(start_x - 1,         start_y + TILE_SIZE, TILE_SIZE + 2, 1, Color.new(255, 255, 255))
      bitmap.fill_rect(start_x + TILE_SIZE, start_y - 1,         1, TILE_SIZE + 2, Color.new(255, 255, 255))
      # Draw text
      pbDrawTextPositions(bitmap, [
        [_INTL("Erase tile(s)"), bitmap.width / 2, start_y + TILE_SIZE + 16, 2, Color.new(248, 248, 248), Color.new(40, 40, 40)]
      ])
    when :delete_row
      # Draw blank tiles
      start_x = (bitmap.width - (TILES_PER_ROW * TILE_SIZE)) / 2
      start_y = (bitmap.height - TILE_SIZE) / 2
      TILES_PER_ROW.times do |i|
        bitmap.blt(start_x + (i * TILE_SIZE), start_y, @blank_tile_bitmap,
                   Rect.new(0, 0, @blank_tile_bitmap.width, @blank_tile_bitmap.height))
      end
      # Draw white box around blank tiles
      bitmap.fill_rect(start_x - 1,                           start_y - 1,         (TILES_PER_ROW * TILE_SIZE) + 2, 1, Color.new(255, 255, 255))
      bitmap.fill_rect(start_x - 1,                           start_y - 1,         1, TILE_SIZE + 2,                   Color.new(255, 255, 255))
      bitmap.fill_rect(start_x - 1,                           start_y + TILE_SIZE, (TILES_PER_ROW * TILE_SIZE) + 2, 1, Color.new(255, 255, 255))
      bitmap.fill_rect(start_x + (TILES_PER_ROW * TILE_SIZE), start_y - 1,         1, TILE_SIZE + 2,                   Color.new(255, 255, 255))
      # Draw text
      pbDrawTextPositions(bitmap, [
        [_INTL("Delete row"), bitmap.width / 2, start_y + TILE_SIZE + 16, 2, Color.new(248, 248, 248), Color.new(40, 40, 40)]
      ])
    end
  end
end
