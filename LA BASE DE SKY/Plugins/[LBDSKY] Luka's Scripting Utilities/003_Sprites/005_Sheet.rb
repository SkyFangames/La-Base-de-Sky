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

#===============================================================================
#  Class used to render animated sprite from spritesheet (horizontal)
#===============================================================================
class SpriteSheet < Sprite
  attr_accessor :speed
  #-----------------------------------------------------------------------------
  #  initializes sprite sheet
  #-----------------------------------------------------------------------------
  def initialize(viewport, frames = 1)
    @frames = frames
    @speed = 1
    @curFrame = 0
    @vertical = false
    super(viewport)
  end
  #-----------------------------------------------------------------------------
  #  sets sheet bitmap
  #-----------------------------------------------------------------------------
  def setBitmap(file, vertical = false)
    self.bitmap = file.is_a?(Bitmap) ? file : pbBitmap(file)
    @vertical = vertical
    if @vertical
      self.src_rect.height /= @frames
    else
      self.src_rect.width /= @frames
    end
  end
  #-----------------------------------------------------------------------------
  #  updates sheet
  #-----------------------------------------------------------------------------
  def update
    return if !self.bitmap
    if @curFrame >= @speed.delta_add(false)
      if @vertical
        self.src_rect.y += self.src_rect.height
        self.src_rect.y = 0 if self.src_rect.y >= self.bitmap.height
      else
        self.src_rect.x += self.src_rect.width
        self.src_rect.x = 0 if self.src_rect.x >= self.bitmap.width
      end
      @curFrame = 0
    end
    @curFrame += 1
  end
  #-----------------------------------------------------------------------------
end
#===============================================================================
#  Class used for selector sprite
#===============================================================================
class SelectorSprite < SpriteSheet
  attr_accessor :filename, :anchor
  #-----------------------------------------------------------------------------
  #  sets sheet bitmap
  #-----------------------------------------------------------------------------
  def render(rect, file = nil, vertical = false)
    @filename = file if @filename.nil? && !file.nil?
    file = @filename if file.nil? && !@filename.nil?
    @curFrame = 0
    self.src_rect.x = 0
    self.src_rect.y = 0
    self.setBitmap(pbSelBitmap(@filename, rect), vertical)
    self.center!
    self.speed = 4
  end
  #-----------------------------------------------------------------------------
  #  target sprite with selector
  #-----------------------------------------------------------------------------
  def target(sprite)
    return if !sprite || !sprite.is_a?(Sprite)
    self.render(Rect.new(0, 0, sprite.width, sprite.height))
    self.anchor = sprite
  end
  #-----------------------------------------------------------------------------
  #  update sprite
  #-----------------------------------------------------------------------------
  def update
    super
    if self.anchor
      self.x = self.anchor.x - self.anchor.ox + self.anchor.width/2
      self.y = self.anchor.y - self.anchor.oy + self.anchor.height/2
      self.opacity = self.anchor.opacity
      self.visible = self.anchor.visible
    end
  end
  #-----------------------------------------------------------------------------
end