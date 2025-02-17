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



#===============================================================================
#  Extensions for the `Sprite` class
#===============================================================================
class Sprite
  # additional sprite attributes
  attr_reader :storedBitmap
  attr_accessor :direction
  attr_accessor :speed
  attr_accessor :toggle
  attr_accessor :end_x, :end_y
  attr_accessor :param, :skew_d
  attr_accessor :ex, :ey
  attr_accessor :zx, :zy
  #-----------------------------------------------------------------------------
  #  MTS compatibility layer
  #-----------------------------------------------------------------------------
  def id?(val); return nil; end
  #-----------------------------------------------------------------------------
  #  draws rect bitmap
  #-----------------------------------------------------------------------------
  def create_rect(width, height, color)
    self.bitmap = Bitmap.new(width,height)
    self.bitmap.fill_rect(0,0,width,height,color)
  end
  def full_rect(color)
    self.blank_screen if !self.bitmap
    self.bitmap.fill_rect(0, 0, self.bitmap.width, self.bitmap.height, color)
  end
  #-----------------------------------------------------------------------------
  #  resets additional values
  #-----------------------------------------------------------------------------
  def default!
    @speed = 1; @toggle = 1; @end_x = 0; @end_y = 0
    @ex = 0; @ey = 0; @zx = 1; @zy = 1; @param = 1; @direction = 1
  end
  #-----------------------------------------------------------------------------
  #  gets zoom
  #-----------------------------------------------------------------------------
  def zoom
    return self.zoom_x
  end
  #-----------------------------------------------------------------------------
  #  sets all zoom values
  #-----------------------------------------------------------------------------
  def zoom=(val)
    self.zoom_x = val
    self.zoom_y = val
  end
  #-----------------------------------------------------------------------------
  #  centers sprite anchor
  #-----------------------------------------------------------------------------
  def center!(snap = false)
    self.ox = self.width/2
    self.oy = self.height/2
    # aligns with the center of the sprite's viewport
    if snap && self.viewport
      self.x = self.viewport.rect.width/2
      self.y = self.viewport.rect.height/2
    end
  end
  def center; return self.width/2, self.height/2; end
  #-----------------------------------------------------------------------------
  #  sets sprite anchor to bottom
  #-----------------------------------------------------------------------------
  def bottom!
    self.ox = self.width/2
    self.oy = self.height
  end
  def bottom; return self.width/2, self.height; end
  #-----------------------------------------------------------------------------
  #  applies screenshot as sprite bitmap
  #-----------------------------------------------------------------------------
  def snap_screen
    bmp = Graphics.snap_to_bitmap
    width = self.viewport ? viewport.rect.width : Graphics.width
    height = self.viewport ? viewport.rect.height : Graphics.height
    x = self.viewport ? viewport.rect.x : 0
    y = self.viewport ? viewport.rect.y : 0
    self.bitmap = Bitmap.new(width,height)
    self.bitmap.blt(0,0,bmp,Rect.new(x,y,width,height)); bmp.dispose
  end
  def screenshot; self.snap_screen; end
  #-----------------------------------------------------------------------------
  #  stretch the provided image across the whole viewport
  #-----------------------------------------------------------------------------
  def stretch_screen(file)
    bmp = pbBitmap(file)
    self.bitmap = Bitmap.new(self.viewport.width, self.viewport.height)
    self.bitmap.stretch_blt(self.bitmap.rect, bmp, bmp.rect)
  end
  #-----------------------------------------------------------------------------
  #  skews sprite's bitmap
  #-----------------------------------------------------------------------------
  def skew(angle = 90)
    return false if !self.bitmap
    return false if angle == self.skew_d
    piangle = angle*(Math::PI/180)
    bmp = self.storedBitmap ? self.storedBitmap : self.bitmap
    width = bmp.width
    width += ((bmp.height - 1)/Math.tan(piangle)).abs if angle != 90
    self.bitmap = Bitmap.new(width, bmp.height)
    for i in 0...bmp.height
      y = bmp.height - i
      x = (angle == 90) ? 0 : i/Math.tan(piangle)
      self.bitmap.blt(x, y, bmp, Rect.new(0, y, bmp.width, 1))
    end
    @calMidX = (angle <= 90) ? bmp.width/2 : (self.bitmap.width - bitmap.width/2)
    self.skew_d = angle
  end
  #-----------------------------------------------------------------------------
  #  gets the mid-point anchor of sprite
  #-----------------------------------------------------------------------------
  def x_mid
    return @calMidX if @calMidX
    return self.bitmap.width/2 if self.bitmap
    return self.ox
  end
  #-----------------------------------------------------------------------------
  #  blurs the contents of the sprite bitmap
  #-----------------------------------------------------------------------------
  def blur_sprite(blur_val = 2, opacity = 35)
    bitmap = self.bitmap
    self.bitmap = Bitmap.new(bitmap.width,bitmap.height)
    self.bitmap.blt(0,0,bitmap,Rect.new(0,0,bitmap.width,bitmap.height))
    x = 0; y = 0
    for i in 1...(8 * blur_val)
      dir = i % 8
      x += (1 + (i / 8))*([0,6,7].include?(dir) ? -1 : 1)*([1,5].include?(dir) ? 0 : 1)
      y += (1 + (i / 8))*([1,4,5,6].include?(dir) ? -1 : 1)*([3,7].include?(dir) ? 0 : 1)
      self.bitmap.blt(x-blur_val,y+(blur_val*2),bitmap,Rect.new(0,0,bitmap.width,bitmap.height),opacity)
    end
  end
  #-----------------------------------------------------------------------------
  #  gets average sprite color
  #-----------------------------------------------------------------------------
  def avg_color(freq = 2)
    return Color.new(0,0,0,0) if !self.bitmap
    bmp = self.bitmap
    width = self.bitmap.width/freq
    height = self.bitmap.height/freq
    red = 0; green = 0; blue = 0
    n = width*height
    for x in 0...width
      for y in 0...height
        color = bmp.get_pixel(x*freq,y*freq)
        if color.alpha > 0
          red += color.red
          green += color.green
          blue += color.blue
        end
      end
    end
    avg = Color.new(red/n,green/n,blue/n)
    return avg
  end
  #-----------------------------------------------------------------------------
  #  draws outline on bitmap
  #-----------------------------------------------------------------------------
  def create_outline(color, thickness = 2)
    return false if !self.bitmap
    # creates temp outline bmp
    out = Bitmap.new(self.bitmap.width, self.bitmap.height)
    for i in 0...4 # corners
      x = (i/2 == 0) ? -r : r
      y = (i%2 == 0) ? -r : r
      out.blt(x, y, self.bitmap, self.bitmap.rect)
    end
    for i in 0...4 # edges
      x = (i < 2) ? 0 : ((i%2 == 0) ? -r : r)
      y = (i >= 2) ? 0 : ((i%2 == 0) ? -r : r)
      out.blt(x, y, self.bitmap, self.bitmap.rect)
    end
    # analyzes the pixel contents of both bitmaps
    # iterates through each X coordinate
    for x in 0...self.bitmap.width
      # iterates through each Y coordinate
      for y in 0...self.bitmap.height
        c1 = self.bitmap.get_pixel(x,y) # target bitmap
        c2 = out.get_pixel(x,y) # outline fill
        # compares the pixel values of the original bitmap and outline bitmap
        self.bitmap.set_pixel(x, y, color) if c1.alpha <= 0 && c2.alpha > 0
      end
    end
    # disposes temp outline bitmap
    out.dispose
  end
  #-----------------------------------------------------------------------------
  #  applies hard-color onto bitmap pixels
  #-----------------------------------------------------------------------------
  def colorize(color, amt = 255)
    return false if !self.bitmap
    alpha = amt/255.0
    # clone current bitmap
    bmp = self.bitmap.clone
    # create new one in cache
    self.bitmap = Bitmap.new(bmp.width, bmp.height)
    # get pixels from bitmap
    pixels = bmp.raw_data.unpack('I*')
    for i in 0...pixels.length
      # get RGBA values from 24 bit INT
      b  =  pixels[i] & 255
      g  = (pixels[i] >> 8) & 255
      r  = (pixels[i] >> 16) & 255
      pa = (pixels[i] >> 24) & 255
      # proceed only if alpha > 0
      if pa > 0
        # calculate new RGB values
        r = alpha * color.red + (1 - alpha) * r
        g = alpha * color.green + (1 - alpha) * g
        b = alpha * color.blue + (1 - alpha) * b
        # convert RGBA to 24 bit INT
        pixels[i] = pa.to_i << 24 | b.to_i << 16 | g.to_i << 8 | r.to_i
      end
    end
    # pack data
    self.bitmap.raw_data = pixels.pack('I*')
  end
  #-----------------------------------------------------------------------------
  #  creates a glow around sprite
  #-----------------------------------------------------------------------------
  def glow(color, opacity = 35, keep = true)
    return false if !self.bitmap
    temp_bmp = self.bitmap.clone
    self.color = color
    self.blur_sprite(3,opacity)
    src = self.bitmap.clone
    self.bitmap.clear
    self.bitmap.stretch_blt(Rect.new(-0.005*src.width,-0.015*src.height,src.width*1.01,1.02*src.height),src,Rect.new(0,0,src.width,src.height))
    self.bitmap.blt(0,0,temp_bmp,Rect.new(0,0,temp_bmp.width,temp_bmp.height)) if keep
  end
  #-----------------------------------------------------------------------------
  #  fuzzes sprite outlines
  #-----------------------------------------------------------------------------
  def fuzz(color, opacity = 35)
    return false if !self.bitmap
    self.colorize(color)
    self.blur_sprite(3,opacity)
    src = self.bitmap.clone
    self.bitmap.clear
    self.bitmap.stretch_blt(Rect.new(-0.005*src.width,-0.015*src.height,src.width*1.01,1.02*src.height),src,Rect.new(0,0,src.width,src.height))
  end
  #-----------------------------------------------------------------------------
  #  caches current bitmap additionally
  #-----------------------------------------------------------------------------
  def memorize_bitmap(bitmap = nil)
    @storedBitmap = bitmap if !bitmap.nil?
    @storedBitmap = self.bitmap.clone if bitmap.nil?
  end
  #-----------------------------------------------------------------------------
  #  returns cached bitmap
  #-----------------------------------------------------------------------------
  def restore_bitmap
    self.bitmap = @storedBitmap.clone
  end
  #-----------------------------------------------------------------------------
  #  downloads a bitmap and applies it to sprite
  #-----------------------------------------------------------------------------
  def online_bitmap(url)
    bmp = Bitmap.online_bitmap(url)
    return if !bmp
    self.bitmap = bmp
  end
  #-----------------------------------------------------------------------------
  #  applies mask to bitmap
  #-----------------------------------------------------------------------------
  def mask(mask = nil, xpush = 0, ypush = 0) # Draw sprite on a sprite/bitmap
    return false if !self.bitmap
    self.bitmap = self.bitmap.mask(mask,xpush,ypush)
  end
  #-----------------------------------------------------------------------------
  #  creates a blank bitmap the size of the viewport
  #-----------------------------------------------------------------------------
  def blank_screen
    self.bitmap = Bitmap.new(self.viewport.width, self.viewport.height)
  end
  #-----------------------------------------------------------------------------
  #  swap out specified colors (resource intensive, best not use on large sprites)
  #-----------------------------------------------------------------------------
  def swap_colors(map)
    self.bitmap.swapColors(map) if self.bitmap
  end
  #-----------------------------------------------------------------------------
  #  swap out specified colors (resource intensive, best not use on large sprites)
  #-----------------------------------------------------------------------------
  def width
    return self.src_rect.width
  end
  #-----------------------------------------------------------------------------
  #  swap out specified colors (resource intensive, best not use on large sprites)
  #-----------------------------------------------------------------------------
  def height
    return self.src_rect.height
  end
  #-----------------------------------------------------------------------------
end

#===============================================================================
#  Extensions for the `Tone` class
#===============================================================================
class Tone
  #-----------------------------------------------------------------------------
  #  gets value of all
  #-----------------------------------------------------------------------------
  def all
    return (self.red + self.green + self.blue)/3
  end
  #-----------------------------------------------------------------------------
  #  applies value to all channels
  #-----------------------------------------------------------------------------
  def all=(val)
    self.red = val
    self.green = val
    self.blue = val
  end
  #-----------------------------------------------------------------------------
end

#===============================================================================
#  MTS utility
#===============================================================================
class PokemonSprite
  def id?(val); return nil; end
end
#===============================================================================
#  Mathematical functions
#===============================================================================
# generates a uniform polygon based on the number of points, radius (for x and y),
# angle and coordinates of its origin
def getPolygonPoints(n, rx = 50,ry=50,a=0,tx=Graphics.width/2,ty=Graphics.height/2)
  points = []
  ang = 360/n
  n.times do
    b = a*(Math::PI/180)
    r = rx*Math.cos(b).abs + ry*Math.sin(b).abs
    x = tx + r*Math.cos(b)
    y = ty - r*Math.sin(b)
    points.push([x,y])
    a += ang
  end
  return points
end
#-------------------------------------------------------------------------------
# Gets a random coordinate on a circumference
def randCircleCord(r, x = nil)
  x = rand(r*2) if x.nil?
  y1 = -Math.sqrt(r**2 - (x - r)**2)
  y2 =  Math.sqrt(r**2 - (x - r)**2)
  return x, (rand(2)==0 ? y1.to_i : y2.to_i) + r
end