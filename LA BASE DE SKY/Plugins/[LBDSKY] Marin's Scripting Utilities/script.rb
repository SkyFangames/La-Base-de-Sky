# Dir class extensions
class Dir
  class << Dir
    alias marin_delete delete
  end

  # Returns all files in the targeted path
  def self.get_files(path, recursive = true)
    return Dir.get_all(path, recursive).select { |path| File.file?(path) }
  end
  
  # Returns all directories in the targeted path
  def self.get_dirs(path, recursive = true)
    return Dir.get_all(path, recursive).select { |path| File.directory?(path) }
  end
  
  # Returns all files and directories in the targeted path
  def self.get_all(path, recursive = true)
    files = []
    Dir.foreach(path) do |f|
      next if f == "." || f == ".."
      if File.directory?(path + "/" + f) && recursive
        files.concat(Dir.get_files(path + "/" + f))
      end
      files << path + "/" + f
    end
    return files
  end
  
  # Deletes a directory and all files/directories within, unless non_empty is false
  # Renamed to `delete_recursive` to avoid overriding `Dir.delete`.
  def self.delete_recursive(path, non_empty = true)
    if non_empty
      for file in Dir.get_all(path)
        if File.directory?(file)
          Dir.delete_recursive(file, non_empty)
        elsif File.file?(file)
          File.delete(file)
        end
      end
    end
    marin_delete(path)
  end
  
  # Creates all directories that don't exist in the given path.
  def self.create(path)
    split = path.split('/')
    for i in 0...split.size
      Dir.mkdir(split[0..i].join('/')) unless File.directory?(split[0..i].join('/'))
    end
  end
end


# Sprite class extensions
class Sprite
  # Shorthand for initializing a bitmap by path, bitmap, or width/height:
  # -> bmp("Graphics/Pictures/bag")
  # -> bmp(32, 32)
  # -> bmp(some_other_bitmap)
  def bmp(arg1 = nil, arg2 = nil)
    if arg1
      if arg2
        arg1 = Graphics.width if arg1 == -1
        arg2 = Graphics.height if arg2 == -1
        self.bitmap = Bitmap.new(arg1, arg2)
      elsif arg1.is_a?(Bitmap)
        self.bitmap = arg1.clone
      else
        self.bitmap = Bitmap.new(arg1)
      end
    else
      return self.bitmap
    end
  end
  
  # Alternative to bmp(path):
  # -> bmp = "Graphics/Pictures/bag"
  def bmp=(arg1)
    bmp(arg1)
  end
  
  # Usage:
  # -> [x]             # Sets sprite.x to x
  # -> [x,y]           # Sets sprite.x to x and sprite.y to y
  # -> [x,y,z]         # Sets sprite.x to x and sprite.y to y and sprite.z to z
  # -> [nil,y]         # Sets sprite.y to y
  # -> [nil,nil,z]     # Sets sprite.z to z
  # -> [x,nil,z]       # Sets sprite.x to x and sprite.z to z
  # Etc.
  def xyz=(args)
    self.x = args[0] || self.x
    self.y = args[1] || self.y
    self.z = args[2] || self.z
  end
  
  # Returns the x, y, and z coordinates in the xyz=(args) format, [x,y,z]
  def xyz
    return [self.x,self.y,self.z]
  end
  
  # Centers the sprite by setting the origin points to half the width and height
  def center_origins
    return if !self.bitmap
    self.ox = self.bitmap.width / 2
    self.oy = self.bitmap.height / 2
  end
  
  # Returns the sprite's full width, taking zoom_x into account
  def fullwidth
    return self.bitmap.width.to_f * self.zoom_x
  end
  
  # Returns the sprite's full height, taking zoom_y into account
  def fullheight
    return self.bitmap.height.to_f * self.zoom_y
  end
end

class TextSprite < Sprite
  # Sets up the sprite and bitmap. You can also pass text to draw
  # either an array of arrays, or an array containing the normal "parameters"
  # for drawing text:
  # [text,x,y,align,basecolor,shadowcolor]
  def initialize(viewport = nil, text = nil, width = -1, height = -1)
    super(viewport)
    @width = width
    @height = height
    self.bmp(@width, @height)
    pbSetSystemFont(self.bmp)
    if text.is_a?(Array)
      if text[0].is_a?(Array)
        pbDrawTextPositions(self.bmp,text)
      else
        pbDrawTextPositions(self.bmp,[text])
      end
    end
  end
  
  # Clears the bitmap (and thus all drawn text)
  def clear
    self.bmp.clear
    pbSetSystemFont(self.bmp)
  end
  
  # You can also pass text to draw either an array of arrays, or an array
  # containing the normal "parameters" for drawing text:
  # [text,x,y,align,basecolor,shadowcolor]
  def draw(text, clear = false)
    self.clear if clear
    if text[0].is_a?(Array)
      pbDrawTextPositions(self.bmp,text)
    else
      pbDrawTextPositions(self.bmp,[text])
    end
  end
  
  # Draws text with outline
  # [text,x,y,align,basecolor,shadowcolor]
  def draw_outline(text, clear = false)
    self.clear if clear
    if text[0].is_a?(Array)
      for e in text
        e[2] -= 224
        pbDrawOutlineText(self.bmp,e[1],e[2],640,480,e[0],e[4],e[5],e[3])
      end
    else
      e = text
      e[2] -= 224
      pbDrawOutlineText(self.bmp,e[1],e[2],640,480,e[0],e[4],e[5],e[3])
    end
  end
  
  # Draws and breaks a line if the width is exceeded
  # [text,x,y,width,numlines,basecolor,shadowcolor]
  def draw_ex(text, clear = false)
    self.clear if clear
    if text[0].is_a?(Array)
      for e in text
        drawTextEx(self.bmp,e[1],e[2],e[3],e[4],e[0],e[5],e[6])
      end
    else
      e = text
      drawTextEx(self.bmp,e[1],e[2],e[3],e[4],e[0],e[5],e[6])
    end
  end
  
  # Clears and disposes the sprite
  def dispose
    clear
    super
  end
end

class ByteWriter
  def initialize(filename)
    @file = File.new(filename, "wb")
  end
 
  def <<(*data)
    write(*data)
  end
 
  def write(*data)
    data.each do |e|
      if e.is_a?(Array) || e.is_a?(Enumerator)
        e.each { |item| write(item) }
      elsif e.is_a?(Numeric)
        @file.putc e
      else
        raise "Invalid data for writing.\nData type: #{e.class}\nData: #{e.inspect[0..100]}"
      end
    end
  end
 
  def write_int(int)
    self << ByteWriter.to_bytes(int)
  end
 
  def close
    @file.close
    @file = nil
  end
 
  def self.to_bytes(int)
    return [
      (int >> 24) & 0xFF,
      (int >> 16) & 0xFF,
      (int >> 8) & 0xFF,
       int & 0xFF
    ]
  end
end
 
class Bitmap
  def save_to_png(filename)
    f = ByteWriter.new(filename)
   
    #============================= Writing header ===============================#
    # PNG signature
    f << [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
    # Header length
    f << [0x00, 0x00, 0x00, 0x0D]
    # IHDR
    headertype = [0x49, 0x48, 0x44, 0x52]
    f << headertype
   
    # Width, height, compression, filter, interlacing
    headerdata = ByteWriter.to_bytes(self.width).
      concat(ByteWriter.to_bytes(self.height)).
      concat([0x08, 0x06, 0x00, 0x00, 0x00])
    f << headerdata
   
    # CRC32 checksum
    sum = headertype.concat(headerdata)
    f.write_int Zlib::crc32(sum.pack("C*"))
   
    #============================== Writing data ================================#
    data = []
    for y in 0...self.height
      # Start scanline
      data << 0x00 # Filter: None
      for x in 0...self.width
        px = self.get_pixel(x, y)
        # Write raw RGBA pixels
        data << px.red
        data << px.green
        data << px.blue
        data << px.alpha
      end
    end
    # Zlib deflation
    smoldata = Zlib::Deflate.deflate(data.pack("C*")).bytes
    # data chunk length
    f.write_int smoldata.size
    # IDAT
    f << [0x49, 0x44, 0x41, 0x54]
    f << smoldata
    # CRC32 checksum
    f.write_int Zlib::crc32([0x49, 0x44, 0x41, 0x54].concat(smoldata).pack("C*"))
   
    #============================== End Of File =================================#
    # Empty chunk
    f << [0x00, 0x00, 0x00, 0x00]
    # IEND
    f << [0x49, 0x45, 0x4E, 0x44]
    # CRC32 checksum
    f.write_int Zlib::crc32([0x49, 0x45, 0x4E, 0x44].pack("C*"))
    f.close
    return nil
  end
end


# Stand-alone methods

# Fades in a black overlay
def showBlk(n = 16)
  return if $blkVp || $blk
  $blkVp = Viewport.new(0,0,Settings::SCREEN_WIDTH,Settings::SCREEN_HEIGHT)
  $blkVp.z = 9999999
  $blk = Sprite.new($blkVp)
  $blk.bmp(-1,-1)
  $blk.bitmap.fill_rect(0,0,Settings::SCREEN_WIDTH,Settings::SCREEN_HEIGHT,Color.new(0,0,0))
  $blk.opacity = 0
  for i in 0...(n + 1)
    Graphics.update
    Input.update
    yield i if block_given?
    $blk.opacity += 256 / n.to_f
  end
end

# Fades out and disposes a black overlay
def hideBlk(n = 16)
  return if !$blk || !$blkVp
  for i in 0...(n + 1)
    Graphics.update
    Input.update
    yield i if block_given?
    $blk.opacity -= 256 / n.to_f
  end
  $blk.dispose
  $blk = nil
  $blkVp.dispose
  $blkVp = nil
end


def pbGetActiveEventPage(event, mapid = nil)
  mapid ||= event.map.map_id if event.respond_to?(:map)
  pages = (event.is_a?(RPG::Event) ? event.pages : event.instance_eval { @event.pages })
  for i in 0...pages.size
    c = pages[pages.size - 1 - i].condition
    ss = !(c.self_switch_valid && !$game_self_switches[[mapid, event.id, c.self_switch_ch]])
    sw1 = !(c.switch1_valid && !$game_switches[c.switch1_id])
    sw2 = !(c.switch2_valid && !$game_switches[c.switch2_id])
    var = true
    if c.variable_valid
      if !c.variable_value || !$game_variables[c.variable_id].is_a?(Numeric) ||
         $game_variables[c.variable_id] < c.variable_value
        var = false
      end
    end
    if ss && sw1 && sw2 && var # All conditions are met
      return pages[pages.size - 1 - i]
    end
  end
  return nil
end