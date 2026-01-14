#===============================================================================
# Pokédex Regional Dexes list menu screen
# * For choosing which region list to view. Only appears when there is more
#   than one accessible region list to choose from, and if
#   Settings::USE_CURRENT_REGION_DEX is false.
#===============================================================================
class Window_DexesList < Window_CommandPokemon

  ICON_SEEN_X_OFFSET    = 236
  ICON_OWNED_X_OFFSET   = 332
  ICON_Y_OFFSET         = 6
  SEEN_NUMBER_X_OFFSET  = 254
  OWNED_NUMBER_X_OFFSET = 350

  def initialize(commands, commands2, width)
    @commands2 = commands2
    super(commands, width)
    @selarrow = AnimatedBitmap.new("Graphics/UI/sel_arrow_white")
    self.baseColor   = Color.new(248, 248, 248)
    self.shadowColor = Color.black
    self.windowskin  = nil
  end

  def drawItem(index, count, rect)
    super(index, count, rect)
    if index >= 0 && index < @commands2.length
      pbDrawShadowText(self.contents, rect.x + SEEN_NUMBER_X_OFFSET, rect.y + (self.contents.text_offset_y || 0),
                       64, rect.height, @commands2[index][0].to_s, self.baseColor, self.shadowColor, 1)
      pbDrawShadowText(self.contents, rect.x + OWNED_NUMBER_X_OFFSET, rect.y + (self.contents.text_offset_y || 0),
                       64, rect.height, @commands2[index][1].to_s, self.baseColor, self.shadowColor, 1)
      allseen = (@commands2[index][0] >= @commands2[index][2])
      allown  = (@commands2[index][1] >= @commands2[index][2])
      pbDrawImagePositions(
        self.contents,
        [["Graphics/UI/Pokedex/icon_menuseenown", rect.x + ICON_SEEN_X_OFFSET, rect.y + ICON_Y_OFFSET, (allseen) ? 24 : 0, 0, 24, 24],
         ["Graphics/UI/Pokedex/icon_menuseenown", rect.x + ICON_OWNED_X_OFFSET, rect.y + ICON_Y_OFFSET, (allown) ? 24 : 0, 24, 24, 24]]
      )
    end
  end
end

#===============================================================================
#
#===============================================================================
class PokemonPokedexMenu_Scene
  SEEN_OBTAINED_TEXT_BASE   = Color.new(248, 248, 248)
  SEEN_OBTAINED_TEXT_SHADOW = Color.new(192, 32, 40)
  TEXT_HEADING_X            = 247 
  TEXT_HEADING_Y            = 136
  TEXT_HEADING_WIDTH        = 250
  TEXT_HEADING_HEIGHT       = 64
  COMMAND_BOX_X             = 40
  COMMAND_BOX_Y             = 192
  COMMAND_BOX_WIDTH         = Graphics.width - 84
  COMMAND_BOX_HEIGHT        = 192

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene(commands, commands2)
    @commands = commands
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @sprites["background"] = IconSprite.new(0, 0, @viewport)
    @sprites["background"].setBitmap(_INTL("Graphics/UI/Pokedex/bg_menu"))
    text_tag = shadowc3tag(SEEN_OBTAINED_TEXT_BASE, SEEN_OBTAINED_TEXT_SHADOW)
    @sprites["headings"] = Window_AdvancedTextPokemon.newWithSize(
      text_tag + _INTL("VISTOS") + "     " + _INTL("OBTENIDOS") + "</c3>", TEXT_HEADING_X, TEXT_HEADING_Y, TEXT_HEADING_WIDTH, TEXT_HEADING_HEIGHT, @viewport
    )
    @sprites["headings"].windowskin = nil
    @sprites["commands"] = Window_DexesList.new(commands, commands2, COMMAND_BOX_WIDTH)
    @sprites["commands"].x      = COMMAND_BOX_X
    @sprites["commands"].y      = COMMAND_BOX_Y
    @sprites["commands"].height = COMMAND_BOX_HEIGHT
    @sprites["commands"].viewport = @viewport
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbScene
    ret = -1
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::USE)
        ret = @sprites["commands"].index
        (ret == @commands.length - 1) ? pbPlayCloseMenuSE : pbSEPlay("GUI pokedex open")
        break
      end
    end
    return ret
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
class PokemonPokedexMenuScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen
    commands  = []
    commands2 = []
    dexnames = Settings.pokedex_names
    $player.pokedex.accessible_dexes.each do |dex|
      if dexnames[dex].nil?
        commands.push(_INTL("Pokédex"))
      elsif dexnames[dex].is_a?(Array)
        commands.push(dexnames[dex][0])
      else
        commands.push(dexnames[dex])
      end
      commands2.push([$player.pokedex.seen_count(dex),
                      $player.pokedex.owned_count(dex),
                      pbGetRegionalDexLength(dex)])
    end
    commands.push(_INTL("Salir"))
    @scene.pbStartScene(commands, commands2)
    loop do
      cmd = @scene.pbScene
      break if cmd < 0 || cmd >= commands2.length   # Cancel/Exit
      $PokemonGlobal.pokedexDex = $player.pokedex.accessible_dexes[cmd]
      pbFadeOutIn do
        scene = PokemonPokedex_Scene.new
        screen = PokemonPokedexScreen.new(scene)
        screen.pbStartScreen
      end
    end
    @scene.pbEndScene
  end
end

