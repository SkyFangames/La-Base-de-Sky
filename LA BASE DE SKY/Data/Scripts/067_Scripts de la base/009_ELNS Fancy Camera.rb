#===============================================================================
# CREDITOS
# ELNS
# Website = https://enls.eu/
#===============================================================================
class FancyCamera
  # Default camera speed (Default: 1)
  DEFAULT_SPEED = 1

  # Increase camera speed when running (Default: true)
  INCREASE_WHEN_RUNNING = false
  
  # Override Scroll Map event commands (Default: true)
  OVERRIDE_SCROLL_MAP = false
end

#if $game_switches && $game_switches[CAMERA_FANCY]

class Game_Temp
  attr_accessor :camera_pos, :camera_x, :camera_y, :camera_shake,
                :camera_speed, :camera_offset, :camera_target_event

  def camera_pos
    @camera_pos = [0, 0] if !@camera_pos
    return @camera_pos || [(self.camera_x * Game_Map::REAL_RES_X) - Game_Player::SCREEN_CENTER_X, (self.camera_y * Game_Map::REAL_RES_Y) - Game_Player::SCREEN_CENTER_Y] || [0, 0]
  end

  def camera_pos=(value)
    $game_temp.camera_target_event = nil
    self.camera_x = value[0]
    self.camera_y = value[1]
  end

  def camera_x=(value)
    @camera_x = value
    @camera_pos[0] = ((value == 0) ? 0 : (@camera_x * Game_Map::REAL_RES_X) - Game_Player::SCREEN_CENTER_X)
  end

  def camera_y=(value)
    @camera_y = value
    @camera_pos[1] = ((value == 0) ? 0 : (@camera_y * Game_Map::REAL_RES_Y) - Game_Player::SCREEN_CENTER_Y)
  end

  def camera_x
    return @camera_x || 0
  end

  def camera_y
    return @camera_y || 0
  end

  def camera_shake
    return @camera_shake || 0
  end

  def camera_shake=(value)
    @camera_shake = value
  end

  def camera_speed
    return (@camera_speed || FancyCamera::DEFAULT_SPEED || 1) * 0.16
  end

  def camera_offset
    if !@camera_offset
      @camera_offset = [0, 0]
    end
    return @camera_offset
  end

  def camera_offset=(value)
    @camera_offset = value
  end

  def camera_target_event
    return @camera_target_event || 0
  end

  def camera_target_event=(value)
    @camera_target_event = value
  end
  
end


# Scrolls the camera to x, y relative the player
def pbCameraScroll(relative_x, relative_y, speed = nil)
  pbCameraSpeed(speed) if speed
  $game_temp.camera_pos = [$game_player.x + relative_x, $game_player.y + relative_y]
end

def pbCameraScrollDirection(direction, distance, speed = nil)
  speed = FancyCamera::DEFAULT_SPEED if !speed || speed == 0
  x = ($game_temp.camera_x == 0) ? $game_player.x : $game_temp.camera_x
  y = ($game_temp.camera_y == 0) ? $game_player.y : $game_temp.camera_y
  case direction
  when 1 # Down Left
    x -= 1 * distance
    y += 1 * distance
  when 2 # Down
    y += 1 * distance
  when 3 # Down Right
    x += 1 * distance
    y += 1 * distance
  when 4 # Left
    x -= 1 * distance
  when 6 # Right
    x += 1 * distance
  when 7 # Up Left
    x -= 1 * distance
    y -= 1 * distance
  when 8 # Up
    y -= 1 * distance
  when 9 # Up Right
    x += 1 * distance
    y -= 1 * distance
  end
  case speed
  when 1  # Slowest
    speed = FancyCamera::DEFAULT_SPEED * 0.5
  when 2  # Slower
    speed = FancyCamera::DEFAULT_SPEED * 0.75
  when 3  # Slow
    speed = FancyCamera::DEFAULT_SPEED * 0.85
  when 4  # Fast
    speed = FancyCamera::DEFAULT_SPEED * 1
  when 5  # Faster
    speed = FancyCamera::DEFAULT_SPEED * 1.5
  when 6  # Fastest
    speed = FancyCamera::DEFAULT_SPEED * 2
  end
  pbCameraScrollTo(x, y, speed)
end


# Scrolls the camera to x, y on the map
def pbCameraScrollTo(x, y, speed = nil)
  if x == $game_player.x && y == $game_player.y
    pbCameraReset(speed)
  else
    pbCameraSpeed(speed) if speed
  $game_temp.camera_pos = [x, y]
  end
end

# Sets the camera to the player and resets the speed
def pbCameraReset(speed = nil)
  $game_temp.camera_speed = (speed != nil) ? speed : FancyCamera::DEFAULT_SPEED
  $game_temp.camera_target_event = nil
  $game_temp.camera_pos = [0, 0]
end

# Scrolls the camera to an event
def pbCameraToEvent(event_id = nil, speed = nil)
  pbCameraSpeed(speed) if speed
  event_id = get_self.id if !event_id
  event = $game_map.events[event_id]
  return if !event
  $game_temp.camera_target_event = event_id
end

# Starts a camera shake
def pbCameraShake(power = 2)
  $game_temp.camera_shake = power
end

# Stops the camera shake
def pbCameraShakeOff
  $game_temp.camera_shake = 0
end

# Sets the camera speed
def pbCameraSpeed(speed)
  speed = FancyCamera::DEFAULT_SPEED if !speed || speed == 0
  $game_temp.camera_speed = speed
end

# Sets the camera offset
def pbCameraOffset(x, y)
  $game_temp.camera_offset = [x, y]
end



def old_lerp(a, b, t)
  t = t / (Graphics.average_frame_rate / 60.0)
  return (1 - t) * a + t * b
end

def ease_in_out(a, b, t)
  return old_lerp(a, b, t * (3.0 - t))
end

#end

class Game_Player < Game_Character
  # Center player on-screen
  alias old_update_screen_position update_screen_position

  def update_screen_position(_last_real_x, _last_real_y)
    if !($game_switches && $game_switches[CAMERA_FANCY])
      old_update_screen_position(_last_real_x, _last_real_y)
    else
      return if self.map.scrolling?
      target = [@real_x - SCREEN_CENTER_X,@real_y - SCREEN_CENTER_Y]
      if $game_temp.camera_pos && $game_temp.camera_pos[0] != 0 && $game_temp.camera_pos[1] != 0
        target = $game_temp.camera_pos
      end
      if $game_temp.camera_target_event && $game_temp.camera_target_event != 0
        event = $game_map.events[$game_temp.camera_target_event]
        if event
          target = [event.real_x - SCREEN_CENTER_X, event.real_y - SCREEN_CENTER_Y]
        end
      end
      if $game_temp.camera_shake > 0
        power = $game_temp.camera_shake * 25
        target = [target[0] + rand(-power..power), target[1] + rand(-power..power)]
      end
      if $game_temp.camera_offset && $game_temp.camera_offset != [0, 0]
        target = [target[0] + ($game_temp.camera_offset[0] * Game_Map::REAL_RES_X), target[1] + ($game_temp.camera_offset[1] * Game_Map::REAL_RES_Y)]
      end
      distance = Math.sqrt((target[0] - self.map.display_x)**2 + (target[1] - self.map.display_y)**2)
      speed = $game_temp.camera_speed * 0.2
      if distance < 0.75
        self.map.display_x = target[0]
        self.map.display_y = target[1]
      else
        self.map.display_x = ease_in_out(self.map.display_x, target[0], speed)
        self.map.display_y = ease_in_out(self.map.display_y, target[1], speed)
      end
    end
  end

  alias old_set_movement_type set_movement_type

  def set_movement_type(type)
    if !($game_switches && $game_switches[CAMERA_FANCY])
      old_set_movement_type(type)
    else
      meta = GameData::PlayerMetadata.get($player&.character_ID || 1)
      new_charset = nil
      case type
      when :fishing
        new_charset = pbGetPlayerCharset(meta.fish_charset)
      when :surf_fishing
        new_charset = pbGetPlayerCharset(meta.surf_fish_charset)
      when :diving, :diving_fast, :diving_jumping, :diving_stopped
        self.move_speed = 3 if !@move_route_forcing
        new_charset = pbGetPlayerCharset(meta.dive_charset)
      when :surfing, :surfing_fast, :surfing_jumping, :surfing_stopped
        if !@move_route_forcing
          pbCameraSpeed(1.4) if FancyCamera::INCREASE_WHEN_RUNNING
          self.move_speed = (type == :surfing_jumping) ? 3 : 4
        end
        new_charset = pbGetPlayerCharset(meta.surf_charset)
      when :descending_waterfall, :ascending_waterfall
        self.move_speed = 2 if !@move_route_forcing
        new_charset = pbGetPlayerCharset(meta.surf_charset)
      when :cycling, :cycling_fast, :cycling_jumping, :cycling_stopped
        if !@move_route_forcing
          pbCameraSpeed(1.7) if FancyCamera::INCREASE_WHEN_RUNNING
          self.move_speed = (type == :cycling_jumping) ? 3 : 5
        end
        new_charset = pbGetPlayerCharset(meta.cycle_charset)
      when :running
        pbCameraSpeed(1.4) if FancyCamera::INCREASE_WHEN_RUNNING
        self.move_speed = 4 if !@move_route_forcing
        new_charset = pbGetPlayerCharset(meta.run_charset)
      when :ice_sliding
        pbCameraSpeed(1.4) if FancyCamera::INCREASE_WHEN_RUNNING
        self.move_speed = 4 if !@move_route_forcing
        new_charset = pbGetPlayerCharset(meta.walk_charset)
      else   # :walking, :jumping, :walking_stopped
        pbCameraSpeed(1) if FancyCamera::INCREASE_WHEN_RUNNING
        self.move_speed = 3 if !@move_route_forcing
        new_charset = pbGetPlayerCharset(meta.walk_charset)
      end
      if @bumping
        pbCameraSpeed(1) if FancyCamera::INCREASE_WHEN_RUNNING
        self.move_speed = 3
      end
      @character_name = new_charset if new_charset
    end
  end

  def moveto(x, y, center = false)
    super
    center(x, y) if center
    make_encounter_count
  end

  def center(x, y)
    pbCameraReset if $game_temp.camera_pos
    self.map.display_x = (x * Game_Map::REAL_RES_X) - SCREEN_CENTER_X
    self.map.display_y = (y * Game_Map::REAL_RES_Y) - SCREEN_CENTER_Y
  end
end

class Game_Character
  alias camera_moveto moveto unless self.method_defined?(:camera_moveto)

  def moveto(x, y, center = true)
    camera_moveto(x, y)
  end
end

if FancyCamera::OVERRIDE_SCROLL_MAP
  class Interpreter
    #-----------------------------------------------------------------------------
    # * Scroll Map
    #-----------------------------------------------------------------------------
    def command_203
      return true if $game_temp.in_battle
      #$game_map.start_scroll(@parameters[0], @parameters[1], @parameters[2])
      x = ($game_temp.camera_x == 0) ? $game_player.x : $game_temp.camera_x
      y = ($game_temp.camera_y == 0) ? $game_player.y : $game_temp.camera_y
      case @parameters[0]
      when 2  # Down
        y += 1 * @parameters[1]
      when 4  # Left
        x -= 1 * @parameters[1]
      when 6  # Right
        x += 1 * @parameters[1]
      when 8  # Up
        y -= 1 * @parameters[1]
      end
      case @parameters[2]
      when 1  # Slowest
        speed = FancyCamera::DEFAULT_SPEED * 0.5
      when 2  # Slower
        speed = FancyCamera::DEFAULT_SPEED * 0.75
      when 3  # Slow
        speed = FancyCamera::DEFAULT_SPEED * 0.85
      when 4  # Fast
        speed = FancyCamera::DEFAULT_SPEED * 1
      when 5  # Faster
        speed = FancyCamera::DEFAULT_SPEED * 1.5
      when 6  # Fastest
        speed = FancyCamera::DEFAULT_SPEED * 2
      end
      pbCameraScrollTo(x, y, speed)
      return true
    end
  end
end

class Scene_Map
  def transfer_player(cancel_swimming = true)
    $game_temp.player_transferring = false
    pbCancelVehicles($game_temp.player_new_map_id, cancel_swimming)
    autofade($game_temp.player_new_map_id)
    pbBridgeOff
    @spritesetGlobal.playersprite.clearShadows
    if $game_map.map_id != $game_temp.player_new_map_id
      $map_factory.setup($game_temp.player_new_map_id)
    end
    $game_player.moveto($game_temp.player_new_x, $game_temp.player_new_y, true)
    case $game_temp.player_new_direction
    when 2 then $game_player.turn_down
    when 4 then $game_player.turn_left
    when 6 then $game_player.turn_right
    when 8 then $game_player.turn_up
    end
    $game_player.straighten
    $game_temp.followers.map_transfer_followers
    $game_map.update
    disposeSpritesets
    RPG::Cache.clear
    createSpritesets
    if $game_temp.transition_processing
      $game_temp.transition_processing = false
      Graphics.transition
    end
    $game_map.autoplay
    Graphics.frame_reset
    Input.update
  end
end

