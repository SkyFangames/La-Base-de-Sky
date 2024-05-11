#===============================================================================
# * Show Species Introdution - by FL (Credits will be apreciated)
#===============================================================================
#
# This script is for Pokémon Essentials. It shows a picture with the pokémon
# species in a border together with a message containing the name and kind, play
# it's cry and mark it as seen in pokédex. Good to make the starter selection
# event. 
#
#== INSTALLATION ===============================================================
#
# Put it above main OR convert into a plugin.
#
#== HOW TO USE =================================================================
#
# Use 'SpeciesIntro.new(sp).show', where sp is the species symbol.
#
#== NOTES ======================================================================
#
# You can look and change SpeciesIntro instance atributes, directly or by
# methods. This way you can change the sprite gender and other effects. Look at
# below examples:
#
#== EXAMPLES ===================================================================
#
# - Show Chikorita:
#
# SpeciesIntro.new(:CHIKORITA).show
#
# - Show shiny west Shellos, without registering at Pokédex as seen:
#
# SpeciesIntro.new(:SHELLOS_1).set_shiny(true).set_mark_as_seen(false).show
#
# - Show shiny Speed Deoxys, with custom message:
#
# si = SpeciesIntro.new(:DEOXYS)
# si.form = 3
# si.shiny = true
# si.message_complement = ".\nAn dangerous alien."
# si.show
#
#===============================================================================

if defined?(PluginManager) && !PluginManager.installed?("Show Species Introduction")
  PluginManager.register({                                                 
    :name    => "Show Species Introduction",                                        
    :version => "1.1",                                                     
    :link    => "https://www.pokecommunity.com/showthread.php?t=504992",             
    :credits => "FL"
  })
end

class SpeciesIntro
  attr_accessor :species
  attr_accessor :form
  attr_accessor :gender
  attr_accessor :shiny
  attr_accessor :shadow
  attr_accessor :mark_as_seen
  attr_accessor :message_complement
  
  def set_form(form)
    @form = form
    return self
  end
  
  def set_gender(gender)
    @gender = gender
    return self
  end
  
  def set_shiny(shiny)
    @shiny = shiny
    return self
  end
  
  def set_shadow(shadow)
    @shadow = shadow
    return self
  end
  
  def set_mark_as_seen(mark_as_seen)
    @mark_as_seen = mark_as_seen
    return self
  end

  def initialize(species)
    species_and_form = Bridge.species_and_form(species)
    @species = species_and_form[0]
    @form = species_and_form[1]
    @gender = 0
    @mark_as_seen = true
  end

  def name
    return Bridge.species_name(@species)
  end

  def category
    return Bridge.species_category(@species, @form)
  end
  
  def set_message_complement(message_complement)
    @message_complement = message_complement
    return self
  end
  
  def text_message
    ret = name
    ret += @message_complement || _INTL(". Pokémon {1}.", category)
    return ret
  end

  def create_picture_icon(bitmap)
    ret = PictureWindow.new(bitmap)
    if PluginManager.installed?("Sprites Animados")
      ret.width = ret.height
      ret.zoom_x = ret.zoom_x * 2
      ret.zoom_y = ret.zoom_y * 2
      ret.x = (Graphics.width/2)
      ret.x = ret.x/2
      ret.x -= (ret.width/2)
      ret.y = ((Graphics.height-96)/2)
      ret.y = ret.y/2
      ret.y -= (ret.height/2)
      #ret.y += 10
    else
      ret.x = (Graphics.width/2) - (ret.width/2)
      ret.y = ((Graphics.height-96)/2) - (ret.height/2)
    end
    return ret
  end

  def show
    if @mark_as_seen
      Bridge.register_as_seen(@species, @form, @gender, @shiny)
    end
    bitmap = Bridge.pokemon_front_sprite_filename(
      @species, @form, @gender, @shiny, @shadow
    )
    Bridge.play_cry(@species, @form)
    if bitmap # to prevent crashes
      iconwindow = create_picture_icon(bitmap)
      Bridge.message(text_message)
      iconwindow.dispose
    end
  end

  module Bridge
    module_function

    def major_version
      ret = 0
      if defined?(Essentials)
        ret = Essentials::VERSION.split(".")[0].to_i
      elsif defined?(ESSENTIALS_VERSION)
        ret = ESSENTIALS_VERSION.split(".")[0].to_i
      elsif defined?(ESSENTIALSVERSION)
        ret = ESSENTIALSVERSION.split(".")[0].to_i
      end
      return ret
    end

    MAJOR_VERSION = major_version

    def message(string, &block)
      return Kernel.pbMessage(string, &block) if MAJOR_VERSION < 20
      return pbMessage(string, &block)
    end

    def species_name(species)
      return PBSpecies.getName(species) if MAJOR_VERSION < 19
      return GameData::Species.get(species).name
    end

    def species_category(species, form)
      if MAJOR_VERSION < 19
        ret = pbGetMessage(
          MessageTypes::Kinds, fspecies_from_form_v18_minus(species, form)
        )
        ret ||= pbGetMessage(MessageTypes::Kinds, species)
        return ret
      end
      return GameData::Species.get_species_form(species, form).category
    end

    def species_and_form(species_full)
      return [getID(PBSpecies, species_full), 0] if MAJOR_VERSION < 17
      if MAJOR_VERSION < 19
        return pbGetSpeciesFromFSpecies(getID(PBSpecies, species_full))
      end
      species_form = GameData::Species.get_species_form(species_full, 0)
      return [species_form.species, species_form.form]
    end

    def pokemon_front_sprite_filename(species, form, gender, shiny, shadow)
      if MAJOR_VERSION < 19
        return pbCheckPokemonBitmapFiles([
          species, false, gender, shiny, form, shadow
        ])
      end
      return GameData::Species.front_sprite_filename(
        species, form, gender, shiny, shadow
      )
    end

    def register_as_seen(species, form, gender, shiny)
      if MAJOR_VERSION < 19
        $Trainer.seen[species]=true
        if MAJOR_VERSION >= 17
          pbSeenForm(fspecies_from_form_v18_minus(species,form))
        end
        return
      end
      (MAJOR_VERSION<20 ? $Trainer : $player).pokedex.register(
        species, gender, form, shiny
      )
    end

    def play_cry(species, form)
      if MAJOR_VERSION < 19
        pbPlayCry(species)
        return
      end
      GameData::Species.play_cry_from_species(species, form)
    end

    def fspecies_from_form_v18_minus(species, form)
      return species if MAJOR_VERSION < 17
      return pbGetFSpeciesFromForm(species, form)
    end
  end
end
