class Battle::Scene
  
  def sceneWait(numframes)
    numframes.times do
    pbGraphicsUpdate
    pbFrameUpdate
    Input.update
    end
  end
  
  def pbDeleteField()
    if @sprites["battle_bg"].visible
      for i in 0...32
        @sprites["battle_bg"].opacity -= 8
        @sprites["base_0"].opacity -= 8
        @sprites["base_1"].opacity -= 8
        sceneWait(1)
      end
    end
  end
  
  def pbSetFieldBackground()
    if @battle.field.terrain == :None
      pbCreateBackdropSprites
    else
      pbDeleteField()
      
      if @battle.field.terrain == :Grassy
        field = "Grassy Terrain"
        sound = "PRSFX- Grassy Terrain"
      elsif @battle.field.terrain == :Misty
        field = "Misty Terrain"
        sound = "PRSFX- Misty Terrain"
      elsif @battle.field.terrain == :Psychic
        field = "Psychic Terrain"
        sound = "PRSFX- Psychic Terrain"
      elsif @battle.field.terrain == :Electric
        field = "Electric Terrain"
        sound = "PRSFX- Electric Terrain"
      end
      @sprites["battle_bg"].setBitmap("Graphics/Animations/PRAS- #{field} BG")
      @sprites["battle_bg"].opacity = 0
      @sprites["battle_bg"].visible = true

      @sprites["base_0"].setBitmap("Graphics/Animations/#{field}playerbase")
      @sprites["base_0"].opacity = 0
      @sprites["base_0"].visible = true

      @sprites["base_1"].setBitmap("Graphics/Animations/#{field}enemybase")
      @sprites["base_1"].opacity = 0
      @sprites["base_1"].visible = true
      pbSEPlay(sound,80)
      for i in 0...32
        @sprites["battle_bg"].opacity += 8
        @sprites["base_0"].opacity += 8
        @sprites["base_1"].opacity += 8
        sceneWait(1)
      end
    end
  end
end

class Battle
  def pbStartBattleCore
    # Set up the battlers on each side
    sendOuts = pbSetUpSides
    @battleAI.create_ai_objects
    # Create all the sprites and play the battle intro animation
    @scene.pbStartBattle(self)
    # Show trainers on both sides sending out Pokémon
    pbStartBattleSendOut(sendOuts)
    # Weather announcement
    weather_data = GameData::BattleWeather.try_get(@field.weather)
    pbCommonAnimation(weather_data.animation) if weather_data
    case @field.weather
    when :Sun         then pbDisplay(_INTL("El sol pega fuerte."))
    when :Rain        then pbDisplay(_INTL("Sigue lloviendo."))
    when :Sandstorm   then pbDisplay(_INTL("La tormenta de arena arrecia."))
    when :Hail        then pbDisplay(_INTL("Sigue nevando."))
    when :HarshSun    then pbDisplay(_INTL("El sol es realmente abrasador."))
    when :HeavyRain   then pbDisplay(_INTL("La lluvia está siendo muy intensa."))
    when :StrongWinds then pbDisplay(_INTL("El aire está lleno de turbulencias."))
    when :ShadowSky   then pbDisplay(_INTL("El cielo está muy oscuro."))
    end
    # Terrain announcement
    terrain_data = GameData::BattleTerrain.try_get(@field.terrain)
    # pbCommonAnimation(terrain_data.animation) if terrain_data
    @scene.pbSetFieldBackground() 
    case @field.terrain
    when :Electric
      pbDisplay(_INTL("¡Una corriente eléctrica recorre el terreno de combate!"))
    when :Grassy
      pbDisplay(_INTL("¡La hierba cubre el terreno de combate!"))
    when :Misty
      pbDisplay(_INTL("¡La niebla cubre el terreno de combate!"))
    when :Psychic
      pbDisplay(_INTL("¡El terreno de combate se siente extraño!"))
    end
    # Abilities upon entering battle
    pbOnAllBattlersEnteringBattle
    # Main battle loop
    pbBattleLoop
  end


    def pbStartTerrain(user, newTerrain, fixedDuration = true)
        return if @field.terrain == newTerrain
        @field.terrain = newTerrain
        duration = (fixedDuration) ? 5 : -1
        if duration > 0 && user && user.itemActive?
          duration = Battle::ItemEffects.triggerTerrainExtender(user.item, newTerrain,
                                                                duration, user, self)
        end
        @field.terrainDuration = duration
        terrain_data = GameData::BattleTerrain.try_get(@field.terrain)
        #pbCommonAnimation(terrain_data.animation) if terrain_data
       
        
        case @field.terrain
        when :Electric
          pbDisplay(_INTL("¡Ha aparecido una corriente eléctrica por el terreno de combate!"))
        when :Grassy
          pbDisplay(_INTL("¡Ha empezado a cercer hierba por todo el terreno de combate!"))
        when :Misty
          pbDisplay(_INTL("¡Una densa niebla cubre el terreno de combate!"))
        when :Psychic
          pbDisplay(_INTL("¡El terreno de combate se ha vuelto extraño!"))
        end
        @scene.pbSetFieldBackground()
        pbHideAbilitySplash(user) if user
        # Check for abilities/items that trigger upon the terrain changing
        allBattlers.each { |b| b.pbAbilityOnTerrainChange }
        allBattlers.each { |b| b.pbItemTerrainStatBoostCheck }
    end

    def pbEOREndTerrain
      # Count down terrain duration
      @field.terrainDuration -= 1 if @field.terrainDuration > 0
      # Terrain wears off
      if @field.terrain != :None && @field.terrainDuration == 0
        case @field.terrain
        when :Electric
          pbDisplay(_INTL("¡La corriente eléctrica ha desaparecido del terreno de combate!"))
        when :Grassy
          pbDisplay(_INTL("¡La hierba ha desaparecido del terreno de combate!"))
        when :Misty
          pbDisplay(_INTL("¡La niebla ha desaparecido del terreno de combate!"))
        when :Psychic
          pbDisplay(_INTL("¡La sensación extraña ha desaparecido del terreno de combate!"))
        end
        @field.terrain = :None
        @scene.pbSetFieldBackground()
        allBattlers.each { |battler| battler.pbAbilityOnTerrainChange }
        # Start up the default terrain
        if @field.defaultTerrain != :None
          pbStartTerrain(nil, @field.defaultTerrain, false)
          allBattlers.each { |battler| battler.pbAbilityOnTerrainChange }
          allBattlers.each { |battler| battler.pbItemTerrainStatBoostCheck }
        end
        return if @field.terrain == :None
      end
      # Terrain continues
      terrain_data = GameData::BattleTerrain.try_get(@field.terrain)
      # pbCommonAnimation(terrain_data.animation) if terrain_data
      case @field.terrain
      when :Electric then pbDisplay(_INTL("Una corriente eléctrica recorre el terreno de combate."))
      when :Grassy   then pbDisplay(_INTL("La hierba cubre el terreno de combate."))
      when :Misty    then pbDisplay(_INTL("La niebla cubre el terreno de combate."))
      when :Psychic  then pbDisplay(_INTL("El terreno de combate se siente extraño."))
      end
    end
end
