#===============================================================================
# Edits species game data to allow for animated sprite properties.
#===============================================================================
module GameData
  #=============================================================================
  # Species metrics.
  #=============================================================================
  class SpeciesMetrics
    attr_reader   :female
    attr_accessor :shadow_sprite, :animation_speed, :super_shiny_hue
	  
    SCHEMA["SectionName"]    = [:id,              "eVS", :Species, 0]
    SCHEMA["BackSprite"]     = [:back_sprite,     "iiI"]
    SCHEMA["FrontSprite"]    = [:front_sprite,    "iiI"]
    SCHEMA["ShadowSize"]     = [:shadow_size,     "i"]
    SCHEMA["ShadowSprite"]   = [:shadow_sprite,   "iii"]
    SCHEMA["AnimationSpeed"] = [:animation_speed, "uU"]
    SCHEMA["SuperShinyHue"]  = [:super_shiny_hue, "i"]
	
    #---------------------------------------------------------------------------
    # Aliased to initialize new schema data.
    #---------------------------------------------------------------------------
    alias animated_initialize initialize
    def initialize(hash)
      animated_initialize(hash)
      @female          = hash[:female]          || false
      @shadow_size     = hash[:shadow_size]     || 1
      @shadow_sprite   = hash[:shadow_sprite]   || [0, 0, 0]
      @animation_speed = hash[:animation_speed] || [2, 2]
      @super_shiny_hue = hash[:super_shiny_hue] || 0
      @randomized_hue  = (1 + rand(7)) * 45
    end
    
    #---------------------------------------------------------------------------
    # Rewritten to account for female sprites having separate metrics.
    #---------------------------------------------------------------------------
    def self.get_species_form(species, form, female = false)
      return nil if !species || !form
      validate species => [Symbol, String]
      validate form => Integer
      raise _INTL("Undefined species {1}.", species) if !GameData::Species.exists?(species)
      species = species.to_sym if species.is_a?(String)
      sp_data = GameData::Species.get_species_form(species, form)
      gender = (female && sp_data.has_gendered_sprites?) ? "_female" : ""
      if form > 0
        trial = sprintf("%s_%d%s", species, form, gender).to_sym
        if !DATA.has_key?(trial)
          self.register({:id => species}) if !DATA[species]
          if species == :ALCREMIE && DATA.has_key?(:ALCREMIE_7)
            base_data = DATA[:ALCREMIE_7]
          else
            base_data = DATA[species]
          end
          self.register({
            :id                    => trial,
            :species               => species,
            :form                  => form,
            :female                => female,
            :back_sprite           => base_data.back_sprite.clone,
            :front_sprite          => base_data.front_sprite.clone,
            :front_sprite_altitude => base_data.front_sprite_altitude,
            :shadow_x              => base_data.shadow_x,
            :shadow_size           => base_data.shadow_size,
            :shadow_sprite         => base_data.shadow_sprite.clone,
            :animation_speed       => base_data.animation_speed.clone,
            :super_shiny_hue       => base_data.super_shiny_hue
          })
        end
        return DATA[trial]
      else
        trial = sprintf("%s%s", species, gender).to_sym
      end
      if !DATA[trial]
        if female && sp_data.has_gendered_sprites?
          self.register({
            :id                    => trial,
            :species               => species,
            :form                  => form,
            :female                => true,
            :back_sprite           => DATA[species].back_sprite.clone,
            :front_sprite          => DATA[species].front_sprite.clone,
            :front_sprite_altitude => DATA[species].front_sprite_altitude,
            :shadow_x              => DATA[species].shadow_x,
            :shadow_size           => DATA[species].shadow_size,
            :shadow_sprite         => DATA[species].shadow_sprite.clone,
            :animation_speed       => DATA[species].animation_speed.clone,
            :super_shiny_hue       => DATA[species].super_shiny_hue
          })
        else
          self.register({:id => trial})
        end
      end 
      return DATA[trial]
    end
	
    #---------------------------------------------------------------------------
    # Rewritten to include new metrics for shadow sprites.
    #---------------------------------------------------------------------------
    def apply_metrics_to_sprite(sprite, index, shadow = false)
      if shadow
        if (index & 1) == 0
          sprite.x += (@back_sprite[0] * 2 + @shadow_sprite[0] * 2)
          sprite.y += (@back_sprite[1] * 2 + @shadow_sprite[1] * 2)
        else
          sprite.x += (@front_sprite[0] * 2 + @shadow_sprite[0] * 2)
          sprite.y += (@front_sprite[1] * 2 + @shadow_sprite[2] * 2)
        end
      elsif (index & 1) == 0
        sprite.x += @back_sprite[0] * 2
        sprite.y += @back_sprite[1] * 2
      else
        sprite.x += @front_sprite[0] * 2
        sprite.y += @front_sprite[1] * 2
        sprite.y -= @front_sprite_altitude * 2
      end
    end
	
    def apply_dynamax_metrics_to_sprite(sprite, index, shadow = false)
      if shadow
        if (index & 1) == 0
          sprite.x += (@dmax_back_sprite[0] * 2 + @shadow_sprite[0] * 2)
          sprite.y += (@dmax_back_sprite[1] * 2 + @shadow_sprite[1] * 2)
        else
          sprite.x += (@dmax_front_sprite[0] * 2 + @shadow_sprite[0] * 2)
          sprite.y += (@dmax_front_sprite[1] * 2 + @shadow_sprite[2] * 2)
        end
      elsif (index & 1) == 0
        sprite.x += @dmax_back_sprite[0] * 2
        sprite.y += @dmax_back_sprite[1] * 2
      else
        sprite.x += @dmax_front_sprite[0] * 2
        sprite.y += @dmax_front_sprite[1] * 2
      end
    end
	
    #---------------------------------------------------------------------------
    # Utilities for obtaining various metric data.
    #---------------------------------------------------------------------------
    def real_id
      return (@female) ? GameData::Species.get_species_form(@species, @form).id : @id
    end
	
    def back_sprite_scale
      return @back_sprite[2] || Settings::BACK_BATTLER_SPRITE_SCALE
    end
    
    def front_sprite_scale
      return @front_sprite[2] || Settings::FRONT_BATTLER_SPRITE_SCALE
    end
    
    def back_sprite_speed
      return @animation_speed[0] || 2
    end
    
    def front_sprite_speed
      return @animation_speed[1] || @animation_speed[0] || 2
    end
    
    def sprite_super_hue
      hue = @super_shiny_hue
      return hue if hue && hue != 0
      @randomized_hue = (1 + rand(7)) * 45 if !@randomized_hue
      return @randomized_hue
    end
    
    def get_random_hue
      @randomized_hue = (1 + rand(7)) * 45
      return @randomized_hue
    end
    
    def shows_shadow?(back = false)
      return false if @shadow_size == 0
      return false if back && !Settings::SHOW_PLAYER_SIDE_SHADOW_SPRITES
      return true
    end
    
    #---------------------------------------------------------------------------
    # Aliased for writing PBS files with new schema data.
    #---------------------------------------------------------------------------
    alias animated_get_property_for_PBS get_property_for_PBS
    def get_property_for_PBS(key)
      ret = animated_get_property_for_PBS(key)
      case key
      when "SectionName"
        ret = [species, (@form > 0) ? @form : nil, (@female) ? "female" : nil]
      when "BackSprite"
        ret = ret[0..1] if ret[2] && ret[2] == Settings::BACK_BATTLER_SPRITE_SCALE
      when "FrontSprite"
        ret = ret[0..1] if ret[2] && ret[2] == Settings::FRONT_BATTLER_SPRITE_SCALE
      when "ShadowSize"
        ret = nil if ret && ret == 1
      when "SuperShinyHue"
        ret = nil if ret == 0
      when "FrontSpriteAltitude", "ShadowX", "DmaxShadowX"
        ret = nil
      when "AnimationSpeed"
        if ret.length > 1
          ret = [ret[0]] if [nil, ret[0]].include?(ret[1])
          ret = [ret[1]] if [nil, ret[1]].include?(ret[0])
        end
        ret = nil if ret.length == 1 && ret[0] == 2
      end
      return ret
    end
  end
  
  #=============================================================================
  # Species files.
  #=============================================================================
  class Species
    #---------------------------------------------------------------------------
    # General sprite utilities.
    #---------------------------------------------------------------------------
    def has_gendered_sprites?; return has_flag?("HasGenderedSprites"); end
    
    def shows_shadow?(back = false)
      return false if back && !Settings::SHOW_PLAYER_SIDE_SHADOW_SPRITES
      metrics_data = GameData::SpeciesMetrics.get_species_form(@species, @form, @gender == 1)
      return metrics_data.shows_shadow?(back)
    end
    
    #---------------------------------------------------------------------------
    # Rewritten to consider female sprites with separate metrics.
    #---------------------------------------------------------------------------
    def apply_metrics_to_sprite(sprite, index, shadow = false)
      female = (sprite.pkmn) ? sprite.pkmn.female? : false
      metrics_data = GameData::SpeciesMetrics.get_species_form(@species, @form, female)
      metrics_data.apply_metrics_to_sprite(sprite, index, shadow)
    end
    
    #---------------------------------------------------------------------------
    # Used to obtain sprites for the Substitute doll.
    #---------------------------------------------------------------------------
    def self.substitute_sprite_bitmap(back = false)
      filename = "Graphics/Pokemon/substitute"
      filename += "_back" if back
      filename = pbResolveBitmap(filename)
      scale = (back) ? Settings::BACK_BATTLER_SPRITE_SCALE : Settings::FRONT_BATTLER_SPRITE_SCALE
      return (filename) ? DeluxeBitmapWrapper.new(filename, [scale, 0]) : nil
    end
  
    #---------------------------------------------------------------------------
    # Rewritten for obtaining animated sprite strips.
    #---------------------------------------------------------------------------
    def self.front_sprite_bitmap(species, form = 0, gender = 0, shiny = false, shadow = false)
      filename = self.front_sprite_filename(species, form, gender, shiny, shadow)
      sp_data = GameData::SpeciesMetrics.get_species_form(species, form, gender == 1)
      return (filename) ? DeluxeBitmapWrapper.new(filename, sp_data) : nil
    end
    
    def self.back_sprite_bitmap(species, form = 0, gender = 0, shiny = false, shadow = false)
      filename = self.back_sprite_filename(species, form, gender, shiny, shadow)
      sp_data = GameData::SpeciesMetrics.get_species_form(species, form, gender == 1)
      return (filename) ? DeluxeBitmapWrapper.new(filename, sp_data, true) : nil
    end
	
    def self.egg_sprite_bitmap(species, form = 0)
      filename = self.egg_sprite_filename(species, form)
      return (filename) ? DeluxeBitmapWrapper.new(filename, [1, 0]) : nil
    end

    def self.sprite_bitmap_from_pokemon(pkmn, back = false, species = nil)
      species = pkmn.species if !species
      species = GameData::Species.get(species).species
      return self.egg_sprite_bitmap(species, pkmn.form) if pkmn.egg?
      if back
        ret = self.back_sprite_bitmap(species, pkmn.form, pkmn.gender, pkmn.shiny?, pkmn.shadowPokemon?)
      else
        ret = self.front_sprite_bitmap(species, pkmn.form, pkmn.gender, pkmn.shiny?, pkmn.shadowPokemon?)
      end
      ret.compile_strip(pkmn, back)
      return ret
    end
  end
end

#===============================================================================
# Utility for quickly obtaining the super shiny hue value to apply to a Pokemon.
#===============================================================================
class Pokemon
  def super_shiny_hue
    return 0 if !super_shiny?
    metrics = GameData::SpeciesMetrics.get_species_form(@species, @form, @gender == 1)
    return metrics.sprite_super_hue
  end
end