#===============================================================================
#
#===============================================================================
class TilesetRearranger
  def load_tileset(id)
    save_positionings
    new_tileset_data = @tilesets_data[id]
    new_tileset_rows = (new_tileset_data.terrain_tags.xsize - TILESET_START_ID) / TILES_PER_ROW
    @tileset_id = id
    @tileset_data = new_tileset_data
    @tilehelper.dispose if @tilehelper
    @tilehelper = TileDrawingHelper.fromTileset(@tileset_data)
    load_positionings
    @height = new_tileset_rows
    @tile_ID_map = Array.new(new_tileset_rows * TILES_PER_ROW) { |i| i }
    find_used_tiles_in_tileset
    find_likely_blank_tiles_in_tileset if SHOW_LIKELY_BLANKS
    clear_history
    clear_selection
    draw_tileset
    draw_title_text
    draw_help_text
  end

  def find_used_tiles_in_tileset
    @used_ids = []
    return if !@tilesets_usage[@tileset_id]
    @tilesets_usage[@tileset_id].each do |id|
      map = load_data(sprintf("Data/Map%03d.rxdata", id))
      # Go through all map tiles
      for y in 0...map.height
        for x in 0...map.width
          for z in 0...3
            tile_id = map.data[x, y, z]
            tile_id = 0 if !tile_id
            @used_ids[tile_id] = true
          end
        end
      end
      # Look through events for tile usage (takes into account events with size)
      map.events.each_value do |event|
        next if !event
        # Get the event's size
        event_width = event_height = 1
        if event.name[/size\((\d+),(\d+)\)/i]
          event_width = $~[1].to_i
          event_height = $~[2].to_i
        end
        # Go through each page of the event in turn to check their graphics
        event.pages.each do |page|
          next if page.graphic.tile_id <= 0
          start_x = (page.graphic.tile_id - TILESET_START_ID) % TILES_PER_ROW
          start_y = (page.graphic.tile_id - TILESET_START_ID) / TILES_PER_ROW
          for yy in 0...event_height
            break if start_y - yy < 0
            for xx in 0...event_width
              next if start_x + xx >= TILES_PER_ROW
              @used_ids[page.graphic.tile_id - yy * TILES_PER_ROW + xx] = true
            end
          end
        end
      end
    end
  end

  def find_likely_blank_tiles_in_tileset
    @likely_blanks ||= []
    @likely_blanks.clear
    should_wrap = @tilehelper.tileset.mega?
    @tile_ID_map.length.times do |i|
      rect = Rect.new((i % TILES_PER_ROW) * TILE_SIZE,
                      (i / TILES_PER_ROW) * TILE_SIZE,
                      TILE_SIZE, TILE_SIZE)
      if should_wrap
        if Kernel.const_defined?(:TilemapRenderer)
          rect = TilemapRenderer::TilesetWrapper.getWrappedRect(rect)
        else
          rect = TileWrap.getWrappedRect(rect)
        end
      end
      found_pixel = false
      TILE_SIZE.times do |x|
        TILE_SIZE.times do |y|
          pixel = @tilehelper.tileset.get_pixel(rect.x + x, rect.y + y)
          found_pixel = true if pixel.alpha > 0
          break if found_pixel
        end
        break if found_pixel
      end
      @likely_blanks[i] = true if !found_pixel
    end
  end

  #-----------------------------------------------------------------------------

  def save_tileset
    if @height > MAX_TILESET_ROWS
      pbMessage(_INTL("This tileset is too tall ({1} rows) and cannot be saved. Please shrink it to at most {2} rows tall.",
                      @height, MAX_TILESET_ROWS))
      return
    end
    # Determine height of tileset (trim off blank rows at bottom)
    tileset_height = @height
    loop do
      used = false
      for i in 0...TILES_PER_ROW
        next if @tile_ID_map[tileset_height * TILES_PER_ROW - 1 - i] == -1
        used = true
        break
      end
      break if used
      tileset_height -= 1
    end
    tileset_height = 1 if tileset_height < 1
    # Generate and save new tileset graphic
    save_tileset_graphic(tileset_height, @tileset_data.tileset_name)
    # Modify data of all maps using this tileset to reflect changes to tile IDs
    save_map_tile_data
    # Modify tileset data to reflect changes to tile IDs
    save_tileset_data(tileset_height)
    # Reload tilesets data, refresh map to account for changes
    $data_tilesets = @tilesets_data
    if $game_map && $MapFactory
      $MapFactory.setup($game_map.map_id)
      $game_player.center($game_player.x, $game_player.y)
      if $scene.is_a?(Scene_Map)
        $scene.disposeSpritesets
        $scene.createSpritesets
      end
    end
    load_tileset(@tileset_id)
    pbMessage(_INTL("Changes saved. To ensure that they are applied properly, close and reopen RPG Maker XP."))
  end

  # Generate and save new tileset graphic.
  def save_tileset_graphic(height, filename)
    bitmap = Bitmap.new(TILESET_WIDTH, height * TILE_SIZE)
    tile_rect = Rect.new(0, 0, TILE_SIZE, TILE_SIZE)
    for yy in 0...height
      for xx in 0...TILES_PER_ROW
        tile_id = @tile_ID_map[yy * TILES_PER_ROW + xx] || -1
        tile_id += TILESET_START_ID if tile_id >= 0
        draw_tile_onto_bitmap(bitmap, xx * TILE_SIZE, yy * TILE_SIZE, tile_id)
      end
    end
    @tilehelper.tileset.to_file("Graphics/Tilesets/" + filename + "_backup.png")
    bitmap.to_file("Graphics/Tilesets/" + filename + ".png")
  end

  # Modify data of all maps using this tileset to reflect changes to tile IDs.
  def save_map_tile_data
    return if !@tilesets_usage[@tileset_id]
    @tilesets_usage[@tileset_id].each do |id|
      filename = sprintf("Data/Map%03d.rxdata", id)
      map = load_data(filename)
      save_data(map, sprintf("Data/Map%03d_backup.rxdata", id))
      # Go through all tiles
      for y in 0...map.height
        for x in 0...map.width
          for z in 0...3
            old_tile_id = map.data[x, y, z] || 0
            if old_tile_id < TILESET_START_ID
              map.data[x, y, z] = old_tile_id   # Just in case it's nil somehow
            else
              map.data[x, y, z] = @tile_ID_map.index(old_tile_id - TILESET_START_ID) + TILESET_START_ID
            end
          end
        end
      end
      # Change tile usage in events
      map.events.each_value do |event|
        next if !event
        event.pages.each do |page|
          next if page.graphic.tile_id <= 0
          page.graphic.tile_id = @tile_ID_map.index(page.graphic.tile_id - TILESET_START_ID) + TILESET_START_ID
        end
      end
      save_data(map, filename)
    end
  end

  # Modify tileset data to reflect changes to tile IDs.
  def save_tileset_data(height)
    save_data(@tilesets_data, "Data/Tilesets_backup.rxdata")
    new_passages = Table.new(TILESET_START_ID + height * TILES_PER_ROW)
    new_priorities = Table.new(TILESET_START_ID + height * TILES_PER_ROW)
    new_terrain_tags = Table.new(TILESET_START_ID + height * TILES_PER_ROW)
    # Fill in table data
    for i in 0...TILESET_START_ID + height * TILES_PER_ROW
      old_id = i
      if i >= TILESET_START_ID
        old_id = @tile_ID_map[i - TILESET_START_ID] || -1
        old_id += TILESET_START_ID if old_id >= 0
      end
      if old_id == -1
        new_passages[i] = 0
        new_priorities[i] = 0
        new_terrain_tags[i] = 0
      else
        new_passages[i] = @tileset_data.passages[old_id] || 0
        new_priorities[i] = @tileset_data.priorities[old_id] || 0
        new_terrain_tags[i] = @tileset_data.terrain_tags[old_id] || 0
      end
    end
    # Apply new tileset data
    @tileset_data.passages = new_passages
    @tileset_data.priorities = new_priorities
    @tileset_data.terrain_tags = new_terrain_tags
    # Save tileset data
    save_data(@tilesets_data, "Data/Tilesets.rxdata")
  end
end
