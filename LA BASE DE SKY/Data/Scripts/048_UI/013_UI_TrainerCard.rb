#===============================================================================
#
#===============================================================================
class PokemonTrainerCard_Scene

  # Ancho del sprite del entrenador mostrado en la tarjeta
  TRAINER_SPRITE_WIDTH = 336
  # Alto del sprite del entrenador mostrado en la tarjeta
  TRAINER_SPRITE_HEIGHT = 112
  # Offset horizontal aplicado al sprite del entrenador (centrado/ajuste)
  TRAINER_SPRITE_X_OFFSET = -128
  # Offset vertical aplicado al sprite del entrenador (posicionamiento)
  TRAINER_SPRITE_Y_OFFSET = -128
  # Posición X del texto "Nombre" en la tarjeta
  NAME_TEXT_X = 34
  # Posición Y del texto "Nombre" en la tarjeta
  NAME_TEXT_Y = 70
  # Posición X donde se dibuja el valor del nombre (a la derecha)
  NAME_VALUE_X = 302
  # Posición Y donde se dibuja el valor del nombre
  NAME_VALUE_Y = 70
  # Posición X del texto "No. ID"
  ID_TEXT_X = 332
  # Posición Y del texto "No. ID"
  ID_TEXT_Y = 70
  # Posición X del valor del ID (formato a la derecha)
  ID_VALUE_X = 468
  # Posición Y del valor del ID
  ID_VALUE_Y = 70
  # Posición X del texto "Dinero"
  MONEY_TEXT_X = 34
  # Posición Y del texto "Dinero"
  MONEY_TEXT_Y = 118
  # Posición X del valor del dinero
  MONEY_VALUE_X = 302
  # Posición Y del valor del dinero
  MONEY_VALUE_Y = 118
  # Posición X del texto "Pokédex"
  POKEDEX_TEXT_X = 34
  # Posición Y del texto "Pokédex"
  POKEDEX_TEXT_Y = 166
  # Posición X del valor de la Pokédex
  POKEDEX_VALUE_X = 302
  # Posición Y del valor de la Pokédex
  POKEDEX_VALUE_Y = 166
  # Posición X del texto "Tiempo"
  TIME_TEXT_X = 34
  # Posición Y del texto "Tiempo"
  TIME_TEXT_Y = 214
  # Posición X del valor del tiempo de juego
  TIME_VALUE_X = 302
  # Posición Y del valor del tiempo de juego
  TIME_VALUE_Y = 214
  # Posición X del texto "Comienzo" (fecha de inicio)
  START_TEXT_X = 34
  # Posición Y del texto "Comienzo"
  START_TEXT_Y = 262
  # Posición X del valor de la fecha de inicio
  START_VALUE_X = 302
  # Posición Y del valor de la fecha de inicio
  START_VALUE_Y = 262
  # Posición X inicial donde se dibujan los iconos de medallas
  REGION_START_X = 72
  # Posición Y donde se dibujan los iconos de medallas
  REGION_Y = 310
  # Tamaño (ancho/alto) de cada icono de medalla en la hoja de sprites
  BADGE_ICON_SIZE = 32
  # Número de medallas por región representadas en la hoja de sprites
  BADGES_PER_REGION = 8
  # Incremento en X entre medallas al dibujarlas en la tarjeta
  BADGE_X_INCREMENT = 48

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    background = pbResolveBitmap("Graphics/UI/Trainer Card/bg_f")
    if $player.female? && background
      addBackgroundPlane(@sprites, "bg", "Trainer Card/bg_f", @viewport)
    else
      addBackgroundPlane(@sprites, "bg", "Trainer Card/bg", @viewport)
    end
    cardexists = pbResolveBitmap(_INTL("Graphics/UI/Trainer Card/card_f"))
    @sprites["card"] = IconSprite.new(0, 0, @viewport)
    if $player.female? && cardexists
      @sprites["card"].setBitmap(_INTL("Graphics/UI/Trainer Card/card_f"))
    else
      @sprites["card"].setBitmap(_INTL("Graphics/UI/Trainer Card/card"))
    end
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @sprites["trainer"] = IconSprite.new(TRAINER_SPRITE_WIDTH, TRAINER_SPRITE_HEIGHT, @viewport)
    @sprites["trainer"].setBitmap(GameData::TrainerType.player_front_sprite_filename($player.trainer_type))
    @sprites["trainer"].x -= (@sprites["trainer"].bitmap.width + TRAINER_SPRITE_X_OFFSET) / 2
    @sprites["trainer"].y -= (@sprites["trainer"].bitmap.height + TRAINER_SPRITE_Y_OFFSET)
    @sprites["trainer"].z = 2
    pbDrawTrainerCardFront
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbDrawTrainerCardFront
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    baseColor   = Color.new(72, 72, 72)
    shadowColor = Color.new(160, 160, 160)
    totalsec = $stats.play_time.to_i
    hour = totalsec / 60 / 60
    min = totalsec / 60 % 60
    time = (hour > 0) ? _INTL("{1}h {2}m", hour, min) : _INTL("{1}m", min)
    $PokemonGlobal.startTime = Time.now if !$PokemonGlobal.startTime
    starttime = _INTL("{1} {2} {3}",
                      $PokemonGlobal.startTime.day,
                      pbGetAbbrevMonthName($PokemonGlobal.startTime.mon),
                      $PokemonGlobal.startTime.year)
    textPositions = [
      [_INTL("Nombre"), NAME_TEXT_X, NAME_TEXT_Y, :left, baseColor, shadowColor],
      [$player.name, NAME_VALUE_X, NAME_VALUE_Y, :right, baseColor, shadowColor],
      [_INTL("No. ID"), ID_TEXT_X, ID_TEXT_Y, :left, baseColor, shadowColor],
      [sprintf("%05d", $player.public_ID), ID_VALUE_X, ID_VALUE_Y, :right, baseColor, shadowColor],
      [_INTL("Dinero"), MONEY_TEXT_X, MONEY_TEXT_Y, :left, baseColor, shadowColor],
      [_INTL("{1}$", $player.money.to_s_formatted), MONEY_VALUE_X, MONEY_VALUE_Y, :right, baseColor, shadowColor],
      [_INTL("Pokédex"), POKEDEX_TEXT_X, POKEDEX_TEXT_Y, :left, baseColor, shadowColor],
      [sprintf("%d/%d", $player.pokedex.owned_count, $player.pokedex.seen_count), POKEDEX_VALUE_X, POKEDEX_VALUE_Y, :right, baseColor, shadowColor],
      [_INTL("Tiempo"), TIME_TEXT_X, TIME_TEXT_Y, :left, baseColor, shadowColor],
      [time, TIME_VALUE_X, TIME_VALUE_Y, :right, baseColor, shadowColor],
      [_INTL("Comienzo"), START_TEXT_X, START_TEXT_Y, :left, baseColor, shadowColor],
      [starttime, START_VALUE_X, START_VALUE_Y, :right, baseColor, shadowColor]
    ]
    pbDrawTextPositions(overlay, textPositions)
    x = REGION_START_X
    region = pbGetCurrentRegion(0) # Get the current region
    imagePositions = []
    BADGES_PER_REGION.times do |i|
      if $player.badges[i + (region * BADGES_PER_REGION)]
        imagePositions.push(["Graphics/UI/Trainer Card/icon_badges", x, REGION_Y, i * BADGE_ICON_SIZE, region * BADGE_ICON_SIZE, BADGE_ICON_SIZE, BADGE_ICON_SIZE])
      end
      x += BADGE_X_INCREMENT
    end
    pbDrawImagePositions(overlay, imagePositions)
  end

  def pbTrainerCard
    pbSEPlay("GUI trainer card open")
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        break
      end
    end
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

#===============================================================================
#
#===============================================================================
class PokemonTrainerCardScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen
    @scene.pbStartScene
    @scene.pbTrainerCard
    @scene.pbEndScene
  end
end

