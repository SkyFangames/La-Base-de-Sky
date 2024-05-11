#===============================================================================
# CREDITOS
# Marin (og speed up script), Phantombass (19.1 version), Mashirosakura, Golisopod User, 
# D0vid (v21.1 version), Naelle & Skyflyer (Turbo Icon/Animation), DPertierra
# Website = https://reliccastle.com/threads/7145
#===============================================================================
#===============================================================================#
# Configuracion de velocidades
#===============================================================================#
SPEEDUP_STAGES = [1, 2, 3]
$GameSpeed = 0
$CanToggle = true

#===============================================================================#
# Controlar la velocidad del turbo presionando ALT
#===============================================================================#
module Input
  def self.update
    update_KGC_ScreenCapture
    pbScreenCapture if trigger?(Input::F8)
    if $CanToggle && trigger?(Input::ALT)
      $GameSpeed += 1
      $GameSpeed = 0 if $GameSpeed >= SPEEDUP_STAGES.size
      $PokemonSystem.battle_speed = $GameSpeed if $PokemonSystem && $PokemonSystem.only_speedup_battles == 1
	    $buttonframes = 0
    end
  end
end
#====================================================================================#
# Devuelve System.Uptime con un multiplicador creando una linea de tiempo alternativa
#====================================================================================#
module System
  class << self
    alias_method :unscaled_uptime, :uptime unless method_defined?(:unscaled_uptime)
  end

  def self.uptime
    return SPEEDUP_STAGES[$GameSpeed] * unscaled_uptime
  end
end
#===============================================================================#
# Controlador de eventos para el turbo en combates
#===============================================================================#
EventHandlers.add(:on_start_battle, :start_speedup, proc {
  $CanToggle = false
  $GameSpeed = $PokemonSystem.battle_speed if $PokemonSystem.only_speedup_battles == 1
})
EventHandlers.add(:on_end_battle, :stop_speedup, proc {
  $GameSpeed = 0 if $PokemonSystem.only_speedup_battles == 1
  $CanToggle = true if $PokemonSystem.only_speedup_battles == 0
})
#===============================================================================#
# Solo se puede cambiar la velocidad en combates durante la fase de comandos 
# de los contrario da errores
#===============================================================================#
class Battle
  alias_method :original_pbCommandPhase, :pbCommandPhase unless method_defined?(:original_pbCommandPhase)
  def pbCommandPhase
    $CanToggle = true
    original_pbCommandPhase
    $CanToggle = false
  end
end
#===============================================================================#
# Corrección para soft lockeos en combates consecutivos
#===============================================================================#
alias :original_pbBattleOnStepTaken :pbBattleOnStepTaken
def pbBattleOnStepTaken(repel_active)
  return if $game_temp.in_battle
  original_pbBattleOnStepTaken(repel_active)
end
#===============================================================================#
# Corrección para controlar la velocidad de la niebla
#===============================================================================#
class Game_Map
  alias_method :original_update, :update unless method_defined?(:original_update)

  def update
    temp_timer = @fog_scroll_last_update_timer
    @fog_scroll_last_update_timer = System.uptime # No scrollear en el metodo de actualización original
    original_update
    @fog_scroll_last_update_timer = temp_timer
    update_fog
  end

  def update_fog
    uptime_now = System.unscaled_uptime
    @fog_scroll_last_update_timer = uptime_now unless @fog_scroll_last_update_timer
    speedup_mult = $PokemonSystem.only_speedup_battles == 1 ? 1 : SPEEDUP_STAGES[$GameSpeed]
    scroll_mult = (uptime_now - @fog_scroll_last_update_timer) * 5 * speedup_mult
    @fog_ox -= @fog_sx * scroll_mult
    @fog_oy -= @fog_sy * scroll_mult
    @fog_scroll_last_update_timer = uptime_now
  end
end
#===============================================================================#
# Correción para crasheos del animation index
#===============================================================================#
class SpriteAnimation
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
    @only_speedup_battles = 0 # Configuracion del turbo (0=siempre, 1=solo_combates)
    @battle_speed = 0 # Depends on the SPEEDUP_STAGES array size
  end
end

#===============================================================================#
# Controlador de opciones del menú 
#===============================================================================#
MenuHandlers.add(:options_menu, :only_speedup_battles, {
  "name" => _INTL("Aumentar velocidad"),
  "order" => 25,
  "type" => EnumOption,
  "parameters" => [_INTL("Siempre"), _INTL("En combates")],
  "description" => _INTL("Elige cuándo quieres que se pueda acelerar la velocidad del juego."),
  "get_proc" => proc { next $PokemonSystem.only_speedup_battles },
  "set_proc" => proc { |value, scene|
    $PokemonSystem.only_speedup_battles = value
  }
})

module Graphics
  class << self
    alias _old_update_turbo update
    def update
      _old_update_turbo
      $buttonframes = 150 if !$buttonframes
      if $buttonframes < 150 # Frames en pantalla
        if !@boton_turbo || @boton_turbo.disposed?
          @boton_turbo = Sprite.new
          if $GameSpeed == 0
            @boton_turbo.bitmap = Bitmap.new("Graphics/Pictures/Turbo0")
          elsif $GameSpeed == 1
            @boton_turbo.bitmap = Bitmap.new("Graphics/Pictures/Turbo1")
          else
            @boton_turbo.bitmap = Bitmap.new("Graphics/Pictures/Turbo2")
          end
          @boton_turbo.z = 999999
        elsif @boton_turbo
          if $GameSpeed == 0
            @boton_turbo.bitmap = Bitmap.new("Graphics/Pictures/Turbo0")
          elsif $GameSpeed == 1
            @boton_turbo.bitmap = Bitmap.new("Graphics/Pictures/Turbo1")
          else
            @boton_turbo.bitmap = Bitmap.new("Graphics/Pictures/Turbo2")
          end
        end
        $buttonframes += 1
        if $buttonframes == 150
          @boton_turbo.dispose
        end
      end
    end
  end
end