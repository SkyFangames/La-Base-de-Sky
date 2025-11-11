#===============================================================================
# Battle Speed Control
# Version: 1.0.0
# Author: Nononever
#===============================================================================
# A simple plugin for battle-speed control with options menu support.
# Allows speed adjustment ONLY during battles.
#===============================================================================

module BattleSpeedControl
  # Available speed stages (1.0 = Normal, 2.0 = Double speed)
  SPEED_STAGES = [1.0, 1.5, 2.0, 3.0]
  
  # Default speed stage (0 = Normal, 1 = 1.5x, 2 = 2x, 3 = 3x)
  DEFAULT_SPEED = 1
  
  # Show speed-up setting in options menu
  SHOW_IN_OPTIONS = true
  
  # Trigger key for toggling speed during battle (Input::SPECIAL, Input::AUX1, etc.)
  # Set to nil to disable trigger key
  TRIGGER_KEY = Input::SPECIAL  # Z key on keyboard, R button on controller
  
  # Global variables
  @in_battle = false
  @battle_speed_multiplier = 1.0
  @battle_start_time = nil
  @accelerated_time = 0
  
  def self.in_battle?
    @in_battle
  end
  
  def self.battle_speed_multiplier
    @battle_speed_multiplier
  end
  
  def self.start_battle
    @in_battle = true
    @battle_speed_multiplier = SPEED_STAGES[$PokemonSystem.battle_speed]
    @battle_start_time = System.battle_speed_control_uptime || 0
    @accelerated_time = 0
  end
  
  def self.end_battle
    @in_battle = false
    @battle_speed_multiplier = 1.0
    @battle_start_time = nil
  end
  
  def self.update_time
    return nil unless @in_battle && @battle_start_time
    
    current_time = System.battle_speed_control_uptime
    return nil unless current_time
    
    real_elapsed = current_time - @battle_start_time
    @accelerated_time = @battle_start_time + (real_elapsed * @battle_speed_multiplier)
    return @accelerated_time
  end
  
  def self.update_trigger_key
    return unless @in_battle && TRIGGER_KEY
    
    if Input.trigger?(TRIGGER_KEY)
      # Cycle through speed stages
      current_index = $PokemonSystem.battle_speed
      next_index = (current_index + 1) % SPEED_STAGES.length
      $PokemonSystem.battle_speed = next_index
      
      # Update current battle speed
      @battle_speed_multiplier = SPEED_STAGES[next_index]
      
      # Show speed change message
      speed_text = "x#{SPEED_STAGES[next_index]}"
      pbMessage(_INTL("Battle speed changed to {1}", speed_text))
    end
  end
end

#===============================================================================
# PokemonSystem Extension - Stores Battle Speed Setting
#===============================================================================
class PokemonSystem
  attr_accessor :battle_speed
  
  alias battle_speed_initialize initialize
  def initialize
    battle_speed_initialize
    @battle_speed = BattleSpeedControl::DEFAULT_SPEED
  end
  
  def battle_speed
    @battle_speed || BattleSpeedControl::DEFAULT_SPEED
  end
end

#===============================================================================
# System.uptime Override during battle
#===============================================================================
module System
  class << self
    alias battle_speed_control_uptime uptime unless method_defined?(:battle_speed_control_uptime)
    
    def uptime
      original_time = battle_speed_control_uptime
      return original_time unless original_time  # Return nil if uptime doesn't exist
      
      # If we're in battle, use accelerated time
      if BattleSpeedControl.in_battle?
        accelerated = BattleSpeedControl.update_time
        return accelerated if accelerated
      end
      
      original_time
    end
  end
end

#===============================================================================
# EventHandlers for Battle Start/End
#===============================================================================
EventHandlers.add(:on_start_battle, :battle_speed_start, proc {
  BattleSpeedControl.start_battle
})

EventHandlers.add(:on_end_battle, :battle_speed_end, proc {
  BattleSpeedControl.end_battle
})

EventHandlers.add(:on_battle_update, :battle_speed_trigger, proc {
  BattleSpeedControl.update_trigger_key
})

#===============================================================================
# Options Menu Integration
#===============================================================================
if BattleSpeedControl::SHOW_IN_OPTIONS
  MenuHandlers.add(:options_menu, :battle_speed, {
    "name"        => _INTL("Battle Speed"),
    "order"       => 25,
    "type"        => EnumOption,
    "parameters"  => BattleSpeedControl::SPEED_STAGES.map { |s| _INTL("x#{s}") },
    "description" => _INTL("Choose the speed for battles."),
    "get_proc"    => proc { next $PokemonSystem.battle_speed },
    "set_proc"    => proc { |value, scene|
      $PokemonSystem.battle_speed = value
    }
  })
end

#===============================================================================
# Debug Info
#===============================================================================
puts "Battle Speed Control v1.1.0 loaded"
puts "Available speeds: #{BattleSpeedControl::SPEED_STAGES.join(', ')}"
puts "Default speed: x#{BattleSpeedControl::SPEED_STAGES[BattleSpeedControl::DEFAULT_SPEED]}"
puts "Trigger key enabled: #{BattleSpeedControl::TRIGGER_KEY ? 'Yes' : 'No'}"
