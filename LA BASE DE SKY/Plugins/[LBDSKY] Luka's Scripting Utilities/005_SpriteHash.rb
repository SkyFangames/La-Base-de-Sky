#===============================================================================
#  SpriteHash - wrapper for handling RMXP sprite hashes
#===============================================================================
class SpriteHash
  #---------------------------------------------------------------------------
  attr_reader :hash, :viewport
  #---------------------------------------------------------------------------
  #  class method to get bitmap from path or other bitmapable object
  #---------------------------------------------------------------------------
  def self.bitmap(path)
    return path if path.is_a?(Bitmap)
    return Sprites::Bitmap.new(path.width, path.height) if path.is_a?(Rect)
    return path.bitmap if path.respond_to?(:bitmap) && path.bitmap

    bitmap = RPG::Cache.fromCache(path) || Sprites::Bitmap.new(path)
    RPG::Cache.setKey(path, bitmap)
    bitmap
  rescue Errno::ENOENT
    LUTS::ErrorMessages::ImageNotFound.new(path).raise
    ::Bitmap.new(2, 2)
  end
  #---------------------------------------------------------------------------
  #  downloads a bitmap and returns it
  #---------------------------------------------------------------------------
  def self.online_bitmap(url)
    file_name = url.split('/').last
    pbDownloadToFile(url, file_name)
    return nil unless File.safe_data?(file_name)

    bitmap = bitmap(file_name)
    File.delete(file_name)

    bitmap
  end
  #---------------------------------------------------------------------------
  #  class constructor
  #---------------------------------------------------------------------------
  def initialize(viewport = nil)
    @viewport = viewport
    @sprites  = {}
    @hash     = SpriteCollection.new(@sprites)
  end
  #---------------------------------------------------------------------------
  #  add new sprite to sprite hash
  #---------------------------------------------------------------------------
  def add(key, options = {})
    if options.key?(:object)
      @sprites[key] = options[:object]
      return @hash.add(key)
    end

    @sprites[key] = sprite_instance(options[:type], options[:class])

    # apply bitmap (allow key value arguments)
    if options[:bitmap]
      if options[:bitmap].is_a?(Hash)
        @sprites[key].set_bitmap(self.class.bitmap(options[:bitmap][:file]), **options[:bitmap].except(:file))
      else
        @sprites[key].set_bitmap(self.class.bitmap(options[:bitmap]))
      end
    end

    options.except(:type, :bitmap, :class).each do |option, value|
      next set_value(key, "#{option}=".to_sym, value) if @sprites[key].respond_to?("#{option}=".to_sym)
      next unless @sprites[key].respond_to?(option)

      set_value(key, option, value)
    end

    @hash.add(key)
    @sprites[key]
  end

  def add_raw(key, object)
    @sprites[key] = object
  end
  #---------------------------------------------------------------------------
  #  get sprite from sprite hash based on key
  #---------------------------------------------------------------------------
  def [](key)
    @sprites[key]
  end
  #---------------------------------------------------------------------------
  #  get all available sprite keys
  #---------------------------------------------------------------------------
  def keys
    @sprites.keys
  end

  def key?(key)
    @sprites.keys.include?(key)
  end
  #---------------------------------------------------------------------------
  #  iterate through sprite hash with code block
  #---------------------------------------------------------------------------
  def each(&block)
    return unless block

    @sprites.each do |key, value|
      block.call(key, value)
    end
  end
  #---------------------------------------------------------------------------
  #  update all sprites in sprite hash
  #---------------------------------------------------------------------------
  def update
    @sprites.each { |_k, sprite| sprite.update }
  end
  #---------------------------------------------------------------------------
  #  set viewport across all sprites
  #---------------------------------------------------------------------------
  def viewport=(val)
    @viewport = val
    @sprites.each { |_k, sprite| sprite.viewport = @viewport }
  end
  #---------------------------------------------------------------------------
  #  disposes all available sprites
  #---------------------------------------------------------------------------
  def dispose(options = {})
    @sprites.keys.reject { |key| Array(options[:except]).include?(key) }.each do |key|
      next if options[:only] && !Array(options[:only]).include?(key)

      @sprites[key].dispose
      @sprites.delete(key)
    end
  end

  def disposed?
    @sprites.keys.empty?
  end
  #---------------------------------------------------------------------------
  #  set value for all sprites in hash
  #---------------------------------------------------------------------------
  def set(options = {})
    @sprites.keys.each do |key|
      options.except(:type, :class).each do |option, value|
        next set_value(key, "#{option}=".to_sym, value) if @sprites[key].respond_to?("#{option}=".to_sym)
        next unless @sprites[key].respond_to?(option)

        set_value(key, option, value)
      end
    end
  end

  private
  #---------------------------------------------------------------------------
  #  create sprite instance from params
  #---------------------------------------------------------------------------
  def sprite_instance(type = nil, klass = nil)
    return (klass.is_a?(String) ? klass.constantize : klass).new(@viewport) if klass
    return Sprites::Base.new(@viewport) unless type

    "Sprites::#{type.to_s.camelize}".constantize.new(@viewport)
  rescue NameError
    LUTS::ErrorMessages::SpriteError.new(type.to_s.camelize).raise
    Sprites::Base.new(@viewport)
  end
  #---------------------------------------------------------------------------
  #  set sprite instance variable based on available methods
  #---------------------------------------------------------------------------
  def set_value(key, option, value)
    return @sprites[key].send(option, value) if option.to_s.chars.last.eql?('=')

    if @sprites[key].method(option).arity > 0
      if value.is_a?(Array)
        @sprites[key].send(option, *value)
      elsif value.is_a?(Hash)
        @sprites[key].send(option, **value)
      else
        @sprites[key].send(option, value)
      end
    else
      @sprites[key].send(option)
    end
  end
  #---------------------------------------------------------------------------
  #  sprite hash class to implicitly define sprite accessors
  #---------------------------------------------------------------------------
  class SpriteCollection
    def initialize(sprites = nil)
      @sprites = sprites
    end

    def add(key)
      return if key.to_s.numeric?

      instance_variable_set("@#{key}", @sprites[key])
      self.class.attr_accessor(key.to_sym)
    end

    def first
      @sprites[@sprites.keys.first]
    end

    def last
      @sprites[@sprites.keys.last]
    end

    def [](key)
      @sprites[key]
    end
  end
  #---------------------------------------------------------------------------
end
