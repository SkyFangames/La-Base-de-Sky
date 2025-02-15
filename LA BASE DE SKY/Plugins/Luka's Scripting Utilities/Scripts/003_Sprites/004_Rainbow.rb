#===============================================================================
#  Class used to render a hue changing sprite
#===============================================================================
module Sprites
  class Rainbow < Base
    #-------------------------------------------------------------------------
    attr_accessor :speed
    #-------------------------------------------------------------------------
    #  set sprite bitmap
    #-------------------------------------------------------------------------
    def set_bitmap(bmp, speed: 1)
      @stored_bitmap = SpriteHash.bitmap(bmp)
      @speed         = speed
      @current_hue   = 0

      self.bitmap = ::Bitmap.new(@stored_bitmap.width, @stored_bitmap.height)
      bitmap.blt(0, 0, @stored_bitmap, @stored_bitmap.rect)
    end
    #-------------------------------------------------------------------------
    #  update sprite animation
    #-------------------------------------------------------------------------
    def update
      @current_hue += @speed.lerp
      @current_hue  = 0 if @current_hue >= 360

      bitmap.clear
      bitmap.blt(0, 0, @stored_bitmap, @stored_bitmap.rect)
      bitmap.hue_change(@current_hue)
    end
    #-------------------------------------------------------------------------
  end
end
