#===============================================================================
# Display methods.
#===============================================================================

#-------------------------------------------------------------------------------
# Shiny Leaf
#-------------------------------------------------------------------------------
# If "vertical" is set to true, Shiny Leaves will be displayed in a vertically
# stacked layout. Otherwise, Shiny Leaves will be displayed horizontally. This
# has no effect on how the Shiny Leaf Crown is displayed.
#-------------------------------------------------------------------------------
def pbDisplayShinyLeaf(pokemon, overlay, xpos, ypos, vertical = false)
  return if !pokemon
  imagepos = []
  path = Settings::POKEMON_UI_GRAPHICS_PATH
  if pokemon.shiny_crown?
    imagepos.push([sprintf(path + "leaf_crown"), xpos - 18, ypos - 3])
  elsif pokemon.shiny_leaf?
    offset_x = (vertical) ? 0  : 10
    offset_y = (vertical) ? 10 : 0
    pokemon.shiny_leaf.times do |i|
      imagepos.push([path + "leaf", xpos - (i * offset_x), ypos + (i * offset_y)])
    end
  end  
  pbDrawImagePositions(overlay, imagepos)
end

#-------------------------------------------------------------------------------
# Happiness Meter
#-------------------------------------------------------------------------------
def pbDisplayHappiness(pokemon, overlay, xpos, ypos)
  return if !pokemon || pokemon.shadowPokemon? || pokemon.egg?
  path = Settings::POKEMON_UI_GRAPHICS_PATH
  heartsBitmap = AnimatedBitmap.new(path + "happy_meter")
  w = heartsBitmap.width
  h = heartsBitmap.height / 2
  pbDrawImagePositions(overlay, [[path + "happy_meter", xpos, ypos, 0, 0, w, h]])
  w = pokemon.happiness * w / 254.0
  w = (w / 2).round * 2
  w = 1 if w < 1
  overlay.blt(xpos, ypos, heartsBitmap.bitmap, Rect.new(0, h, w, h))
end

#-------------------------------------------------------------------------------
# IV Ratings
#-------------------------------------------------------------------------------
# If "horizontal" is set to true, IV stars will be displayed in a horizontal
# layout, side by side. Otherwise, IV stars will be displayed vertically and
# spaced out in a way to account for the stat display in the Summary.
#-------------------------------------------------------------------------------
def pbDisplayIVRatings(pokemon, overlay, xpos, ypos, horizontal = false)
  return if !pokemon
  imagepos = []
  path  = Settings::POKEMON_UI_GRAPHICS_PATH
  style = (Settings::IV_DISPLAY_STYLE == 0) ? 0 : 16
  maxIV = Pokemon::IV_STAT_LIMIT
  offset_x = (horizontal) ? 16 : 0
  offset_y = (horizontal) ? 0  : 32
  i = 0
  GameData::Stat.each_main do |s|
    stat = pokemon.iv[s.id]
    case stat
    when maxIV     then icon = 5  # 31 IV
    when maxIV - 1 then icon = 4  # 30 IV
    when 0         then icon = 0  #  0 IV
    else
      if stat > (maxIV - (maxIV / 4).floor)
        icon = 3 # 25-29 IV
      elsif stat > (maxIV - (maxIV / 2).floor)
        icon = 2 # 16-24 IV
      else
        icon = 1 #  1-15 IV
      end
    end
    imagepos.push([
      path + "iv_ratings", xpos + (i * offset_x), ypos + (i * offset_y), icon * 16, style, 16, 16
    ])
    if s.id == :HP && !horizontal
      ypos += (PluginManager.installed?("BW Summary Screen")) ? 18 : 12 
    end
    i += 1
  end
  pbDrawImagePositions(overlay, imagepos)
end


#===============================================================================
# Debug tools - Shiny leaf.
#===============================================================================
MenuHandlers.add(:pokemon_debug_menu, :set_shiny_leaf, {
  "name"   => _INTL("Hoja brillante"),
  "parent" => :cosmetic,
  "condition" => proc { next Settings::SUMMARY_SHINY_LEAF },
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    cmd = 0
    loop do
      msg = [_INTL("Tiene corona brillante."), _INTL("Número de hojas brillantes: x#{pkmn.shiny_leaf}.")][pkmn.shiny_crown? ? 0 : 1]
      cmd = screen.pbShowCommands(msg, [
           _INTL("Definir contador de hoja"),
           _INTL("Definir corona"),
           _INTL("Resetear")], cmd)
      break if cmd < 0
      case cmd
      when 0   # Set Leaf
        params = ChooseNumberParams.new
        params.setRange(0, 6)
        params.setDefaultValue(pkmn.shiny_leaf)
        leafcount = pbMessageChooseNumber(
          _INTL("Indica el contador de hojas de {1} (máx. 6).", pkmn.name), params) { screen.pbUpdate }
        pkmn.shiny_leaf = leafcount
      when 1   # Set Crown
        pkmn.shiny_leaf = 6
      when 2   # Reset
        pkmn.shiny_leaf = 0
      end
      screen.pbRefreshSingle(pkmnid)
    end
    next false
  }
})