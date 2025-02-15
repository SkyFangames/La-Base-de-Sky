#===============================================================================
#  Class used for generating scrolling backgrounds (move animations)
#===============================================================================
module Sprites
  class Scrolling < Base
    #-------------------------------------------------------------------------
    attr_accessor :speed, :direction, :vertical, :pulse, :min_o, :max_o
    #-------------------------------------------------------------------------
    #  set default attribute values
    #-------------------------------------------------------------------------
    def default!
      super
      additional_defaults
    end
    #-------------------------------------------------------------------------
    #  set sprite bitmap
    #-------------------------------------------------------------------------
    def set_bitmap(bmp, vertical: false, pulse: false, speed: 1)
      additional_defaults

      bmp       = SpriteHash.bitmap(bmp)
      @vertical = vertical
      @pulse    = pulse
      @speed    = speed

      # construct bitmap strip
      if @vertical
        self.bitmap = ::Bitmap.new(bmp.width, bmp.height * 2)

        2.times do |i|
          bitmap.blt(0, bmp.height * i, bmp, bmp.rect)
        end

        src_rect.set(0, @direction > 0 ? 0 : bmp.height, bmp.width, bmp.height)
      else
        self.bitmap = ::Bitmap.new(bmp.width * 2, bmp.height)

        2.times do |i|
          bitmap.blt(bmp.width * i, 0, bmp, bmp.rect)
        end

        src_rect.set(@direction > 0 ? 0 : bmp.width, 0, bmp.width, bmp.height)
      end

      bmp.dispose
    end
    #-------------------------------------------------------------------------
    #  update sprite animation
    #-------------------------------------------------------------------------
    def update
      @frame += 1

      return if @frame < (1 / @speed).to_i.lerp

      mod = [@direction, ((@speed < 1 ? 1 : @speed) * @direction)]
      # update scrolling motion
      if @vertical
        @current_y += (@direction > 0 ? mod.max : mod.min).lerp
        @current_y = 0 if @direction > 0 && src_rect.y >= src_rect.height
        @current_y = src_rect.height if @direction < 0 && src_rect.y <= 0
        src_rect.y = @current_y
      else
        @current_x += (@direction > 0 ? mod.max : mod.min).lerp
        @current_x = 0 if @direction > 0 && src_rect.x >= src_rect.width
        @current_x = src_rect.width if @direction < 0 && src_rect.x <= 0
        src_rect.x = @current_x
      end

      if @pulse
        opacity -= (@gopac * (@speed < 1 ? 1 : @speed)).lerp
        @gopac *= -1 if [@max_o, @min_o].include?(opacity)
      end

      @frame = 0
    end

    private
    #-------------------------------------------------------------------------
    #  class specific defaults
    #-------------------------------------------------------------------------
    def additional_defaults
      @direction ||= 1
      @speed     ||= 3
      @gopac       = 1
      @frame       = 0
      @min_o       = 0
      @max_o       = 255
      @current_x   = 0.0
      @current_y   = 0.0
    end
    #-------------------------------------------------------------------------
  end
end
