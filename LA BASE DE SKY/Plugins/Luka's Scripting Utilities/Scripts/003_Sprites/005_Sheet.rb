#===============================================================================
#  Class used to render animated sprite from spritesheet (horizontal)
#===============================================================================
module Sprites
  class Sheet < Base
    #-------------------------------------------------------------------------
    attr_reader   :cur_frame
    attr_accessor :speed
    #-------------------------------------------------------------------------
    #  class constructor
    #-------------------------------------------------------------------------
    def initialize(viewport)
      super(viewport)

      @frames    = 1
      @speed     = 1
      @cur_frame = 0
      @vertical  = false
    end
    #-------------------------------------------------------------------------
    #  set sprite bitmap
    #-------------------------------------------------------------------------
    def set_bitmap(file, frames: 1, vertical: false, speed: @speed)
      @speed    = speed
      @frames   = frames
      @vertical = vertical

      self.bitmap = SpriteHash.bitmap(file)

      if @vertical
        src_rect.height /= @frames
      else
        src_rect.width /= @frames
      end
    end
    #-------------------------------------------------------------------------
    #  update sprite animation
    #-------------------------------------------------------------------------
    def update
      return unless bitmap

      if @cur_frame.lerp >= @speed
        if @vertical
          src_rect.y += src_rect.height
          src_rect.y = 0 if src_rect.y >= bitmap.height
        else
          src_rect.x += src_rect.width
          src_rect.x = 0 if src_rect.x >= bitmap.width
        end
        @cur_frame = 0
      end
      @cur_frame += 1
    end
    #-------------------------------------------------------------------------
  end
end
