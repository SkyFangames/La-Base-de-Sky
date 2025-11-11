################################################################################
#
# Pokemon sprites (out of battle)
#
################################################################################

class PokemonSprite < Sprite
  attr_reader   :pkmn
  attr_accessor :display_values

  #-----------------------------------------------------------------------------
  # Animated sprite utilities.
  #-----------------------------------------------------------------------------
  def animated?
    return !@_iconbitmap.nil? && @_iconbitmap.is_a?(DeluxeBitmapWrapper)
  end
  
  def static?
    return true if !animated?
    return @_iconbitmap.length > 1
  end
  
  def iconBitmap; return @_iconbitmap; end
  
  def hue=(value)
    return if !animated? || @_iconbitmap.changedHue?
    @_iconbitmap.hue_change(value)
    self.bitmap = @_iconbitmap.bitmap
  end
  
  def to_first_frame
    return if !@_iconbitmap
    @_iconbitmap.to_frame(0)
    self.bitmap = @_iconbitmap.bitmap
  end
  
  def to_last_frame
    return if !@_iconbitmap
    @_iconbitmap.to_frame("last")
    self.bitmap = @_iconbitmap.bitmap
  end
  
  def play
    return if !@_iconbitmap
    @_iconbitmap.play
    self.bitmap = @_iconbitmap.bitmap
  end
  
  def finished?
    return true if !@_iconbitmap
    return @_iconbitmap.finished?
  end
  
  def reversed=(value)
    return if !@_iconbitmap
    @_iconbitmap.reversed = value
  end
  
  
  #-----------------------------------------------------------------------------
  # Aliased to set Pokemon property and update the animation.
  #-----------------------------------------------------------------------------
  alias animated_setPokemonBitmap setPokemonBitmap
  def setPokemonBitmap(pokemon, back = false)
    animated_setPokemonBitmap(pokemon, back)
    @pkmn = pokemon
    @_iconbitmap.setPokemon(@pkmn, back)
    @_iconbitmap.update_pokemon_sprite
    pbSetDisplay
  end
  
  alias animated_setPokemonBitmapSpecies setPokemonBitmapSpecies
  def setPokemonBitmapSpecies(pokemon, species, back = false)
    animated_setPokemonBitmapSpecies(pokemon, species, back)
    @pkmn = pokemon
    @_iconbitmap.setPokemon(@pkmn, back, nil, species)
    @_iconbitmap.update_pokemon_sprite
    pbSetDisplay
  end
  
  alias animated_setSpeciesBitmap setSpeciesBitmap
  def setSpeciesBitmap(species, gender = 0, form = 0, shiny = false, shadow = false, back = false, egg = false)
    animated_setSpeciesBitmap(species, gender, form, shiny, shadow, back, egg)
    species_id = GameData::Species.get_species_form(species, form).id
    pbSetDisplay([], species_id, back)
  end
  
  alias animated_update update
  def update
    @_iconbitmap.update_pokemon_sprite if animated?
    animated_update
  end
  
  #-----------------------------------------------------------------------------
  # Specifically used for displaying sprites in the Summary (no back sprite scaling).
  #-----------------------------------------------------------------------------
  def setSummaryBitmap(pkmn, back = false)
    @_iconbitmap&.dispose
    filename = GameData::Species.sprite_filename(
      pkmn.species, pkmn.form, pkmn.gender, pkmn.shiny?, pkmn.shadowPokemon?, back, pkmn.egg?)
    if filename
      @pkmn = pkmn
      bitmap = DeluxeBitmapWrapper.new(filename, [Settings::FRONT_BATTLER_SPRITE_SCALE, 1])
      bitmap.compile_strip(@pkmn, back)
      bitmap.setPokemon(@pkmn, back)
      bitmap.update_pokemon_sprite
      @_iconbitmap = bitmap
      self.bitmap = @_iconbitmap.bitmap
      self.color = Color.new(0, 0, 0, 0)
      self.set_plugin_pattern(@pkmn)
      changeOrigin
    else
      @_iconbitmap = nil
      self.bitmap = nil
    end
    pbSetDisplay
  end
  
  #-----------------------------------------------------------------------------
  # Generates a shadow sprite cast by the inputted Pokemon.
  #-----------------------------------------------------------------------------
  def setShadowBitmap(pkmn_sprite, back = false)
    @pkmn = pkmn_sprite.pkmn
    @_iconbitmap&.dispose
    @_iconbitmap = (pkmn) ? GameData::Species.sprite_bitmap_from_pokemon(pkmn, back) : nil
    self.bitmap = (@_iconbitmap) ? @_iconbitmap.bitmap : nil
    return if !@_iconbitmap
    setOffset
    self.color = Color.black
    self.opacity = 100
    metrics = GameData::SpeciesMetrics.get_species_form(@pkmn.species, @pkmn.form, @pkmn.female?)
    self.visible = false if !metrics.shows_shadow?(back)
    shadow_size = metrics.shadow_size
    shadow_size -= 1 if shadow_size > 0
    self.zoom_x = pkmn_sprite.zoom_x + (shadow_size * 0.1)
    self.zoom_y = pkmn_sprite.zoom_y * 0.25 + (shadow_size * 0.025)
  end
  
  #-----------------------------------------------------------------------------
  # Generates a shadow sprite for a species.
  #-----------------------------------------------------------------------------
  def setSpeciesShadowBitmap(species, form = 0, female = false, shiny = false, shadow = false, dynamax = false, back = false)
    @_iconbitmap&.dispose
    @_iconbitmap = GameData::Species.sprite_bitmap(species, form, ((female) ? 1 : 0), shiny, shadow, back)
    self.bitmap = (@_iconbitmap) ? @_iconbitmap.bitmap : nil
    return if !@_iconbitmap
    setOffset
    self.color = Color.black
    self.opacity = 100
    metrics = GameData::SpeciesMetrics.get_species_form(species, form, female)
    self.visible = false if !metrics.shows_shadow?(back)
    shadow_size = metrics.shadow_size
    shadow_size -= 1 if shadow_size > 0
    self.zoom_x = (dynamax ? 1.5 : 1) + (shadow_size * 0.1)
    self.zoom_y = (dynamax ? 1.5 : 1) * 0.25 + (shadow_size * 0.025)
  end
  
  #-----------------------------------------------------------------------------
  # Utility for determining how to display sprites in various UI's.
  #-----------------------------------------------------------------------------
  def pbSetDisplay(params = [], species = nil, back = false)
    @display_values = params if !@display_values && !params.empty?
    return if !@_iconbitmap || !@display_values
    setOffset
    v = @display_values.clone
    self.x = v[0] || 0
    self.y = v[1] || 0
    offset = findCenter(self.bitmap)
    sp_metrics = Settings::POKEMON_UI_METRICS
    species_offset = (species) ? sp_metrics[species] : sp_metrics[@pkmn.species_data.id]
    if species_offset
      offset[0] = (back) ? (offset[0] - species_offset[0]) : (offset[0] + species_offset[0])
      offset[1] += species_offset[1]
    end
    (self.mirror) ? self.x -= offset[0] : self.x += offset[0]
    self.y += offset[1]
    if Settings::CONSTRICT_POKEMON_SPRITES
      width, height = self.bitmap.width, self.bitmap.height
      v[2] += (v[2] * self.zoom_x * 0.6).ceil if v[2] && self.zoom_x != 1
      v[3] += (v[3] * self.zoom_y * 0.6).ceil if v[3] && self.zoom_y != 1
      c_x = v[2] || width
      if width < c_x
        @_iconbitmap.constrict_x += offset[0] if offset[0] < 0
        @_iconbitmap.constrict_w = (offset[0] < 0) ? (width + -offset[0] * 2) : (width + offset[0] * 2)
      else
        @_iconbitmap.constrict_x = ((width - c_x) / 2.0).ceil + -offset[0]
        @_iconbitmap.constrict_w = c_x
      end
      c_y = v[3] || v[2] || height
      if height < c_y
        @_iconbitmap.constrict_y += offset[1] if offset[1] < 0
        @_iconbitmap.constrict_h = (offset[1] < 0) ? (height + -offset[1] * 2) : (height + offset[1] * 2)
      else
        @_iconbitmap.constrict_y = ((height - c_y) / 2.0).ceil + -offset[1]
        @_iconbitmap.constrict_h = c_y
      end
    end
    self.update
  end
end


################################################################################
#
# Pokemon icon sprites (Pokemon)
#
################################################################################

class PokemonIconSprite < Sprite
  #-----------------------------------------------------------------------------
  # Rewritten to include Super Shiny hues.
  #-----------------------------------------------------------------------------
  def pokemon=(value)
    @pokemon = value
    @animBitmap&.dispose
    @animBitmap = nil
    if !@pokemon
      self.bitmap = nil
      @current_frame = 0
      return
    end
    hue = 0
    if @pokemon.super_shiny?
      metrics = GameData::SpeciesMetrics.get_species_form(@pokemon.species, @pokemon.form, @pokemon.female?)
      hue = metrics.sprite_super_hue
    end
    filename = GameData::Species.icon_filename_from_pokemon(value)
    @animBitmap = AnimatedBitmap.new(filename, hue)
    self.bitmap = @animBitmap.bitmap
    self.src_rect.width  = @animBitmap.height
    self.src_rect.height = @animBitmap.height
    self.set_plugin_icon_pattern
    @frames_count = @animBitmap.width / @animBitmap.height
    @current_frame = 0 if @current_frame >= @frames_count
    changeOrigin
  end
end


################################################################################
#
# Pokemon icon sprites (Species)
#
################################################################################

class PokemonSpeciesIconSprite < Sprite
  #-----------------------------------------------------------------------------
  # Rewritten to include Super Shiny hues.
  #-----------------------------------------------------------------------------
  def refresh
    @animBitmap&.dispose
    @animBitmap = nil
    shiny = (@shiny && @shiny != 0)
    bitmapFileName = GameData::Species.icon_filename(@species, @form, @gender, shiny)
    return if !bitmapFileName
    hue = 0
    if @shiny.is_a?(Integer) && @shiny >= 2
      metrics = GameData::SpeciesMetrics.get_species_form(@species, @form, @gender == 1)
      hue = metrics.sprite_super_hue
    end
    @animBitmap = AnimatedBitmap.new(bitmapFileName, hue)
    self.bitmap = @animBitmap.bitmap
    self.src_rect.width  = @animBitmap.height
    self.src_rect.height = @animBitmap.height
    @frames_count = @animBitmap.width / @animBitmap.height
    @current_frame = 0 if @current_frame >= @frames_count
    changeOrigin
  end
end


################################################################################
#
# Pokemon icon sprites (Storage)
#
################################################################################

class PokemonBoxIcon < IconSprite
  #-----------------------------------------------------------------------------
  # Rewritten to include Super Shiny hues.
  #-----------------------------------------------------------------------------
  def refresh
    return if !@pokemon
    hue = 0
    if @pokemon.super_shiny?
      metrics = GameData::SpeciesMetrics.get_species_form(@pokemon.species, @pokemon.form, @pokemon.female?)
      hue = metrics.sprite_super_hue
    end
    self.setBitmap(GameData::Species.icon_filename_from_pokemon(@pokemon), hue)
    self.src_rect = Rect.new(0, 0, self.bitmap.height, self.bitmap.height)
    self.set_shadow_pattern(@pokemon)
  end
end


################################################################################
#
# Sprite patterns applied for status conditions.
#
################################################################################

class Sprite
  attr_accessor :pattern_pulse
  attr_accessor :last_frame
  
  def apply_status_pattern(pokemon)
    return if !self.pattern.nil?
    return if pokemon.status == :NONE
    status = pokemon.status
    status = :FROZEN if status == :FROSTBITE
    path = Settings::DELUXE_GRAPHICS_PATH + "Status patterns/" + status.to_s
    return if !pbResolveBitmap(path)
    self.pattern = Bitmap.new(path)
    self.pattern_opacity = 60
    self.pattern_pulse = 1
    self.pattern_type = :status
    self.last_frame = 0
  end

  def set_status_pattern(pokemon)
    return if !pokemon
    return if pokemon.shadowPokemon?
    return if pokemon.dynamax?
    return if pokemon.tera?
    if pokemon.status != :NONE
      apply_status_pattern(pokemon)
    else
      clear_status_pattern
    end
  end
  
  def clear_status_pattern
    return if self.pattern_type != :status
    self.pattern = nil
    self.pattern_pulse = nil
    self.pattern_type = nil
    self.last_frame = nil
  end
  
  def update_status_pattern
    return if self.pattern_type != :status
    frame = (System.uptime / 0.05).to_i % 2
    return if frame == self.last_frame
    pulse = self.pattern_pulse
    self.last_frame = frame
    self.pattern_opacity += pulse
    if self.pattern_opacity >= 128
      self.pattern_pulse = -1
    elsif self.pattern_opacity <= 16
      self.pattern_pulse = 1
    end
  end
  
  #-----------------------------------------------------------------------------
  # Compatibility with other plugins that add sprite patterns.
  #-----------------------------------------------------------------------------
  alias status_set_plugin_pattern set_plugin_pattern
  def set_plugin_pattern(pokemon, override = false)
    status_set_plugin_pattern(pokemon, override)
    set_status_pattern(pokemon)
  end
  
  alias status_update_plugin_pattern update_plugin_pattern
  def update_plugin_pattern
    status_update_plugin_pattern
    update_status_pattern
  end
end