#===============================================================================
# * Hall de la Fama - por FL (Se agradecerán los créditos)
#===============================================================================
#
# Este script es para Pokémon Essentials. Crea un Salón de la Fama que se puede
# registrar como en los juegos de la Generación 3.
#
#===============================================================================
#
# Para que este script funcione, colócalo encima de Main, coloca una imagen de 
# 512x384 en hallfamebars y un fondo de 8x24 en hallfamebg. Para llamar a este 
# script, utiliza 'pbHallOfFameEntry'. Después de registrar la primera entrada, 
# puedes acceder a los equipos del Salón de la Fama usando un PC. También puedes 
# comprobar el número de la última entrada del Salón de la Fama del jugador 
# usando '$PokemonGlobal.hallOfFameLastNumber'.
#
#===============================================================================
class HallOfFame_Scene
  # Cuando es true, todos los Pokémon estarán en una sola fila.
  # Cuando es false, todos los Pokémon estarán en dos filas.
  SINGLE_ROW_OF_POKEMON = false
  # Activa el movimiento de los Pokémon en la entrada del salón.
  ANIMATION = true
  # Tiempo en segundos para que un Pokémon se deslice a su posición desde fuera 
  # de la pantalla.
  APPEAR_SPEED = 0.4
  # Tiempo de espera (en segundos) entre mostrar cada Pokémon (y entrenador).
  ENTRY_WAIT_TIME = 3.0
  # Tiempo de espera (en segundos) al mostrar "¡Bienvenido al Salón de la Fama!".
  WELCOME_WAIT_TIME = 4.0
  # Límite máximo de entradas simultáneas en el salón guardadas.
  # 0 = No guarda ningún salón. -1 = Sin límite.
  # Es preferible usar números más grandes (como 500 y 1000) que no poner límite.
  # Si un jugador supera este límite, la primera entrada será eliminada.
  HALL_ENTRIES_LIMIT = 50
  # El nombre de la música de entrada. Pon "" para no reproducir nada.
  HALL_OF_FAME_BGM = "Salón de la Fama"
  # Permite que los huevos se muestren y se guarden en el salón.
  ALLOW_EGGS = true
  # Elimina las barras del salón cuando aparece el sprite del entrenador.
  REMOVE_BARS_WHEN_SHOWING_TRAINER = true
  # La velocidad de desvanecimiento final en la entrada.
  FINAL_FADE_DURATION = 1.0
  # Valor de opacidad del sprite cuando no está seleccionado.
  OPACITY = 64
  TEXT_BASE_COLOR   = Color.new(248, 248, 248)
  TEXT_SHADOW_COLOR = Color.new(0, 0, 0)

  VIEWPORT_Z = 99999
  OVERLAY_Z = 10

  # Constantes de diseño / posiciones
  # Multiplicador X y base usados cuando los Pokémon están en una sola fila
  POINT_SINGLE_MULT = 60
  POINT_SINGLE_BASE = 48
  # Factor y base X para columnas cuando hay varias filas
  POINT_X_FACTOR = 160
  POINT_X_BASE = 96

  # Coordenadas Y base y pasos para filas en modo single/normal
  Y_SINGLE_BASE = 180
  Y_SINGLE_STEP = 32
  Y_BASE = 96
  Y_ROW_STEP = 64

  # Posición del sprite del entrenador según layout
  TRAINER_Y_SINGLE = 208
  TRAINER_X_RIGHT_OFFSET = 96
  TRAINER_Y = 160

  # Posiciones y offsets para la información del pokémon en pantalla
  DEX_X = 32
  INFO_RIGHT_OFFSET = 192
  INFO_LINE1_OFFSET = 74
  LV_X = 64
  INFO_LINE2_OFFSET = 42
  # Offset desde el centro para el número del Hall en la cabecera
  CENTER_HALF_OFFSET = 104
  HALL_LABEL_Y = 6
  # Desplazamiento vertical para el mensaje de bienvenida
  WELCOME_Y_OFFSET = 68

  # Placement for pokemon icons
  def pbStartScene
    @sprites = {}
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = VIEWPORT_Z
    # Comment the below line to doesn't use a background
    addBackgroundPlane(@sprites, "bg", "Hall of Fame/bg", @viewport)
    @sprites["hallbars"] = IconSprite.new(@viewport)
    @sprites["hallbars"].setBitmap("Graphics/UI/Hall of Fame/bars")
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    @sprites["overlay"].z = OVERLAY_Z
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @alreadyFadedInEnd = false
    @useMusic = false
    @battlerIndex = 0
    @hallEntry = []
    @nationalDexList = [:NONE]
    GameData::Species.each_species { |s| @nationalDexList.push(s.species) }
  end

  def pbStartSceneEntry
    pbStartScene
    @useMusic = (HALL_OF_FAME_BGM && HALL_OF_FAME_BGM != "")
    pbBGMPlay(HALL_OF_FAME_BGM) if @useMusic
    saveHallEntry
    @movements = []
    createBattlers
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbStartScenePC
    pbStartScene
    @hallIndex = $PokemonGlobal.hallOfFame.size - 1
    @hallEntry = $PokemonGlobal.hallOfFame[-1]
    createBattlers(false)
    pbFadeInAndShow(@sprites) { pbUpdate }
    pbUpdatePC
  end

  def pbEndScene
    $game_map.autoplay if @useMusic
    pbDisposeMessageWindow(@sprites["msgwindow"]) if @sprites.include?("msgwindow")
    pbFadeOutAndHide(@sprites) { pbUpdate } if !@alreadyFadedInEnd
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def slowFadeOut(duration)
    col = Color.new(0, 0, 0, 0)
    timer_start = System.uptime
    loop do
      col.alpha = lerp(0, 255, duration, timer_start, System.uptime)
      @viewport.color = col
      Graphics.update
      Input.update
      pbUpdate
      break if col.alpha == 255
    end
  end

  # Dispose the sprite if the sprite exists and make it null
  def restartSpritePosition(sprites, spritename)
    sprites[spritename].dispose if sprites.include?(spritename) && sprites[spritename]
    sprites[spritename] = nil
  end

  # Change the pokémon sprites opacity except the index one
  def setPokemonSpritesOpacity(index, opacity = 255)
    @hallEntry.size.times do |n|
      @sprites["pokemon#{n}"].opacity = (n == index) ? 255 : opacity if @sprites["pokemon#{n}"]
    end
  end

  def saveHallEntry
    $player.party.each do |pkmn|
      # Clones every pokémon object
      @hallEntry.push(pkmn.clone) if !pkmn.egg? || ALLOW_EGGS
    end
    # Update the global variables
    $PokemonGlobal.hallOfFame.push(@hallEntry)
    $PokemonGlobal.hallOfFameLastNumber += 1
    if HALL_ENTRIES_LIMIT >= 0 && $PokemonGlobal.hallOfFame.size > HALL_ENTRIES_LIMIT
      $PokemonGlobal.hallOfFame.delete_at(0)
    end
  end

  # Return the x/y point position in screen for battler index number
  # Don't use odd numbers!
  def xpointformula(battlernumber)
    if SINGLE_ROW_OF_POKEMON
      ret = ((POINT_SINGLE_MULT * (battlernumber / 2)) + POINT_SINGLE_BASE) * (xpositionformula(battlernumber) - 1)
      return ret + (Graphics.width / 2)
    end
    return POINT_X_BASE + (POINT_X_FACTOR * xpositionformula(battlernumber))
  end

  def ypointformula(battlernumber)
    return Y_SINGLE_BASE - (Y_SINGLE_STEP * (battlernumber / 2)) if SINGLE_ROW_OF_POKEMON
    return Y_BASE + (Y_ROW_STEP * ypositionformula(battlernumber))
  end

  # Returns 0, 1 or 2 as the x position value (left, middle, right column)
  def xpositionformula(battlernumber)
    return (battlernumber % 2) * 2 if SINGLE_ROW_OF_POKEMON       # 0, 2, 0, 2, 0, 2
    return (1 - battlernumber) % 3 if (battlernumber / 3).even?   # First 3 mons: 1, 0, 2
    return (1 + battlernumber) % 3                                # Second 3 mons: 1, 2, 0
  end

  # Returns 0, 1 or 2 as the y position value (top, middle, bottom row)
  def ypositionformula(battlernumber)
    return 1 if SINGLE_ROW_OF_POKEMON      # 1, 1, 1, 1, 1, 1
    return ((battlernumber / 3) % 2) * 2   # 0, 0, 0, 2, 2, 2
  end

  def moveSprite(i)
    spritename = (i > -1) ? "pokemon#{i}" : "trainer"
    if !ANIMATION   # Skips animation, place directly in end position
      @sprites[spritename].x = @movements[i][1]
      @sprites[spritename].y = @movements[i][3]
      @movements[i][0] = @movements[i][1]
      @movements[i][2] = @movements[i][3]
      return
    end
    @movements[i][4] = System.uptime if !@movements[i][4]
    speed = (i > -1) ? APPEAR_SPEED : APPEAR_SPEED * 3
    @sprites[spritename].x = lerp(@movements[i][0], @movements[i][1], speed, @movements[i][4], System.uptime)
    @sprites[spritename].y = lerp(@movements[i][2], @movements[i][3], speed, @movements[i][4], System.uptime)
    @movements[i][0] = @movements[i][1] if @sprites[spritename].x == @movements[i][1]
    @movements[i][2] = @movements[i][3] if @sprites[spritename].y == @movements[i][3]
  end

  def createBattlers(hide = true)
    # Movement in animation
    Settings::MAX_PARTY_SIZE.times do |i|
      # Clear all pokémon sprites and dispose the ones that exists every time
      # that this method is call
      restartSpritePosition(@sprites, "pokemon#{i}")
      next if i >= @hallEntry.size
      end_x = xpointformula(i)
      end_y = ypointformula(i)
      @sprites["pokemon#{i}"] = PokemonSprite.new(@viewport)
      @sprites["pokemon#{i}"].setPokemonBitmap(@hallEntry[i])
      # This method doesn't put the exact coordinates
      @sprites["pokemon#{i}"].x = end_x
      @sprites["pokemon#{i}"].y = end_y
      @sprites["pokemon#{i}"].z = Settings::MAX_PARTY_SIZE - i if SINGLE_ROW_OF_POKEMON
      next if !hide
      # Animation distance calculation
      x_direction = xpositionformula(i) - 1
      y_direction = ypositionformula(i) - 1
      distance = 0
      if y_direction == 0
        distance = (x_direction > 0) ? end_x : Graphics.width - end_x
        distance += @sprites["pokemon#{i}"].bitmap.width / 2
      else
        distance = (y_direction > 0) ? end_y : Graphics.height - end_y
        distance += @sprites["pokemon#{i}"].bitmap.height / 2
      end
      start_x = end_x - (x_direction * distance)
      start_y = end_y - (y_direction * distance)
      @sprites["pokemon#{i}"].x = start_x
      @sprites["pokemon#{i}"].y = start_y
      @movements[i] = [start_x, end_x, start_y, end_y]
    end
  end

  def createTrainerBattler
    @sprites["trainer"] = IconSprite.new(@viewport)
    @sprites["trainer"].setBitmap(GameData::TrainerType.player_front_sprite_filename($player.trainer_type))
    if SINGLE_ROW_OF_POKEMON
      @sprites["trainer"].x = Graphics.width / 2
      @sprites["trainer"].y = TRAINER_Y_SINGLE
    else
      @sprites["trainer"].x = Graphics.width - TRAINER_X_RIGHT_OFFSET
      @sprites["trainer"].y = TRAINER_Y
    end
    @movements.push([Graphics.width / 2, @sprites["trainer"].x, @sprites["trainer"].y, @sprites["trainer"].y])
    @sprites["trainer"].z = 9
    @sprites["trainer"].ox = @sprites["trainer"].bitmap.width / 2
    @sprites["trainer"].oy = @sprites["trainer"].bitmap.height / 2
    if REMOVE_BARS_WHEN_SHOWING_TRAINER
      @sprites["overlay"].bitmap.clear
      @sprites["hallbars"].visible = false
    end
    if ANIMATION && !SINGLE_ROW_OF_POKEMON   # Trainer Animation
      @sprites["trainer"].x = @movements.last[0]
    else
      timer_start = System.uptime
      loop do
        Graphics.update
        Input.update
        pbUpdate
        break if System.uptime - timer_start >= ENTRY_WAIT_TIME
      end
    end
  end

  def writeTrainerData
    if $PokemonGlobal.hallOfFameLastNumber == 1
      totalsec = $stats.time_to_enter_hall_of_fame.to_i
    else
      totalsec = $stats.play_time.to_i
    end
    hour = totalsec / 60 / 60
    min = totalsec / 60 % 60
    pubid = sprintf("%05d", $player.public_ID)
    lefttext = _INTL("Nombre<r>{1}", $player.name) + "<br>"
    lefttext += _INTL("No. ID<r>{1}", pubid) + "<br>"
    if hour > 0
      lefttext += _INTL("Tiempo<r>{1}h {2}m", hour, min) + "<br>"
    else
      lefttext += _INTL("Tiempo<r>{1}m", min) + "<br>"
    end
    lefttext += _INTL("Pokédex<r>{1}/{2}",
                      $player.pokedex.owned_count, $player.pokedex.seen_count) + "<br>"
    @sprites["messagebox"] = Window_AdvancedTextPokemon.new(lefttext)
    @sprites["messagebox"].viewport = @viewport
    @sprites["messagebox"].width = 192 if @sprites["messagebox"].width < 192
    @sprites["msgwindow"] = pbCreateMessageWindow(@viewport)
    pbMessageDisplay(@sprites["msgwindow"],
                     _INTL("¡Campeón de la Liga!\n¡Enhorabuena!") + "\\^")
  end

  def writePokemonData(pokemon, hallNumber = -1)
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    pokename = pokemon.name
    speciesname = pokemon.speciesName
    if pokemon.male?
      speciesname += "♂"
    elsif pokemon.female?
      speciesname += "♀"
    end
    pokename += "/" + speciesname
    pokename = _INTL("Huevo") + "/" + _INTL("Huevo") if pokemon.egg?
    idno = (pokemon.owner.name.empty? || pokemon.egg?) ? "?????" : sprintf("%05d", pokemon.owner.public_id)
    dexnumber = _INTL("No. ???")
    if !pokemon.egg?
      number = @nationalDexList.index(pokemon.species) || 0
      dexnumber = _ISPRINTF("No. {1:03d}", number)
    end
    textPositions = [
      [dexnumber, DEX_X, Graphics.height - INFO_LINE1_OFFSET, :left, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR],
      [pokename, Graphics.width - INFO_RIGHT_OFFSET, Graphics.height - INFO_LINE1_OFFSET, :center, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR],
      [_INTL("Nv. {1}", pokemon.egg? ? "?" : pokemon.level),
       LV_X, Graphics.height - INFO_LINE2_OFFSET, :left, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR],
      [_INTL("No. ID {1}", pokemon.egg? ? "?????" : idno),
       Graphics.width - INFO_RIGHT_OFFSET, Graphics.height - INFO_LINE2_OFFSET, :center, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR]
    ]
    if hallNumber > -1
      textPositions.push([_INTL("Hall de la Fama No."), (Graphics.width / 2) - CENTER_HALF_OFFSET, HALL_LABEL_Y, :left, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR])
      textPositions.push([hallNumber.to_s, (Graphics.width / 2) + CENTER_HALF_OFFSET, HALL_LABEL_Y, :right, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR])
    end
    pbDrawTextPositions(overlay, textPositions)
  end

  def writeWelcome
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    pbDrawTextPositions(overlay, [[_INTL("¡Bienvenido al Hall de la Fama!"),
                                   Graphics.width / 2, Graphics.height - WELCOME_Y_OFFSET, :center, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR]])
  end

  def pbAnimationLoop
    loop do
      Graphics.update
      Input.update
      pbUpdate
      pbUpdateAnimation
      break if @battlerIndex == @hallEntry.size + 2
    end
  end

  def pbPCSelection
    loop do
      Graphics.update
      Input.update
      pbUpdate
      continueScene = true
      break if Input.trigger?(Input::BACK)   # Exits
      if Input.trigger?(Input::USE)   # Moves the selection one entry backward
        @battlerIndex += 10
        continueScene = pbUpdatePC
      end
      if Input.trigger?(Input::LEFT)   # Moves the selection one pokémon forward
        @battlerIndex -= 1
        continueScene = pbUpdatePC
      end
      if Input.trigger?(Input::RIGHT)   # Moves the selection one pokémon backward
        @battlerIndex += 1
        continueScene = pbUpdatePC
      end
      break if !continueScene
    end
  end

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbUpdateAnimation
    if @battlerIndex <= @hallEntry.size
      if @movements[@battlerIndex] &&
         (@movements[@battlerIndex][0] != @movements[@battlerIndex][1] ||
         @movements[@battlerIndex][2] != @movements[@battlerIndex][3])
        spriteIndex = (@battlerIndex < @hallEntry.size) ? @battlerIndex : -1
        moveSprite(spriteIndex)
      else
        @battlerIndex += 1
        if @battlerIndex <= @hallEntry.size
          # If it is a pokémon, write the pokémon text, wait the
          # ENTRY_WAIT_TIME and goes to the next battler
          @hallEntry[@battlerIndex - 1].play_cry
          writePokemonData(@hallEntry[@battlerIndex - 1])
          timer_start = System.uptime
          loop do
            Graphics.update
            Input.update
            pbUpdate
            break if System.uptime - timer_start >= ENTRY_WAIT_TIME
          end
          if @battlerIndex < @hallEntry.size   # Preparates the next battler
            setPokemonSpritesOpacity(@battlerIndex, OPACITY)
            @sprites["overlay"].bitmap.clear
          else   # Show the welcome message and prepares the trainer
            setPokemonSpritesOpacity(-1)
            writeWelcome
            timer_start = System.uptime
            loop do
              Graphics.update
              Input.update
              pbUpdate
              break if System.uptime - timer_start >= WELCOME_WAIT_TIME
            end
            setPokemonSpritesOpacity(-1, OPACITY) if !SINGLE_ROW_OF_POKEMON
            createTrainerBattler
          end
        end
      end
    elsif @battlerIndex > @hallEntry.size
      # Write the trainer data and fade
      writeTrainerData
      timer_start = System.uptime
      loop do
        Graphics.update
        Input.update
        pbUpdate
        break if System.uptime - timer_start >= ENTRY_WAIT_TIME
      end
      pbBGMFade(FINAL_FADE_DURATION) if @useMusic
      slowFadeOut(FINAL_FADE_DURATION)
      @alreadyFadedInEnd = true
      @battlerIndex += 1
    end
  end

  def pbUpdatePC
    # Change the team
    if @battlerIndex >= @hallEntry.size
      @hallIndex -= 1
      return false if @hallIndex == -1
      @hallEntry = $PokemonGlobal.hallOfFame[@hallIndex]
      @battlerIndex = 0
      createBattlers(false)
    elsif @battlerIndex < 0
      @hallIndex += 1
      return false if @hallIndex >= $PokemonGlobal.hallOfFame.size
      @hallEntry = $PokemonGlobal.hallOfFame[@hallIndex]
      @battlerIndex = @hallEntry.size - 1
      createBattlers(false)
    end
    # Change the pokemon
    @hallEntry[@battlerIndex].play_cry
    setPokemonSpritesOpacity(@battlerIndex, OPACITY)
    hallNumber = $PokemonGlobal.hallOfFameLastNumber + @hallIndex -
                 $PokemonGlobal.hallOfFame.size + 1
    writePokemonData(@hallEntry[@battlerIndex], hallNumber)
    return true
  end
end

#===============================================================================
#
#===============================================================================
class HallOfFameScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreenEntry
    @scene.pbStartSceneEntry
    @scene.pbAnimationLoop
    @scene.pbEndScene
  end

  def pbStartScreenPC
    @scene.pbStartScenePC
    @scene.pbPCSelection
    @scene.pbEndScene
  end
end

#===============================================================================
#
#===============================================================================
MenuHandlers.add(:pc_menu, :hall_of_fame, {
  "name"      => _INTL("Hall de la Fama"),
  "order"     => 40,
  "condition" => proc { next $PokemonGlobal.hallOfFameLastNumber > 0 },
  "effect"    => proc { |menu|
    pbMessage("\\se[PC access]" + _INTL("Has accedido al Hall de la Fama."))
    pbHallOfFamePC
    next false
  }
})

#===============================================================================
#
#===============================================================================
class PokemonGlobalMetadata
  attr_writer :hallOfFame
  # Number necessary if hallOfFame array reach in its size limit
  attr_writer :hallOfFameLastNumber

  def hallOfFame
    @hallOfFame = [] if !@hallOfFame
    return @hallOfFame
  end

  def hallOfFameLastNumber
    return @hallOfFameLastNumber || 0
  end
end

#===============================================================================
#
#===============================================================================
def pbHallOfFameEntry
  scene = HallOfFame_Scene.new
  screen = HallOfFameScreen.new(scene)
  screen.pbStartScreenEntry
end

def pbHallOfFamePC
  scene = HallOfFame_Scene.new
  screen = HallOfFameScreen.new(scene)
  screen.pbStartScreenPC
end

