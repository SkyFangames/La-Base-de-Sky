#===============================================================================
#  Class used for generating sprites with a trail
#===============================================================================
module Sprites
  class Trailing
    include LUTS::Concerns::Animatable
    #-------------------------------------------------------------------------
    attr_accessor :x, :y, :z, :color, :key_frame, :zoom_x, :zoom_y, :opacity
    #-------------------------------------------------------------------------
    #  class constructor
    #-------------------------------------------------------------------------
    def initialize(viewport, bmp)
      @viewport = viewport
      @bmp      = bmp
      @sprites  = {}

      default!
    end
    #-------------------------------------------------------------------------
    #  set default attribute values
    #-------------------------------------------------------------------------
    def default!
      super

      @x         = 0
      @y         = 0
      @z         = 0
      @i         = 0
      @zoom_x    = 1
      @zoom_y    = 1
      @frame     = 128
      @key_frame = 0
      @color     = Color.new(0, 0, 0, 0)
      @opacity   = 255
    end
    #-------------------------------------------------------------------------
    #  update sprite animation
    #-------------------------------------------------------------------------
    def update
      @frame += 1
      reset_particle if @frame > @key_frame.delta_add(false)

      @sprites.keys.each do |key|
        next unless @sprites[key].opacity > @key_frame.delta_add(false)

        @sprites[key].opacity -= 24.delta_sub(false)
        @sprites[key].zoom_x  -= 0.035.delta_sub(false)
        @sprites[key].zoom_y  -= 0.035.delta_sub(false)
        @sprites[key].color    = @color
      end
    end
    #-------------------------------------------------------------------------
    #  set sprite particle visibility
    #-------------------------------------------------------------------------
    def visible=(val)
      @sprites.keys.each do |key|
        @sprites[key].visible = val
      end
    end
    #-------------------------------------------------------------------------
    #  dispose all sprite particles
    #-------------------------------------------------------------------------
    def dispose
      @sprites.keys.each do |key|
        @sprites[key].dispose
      end

      @sprites.clear
    end
    #-------------------------------------------------------------------------
    #  check if sprites are disposed
    #-------------------------------------------------------------------------
    def disposed?
      @sprites.keys.empty?
    end

    private
    #-------------------------------------------------------------------------
    #  reset active sprite particle
    #-------------------------------------------------------------------------
    def reset_particle
      @sprites[@i] = Base.new(@viewport)
      @sprites[@i].bitmap = @bmp
      @sprites[@i].center
      @sprites[@i].x = x
      @sprites[@i].y = y
      @sprites[@i].z = z
      @sprites[@i].zoom_x = @zoom_x
      @sprites[@i].zoom_y = @zoom_y
      @sprites[@i].opacity = @opacity
      @i += 1
      @frame = 0
    end
    #-------------------------------------------------------------------------
  end
end
