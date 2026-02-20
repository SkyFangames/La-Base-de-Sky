#===============================================================================
# Location signpost
#===============================================================================
class LocationWindow
  APPEAR_TIME = 0.6   # In seconds; is also the disappear time
  LINGER_TIME = 1.6   # In seconds; time during which self is fully visible

  def initialize(name, graphic_name = nil, animate = true, viewport = nil)
    initialize_viewport(viewport)
    @graphic_offset = [0, 0]
    @window_offset = [0, 0]
    initialize_graphic(graphic_name)
    initialize_text_window(name)
    apply_style(graphic_name)
    setup_initial_positions
    @current_map = $game_map.map_id
    @timer_start = System.uptime
    @delayed = !$game_temp.fly_destination.nil?
    @animate = animate
  end

  def initialize_viewport(viewport)
    if viewport
      @viewport = viewport
      return
    end
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
  end

  def initialize_graphic(graphic_name)
    return if graphic_name.nil? || !pbResolveBitmap("Graphics/UI/Location/#{graphic_name}")
    @graphic = Sprite.new(@viewport)
    @graphic.bitmap = RPG::Cache.ui("Location/#{graphic_name}")
    @graphic.x = 0
    @graphic.y = 0
  end

  def initialize_text_window(name)
    @window = Window_AdvancedTextPokemon.new(name)
    @window.resizeToFit(name, Graphics.width)
    @window.x        = 0
    @window.y        = 0
    @window.z        = 1
    @window.viewport = @viewport
  end

  def apply_style(graphic_name)
    # Set up values to be used elsewhere
    @graphic_offset = [0, 0]
    @window_offset = [0, 0]
    @y_distance = @window.height
    return if graphic_name.nil?
    # Determine the style and base/shadow colors
    style = :none
    base_color = nil
    shadow_color = nil
    zoom_x = 1
    zoom_y = 1
    center_text = false
    Settings::LOCATION_SIGN_GRAPHIC_STYLES.each_pair do |val, filenames|
      filenames.each do |filename|
        if filename.is_a?(Hash)
          next if !filename.key?(:graphic) || filename[:graphic] != graphic_name
          base_color = filename[:text_color] if filename.key?(:text_color)
          shadow_color = filename[:shadow_color] if filename.key?(:shadow_color)
          zoom_x = filename[:zoomx] || 1 
          zoom_y = filename[:zoomy] || 1
          @window_offset = filename[:text_offset] || [0, 0]
          @graphic_offset = filename[:graphic_offset] || [0, 0]
          center_text = filename[:center_text] || false
        else
          next if filename != graphic_name
        end
        style = val
        break
      end
      break if style != :none
    end
    return if style == :none
    # Apply the style
    @y_distance = @graphic&.height || @window.height
    @window.back_opacity = 0
    @graphic.zoom_x = zoom_x if zoom_x
    @graphic.zoom_y = zoom_y if zoom_y
    case style
    when :dp
      @window.baseColor = base_color if base_color
      @window.shadowColor = shadow_color if shadow_color
      @graphic&.dispose
      @graphic = Window_AdvancedTextPokemon.new("")
      @graphic.setSkin("Graphics/UI/Location/#{graphic_name}")
      @graphic.width    = @window.width + (@window_offset[0] * 2) - 4
      @graphic.height   = 48
      @graphic.x        = 0
      @graphic.y        = (@animate) ? -@graphic.height : @graphic_offset[1]
      @graphic.z        = 0
      @graphic.zoom_x = zoom_x if zoom_x
      @graphic.zoom_y = zoom_y if zoom_y
      @graphic.viewport = @viewport
      @y_distance = @graphic.height
    when :hgss
      @window.baseColor = base_color if base_color
      @window.shadowColor = shadow_color if shadow_color
      @window.width = @graphic.width
    when :platinum
      @window.baseColor = base_color || Color.black
      @window.shadowColor = shadow_color || Color.new(144, 144, 160)
      @window_offset = [10, 16] if @window_offset == [0, 0]
    when :oras
      @window.baseColor = base_color || Color.white
      @window.shadowColor = shadow_color || Color.new(0, 0, 0, 128)
    when :xy
      @window.baseColor = base_color || Color.white
      @window.shadowColor = shadow_color || Color.new(0, 0, 0, 128)
    end
    @window.text = @window.text   # Because the text colors were changed
    @window.text = "<ac>" + @window.text if center_text
  end

  def setup_initial_positions
    # Determine animation direction based on graphic position
    @animate_from_bottom = @graphic && (@graphic_offset[1] > Graphics.height / 2)
    
    if @animate
      if @animate_from_bottom
        initial_y_offset = @y_distance
      else
        initial_y_offset = -@y_distance
      end
    else
      initial_y_offset = 0
    end
    
    # Position graphic
    if @graphic
      @graphic.x = @graphic_offset[0]
      @graphic.y = @graphic_offset[1] + initial_y_offset
    end
    
    # Position window relative to graphic (text_offset is relative to graphic_offset)
    @window.x = @graphic_offset[0] + @window_offset[0]
    @window.y = @graphic_offset[1] + @window_offset[1] + initial_y_offset
  end

  def disposed?
    return @window.disposed?
  end

  def dispose
    @graphic&.dispose
    @window.dispose
    @viewport.dispose
  end

  def update
    return if disposed? || $game_temp.fly_destination
    if @delayed
      @timer_start = System.uptime
      @delayed = false
    end
    @graphic&.update
    @window.update
    return if !@animate
    if $game_temp.message_window_showing || @current_map != $game_map.map_id
      dispose
      return
    end
    
    # Calculate animation offset
    if System.uptime - @timer_start >= APPEAR_TIME + LINGER_TIME
      # Disappearing
      if @animate_from_bottom
        y_offset = lerp(0, @y_distance, APPEAR_TIME, @timer_start + APPEAR_TIME + LINGER_TIME, System.uptime)
        if y_offset >= @y_distance
          dispose
          return
        end
      else
        y_offset = lerp(0, -@y_distance, APPEAR_TIME, @timer_start + APPEAR_TIME + LINGER_TIME, System.uptime)
        if y_offset <= -@y_distance
          dispose
          return
        end
      end
    else
      # Appearing
      if @animate_from_bottom
        y_offset = lerp(@y_distance, 0, APPEAR_TIME, @timer_start, System.uptime)
      else
        y_offset = lerp(-@y_distance, 0, APPEAR_TIME, @timer_start, System.uptime)
      end
    end
    
    # Apply positions (text is positioned relative to graphic)
    if @graphic
      @graphic.x = @graphic_offset[0]
      @graphic.y = @graphic_offset[1] + y_offset
    end
    @window.x = @graphic_offset[0] + @window_offset[0]
    @window.y = @graphic_offset[1] + @window_offset[1] + y_offset
  end
end

#===============================================================================
# Visibility circle in dark maps
#===============================================================================
class DarknessSprite < Sprite
  attr_reader :radius

  PIXELLATE_CIRCLE = true

  def initialize(viewport = nil)
    super(viewport)
    bitmap_size = [Graphics.width, Graphics.height]
    bitmap_size = [Graphics.width / 2, Graphics.height / 2] if PIXELLATE_CIRCLE
    @darkness = Bitmap.new(*bitmap_size)
    @radius = radiusMin
    self.bitmap = @darkness
    self.z      = 99998
    self.zoom_x = 2.0 if PIXELLATE_CIRCLE
    self.zoom_y = 2.0 if PIXELLATE_CIRCLE
    refresh
  end

  def dispose
    @darkness.dispose
    super
  end

  # Before using Flash.
  def radiusMin
    ret = 64
    return (PIXELLATE_CIRCLE) ? ret / 2 : ret
  end

  # After using Flash.
  def radiusMax
    ret = 176
    return (PIXELLATE_CIRCLE) ? ret / 2 : ret
  end

  def radius=(value)
    @radius = value.round
    refresh
  end

  def refresh
    @darkness.fill_rect(0, 0, @darkness.width, @darkness.height, Color.black)
    cx = @darkness.width / 2
    cy = @darkness.height / 2
    cradius = @radius - (@radius % 2)
    numfades = 5
    (1..numfades).each do |i|
      (cx - cradius..cx + cradius).each do |j|
        diff2 = (cradius * cradius) - ((j - cx) * (j - cx))
        diff = Math.sqrt(diff2).round
        @darkness.fill_rect(j, cy - diff, 1, diff * 2, Color.new(0, 0, 0, 255.0 * (numfades - i) / numfades))
      end
      cradius = (cradius * 0.9).floor
    end
  end
end

#===============================================================================
# Light effects
#===============================================================================
class LightEffect
  def initialize(event, viewport = nil, map = nil, filename = nil)
    @light = IconSprite.new(0, 0, viewport)
    if !nil_or_empty?(filename) && pbResolveBitmap("Graphics/Pictures/" + filename)
      @light.setBitmap("Graphics/Pictures/" + filename)
    else
      @light.setBitmap("Graphics/Pictures/LE")
    end
    @light.z = 1000
    @event = event
    @map = (map) ? map : $game_map
    @disposed = false
  end

  def disposed?
    return @disposed
  end

  def dispose
    @light.dispose
    @map = nil
    @event = nil
    @disposed = true
  end

  def update
    @light.update
  end
end

#===============================================================================
#
#===============================================================================
class LightEffect_Lamp < LightEffect
  def initialize(event, viewport = nil, map = nil)
    lamp = AnimatedBitmap.new("Graphics/Pictures/LE")
    @light = Sprite.new(viewport)
    @light.bitmap = Bitmap.new(128, 64)
    src_rect = Rect.new(0, 0, 64, 64)
    @light.bitmap.blt(0, 0, lamp.bitmap, src_rect)
    @light.bitmap.blt(20, 0, lamp.bitmap, src_rect)
    @light.visible = true
    @light.z       = 1000
    lamp.dispose
    @map = (map) ? map : $game_map
    @event = event
  end
end

#===============================================================================
#
#===============================================================================
class LightEffect_Basic < LightEffect
  def initialize(event, viewport = nil, map = nil, filename = nil)
    super
    @light.ox = @light.bitmap.width / 2
    @light.oy = @light.bitmap.height / 2
    @light.opacity = 100
  end

  def update
    return if !@light || !@event
    super
    if (Object.const_defined?(:ScreenPosHelper) rescue false)
      @light.x      = ScreenPosHelper.pbScreenX(@event)
      @light.y      = ScreenPosHelper.pbScreenY(@event) - (@event.height * Game_Map::TILE_HEIGHT / 2)
      @light.zoom_x = ScreenPosHelper.pbScreenZoomX(@event)
      @light.zoom_y = @light.zoom_x
    else
      @light.x = @event.screen_x
      @light.y = @event.screen_y - (Game_Map::TILE_HEIGHT / 2)
    end
    @light.tone = $game_screen.tone
  end
end

#===============================================================================
#
#===============================================================================
class LightEffect_DayNight < LightEffect
  def initialize(event, viewport = nil, map = nil, filename = nil)
    super
    @light.ox = @light.bitmap.width / 2
    @light.oy = @light.bitmap.height / 2
  end

  def update
    return if !@light || !@event
    super
    shade = PBDayNight.getShade
    if shade >= 144   # If light enough, call it fully day
      shade = 255
    elsif shade <= 64   # If dark enough, call it fully night
      shade = 0
    else
      shade = 255 - (255 * (144 - shade) / (144 - 64))
    end
    @light.opacity = 255 - shade
    if @light.opacity > 0
      if (Object.const_defined?(:ScreenPosHelper) rescue false)
        @light.x      = ScreenPosHelper.pbScreenX(@event)
        @light.y      = ScreenPosHelper.pbScreenY(@event) - (@event.height * Game_Map::TILE_HEIGHT / 2)
        @light.zoom_x = ScreenPosHelper.pbScreenZoomX(@event)
        @light.zoom_y = ScreenPosHelper.pbScreenZoomY(@event)
      else
        @light.x = @event.screen_x
        @light.y = @event.screen_y - (Game_Map::TILE_HEIGHT / 2)
      end
      @light.tone.set($game_screen.tone.red,
                      $game_screen.tone.green,
                      $game_screen.tone.blue,
                      $game_screen.tone.gray)
    end
  end
end

#===============================================================================
#
#===============================================================================
EventHandlers.add(:on_new_spriteset_map, :add_light_effects,
  proc { |spriteset, viewport|
    map = spriteset.map   # Map associated with the spriteset (not necessarily the current map)
    map.events.each_key do |i|
      if map.events[i].name[/^outdoorlight\((\w+)\)$/i]
        filename = $~[1].to_s
        spriteset.addUserSprite(LightEffect_DayNight.new(map.events[i], viewport, map, filename))
      elsif map.events[i].name[/^outdoorlight$/i]
        spriteset.addUserSprite(LightEffect_DayNight.new(map.events[i], viewport, map))
      elsif map.events[i].name[/^light\((\w+)\)$/i]
        filename = $~[1].to_s
        spriteset.addUserSprite(LightEffect_Basic.new(map.events[i], viewport, map, filename))
      elsif map.events[i].name[/^light$/i]
        spriteset.addUserSprite(LightEffect_Basic.new(map.events[i], viewport, map))
      end
    end
  }
)
