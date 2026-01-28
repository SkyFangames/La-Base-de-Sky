#====================================================================================
# Events Utilities
# Créditos: Zik
#
# Extiende la funcionalidad de los eventos mediante comentarios o nombre del 
# evento a modo de comandos.
#====================================================================================
#
# Comandos soportados como parte del nombre de evento:
#   sizeblock(x,y)                -> Define un área de colisión en el evento sin
#                                    necesidad de asignar un gráfico.
#
# Comandos soportados como Comentarios:
#   s:Hitbox/Rx,Ry               -> Define un radio de colisión alrededor del evento
#                                   e igualmente permite la interacción con él.
#   s:Offset/X,Y                 -> Desplaza el gráfico visualmente (en píxeles).
#   s:Offset_shadow/X,Y          -> Desplaza el gráfico de la sombra (en píxeles).
#   s:Float                      -> Activa una animación de levitación suave.
#   s:doppelganger               -> Cambia al gráfico actual del jugador.
#   s:pokemon_event/Nombre       -> Cambiará el gráfico al del Pokémon especificado.
#   s:pokemon_event_shiny/Nombre -> Lo mismo, pero su versión Shiny.
#                                   Ambos inlcuyen que al interactuar suene su cry.
#====================================================================================

class Game_Event < Game_Character
  attr_reader :hitbox_rx, :hitbox_ry
  attr_reader :block_width, :block_height
  attr_accessor :visual_offset_x, :visual_offset_y
  attr_accessor :is_floating
  attr_accessor :cry_species
  attr_reader :float_offset
  attr_accessor :shadow_offset_x, :shadow_offset_y

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
    @block_width = 1
    @block_height = 1
    @visual_offset_x = 0
    @visual_offset_y = 0
    @is_floating = false
    @float_offset = 0
    @shadow_offset_x = 0
    @shadow_offset_y = 0
    @cry_species = nil
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

      # --- HITBOX (Radio) ---
      if cmd_text.match(/^s:Hitbox\/(\d+),(\d+)/i)
        @hitbox_rx = $1.to_i
        @hitbox_ry = $2.to_i
      
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
      timer = Graphics.frame_count + (@id * 7)
      @float_offset = (Math.sin(timer / 15.0) * 5).round
      y -= @float_offset 
    else
      @float_offset = 0
    end
    
    return y
  end

  def at_coordinate?(x, y)
    # Prioridad 1: HITBOX
    if @hitbox_rx > 0 || @hitbox_ry > 0
      return x.between?(@x - @hitbox_rx, @x + @hitbox_rx) &&
             y.between?(@y - @hitbox_ry, @y + @hitbox_ry)
    end
  
    # Prioridad 2: SIZEBLOCK
    bw = @block_width || 1
    bh = @block_height || 1
    return x.between?(@x, @x + bw - 1) &&
           y.between?(@y - bh + 1, @y)
  end
end