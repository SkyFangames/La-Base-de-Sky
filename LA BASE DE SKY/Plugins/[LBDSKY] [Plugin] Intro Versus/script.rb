#=============================================================================
# ANIMACIÓN CUSTOM DE INTRO VERSUS
#
# Para que funcione, añade a la carpeta de Graphics/Transitions todos los
# archivos que vienen con el plugin, y además añade estos archivos para
# el entrenador en el que quieras que aparezca:
#     custom_background_CLASEENTRENADOR.png
#     custom_vs_CLASEENTRENADOR.png
#
# Esos dos archivos tienen que estar también en la carpeta de Transitions.
# Por ejemplo, si tengo un entrenador que es un CAZABICHOS, el primer archivo
# sería "custom_background_CAZABICHOS.png"
#=============================================================================

module Transitions
  class VSTrainerCustom < Transition_Base
      DURATION           = 5.0
      BAR_Y              = 46
      BAR_SCROLL_SPEED   = 1800
      BAR_MASK           = [8, 7, 6, 5, 4, 3, 2, 1, 0, 1, 2, 3, 4, 5, 6, 7]
      FOE_SPRITE_X_LIMIT = 284   # El gráfico del rival salta a esta posición antes de llegar a la posición final.
      FOE_SPRITE_X       = 328-72   # Posicion final del sprite rival.

      FUENTE_DE_TEXTO    = "Power Clear" # Indica aquí el nombre de la fuente de texto del nombre.
                                         # La Font debe estar en la carpeta Fonts
      TAMANYO_DE_TEXTO   = 60
      POS_X_TEXTO        = 84  # Posición horizontal del nombre.
      POS_Y_TEXTO        = 276 # Posición vertical del nombre.

      def initialize_bitmaps
      @bar_bitmap   = RPG::Cache.transition("custom_vsBar")
      @vs_1_bitmap  = RPG::Cache.transition("custom_vs1")
      @vs_2_bitmap  = RPG::Cache.transition("custom_vs2")
      @foe_bitmap   = RPG::Cache.transition("custom_vs_#{$game_temp.transition_animation_data[0]}")
      @background   = RPG::Cache.transition("custom_background_#{$game_temp.transition_animation_data[0]}")
      @black_bitmap = RPG::Cache.transition("black_half")
      dispose if !@bar_bitmap || !@vs_1_bitmap || !@vs_2_bitmap || !@foe_bitmap || !@background || !@black_bitmap 
      end

      def initialize_sprites
      @flash_viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
      @flash_viewport.z     = 99999
      @flash_viewport.color = Color.new(255, 255, 255, 0)
      # Background black
      @rear_black_sprite = new_sprite(0, 0, @black_bitmap)
      @rear_black_sprite.z       = 1
      @rear_black_sprite.zoom_y  = 2.0
      @rear_black_sprite.opacity = 224
      @rear_black_sprite.visible = false
      # Background
      @rear_black_sprite = new_sprite(0, 0, @background)
      @rear_black_sprite.z       = 1
      @rear_black_sprite.visible = false
      # Bar sprites (need 2 of them to make them loop around)
      ((Graphics.width.to_f / @bar_bitmap.width).ceil + 1).times do |i|
          spr = new_sprite(@bar_bitmap.width * i, BAR_Y, @bar_bitmap)
          spr.z = 2
          @sprites.push(spr)
      end
      # Overworld sprite
      @bar_mask_sprite = new_sprite(0, 0, @overworld_bitmap.clone)
      @bar_mask_sprite.z = 3
      # VS logo
      @vs_x = 144
      @vs_y = @sprites[0].y + (@sprites[0].height / 2)
      @vs_main_sprite = new_sprite(@vs_x, @vs_y, @vs_1_bitmap, @vs_1_bitmap.width / 2, @vs_1_bitmap.height / 2)
      @vs_main_sprite.z       = 4
      @vs_main_sprite.visible = false
      @vs_1_sprite = new_sprite(@vs_x, @vs_y, @vs_2_bitmap, @vs_2_bitmap.width / 2, @vs_2_bitmap.height / 2)
      @vs_1_sprite.z       = 5
      @vs_1_sprite.zoom_x  = 2.0
      @vs_1_sprite.zoom_y  = @vs_1_sprite.zoom_x
      @vs_1_sprite.visible = false
      @vs_2_sprite = new_sprite(@vs_x, @vs_y, @vs_2_bitmap, @vs_2_bitmap.width / 2, @vs_2_bitmap.height / 2)
      @vs_2_sprite.z       = 6
      @vs_2_sprite.zoom_x  = 2.0
      @vs_2_sprite.zoom_y  = @vs_2_sprite.zoom_x
      @vs_2_sprite.visible = false
      # Foe sprite
      @foe_sprite = new_sprite(Graphics.width + @foe_bitmap.width, Graphics.height, #@sprites[0].y + @sprites[0].height - 12,
                              @foe_bitmap, @foe_bitmap.width / 2, @foe_bitmap.height)
      @foe_sprite.z     = 7
      @foe_sprite.color = Color.black
      # Sprite with foe's name written in it
      @text_sprite = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
      @text_sprite.x       = POS_X_TEXTO
      @text_sprite.y       = POS_Y_TEXTO
      @text_sprite.z       = 8
      @text_sprite.visible = false
      #pbSetSystemFont(@text_sprite.bitmap)
      @text_sprite.bitmap.font.name = FUENTE_DE_TEXTO
      @text_sprite.bitmap.font.size = TAMANYO_DE_TEXTO
      pbDrawTextPositions(@text_sprite.bitmap,
                          [[$game_temp.transition_animation_data[1], 0, 0, :left,
                              Color.new(248, 248, 248), Color.new(72, 80, 80)]])
      # Foreground black
      @black_sprite = new_sprite(0, 0, @black_bitmap)
      @black_sprite.z       = 10
      @black_sprite.zoom_y  = 2.0
      @black_sprite.visible = false
      end

      def set_up_timings
      @bar_x = 0
      @bar_appear_end      = 0.2   # Starts appearing at 0.0
      @vs_appear_start     = 0.7
      @vs_appear_start_2   = 0.9
      @vs_shrink_time      = @vs_appear_start_2 - @vs_appear_start
      @vs_appear_final     = @vs_appear_start_2 + @vs_shrink_time
      @foe_appear_start    = 1.25
      @foe_appear_end      = 1.4
      @flash_start         = 1.9
      @flash_duration      = 0.25
      @fade_to_white_start = 4.0
      @fade_to_white_end   = 4.5
      @fade_to_black_start = 4.8
      end

      def dispose_all
      # Dispose sprites
      @rear_black_sprite&.dispose
      @bar_mask_sprite&.dispose
      @vs_main_sprite&.dispose
      @vs_1_sprite&.dispose
      @vs_2_sprite&.dispose
      @foe_sprite&.dispose
      @text_sprite&.dispose
      @black_sprite&.dispose
      # Dispose bitmaps
      @bar_bitmap&.dispose
      @vs_1_bitmap&.dispose
      @vs_2_bitmap&.dispose
      @foe_bitmap&.dispose
      @background&.dispose
      @black_bitmap&.dispose
      # Dispose viewport
      @flash_viewport&.dispose
      end

      def update_anim
      # Bar scrolling
      @bar_x = -timer * BAR_SCROLL_SPEED
      while @bar_x <= -@bar_bitmap.width
          @bar_x += @bar_bitmap.width
      end
      @sprites.each_with_index { |spr, i| spr.x = @bar_x + (i * @bar_bitmap.width) }
      # Vibrate VS sprite
      if timer <= @flash_start + @flash_duration/2
          vs_phase = (timer * 30).to_i % 3
          @vs_main_sprite.x = @vs_x + [0, 4, 0][vs_phase]
          @vs_main_sprite.y = @vs_y + [0, 0, -4][vs_phase]
      end
      if timer >= @fade_to_black_start
          # Fade to black
          @black_sprite.visible = true
          proportion = (timer - @fade_to_black_start) / (@duration - @fade_to_black_start)
          @flash_viewport.color.alpha = 255 * (1 - proportion)
      elsif timer >= @fade_to_white_start
          # Slowly fade to white
          proportion = (timer - @fade_to_white_start) / (@fade_to_white_end - @fade_to_white_start)
          @flash_viewport.color.alpha = 255 * proportion
      elsif timer >= @flash_start + @flash_duration
          @flash_viewport.color.alpha = 0
      elsif timer >= @flash_start
          # Flash the screen white
          proportion = (timer - @flash_start) / @flash_duration
          if proportion >= 0.5
          @flash_viewport.color.alpha = 320 * 2 * (1 - proportion)
          @rear_black_sprite.visible = true
          @foe_sprite.color.alpha = 0
          @text_sprite.visible = true
          else
          @flash_viewport.color.alpha = 320 * 2 * proportion
          end
      elsif timer >= @foe_appear_end
          @foe_sprite.x = FOE_SPRITE_X
      elsif timer >= @foe_appear_start
          # Foe sprite appears
          proportion = (timer - @foe_appear_start) / (@foe_appear_end - @foe_appear_start)
          start_x = Graphics.width + (@foe_bitmap.width / 2)
          @foe_sprite.x = start_x + ((FOE_SPRITE_X_LIMIT - start_x) * proportion)
      elsif timer >= @vs_appear_final
          @vs_1_sprite.visible = false
      elsif timer >= @vs_appear_start_2
          # Temp VS sprites enlarge and shrink again
          if @vs_2_sprite.visible
          @vs_2_sprite.zoom_x = 1.6 - (0.8 * (timer - @vs_appear_start_2) / @vs_shrink_time)
          @vs_2_sprite.zoom_y = @vs_2_sprite.zoom_x
          if @vs_2_sprite.zoom_x <= 1.2
              @vs_2_sprite.visible = false
              @vs_main_sprite.visible = true
          end
          end
          @vs_1_sprite.zoom_x = 2.0 - (0.8 * (timer - @vs_appear_start_2) / @vs_shrink_time)
          @vs_1_sprite.zoom_y = @vs_1_sprite.zoom_x
      elsif timer >= @vs_appear_start
          # Temp VS sprites appear and start shrinking
          @vs_2_sprite.visible = true
          @vs_2_sprite.zoom_x = 2.0 - (0.8 * (timer - @vs_appear_start) / @vs_shrink_time)
          @vs_2_sprite.zoom_y = @vs_2_sprite.zoom_x
          if @vs_1_sprite.visible || @vs_2_sprite.zoom_x <= 1.6   # Halfway between 2.0 and 1.2
          @vs_1_sprite.visible = true
          @vs_1_sprite.zoom_x = 2.0 - (0.8 * (timer - @vs_appear_start - (@vs_shrink_time / 2)) / @vs_shrink_time)
          @vs_1_sprite.zoom_y = @vs_1_sprite.zoom_x
          end
      elsif timer >= @bar_appear_end
          @bar_mask_sprite.visible = false
      else
          start_x = Graphics.width * (1 - (timer / @bar_appear_end))
          color = Color.new(0, 0, 0, 0)   # Transparent
          (@sprites[0].height / 2).times do |i|
          x = start_x - (BAR_MASK[i % BAR_MASK.length] * 4)
          @bar_mask_sprite.bitmap.fill_rect(x, BAR_Y + (i * 2), @bar_mask_sprite.width - x, 2, color)
          end
      end
      end
  end
end


#===============================================================================
# Comprobación de que existen los gráficos custom.
#===============================================================================
SpecialBattleIntroAnimations.register("vs_trainer_animation_custom", 60,   # Priority 60
proc { |battle_type, foe, location|   # Condition
next false if battle_type.even? || foe.length != 1   # Trainer battle against 1 trainer
tr_type = foe[0].trainer_type
next pbResolveBitmap("Graphics/Transitions/custom_vs_#{tr_type}") &&
pbResolveBitmap("Graphics/Transitions/custom_background_#{tr_type}")
},
proc { |viewport, battle_type, foe, location|   # Animation
$game_temp.transition_animation_data = [foe[0].trainer_type, foe[0].name]
pbBattleAnimationCore("VSTrainerCustom", viewport, location, 1)
$game_temp.transition_animation_data = nil
}
)



#===============================================================================
# Reemplazamos este módulo para añadir la transición a la lista.
#===============================================================================
module Graphics
  @@transition = nil
  STOP_WHILE_TRANSITION = true

  unless defined?(transition_KGC_SpecialTransition)
    class << Graphics
      alias transition_KGC_SpecialTransition transition
    end

    class << Graphics
      alias update_KGC_SpecialTransition update
    end
  end

  def self.update
      update_KGC_SpecialTransition
      @@transition.update if @@transition && !@@transition.disposed?
      @@transition = nil if @@transition&.disposed?

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
      TrainerSensor.update if $scene && $scene.is_a?(Scene_Map)
  end

  # duration is in 1/20ths of a second
  def self.transition(duration = 8, filename = "", vague = 20)
    duration = duration.floor
    if judge_special_transition(duration, filename)
      duration = 0
      filename = ""
    end
    duration *= Graphics.frame_rate / 20   # For default fade-in animation, must be in frames
    begin
      transition_KGC_SpecialTransition(duration, filename, vague)
    rescue Exception
      transition_KGC_SpecialTransition(duration, "", vague) if filename != ""
    end
    if STOP_WHILE_TRANSITION && !@_interrupt_transition
      while @@transition && !@@transition.disposed?
        update
      end
    end
  end

  def self.judge_special_transition(duration, filename)
    return false if @_interrupt_transition
    ret = true
    if @@transition && !@@transition.disposed?
      @@transition.dispose
      @@transition = nil
    end
    duration /= 20.0   # Turn into seconds
    dc = File.basename(filename).downcase
    case dc
    # Other coded transitions
    when "breakingglass"    then @@transition = Transitions::BreakingGlass.new(duration)
    when "rotatingpieces"   then @@transition = Transitions::ShrinkingPieces.new(duration, true)
    when "shrinkingpieces"  then @@transition = Transitions::ShrinkingPieces.new(duration, false)
    when "splash"           then @@transition = Transitions::SplashTransition.new(duration, 9.6)
    when "random_stripe_v"  then @@transition = Transitions::RandomStripeTransition.new(duration, 0)
    when "random_stripe_h"  then @@transition = Transitions::RandomStripeTransition.new(duration, 1)
    when "zoomin"           then @@transition = Transitions::ZoomInTransition.new(duration)
    when "scrolldown"       then @@transition = Transitions::ScrollScreen.new(duration, 2)
    when "scrollleft"       then @@transition = Transitions::ScrollScreen.new(duration, 4)
    when "scrollright"      then @@transition = Transitions::ScrollScreen.new(duration, 6)
    when "scrollup"         then @@transition = Transitions::ScrollScreen.new(duration, 8)
    when "scrolldownleft"   then @@transition = Transitions::ScrollScreen.new(duration, 1)
    when "scrolldownright"  then @@transition = Transitions::ScrollScreen.new(duration, 3)
    when "scrollupleft"     then @@transition = Transitions::ScrollScreen.new(duration, 7)
    when "scrollupright"    then @@transition = Transitions::ScrollScreen.new(duration, 9)
    when "mosaic"           then @@transition = Transitions::MosaicTransition.new(duration)
    # HGSS transitions
    when "snakesquares"     then @@transition = Transitions::SnakeSquares.new(duration)
    when "diagonalbubbletl" then @@transition = Transitions::DiagonalBubble.new(duration, 0)
    when "diagonalbubbletr" then @@transition = Transitions::DiagonalBubble.new(duration, 1)
    when "diagonalbubblebl" then @@transition = Transitions::DiagonalBubble.new(duration, 2)
    when "diagonalbubblebr" then @@transition = Transitions::DiagonalBubble.new(duration, 3)
    when "risingsplash"     then @@transition = Transitions::RisingSplash.new(duration)
    when "twoballpass"      then @@transition = Transitions::TwoBallPass.new(duration)
    when "spinballsplit"    then @@transition = Transitions::SpinBallSplit.new(duration)
    when "threeballdown"    then @@transition = Transitions::ThreeBallDown.new(duration)
    when "balldown"         then @@transition = Transitions::BallDown.new(duration)
    when "wavythreeballup"  then @@transition = Transitions::WavyThreeBallUp.new(duration)
    when "wavyspinball"     then @@transition = Transitions::WavySpinBall.new(duration)
    when "fourballburst"    then @@transition = Transitions::FourBallBurst.new(duration)
    when "vstrainer"        then @@transition = Transitions::VSTrainer.new(duration)
    when "vstrainercustom"  then @@transition = Transitions::VSTrainerCustom.new(duration)
    when "vselitefour"      then @@transition = Transitions::VSEliteFour.new(duration)
    when "rocketgrunt"      then @@transition = Transitions::RocketGrunt.new(duration)
    when "vsrocketadmin"    then @@transition = Transitions::VSRocketAdmin.new(duration)
    # Graphic transitions
    when "fadetoblack"      then @@transition = Transitions::FadeToBlack.new(duration)
    when "fadefromblack"    then @@transition = Transitions::FadeFromBlack.new(duration)
    else                         ret = false
    end
    Graphics.frame_reset if ret
    return ret
  end
end