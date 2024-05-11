#===============================================================================
# Settings.
#===============================================================================
module Settings
  #-----------------------------------------------------------------------------
  # Graphics path
  #-----------------------------------------------------------------------------
  # Stores the path name for the graphics utilized by this plugin.
  #-----------------------------------------------------------------------------
  POKEDEX_DATA_PAGE_GRAPHICS_PATH = "Graphics/Plugins/Pokedex Data Page/"
  
  #-----------------------------------------------------------------------------
  # The switch number used to unlock the Data page in the Pokedex.
  #-----------------------------------------------------------------------------
  POKEDEX_DATA_PAGE_SWITCH = 60
  
  #-----------------------------------------------------------------------------
  # Toggles whether or not alternative Egg Group names should be displayed.
  #-----------------------------------------------------------------------------
  ALT_EGG_GROUP_NAMES = false
  
  #-----------------------------------------------------------------------------
  # List of regional names to check for to display for evolution methods.
  #-----------------------------------------------------------------------------
  REGIONAL_NAMES = ["Alola", "Galar", "Hisui", "Paldea"]
end


#===============================================================================
# Menu handler for the Pokedex Data page.
#===============================================================================
UIHandlers.add(:pokedex, :page_data, { 
  "name"      => "DATA",
  "suffix"    => "data",
  "order"     => 40,
  #"condition" => proc { next $game_switches[Settings::POKEDEX_DATA_PAGE_SWITCH] },
  "layout"    => proc { |species, scene| scene.drawPageData }
})


#===============================================================================
# Various utilities and aliases required for setting up Data page displays.
#===============================================================================
class PokemonPokedexInfo_Scene
  #-----------------------------------------------------------------------------
  # Sets the coordinates for Pokemon family icons on the Data page.
  #-----------------------------------------------------------------------------
  ICONS_POS_Y         = 130
  ICONS_CENTER        = 369
  ICONS_OFFSET_DOUBLE = 54
  ICONS_LEFT_DOUBLE   = ICONS_CENTER - ICONS_OFFSET_DOUBLE + 2
  ICONS_RIGHT_DOUBLE  = ICONS_CENTER + ICONS_OFFSET_DOUBLE - 2
  ICONS_OFFSET_TRIPLE = 105
  ICONS_LEFT_TRIPLE   = ICONS_CENTER - ICONS_OFFSET_TRIPLE + 1
  ICONS_RIGHT_TRIPLE  = ICONS_CENTER + ICONS_OFFSET_TRIPLE - 1
  
  #-----------------------------------------------------------------------------
  # Sets the text color options for notes drawn on the Data page.
  #-----------------------------------------------------------------------------
  DATA_TEXT_TAGS = [
    shadowc3tag(Color.new(88, 88, 80),  Color.new(168, 184, 184)), # Black
    shadowc3tag(Color.new(232, 32, 16), Color.new(248, 168, 184)), # Red
    shadowc3tag(Color.new(0, 112, 248), Color.new(120, 184, 232)), # Blue
    shadowc3tag(Color.new(96, 176, 72), Color.new(174, 208, 144))  # Green
  ]
  
  #-----------------------------------------------------------------------------
  # Aliased for implementing custom UI elements.
  #-----------------------------------------------------------------------------
  alias modular_pbStartScene pbStartScene
  def pbStartScene(*args)
    @cursor        = :general
    @data_hash     = {}
    @moveList      = []
    @moveCommands  = []
    @moveListIndex = 0
    @viewingMoves  = false
    @forceRefresh  = false
    if PluginManager.installed?("[DBK] Z-Power")
      @zcrystals = []
      GameData::Item.each { |item| @zcrystals.push(item) if item.is_zcrystal? }
    end
    if PluginManager.installed?("[DBK] Dynamax")
      @maxmoves = GameData::Move.get_generic_dynamax_moves
    end
    modular_pbStartScene(*args)
    @typebitmap2 = AnimatedBitmap.new(_INTL("Graphics/UI/types"))
    3.times do |i|
      @sprites["familyicon#{i}"] = PokemonSpeciesIconSprite.new(nil, @viewport)
      @sprites["familyicon#{i}"].setOffset(PictureOrigin::CENTER)
      @sprites["familyicon#{i}"].x = ICONS_CENTER
      @sprites["familyicon#{i}"].y = ICONS_POS_Y
      @sprites["familyicon#{i}"].visible = false
    end
    @sprites["itemicon"] = ItemIconSprite.new(261, 200, nil, @viewport)
    @sprites["itemicon"].blankzero = true
    @sprites["leftarrow"] = AnimatedSprite.new("Graphics/UI/left_arrow", 8, 40, 28, 2, @viewport)
    @sprites["leftarrow"].x       = -2
    @sprites["leftarrow"].y       = 46
    @sprites["leftarrow"].visible = false
    @sprites["leftarrow"].play
    @sprites["rightarrow"] = AnimatedSprite.new("Graphics/UI/right_arrow", 8, 40, 28, 2, @viewport)
    @sprites["rightarrow"].x       = 220
    @sprites["rightarrow"].y       = 46
    @sprites["rightarrow"].visible = false
    @sprites["rightarrow"].play
    @sprites["movecmds"] = Window_CommandPokemon.new(@moveCommands, 32)
    @sprites["movecmds"].height = 32 * 5
    @sprites["movecmds"].visible = false
    @sprites["data_overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["data_overlay"].bitmap)
    @sprites["pokelist"] = PokemonDataPageSprite.new(@species, 0, @viewport)
    @sprites["pokelist"].visible = false
  end
  
  alias modular_pbEndScene pbEndScene
  def pbEndScene
    modular_pbEndScene
    @typebitmap2&.dispose
  end
  
  alias modular_drawPage drawPage
  def drawPage(page)
    pbResetFamilyIcons
    @sprites["itemicon"].item = nil        if @sprites["itemicon"]
    @sprites["data_overlay"].bitmap.clear  if @sprites["data_overlay"]
    modular_drawPage(page)
  end
  
  #-----------------------------------------------------------------------------
  # Allows for a custom action on the Data page when the USE key is pressed.
  #-----------------------------------------------------------------------------
  alias modular_pbPageCustomUse pbPageCustomUse
  def pbPageCustomUse(page_id)
    if page_id == :page_data
      pbDataPageMenu
      return true
    end
    return modular_pbPageCustomUse(page_id)
  end
  
  #-----------------------------------------------------------------------------
  # Utility for resetting family icon sprites.
  #-----------------------------------------------------------------------------
  def pbResetFamilyIcons
    3.times do |i|
      next if !@sprites["familyicon#{i}"]
      @sprites["familyicon#{i}"].visible = false
      @sprites["familyicon#{i}"].x = ICONS_CENTER
      @sprites["familyicon#{i}"].y = ICONS_POS_Y
    end
  end
  
  #-----------------------------------------------------------------------------
  # Utility for determining if a species has gender differences.
  #-----------------------------------------------------------------------------
  def gender_difference?(form)
    file1 = GameData::Species.front_sprite_filename(@species, form)
    file2 = GameData::Species.front_sprite_filename(@species, form, 1)
    return true if file1 != file2 
    species_data = GameData::Species.get_species_form(@species, form)
    return [_INTL("Macho"), _INTL("Hembra")].include?(species_data.form_name)
  end
  
  #-----------------------------------------------------------------------------
  # Rewritten to allow for forms with gender differences to appear.
  #-----------------------------------------------------------------------------
  def pbGetAvailableForms
    ret = []
    multiple_forms = false
    GameData::Species.each do |sp|
      next if sp.species != @species
      next if sp.form != 0 && (!sp.real_form_name || sp.real_form_name.empty?)
      next if sp.pokedex_form != sp.form
      multiple_forms = true if sp.form > 0
      if sp.single_gendered?
        real_gender = (sp.gender_ratio == :AlwaysFemale) ? 1 : 0
        next if !$player.pokedex.seen_form?(@species, real_gender, sp.form) && !Settings::DEX_SHOWS_ALL_FORMS
        real_gender = 2 if sp.gender_ratio == :Genderless
        ret.push([sp.form_name, real_gender, sp.form])
      elsif !gender_difference?(sp.form)
        2.times do |real_gndr|
          next if !$player.pokedex.seen_form?(@species, real_gndr, sp.form) && !Settings::DEX_SHOWS_ALL_FORMS
          ret.push([sp.form_name || _INTL("Forma Normal"), 0, sp.form])
          break
        end
      elsif sp.form_name == _INTL("Macho") || sp.form_name == _INTL("Hembra")
        next if !$player.pokedex.seen_form?(@species, sp.form, sp.form) && !Settings::DEX_SHOWS_ALL_FORMS
        ret.push([sp.form_name, sp.form, sp.form])
      else
        g = [_INTL("macho"), _INTL("Hembra")]
        2.times do |real_gndr|
          next if !$player.pokedex.seen_form?(@species, real_gndr, sp.form) && !Settings::DEX_SHOWS_ALL_FORMS
          form_name = (sp.form_name) ? sp.form_name + " " + g[real_gndr] : g[real_gndr]
          ret.push([form_name, real_gndr, sp.form]) 
        end
      end
    end
    ret.sort! { |a, b| (a[2] == b[2]) ? a[1] <=> b[1] : a[2] <=> b[2] }
    ret.each do |entry|
      if entry[0]
        entry[0] = "" if !multiple_forms && !gender_difference?(entry[2])
      else
        case entry[1]
        when 0 then entry[0] = _INTL("Macho")
        when 1 then entry[0] = _INTL("Hembra")
        else
          entry[0] = (multiple_forms) ? _INTL("Forma Normal") : _INTL("Sin Género")
        end
      end
      entry[1] = 0 if entry[1] == 2
    end
    return ret
  end
end


#===============================================================================
# Fix for shiny icons appearing when they shouldn't be if you have any installed.
#===============================================================================
class PokemonSpeciesIconSprite < Sprite
  alias _shinyfix_initialize initialize
  def initialize(*args)
    _shinyfix_initialize(*args)
    @shiny = false
    refresh
  end
end