#===============================================================================
# CREDITOS
# Golisopod User, Wolf PP, Marin, Zik
# Website    = https://www.youtube.com/watch?v=dQw4w9WgXcQ
#===============================================================================
module OWShadowSettings
  # Set this to true if you want the event name and character name blacklists to be case sensitive.
  CASE_SENSITIVE_BLACKLISTS = false

  # If an event name contains one of these words, it will not have a shadow.
  SHADOWLESS_EVENT_NAME     = [
    "door", "FlechaSalida", "nurse", "Enfermera", "Healing balls", "Balls curativas", "Mart","Tendero", "SmashRock", "RocaRompible", "StrengthBoulder", "PiedraFuerza",
    "CutTree", "ArbolCorte", "HeadbuttTree", "ArbolGolpeCabeza", "BerryPlant", "Planta Bayas", ".shadowless", ".noshadow", ".sl", "Entrada Mazmorra Bosque", "Entrada Cueva", "Relic Stone",
    "Escalera", "Puerta"
  ]

  # If the character file and event uses contains one of these words in its filename, it will not have a shadow.
  SHADOWLESS_CHARACTER_NAME = ["nil"]

  # If an event stands on a tile with one of these terrain tags, it will not have a shadow.
  # (Names can be seen in the script section "Terrain Tag")
  SHADOWLESS_TERRAIN_NAME   = [
    :Grass, :DeepWater, :StillWater, :Water, :Waterfall, :WaterfallCrest,
    :Puddle
  ]

  # Hash to adjust the shadow radius for specific character files.
  # Key: Part of the filename (e.g., "PIKACHU").
  # Value: Integer to add/subtract from the calculated logical width (e.g., -2).
  CHARACTER_RADIUS_FIX = {
    "PIKACHU" => -2,
    "SNORLAX" => 8
  }
end

#-------------------------------------------------------------------------------
# New Class for Shadow object
#-------------------------------------------------------------------------------
class Sprite_OWShadow
  attr_reader :visible
  #-----------------------------------------------------------------------------
  # Initialize a shadow sprite based on the name of the event
  #-----------------------------------------------------------------------------
  def initialize(sprite, event, viewport = nil)
    @rsprite  = sprite
    @event    = event
    @viewport = viewport
    @sprite   = Sprite.new(viewport)
    @disposed = false
    @remove   = false
    
    # Store data for both directions
    @shadow_data_down = nil
    @shadow_data_up   = nil
    
    update
  end
  #-----------------------------------------------------------------------------
  # Helper to calculate coordinates for a specific row
  #-----------------------------------------------------------------------------
  def get_frame_coordinates(row_direction)
    rect = @rsprite.src_rect
    cw = rect.width
    ch = rect.height   
    sx = 0
    sy = 0   

    if @event.respond_to?(:character_name) && @event.character_name && !@event.character_name.empty?
      is_single_sheet = @event.character_name[/^[\$\!]./] ? true : false     
      if is_single_sheet
        sx = 0
        sy = ch * row_direction
      else
        idx = (@event.respond_to?(:character_index) ? @event.character_index : 0)
        char_col = idx % 4
        char_row = idx / 4        
        frames_per_char = (@rsprite.bitmap.width / cw) / 4
        frames_per_char = 4 if frames_per_char < 1        
        sx = char_col * (frames_per_char * cw)
        sy = (char_row * (4 * ch)) + (ch * row_direction)
      end
    end    

    if sx + cw > @rsprite.bitmap.width || sy + ch > @rsprite.bitmap.height
      return rect.x, rect.y
    end   

    return sx, sy
  end
  #-----------------------------------------------------------------------------
  # Analyzes pixel density to ignore thin adornments
  #-----------------------------------------------------------------------------
  def analyze_footprint(bitmap, sx, sy, cw, ch)
    # Settings for "Smart" detection
    scan_height = 12
    density_threshold = 3
    
    scan_y_start = [ch - scan_height, 0].max
    scan_y_end   = ch
    
    min_x = cw
    max_x = 0
    found_body = false

    (0...cw).each do |x|
      pixel_count = 0
      (scan_y_start...scan_y_end).each do |y|
        next if (sx + x) >= bitmap.width || (sy + y) >= bitmap.height
        if bitmap.get_pixel(sx + x, sy + y).alpha > 20 # Tolerance for semi-transparency
          pixel_count += 1
        end
      end
      
      # If this has enough "mass", it's the start of the body
      if pixel_count >= density_threshold
        min_x = x
        found_body = true
        break
      end
    end

    if found_body
      (0...cw).to_a.reverse.each do |x|
        pixel_count = 0
        (scan_y_start...scan_y_end).each do |y|
          next if (sx + x) >= bitmap.width || (sy + y) >= bitmap.height
          if bitmap.get_pixel(sx + x, sy + y).alpha > 20
            pixel_count += 1
          end
        end
        
        if pixel_count >= density_threshold
          max_x = x
          break
        end
      end
      
      real_width = max_x - min_x + 1
      
      # Calculate Offset
      feet_center = min_x + (real_width / 2.0)
      frame_center = cw / 2.0
      offset_x = feet_center - frame_center
      
      return real_width, offset_x
    else
      return fallback_scan(bitmap, sx, sy, cw, ch)
    end
  end
  #-----------------------------------------------------------------------------
  # Fallback scan for sprites with very thin legs/floating
  #-----------------------------------------------------------------------------
  def fallback_scan(bitmap, sx, sy, cw, ch)
    scan_y_start = [ch - 8, 0].max
    scan_y_end = ch
    min_x = cw
    max_x = 0
    found = false
    
    (0...cw).each do |x|
      (scan_y_start...scan_y_end).each do |y|
        next if (sx + x) >= bitmap.width || (sy + y) >= bitmap.height
        if bitmap.get_pixel(sx + x, sy + y).alpha > 0
          min_x = x
          found = true
          break
        end
      end
      break if found
    end
    
    if found
      (0...cw).to_a.reverse.each do |x|
        (scan_y_start...scan_y_end).each do |y|
          next if (sx + x) >= bitmap.width || (sy + y) >= bitmap.height
          if bitmap.get_pixel(sx + x, sy + y).alpha > 0
            max_x = x
            break
          end
        end
        break if max_x > 0
      end
      real_width = max_x - min_x + 1
      feet_center = min_x + (real_width / 2.0)
      frame_center = cw / 2.0
      return real_width, (feet_center - frame_center)
    end
    
    return cw, 0
  end
  #-----------------------------------------------------------------------------
  # Generate a shadow bitmap and offset
  #-----------------------------------------------------------------------------
  def generate_shadow_data(row_direction)
    return nil if !@rsprite.bitmap || @rsprite.disposed?
    
    bitmap = @rsprite.bitmap
    rect = @rsprite.src_rect
    cw = rect.width
    ch = rect.height
    
    # Get coordinates for the specific frame (Down or Up)
    sx, sy = get_frame_coordinates(row_direction)
    real_width, offset_x = analyze_footprint(bitmap, sx, sy, cw, ch)

    # --- Draw Bitmap ---
    logical_width = (real_width * 0.9 / 2).ceil + 4
    
    # Apply Character Radius Fix
    if @event.respond_to?(:character_name) && @event.character_name
      char_name = @event.character_name
      OWShadowSettings::CHARACTER_RADIUS_FIX.each do |key, value|
        if char_name.include?(key)
          logical_width += value
          break
        end
      end
    end
    
    logical_width = [logical_width, 8].max
    logical_width -= 1 if logical_width.odd?    
    logical_height = (logical_width * 0.5).ceil
    logical_height = [logical_height, 4].max
    logical_height += 1 if logical_height.odd?
    
    bmp = Bitmap.new(logical_width * 2, logical_height * 2)
    color = Color.new(0, 0, 0, 80)
    
    cx = logical_width / 2.0 - 0.5
    cy = logical_height / 2.0 - 0.5
    rx = logical_width / 2.0
    ry = logical_height / 2.0

    (0...logical_height).each do |y|
      (0...logical_width).each do |x|
        dx = (x - cx) / rx
        dy = (y - cy) / ry
        if (dx**2 + dy**2) <= 0.9
           bmp.fill_rect(x * 2, y * 2, 2, 2, color)
        end
      end
    end
    
    return { :bitmap => bmp, :offset => offset_x }
  end
  #-----------------------------------------------------------------------------
  # Override the bitmap of the shadow sprite
  #-----------------------------------------------------------------------------
  def set_bitmap(name)
    @shadow_data_down = nil
    @shadow_data_up = nil
    @sprite.dispose if @sprite && !@sprite.disposed?
    @sprite = nil
    @sprite = Sprite.new(@viewport)
    update
  end
  #-----------------------------------------------------------------------------
  # Dispose the shadow bitmap
  #-----------------------------------------------------------------------------
  def dispose
    return if @disposed
    @sprite.dispose if @sprite
    @shadow_data_down[:bitmap].dispose if @shadow_data_down && @shadow_data_down[:bitmap]
    @shadow_data_up[:bitmap].dispose if @shadow_data_up && @shadow_data_up[:bitmap]
    @sprite = nil
    @disposed = true
  end
  #-----------------------------------------------------------------------------
  # Check whether the shadow has been disposed
  #-----------------------------------------------------------------------------
  def disposed?; return @disposed; end
  #-----------------------------------------------------------------------------
  # Calculation of shadow size and position
  #-----------------------------------------------------------------------------
  def update
    return if disposed? || !$scene.is_a?(Scene_Map)
    @sprite = Sprite.new(@viewport) if !@sprite
    if (!@shadow_data_down || !@shadow_data_up) && @rsprite.bitmap && !@rsprite.disposed?
      @shadow_data_down = generate_shadow_data(0) # Row 0: Down
      @shadow_data_up   = generate_shadow_data(3) # Row 3: Up
    end
    return unless @shadow_data_down # Wait until generation is successful

    is_floating = @event.respond_to?(:is_floating) && @event.is_floating
    float_offset = (is_floating && @event.respond_to?(:float_offset)) ? @event.float_offset : 0
    if @event.jumping?
      ground_y = (@event.real_y - $game_map.display_y + 3) / 4 + 32
      jump_offset = (ground_y - @rsprite.y).abs
    elsif is_floating
      ground_y = @rsprite.y + float_offset
      jump_offset = 0
    else
      ground_y = @rsprite.y
      jump_offset = 0
    end
    if @event.direction == 8 || @event.direction == 6
      current_data = @shadow_data_up
    else
      current_data = @shadow_data_down
    end
    current_data = @shadow_data_down if current_data.nil?

    s_off_x = (@event.respond_to?(:shadow_offset_x) ? @event.shadow_offset_x : 0)
    s_off_y = (@event.respond_to?(:shadow_offset_y) ? @event.shadow_offset_y : 0)
    @sprite.bitmap  = current_data[:bitmap]
    @sprite.x       = @rsprite.x + s_off_x
    @sprite.y       = ground_y + s_off_y
    @sprite.ox      = (current_data[:bitmap].width / 2) - current_data[:offset]
    @sprite.oy      = current_data[:bitmap].height
    @sprite.z       = @event.screen_z(current_data[:bitmap].height) - 1
    scale_factor = 1.0

    if @event.jumping?
      scale_factor = 1.0 - (jump_offset * 0.01)
    elsif is_floating
      scale_factor = 1.0 - (float_offset * 0.03)
    end

    scale_factor = 0.4 if scale_factor < 0.4
    scale_factor = 1.2 if scale_factor > 1.2

    @sprite.zoom_x  = @rsprite.zoom_x * scale_factor
    @sprite.zoom_y  = @rsprite.zoom_y * scale_factor
    
    @sprite.opacity = @rsprite.opacity
    @sprite.visible = @rsprite.visible && @event.shows_shadow?
  end
end

#-------------------------------------------------------------------------------
# New Method for setting shadow of any event given the map id and event id
#-------------------------------------------------------------------------------
def pbSetOverworldShadow(name, event_id = nil, map_id = nil)
  return if !$scene.is_a?(Scene_Map)
  return if nil_or_empty?(name)
  if !event_id
    $scene.spritesetGlobal.playersprite.ow_shadow.set_bitmap(name)
  else
    map_id = $game_map.map_id if !map_id
    $scene.spritesets[map_id].character_sprites[(event_id - 1)].ow_shadow.set_bitmap(name)
  end
end

#-------------------------------------------------------------------------------
# Referencing and initializing Shadow Sprite in Sprite_Character
#-------------------------------------------------------------------------------
class Sprite_Character
  attr_accessor :ow_shadow
  #-----------------------------------------------------------------------------
  # Initializing Shadow with Character
  #-----------------------------------------------------------------------------
  alias __ow_shadow__initialize initialize unless private_method_defined?(:__ow_shadow__initialize)
  def initialize(*args)
    __ow_shadow__initialize(*args)
    @ow_shadow = Sprite_OWShadow.new(self, args[1], args[0])
    update
  end
  #-----------------------------------------------------------------------------
  # Disposing Shadow with Character
  #-----------------------------------------------------------------------------
  alias __ow_shadow__dispose dispose unless method_defined?(:__ow_shadow__dispose)
  def dispose(*args)
    __ow_shadow__dispose(*args)
    @ow_shadow.dispose if @ow_shadow
    @ow_shadow = nil
  end
  #-----------------------------------------------------------------------------
  # Updating Shadow with Character
  #-----------------------------------------------------------------------------
  alias __ow_shadow__update update unless method_defined?(:__ow_shadow__update)
  def update(*args)
    __ow_shadow__update(*args)
    return if !@ow_shadow
    @ow_shadow.update
  end
end

#-------------------------------------------------------------------------------
# Adding shadow checking method to Game_Event
#-------------------------------------------------------------------------------
class Game_Character
  attr_reader :jump_count
  attr_reader :jump_distance
  attr_reader :jump_distance_left
  attr_reader :jump_peak
  #-----------------------------------------------------------------------------
  # Initializing Shadow with event
  #-----------------------------------------------------------------------------
  alias __ow_shadow__initialize initialize unless private_method_defined?(:__ow_shadow__initialize)
  def initialize(*args)
    __ow_shadow__initialize(*args)
    @shows_shadow = false
  end
  #-----------------------------------------------------------------------------
  # Updating Shadow with Character
  #-----------------------------------------------------------------------------
  alias __ow_shadow__calculate_bush_depth calculate_bush_depth unless method_defined?(:__ow_shadow__calculate_bush_depth)
  def calculate_bush_depth(*args)
    __ow_shadow__calculate_bush_depth(*args)
    @shows_shadow = shows_shadow?(true)
  end
  #-----------------------------------------------------------------------------
  # Check whether the character should have a shadow
  #-----------------------------------------------------------------------------
  def shows_shadow?(recalc = false)
    return @shows_shadow if !recalc
    return false if nil_or_empty?(self.character_name) || self.transparent
    if OWShadowSettings::CASE_SENSITIVE_BLACKLISTS
      return false if OWShadowSettings::SHADOWLESS_CHARACTER_NAME.any?{ |e| self.character_name[/#{e}/] }
      return false if self.respond_to?(:name) && OWShadowSettings::SHADOWLESS_EVENT_NAME.any? { |e| self.name[/#{e}/]}
    else
      return false if OWShadowSettings::SHADOWLESS_CHARACTER_NAME.any?{ |e| self.character_name[/#{e}/i] }
      return false if self.respond_to?(:name) && OWShadowSettings::SHADOWLESS_EVENT_NAME.any? { |e| self.name[/#{e}/]}
    end
    terrain = $game_map.terrain_tag(self.x, self.y)
    return false if OWShadowSettings::SHADOWLESS_TERRAIN_NAME.any? { |e| terrain == e } if terrain
    return true
  end
  #-----------------------------------------------------------------------------
  # Updating Shadows when transparency is changed
  #-----------------------------------------------------------------------------
  alias __ow_shadow__transparent_set transparent= unless method_defined?(:__ow_shadow__transparent_set)
  def transparent=(*args)
    __ow_shadow__transparent_set(*args)
    @shows_shadow = shows_shadow?(true)
  end
  #-----------------------------------------------------------------------------
end

#-------------------------------------------------------------------------------
# Updating Shadow with Character
#-------------------------------------------------------------------------------
class Game_Event
  alias __ow_shadow__refresh refresh unless method_defined?(:__ow_shadow__refresh)
  def refresh(*args)
    ret = __ow_shadow__refresh(*args)
    @shows_shadow = shows_shadow?(true)
    return ret
  end
end

class Game_Player
  #-----------------------------------------------------------------------------
  # Updating Shadow with Player's Movement
  #-----------------------------------------------------------------------------
  alias __ow_shadow__set_movement_type set_movement_type unless method_defined?(:__ow_shadow__set_movement_type)
  def set_movement_type(*args)
    ret = __ow_shadow__set_movement_type(*args)
    @shows_shadow = shows_shadow?(true)
    return ret
  end
  #-----------------------------------------------------------------------------
end

#-------------------------------------------------------------------------------
# Adding accessors to the Scene_Map class
#-------------------------------------------------------------------------------
class Scene_Map
  attr_accessor :spritesets
end

#-------------------------------------------------------------------------------
# Adding accessors to the Game_Character class
#-------------------------------------------------------------------------------
class Spriteset_Map
  attr_accessor :character_sprites
end

