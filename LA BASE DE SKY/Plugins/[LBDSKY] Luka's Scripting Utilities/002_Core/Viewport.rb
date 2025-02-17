#===============================================================================
#  Extensions for the `Viewport` class
#===============================================================================
class ::Viewport
  include LUTS::Concerns::Animatable
  #-----------------------------------------------------------------------------
  #  returns an array of all sprites belonging to target viewport
  #-----------------------------------------------------------------------------
  def sprites
    [].tap do |array|
      ObjectSpace.each_object(Sprite) do |sprite|
        next if sprite.disposed?

        array << sprite if sprite.viewport.eql?(self)
      end
    end
  end
  #-----------------------------------------------------------------------------
  #  flattens sprites in viewport into a single bitmap
  #-----------------------------------------------------------------------------
  def flatten(large: false)
    bmp = Bitmap.new(width + (large ? width : 0), height + (large ? height : 0))
    sprites.sort { |a, b| [a.z, a.__id__] <=> [b.z, b.__id__] }.each do |sprite|
      next unless sprite.bitmap
      next unless sprite.visible
      next unless sprite.in_viewport?(large: large)

      x = large ? sprite.apparent_x + width / 2 : sprite.apparent_x
      y = large ? sprite.apparent_y + height / 2 : sprite.apparent_y
      rect = Rect.new(x, y, sprite.apparent_width, sprite.apparent_height)
      bmp.stretch_blt(rect, sprite.bitmap, sprite.src_rect, sprite.opacity)
    end
    return bmp
  end
  #-----------------------------------------------------------------------------
  #  removes any applied color
  #-----------------------------------------------------------------------------
  def reset_color
    color = Color.new(0, 0, 0, 0)
  end
  #-----------------------------------------------------------------------------
  #  returns the viewport metrics
  #-----------------------------------------------------------------------------
  def width
    rect.width
  end

  def height
    rect.height
  end

  def x
    rect.x
  end

  def y
    rect.y
  end

  def alpha
    color.alpha
  end

  def alpha=(val)
    color.alpha = val
  end
  #-----------------------------------------------------------------------------
end
