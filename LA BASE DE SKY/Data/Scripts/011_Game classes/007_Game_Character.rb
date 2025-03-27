class Game_Character
  attr_reader   :id
  attr_reader   :original_x
  attr_reader   :original_y
  attr_reader   :x
  attr_reader   :y
  attr_reader   :real_x
  attr_reader   :real_y
  attr_writer   :x_offset   # In pixels, positive shifts sprite to the right
  attr_writer   :y_offset   # In pixels, positive shifts sprite down
  attr_accessor :width
  attr_accessor :height
  attr_accessor :sprite_size
  attr_reader   :tile_id
  attr_accessor :character_name
  attr_accessor :character_hue
  attr_accessor :opacity
  attr_reader   :blend_type
  attr_accessor :direction
  attr_accessor :pattern
  attr_accessor :pattern_surf
  attr_accessor :lock_pattern
  attr_reader   :move_route_forcing
  attr_accessor :through
  attr_accessor :animation_id
  attr_accessor :transparent
  attr_reader   :move_speed
  attr_reader   :jump_speed
  attr_accessor :walk_anime
  attr_writer   :bob_height

  def initialize(map = nil)
    @map                       = map
    @id                        = 0
    @original_x                = 0
    @original_y                = 0
    @x                         = 0
    @y                         = 0
    @real_x                    = 0
    @real_y                    = 0
    @x_offset                  = 0
    @y_offset                  = 0
    @width                     = 1
    @height                    = 1
    @sprite_size               = [Game_Map::TILE_WIDTH, Game_Map::TILE_HEIGHT]
    @tile_id                   = 0
    @character_name            = ""
    @character_hue             = 0
    @opacity                   = 255
    @blend_type                = 0
    @direction                 = 2
    @pattern                   = 0
    @pattern_surf              = 0
    @lock_pattern              = false
    @move_route_forcing        = false
    @through                   = false
    @animation_id              = 0
    @transparent               = false
    @original_direction        = 2
    @original_pattern          = 0
    @move_type                 = 0
    self.move_speed            = 3
    self.move_frequency        = 6
    self.jump_speed            = 3
    @move_route                = nil
    @move_route_index          = 0
    @original_move_route       = nil
    @original_move_route_index = 0
    @walk_anime                = true    # Whether character should animate while moving
    @step_anime                = false   # Whether character should animate while still
    @direction_fix             = false
    @always_on_top             = false
    @anime_count               = 0   # Time since pattern was last changed
    @stop_count                = 0   # Time since character last finished moving
    @bumping                   = false   # Used by the player only when walking into something
    @jump_peak                 = 0   # Max height while jumping
    @jump_distance             = 0   # Total distance of jump
    @jump_fraction             = 0   # How far through a jump we currently are (0-1)
    @jumping_on_spot           = false
    @bob_height                = 0
    @wait_count                = 0
    @wait_start                = nil
    @moved_this_frame          = false
    @moveto_happened           = false
    @locked                    = false
    @prelock_direction         = 0
  end

  def x_offset; return @x_offset || 0; end
  def y_offset; return @y_offset || 0; end

  def at_coordinate?(check_x, check_y)
    return check_x >= @x && check_x < @x + @width &&
           check_y > @y - @height && check_y <= @y
  end

  def in_line_with_coordinate?(check_x, check_y)
    return (check_x >= @x && check_x < @x + @width) ||
           (check_y > @y - @height && check_y <= @y)
  end

  def each_occupied_tile
    (@x...(@x + @width)).each do |i|
      ((@y - @height + 1)..@y).each do |j|
        yield i, j
      end
    end
  end

  def move_speed=(val)
    @move_speed = val
    # Time taken to traverse one tile (in seconds) for each speed:
    #   1 => 1.0
    #   2 => 0.5
    #   3 => 0.25    # Walking speed
    #   4 => 0.125   # Running speed (2x walking speed)
    #   5 => 0.1     # Cycling speed (1.25x running speed)
    #   6 => 0.05
    case val
    when 6 then @move_time = 0.05
    when 5 then @move_time = 0.1
    else        @move_time = 2.0 / (2**val)
    end
  end

  # Takes the same values as move_speed above.
  def jump_speed=(val)
    @jump_speed = val
    case val
    when 6 then @jump_time = 0.05
    when 5 then @jump_time = 0.1
    else        @jump_time = 2.0 / (2**val)
    end
  end

  # Returns time in seconds for one full cycle (4 frames) of an animating
  # charset to show. Two frames are shown per movement across one tile.
  def pattern_update_speed
    return @jump_time * 2 if jumping?
    ret = @move_time * 2
    ret *= 2 if @move_speed >= 5   # Cycling speed or faster; slower animation
    return ret
  end

  def move_frequency=(val)
    return if val == @move_frequency
    @move_frequency = val
    # Time in seconds to wait between each action in a move route (not forced).
    # Specifically, this is the time to wait after the character stops moving
    # because of the previous action.
    #   1 => 4.75 seconds
    #   2 => 3.6 seconds
    #   3 => 2.55 seconds
    #   4 => 1.6 seconds
    #   5 => 0.75 seconds
    #   6 => 0 seconds, i.e. continuous movement
    @command_delay = (40 - (val * 2)) * (6 - val) / 40.0
  end

  def bob_height
    @bob_height = 0 if !@bob_height
    return @bob_height
  end

  def lock
    return if @locked
    @prelock_direction = 0   # Was @direction but disabled
    turn_toward_player
    @locked = true
  end

  def minilock
    @prelock_direction = 0   # Was @direction but disabled
    @locked = true
  end

  def lock?
    return @locked
  end

  def unlock
    return unless @locked
    @locked = false
    @direction = @prelock_direction if !@direction_fix && @prelock_direction != 0
  end

  #=============================================================================
  # Information from map data
  #=============================================================================
  def map
    return (@map) ? @map : $game_map
  end

  def terrain_tag
    return self.map.terrain_tag(@x, @y)
  end

  def bush_depth
    return @bush_depth || 0
  end

  def calculate_bush_depth
    if @tile_id > 0 || @always_on_top || jumping?
      @bush_depth = 0
      return
    end
    this_map = (self.map.valid?(@x, @y)) ? [self.map, @x, @y] : $map_factory&.getNewMap(@x, @y, self.map.map_id)
    if this_map && this_map[0].deepBush?(this_map[1], this_map[2])
      xbehind = @x + (@direction == 4 ? 1 : @direction == 6 ? -1 : 0)
      ybehind = @y + (@direction == 8 ? 1 : @direction == 2 ? -1 : 0)
      if moving?
        behind_map = (self.map.valid?(xbehind, ybehind)) ? [self.map, xbehind, ybehind] : $map_factory&.getNewMap(xbehind, ybehind, self.map.map_id)
        @bush_depth = Game_Map::TILE_HEIGHT if behind_map[0].deepBush?(behind_map[1], behind_map[2])
      else
        @bush_depth = Game_Map::TILE_HEIGHT
      end
    elsif this_map && this_map[0].bush?(this_map[1], this_map[2]) && !moving?
      @bush_depth = 12
    else
      @bush_depth = 0
    end
  end

  def fullPattern
    case self.direction
    when 2 then return self.pattern
    when 4 then return self.pattern + 4
    when 6 then return self.pattern + 8
    when 8 then return self.pattern + 12
    end
    return 0
  end

  #=============================================================================
  # Passability
  #=============================================================================
  def passable?(x, y, d, strict = false)
    new_x = x + (d == 6 ? 1 : d == 4 ? -1 : 0)
    new_y = y + (d == 2 ? 1 : d == 8 ? -1 : 0)
    return false unless self.map.valid?(new_x, new_y)
    return true if @through
    if strict
      return false unless self.map.passableStrict?(x, y, d, self)
      return false unless self.map.passableStrict?(new_x, new_y, 10 - d, self)
    else
      return false unless self.map.passable?(x, y, d, self)
      return false unless self.map.passable?(new_x, new_y, 10 - d, self)
    end
    self.map.events.each_value do |event|
      next if self == event || !event.at_coordinate?(new_x, new_y) || event.through
      return false if self != $game_player || event.character_name != ""
    end
    if $game_player.x == new_x && $game_player.y == new_y &&
       !$game_player.through && @character_name != ""
      return false
    end
    return true
  end

  def can_move_from_coordinate?(start_x, start_y, dir, strict = false)
    case dir
    when 2, 8   # Down, up
      y_diff = (dir == 8) ? @height - 1 : 0
      (start_x...(start_x + @width)).each do |i|
        return false if !passable?(i, start_y - y_diff, dir, strict)
      end
      return true
    when 4, 6   # Left, right
      x_diff = (dir == 6) ? @width - 1 : 0
      ((start_y - @height + 1)..start_y).each do |i|
        return false if !passable?(start_x + x_diff, i, dir, strict)
      end
      return true
    when 1, 3   # Down diagonals
      # Treated as moving down first and then horizontally, because that
      # describes which tiles the character's feet touch
      (start_x...(start_x + @width)).each do |i|
        return false if !passable?(i, start_y, 2, strict)
      end
      x_diff = (dir == 3) ? @width - 1 : 0
      ((start_y - @height + 1)..start_y).each do |i|
        return false if !passable?(start_x + x_diff, i + 1, dir + 3, strict)
      end
      return true
    when 7, 9   # Up diagonals
      # Treated as moving horizontally first and then up, because that describes
      # which tiles the character's feet touch
      x_diff = (dir == 9) ? @width - 1 : 0
      ((start_y - @height + 1)..start_y).each do |i|
        return false if !passable?(start_x + x_diff, i, dir - 3, strict)
      end
      x_tile_offset = (dir == 9) ? 1 : -1
      (start_x...(start_x + @width)).each do |i|
        return false if !passable?(i + x_tile_offset, start_y - @height + 1, 8, strict)
      end
      return true
    end
    return false
  end

  def can_move_in_direction?(dir, strict = false)
    return can_move_from_coordinate?(@x, @y, dir, strict)
  end

  #=============================================================================
  # Screen position of the character
  #=============================================================================
  def screen_x
    ret = ((@real_x.to_f - self.map.display_x) / Game_Map::X_SUBPIXELS).round
    ret += @width * Game_Map::TILE_WIDTH / 2
    ret += self.x_offset
    return ret
  end

  def screen_y_ground
    ret = ((@real_y.to_f - self.map.display_y) / Game_Map::Y_SUBPIXELS).round
    ret += Game_Map::TILE_HEIGHT
    return ret
  end

  def screen_y
    ret = screen_y_ground
    if jumping?
      jump_progress = (@jump_fraction - 0.5).abs   # 0.5 to 0 to 0.5
      ret += @jump_peak * ((4 * (jump_progress**2)) - 1)
    end
    ret += self.y_offset
    return ret
  end

  def screen_z(height = 0)
    return 999 if @always_on_top
    z = screen_y_ground
    if @tile_id > 0
      begin
        return z + (self.map.priorities[@tile_id] * 32)
      rescue
      raise "El gráfico del evento es un tile fuera de rango (evento #{@id}, mapa #{self.map.map_id})"
      end
    end
    # Add z if height exceeds 32
    return z + ((height > Game_Map::TILE_HEIGHT) ? Game_Map::TILE_HEIGHT - 1 : 0)
  end

  #=============================================================================
  # Movement
  #=============================================================================
  def moving?
    return !@move_timer.nil?
  end

  def jumping?
    return !@jump_timer.nil?
  end

  def straighten
    @pattern = 0 if @walk_anime || @step_anime
    @anime_count = 0
    @prelock_direction = 0
  end

  def force_move_route(move_route)
    if @original_move_route.nil?
      @original_move_route       = @move_route
      @original_move_route_index = @move_route_index
    end
    @move_route         = move_route
    @move_route_index   = 0
    @move_route_forcing = true
    @prelock_direction  = 0
    @wait_count         = 0
    @wait_start         = nil
    move_type_custom
  end

  def moveto(x, y)
    @x = x % self.map.width
    @y = y % self.map.height
    @real_x = @x * Game_Map::REAL_RES_X
    @real_y = @y * Game_Map::REAL_RES_Y
    @prelock_direction = 0
    @moveto_happened = true
    calculate_bush_depth
    triggerLeaveTile
  end

  def triggerLeaveTile
    if @oldX && @oldY && @oldMap &&
       (@oldX != self.x || @oldY != self.y || @oldMap != self.map.map_id)
      EventHandlers.trigger(:on_leave_tile, self, @oldMap, @oldX, @oldY)
    end
    @oldX = self.x
    @oldY = self.y
    @oldMap = self.map.map_id
  end

  def increase_steps
    @stop_count = 0
    triggerLeaveTile
  end

  #=============================================================================
  # Movement commands
  #=============================================================================
  def move_type_random
    case rand(6)
    when 0..3 then move_random
    when 4    then move_forward
    when 5    then @stop_count = 0
    end
  end

  def move_type_toward_player
    sx = @x + (@width / 2.0) - ($game_player.x + ($game_player.width / 2.0))
    sy = @y - (@height / 2.0) - ($game_player.y - ($game_player.height / 2.0))
    if sx.abs + sy.abs >= 20
      move_random
      return
    end
    case rand(6)
    when 0..3 then move_toward_player
    when 4    then move_random
    when 5    then move_forward
    end
  end

  def move_type_custom
    return if jumping? || moving?
    return if @move_route.list.size <= 1   # Empty move route
    (@move_route.list.size - 1).times do
      command = @move_route.list[@move_route_index]
      if command.code == 0
        if @move_route.repeat
          @move_route_index = 0
          command = @move_route.list[@move_route_index]
        else
          if @move_route_forcing
            @move_route_forcing = false
            @move_route       = @original_move_route
            @move_route_index = @original_move_route_index
            @original_move_route = nil
          end
          @stop_count = 0
          return
        end
      end
      # The below move route commands wait for a frame (i.e. return) after
      # executing them
      if command.code <= 14
        case command.code
        when 1  then move_down
        when 2  then move_left
        when 3  then move_right
        when 4  then move_up
        when 5  then move_lower_left
        when 6  then move_lower_right
        when 7  then move_upper_left
        when 8  then move_upper_right
        when 9  then move_random
        when 10 then move_toward_player
        when 11 then move_away_from_player
        when 12 then move_forward
        when 13 then move_backward
        when 14 then jump(command.parameters[0], command.parameters[1])
        end
        @move_route_index += 1 if @move_route.skippable || moving? || jumping?
        return
      end
      # The below move route commands wait for a frame (i.e. return) after
      # executing them
      if command.code >= 15 && command.code <= 26
        case command.code
        when 15   # Wait
          @wait_count = command.parameters[0] / 20.0
          @wait_start = System.uptime
        when 16 then turn_down
        when 17 then turn_left
        when 18 then turn_right
        when 19 then turn_up
        when 20 then turn_right_90
        when 21 then turn_left_90
        when 22 then turn_180
        when 23 then turn_right_or_left_90
        when 24 then turn_random
        when 25 then turn_toward_player
        when 26 then turn_away_from_player
        end
        @move_route_index += 1
        return
      end
      # The below move route commands don't wait for a frame (i.e. return) after
      # executing them
      if command.code >= 27
        case command.code
        when 27
          $game_switches[command.parameters[0]] = true
          self.map.need_refresh = true
        when 28
          $game_switches[command.parameters[0]] = false
          self.map.need_refresh = true
        when 29 then self.move_speed = command.parameters[0]
        when 30 then self.move_frequency = command.parameters[0]
        when 31 then @walk_anime = true
        when 32 then @walk_anime = false
        when 33 then @step_anime = true
        when 34 then @step_anime = false
        when 35 then @direction_fix = true
        when 36 then @direction_fix = false
        when 37 then @through = true
        when 38 then @through = false
        when 39
          old_always_on_top = @always_on_top
          @always_on_top = true
          calculate_bush_depth if @always_on_top != old_always_on_top
        when 40
          old_always_on_top = @always_on_top
          @always_on_top = false
          calculate_bush_depth if @always_on_top != old_always_on_top
        when 41
          old_tile_id = @tile_id
          @tile_id = 0
          @character_name = command.parameters[0]
          @character_hue = command.parameters[1]
          if @original_direction != command.parameters[2]
            @direction = command.parameters[2]
            @original_direction = @direction
            @prelock_direction = 0
          end
          if @original_pattern != command.parameters[3]
            @pattern = command.parameters[3]
            @original_pattern = @pattern
          end
          calculate_bush_depth if @tile_id != old_tile_id
        when 42 then @opacity = command.parameters[0]
        when 43 then @blend_type = command.parameters[0]
        when 44 then pbSEPlay(command.parameters[0])
        when 45
          eval(command.parameters[0])
          if command.parameters[0][/^move_random_range/] ||
             command.parameters[0][/^move_random_UD/] ||
             command.parameters[0][/^move_random_LR/]
            @move_route_index += 1
            return
          end
        end
        @move_route_index += 1
      end
    end
  end

  def move_generic(dir, turn_enabled = true)
    turn_generic(dir) if turn_enabled
    if can_move_in_direction?(dir)
      turn_generic(dir)
      @move_initial_x = @x
      @move_initial_y = @y
      @x += (dir == 4) ? -1 : (dir == 6) ? 1 : 0
      @y += (dir == 8) ? -1 : (dir == 2) ? 1 : 0
      @move_timer = 0.0
      increase_steps
    else
      check_event_trigger_touch(dir)
    end
  end

  def move_down(turn_enabled = true)
    move_generic(2, turn_enabled)
  end

  def move_left(turn_enabled = true)
    move_generic(4, turn_enabled)
  end

  def move_right(turn_enabled = true)
    move_generic(6, turn_enabled)
  end

  def move_up(turn_enabled = true)
    move_generic(8, turn_enabled)
  end

  def move_upper_left
    unless @direction_fix
      @direction = (@direction == 6 ? 4 : @direction == 2 ? 8 : @direction)
    end
    if can_move_in_direction?(7)
      @move_initial_x = @x
      @move_initial_y = @y
      @x -= 1
      @y -= 1
      @move_timer = 0.0
      increase_steps
    end
  end

  def move_upper_right
    unless @direction_fix
      @direction = (@direction == 4 ? 6 : @direction == 2 ? 8 : @direction)
    end
    if can_move_in_direction?(9)
      @move_initial_x = @x
      @move_initial_y = @y
      @x += 1
      @y -= 1
      @move_timer = 0.0
      increase_steps
    end
  end

  def move_lower_left
    unless @direction_fix
      @direction = (@direction == 6 ? 4 : @direction == 8 ? 2 : @direction)
    end
    if can_move_in_direction?(1)
      @move_initial_x = @x
      @move_initial_y = @y
      @x -= 1
      @y += 1
      @move_timer = 0.0
      increase_steps
    end
  end

  def move_lower_right
    unless @direction_fix
      @direction = (@direction == 4 ? 6 : @direction == 8 ? 2 : @direction)
    end
    if can_move_in_direction?(3)
      @move_initial_x = @x
      @move_initial_y = @y
      @x += 1
      @y += 1
      @move_timer = 0.0
      increase_steps
    end
  end

  # Anticlockwise.
  def moveLeft90
    case self.direction
    when 2 then move_right   # down
    when 4 then move_down    # left
    when 6 then move_up      # right
    when 8 then move_left    # up
    end
  end

  # Clockwise.
  def moveRight90
    case self.direction
    when 2 then move_left    # down
    when 4 then move_up      # left
    when 6 then move_down    # right
    when 8 then move_right   # up
    end
  end

  def move_random
    case rand(4)
    when 0 then move_down(false)
    when 1 then move_left(false)
    when 2 then move_right(false)
    when 3 then move_up(false)
    end
  end

  def move_random_range(xrange = -1, yrange = -1)
    dirs = []   # 0=down, 1=left, 2=right, 3=up
    if xrange < 0
      dirs.push(1)
      dirs.push(2)
    elsif xrange > 0
      dirs.push(1) if @x > @original_x - xrange
      dirs.push(2) if @x < @original_x + xrange
    end
    if yrange < 0
      dirs.push(0)
      dirs.push(3)
    elsif yrange > 0
      dirs.push(0) if @y < @original_y + yrange
      dirs.push(3) if @y > @original_y - yrange
    end
    return if dirs.length == 0
    case dirs[rand(dirs.length)]
    when 0 then move_down(false)
    when 1 then move_left(false)
    when 2 then move_right(false)
    when 3 then move_up(false)
    end
  end
  
  # Función que mueve un evento de manera aleatoria dentro de un rango definido, con acciones adicionales
  # Valores de "corner":
  #   ABDE: Abajo a la derecha
  #   ARDE: Arriba a la derecha
  #   ABIZ: Abajo a la izquierda
  #   ARIZ: Arriba a la izquierda
  def move_random_range_with_corner(xrange=-1, yrange=-1, corner="ABDE")
    dirs = []   # 0=abajo, 1=izquierda, 2=derecha, 3=arriba
    # Mapeo de esquinas a coordenadas iniciales
    corner_map = {
      "ARIZ" => [@original_x, @original_y],
      "ABIZ" => [@original_x, @original_y - yrange],
      "ABDE" => [@original_x - xrange, @original_y - yrange],
      "ARDE" => [@original_x - xrange, @original_y]
    }
    # Calcula la posición inicial según la esquina especificada
    initial_x, initial_y = corner_map[corner]
    # Determina las direcciones posibles basadas en el rango
    if xrange < 0
      dirs.push(1); dirs.push(2)
    elsif xrange > 0
      dirs.push(1) if @x > initial_x
      dirs.push(2) if @x < initial_x + xrange
    end
    if yrange < 0
      dirs.push(0); dirs.push(3)
    elsif yrange > 0
      dirs.push(0) if @y < initial_y + yrange
      dirs.push(3) if @y > initial_y
    end
    return if dirs.empty?
    # Define las acciones posibles: moverse, girar o quedarse quieto
    actions = [:move, :turn, :stay]
    # Selecciona una acción aleatoria según las proporciones dadas
    action = select_random_action(actions)
    # Realiza la acción seleccionada
    case action
    when :move
      # Selecciona una dirección de movimiento aleatoria
      case dirs[rand(dirs.length)]
        when 0 then move_down(false)
        when 1 then move_left(false)
        when 2 then move_right(false)
        when 3 then move_up(false)
      end
    when :turn
      # Gira en una dirección aleatoria
      dir_giro = rand(4)
      case dir_giro
        when 0 then turn_up
        when 1 then turn_down
        when 2 then turn_left
        when 3 then turn_right
      end
    when :stay
      # No hace nada, que se gire en la dirección a la que ya mira.
      case @direction
        # El evento está mirando hacia abajo
        when 2 then turn_down
        # El evento está mirando hacia la izquierda
        when 4 then turn_left
        # El evento está mirando hacia la derecha
        when 6 then turn_right
        # El evento está mirando hacia arriba
        when 8 then turn_up
      end
    end
  end
  
  def select_random_action(actions)
    # Genera un número aleatorio entre 1 y la suma de los pesos de las acciones
    total_weight = actions.size + actions.size + actions.size
    random_number = rand(1..total_weight)
    # Asigna una acción en función del número aleatorio generado
    if random_number <= actions.size
      return actions[0]
    elsif random_number <= actions.size * 2
      return actions[1]
    else
      return actions[2]
    end
  end

  def move_random_UD(range = -1)
    move_random_range(0, range)
  end

  def move_random_LR(range = -1)
    move_random_range(range, 0)
  end

  def move_toward_player
    sx = @x + (@width / 2.0) - ($game_player.x + ($game_player.width / 2.0))
    sy = @y - (@height / 2.0) - ($game_player.y - ($game_player.height / 2.0))
    return if sx == 0 && sy == 0
    abs_sx = sx.abs
    abs_sy = sy.abs
    if abs_sx == abs_sy
      (rand(2) == 0) ? abs_sx += 1 : abs_sy += 1
    end
    if abs_sx > abs_sy
      (sx > 0) ? move_left : move_right
      if !moving? && sy != 0
        (sy > 0) ? move_up : move_down
      end
    else
      (sy > 0) ? move_up : move_down
      if !moving? && sx != 0
        (sx > 0) ? move_left : move_right
      end
    end
  end

  def move_away_from_player
    sx = @x + (@width / 2.0) - ($game_player.x + ($game_player.width / 2.0))
    sy = @y - (@height / 2.0) - ($game_player.y - ($game_player.height / 2.0))
    return if sx == 0 && sy == 0
    abs_sx = sx.abs
    abs_sy = sy.abs
    if abs_sx == abs_sy
      (rand(2) == 0) ? abs_sx += 1 : abs_sy += 1
    end
    if abs_sx > abs_sy
      (sx > 0) ? move_right : move_left
      if !moving? && sy != 0
        (sy > 0) ? move_down : move_up
      end
    else
      (sy > 0) ? move_down : move_up
      if !moving? && sx != 0
        (sx > 0) ? move_right : move_left
      end
    end
  end

  def move_forward
    case @direction
    when 2 then move_down(false)
    when 4 then move_left(false)
    when 6 then move_right(false)
    when 8 then move_up(false)
    end
  end

  def move_backward
    last_direction_fix = @direction_fix
    @direction_fix = true
    case @direction
    when 2 then move_up(false)
    when 4 then move_right(false)
    when 6 then move_left(false)
    when 8 then move_down(false)
    end
    @direction_fix = last_direction_fix
  end

  def jump(x_plus, y_plus)
    if x_plus != 0 || y_plus != 0
      if x_plus.abs > y_plus.abs
        (x_plus < 0) ? turn_left : turn_right
      else
        (y_plus < 0) ? turn_up : turn_down
      end
      each_occupied_tile { |i, j| return if !passable?(i + x_plus, j + y_plus, 0) }
    end
    @jump_initial_x = @x
    @jump_initial_y = @y
    @x += x_plus
    @y += y_plus
    @jump_timer = 0.0
    real_distance = Math.sqrt((x_plus**2) + (y_plus**2))
    distance = [1, real_distance].max
    @jump_peak = distance * Game_Map::TILE_HEIGHT * 3 / 8   # 3/4 of tile for ledge jumping
    @jump_distance = [x_plus.abs * Game_Map::REAL_RES_X, y_plus.abs * Game_Map::REAL_RES_Y].max
    @jumping_on_spot = (real_distance == 0)
    increase_steps
  end

  def jumpForward(distance = 1)
    return false if distance == 0
    old_x = @x
    old_y = @y
    case self.direction
    when 2 then jump(0, distance)    # down
    when 4 then jump(-distance, 0)   # left
    when 6 then jump(distance, 0)    # right
    when 8 then jump(0, -distance)   # up
    end
    return @x != old_x || @y != old_y
  end

  def jumpBackward(distance = 1)
    return false if distance == 0
    old_x = @x
    old_y = @y
    case self.direction
    when 2 then jump(0, -distance)   # down
    when 4 then jump(distance, 0)    # left
    when 6 then jump(-distance, 0)   # right
    when 8 then jump(0, distance)    # up
    end
    return @x != old_x || @y != old_y
  end

  def turn_generic(dir)
    return if @direction_fix
    oldDirection = @direction
    @direction = dir
    @stop_count = 0
    pbCheckEventTriggerAfterTurning if dir != oldDirection
  end

  def turn_down;  turn_generic(2); end
  def turn_left;  turn_generic(4); end
  def turn_right; turn_generic(6); end
  def turn_up;    turn_generic(8); end

  def turn_right_90
    case @direction
    when 2 then turn_left
    when 4 then turn_up
    when 6 then turn_down
    when 8 then turn_right
    end
  end

  def turn_left_90
    case @direction
    when 2 then turn_right
    when 4 then turn_down
    when 6 then turn_up
    when 8 then turn_left
    end
  end

  def turn_180
    case @direction
    when 2 then turn_up
    when 4 then turn_right
    when 6 then turn_left
    when 8 then turn_down
    end
  end

  def turn_right_or_left_90
    (rand(2) == 0) ? turn_right_90 : turn_left_90
  end

  def turn_random
    case rand(4)
    when 0 then turn_up
    when 1 then turn_right
    when 2 then turn_left
    when 3 then turn_down
    end
  end

  def turn_toward_player
    sx = @x + (@width / 2.0) - ($game_player.x + ($game_player.width / 2.0))
    sy = @y - (@height / 2.0) - ($game_player.y - ($game_player.height / 2.0))
    return if sx == 0 && sy == 0
    if sx.abs > sy.abs
      (sx > 0) ? turn_left : turn_right
    else
      (sy > 0) ? turn_up : turn_down
    end
  end

  def turn_away_from_player
    sx = @x + (@width / 2.0) - ($game_player.x + ($game_player.width / 2.0))
    sy = @y - (@height / 2.0) - ($game_player.y - ($game_player.height / 2.0))
    return if sx == 0 && sy == 0
    if sx.abs > sy.abs
      (sx > 0) ? turn_right : turn_left
    else
      (sy > 0) ? turn_down : turn_up
    end
  end

  #=============================================================================
  # Updating
  #=============================================================================
  def update
    return if $game_temp.in_menu
    time_now = System.uptime
    @last_update_time = time_now if !@last_update_time || @last_update_time > time_now
    @delta_t = time_now - @last_update_time
    @last_update_time = time_now
    return if @delta_t > 0.25   # Was in a menu; delay movement
    @moved_last_frame = @moved_this_frame
    @stopped_last_frame = @stopped_this_frame
    @moved_this_frame = false
    @stopped_this_frame = false
    # Update command
    update_command
    # Update movement
    (moving? || jumping?) ? update_move : update_stop
    # Update animation
    update_pattern
  end

  def update_command
    if @wait_count > 0
      return if System.uptime - @wait_start < @wait_count
      @wait_count = 0
      @wait_start = nil
    end
    if @move_route_forcing
      move_type_custom
    elsif !@starting && !lock? && !moving? && !jumping?
      update_command_new
    end
  end

  def update_command_new
    if @stop_count >= @command_delay
      case @move_type
      when 1 then move_type_random
      when 2 then move_type_toward_player
      when 3 then move_type_custom
      end
    end
  end

  def update_move
    if @move_timer
      @move_timer += @delta_t
      # Move horizontally
      if @x != @move_initial_x
        dist = (@move_initial_x - @x).abs
        @real_x = lerp(@move_initial_x, @x, @move_time * dist, @move_timer) * Game_Map::REAL_RES_X
      end
      # Move vertically
      if @y != @move_initial_y
        dist = (@move_initial_y - @y).abs
        @real_y = lerp(@move_initial_y, @y, @move_time * dist, @move_timer) * Game_Map::REAL_RES_Y
      end
    elsif @jump_timer
      self.jump_speed = 3 if !@jump_time
      @jump_timer += @delta_t
      dist = [(@x - @jump_initial_x).abs, (@y - @jump_initial_y).abs].max
      dist = 1 if dist == 0   # Jumping on spot
      # Move horizontally
      if @x != @jump_initial_x
        @real_x = lerp(@jump_initial_x, @x, @jump_time * dist, @jump_timer) * Game_Map::REAL_RES_X
      end
      # Move vertically
      if @y != @jump_initial_y
        @real_y = lerp(@jump_initial_y, @y, @jump_time * dist, @jump_timer) * Game_Map::REAL_RES_Y
      end
      # Calculate how far through the jump we are (from 0 to 1)
      @jump_fraction = @jump_timer / (@jump_time * dist)
    end
    # Snap to end position if close enough
    @real_x = @x * Game_Map::REAL_RES_X if (@real_x - (@x * Game_Map::REAL_RES_X)).abs < Game_Map::X_SUBPIXELS / 2
    @real_y = @y * Game_Map::REAL_RES_Y if (@real_y - (@y * Game_Map::REAL_RES_Y)).abs < Game_Map::Y_SUBPIXELS / 2
    # End of move
    if moving? && @move_timer >= @move_time &&
       @real_x == @x * Game_Map::REAL_RES_X && @real_y == @y * Game_Map::REAL_RES_Y
      @move_timer = nil
      @bumping = false
    end
    # End of jump
    if jumping? && @jump_fraction >= 1
      @jump_timer = nil
      @jump_peak = 0
      @jump_distance = 0
      @jump_fraction = 0
      @jumping_on_spot = false
    end
    # End of a step, so perform events that happen at this time
    if !jumping? && !moving?
      EventHandlers.trigger(:on_step_taken, self)
      calculate_bush_depth
      @stopped_this_frame = true
    elsif !@moved_last_frame || @stopped_last_frame   # Started a new step
      calculate_bush_depth
    end
    # Increment animation counter
    @anime_count += @delta_t if @walk_anime || @step_anime
    @moved_this_frame = true
  end

  def update_stop
    @anime_count += @delta_t if @step_anime
    @stop_count += @delta_t if !@starting && !lock?
  end

  def update_pattern
    return if @lock_pattern
#    return if @jumping_on_spot   # Don't animate if jumping on the spot
    # Character has stopped moving, return to original pattern
    if @moved_last_frame && !@moved_this_frame && !@step_anime
      @pattern = @original_pattern
      @anime_count = 0
      return
    end
    # Character has started to move, change pattern immediately
    if !@moved_last_frame && @moved_this_frame && !@step_anime
      @pattern = (@pattern + 1) % 4 if @walk_anime
      @anime_count = 0
      return
    end
    # Calculate how many frames each pattern should display for, i.e. the time
    # it takes to move half a tile (or a whole tile if cycling). We assume the
    # game uses square tiles.
    pattern_time = pattern_update_speed / 4   # 4 frames per cycle in a charset
    return if @anime_count < pattern_time
    # Advance to the next animation frame
    @pattern = (@pattern + 1) % 4
    @anime_count -= pattern_time
  end
end

