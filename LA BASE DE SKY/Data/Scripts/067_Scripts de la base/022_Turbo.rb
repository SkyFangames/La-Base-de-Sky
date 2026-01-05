#===============================================================================#
# Whether the options menu shows the speed up settings (true by default)
#===============================================================================#
module Settings
  SPEED_OPTIONS = true
end

#===============================================================================#
# Speed-up config
#===============================================================================#
SPEEDUP_STAGES = [1, 1.5, 2]
TURBO_BUTTON_DISPLAY_FRAMES = 150
FOG_SCROLL_MULTIPLIER = 5

$GameSpeed = 0
$CanToggle = true
$RefreshEventsForTurbo = false
$SpeedDifference = 0
$ActiveAnimations = []

#===============================================================================#
# Set $CanToggle depending on the saved setting
#===============================================================================#
module Game
  class << self
    alias_method :original_load, :load unless method_defined?(:original_load)
  end

  def self.load(save_data)
    original_load(save_data)
    # echoln "UNSCALED #{System.unscaled_uptime} * #{SPEEDUP_STAGES[$GameSpeed]} - #{$GameSpeed}"
    $CanToggle = $PokemonSystem&.only_speedup_battles == 0
  end
end

#===============================================================================#
# Handle incrementing speed stages if $CanToggle allows it
#===============================================================================#
module Input
  def self.update
    update_KGC_ScreenCapture
    pbScreenCapture if trigger?(Input::F8)
    if $CanToggle && (trigger?(Input::ALT) || (trigger?(Input::AUX1) && !Input.text_input))
      old_speed = $GameSpeed
      $GameSpeed += 1
      if $GameSpeed >= SPEEDUP_STAGES.size
        $GameSpeed = 0 
        $SpeedDifference += (System.real_uptime * SPEEDUP_STAGES[-1])
      end
      # Adjust active animation timers to prevent skipping
      if old_speed != $GameSpeed
        current_time = System.unscaled_uptime
        $ActiveAnimations.each do |anim|
          next unless anim && !anim.disposed?
          next unless anim.animation_active?
          # Calculate how much time has passed in the old speed
          old_elapsed = current_time - anim.instance_variable_get(:@_animation_real_start)
          # Calculate current frame progress
          old_progress = old_elapsed * SPEEDUP_STAGES[old_speed]
          # Set new timer start to maintain current frame
          new_start = current_time - (old_progress / SPEEDUP_STAGES[$GameSpeed])
          anim.instance_variable_set(:@_animation_real_start, new_start)
          anim.instance_variable_set(:@_animation_timer_start, System.uptime)
        end
      end
      # $PokemonSystem.battle_speed = $GameSpeed if $PokemonSystem && $PokemonSystem.only_speedup_battles == 1
      $buttonframes = 0
      $RefreshEventsForTurbo = true
    end
  end
end

#===============================================================================#
# Return System.Uptime with a multiplier to create an alternative timeline
#===============================================================================#
module System
  class << self
    unless method_defined?(:unscaled_uptime)
      alias_method :unscaled_uptime, :uptime
    end
  end

  def self.real_uptime
    return unscaled_uptime
  end

  def self.uptime
    return (SPEEDUP_STAGES[$GameSpeed] * unscaled_uptime) + $SpeedDifference
  end
end

#===============================================================================#
# Event handlers for in-battle speed-up restrictions
#===============================================================================#
EventHandlers.add(:on_start_battle, :start_speedup, proc {
  if $PokemonSystem&.only_speedup_battles == 1
    $CanToggle = true
    $GameSpeed = $PokemonSystem.battle_speed
  end
})
EventHandlers.add(:on_end_battle, :stop_speedup, proc {
  if $PokemonSystem&.only_speedup_battles == 1
    $GameSpeed = 0
    $CanToggle = false
  end
})


#===============================================================================#
# Can only change speed in battle during command phase (prevents weird animation glitches)
#===============================================================================#
# class Battle
#   alias_method :original_pbCommandPhase, :pbCommandPhase unless method_defined?(:original_pbCommandPhase)
#   def pbCommandPhase
#     $CanToggle = true
#     original_pbCommandPhase
#     $CanToggle = false
#   end
# end

#===============================================================================#
# Fix for consecutive battle soft-lock glitch
#===============================================================================#
alias :original_pbBattleOnStepTaken :pbBattleOnStepTaken
def pbBattleOnStepTaken(repel_active)
  return if $game_temp.in_battle
  original_pbBattleOnStepTaken(repel_active)
end

#===============================================================================#
# Fix for skipping player touch events at high turbo speeds
#===============================================================================#
class Game_Player < Game_Character
  alias_method :original_moveto, :moveto unless method_defined?(:original_moveto)
  
  def moveto(x, y, center = false)
    # Check intermediate tiles when turbo is active to prevent skipping events
    if $GameSpeed > 0 && @x && @y
      old_x, old_y = @x, @y
      # Check tiles between old and new position
      dx = (x - old_x).abs
      dy = (y - old_y).abs
      steps = [dx, dy].max
      
      if steps > 1
        steps.times do |i|
          progress = (i + 1).to_f / steps
          check_x = (old_x + (x - old_x) * progress).round
          check_y = (old_y + (y - old_y) * progress).round
          
          # Check for player touch events at intermediate positions
          $game_map.events.each_value do |event|
            next if event.tile_id >= 0 || event.character_name == ""
            next unless event.x == check_x && event.y == check_y
            next if event.jumping? || event.over_trigger?
            if event.list && event.list.size > 1 && [1, 2].include?(event.trigger)
              event.start
            end
          end
        end
      end
    end
    
    original_moveto(x, y, center)
  end
end

class Game_Event < Game_Character
  def pbGetInterpreter
    return @interpreter
  end

  def pbResetInterpreterWaitCount
    @interpreter.pbRefreshWaitCount if @interpreter
  end

  def IsParallel
    return @trigger == 4
  end  
end  

class Interpreter
  def pbRefreshWaitCount
    @wait_count = 0
    @wait_start = System.uptime
  end  
end  

class Window_AdvancedTextPokemon < SpriteWindow_Base
  def pbResetWaitCounter
    @wait_timer_start = nil
    @waitcount = 0
    @display_last_updated = nil
  end  
end  

$CurrentMsgWindow = nil;
def pbMessage(message, commands = nil, cmdIfCancel = 0, skin = nil, defaultCmd = 0, &block)
  ret = 0
  msgwindow = pbCreateMessageWindow(nil, skin)
  $CurrentMsgWindow = msgwindow

  if commands
    ret = pbMessageDisplay(msgwindow, message, true,
                           proc { |msgwndw|
                             next Kernel.pbShowCommands(msgwndw, commands, cmdIfCancel, defaultCmd, &block)
                           }, &block)
  else
    pbMessageDisplay(msgwindow, message, &block)
  end
  pbDisposeMessageWindow(msgwindow)
  $CurrentMsgWindow = nil
  Input.update
  return ret
end

#===============================================================================#
# Fix for scrolling fog speed
#===============================================================================#
class Game_Map
  alias_method :original_update, :update unless method_defined?(:original_update)

  def update
    if $RefreshEventsForTurbo
      begin
        if $game_map&.events
          $game_map.events.each_value { |event| event.pbResetInterpreterWaitCount if event }
        end
        @scroll_timer_start = System.uptime/SPEEDUP_STAGES[SPEEDUP_STAGES.size-1] if (@scroll_distance_x || 0) != 0 || (@scroll_distance_y || 0) != 0
        $CurrentMsgWindow.pbResetWaitCounter if $game_temp&.message_window_showing && $CurrentMsgWindow
      rescue => e
        # Registrar error pero no interrumpir el juego
        Console.echo_warn("Error actualizando eventos para turbo: #{e.message}")
      ensure
        $RefreshEventsForTurbo = false
      end
    end

    temp_timer = @fog_scroll_last_update_timer
    @fog_scroll_last_update_timer = System.uptime # No desplazar en el método original de actualización
    original_update
    @fog_scroll_last_update_timer = temp_timer
    update_fog
  end

  def update_fog
    uptime_now = System.unscaled_uptime
    @fog_scroll_last_update_timer = uptime_now unless @fog_scroll_last_update_timer
    speedup_mult = $PokemonSystem&.only_speedup_battles == 1 ? 1 : SPEEDUP_STAGES[$GameSpeed]
    scroll_mult = (uptime_now - @fog_scroll_last_update_timer) * FOG_SCROLL_MULTIPLIER * speedup_mult
    @fog_ox -= @fog_sx * scroll_mult
    @fog_oy -= @fog_sy * scroll_mult
    @fog_scroll_last_update_timer = uptime_now
  end
end

#===============================================================================#
# Fix for animation index crash
#===============================================================================#
class SpriteAnimation
  alias_method :original_animation, :animation unless method_defined?(:original_animation)
  
  def animation(animation, hit, height = 3)
    @_animation_real_start = System.unscaled_uptime
    $ActiveAnimations << self unless $ActiveAnimations.include?(self)
    original_animation(animation, hit, height)
  end
  
  def animation_active?
    return @_animation_duration && @_animation_duration > 0
  end
  
  alias_method :original_dispose_animation, :dispose_animation unless method_defined?(:original_dispose_animation)
  
  def dispose_animation
    $ActiveAnimations.delete(self)
    original_dispose_animation
  end
  
  def update_animation
    new_index = ((System.uptime - @_animation_timer_start) / @_animation_time_per_frame).to_i
    if new_index >= @_animation_duration
      dispose_animation
      return
    end
    quick_update = (@_animation_index == new_index)
    @_animation_index = new_index
    frame_index = @_animation_index
    current_frame = @_animation.frames[frame_index]
    unless current_frame
      dispose_animation
      return
    end
    cell_data   = current_frame.cell_data
    position    = @_animation.position
    animation_set_sprites(@_animation_sprites, cell_data, position, quick_update)
    return if quick_update
    @_animation.timings.each do |timing|
      next if timing.frame != frame_index
      animation_process_timing(timing, @_animation_hit)
    end
  end
end

#===============================================================================#
# PokemonSystem Accessors
#===============================================================================#
class PokemonSystem
  alias_method :original_initialize, :initialize unless method_defined?(:original_initialize)
  attr_accessor :only_speedup_battles
  attr_accessor :battle_speed

  def initialize
    original_initialize
    @only_speedup_battles = 0 # Speed up setting (0=always, 1=battle_only)
    @battle_speed = 0 # Depends on the SPEEDUP_STAGES array size
  end
end

MenuHandlers.add(:options_menu, :turbo, {
  "name"        => _INTL("Modo turbo"),
  "order"       => 45,
  "type"        => EnumOption,
  "condition"   => proc { next expshare_enabled? },
  "parameters"  => [_INTL("Siempre"), _INTL("Combates")],
  "description" => _INTL("Define el modo del turbo, si se puede activar siempre o solo en combates."),
  "get_proc"    => proc { next $PokemonSystem&.only_speedup_battles || 0 },
  "set_proc"    => proc { |value, _scene| 
    next unless $PokemonSystem
    $PokemonSystem.only_speedup_battles = value 
    $CanToggle = $PokemonSystem.only_speedup_battles == 0
    $GameSpeed = 0 if $PokemonSystem.only_speedup_battles == 1
  }
})



module Graphics
  class << self
    alias _old_update_turbo update
    
    # Cachear los bitmaps para evitar fugas de memoria
    def get_turbo_bitmap(speed)
      @turbo_bitmaps ||= {}
      unless @turbo_bitmaps[speed]
        begin
          @turbo_bitmaps[speed] = Bitmap.new("Graphics/Pictures/Turbo#{speed}")
        rescue => e
          Console.echo_warn("Error cargando bitmap de turbo: #{e.message}")
          return nil
        end
      end
      @turbo_bitmaps[speed]
    end
    
    # Limpiar bitmaps cacheados cuando sea necesario
    def dispose_turbo_bitmaps
      return unless @turbo_bitmaps
      @turbo_bitmaps.each_value { |bitmap| bitmap&.dispose }
      @turbo_bitmaps.clear
    end
    
    def update
      _old_update_turbo
      $buttonframes = TURBO_BUTTON_DISPLAY_FRAMES unless $buttonframes
      
      if $buttonframes < TURBO_BUTTON_DISPLAY_FRAMES
        # Crear sprite solo si no existe o está disposed
        if !@boton_turbo || @boton_turbo.disposed?
          @boton_turbo = Sprite.new
          @boton_turbo.z = 999999
          @last_displayed_speed = nil
        end
        
        # Solo actualizar bitmap si la velocidad cambió
        if @last_displayed_speed != $GameSpeed
          bitmap = get_turbo_bitmap($GameSpeed)
          @boton_turbo.bitmap = bitmap if bitmap
          @last_displayed_speed = $GameSpeed
        end
        
        $buttonframes += 1
        if $buttonframes >= TURBO_BUTTON_DISPLAY_FRAMES
          @boton_turbo&.dispose
          @last_displayed_speed = nil
        end
      end
    end
  end
end
