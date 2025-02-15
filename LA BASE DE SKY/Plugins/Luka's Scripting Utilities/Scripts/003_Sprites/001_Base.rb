#===============================================================================
#  Base sprite class for LUTS
#===============================================================================
module Sprites
  class Base < ::FloatSprite
    include LUTS::Concerns::Animatable
    #-------------------------------------------------------------------------
    attr_reader   :stored_bitmap
    attr_accessor :direction, :speed, :toggle, :end_x, :end_y, :param, :skew_d
    attr_accessor :ex, :ey, :zx, :zy, :dx, :dy, :finished
    #-------------------------------------------------------------------------
    #  class constructor
    #-------------------------------------------------------------------------
    def initialize(viewport)
      super(viewport)

      default!
    end
    #-------------------------------------------------------------------------
    #  default additional attribute values
    #-------------------------------------------------------------------------
    def default!
      @speed     = 1
      @toggle    = 1
      @end_x     = 0
      @end_y     = 0
      @ex        = 0
      @ey        = 0
      @zx        = 1
      @zy        = 1
      @param     = 1
      @direction = 1
      @float_x   = 0.0
      @float_y   = 0.0
    end
    #-------------------------------------------------------------------------
    #  set sprite bitmap
    #-------------------------------------------------------------------------
    def set_bitmap(bmp)
      self.bitmap = SpriteHash.bitmap(bmp)
    end
    #-------------------------------------------------------------------------
    #  set color rect as sprite bitmap
    #-------------------------------------------------------------------------
    def create_rect(width, height, color)
      self.bitmap = Bitmap.new(width, height).fill_rect(0, 0, width, height, color)
    end
    #-------------------------------------------------------------------------
    #  set sprite bitmap to fill entire screen with color
    #-------------------------------------------------------------------------
    def full_rect(color)
      bmp = bitmap || blank_screen
      bmp.fill_rect(0, 0, bmp.width, bmp.height, color)
    end
    #-------------------------------------------------------------------------
    #  get zoom value
    #-------------------------------------------------------------------------
    def zoom
      zoom_x
    end
    #-------------------------------------------------------------------------
    #  set both zoom values
    #-------------------------------------------------------------------------
    def zoom=(val)
      self.zoom_x = val
      self.zoom_y = val
    end
    #-------------------------------------------------------------------------
    #  get sprite center
    #-------------------------------------------------------------------------
    def center
      [width / 2, height / 2]
    end
    #-------------------------------------------------------------------------
    #  set sprite center
    #-------------------------------------------------------------------------
    def center!(snap: false)
      anchor(:middle)
      # aligns with the center of the sprite's viewport
      return unless snap && viewport

      self.x = viewport.rect.width / 2
      self.y = viewport.rect.height / 2
    end
    #-------------------------------------------------------------------------
    #  get sprite bottom center anchor
    #-------------------------------------------------------------------------
    def bottom
      [width / 2, height]
    end
    #-------------------------------------------------------------------------
    #  set sprite bottom center anchor
    #-------------------------------------------------------------------------
    def bottom!
      anchor(:bottom_middle)
    end
    #-------------------------------------------------------------------------
    #  set sprite anchor
    #-------------------------------------------------------------------------
    def anchor(type)
      case type
      when :bottom_left
        self.ox = 0
        self.oy = height
      when :bottom_middle
        self.ox = width / 2
        self.oy = height
      when :bottom_right
        self.ox = width
        self.oy = height
      when :middle_left
        self.ox = 0
        self.oy = height / 2
      when :middle
        self.ox = width / 2
        self.oy = height / 2
      when :middle_right
        self.ox = width
        self.oy = height / 2
      when :top_left
        self.ox = 0
        self.oy = 0
      when :top_middle
        self.ox = width / 2
        self.oy = 0
      when :top_right
        self.ox = width
        self.oy = 0
      end
    end
    #-------------------------------------------------------------------------
    #  sprite rect components
    #-------------------------------------------------------------------------
    def width;        src_rect.width;        end
    def width=(val);  src_rect.width = val;  end
    def height;       src_rect.height;       end
    def height=(val); src_rect.height = val; end
    def rect_x;       src_rect.x;            end
    def rect_x=(val); src_rect.x = val;      end
    def rect_y;       src_rect.y;            end
    def rect_y=(val); src_rect.y = val;      end
    #-------------------------------------------------------------------------
    #  take screenshot and set as sprite bitmap
    #-------------------------------------------------------------------------
    def snap_screen
      bmp = Graphics.snap_to_bitmap
      self.bitmap = Bitmap.new(viewport.width, viewport.height)
      self.bitmap.blt(0, 0, bmp, Rect.new(viewport.x, viewport.y, viewport.width, viewport.height))
    end
    #-------------------------------------------------------------------------
    #  draw bitmap stretched across entire screen
    #-------------------------------------------------------------------------
    def stretch_screen(path)
      bmp = Sprites.bitmap(path)

      self.bitmap = Bitmap.new(viewport.width, viewport.height)
      bitmap.stretch_blt(bitmap.rect, bmp, bmp.rect)
      bmp.dispose
    end
    #-------------------------------------------------------------------------
    #  skew sprite based on angle
    #-------------------------------------------------------------------------
    def skew(angle: 90)
      return unless bitmap && angle != skew_d

      piangle = angle * (::Math::PI / 180)
      bmp     = stored_bitmap || bitmap
      width   = bmp.width
      width  += ((bmp.height - 1) / ::Math.tan(piangle)).abs unless angle.eql?(90)
      self.bitmap = ::Bitmap.new(width, bmp.height)

      bmp.height.times do |i|
        y = bmp.height - i
        x = angle.eql?(90) ? 0 : i / ::Math.tan(piangle)
        bitmap.blt(x, y, bmp, ::Rect.new(0, y, bmp.width, 1))
      end
      @calc_mid_x = angle <= 90 ? bmp.width / 2 : (bitmap.width - bitmap.width / 2)
      self.skew_d = angle
    end
    #-------------------------------------------------------------------------
    #  get sprite X midpoint
    #-------------------------------------------------------------------------
    def x_mid
      return @calc_mid_x if @calc_mid_x

      bitmap ? bitmap.width / 2 : ox
    end
    #-------------------------------------------------------------------------
    #  apply blur to sprite
    #-------------------------------------------------------------------------
    def blur
      bitmap.blur
    end
    #-------------------------------------------------------------------------
    #  get average sprite color
    #-------------------------------------------------------------------------
    def avg_color(freq: 2)
      return Color.new(0, 0, 0, 0) unless bitmap

      width  = bitmap.width / freq
      height = bitmap.height / freq
      red    = 0
      green  = 0
      blue   = 0

      n = width * height
      width.times do |x|
        height.times do |y|
          color = bitmap.get_pixel(x * freq, y * freq)
          next unless color.alpha > 0

          red   += color.red
          green += color.green
          blue  += color.blue
        end
      end

      Color.new(red / n, green / n, blue / n)
    end
    #-------------------------------------------------------------------------
    #  draw outline for sprite
    #-------------------------------------------------------------------------
    def outline(color)
      return unless bitmap

      # creates temp outline bmp
      out = Bitmap.new(bitmap.width, bitmap.height)
      5.times do |i| # corners
        x = (i / 2).zero? ? -r : r
        y = i.even? ? -r : r
        out.blt(x, y, bitmap, bitmap.rect)
      end

      5.times do |i| # edges
        x = i < 2 ? 0 : (i.even? ? -r : r)
        y = i >= 2 ? 0 : (i.even? ? -r : r)
        out.blt(x, y, bitmap, bitmap.rect)
      end
      # analyzes the pixel contents of both bitmaps
      # iterates through each X coordinate
      bitmap.width.times do |x|
        # iterates through each Y coordinate
        bitmap.height.times do |y|
          c1 = bitmap.get_pixel(x, y) # target bitmap
          c2 = out.get_pixel(x, y) # outline fill
          # compares the pixel values of the original bitmap and outline bitmap
          bitmap.set_pixel(x, y, color) if c1.alpha <= 0 && c2.alpha > 0
        end
      end
      # disposes temp outline bitmap
      out.dispose
    end
    #-------------------------------------------------------------------------
    #  apply color to solid pixels of sprite
    #-------------------------------------------------------------------------
    def colorize(color, amount: 255)
      return unless bitmap

      alpha = amount / 255.0
      # iterates through each X coordinate
      bitmap.width.times do |x|
        # iterates through each Y coordinate
        bitmap.height.times do |y|
          pixel = bitmap.get_pixel(x, y)
          next unless pixel.alpha > 0

          r = alpha * color.red + (1 - alpha) * pixel.red
          g = alpha * color.green + (1 - alpha) * pixel.green
          b = alpha * color.blue + (1 - alpha) * pixel.blue

          bitmap.set_pixel(x, y, Color.new(r, g, b))
        end
      end
    end
    #-------------------------------------------------------------------------
    #  turn sprite into a glow
    #-------------------------------------------------------------------------
    def glow(color, keep: true)
      return unless bitmap

      src = bitmap.clone.blur
      bitmap.clear
      bitmap.stretch_blt(Rect.new(-0.005 * src.width, -0.015 * src.height, src.width * 1.01, 1.02 * src.height), src, Rect.new(0, 0, src.width, src.height))
      bitmap.blt(0, 0, temp_bmp, Rect.new(0, 0, temp_bmp.width, temp_bmp.height)) if keep

      self.color = color
      src.dispose
    end
    #-------------------------------------------------------------------------
    #  memorize current bitmap
    #-------------------------------------------------------------------------
    def memorize_bitmap(bmp = nil)
      @stored_bitmap = (bmp || bitmap)&.clone
    end
    #-------------------------------------------------------------------------
    #  restore memorized bitmap
    #-------------------------------------------------------------------------
    def restore_bitmap
      self.bitmap = @stored_bitmap.clone
    end
    #-------------------------------------------------------------------------
    #  apply bitmap from URL source
    #-------------------------------------------------------------------------
    def online_bitmap(url)
      self.bitmap = Sprites.online_bitmap(url)
    end
    #-------------------------------------------------------------------------
    #  mask bitmap with another bitmap
    #-------------------------------------------------------------------------
    def mask(mask = nil, ox: 0, oy: 0)
      return unless bitmap

      self.bitmap = bitmap.mask(mask, ox, oy)
    end
    #-------------------------------------------------------------------------
    #  generate blank bitmap to fill viewport
    #-------------------------------------------------------------------------
    def blank_screen
      self.bitmap = Bitmap.new(viewport.width, viewport.height)
    end
    #-------------------------------------------------------------------------
    #  swap bitmap colors
    #-------------------------------------------------------------------------
    def swap_colors(map)
      bitmap.swap_colors(map) if bitmap
    end
    #-------------------------------------------------------------------------
  end
end

class AnimatedPlane < Plane
  attr_accessor :end_x, :end_y
end
