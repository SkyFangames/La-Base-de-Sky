#===============================================================================
# Continuous Weather Animations Plugin
# Makes weather animations play continuously during battle
#===============================================================================

module ContinuousWeatherSettings
  ENABLED = true
  # How often to restart weather animations (in frames, 60 = 1 second)
  ANIMATION_RESTART_INTERVAL = 600  # 10 seconds
  
  # Weather types that should NOT use continuous animation (keep original end-of-turn behavior)
  EXCLUDED_WEATHER_TYPES = []

  VOLUME = 50 # Volume for weather sound effects (0-100)
end

class Battle::Scene
  # Add our weather system to the battle scene initialization
  alias cwas_pbInitSprites pbInitSprites
  def pbInitSprites
    cwas_pbInitSprites
    pbCreateWeatherOverlay if ContinuousWeatherSettings::ENABLED
  end

  # Add weather disposal to sprite cleanup
  alias cwas_pbDisposeSprites pbDisposeSprites
  def pbDisposeSprites
    cwas_pbDisposeSprites
    pbDisposeWeather if ContinuousWeatherSettings::ENABLED
  end

  # Add weather updates to frame updates
  alias cwas_pbFrameUpdate pbFrameUpdate
  def pbFrameUpdate(cw = nil)
    cwas_pbFrameUpdate(cw)
    pbUpdateWeather if ContinuousWeatherSettings::ENABLED
  end

  def pbCreateWeatherOverlay
    # Initialize continuous weather animation system
    @continuousWeatherActive = false
    @currentWeatherAnimation = nil
    @weatherAnimationPlayer = nil
    @weatherAnimationTimer = 0
    @weatherAnimationInterval = ContinuousWeatherSettings::ANIMATION_RESTART_INTERVAL
  end

  def pbStartContinuousWeather(battleWeather)
    return if !ContinuousWeatherSettings::ENABLED
    return if battleWeather == :None || battleWeather.nil?
    return if battleWeather == @currentWeatherType
    
    # Check if this weather type should be excluded
    if ContinuousWeatherSettings::EXCLUDED_WEATHER_TYPES.include?(battleWeather)
      return
    end
    
    
    # Stop any existing weather first
    pbStopContinuousWeather if @continuousWeatherActive
    
    # Get the animation name for this weather
    weather_data = GameData::BattleWeather.try_get(battleWeather)
    if !weather_data || !weather_data.animation
      return
    end
    
    @currentWeatherType = battleWeather
    @currentWeatherAnimation = weather_data.animation
    @continuousWeatherActive = true
    @weatherAnimationTimer = 0
    
    # Start the first weather animation immediately
    pbStartWeatherAnimation
  end

  def pbStopContinuousWeather
    return if !ContinuousWeatherSettings::ENABLED
    return if !@continuousWeatherActive

    # Dispose the current animation player if it exists
    if @weatherAnimationPlayer
      @weatherAnimationPlayer.dispose
      @weatherAnimationPlayer = nil
    end

    @continuousWeatherActive = false
    @currentWeatherType = :None
    @currentWeatherAnimation = nil
    @weatherAnimationTimer = 0
  end

  def pbStartWeatherAnimation
    return if !ContinuousWeatherSettings::ENABLED
    return if !@currentWeatherAnimation
    
    # Load the animation just like pbCommonAnimation does
    animations = pbLoadBattleAnimations
    if !animations
      return
    end
    
    animation = nil
    animations.each do |a|
      next if !a || a.name != "Common:" + @currentWeatherAnimation
      animation = a
      break
    end
    if !animation
      return
    end
    
    # Dispose previous animation player if it exists
    @weatherAnimationPlayer&.dispose
    
    # Create animation player using the scene (same as original approach)
    animation.volume = ContinuousWeatherSettings::VOLUME if ContinuousWeatherSettings::VOLUME
    @weatherAnimationPlayer = PBAnimationPlayerX.new(animation, nil, nil, self, false)
    
    # Start the animation
    @weatherAnimationPlayer.start
    @weatherAnimationTimer = 0
  end

  def pbUpdateWeather
    return if !ContinuousWeatherSettings::ENABLED
    return if !@continuousWeatherActive
    
    @weatherAnimationTimer += 1
    # Update the current animation player
    if @weatherAnimationPlayer && !@weatherAnimationPlayer.animDone?
      @weatherAnimationPlayer.update
    end
    
    # Check if we need to restart the animation
    if !@weatherAnimationPlayer || @weatherAnimationPlayer.animDone? || @weatherAnimationTimer >= @weatherAnimationInterval
      pbStartWeatherAnimation
    end
  end

  def pbDisposeWeather
    return if !ContinuousWeatherSettings::ENABLED
    pbStopContinuousWeather
  end
end

#===============================================================================
# Battle class modifications
#===============================================================================
class Battle
  # Hook into weather starting to begin continuous animations
  alias cwas_pbStartWeather pbStartWeather
  def pbStartWeather(user, newWeather, fixedDuration = false, showAnim = true)
    cwas_pbStartWeather(user, newWeather, fixedDuration, showAnim)
    # Start continuous weather animation
    @scene.pbStartContinuousWeather(@field.weather) if @field.weather != :None && ContinuousWeatherSettings::ENABLED
  end

  alias cwas_pbStartBattleCore pbStartBattleCore
  def pbStartBattleCore(battle_loop = true)
    cwas_pbStartBattleCore(false)
    @scene.pbStartContinuousWeather(@field.weather) if @field.weather != :None && ContinuousWeatherSettings::ENABLED
    pbBattleLoop if battle_loop
  end

  # Hook into end of round weather to stop continuous animation when weather ends
  alias cwas_pbEOREndWeather pbEOREndWeather
  def pbEOREndWeather(priority)
    old_weather = @field.weather
    
    # Call the original method
    cwas_pbEOREndWeather(priority)
    
    # If weather ended, stop continuous animation
    if old_weather != :None && @field.weather == :None
      @scene.pbStopContinuousWeather
    end
  end

  alias cwas_pbEndPrimordialWeather pbEndPrimordialWeather
  def pbEndPrimordialWeather
    old_weather = @field.weather
    cwas_pbEndPrimordialWeather
    if old_weather != :None && @field.weather == :None
      @scene.pbStopContinuousWeather
    end
  end

end