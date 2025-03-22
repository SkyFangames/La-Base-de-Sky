#########################################################
###                 Encounter list UI                 ###
### Based on the original resource by raZ and friends ###
#########################################################


# This is the name of a graphic in your Graphics/Pictures folder that changes the look of the UI
# If the graphic does not exist, you will get an error
WINDOWSKIN = "base.png"

# This hash allows you to define the names of your encounter types if you want them to be more logical
# E.g. "Surfing" instead of "Water"
# If missing, the script will use the encounter type names in GameData::EncounterTypes
USER_DEFINED_NAMES = {
:Land => "Hierba",
:LandDay => "Hierba (día)",
:LandNight => "Hierba (noche)",
:LandMorning => "Hierba (mañana)",
:LandAfternoon => "Hierba (medio día)", 
:LandEvening => "Hierba (atardecer)",
:Cave => "Cueva",
:CaveDay => "Cueva (día)",
:CaveNight => "Cueva (noche)",
:CaveMorning => "Cueva (mañana)",
:CaveAfternoon => "Cueva (medio día)",
:CaveEvening => "Cueva (atardecer)",
:Water => "Surfeando",
:WaterDay => "Surfeando (día)",
:WaterNight => "Surfeando (noche)",
:WaterMorning => "Surfeando (mañana)",
:WaterAfternoon => "Surfeando (medio día)",
:WaterEvening => "Surfeando (atardecer)",
:OldRod => "Pescando (Caña Vieja)",
:GoodRod => "Pescando (Caña Buena)",
:SuperRod => "Pescando (Super Caña)",
:RockSmash => "Golpe Roca",
:HeadbuttLow => "Cabezazo (Raro)",
:HeadbuttHigh => "Cabezazo (Común)",
:BugContest => "Concurso de Bichos",
:PokeRadar => "PokéRadar"
}

# Remove the '#' from this line to use default encounter type names
#USER_DEFINED_NAMES = nil

SHOW_SHADOWS_FOR_UNSEEN_POKEMON = true

# Method that returns whether a specific form has been seen (any gender)
def seen_form_any_gender?(species, form)
  ret = false
  if $player.pokedex.seen_form?(species, 0, form) ||
     $player.pokedex.seen_form?(species, 1, form)
    ret = true
  end
  return ret
end

class EncounterList_Scene
  # Constructor method
  # Sets a handful of key variables needed throughout the script
  def initialize
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    mapid = $game_map.map_id
    @encounter_data = GameData::Encounter.get(mapid, $PokemonGlobal.encounter_version)
    if @encounter_data
      @encounter_tables = Marshal.load(Marshal.dump(@encounter_data.types))
      @max_enc, @eLength = getMaxEncounters(@encounter_tables)
    else
      @max_enc, @eLength = [1, 1]
    end
    @index = 0
  end

  # This gets the highest number of unique encounters across all defined encounter types for the map
  # It might sound weird, but this is needed for drawing the icons
  def getMaxEncounters(data)
    keys = data.keys
    a = []
    keys.each do |key|
      b = []
      arr = data[key]
      b.push(*arr.map { |item| item[1] })
      a.push(b.uniq.length)
    end
    return a.max, keys.length
  end

  # This method initiates the following:
  # Background graphics, text overlay, Pokémon sprites and navigation arrows
  def pbStartScene
    unless File.file?("Graphics/UI/EncounterUI/"+WINDOWSKIN)
      raise _INTL("Te faltan los gráficos para esta interfaz. Asegúrate de que la imágen está en la carpeta Graphics/UI/EncounterUI y que tiene el nombre correcto.")
    end

    #addBackgroundPlane(@sprites,"bg","EncounterUI/bg",@viewport)
    @sprites["bg"] = IconSprite.new(0, 0, @viewport)
    @sprites["bg"].setBitmap("Graphics/UI/EncounterUI/bg")
    @sprites["bg"].ox = @sprites["bg"].bitmap.width / 2
    @sprites["bg"].oy = @sprites["bg"].bitmap.height / 2
    @sprites["bg"].x = Graphics.width / 2
    @sprites["bg"].y = Graphics.height / 2
    

    @sprites["base"] = IconSprite.new(0, 0, @viewport)
    @sprites["base"].setBitmap("Graphics/UI/EncounterUI/#{WINDOWSKIN}")
    @sprites["base"].ox = @sprites["base"].bitmap.width / 2
    @sprites["base"].oy = @sprites["base"].bitmap.height / 2
    @sprites["base"].x = Graphics.width / 2
    @sprites["base"].y = Graphics.height / 2
    @sprites["base"].opacity = 200
    @sprites["locwindow"] = Window_AdvancedTextPokemon.new('')
    @sprites["locwindow"].viewport = @viewport
    @sprites["locwindow"].width = 512
    @sprites["locwindow"].height = 344
    @sprites["locwindow"].x = (Graphics.width - @sprites["locwindow"].width) / 2
    @sprites["locwindow"].y = (Graphics.height - @sprites["locwindow"].height) / 2
    @sprites["locwindow"].windowskin = nil
    @h = (Graphics.height - @sprites["base"].bitmap.height) / 2
    @w = (Graphics.width - @sprites["base"].bitmap.width) / 2
    @max_enc&.times do |i|
      @sprites["icon_#{i}"] = PokemonSpeciesIconSprite.new(nil, @viewport)
      @default_color = Color.new(@sprites["icon_#{i}"].color.red, @sprites["icon_#{i}"].color.green, @sprites["icon_#{i}"].color.blue, @sprites["icon_#{i}"].color.alpha)
      @sprites["icon_#{i}"].x = @w + 28 + 64 * (i % 7)
      @sprites["icon_#{i}"].y = @h + 100 + (i / 7) * 64
      @sprites["icon_#{i}"].visible = false
    end
    @sprites["rightarrow"] = AnimatedSprite.new('Graphics/UI/EncounterUI/right_arrow', 8, 40, 28, 2, @viewport)
    @sprites["rightarrow"].x = Graphics.width - @sprites["rightarrow"].bitmap.width
    @sprites["rightarrow"].y = Graphics.height / 2 - @sprites["rightarrow"].bitmap.height / 16
    @sprites["rightarrow"].visible = false
    @sprites["rightarrow"].play
    @sprites["leftarrow"] = AnimatedSprite.new("Graphics/UI/EncounterUI/left_arrow", 8, 40, 28, 2, @viewport)
    @sprites["leftarrow"].x = 0
    @sprites["leftarrow"].y = Graphics.height / 2 - @sprites["rightarrow"].bitmap.height / 16
    @sprites["leftarrow"].visible = false
    @sprites["leftarrow"].play
    @encounter_data ? drawPresent : drawAbsent
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  # Main function that controls the UI
  def pbEncounter
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::RIGHT) && @eLength > 1 && @index < @eLength - 1
        pbPlayCursorSE
        hideSprites
        @index += 1
        drawPresent
      elsif Input.trigger?(Input::LEFT) && @eLength > 1 && @index != 0
        pbPlayCursorSE
        hideSprites
        @index -= 1
        drawPresent
      elsif Input.trigger?(Input::USE) || Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        break
      end
    end
  end

  # Draw text and icons if map has encounters defined
  def drawPresent
    @sprites["rightarrow"].visible = @index < @eLength - 1
    @sprites["leftarrow"].visible = @index.positive?
    i = 0
    enc_array, curr_key = getEncData
    enc_array.each do |s|
      species_data = GameData::Species.get(s) # SI NO LO HE CAPTURADO
      
      # Reset sprite's visual properties before setting new ones
      @sprites["icon_#{i}"].tone = Tone.new(0, 0, 0, 0)
      @sprites["icon_#{i}"].color = @default_color
      @sprites["icon_#{i}"].pbSetParams(s, 0, species_data.form, false)
      
      if SHOW_SHADOWS_FOR_UNSEEN_POKEMON && !seen_form_any_gender?(s, species_data.form)
        @sprites["icon_#{i}"].color = Color.new(0, 0, 0)
      elsif SHOW_SHADOWS_FOR_UNSEEN_POKEMON && !$player.owned?(species_data) # SI NO LO HE CAPTURADO
        @sprites["icon_#{i}"].tone = Tone.new(0,0,0,255)
      end
      @sprites["icon_#{i}"].visible = true
      i += 1
    end
    # Get user-defined encounter name or default one if not present
    name = USER_DEFINED_NAMES ? USER_DEFINED_NAMES[curr_key] : GameData::EncounterType.get(curr_key).real_name
    loctext = _INTL("<ac><c2=7E105D08>{1}:</c2> <c2=43F022E8>{2}</c2></ac>", $game_map.name, name)
    loctext += sprintf("<al><c2=7FFF5EF7>Encuentros totales de la zona: %s</c2></al>",enc_array.length)
    loctext += sprintf("<c2=63184210>-----------------------------------------</c2>")
    @sprites["locwindow"].setText(loctext)
  end

  # Draw text if map has no encounters defined (e.g. in buildings)
  def drawAbsent
    loctext = _INTL("<ac><c2=7E105D08>{1}</c2></ac>", $game_map.name)
    loctext += sprintf("<al><c2=7FFF5EF7>Zona sin Pokémon salvajes</c2></al>")
    loctext += sprintf("<c2=63184210>-----------------------------------------</c2>")
    @sprites["locwindow"].setText(loctext)
  end

  # Method that returns an array of symbolic names for chosen encounter type on current map
  # Currently, ordered by appereance chance and then by national Pokédex number
  def getEncData
    curr_key = @encounter_tables.keys[@index]
    enc_array = []
    encounters = @encounter_tables[curr_key]
    if encounters
      enc_array = encounters.map { |e| [e[1], e[0]] }
      # Ordena por probabilidad de aparición en orden descendente
      enc_array.sort_by! { |e| 
        dexlist = pbGetDexList(e[0]) 
        dexnum = dexlist[0][dexlist[1]][:number] 
        [-e[1], dexnum] 
      }

      # Nos quedamos solo con el ID de la especie
      enc_array.map! { |e| e[0] }

      enc_array.uniq!
    end
    return enc_array, curr_key
  end

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  # Hide sprites
  def hideSprites
    @max_enc.times do |i|
      @sprites["icon_#{i}"].visible = false
    end
  end

  # Dipose stuff at the end
  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

class EncounterList_Screen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen
    @scene.pbStartScene
    @scene.pbEncounter
    @scene.pbEndScene
  end
end

ItemHandlers::UseFromBag.add(:RADAR, proc{ |item|
  scene = EncounterList_Scene.new
  screen = EncounterList_Screen.new(scene)
  screen.pbStartScreen
  next 1
})

ItemHandlers::UseInField.add(:RADAR, proc{ |item|
  scene = EncounterList_Scene.new
  screen = EncounterList_Screen.new(scene)
  screen.pbStartScreen
  next 1
})
