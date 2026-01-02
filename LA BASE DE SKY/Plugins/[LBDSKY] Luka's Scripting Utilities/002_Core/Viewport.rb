#===============================================================================
#  Luka's Scripting Utilities
#
#  Core extensions for the `Viewport` class
#===============================================================================
class ::Viewport
  # Allows viewport components to be animated easily
  include LUTS::Concerns::Animatable
  # Allows viewport components to take blocks during instanciation
  include LUTS::Concerns::BlockConstructor
  # Allows viewport components to use float values for smooth calculations
  include LUTS::Concerns::Floatable

  # @return [Symbol]
  attr_accessor :tag

  # @param tag [Symbol]
  # @return [Array<Viewport>]
  def self.get_by_tag(tag)
    [].tap do |array|
      ObjectSpace.each_object(Viewport) do |viewport|
        array << viewport if viewport.tag.eql?(tag)
      end
    end
  end

  # @return [Array<Sprite>] all sprites belonging to target viewport
  def sprites
    [].tap do |array|
      ObjectSpace.each_object(Sprite) do |sprite|
        next if sprite.disposed?

        array << sprite if sprite.viewport.eql?(self)
      end
    end
  end

  # Flattens sprites in viewport into a single bitmap
  # @return [Bitmap]
  def flatten
    bmp = Bitmap.new(width, height)
    sprites.sort { |a, b| [a.z, a.__id__] <=> [b.z, b.__id__] }.each do |sprite|
      next unless sprite.bitmap
      next unless sprite.visible

      rect = Rect.new(sprite.apparent_x, sprite.apparent_y, sprite.apparent_width, sprite.apparent_height)
      bmp.stretch_blt(rect, sprite.bitmap, sprite.src_rect, sprite.opacity)
    end

    bmp
  end

  # Removes any applied color
  def reset_color
    self.color = Color.blank
  end

  # @return [Integer]
  def width
    rect.width
  end

  # @param val [Integer]
  def width=(val)
    rect.width = val
  end

  # @return [Integer]
  def height
    rect.height
  end

  # @param val [Integer]
  def height=(val)
    rect.height = val
  end

  # @return [Integer]
  def x
    rect.x
  end

  # @param val [Integer]
  def x=(val)
    rect.x = val
  end

  # @return [Integer]
  def y
    rect.y
  end

  # @param val [Integer]
  def y=(val)
    rect.y = val
  end

  # @return [Integer] color alpha value
  def alpha
    color.alpha
  end

  # @param val [Integer]
  def alpha=(val)
    color.alpha = val
  end
end
