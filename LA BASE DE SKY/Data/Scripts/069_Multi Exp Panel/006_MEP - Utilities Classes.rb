#===============================================================================
# CREDITOS
# Swdfm
#===============================================================================
def pbPackageBitmap(bmp)
  bmp = [bmp] unless bmp.is_a?(Array)
  return AnimatedBitmap_Swdfm_Layer.new(bmp)
end

class AnimatedBitmap_Swdfm_Layer < AnimatedBitmap
  def initialize(bmps)
    bmps = [bmps] unless bmps.is_a?(Array)
    @bitmap = PngAnimatedBitmap_Layer.new(bmps)
  end
end

class PngAnimatedBitmap_Layer < PngAnimatedBitmap
  def initialize(bmps)
    @frames       = bmps
    @currentFrame = 0
    @framecount   = 0
    @frameDelay   = 10
  end
end

class IconSprite < Sprite
  def setBitmap_Swdfm(layer)
    oldrc = self.src_rect
    clearBitmaps
    @_iconbitmap  = layer
    self.bitmap   = @_iconbitmap ? @_iconbitmap.bitmap : nil
    self.src_rect = oldrc
  end
end
