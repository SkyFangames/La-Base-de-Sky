#===============================================================================
# * Pokegear - by LinKazamine and CynderHydra (Credits will be apreciated)
#===============================================================================
#
# This script is for Pokémon Essentials. It adds a themes the Pokégear.
#===============================================================================

class PokemonPhone_Scene
  def pbStartScene
    @sprites = {}
    # Create viewport
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    # Background
    addBackgroundPlane(@sprites, "bg", "Phone/bg", @viewport)
    @sprites["background"] = IconSprite.new(0, 0, @viewport)
    @sprites["background"].setBitmap("Graphics/UI/Pokegear/#{$PokemonSystem.pokegear}/phonebg")
    # List of contacts
    @sprites["list"] = Window_PhoneList.newEmpty(152, 32, Graphics.width - 142, Graphics.height - 80, @viewport)
    @sprites["list"].windowskin = nil
    # Rematch readiness icons
    if Phone.rematches_enabled
      @sprites["list"].page_item_max.times do |i|
        @sprites["rematch_#{i}"] = IconSprite.new(468, 62 + (i * 32), @viewport)
      end
    end
    # Phone signal icon
    @sprites["signal"] = IconSprite.new(Graphics.width - 32, 0, @viewport)
    if Phone::Call.can_make?
      @sprites["signal"].setBitmap("Graphics/UI/Phone/icon_signal")
    else
      @sprites["signal"].setBitmap("Graphics/UI/Phone/icon_nosignal")
    end
    # Title text
    @sprites["header"] = Window_UnformattedTextPokemon.newWithSize(
      _INTL("Teléfono"), 2, -18, 128, 64, @viewport
    )
    @sprites["header"].baseColor   = Color.new(248, 248, 248)
    @sprites["header"].shadowColor = Color.black
    @sprites["header"].windowskin = nil
    # Info text about all contacts
    @sprites["info"] = Window_AdvancedTextPokemon.newWithSize("", -8, 224, 180, 160, @viewport)
    @sprites["info"].windowskin = nil
    # Portrait of contact
    @sprites["icon"] = IconSprite.new(70, 102, @viewport)
    # Contact's location text
    @sprites["bottom"] = Window_AdvancedTextPokemon.newWithSize(
      "", 162, Graphics.height - 64, Graphics.width - 158, 64, @viewport
    )
    @sprites["bottom"].windowskin = nil
    # Start scene
    pbRefreshList
    pbFadeInAndShow(@sprites) { pbUpdate }
  end
end
