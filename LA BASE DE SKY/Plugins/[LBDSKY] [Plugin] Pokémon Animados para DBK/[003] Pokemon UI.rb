#===============================================================================
# Miscellaneous edits to various UI's for animated sprites.
#===============================================================================

#===============================================================================
# Options
#===============================================================================
# Adds setting in the Options menu to toggle sprite animations.
#-------------------------------------------------------------------------------
class PokemonSystem
  attr_accessor :animated_sprites
  
  alias animated_initialize initialize
  def initialize
    animated_initialize
    @animated_sprites = 0
  end
  
  def animated_sprites
    return @animated_sprites || 0
  end
  
  def animated_sprites=(value)
    @animated_sprites = 0 if !@animated_sprites
    @animated_sprites = value
  end
end

MenuHandlers.add(:options_menu, :animated_sprites, {
  "name"        => _INTL("Pokémon Animados"),
  "order"       => 35,
  "type"        => EnumOption,
  "parameters"  => [_INTL("Sí"), _INTL("No")],
  "description" => _INTL("Elige si quieres que los Pokémon estén animados."),
  "get_proc"    => proc { next $PokemonSystem.animated_sprites },
  "set_proc"    => proc { |value, _scene| $PokemonSystem.animated_sprites = value }
})

#===============================================================================
# Summary
#===============================================================================
# Auto-positions sprites in the Summary UI.
#-------------------------------------------------------------------------------
class PokemonSummary_Scene
  def pbFadeInAndShow(sprites, visiblesprites = nil)
    duration = 0.4
    col = Color.new(0, 0, 0, 0)
    if visiblesprites
      visiblesprites.each do |i|
        if i[1] && sprites[i[0]] && !pbDisposed?(sprites[i[0]])
          sprites[i[0]].visible = true
        end
      end
    end
    if @sprites["pokemon"]
      @sprites["pokemon"].display_values = [104, 206, 208, 164]
      @sprites["pokemon"].pbSetDisplay
    end
    pbDeactivateWindows(sprites) do
      timer_start = System.uptime
      loop do
        col.alpha = lerp(255, 0, duration, timer_start, System.uptime)
        pbSetSpritesToColor(sprites, col)
        (block_given?) ? yield : pbUpdateSpriteHash(sprites)
        break if col.alpha == 0
      end
    end
  end
end

#===============================================================================
# Pokedex
#===============================================================================
# Auto-positions sprites in the Pokedex UI's.
#-------------------------------------------------------------------------------
class PokemonPokedex_Scene
  def setIconBitmap(species)
    gender, form, _shiny = $player.pokedex.last_form_seen(species)
    @sprites["icon"].setSpeciesBitmap(species, gender, form, false)
    species_id = (species) ? GameData::Species.get_species_form(species, form).id : nil
    @sprites["icon"].pbSetDisplay([112, 196, 224, 216], species_id)
  end
end

class PokemonPokedexInfo_Scene
  alias animated_pbUpdateDummyPokemon pbUpdateDummyPokemon
  def pbUpdateDummyPokemon
    animated_pbUpdateDummyPokemon
    species_id = GameData::Species.get_species_form(@species, @form).id
    @sprites["infosprite"].pbSetDisplay([104, 136, 208, 200], species_id)
    @sprites["formfront"].pbSetDisplay([130, 158, 200, 196], species_id) if @sprites["formfront"]
    if @sprites["formback"] && @sprites["formfront"]
      sp_data = GameData::SpeciesMetrics.get_species_form(@species, @form, @gender == 1)
      if sp_data.back_sprite_scale != sp_data.front_sprite_scale
        zoomX = sp_data.front_sprite_scale.to_f / sp_data.back_sprite_scale
        zoomY = sp_data.front_sprite_scale.to_f / sp_data.back_sprite_scale
        @sprites["formback"].zoom_x = zoomX
        @sprites["formback"].zoom_y = zoomY
      end
      @sprites["formback"].pbSetDisplay([382, 158, 200, 196], species_id, true)
    end
  end
end

#===============================================================================
# Storage
#===============================================================================
# Auto-Positions sprites in the PC Storage UI.
#-------------------------------------------------------------------------------
class PokemonStorageScene
  alias animated_pbUpdateOverlay pbUpdateOverlay
  def pbUpdateOverlay(*args)
    @sprites["pokemon"].pbSetDisplay([90, 134, 168])
    animated_pbUpdateOverlay(*args)
  end
end

#===============================================================================
# Evolution scene
#===============================================================================
# Auto-Positions sprites during the evolution scene.
#-------------------------------------------------------------------------------
class PokemonEvolutionScene
  alias animated_set_up_animation set_up_animation
  def set_up_animation
    x, y = @sprites["rsprite1"].x, @sprites["rsprite1"].y
    @sprites["rsprite1"].pbSetDisplay([x, y])
    @sprites["rsprite2"].pbSetDisplay([x, y], @newspecies)
    animated_set_up_animation
  end
end

#===============================================================================
# Utilities
#===============================================================================
# Used in calculating auto-positioning for sprites in various UI's.
#-------------------------------------------------------------------------------
def findCenter(bitmap)
  return [0, 0] if !bitmap
  width = bitmap.width
  height = bitmap.height
  coords = []
  4.times do |i|
    a1 = (i <= 1) ? width : height
    a2 = (i >= 2) ? height : width
    (1..a1).each do |p1|
      break if coords[i]
      a2.times do |p2|
        if i.even?
          pixels = (i <= 1) ? [p1, p2] : [p2, p1]
          next if bitmap.get_pixel(*pixels).alpha <= 0
          coords[i] = p1
          break
        else
          pixels = (i <= 1) ? [a1 - p1, p2] : [p2, a1 - p1]
          next if bitmap.get_pixel(*pixels).alpha <= 0
          coords[i] = p1 - 1
          break
        end
      end
    end
  end
  offsetX = ((coords[1] - coords[0]) / 2).ceil
  offsetY = ((coords[3] - coords[2]) / 2).ceil
  return [offsetX, offsetY]
end