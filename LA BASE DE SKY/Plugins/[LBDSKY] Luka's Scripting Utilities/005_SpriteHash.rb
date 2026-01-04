#===============================================================================
#  Luka's Scripting Utilities
#
#  SpriteHash - wrapper for handling RMXP sprite hashes
#===============================================================================
class SpriteHash
  # @return [SpriteHash::SpriteCollection]
  attr_reader :hash
  # @return [Viewport]
  attr_reader :viewport

  # Class method to get bitmap from path or other bitmapable object
  # @param path [String]
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

  # Downloads a bitmap and returns it
  # @param url [String]
  def self.online_bitmap(url)
    file_name = url.split('/').last
    pbDownloadToFile(url, file_name)
    return nil unless File.safe_data?(file_name)

    bitmap = bitmap(file_name)
    File.delete(file_name)

    bitmap
  end

  # @param viewport [Viewport]
  def initialize(viewport = nil)
    @viewport = viewport
    @sprites  = {}
    @hash     = SpriteCollection.new(@sprites)
  end

  # Adds new sprite to sprite hash
  # @param key [Symbol]
  # @param options [Hash]
  # @param block [Proc]
  # @return [Sprites::Base]
  def add(key, options = {}, &block)
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
    block.call(@sprites[key]) if block_given?
    @sprites[key]
  end

  # Adds sprite already instanciated elsewhere
  # @param key [Symbol]
  # @param object [Object]
  # @param block [Proc]
  # @return [Object]
  def add_raw(key, object, &block)
    @sprites[key] = object
    block.call(@sprites[key]) if block_given?
    @sprites[key]
  end

  # @return [Object] sprite from sprite hash based on key
  def [](key)
    @sprites[key]
  end

  # @return [Array<Symbol>] all available sprite keys
  def keys
    @sprites.keys
  end

  # @param key [Symbol]
  # @return [Boolean]
  def key?(key)
    @sprites.keys.include?(key)
  end

  # Iterates through sprite hash with code block
  # @param block [Proc]
  def each(&block)
    return unless block_given?

    @sprites.each do |key, sprite|
      block.call(key, sprite)
    end
  end

  # Iterates through each sprite in hash
  # @param block [Proc]
  def each_sprite(&block)
    return unless block_given?

    @sprites.each_value do |sprite|
      block.call(sprite)
    end
  end

  # Iterates through each key in hash
  # @param block [Proc]
  def each_key(&block)
    return unless block_given?

    @sprites.each_key do |key|
      block.call(key)
    end
  end

  # Selects only evaluated blocks
  # @param block [Proc]
  # @return [Array<Object>]
  def select(&block)
    return @sprites unless block_given?

    @sprites.select do |key, sprite|
      block.call(key, sprite)
    end
  end

  # Rejects only evaluated blocks
  # @param block [Proc]
  # @return [Array<Object>]
  def reject(&block)
    return @sprites unless block_given?

    @sprites.reject do |key, sprite|
      block.call(key, sprite)
    end
  end

  # Update all sprites in sprite hash
  def update
    @sprites.each_value(&:update)
  end

  # Sets viewport across all sprites
  # @param val [Viewport]
  def viewport=(val)
    @viewport = val
    @sprites.each_value { |sprite| sprite.viewport = @viewport }
  end

  # Disposes all available sprites
  # @param options [Hash]
  def dispose(options = {})
    @sprites.keys.reject { |key| Array(options[:except]).include?(key) }.each do |key|
      next if options[:only] && !Array(options[:only]).include?(key)
      next if @sprites[key]&.disposed?

      @sprites[key].dispose
      @sprites.delete(key)
    end
  end

  # @return [Boolean]
  def disposed?
    @sprites.keys.empty?
  end

  # Set value for all sprites in hash
  # @param options [Hash]
  def set(options = {})
    @sprites.each_key do |key|
      options.except(:type, :class).each do |option, value|
        next set_value(key, "#{option}=".to_sym, value) if @sprites[key].respond_to?("#{option}=".to_sym)
        next unless @sprites[key].respond_to?(option)

        set_value(key, option, value)
      end
    end
  end

  private

  # Creates sprite instance from params
  # @param type [Symbol]
  # @param klass [Class]
  def sprite_instance(type = nil, klass = nil)
    return (klass.is_a?(String) ? klass.constantize : klass).new(@viewport) if klass
    return Sprites::Base.new(@viewport) unless type

    "Sprites::#{type.to_s.camelize}".constantize.new(@viewport)
  rescue NameError
    LUTS::ErrorMessages::SpriteError.new(type.to_s.camelize).raise
    Sprites::Base.new(@viewport)
  end

  # Sets sprite instance variable based on available methods
  # @param key [Symbol]
  # @param option [Symbol]
  # @param value [Object]
  def set_value(key, option, value)
    return @sprites[key].send(option, value) if option.to_s.chars.last.eql?('=')

    if @sprites[key].method(option).arity.positive?
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

  # Sprite hash class to implicitly define sprite accessors
  class SpriteCollection
    # @param sprites [Hash]
    def initialize(sprites = nil)
      @sprites = sprites
    end

    # Adds key to sprite collection
    # @param key [Symbol]
    def add(key)
      return if key.to_s.numeric?

      instance_variable_set("@#{key}", @sprites[key])
      self.class.attr_accessor(key.to_sym)
    end

    # @return [Object]
    def first
      @sprites[@sprites.keys.first]
    end

    # @return [Object]
    def last
      @sprites[@sprites.keys.last]
    end

    # @param key [Symbol]
    # @return [Object]
    def [](key)
      @sprites[key]
    end
  end
end
