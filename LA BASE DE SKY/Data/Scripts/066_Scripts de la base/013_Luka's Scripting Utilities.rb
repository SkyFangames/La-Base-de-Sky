#===============================================================================
#  Scripting Utilities
#    by Luka S.J.
# ----------------
#  Various utilities used within my plugins. Neat and nifty ways to speed
#  the coding process of certain scripts.
#===============================================================================
#  Extensions for `Numeric` data types
#===============================================================================
class ::Numeric
  #-----------------------------------------------------------------------------
  #  Delta offset for frame rates
  #-----------------------------------------------------------------------------
  def delta(type = :add, round = true)
    d = Graphics.frame_rate/40.0
    a = round ? (self*d).to_i : (self*d)
    s = round ? (self/d).floor : (self/d)
    return type == :add ? a : s
  end
  def delta_add(round = true)
    return self.delta(:add, round)
  end
  def delta_sub(round = true)
    return self.delta(:sub, round)
  end
  #-----------------------------------------------------------------------------
  #  Superior way to round stuff
  #-----------------------------------------------------------------------------
	alias quick_mafs round
	def round(n = 0)
		# gets the current float to an actually roundable integer
		t = self*(10.0**n)
		# returns the rounded value
		return t.quick_mafs/(10.0**n)
	end
end
#===============================================================================
#  Extensions for the `Dir` class
#===============================================================================
class Dir
  #-----------------------------------------------------------------------------
  #  Creates all the required directories for filename path
  #-----------------------------------------------------------------------------
  def self.create(path)
    path.gsub!("\\", "/") # Windows compatibility
    # get path tree
    dirs = path.split("/"); full = ""
    for dir in dirs
      full += dir + "/"
      # creates directories
      self.mkdir(full) if !self.safe?(full)
    end
  end
  #-----------------------------------------------------------------------------
  #  Generates entire file/folder tree from a certain directory
  #-----------------------------------------------------------------------------
  def self.all_dirs(dir)
    # sets variables for starting
    dirs = []
    for file in self.get(dir, "*", true)
      # engages in recursion to read the entire folder tree
      dirs += self.all_dirs(file) if self.safe?(file)
    end
    # returns all found directories
    return dirs.length > 0 ? (dirs + [dir]) : [dir]
  end
  #-----------------------------------------------------------------------------
  #  Deletes all the files in a directory and all the sub directories (allows for non-empty dirs)
  #-----------------------------------------------------------------------------
  def self.delete_all(dir)
    # delete all files in dir
    self.all(dir).each { |f| File.delete(f) }
    # delete all dirs in dir
    self.all_dirs(dir).each { |f| Dir.delete(f) }
  end
  #-----------------------------------------------------------------------------
end
#===============================================================================
#  Extensions for the `File` class
#===============================================================================
class File
  #-----------------------------------------------------------------------------
  #  Checks for existing .rxdata file
  #-----------------------------------------------------------------------------
  def self.safeData?(file)
    ret = false
    ret = (load_data(file) ? true : false) rescue false
    return ret
  end
  #-----------------------------------------------------------------------------
end
#===============================================================================
#  Extensions for the `PluginManager`
#===============================================================================
module PluginManager
  #-----------------------------------------------------------------------------
  #  Get plugin dir based on meta entries
  #-----------------------------------------------------------------------------
  def self.find_dir(plugin)
    # go through the plugins folder
    for dir in Dir.get("Plugins")
      next if !Dir.safe?(dir)
      next if !safeExists?(dir + "/meta.txt")
      # read meta
      meta = self.readMeta(dir, "meta.txt")
      return dir if meta[:name] == plugin
    end
    # return nil if no plugin dir found
    return nil
  end
  #-----------------------------------------------------------------------------
end
#===============================================================================
#  Extensions for the `String` data type
#===============================================================================
class ::String
  #-----------------------------------------------------------------------------
  #  get string bytes
  #-----------------------------------------------------------------------------
  def bytes
    byte = []
    self.each_byte {|b| byte.push(b) }
    return byte
  end
  #-----------------------------------------------------------------------------
  #  checks if string contains only numeric values
  #-----------------------------------------------------------------------------
  def is_numeric?
    for c in self.gsub('.', '').gsub('-', '').scan(/./)
      return false unless (0..9).to_a.map { |n| n.to_s }.include?(c)
    end
    return true
  end
  #-----------------------------------------------------------------------------
end
#===============================================================================
#  Extensions for the `Array` data types
#===============================================================================
class ::Array
  #-----------------------------------------------------------------------------
  #  swaps specific indexes
  #-----------------------------------------------------------------------------
  def swap_at(index1, index2)
    val1 = self[index1].clone
    val2 = self[index2].clone
    self[index1] = val2
    self[index2] = val1
  end
  #-----------------------------------------------------------------------------
  #  pushes value to last index
  #-----------------------------------------------------------------------------
  def to_last(val)
    self.delete(val) if self.include?(val)
    self.push(val)
  end
  #-----------------------------------------------------------------------------
  #  check if part of string matches
  #-----------------------------------------------------------------------------
  def string_include?(val)
    return false if !val.is_a?(String)
    ret = false
    for a in self
      ret = true if a.is_a?(String) && val.include?(a)
    end
    return ret
  end
  #-----------------------------------------------------------------------------
end
#===============================================================================
#  Extensions for the `Hash` data types
#===============================================================================
class ::Hash
  #-----------------------------------------------------------------------------
  #  checks if hash has key
  #-----------------------------------------------------------------------------
  def has_key?(*args)
    for key in args
      return false if !self.keys.include?(key)
    end
    return true
  end
  #-----------------------------------------------------------------------------
  #  checks if key has a value
  #-----------------------------------------------------------------------------
  def try_key?(*args)
    for key in args
      return false if !self.keys.include?(key) || !self[key]
    end
    return true
  end
  #-----------------------------------------------------------------------------
  #  gets value associated with key (safe method)
  #-----------------------------------------------------------------------------
  def get_key(key)
    return self.has_key?(key) ? self[key] : nil
  end
  #-----------------------------------------------------------------------------
  #  merges and replace current hash
  #-----------------------------------------------------------------------------
  def deep_merge!(hash)
    # failsafe
    return if !hash.is_a?(Hash)
    for key in hash.keys
      if self[key].is_a?(Hash)
        self[key].deep_merge!(hash[key])
      else
        self[key] = hash[key]
      end
    end
  end
  #-----------------------------------------------------------------------------
  #  merges two hashes
  #-----------------------------------------------------------------------------
  def deep_merge(hash)
    h = self.clone
    # failsafe
    return h if !hash.is_a?(Hash)
    for key in hash.keys
      if self[key].is_a?(Hash)
        h.deep_merge!(hash[key])
      else
        h = hash[key]
      end
    end
    return h
  end
  #-----------------------------------------------------------------------------
end
#===============================================================================
#  Extensions for the `Viewport` class
#===============================================================================
class Viewport
  #-----------------------------------------------------------------------------
  #  returns a hash of all sprites belonging to target viewport
  #-----------------------------------------------------------------------------
  def sprites
    hash = {}; i = 0
    ObjectSpace.each_object(Sprite) do |o|
      begin
        hash[i] = o if o.viewport && !o.viewport.nil? && o.viewport == self
        rescue RGSSError
      end
    end
    return hash
  end
  #-----------------------------------------------------------------------------
  #  gets width of viewport
  #-----------------------------------------------------------------------------
  def width
    return self.rect.width
  end
  #-----------------------------------------------------------------------------
  #  gets height of viewport
  #-----------------------------------------------------------------------------
  def height
    return self.rect.height
  end
  #-----------------------------------------------------------------------------
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
#  Extensions for the `Bitmap` class
#===============================================================================
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
#===============================================================================
#  Extensions for the `Color` class
#===============================================================================
class Color
	# alias for old constructor
	alias init_org initialize unless self.private_method_defined?(:init_org)
  #-----------------------------------------------------------------------------
	# new constructor accepts RGB values as well as a hex number or string value
  #-----------------------------------------------------------------------------
	def initialize(*args)
		Env.log.error("Wrong number of arguments! At least 1 is needed!") if args.length < 1
		if args.length == 1
			if args[0].is_a?(Fixnum)
				hex = args[0].dup.to_s(16)
			elsif args[0].is_a?(String)
        hex = args[0].dup
				hex.gsub!("#", "") if hex.include?("#")
			end
			Env.log.error("Wrong type of argument given!") if !hex
			r = hex[0...2].to_i(16)
			g = hex[2...4].to_i(16)
			b = hex[4...6].to_i(16)
		elsif args.length == 3
			r, g, b = *args
		end
		return init_org(r, g, b) if r && g && b
		return init_org(*args)
	end
  #-----------------------------------------------------------------------------
	# returns an RGB color value as a hex value
  #-----------------------------------------------------------------------------
	def to_hex
		r = sprintf("%02X", self.red)
		g = sprintf("%02X", self.green)
		b = sprintf("%02X", self.blue)
		return ("#" + r + g + b).upcase
	end
  #-----------------------------------------------------------------------------
	# returns Hex color value as RGB
  #-----------------------------------------------------------------------------
	def to_rgb(hex)
		hex = hex.to_s(16) if hex.is_a?(Numeric)
		r = hex[0...2].to_i(16)
		g = hex[2...4].to_i(16)
		b = hex[4...6].to_i(16)
		return r, g, b
	end
  #-----------------------------------------------------------------------------
	# returns decimal color
  #-----------------------------------------------------------------------------
	def to_dec
		return self.to_hex.gsub("#", "").to_i(16)
	end
  #-----------------------------------------------------------------------------
	# byte order in ARGB instead of RGBA.
  #-----------------------------------------------------------------------------
  def to_i
    return self.alpha.to_i << 24 | self.blue.to_i << 16 | self.green.to_i << 8 | self.red.to_i
  end
  #-----------------------------------------------------------------------------
	# return color from byte integer value
  #-----------------------------------------------------------------------------
  def self.from_i(value)
    b =  clr & 255
    g = (clr >> 8) & 255
    r = (clr >> 16) & 255
    a = (clr >> 24) & 255
    return Color.new(r, g, b, a)
  end
  #-----------------------------------------------------------------------------
	# parse color input to return color object
  #-----------------------------------------------------------------------------
  def self.parse(color)
    if color.is_a?(Color) # color object
      return color
    elsif color.is_a?(String) # string
      if color.include?("#") # hex color
        return Color.new(color)
      elsif color.include(",") # RGB color
        rgb = color.split(",")
        return Color.new(rgb[0].to_i, rgb[1].to_i, rgb[2].to_i)
      end
    elsif color.is_a?(Numeric) # decimal color
      return Color.new(color)
    end
    # returns nothing if wrong input
    return nil
  end
  #-----------------------------------------------------------------------------
	# returns color object for some commonly used colors
  #-----------------------------------------------------------------------------
  def self.red; return Color.new(255, 0, 0); end
  def self.green; return Color.new(0, 255, 0); end
  def self.blue; return Color.new(0, 0, 255); end
  def self.black; return Color.new(0, 0, 0); end
  def self.white; return Color.new(255, 255, 255); end
  def self.yellow; return Color.new(255, 255, 0); end
  def self.orange; return Color.new(255, 155, 0); end
  def self.purple; return Color.new(155, 0, 255); end
  def self.brown; return Color.new(112, 72, 32); end
  def self.teal; return Color.new(0, 255, 255); end
  def self.magenta; return Color.new(255, 0, 255); end
  #-----------------------------------------------------------------------------
	# returns darkened color
  #-----------------------------------------------------------------------------
  def darken(amt = 0.2)
    red = self.red - self.red*amt
    green = self.green - self.green*amt
    blue = self.blue - self.blue*amt
    return Color.new(red, green, blue)
  end
  #-----------------------------------------------------------------------------
end
#===============================================================================
#  Class used for generating scrolling backgrounds (move animations)
#===============================================================================
class ScrollingSprite < Sprite
  attr_accessor :speed
  attr_accessor :direction
  attr_accessor :vertical
  attr_accessor :pulse
  attr_accessor :min_o, :max_o
  #-----------------------------------------------------------------------------
  #  applies bitmap to sprite
  #-----------------------------------------------------------------------------
  def setBitmap(val, vertical = false, pulse = false)
    @vertical = vertical
    @pulse = pulse
    @direction = 1 if @direction.nil?
    @gopac = 1
    @frame = 0
    @speed = 32 if @speed.nil?
    @min_o = 0
    @max_o = 255
    val = pbBitmap(val) if val.is_a?(String)
    if @vertical
      bmp = Bitmap.new(val.width,val.height*2)
      for i in 0...2
        bmp.blt(0,val.height*i,val,val.rect)
      end
      self.bitmap = bmp
      y = @direction > 0 ? 0 : val.height
      self.src_rect.set(0,y,val.width,val.height)
    else
      bmp = Bitmap.new(val.width*2,val.height)
      for i in 0...2
        bmp.blt(val.width*i,0,val,val.rect)
      end
      self.bitmap = bmp
      x = @direction > 0 ? 0 : val.width
      self.src_rect.set(x,0,val.width,val.height)
    end
  end
  #-----------------------------------------------------------------------------
  #  updates sprite
  #-----------------------------------------------------------------------------
  def update
    s = (1/@speed).to_i
    @frame += 1
    return if @frame < s.delta_add(false)
    mod = [@direction, ((@speed < 1 ? 1 : @speed)*@direction).delta_sub(false)]
    if @vertical
      self.src_rect.y += @direction > 0 ? mod.max : mod.min
      self.src_rect.y = 0 if @direction > 0 && self.src_rect.y >= self.src_rect.height
      self.src_rect.y = self.src_rect.height if @direction < 0 && self.src_rect.y <= 0
    else
      self.src_rect.x += @direction > 0 ? mod.max : mod.min
      self.src_rect.x = 0 if @direction > 0 && self.src_rect.x >= self.src_rect.width
      self.src_rect.x = self.src_rect.width if @direction < 0 && self.src_rect.x <= 0
    end
    if @pulse
      self.opacity -= (@gopac*(@speed < 1 ? 1 : @speed)).delta_sub(false)
      @gopac *= -1 if self.opacity == @max_o || self.opacity == @min_o
    end
    @frame = 0
  end
  #-----------------------------------------------------------------------------
end
#===============================================================================
#  Class used for generating sprites with a trail
#===============================================================================
class TrailingSprite
  attr_accessor :x, :y, :z
  attr_accessor :color
  attr_accessor :keyFrame
  attr_accessor :zoom_x, :zoom_y
  attr_accessor :opacity
  #-----------------------------------------------------------------------------
  #  initializes trailing sprite
  #-----------------------------------------------------------------------------
  def initialize(viewport, bmp)
    @viewport = viewport
    @bmp = bmp
    @sprites = {}
    @x = 0; @y = 0; @z = 0; @i = 0
    @frame = 128
    @keyFrame = 0
    @color = Color.new(0,0,0,0)
    @zoom_x = 1; @zoom_y = 1
    @opacity = 255
  end
  #-----------------------------------------------------------------------------
  #  updates trailing sprite
  #-----------------------------------------------------------------------------
  def update
    @frame += 1
    if @frame > @keyFrame.delta_add(false)
      @sprites["#{@i}"] = Sprite.new(@viewport)
      @sprites["#{@i}"].bitmap = @bmp
      @sprites["#{@i}"].center
      @sprites["#{@i}"].x = x
      @sprites["#{@i}"].y = y
      @sprites["#{@i}"].z = z
      @sprites["#{@i}"].zoom_x = @zoom_x
      @sprites["#{@i}"].zoom_y = @zoom_y
      @sprites["#{@i}"].opacity = @opacity
      @i += 1
      @frame = 0
    end
    for key in @sprites.keys
      if @sprites[key].opacity > @keyFrame.delta_add(false)
        @sprites[key].opacity -= 24.delta_sub(false)
        @sprites[key].zoom_x -= 0.035.delta_sub(false)
        @sprites[key].zoom_y -= 0.035.delta_sub(false)
        @sprites[key].color = @color
      end
    end
  end
  #-----------------------------------------------------------------------------
  #  sets visibility for trail path
  #-----------------------------------------------------------------------------
  def visible=(val)
    for key in @sprites.keys
      @sprites[key].visible = val
    end
  end
  #-----------------------------------------------------------------------------
  #  disposes all trail
  #-----------------------------------------------------------------------------
  def dispose
    for key in @sprites.keys
      @sprites[key].dispose
    end
    @sprites.clear
  end
  #-----------------------------------------------------------------------------
  #  checks if disposed
  #-----------------------------------------------------------------------------
  def disposed?
    @sprites.keys.length < 1
  end
  #-----------------------------------------------------------------------------
end
#===============================================================================
#  Class used to render a hue changing sprite
#===============================================================================
class RainbowSprite < Sprite
  attr_accessor :speed
  #-----------------------------------------------------------------------------
  #  sets bitmap to sprite
  #-----------------------------------------------------------------------------
  def setBitmap(val, speed = 1)
    @val = val
    @val = pbBitmap(val) if val.is_a?(String)
    @speed = speed
    self.bitmap = Bitmap.new(@val.width,@val.height)
    self.bitmap.blt(0, 0, @val, @val.rect)
    @current_hue = 0
  end
  #-----------------------------------------------------------------------------
  #  updates sprite
  #-----------------------------------------------------------------------------
  def update
    @current_hue += [1, @speed.delta_sub(false)].max
    @current_hue = 0 if @current_hue >= 360
    self.bitmap.clear
    self.bitmap.blt(0, 0, @val, @val.rect)
    self.bitmap.hue_change(@current_hue)
  end
  #-----------------------------------------------------------------------------
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
#===============================================================================
#  Block callback wrapper structure
#===============================================================================
class CallbackWrapper
  @params = {}
  #-----------------------------------------------------------------------------
  #  execute callback
  #-----------------------------------------------------------------------------
  def execute(block, *args)
    @params.each do |key, value|
      args.instance_variable_set("@#{key.to_s}", value)
    end
    args.instance_eval(&block)
  end
  #-----------------------------------------------------------------------------
  #  set instance variables
  #-----------------------------------------------------------------------------
  def set(params)
    @params = params
  end
  #-----------------------------------------------------------------------------
end
#===============================================================================
#  Error logger utility
#-------------------------------------------------------------------------------
#  used to store custom error log messages
#===============================================================================
class ErrorLogger
  #-----------------------------------------------------------------------------
  # initialization
  #-----------------------------------------------------------------------------
  def initialize(file = nil)
    file = "systemout.txt" if file.nil?
    @file = RTP.getSaveFileName(file)
  end
  #-----------------------------------------------------------------------------
  # record message
  #-----------------------------------------------------------------------------
  def log_msg(msg, type = "INFO", file = nil)
    file = @file if file.nil?
    echoln "#{type.upcase}: #{msg}"
    msg = "#{time_stamp} [#{type.upcase}] #{msg}\r\n"
    File.open(file, 'ab') {|f| f.write(msg)}
  end
  #-----------------------------------------------------------------------------
  # format timestamp
  #-----------------------------------------------------------------------------
  def time_stamp
    time = Time.now
    return time.strftime "[%H:%M:%S %a %d-%b-%Y]"
  end
  #-----------------------------------------------------------------------------
  # logger input
  #-----------------------------------------------------------------------------
  def log(msg, file = nil); log_msg(msg, "INFO", file); end
  def info(msg, file = nil); log_msg(msg, "INFO", file); end
  def error(msg, file = nil)
    log_msg(msg, "ERROR", file)
    raise msg
  end
  def warn(msg, file = nil); log_msg(msg, "WARN", file); end
  def debug(msg, file = nil)
    return if !$DEBUG
    log_msg(msg, "DEBUG", file)
  end
end
#===============================================================================
#  Environment module for easy Win directory manipulation
#===============================================================================
module Env
  @logger = ErrorLogger.new
  #-----------------------------------------------------------------------------
  # constant containing GUIDs found on MSDN for common directories
  #-----------------------------------------------------------------------------
  COMMON_PATHS = {
      "CAMERA_ROLL" => "AB5FB87B-7CE2-4F83-915D-550846C9537B",
      "START_MENU" => "A4115719-D62E-491D-AA7C-E74B8BE3B067",
      "DESKTOP" => "B4BFCC3A-DB2C-424C-B029-7FE99A87C641",
      "DOCUMENTS" => "FDD39AD0-238F-46AF-ADB4-6C85480369C7",
      "DOWNLOADS" => "374DE290-123F-4565-9164-39C4925E467B",
      "HOME" => "5E6C858F-0E22-4760-9AFE-EA3317B67173",
      "MUSIC" => "4BD8D571-6D19-48D3-BE97-422220080E43",
      "PICTURES" => "33E28130-4E1E-4676-835A-98395C3BC3BB",
      "SAVED_GAMES" => "4C5C32FF-BB9D-43b0-B5B4-2D72E54EAAA4",
      "SCREENSHOTS" => "b7bede81-df94-4682-a7d8-57a52620b86f",
      "VIDEOS" => "18989B1D-99B5-455B-841C-AB7C74E4DDFC",
      "LOCAL" => "F1B32785-6FBA-4FCF-9D55-7B8E7F157091",
      "LOCALLOW" => "A520A1A4-1780-4FF6-BD18-167343C5AF16",
      "ROAMING" => "3EB685DB-65F9-4CF6-A03A-E3EF65729F3D",
      "PROGRAM_DATA" => "62AB5D82-FDC1-4DC3-A9DD-070D1D495D97",
      "PROGRAM_FILES_X64" => "6D809377-6AF0-444b-8957-A3773F02200E",
      "PROGRAM_FILES_X86" => "7C5A40EF-A0FB-4BFC-874A-C0F2E0B9FA8E",
      "COMMON_FILES" => "F7F1ED05-9F6D-47A2-AAAE-29D317C6F066",
      "PUBLIC" => "DFDF76A2-C82A-4D63-906A-5644AC457385",
  }
  #-----------------------------------------------------------------------------
  # escape chars for Directories
  #-----------------------------------------------------------------------------
  @char_set = {
    "\\" => "&bs;", "/" => "&fs;", ":" => "&cn;", "*" => "&as;",
    "?" => "&qm;", "\"" => "&dq;", "<" => "&lt;", ">" => "&gt;",
    "|" => "&po;"
  }
  #-----------------------------------------------------------------------------
  # returns directory path based on GUID
  #-----------------------------------------------------------------------------
  def self.path(type)
    hex = self.guid_to_hex(COMMON_PATHS[type])
    return getKnownFolder(hex)
  end
  #-----------------------------------------------------------------------------
  # converts GUID to proper hex array
  #-----------------------------------------------------------------------------
  def self.guid_to_hex(string)
    chunks = string.split("-")
    hex = []
    for i in 0...chunks.length
      chunk = chunks[i]
      if i < 3
        hex.push(chunk.hex)
      else
        split = chunk.scan(/../)
        for s in split
          hex.push(s.hex)
        end
      end
    end
    return hex
  end
  #-----------------------------------------------------------------------------
  # returns working directory
  #-----------------------------------------------------------------------------
  def self.directory
    return Dir.pwd.gsub("/","\\")
  end
  #-----------------------------------------------------------------------------
  # return error logger
  #-----------------------------------------------------------------------------
  def self.log
    return @logger
  end
  #-----------------------------------------------------------------------------
  # escape characters
  #-----------------------------------------------------------------------------
  def self.char_esc(str)
    for key in @char_set.keys
      str.gsub!(key, @char_set[key])
    end
    return str
  end
  #-----------------------------------------------------------------------------
  # describe characters
  #-----------------------------------------------------------------------------
  def self.char_dsc(str)
    for key in @char_set.keys
      str.gsub!(@char_set[key], key)
    end
    return str
  end
  #-----------------------------------------------------------------------------
  # interpret file stream and convert to appropriate Hash map
  #-----------------------------------------------------------------------------
  def self.interpret(filename)
    # failsafe
    return {} if !safeExists?(filename)
    # read file
    contents = File.open(filename, 'rb') {|f| f.read.gsub("\t", "  ") }
    # begin interpretation
    data = {}; entries = []
    # skip if empty
    return data if !contents || contents.empty?
    indexes = contents.scan(/(?<=\[)(.*?)(?=\])/i)
    return data if indexes.nil?
    indexes.push(indexes[-1])
    # iterate through each index and compile data points
    for j in 0...indexes.length
      i = indexes[j]
      if j == indexes.length - 1 # when final entry
        m = contents.split("[#{i[0]}]")[1]
        next if m.nil?
      else # fetch data contents
        m = contents.split("[#{i[0]}]")[0]
        next if m.nil?
        contents.gsub!(m, "")
      end
      m.gsub!("[#{i[0]}]\r\n", "")
      m.gsub!("[#{i[0]}]\n", "")
      # safely read each line and push into array
      read_lines = []
      m.each_line do |ext_line|
        ext_line.gsub!("\r\n", "")
        ext_line.gsub!("\n", "")
        read_lines.push(ext_line)
      end
      # push read lines into array
      entries.push(read_lines) # push into array
    end
    # delete first empty data point
    entries.delete_at(0)
    # loop to iterate through each data point and compile usable information
    for i in 0...entries.length
      d = {}
      # set primary section
      section = "__pk__"
      # compiles data into proper structure
      for e in entries[i]
        d[section] = {} if !d.keys.include?(section)
        e = e.split("#")[0]
        next if e.nil? || e == "" || (e.include?("[") && e.include?("]"))
        a = e.split("=")
        a[0] = a[0] ? a[0].strip : ""
        a[1] = a[1] ? a[1].strip : ""
        next section = a[0] if a[1].nil? || a[1] == "" || a[1].empty?
        # split array
        a[1] = a[1].split(",")
        # raise error
        if a[0] == "XY" && a[1].length < 2
          raise self.lengthError(filename, indexes[i][0], section, 2, a[0], a[1])
        elsif a[0] == "XYZ" && a[1].length < 3
          raise self.lengthError(filename, indexes[i][0], section, 3, a[0], a[1])
        end
        # convert to proper type
        for q in 0...a[1].length
          typ = "String"
          begin
            if a[1][q].is_numeric? && a[1][q].include?('.')
              typ = "Float"
              a[1][q] = a[1][q].to_f
            elsif a[1][q].is_numeric?
              typ = "Integer"
              a[1][q] = a[1][q].to_i
            elsif a[1][q].downcase == "true" || a[1][q].downcase == "false"
              typ = "Boolean"
              a[1][q] = a[1][q].downcase == "true"
            end
          rescue
            self.log.error(self.formatError(filename, indexes[i][0], section, typ, a[0], a[1][q]))
          end
        end
        # add data to section
        d[section][a[0]] = a[1]
      end
      # delete primary if empty
      d.delete("__pk__") if d["__pk__"] && d["__pk__"].empty?
      # push data entry
      data[indexes[i][0]] = d
    end
    return data
  end
  #-----------------------------------------------------------------------------
  # print out formatting error
  #-----------------------------------------------------------------------------
  def self.formatError(filename, section, sub, type, key, val)
    sectn = (sub == "__pk__") ? "[#{section}]" : "[#{section}]\nSub-section: #{sub}"
    return "File: #{filename}\nError compiling data in Section: #{sectn}\nCould not implicitly convert value for Key: #{key} to type (#{type})\n#{key} = #{val}"
  end
  def self.lengthError(filename, section, sub, len, key, val)
    sectn = (sub == "__pk__") ? "[#{section}]" : "[#{section}]\nSub-section: #{sub}"
    return "File: #{filename}\nError compiling data in Section: #{sectn}\nWrong number of arguments for Key: #{key}, got #{val.length} expected #{len}"
  end
  #-----------------------------------------------------------------------------
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
#===============================================================================
#  Legacy utilities
#===============================================================================
def isConst?(val, mod, constant)
  begin
    return false if !mod.const_defined?(constant.to_sym)
  rescue
    return false
  end
  return (val == mod.const_get(constant.to_sym))
end
def hasConst?(mod, constant)
  return false if !mod || !constant || constant == ""
  return mod.const_defined?(constant.to_sym) rescue false
end
def getConst(mod, constant)
  return nil if !mod || !constant || constant == ""
  return mod.const_get(constant.to_sym) rescue nil
end
#===============================================================================
