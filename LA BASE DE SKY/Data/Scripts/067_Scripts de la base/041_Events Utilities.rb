#====================================================================================
# Events Utilities
# Créditos: Zik
#
# Extiende la funcionalidad de los eventos mediante comentarios o nombre del 
# evento a modo de comandos.
#====================================================================================
#
# Comandos soportados como parte del nombre de evento:
#  sizeblock(x,y)                 -> Define un área de colisión en el evento sin
#                                    necesidad de asignar un gráfico.
#
# Comandos soportados como Comentarios en el evento:
#  s:Hitbox/X,Y                  -> Define un area de colisión usando de base el 
#                                   evento e igualmente permite la interacción
#                                   con él.  
#                                   
#  s:Hitbox_radius/Rx,Ry         -> Define un radio de colisión alrededor del evento
#                                   e igualmente permite la interacción con él.
#                                   No es necesario anmbos valores, con uno basta.
#
#  s:Offset/X,Y                  -> Desplaza el gráfico visualmente (en píxeles).
#
#  s:Offset_shadow/X,Y           -> Desplaza el gráfico de la sombra (en píxeles).
#
#  s:Float                       -> Activa una animación de levitación suave.
#
#  s:doppelganger                -> Cambia al gráfico actual del jugador.
#
#  s:pokemon_event/Nombre        -> Cambiará el gráfico al del Pokémon especificado.
#
#  s:pokemon_event_shiny/Nombre  -> Lo mismo, pero su versión Shiny.
#                                   Ambos inlcuyen que al interactuar suene su cry.
#
#  s:Custom/RUTA                 -> Carga un gráfico en específico para el ow usando
#                                   una ruta dentro de Graphics. La imagen será 
#                                   dividida en un 4x4 para que sean los lados del ow.
#                                   Ejemplo: s:Custom/Pictures/introBoy
#
#  s:Custom_full/RUTA            -> Carga un gráfico en específico para el ow usando
#                                   una ruta dentro de Graphics. La imagen será 
#                                   cargada de forma completa.
#                                   Ejemplo: s:Custom_full/Pictures/introBoy
#
#  s:Spritesheet_FRAMES_VEL/RUTA -> Carga un gráfico en específico para el ow usando
#                                   una ruta dentro de Graphics. Esta imagen será 
#                                   tomada como un spritesheet horizontal y divido 
#                                   en la cantidad de segmentos(FRAMES) que ocupes. 
#                                   El parámetro de la velocidad(VEL) puede ser
#                                   omitido (por defecto será 4).
#                                   Ejemplo: s:Spritesheet_8_4/Pictures/molino
#                                            s:Spritesheet_8/Pictures/molino
#====================================================================================

class Game_Event < Game_Character
  attr_reader :hitbox_rx, :hitbox_ry
  attr_reader :hitbox_cx, :hitbox_hy
  attr_reader :block_width, :block_height
  attr_accessor :visual_offset_x, :visual_offset_y
  attr_accessor :is_floating
  attr_accessor :cry_species
  attr_reader :float_offset
  attr_accessor :shadow_offset_x, :shadow_offset_y
  attr_accessor :is_full_image
  attr_accessor :custom_frames, :current_spritesheet_frame, :custom_speed

  #-----------------------------------------------------------------------------
  # PROTECCIÓN DE ALIAS
  #-----------------------------------------------------------------------------
  unless method_defined?(:zik_ext_initialize)
    alias_method :zik_ext_initialize, :initialize
  end

  unless method_defined?(:zik_ext_refresh)
    alias_method :zik_ext_refresh, :refresh
  end

  unless method_defined?(:zik_ext_screen_y)
    alias_method :zik_ext_screen_y, :screen_y
  end

  unless method_defined?(:zik_ext_should_update?)
    alias_method :zik_ext_should_update?, :should_update?
  end

  unless method_defined?(:zik_ext_start)
    alias_method :zik_ext_start, :start
  end

  #-----------------------------------------------------------------------------
  # Implementación
  #-----------------------------------------------------------------------------
  def initialize(map_id, event, map = nil)
    @hitbox_rx = 0
    @hitbox_ry = 0
    @hitbox_cx = 0
    @hitbox_hy = 0
    @block_width = 1
    @block_height = 1
    @is_full_image = false
    @custom_frames = 0
    @current_spritesheet_frame = 0
    @spritesheet_timer = 0
    @visual_offset_x = 0
    @visual_offset_y = 0
    @is_floating = false
    @float_offset = 0
    @shadow_offset_x = 0
    @shadow_offset_y = 0
    @cry_species = nil
    @custom_frames = 0
    @custom_speed = 0
    @current_spritesheet_frame = 0
    @spritesheet_timer = 0
    zik_ext_initialize(map_id, event, map)
  end

  def refresh
    zik_ext_refresh
    
    # --- SIZEBLOCK (Área) ---
    @block_width = 1
    @block_height = 1
    is_blocker = false
    if @event.name[/sizeblock\((\d+),(\d+)\)/i]
      @block_width = $1.to_i
      @block_height = $2.to_i
      is_blocker = true
    elsif @event.name[/sizeblock/i]
      is_blocker = true
    end
    if is_blocker
      @through = false
      @priority_type = 1
      @trigger = 0
      if @character_name == "" && @tile_id == 0
        @character_name = $game_player.character_name 
        @opacity = 0
      end
    end

    # Resetear valores de comentarios
    @hitbox_rx = 0
    @hitbox_ry = 0
    @hitbox_cx = 0
    @hitbox_hy = 0
    @visual_offset_x = 0
    @visual_offset_y = 0
    @is_floating = false
    @float_offset = 0
    @cry_species = nil

    return unless @page && @list

    # Analizar comentarios
    @list.each do |command|
      next unless [108, 408].include?(command.code)
      cmd_text = command.parameters[0]
      next if cmd_text.nil?

      # --- HITBOX RADIUS ---
      if cmd_text.match(/^s:Hitbox_radius\/(\d+)(?:,(\d+))?/i)
        val_x = $1.to_i
        val_y = $2 ? $2.to_i : val_x
        @hitbox_rx = val_x
        @hitbox_ry = val_y

      # --- HITBOX ---
      elsif cmd_text.match(/^s:Hitbox\/(\d+),(\d+)/i)
        @hitbox_cx = $1.to_i
        @hitbox_hy = $2.to_i
      
      # --- OFFSET ---
      elsif cmd_text.match(/^s:Offset\/([-\d]+),([-\d]+)/i)
        @visual_offset_x = $1.to_i
        @visual_offset_y = $2.to_i

      # --- OFFSET SHADOW ---
      elsif cmd_text.match(/^s:Offset_shadow\/([-\d]+),([-\d]+)/i)
        @shadow_offset_x = $1.to_i
        @shadow_offset_y = $2.to_i

      # --- FLOAT ---
      elsif cmd_text.match(/^s:Float/i)
        @is_floating = true

      # --- POKÉMON EVENT ---
      elsif cmd_text.match(/^s:pokemon_event_shiny\/(.+)/i)
        filename = $1.strip
        @character_name = "Followers shiny/#{filename}"
        @cry_species = filename

      elsif cmd_text.match(/^s:pokemon_event\/(.+)/i)
        filename = $1.strip
        @character_name = "Followers/#{filename}"
        @cry_species = filename

      #---- DOPPELGANGER ---
      elsif cmd_text.match(/^s:doppelganger/i)
        @character_name = $game_player.character_name
      
      # --- CUSTOM ---
      elsif cmd_text.match(/^s:Custom\/(.+)/i)
        filename = $1.strip
        @character_name = "../#{filename}"  
      
      # --- CUSTOM FULL ---  
      elsif cmd_text.match(/^s:Custom_full\/(.+)/i)
        filename = $1.strip
        @character_name = "../#{filename}"
        @is_full_image = true
        @direction_fix = true
        @step_anime = false 
        
      # --- SPRITESHEET ---
      elsif cmd_text.match(/^s:Spritesheet_(\d+)(?:_(\d+))?\/(.+)/i)
        @custom_frames = $1.to_i
        @custom_speed = $2 ? $2.to_i : 0 
        filename = $3.strip       
        @character_name = "../#{filename}"
        @step_anime = true
        @direction_fix = true
      end
    end
  end

  #-----------------------------------------------------------------------------
  # Lógica de Interacción
  #-----------------------------------------------------------------------------
  def start
    if @cry_species && ![@trigger == 3, @trigger == 4].include?(true)
      Pokemon.play_cry(@cry_species) rescue nil
    end
    
    zik_ext_start
  end

  #-----------------------------------------------------------------------------
  # Lógica Visual y Física
  #-----------------------------------------------------------------------------
  def should_update?(recalc = false)
    return true if @is_floating
    return zik_ext_should_update?(recalc)
  end

  def screen_x
    return super + @visual_offset_x
  end

  def screen_y
    y = zik_ext_screen_y + @visual_offset_y
    
    if @is_floating
      time_factor = (System.uptime * 4.0) + (@id * 0.5)   
      @float_offset = (Math.sin(time_factor) * 5).round
      y -= @float_offset 
    else
      @float_offset = 0
    end

    return y
  end

  def at_coordinate?(x, y)
    # Prioridad 1: HITBOX RADIUS
    if @hitbox_rx > 0 || @hitbox_ry > 0
      return x.between?(@x - @hitbox_rx, @x + @hitbox_rx) &&
             y.between?(@y - @hitbox_ry, @y + @hitbox_ry)
    end

    # Prioridad 2: HITBOX
    if @hitbox_cx > 0 || @hitbox_hy > 0
      return x.between?(@x - @hitbox_cx, @x + @hitbox_cx) &&
             y.between?(@y - @hitbox_hy, @y)
    end
  
    # Prioridad 3: SIZEBLOCK
    effective_width = (@block_width > 1) ? @block_width : (@width || 1)
    effective_height = (@block_height > 1) ? @block_height : (@height || 1)
    return x.between?(@x, @x + effective_width - 1) &&
           y.between?(@y - effective_height + 1, @y)
  end
end

#===============================================================================
# Parche para Sprite_Character
#===============================================================================
class Sprite_Character
  alias_method :zik_full_update_charset_frame, :update_charset_frame unless method_defined?(:zik_full_update_charset_frame)

  def update_charset_frame
    bmp = (@charbitmapAnimated && @charbitmap) ? @charbitmap.bitmap : @charbitmap
    return unless bmp

    # IMAGEN COMPLETA
    if @character.respond_to?(:is_full_image) && @character.is_full_image
      self.src_rect.set(0, 0, bmp.width, bmp.height)
      self.ox = bmp.width / 2
      self.oy = bmp.height

    # SPRITESHEET
    elsif @character.respond_to?(:custom_frames) && @character.custom_frames.to_i > 0
      cw = bmp.width / @character.custom_frames
      ch = bmp.height

      if @character.custom_speed.to_i > 0
        target_frames = @character.custom_speed
      else
        target_frames = (7 - @character.move_speed) * 3
        target_frames = 4 if target_frames <= 0
      end

      duration_per_frame = target_frames / 60.0
      current_frame = (System.uptime / duration_per_frame).to_i % @character.custom_frames 
      sx = current_frame * cw
      self.src_rect.set(sx, 0, cw, ch)
      self.ox = cw / 2
      self.oy = ch
    else
      zik_full_update_charset_frame
    end
  end
end