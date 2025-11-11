#===============================================================================
# Original bitmap wrapper by Luka S.J. for EBDX sprites.
# Modified by GolisopodUser for the Generation 8 Pack.
# Modified further by Lucidious89.
#===============================================================================
class DeluxeBitmapWrapper
  attr_reader :width, :height, :total_frames, :frame_idx
  attr_accessor :constrict_x, :constrict_y, :constrict_w, :constrict_h
  attr_accessor :pokemon, :scale, :speed, :reversed
  
  def initialize(file, metrics, back = false)
    raise "DeluxeBitmapWrapper filename is nil." if file.nil?
    @bitmaps      = []
    @bmp_file     = file
    @pokemon      = nil
    @changed_hue  = false
    @reversed     = false
    @width        = 0
    @height       = 0
    @total_frames = 0
    @frame_idx    = 0
    @last_uptime  = 0
    @constrict_x  = 0
    @constrict_y  = 0
    case metrics
    when Array
      @scale, @speed = *metrics
    when GameData::SpeciesMetrics
      @scale = (back) ? metrics.back_sprite_scale : metrics.front_sprite_scale
      @speed = (back) ? metrics.back_sprite_speed : metrics.front_sprite_speed
    else
      @scale = 1
      @speed = 0
    end
    @speed = 0 if $PokemonSystem.animated_sprites > 0
    @base_speed = @speed
    self.refresh
  end
  
  def length; return @total_frames; end
  def copy;   return @bitmaps[@frame_idx].clone; end
  def each;   end
  
  #-----------------------------------------------------------------------------
  # Refreshes bitmap properties based on the Pokemon's condition.
  #-----------------------------------------------------------------------------
  def update_pokemon_sprite(speed_mod = nil, reversed = false)
    return if $PokemonSystem.animated_sprites > 0
    if !speed_mod.nil?
      @base_speed = speed_mod
      @speed = @base_speed
    end
    return if !@pokemon || @base_speed == 0
    case @pokemon.status
    when :FROZEN then @speed = 0
    when :SLEEP  then @speed = (@base_speed * 3)
    else
      if [:PARALYSIS, :DROWSY].include?(@pokemon.status) ||
         @pokemon.hp <= @pokemon.totalhp / 4
        @speed = @base_speed * 2
      else
        @speed = @base_speed
      end
    end
    if @pokemon.is_a?(Battle::Battler)
      return if @total_frames == 1
      if @speed == @base_speed
        val = @pokemon.stages[:SPEED] / 10.0
        mod = (val < 0) ? val.abs : -val
        @speed += mod
      end
      if @pokemon.effects[PBEffects::Confusion] > 0 || 
         @pokemon.effects[PBEffects::Attract] >= 0 || reversed
        @reversed = true
      else
        @reversed = false
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Assigns a Pokemon object to this bitmap. Sets hue and animation speed. 
  #-----------------------------------------------------------------------------
  def setPokemon(pokemon, back = false, hue = nil, species = nil)
    @pokemon = pokemon
    return if !@pokemon
    case @pokemon
    when Pokemon
      species = @pokemon.species if !species
      metrics = GameData::SpeciesMetrics.get_species_form(species, @pokemon.form, @pokemon.gender == 1)
      hue_change(metrics.sprite_super_hue) if @pokemon.super_shiny?
      if $PokemonSystem.animated_sprites == 0
        @speed = (back) ? metrics.back_sprite_speed : metrics.front_sprite_speed
        @base_speed = @speed
      end
    when Battle::Battler
      pkmn = @pokemon.visiblePokemon
      metrics = GameData::SpeciesMetrics.get_species_form(pkmn.species, pkmn.form, pkmn.gender == 1)
      hue_change(metrics.sprite_super_hue) if pkmn.super_shiny?
      if $PokemonSystem.animated_sprites == 0
        @speed = (back) ? metrics.back_sprite_speed : metrics.front_sprite_speed
        @base_speed = @speed
      end
    end
    hue_change(hue) if hue && !changedHue?
  end
  
  #-----------------------------------------------------------------------------
  # Compiles a spritesheet.
  #-----------------------------------------------------------------------------
  def compile_strip(pkmn = nil, back = false)
    strip = []
    bmp = Bitmap.new(@bmp_file)
    $game_temp.spinda_spots = nil
    alter_function = MultipleForms.getFunction(pkmn.species, "alterBitmap") if pkmn
    @total_frames.times do |i|
      bitmap = Bitmap.new(@width, @height)
      bitmap.stretch_blt(Rect.new(0, 0, @width, @height), bmp, Rect.new((@width / @scale) * i, 0, @width / @scale, @height / @scale))
      if alter_function && !back
        pkmn.set_spot_pattern(bitmap, @scale, i)
        alter_function.call(pkmn, bitmap, @scale, i)
      end
      strip.push(bitmap)
    end
    self.refresh(strip)
  end
  
  #-----------------------------------------------------------------------------
  # Refreshes bitmap parameters.
  #-----------------------------------------------------------------------------
  def refresh(bitmaps = nil)
    self.dispose
    if bitmaps.nil? && @bmp_file.is_a?(String)
      f_bmp = Bitmap.new(@bmp_file)
      if f_bmp.animated?
        @width = f_bmp.width * @scale
        @height = f_bmp.height * @scale
        f_bmp.frame_count.times do |i|
          f_bmp.goto_and_stop(i)
          bitmap = Bitmap.new(@width, @height)
          bitmap.stretch_blt(Rect.new(0, 0, @width, @height), f_bmp, Rect.new(0, 0, f_bmp.width, f_bmp.height))
          @bitmaps.push(bitmap)
        end
      elsif f_bmp.width > (f_bmp.height * 2)
        @width = f_bmp.height * @scale
        @height = f_bmp.height * @scale
        (f_bmp.width.to_f / f_bmp.height).ceil.times do |i|
          x = i * f_bmp.height
          bitmap = Bitmap.new(@width, @height)
          bitmap.stretch_blt(Rect.new(0, 0, @width, @height), f_bmp, Rect.new(x, 0, f_bmp.height, f_bmp.height))
          @bitmaps.push(bitmap)
        end
      else
        @width = f_bmp.width * @scale
        @height = f_bmp.height * @scale
        bitmap = Bitmap.new(@width, @height)
        bitmap.stretch_blt(Rect.new(0, 0, @width, @height), f_bmp, Rect.new(0, 0, f_bmp.width, f_bmp.height))
        @bitmaps.push(bitmap)
      end
      f_bmp.dispose
    else
      @bitmaps = bitmaps
    end
    if @bitmaps.length < 1 && !self.is_bitmap?
      raise "Unable to construct proper bitmap sheet from `#{@bmp_file}`"
    end
    if !self.is_bitmap?
      @total_frames = @bitmaps.length
      @temp_bmp = Bitmap.new(@bitmaps[0].width, @bitmaps[0].width)
    end
  end
  
  #-----------------------------------------------------------------------------
  # Animation related utilities.
  #-----------------------------------------------------------------------------
  def update
    return false if self.disposed?
    return false if $PokemonSystem.animated_sprites > 0
    return false if @speed <= 0
    timer = System.uptime
    delay = ((@speed / 2.0) * Settings::ANIMATION_FRAME_DELAY).round / 1000.0
    return if timer - @last_uptime < delay
    (@reversed) ? @frame_idx -= 1 : @frame_idx += 1
    @frame_idx = 0 if @frame_idx >= @total_frames
    @frame_idx = @total_frames - 1 if @frame_idx < 0
    @last_uptime = timer
  end
  
  def to_frame(frame)
    frame = frame == "last" ? @total_frames - 1 : 0 if frame.is_a?(String)
    frame = @total_frames - 1 if frame >= @total_frames
    frame = 0 if frame < 0
    @frame_idx = frame
  end
  
  def play
    return if self.finished?
    self.update
  end
  
  def deanimate
    @frame_idx = 0
    @speed = 0
  end
  
  def reanimate
    @speed = @base_speed
  end
  
  def finished?
    if @reversed
      return (@frame_idx == 0)
    else
      return (@frame_idx >= @total_frames - 1)
    end
  end

  #-----------------------------------------------------------------------------
  # Bitmap related utilities.
  #-----------------------------------------------------------------------------
  def bitmap
    return @bmp_file if self.is_bitmap? && !@bmp_file.disposed?
    return nil if self.disposed?
    x, y, w, h = self.box
    @temp_bmp.clear
    @temp_bmp.blt(x, y, @bitmaps[@frame_idx], Rect.new(x, y, w, h))
    return @temp_bmp
  end
  
  def bitmap=(value)
    return if !value.is_a?(String)
    @bmp_file = value
    self.refresh
  end
  
  def is_bitmap?
    return @bmp_file.is_a?(BitmapWrapper) || @bmp_file.is_a?(Bitmap)
  end
  
  def box
    x = @constrict_x || 0
    y = @constrict_y || 0
    w = @constrict_w || @width
    h = @constrict_h || @height
    return x, y, w, h
  end
  
  #-----------------------------------------------------------------------------
  # Hue related utilities.
  #-----------------------------------------------------------------------------
  def hue_change(value)
    @bitmaps.each { |bmp| bmp.hue_change(value) }
    @changed_hue = true
  end
  
  def changedHue?; return @changed_hue; end
  
  #-----------------------------------------------------------------------------
  # Dispose related utilities.
  #-----------------------------------------------------------------------------
  def dispose
    @bitmaps.each { |bmp| bmp.dispose }
    @bitmaps.clear
    @temp_bmp.dispose if @temp_bmp && !@temp_bmp.disposed?
  end
  
  def disposed?; return @bitmaps.empty?; end
end