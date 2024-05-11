#===============================================================================
# * Watch in the Pokegear Menu - by FL (Credits will be apreciated)
#===============================================================================
#
# This script is for Pokémon Essentials. It adds a watch in the Pokégear menu.
# Requires FL's Watch in the Pokegear script.
#===============================================================================

if PluginManager.installed?("Pokegear Watch")

class PokemonPokegear_Scene
  USE_PM_AM = false # Make it false to use European format
  SHOW_SECONDS = true # Make it false to won't show the seconds
  SHOW_WEEKDAY_NAME = true # Make it false to won't show weekday name

  if method_defined?(:update) # to support on older versions
    alias :_old_fl_watch_update :update
    def update
      refresh_date
      _old_fl_watch_update
    end
  else
    alias :_old_fl_watch_update :pbUpdate
    def pbUpdate
      refresh_date
      _old_fl_watch_update
    end
  end
  
  def initialize_watch
    @sprites["watch"] = IconSprite.new(0,0,@viewport)
    @sprites["watch"].setBitmap("Graphics/Pictures/Pokegear/#{$PokemonSystem.pokegear}/watch")
    @sprites["watch"].x = (Graphics.width - @sprites["watch"].bitmap.width)/2
    @sprites["overlay"] = BitmapSprite.new(
      Graphics.width,Graphics.height,@viewport
    )
    pbSetSystemFont(@sprites["overlay"].bitmap)
    refresh_date
  end
  
  def refresh_date
    new_date = pbGetTimeNow.strftime(time_format)
    return false if @date_string == new_date
    @date_string = new_date  
    @sprites["overlay"].bitmap.clear
    PokegearWatchBridge.drawTextPositions(@sprites["overlay"].bitmap, [[
      @date_string,Graphics.width/2,4,2,
      Color.new(248, 248, 248),Color.new(40, 40, 40)
    ]])
    return true
  end

  def time_format
    ret = "%M"
    ret +=":%S" if SHOW_SECONDS
    ret = USE_PM_AM ? "%I:#{ret} %p" : "%H:#{ret}"
    ret = "%A "+ret if SHOW_WEEKDAY_NAME
    return ret
  end
end

class PokemonPokegearTheme_Scene
  USE_PM_AM = false # Make it false to use European format
  SHOW_SECONDS = true # Make it false to won't show the seconds
  SHOW_WEEKDAY_NAME = true # Make it false to won't show weekday name

  if method_defined?(:update) # to support on older versions
    alias :_old_fl_watch_update :update
    def update
      refresh_date
      _old_fl_watch_update
    end
  else
    alias :_old_fl_watch_update :pbUpdate
    def pbUpdate
      refresh_date
      _old_fl_watch_update
    end
  end
  
  def initialize_watch
    @sprites["watch"] = IconSprite.new(0,0,@viewport)
    @sprites["watch"].setBitmap("Graphics/Pictures/Pokegear/#{$PokemonSystem.pokegear}/watch")
    @sprites["watch"].x = (Graphics.width - @sprites["watch"].bitmap.width)/2
    @sprites["overlay"] = BitmapSprite.new(
      Graphics.width,Graphics.height,@viewport
    )
    pbSetSystemFont(@sprites["overlay"].bitmap)
    refresh_date
  end
  
  def refresh_date
    new_date = pbGetTimeNow.strftime(time_format)
    return false if @date_string == new_date
    @date_string = new_date  
    @sprites["overlay"].bitmap.clear
    PokegearWatchBridge.drawTextPositions(@sprites["overlay"].bitmap, [[
      @date_string,Graphics.width/2,4,2,
      Color.new(248, 248, 248),Color.new(40, 40, 40)
    ]])
    return true
  end

  def time_format
    ret = "%M"
    ret +=":%S" if SHOW_SECONDS
    ret = USE_PM_AM ? "%I:#{ret} %p" : "%H:#{ret}"
    ret = "%A "+ret if SHOW_WEEKDAY_NAME
    return ret
  end
end

end
