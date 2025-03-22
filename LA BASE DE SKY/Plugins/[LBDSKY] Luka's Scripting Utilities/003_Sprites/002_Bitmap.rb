#===============================================================================
#  Extensions for the `Bitmap` class
#===============================================================================
module Sprites
  class Bitmap < ::Bitmap
    #-------------------------------------------------------------------------
    attr_accessor :path

    def initialize(*args)
      @path = args.first if args.first.is_a?(String)

      super(*args)
    end
    #-------------------------------------------------------------------------
    #  draws circle on bitmap
    #-------------------------------------------------------------------------
    def draw_circle(color, radius:, hollow: false)
      # basic circle formula
      # (x - center_x)**2 + (y - center_y)**2 = r**2
      width.times do |x|
        f = (radius**2 - (x - width / 2)**2)
        next if f < 0

        y1 = -Math.sqrt(f).to_i + height / 2
        y2 = Math.sqrt(f).to_i + height / 2

        if hollow
          set_pixel(x, y1, color)
          set_pixel(x, y2, color)
        else
          fill_rect(x, y1, 1, y2 - y1, color)
        end
      end
    end
    #-------------------------------------------------------------------------
    #  sets font parameters
    #-------------------------------------------------------------------------
    def set_font(name:, size:, bold: false)
      font.name = name
      font.size = size
      font.bold = bold
    end
    #-------------------------------------------------------------------------
    #  applies mask on bitmap
    #-------------------------------------------------------------------------
    def mask!(mask = nil, offset_x: 0, offset_y: 0)
      bitmap = clone
      if mask.is_a?(Bitmap)
        mbmp = mask
      elsif mask.is_a?(Sprite)
        mbmp = mask.bitmap
      elsif mask.is_a?(String)
        mbmp = Sprites.bitmap(mask)
      else
        return false
      end

      cbmp = Bitmap.new(mbmp.width, mbmp.height)
      mask = mbmp.clone
      ox = (bitmap.width - mbmp.width) / 2
      oy = (bitmap.height - mbmp.height) / 2
      width = mbmp.width + ox
      height = mbmp.height + oy

      (oy...height).each do |y|
        (ox...width).each do |x|
          pixel = mask.get_pixel(x - ox, y - oy)
          color = bitmap.get_pixel(x - offset_x, y - offset_y)
          alpha = pixel.alpha
          alpha = color.alpha if color.alpha < pixel.alpha

          cbmp.set_pixel(x - ox, y - oy, Color.new(color.red, color.green, color.blue, alpha))
        end
      end

      mask.dispose
      cbmp
    end
    #-------------------------------------------------------------------------
    #  swap out specified colors (resource intensive, best not use on large sprites)
    #-------------------------------------------------------------------------
    def swap_colors(bmp)
      map = {}.tap do |map_hash|
        bmp.width.times do |x|
          start = bmp.get_pixel(x, 0)
          final = bmp.get_pixel(x, 1)

          map_hash[[start.red, start.green, start.blue]] = [final.red, final.green, final.blue]
        end
      end
      # failsafe
      return unless map.is_a?(Hash)

      # iterate over sprite's pixels
      width.times do |x|
        height.times do |y|
          pixel = get_pixel(x, y)
          next if pixel.alpha == 0

          final = nil
          map.keys.each do |key|
            # check for key mapping
            target = Color.new(*key)
            final  = Color.new(*map[key]) if tolerance?(pixel, target)
          end
          # swap current pixel color with target
          set_pixel(x, y, final) if final && final.is_a?(Color)
        end
      end
    end

    def tolerance?(pixel, target)
      tol = 0.05

      return false unless pixel.red.between?(target.red - target.red * tol, target.red + target.red * tol)
      return false unless pixel.green.between?(target.green - target.green * tol, target.green + target.green * tol)
      return false unless pixel.blue.between?(target.blue - target.blue * tol, target.blue + target.blue * tol)

      true
    end
    #-------------------------------------------------------------------------
  end
end

#===============================================================================
#  Safe bitmap loading method
#===============================================================================
def pbBitmap(name)
  begin
    dir = name.split("/")[0...-1].join("/") + "/"
    file = name.split("/")[-1]
    bmp = RPG::Cache.load_bitmap(dir, file)
    bmp.storedPath = name
  rescue
    Env.log.warn("Image located at '#{name}' was not found!")
    bmp = Bitmap.new(2,2)
  end
  return bmp
end
#===============================================================================
#  Renders bitmap spritesheet for selection cursor
#===============================================================================
def pbSelBitmap(name, rect)
  bmp = pbBitmap(name)
  qw = bmp.width/2
  qh = bmp.height/2
  max_w = rect.width + qw*2 - 8
  max_h = rect.height + qh*2 - 8
  full = Bitmap.new(max_w*4,max_h)
  # draws 4 frames where corners of selection get closer to bounding rect
  for i in 0...4
    for j in 0...4
      m = (i < 3) ? i : (i-2)
      x = (j%2 == 0 ? 2 : -2)*m + max_w*i + (j%2 == 0 ? 0 : max_w-qw)
      y = (j/2 == 0 ? 2 : -2)*m + (j/2 == 0 ? 0 : max_h-qh)
      full.blt(x,y,bmp,Rect.new(qw*(j%2),qh*(j/2),qw,qh))
    end
  end
  return full
end

class Bitmap
  attr_accessor :storedPath
  #-----------------------------------------------------------------------------
  #  draws circle on bitmap
  #-----------------------------------------------------------------------------
  def bmp_circle(color = Color.new(255,255,255), r = (self.width/2), tx = (self.width/2), ty = (self.height/2), hollow = false)
    # basic circle formula
    # (x - tx)**2 + (y - ty)**2 = r**2
    for x in 0...self.width
      f = (r**2 - (x - tx)**2)
      next if f < 0
      y1 = -Math.sqrt(f).to_i + ty
      y2 =  Math.sqrt(f).to_i + ty
      if hollow
        self.set_pixel(x, y1, color)
        self.set_pixel(x, y2, color)
      else
        self.fill_rect(x, y1, 1, y2 - y1, color)
      end
    end
  end
  def draw_circle(*args); self.bmp_circle(*args); end
  #-----------------------------------------------------------------------------
  #  sets font parameters
  #-----------------------------------------------------------------------------
  def set_font(name, size, bold = false)
    self.font.name = name
    self.font.size = size
    self.font.bold = bold
  end
  #-----------------------------------------------------------------------------
  #  applies mask on bitmap
  #-----------------------------------------------------------------------------
  def mask!(mask = nil, xpush = 0, ypush = 0) # Draw sprite on a sprite/bitmap
    bitmap = self.clone
    if mask.is_a?(Bitmap)
      mbmp = mask
    elsif mask.is_a?(Sprite)
      mbmp = mask.bitmap
    elsif mask.is_a?(String)
      mbmp = pbBitmap(mask)
    else
      return false
    end
    cbmp = Bitmap.new(mbmp.width, mbmp.height)
    mask = mbmp.clone
    ox = (bitmap.width - mbmp.width) / 2
    oy = (bitmap.height - mbmp.height) / 2
    width = mbmp.width + ox
    height = mbmp.height + oy
    for y in oy...height
      for x in ox...width
        pixel = mask.get_pixel(x - ox, y - oy)
        color = bitmap.get_pixel(x - xpush, y - ypush)
        alpha = pixel.alpha
        alpha = color.alpha if color.alpha < pixel.alpha
        cbmp.set_pixel(x - ox, y - oy, Color.new(color.red, color.green,
            color.blue, alpha))
      end
    end; mask.dispose
    return cbmp
  end
  #-----------------------------------------------------------------------------
  #  swap out specified colors (resource intensive, best not use on large sprites)
  #-----------------------------------------------------------------------------
  def swap_colors(map)
    # check for a potential bitmap map
    if map.is_a?(Bitmap)
      bmp = map.clone; map = {}
      for x in 0...bmp.width
        map[bmp.get_pixel(x, 0).to_hex] = bmp.get_pixel(x, 1).to_hex
      end
    end
    # failsafe
    return if !map.is_a?(Hash)
    # iterate over sprite's pixels
    for x in 0...self.width
      for y in 0...self.height
        pixel = self.get_pixel(x, y)
        final = nil
        for key in map.keys
          # check for key mapping
          target = Color.parse(key)
          final = Color.parse(map[key]) if target == pixel
        end
        # swap current pixel color with target
        self.set_pixel(x, y, final) if final && final.is_a?(Color)
      end
    end
  end
  #-----------------------------------------------------------------------------
  #  Function that returns a fully rendered window bitmap from a skin
  #-----------------------------------------------------------------------------
  # `slice` is of a `Rect.new` type, and is used to cut the windowskin into 9 parts
  # `rect` is of a `Rect.new` type, and is used to define the dimensions of the rendered window
  # `path` is a string pointing to the actual windowskin graphic
  def self.smartWindow(slice, rect, path = "img/window001.png")
    window = Bitmap.new(path)
    output = Bitmap.new(rect.width, rect.height)
    # coordinates for the 9-slice sprite (slice)
    x1 = [0, slice.x, slice.x + slice.width]
    y1 = [0, slice.y, slice.y + slice.height]
    w1 = [slice.x, slice.width, window.width - slice.x - slice.width]
    h1 = [slice.y, slice.height, window.height - slice.y - slice.height]
    # coordinates for the 9-slice sprite (rect)
    x2 = [0, x1[1], rect.width - w1[2]]
    y2 = [0, y1[1], rect.height - h1[2]]
    w2 = [x1[1], rect.width - x1[1] - w1[2], w1[2]]
    h2 = [y1[1], rect.height - y1[1] - h1[2], h1[2]]
    # creates a 9-point matrix to slice up the window skin
    slice_matrix = []
    rect_matrix = []
    for y in 0...3
      for x in 0...3
        # matrix that handles cutting of the original window skin
        slice_matrix.push(Rect.new(x1[x], y1[y], w1[x], h1[y]))
        # matrix that handles generating of the entire window
        rect_matrix.push(Rect.new(x2[x], y2[y], w2[x], h2[y]))
      end
    end
    # fills window skin
    for i in 0...9
      output.stretch_blt(rect_matrix[i], window, slice_matrix[i])
    end
    window.dispose
    # returns the newly formed window
    return output
  end
  #-----------------------------------------------------------------------------
  #  downloads a bitmap and returns it
  #-----------------------------------------------------------------------------
  def self.online_bitmap(url)
    fname = url.split("/")[-1]
    pbDownloadToFile(url, fname)
    return nil if !safeExists?(fname)
    bmp = pbBitmap(fname)
    File.delete(fname)
    return bmp
  end
  #-----------------------------------------------------------------------------
end