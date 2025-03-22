def pbEmergencySave
  oldscene = $scene
  $scene = nil
  pbMessage(_INTL("El script está tardando mucho. Se va a reiniciar el juego."))
  return if !$player
  if SaveData.exists?
    File.open(SaveData::FILE_PATH, "rb") do |r|
      File.open(SaveData::FILE_PATH + ".bak", "wb") do |w|
        loop do
          s = r.read(4096)
          break if !s
          w.write(s)
        end
      end
    end
  end
  if Game.save
    pbMessage("\\se[]" + _INTL("Se ha guardado la partida.") + "\\me[GUI save game]\\wtnp[20]")
    pbMessage("\\se[]" + _INTL("Se ha hecho una copia del anterior archivo de guardado.") + "\\wtnp[20]")
  else
    pbMessage("\\se[]" + _INTL("El guardado ha fallado.") + "\\wtnp[30]")
  end
  $scene = oldscene
end

#===============================================================================
#
#===============================================================================
class PokemonSave_Scene
  LOCATION_TEXT_BASE   = Color.new(32, 152, 8)   # Green
  LOCATION_TEXT_SHADOW = Color.new(144, 240, 144)
  MALE_TEXT_BASE       = Color.new(0, 112, 248)   # Blue
  MALE_TEXT_SHADOW     = Color.new(120, 184, 232)
  FEMALE_TEXT_BASE     = Color.new(232, 32, 16)   # Red
  FEMALE_TEXT_SHADOW   = Color.new(248, 168, 184)
  OTHER_TEXT_BASE      = Color.new(0, 112, 248)   # Blue
  OTHER_TEXT_SHADOW    = Color.new(120, 184, 232)

  def pbStartScreen
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    totalsec = $stats.play_time.to_i
    hour = totalsec / 60 / 60
    min = totalsec / 60 % 60
    mapname = $game_map.name
    if $player.male?
      text_tag = shadowc3tag(MALE_TEXT_BASE, MALE_TEXT_SHADOW)
    elsif $player.female?
      text_tag = shadowc3tag(FEMALE_TEXT_BASE, FEMALE_TEXT_SHADOW)
    else
      text_tag = shadowc3tag(OTHER_TEXT_BASE, OTHER_TEXT_SHADOW)
    end
    location_tag = shadowc3tag(LOCATION_TEXT_BASE, LOCATION_TEXT_SHADOW)
    loctext = location_tag + "<ac>" + mapname + "</ac></c3>"
    loctext += _INTL("Jugador") + "<r>" + text_tag + $player.name + "</c3><br>"
    if hour > 0
      loctext += _INTL("Tiempo") + "<r>" + text_tag + _INTL("{1}h {2}m", hour, min) + "</c3><br>"
    else
      loctext += _INTL("Tiempo") + "<r>" + text_tag + _INTL("{1}m", min) + "</c3><br>"
    end
    loctext += _INTL("Medallas") + "<r>" + text_tag + $player.badge_count.to_s + "</c3><br>"
    if $player.has_pokedex
      loctext += _INTL("Pokédex") + "<r>" + text_tag + $player.pokedex.owned_count.to_s + "/" + $player.pokedex.seen_count.to_s + "</c3>"
    end
    @sprites["locwindow"] = Window_AdvancedTextPokemon.new(loctext)
    @sprites["locwindow"].viewport = @viewport
    @sprites["locwindow"].x = 0
    @sprites["locwindow"].y = 0
    @sprites["locwindow"].width = 228 if @sprites["locwindow"].width < 228
    @sprites["locwindow"].visible = true
  end

  def pbEndScreen
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

#===============================================================================
#
#===============================================================================
class PokemonSaveScreen
  def initialize(scene)
    @scene = scene
  end

  def pbDisplay(text, brief = false)
    @scene.pbDisplay(text, brief)
  end

  def pbDisplayPaused(text)
    @scene.pbDisplayPaused(text)
  end

  def pbConfirm(text)
    return @scene.pbConfirm(text)
  end

  def pbSaveScreen
    ret = false
    @scene.pbStartScreen
    if pbConfirmMessage(_INTL("¿Quieres guardar la partida?"))
      if SaveData.exists? && $game_temp.begun_new_game
        pbMessage(_INTL("¡AVISO!") + "\1")
        pbMessage(_INTL("Tienes ya un archivo de guardado de una partida diferente.") + "\1")
        pbMessage(_INTL("Si guardas ahora, todos los datos de la otra partida se perderán para siempre.") + "\1")
        if !pbConfirmMessageSerious(_INTL("¿Estás seguro de que quieres guardar la partida y sobreescribir el otro archivo?"))
          pbSEPlay("GUI save choice")
          @scene.pbEndScreen
          return false
        end
      end
      $game_temp.begun_new_game = false
      pbSEPlay("GUI save choice")
      if Game.save
        pbMessage("\\se[]" + _INTL("{1} guardó la partida.", $player.name) + "\\me[GUI save game]\\wtnp[20]")
        ret = true
      else
        pbMessage("\\se[]" + _INTL("El guardado ha fallado.") + "\\wtnp[30]")
        ret = false
      end
    else
      pbSEPlay("GUI save choice")
    end
    @scene.pbEndScreen
    return ret
  end
end
#===============================================================================
#
#===============================================================================
def pbSaveScreen
  scene = PokemonSave_Scene.new
  screen = PokemonSaveScreen.new(scene)
  ret = screen.pbSaveScreen
  return ret
end