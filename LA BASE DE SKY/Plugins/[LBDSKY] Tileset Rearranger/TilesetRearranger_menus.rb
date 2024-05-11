#===============================================================================
#
#===============================================================================
class TilesetRearranger
  def choose_tileset
    commands = []
    for i in 1...@tilesets_data.length
      commands.push(sprintf("%03d %s", i, @tilesets_data[i].name))
    end
    ret = pbShowCommands(nil, commands, -1, (@tileset_id || 1) - 1)
    return false if ret < 0
    load_tileset(ret + 1)
    return true
  end

  def open_menu
    commands = [
       _INTL("Go to bottom"),
       _INTL("Go to top"),
       _INTL("Clear all unused tiles"),
       _INTL("Delete all unused rows"),
       _INTL("List maps using this tileset"),
       _INTL("Change tileset"),
       _INTL("Cancel")
    ]
    case pbShowCommands(nil, commands, -1)
    when 0   # Go to bottom
      update_cursor_position(0, @height)
    when 1   # Go to top
      update_cursor_position(0, -@height)
    when 2   # Clear all unused tiles
      add_to_history
      clear_unused_tiles_in_area(0, 0, TILES_PER_ROW, @height)
      draw_help_text
    when 3   # Delete all unused rows
      add_to_history
      row = 0
      did_something = false
      loop do
        break if row >= @height
        used = false
        for i in 0...TILES_PER_ROW
          tile_id = @tile_ID_map[row * TILES_PER_ROW + i]
          next if !tile_id || tile_id < 0 || !@used_ids[TILESET_START_ID + tile_id]
          used = true
          break
        end
        if used
          row += 1
          next
        end
        did_something = true
        # Row is empty, delete it
        if @height > 1
          TILES_PER_ROW.times { @tile_ID_map.delete_at(row * TILES_PER_ROW) }
          @height -= 1
        else
          clear_unused_tiles_in_area(0, 0, TILES_PER_ROW, @height)
          break
        end
      end
      if did_something
        ensure_cursor_and_tileset_on_screen
      else
        @history.pop
      end
      draw_tileset
      draw_cursor
      draw_title_text
      draw_help_text
    when 4   # List maps using this tileset
      if @tilesets_usage[@tileset_id] && @tilesets_usage[@tileset_id].length > 0
        map_names = []
        @tilesets_usage[@tileset_id].each do |map_id|
          map_names.push(sprintf("%03d: %s", map_id, @map_names[map_id]))
        end
        map_names.sort!
        map_names.insert(0, _ISPRINTF("Maps using tileset {1:03d}: {2:s}:", @tileset_id, @tilesets_data[@tileset_id].name))
        pbShowCommands(nil, map_names, -1)
      else
        pbMessage(_ISPRINTF("No maps use tileset {1:03d}: {2:s}.", @tileset_id, @tilesets_data[@tileset_id].name))
      end
    when 5   # Change tileset
      choose_tileset
    end
  end
end
