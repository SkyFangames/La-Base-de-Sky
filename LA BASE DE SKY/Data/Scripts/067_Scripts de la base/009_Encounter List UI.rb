#########################################################
###                 Encounter list UI                 ###
### Based on the original resource by raZ and friends ###
#########################################################


class EncounterListSettings
  # This is the name of a graphic in your Graphics/Pictures folder that changes the look of the UI
  # If the graphic does not exist, you will get an error
  WINDOWSKIN = "base.png"

  # Constantes de layout y posiciones (ajustar si cambia la resolución)
  ICONS_PER_ROW = 7         # Número de iconos por fila
  ICON_SPACING = 64         # Espacio (px) entre iconos horizontal y verticalmente
  ICON_LEFT_OFFSET = 28     # Desplazamiento X desde el borde izquierdo del panel base para los iconos
  ICON_TOP_OFFSET = 100     # Desplazamiento Y desde el borde superior del panel base para los iconos
  ARROW_Y_DIVISOR = 16      # Divisor aplicado a la altura del sprite de flecha para posicionarlo verticalmente

  # This hash allows you to define the names of your encounter types if you want them to be more logical
  # E.g. "Surfing" instead of "Water"
  # If missing, the script will use the encounter type names in GameData::EncounterTypes
  USER_DEFINED_NAMES = {
    :Land           => _INTL("Hierba"),
    :LandDay        => _INTL("Hierba (día)"),
    :LandNight      => _INTL("Hierba (noche)"),
    :LandMorning    => _INTL("Hierba (mañana)"),
    :LandAfternoon  => _INTL("Hierba (medio día)"), 
    :LandEvening    => _INTL("Hierba (atardecer)"),
    :Cave           => _INTL("Cueva"),
    :CaveDay        => _INTL("Cueva (día)"),
    :CaveNight      => _INTL("Cueva (noche)"),
    :CaveMorning    => _INTL("Cueva (mañana)"),
    :CaveAfternoon  => _INTL("Cueva (medio día)"),
    :CaveEvening    => _INTL("Cueva (atardecer)"),
    :Water          => _INTL("Surfeando"),
    :WaterDay       => _INTL("Surfeando (día)"),
    :WaterNight     => _INTL("Surfeando (noche)"),
    :WaterMorning   => _INTL("Surfeando (mañana)"),
    :WaterAfternoon => _INTL("Surfeando (medio día)"),
    :WaterEvening   => _INTL("Surfeando (atardecer)"),
    :OldRod         => _INTL("Pescando (Caña Vieja)"),
    :GoodRod        => _INTL("Pescando (Caña Buena)"),
    :SuperRod       => _INTL("Pescando (Super Caña)"),
    :RockSmash      => _INTL("Golpe Roca"),
    :HeadbuttLow    => _INTL("Cabezazo (Raro)"),
    :HeadbuttHigh   => _INTL("Cabezazo (Común)"),
    :BugContest     => _INTL("Concurso de Bichos"),
    :PokeRadar      => _INTL("PokéRadar")
  }

  # Remove the '#' from this line to use default encounter type names
  #EncounterListSettings::USER_DEFINED_NAMES = nil

  SHOW_SHADOWS_FOR_UNSEEN_POKEMON = true

  LOC_WINDOW_WIDTH = 512
  LOC_WINDOW_HEIGHT = 344
end


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
    unless File.file?("Graphics/UI/EncounterUI/"+EncounterListSettings::WINDOWSKIN)
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
    @sprites["base"].setBitmap("Graphics/UI/EncounterUI/#{EncounterListSettings::WINDOWSKIN}")
    @sprites["base"].ox = @sprites["base"].bitmap.width / 2
    @sprites["base"].oy = @sprites["base"].bitmap.height / 2
    @sprites["base"].x = Graphics.width / 2
    @sprites["base"].y = Graphics.height / 2
    @sprites["base"].opacity = 200
    @sprites["locwindow"] = Window_AdvancedTextPokemon.new('')
    @sprites["locwindow"].viewport = @viewport
    @sprites["locwindow"].width = EncounterListSettings::LOC_WINDOW_WIDTH
    @sprites["locwindow"].height = EncounterListSettings::LOC_WINDOW_HEIGHT
    @sprites["locwindow"].x = (Graphics.width - @sprites["locwindow"].width) / 2
    @sprites["locwindow"].y = (Graphics.height - @sprites["locwindow"].height) / 2
    @sprites["locwindow"].windowskin = nil
    @h = (Graphics.height - @sprites["base"].bitmap.height) / 2
    @w = (Graphics.width - @sprites["base"].bitmap.width) / 2
    @max_enc&.times do |i|
      @sprites["icon_#{i}"] = PokemonSpeciesIconSprite.new(nil, @viewport)
      @default_color = Color.new(@sprites["icon_#{i}"].color.red, @sprites["icon_#{i}"].color.green, @sprites["icon_#{i}"].color.blue, @sprites["icon_#{i}"].color.alpha)
      @sprites["icon_#{i}"].x = @w + EncounterListSettings::ICON_LEFT_OFFSET + EncounterListSettings::ICON_SPACING * (i % EncounterListSettings::ICONS_PER_ROW)
      @sprites["icon_#{i}"].y = @h + EncounterListSettings::ICON_TOP_OFFSET + (i / EncounterListSettings::ICONS_PER_ROW) * EncounterListSettings::ICON_SPACING
      @sprites["icon_#{i}"].visible = false
    end
    @sprites["rightarrow"] = AnimatedSprite.new('Graphics/UI/EncounterUI/right_arrow', 8, 40, 28, 2, @viewport)
    @sprites["rightarrow"].x = Graphics.width - @sprites["rightarrow"].bitmap.width
    @sprites["rightarrow"].y = Graphics.height / 2 - @sprites["rightarrow"].bitmap.height / EncounterListSettings::ARROW_Y_DIVISOR
    @sprites["rightarrow"].visible = false
    @sprites["rightarrow"].play
    @sprites["leftarrow"] = AnimatedSprite.new("Graphics/UI/EncounterUI/left_arrow", 8, 40, 28, 2, @viewport)
    @sprites["leftarrow"].x = 0
    @sprites["leftarrow"].y = Graphics.height / 2 - @sprites["rightarrow"].bitmap.height / EncounterListSettings::ARROW_Y_DIVISOR
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
      
      if EncounterListSettings::USER_DEFINED_NAMES && !seen_form_any_gender?(s, species_data.form)
        @sprites["icon_#{i}"].color = Color.new(0, 0, 0)
      elsif EncounterListSettings::USER_DEFINED_NAMES && !$player.owned?(species_data) # SI NO LO HE CAPTURADO
        @sprites["icon_#{i}"].tone = Tone.new(0,0,0,255)
      end
      @sprites["icon_#{i}"].visible = true
      i += 1
    end
    # Get user-defined encounter name or default one if not present
    raw_name = EncounterListSettings::USER_DEFINED_NAMES ? EncounterListSettings::USER_DEFINED_NAMES[curr_key] : GameData::EncounterType.get(curr_key).real_name
    name = _INTL(raw_name)
    loctext = _INTL("<ac><c2=7E105D08>{1}:</c2> <c2=43F022E8>{2}</c2></ac>", $game_map.name, name)
    loctext += _INTL("<al><c2=7FFF5EF7>Encuentros totales de la zona: {1}</c2></al>", enc_array.length)
    loctext += "<c2=63184210>-----------------------------------------</c2>"
    @sprites["locwindow"].setText(loctext)
  end

  # Draw text if map has no encounters defined (e.g. in buildings)
  def drawAbsent
    loctext = _INTL("<ac><c2=7E105D08>{1}</c2></ac>", $game_map.name)
    loctext += sprintf("<al><c2=7FFF5EF7>" + _INTL("Zona sin Pokémon salvajes") + "</c2></al>")
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

def pbStartRadar
  scene = EncounterList_Scene.new
  screen = EncounterList_Screen.new(scene)
  screen.pbStartScreen
end