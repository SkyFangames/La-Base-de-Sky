#===============================================================================
# Modes:
#   :swap       = swap tiles
#   :cut_insert = cut/insert tiles (an alternate submode of :swap)
#   :erase      = erase tiles
#   :add_row    = insert row
#   :delete_row = delete row
#   :move_row   = move rows
#===============================================================================
class TilesetRearranger
  # Fundamental values, don't change these
  TILE_SIZE            = Game_Map::TILE_WIDTH
  TILES_PER_ROW        = 8
  TILESET_WIDTH        = TILES_PER_ROW * TILE_SIZE   # In pixels
  TILES_PER_AUTOTILE   = 48
  TILESET_START_ID     = TILES_PER_ROW * TILES_PER_AUTOTILE
  MAX_TILESET_ROWS     = Bitmap.max_size / TILE_SIZE   # Number of tiles vertically
  # Size and positioning of screen/elements
  SCREEN_WIDTH         = TILESET_WIDTH * 2 + 128
  SCREEN_HEIGHT        = Settings::SCREEN_HEIGHT * 2
  SCROLL_BAR_WIDTH     = 16
  TILESET_OFFSET_X     = SCROLL_BAR_WIDTH + 32   # To allow cursor to fit on the left for row insertion
  TILESET_OFFSET_Y     = 0     # For the sake of it
  NUM_ROWS_VISIBLE     = (SCREEN_HEIGHT - TILESET_OFFSET_Y) / TILE_SIZE
  # Other numbers
  MAX_SELECTION_HEIGHT = 14    # For swapping tiles only
  HISTORY_LENGTH       = 100   # Arbitrary value, probably big enough
  # Colors
  CURSOR_COLOR         = Color.new(224, 0, 0)       # Red (current cursor)
  CURSOR_OUTLINE_COLOR = Color.new(255, 255, 255)   # White
  SELECTION_COLOR      = Color.new(0, 104, 224)     # Blue (previously selected tiles)
  BLANK_TILE_BG_COLOR  = Color.new(255, 255, 255)   # White background
  BLANK_TILE_X_COLOR   = Color.new(255, 0, 0)       # Red [X] on top
  # Other
  SHOW_LIKELY_BLANKS   = true

  #-----------------------------------------------------------------------------

  def initialize
    @tilesets_data = load_data("Data/Tilesets.rxdata")
    @swap_mode = :swap
    @mode = @swap_mode
    @height = 0
    reset_positionings
    clear_history
    initialize_tileset_allocation_info
    @viewport = Viewport.new(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
    @viewport.z = 99999
    @sprites = {}
    @sprites["title"] = Window_UnformattedTextPokemon.newWithSize("",
       TILESET_OFFSET_X + TILESET_WIDTH, 0, SCREEN_WIDTH - TILESET_OFFSET_X - TILESET_WIDTH, 128, @viewport)
    @sprites["help_text"] = Window_UnformattedTextPokemon.newWithSize(_INTL("Choose tileset to load"),
       TILESET_OFFSET_X + TILESET_WIDTH, SCREEN_HEIGHT - 64, SCREEN_WIDTH - TILESET_OFFSET_X - TILESET_WIDTH, 64, @viewport)
    @sprites["scroll_bar"] = BitmapSprite.new(SCROLL_BAR_WIDTH, SCREEN_HEIGHT, @viewport)
    @sprites["tileset"] = BitmapSprite.new(TILESET_WIDTH, NUM_ROWS_VISIBLE * TILE_SIZE, @viewport)
    @sprites["tileset"].x = TILESET_OFFSET_X
    @sprites["tileset"].y = TILESET_OFFSET_Y
    @sprites["selection"] = BitmapSprite.new(TILESET_WIDTH + 2, MAX_SELECTION_HEIGHT * TILE_SIZE + 2, @viewport)
    @sprites["selection"].x = SCREEN_WIDTH + SCROLL_BAR_WIDTH - TILESET_OFFSET_X - @sprites["selection"].bitmap.width + 1
    @sprites["selection"].y = (SCREEN_HEIGHT - @sprites["selection"].bitmap.height) / 2
    pbSetSystemFont(@sprites["selection"].bitmap)
    @sprites["cursor"] = BitmapSprite.new(SCREEN_WIDTH, SCREEN_HEIGHT, @viewport)
    pbSetSystemFont(@sprites["cursor"].bitmap)
    @sprites["overlay"] = BitmapSprite.new(SCREEN_WIDTH, SCREEN_HEIGHT, @viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    initialize_bitmaps
    draw_title_text
    clear_selection(true)
  end

  # Goes through all maps to find which tileset each uses. Also gets map names.
  def initialize_tileset_allocation_info
    @tilesets_usage = []
    @map_names = []
    map_infos = pbLoadMapInfos
    for id in map_infos.keys
      next if !map_infos[id]
      map = load_data(sprintf("Data/Map%03d.rxdata", id))
      @tilesets_usage[map.tileset_id] = [] if !@tilesets_usage[map.tileset_id]
      @tilesets_usage[map.tileset_id].push(id)
      @map_names[id] = map_infos[id].name
    end
  end

  # Generates graphics used only in this editor.
  def initialize_bitmaps
    # Star bitmap (indicates tiles used by a map)
    @star_bitmap = BitmapWrapper.new(TILE_SIZE, TILE_SIZE)
    star_width = 13
    star = [
      0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 1, 2, 1, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 1, 2, 1, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 1, 2, 2, 2, 1, 0, 0, 0, 0,
      1, 1, 1, 1, 1, 2, 2, 2, 1, 1, 1, 1, 1,
      1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1,
      0, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0,
      0, 0, 1, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0,
      0, 0, 0, 1, 2, 2, 2, 2, 2, 1, 0, 0, 0,
      0, 0, 1, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0,
      0, 0, 1, 2, 2, 2, 2, 2, 2, 2, 1, 0, 0,
      0, 1, 2, 2, 2, 1, 1, 1, 2, 2, 2, 1, 0,
      0, 1, 2, 1, 1, 0, 0, 0, 1, 1, 2, 1, 0,
      0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0
    ]
    x_offset = (TILE_SIZE - star_width) / 2
    y_offset = (TILE_SIZE - (star.length / star_width)) / 2
    star.each_with_index do |val, i|
      next if val == 0
      color = Color.new(255 * (val - 1), 255 * (val - 1), 255 * (val - 1))
      @star_bitmap.fill_rect(x_offset + i % star_width, y_offset + i / star_width, 1, 1, color)
    end
    # Likely blank bitmap
    @likely_blank_bitmap = BitmapWrapper.new(TILE_SIZE, TILE_SIZE)
    4.times do |x|
      4.times do |y|
        col = (x + y).even? ? 0 : 255
        @likely_blank_bitmap.fill_rect(8 * x, 8 * y, 8, 8, Color.new(col, 0, col))
      end
    end
    # Blank tile bitmap (used for cleared tiles: white with red [X])
    @blank_tile_bitmap = BitmapWrapper.new(TILE_SIZE, TILE_SIZE)
    @blank_tile_bitmap.fill_rect(0, 0, TILE_SIZE, TILE_SIZE, BLANK_TILE_BG_COLOR)
    @blank_tile_bitmap.fill_rect(0,             0,             TILE_SIZE, 1, BLANK_TILE_X_COLOR)
    @blank_tile_bitmap.fill_rect(0,             0,             1, TILE_SIZE, BLANK_TILE_X_COLOR)
    @blank_tile_bitmap.fill_rect(0,             TILE_SIZE - 1, TILE_SIZE, 1, BLANK_TILE_X_COLOR)
    @blank_tile_bitmap.fill_rect(TILE_SIZE - 1, 0,             1, TILE_SIZE, BLANK_TILE_X_COLOR)
    for i in 0...TILE_SIZE
      @blank_tile_bitmap.fill_rect(i, i,                 1, 1, BLANK_TILE_X_COLOR)
      @blank_tile_bitmap.fill_rect(i, TILE_SIZE - i - 1, 1, 1, BLANK_TILE_X_COLOR)
    end
    # Arrow cursor (for insertion modes)
    @arrow_bitmap = BitmapWrapper.new(26, 24)
    # red
    @arrow_bitmap.fill_rect(0, 8, 10, 8, CURSOR_OUTLINE_COLOR)
    @arrow_bitmap.fill_rect(10, 0, 5, 24, CURSOR_OUTLINE_COLOR)
    @arrow_bitmap.fill_rect(2, 10, 10, 4, CURSOR_COLOR)
    @arrow_bitmap.fill_rect(12, 2, 3, 20, CURSOR_COLOR)
    11.times do |i|
      @arrow_bitmap.fill_rect(15 + i, i, 1, 24 - (2 * i), CURSOR_OUTLINE_COLOR)
      @arrow_bitmap.fill_rect(15 + i, i + 3, 1, 18 - (2 * i), CURSOR_COLOR) if i < 9
    end
  end

  #-----------------------------------------------------------------------------

  def open_screen
    Graphics.resize_screen(SCREEN_WIDTH, SCREEN_HEIGHT)
    pbSetResizeFactor(1)
    return choose_tileset
  end

  def close_screen
    pbDisposeSpriteHash(@sprites)
    @star_bitmap.dispose
    @likely_blank_bitmap.dispose
    @blank_tile_bitmap.dispose
    @arrow_bitmap.dispose
    @viewport.dispose
    @tilehelper.dispose if @tilehelper
    Graphics.resize_screen(Settings::SCREEN_WIDTH, Settings::SCREEN_HEIGHT)
    pbSetResizeFactor($PokemonSystem.screensize)
  end

  def main
    if open_screen
      loop do
        Graphics.update
        Input.update
        break if !update
      end
    end
    close_screen
  end
end

#===============================================================================
#
#===============================================================================
if Kernel.const_defined?(:MenuHandlers)   # Essentials v20+
  MenuHandlers.add(:debug_menu, :tileset_rearranger, {
    "name"        => _INTL("Tileset Rearranger"),
    "parent"      => :editors_menu,
    "description" => _INTL("Rearrange tiles in tilesets."),
    "effect"      => proc {
      pbFadeOutIn { TilesetRearranger.new.main }
    }
  })
elsif Kernel.const_defined?(:DebugMenuCommands)   # Essentials v19.1 and earlier
  DebugMenuCommands.register("tileset_rearranger", {
    "parent"      => "editorsmenu",
    "name"        => _INTL("Tileset Rearranger"),
    "description" => _INTL("Rearrange tiles in tilesets."),
    "always_show" => true,
    "effect"      => proc { |sprites, viewport|
      pbFadeOutIn { TilesetRearranger.new.main }
    }
  })
end
