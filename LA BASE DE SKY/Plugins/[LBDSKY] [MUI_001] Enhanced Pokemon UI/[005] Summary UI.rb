#===============================================================================
# Summary UI edits.
#===============================================================================
class PokemonSummary_Scene
  #-----------------------------------------------------------------------------
  # Aliased to add shiny leaf display.
  #-----------------------------------------------------------------------------
  alias enhanced_drawPage drawPage
  def drawPage(page)
    enhanced_drawPage(page)
    return if !Settings::SUMMARY_SHINY_LEAF
    overlay = @sprites["overlay"].bitmap
    
    if PluginManager.installed?("BW Summary Screen")
      x_pos = Graphics.width + SHINY_LEAF_BW_X
      y_pos = SHINY_LEAF_BW_Y
    else
      x_pos = SHINY_LEAF_X
      y_pos = SHINY_LEAF_Y
    end
    
    pbDisplayShinyLeaf(@pokemon, overlay, x_pos, y_pos)
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to add happiness meter display.
  #-----------------------------------------------------------------------------
  alias enhanced_drawPageOne drawPageOne
  def drawPageOne
    enhanced_drawPageOne
    return if !Settings::SUMMARY_HAPPINESS_METER
    overlay = @sprites["overlay"].bitmap
    pbDisplayHappiness(@pokemon, overlay, HAPPY_METER_X, HAPPY_METER_Y)
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to add IV rankings display.
  #-----------------------------------------------------------------------------
  alias enhanced_drawPageThree drawPageThree
  def drawPageThree
    (@statToggle) ? drawEnhancedStats : enhanced_drawPageThree
    return if !Settings::SUMMARY_IV_RATINGS
    overlay = @sprites["overlay"].bitmap
    if PluginManager.installed?("BW Summary Screen")
      x_pos = IV_RATINGS_BW_X
      y_pos = IV_RATINGS_BW_Y
    else
      x_pos = IV_RATINGS_X
      y_pos = IV_RATINGS_Y
    end
    
    pbDisplayIVRating(@pokemon, overlay, x_pos, y_pos)
  end
	
  def pbDisplayIVRating(*args)
    return if args.length == 0
    pbDisplayIVRatings(*args)
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to add a toggle for the Enhanced Stats display.
  #-----------------------------------------------------------------------------
  alias enhanced_pbPageCustomUse pbPageCustomUse
  def pbPageCustomUse(page_id)
    if page_id == :page_skills
      if defined?(Settings::DISPLAY_ENHANCED_STATS) && Settings::DISPLAY_ENHANCED_STATS
        @statToggle = !@statToggle
        drawPage(:page_skills)
        pbPlayDecisionSE
        return true
      end
    end
    return enhanced_pbPageCustomUse(page_id)
  end

  #-----------------------------------------------------------------------------
  # Aliased to add Legacy data display.
  #-----------------------------------------------------------------------------
  alias enhanced_pbStartScene pbStartScene
  def pbStartScene(*args)
    if Settings::SUMMARY_LEGACY_DATA
      UIHandlers.edit_hash(:summary, :page_memo, "options", 
        [:item, :nickname, :pokedex, _INTL("Ver Histórico"), :mark]
      )
    end
    @statToggle = false
    enhanced_pbStartScene(*args)
    @sprites["legacy_overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["legacy_overlay"].bitmap)
    @sprites["legacyicon"] = PokemonIconSprite.new(@pokemon, @viewport)
    @sprites["legacyicon"].setOffset(PictureOrigin::CENTER)
    @sprites["legacyicon"].visible = false
  end

  alias enhanced_pbPageCustomOption pbPageCustomOption
  def pbPageCustomOption(cmd)
    if cmd == _INTL("Ver Histórico")
      pbLegacyMenu
      return true
    end
    return enhanced_pbPageCustomOption(cmd)
  end
  
  #-----------------------------------------------------------------------------
  # Legacy data menu.
  #-----------------------------------------------------------------------------
  TOTAL_LEGACY_PAGES = 3
  LEGACY_ICON_X = 64
  LEGACY_ICON_Y_OFFSET = 64
  HISTORY_TEXT_X = 295
  HISTORY_TEXT_Y_OFFSET = 38
  NAME_Y_OFFSET = 90
  ACHIEVE_X = 38
  ACHIEVE_Y_OFFSET = 134
  LEGACY_ARROW_RIGHT_X = 118
  LEGACY_ARROW_RIGHT_Y_OFFSET = 84
  LEGACY_ARROW_LEFT_X = 362  
  LEGACY_ARROW_LEFT_Y_OFFSET = 84

  ENHANCED_HP_X = 292
  # Enhanced stats layout constants
  STATS_DEFAULT_X = 248
  STATS_FIRST_Y = 94
  STATS_Y_SPACING = 32
  STATS_HP_Y = 82
  STATS_NAME_SEPARATOR_X = 424
  STATS_EV_X = 408
  STATS_IV_X = 456
  STATS_TOTAL_LABEL_X = 224
  STATS_TOTAL_VALUE_X = 434
  STATS_REMAIN_LABEL_X = 224
  STATS_REMAIN_VALUE_X = 444
  STATS_HIDDENPOWER_LABEL_X = 224
  STATS_TOTAL_Y = 290
  STATS_REMAIN_Y = 322
  STATS_HIDDENPOWER_Y = 354

  # HP bar constants
  HP_BAR_MAX_WIDTH = 96
  HP_BAR_MIN_WIDTH = 1
  HP_BAR_ROUND_UNIT = 2
  HP_BAR_IMAGE = "Graphics/UI/Summary/overlay_hp"
  HP_BAR_HEIGHT = 6

  # Type icon constants
  TYPE_ICON_X = 428
  TYPE_ICON_Y = 351
  TYPE_ICON_WIDTH = 64
  TYPE_ICON_HEIGHT = 28
  
  def pbLegacyMenu    
    base    = Color.new(64, 64, 64)
    shadow  = Color.new(176, 176, 176)
    base2   = Color.new(248, 248, 248)
    shadow2 = Color.new(64, 64, 64)
    path = Settings::POKEMON_UI_GRAPHICS_PATH
    legacy_overlay = @sprites["legacy_overlay"].bitmap
    legacy_overlay.clear
    ypos = 62
    index = 0
    @sprites["legacyicon"].x = LEGACY_ICON_X
    @sprites["legacyicon"].y = ypos + LEGACY_ICON_Y_OFFSET
    @sprites["legacyicon"].pokemon = @pokemon
    @sprites["legacyicon"].visible = true
    data = @pokemon.legacy_data
    dorefresh = true
    loop do
      Graphics.update
      Input.update
      pbUpdate
      textpos = []
      imagepos = []
      if Input.trigger?(Input::BACK)
        break
      elsif Input.trigger?(Input::UP) && index > 0
        index -= 1
        pbPlayCursorSE
        dorefresh = true
      elsif Input.trigger?(Input::DOWN) && index < TOTAL_LEGACY_PAGES - 1
        index += 1
        pbPlayCursorSE
        dorefresh = true
      end
      if dorefresh
        case index
        when 0  # General
          name = _INTL("General")
          hour = data[:party_time].to_i / 60 / 60
          min  = data[:party_time].to_i / 60 % 60
          addltext = [
            [_INTL("Tiempo total en el equipo:"), "#{hour} hrs #{min} min"],
            [_INTL("Objetos consumidos:"),        data[:item_count]],
            [_INTL("Movimientos aprendidos:"),    data[:move_count]],
            [_INTL("Huevos generados:"),          data[:egg_count]],
            [_INTL("Veces intercambiado:"),       data[:trade_count]]
          ]
        when 1  # Battle History
          name = _INTL("Combates")
          addltext = [
            [_INTL("Rivales derrotados:"),         data[:defeated_count]],
            [_INTL("Veces derrotado:"),            data[:fainted_count]],
            [_INTL("Ataques muy eficaces:"),       data[:supereff_count]],
            [_INTL("Golpes críticos hechos:"),     data[:critical_count]],
            [_INTL("Número de retiradas:"),        data[:retreat_count]]
          ]
        when 2  # Team History
          name = _INTL("Equipo")
          addltext = [
            [_INTL("Victorias contra Entrenadores:"),    data[:trainer_count]],
            [_INTL("Victorias a Líderes de Gimnasio:"),  data[:leader_count]],
            [_INTL("Victorias contra Legendarios:"),     data[:legend_count]],
            [_INTL("Veces en el Hall de la Fama:"),      data[:champion_count]],
            [_INTL("Total de empates o derrotas:"),      data[:loss_count]]
          ]
        end
        textpos.push([_INTL("HISTÓRICO DE {1}", @pokemon.name.upcase), HISTORY_TEXT_X, ypos + HISTORY_TEXT_Y_OFFSET, :center, base2, shadow2],
                     [name, Graphics.width / 2, ypos + NAME_Y_OFFSET, :center, base, shadow])
        addltext.each_with_index do |txt, i|
          textY = ypos + ACHIEVE_Y_OFFSET + (i * 32)
          textpos.push([txt[0], ACHIEVE_X, textY, :left, base, shadow])
          textpos.push([_INTL("{1}", txt[1]), Graphics.width - ACHIEVE_X, textY, :right, base, shadow])
        end
        imagepos.push([path + "bg_legacy", 0, ypos])
        if index > 0
          imagepos.push([path + "arrows_legacy", LEGACY_ARROW_RIGHT_X, ypos + LEGACY_ARROW_RIGHT_Y_OFFSET, 0, 0, 32, 32])
        end
        if index < TOTAL_LEGACY_PAGES - 1
          imagepos.push([path + "arrows_legacy", LEGACY_ARROW_LEFT_X, ypos + LEGACY_ARROW_LEFT_Y_OFFSET, 32, 0, 32, 32])
        end
        legacy_overlay.clear
        pbDrawImagePositions(legacy_overlay, imagepos)
        pbDrawTextPositions(legacy_overlay, textpos)
        dorefresh = false
      end
    end
    legacy_overlay.clear
    @sprites["legacyicon"].visible = false
  end
  
  #-----------------------------------------------------------------------------
  # Enhanced stats display.
  #-----------------------------------------------------------------------------
  def drawEnhancedStats
    overlay = @sprites["overlay"].bitmap
    base   = Color.new(248, 248, 248)
    shadow = Color.new(104, 104, 104)
    base2 = Color.new(64, 64, 64)
    shadow2 = Color.new(176, 176, 176)
    index = 0
    ev_total = 0
    iv_total = 0
    textpos = []
    GameData::Stat.each_main do |s|
      case s.id
      when :HP then xpos, ypos, align = ENHANCED_HP_X, STATS_HP_Y, :center
      else xpos, ypos, align = STATS_DEFAULT_X, STATS_FIRST_Y + (STATS_Y_SPACING * index), :left
      end
      name = (s.id == :SPECIAL_ATTACK) ? _INTL("Atq. Esp.") : (s.id == :SPECIAL_DEFENSE) ? _INTL("Def. Esp.") : s.name
      statshadow = shadow
      if !@pokemon.shadowPokemon? || @pokemon.heartStage <= 3
        @pokemon.nature_for_stats.stat_changes.each do |change|
          next if s.id != change[0]
          if change[1] > 0
            statshadow = Color.new(136, 96, 72)
          elsif change[1] < 0
            statshadow = Color.new(64, 120, 152)
          end
        end
      end
      textpos.push(
        [_INTL("{1}", name), xpos, ypos, align, base, statshadow],
        [_INTL("|"), STATS_NAME_SEPARATOR_X, ypos, :right, base2, shadow2],
        [@pokemon.ev[s.id].to_s, STATS_EV_X, ypos, :right, base2, shadow2],
        [@pokemon.iv[s.id].to_s, STATS_IV_X, ypos, :right, base2, shadow2]
      )
      ev_total += @pokemon.ev[s.id]
      iv_total += @pokemon.iv[s.id]
      index += 1
    end
    textpos.push(
      [_INTL("EV/IV Totales"), STATS_TOTAL_LABEL_X, STATS_TOTAL_Y, :left, base, shadow],
      [sprintf("%d  |  %d", ev_total, iv_total), STATS_TOTAL_VALUE_X, STATS_TOTAL_Y, :center, base2, shadow2],
      [_INTL("EVs restantes:"), STATS_REMAIN_LABEL_X, STATS_REMAIN_Y, :left, base2, shadow2],
      [sprintf("%d/%d", Pokemon::EV_LIMIT - ev_total, Pokemon::EV_LIMIT), STATS_REMAIN_VALUE_X, STATS_REMAIN_Y, :center, base2, shadow2],
      [_INTL("Tipo de Poder Oculto:"), STATS_HIDDENPOWER_LABEL_X, STATS_HIDDENPOWER_Y, :left, base2, shadow2]
    )
    pbDrawTextPositions(overlay, textpos)
    if @pokemon.hp > 0
      w = @pokemon.hp * HP_BAR_MAX_WIDTH / @pokemon.totalhp.to_f
      w = HP_BAR_MIN_WIDTH if w < HP_BAR_MIN_WIDTH
      w = ((w / HP_BAR_WIDTH_ROUND_UNIT).round) * HP_BAR_WIDTH_ROUND_UNIT
      hpzone = 0
      hpzone = 1 if @pokemon.hp <= (@pokemon.totalhp / 2).floor
      hpzone = 2 if @pokemon.hp <= (@pokemon.totalhp / 4).floor
      imagepos = [
        [HP_BAR_IMAGE, 360, 110, 0, hpzone * HP_BAR_HEIGHT, w, HP_BAR_HEIGHT]
      ]
      pbDrawImagePositions(overlay, imagepos)
    end
    hiddenpower = pbHiddenPower(@pokemon)
    type_number = GameData::Type.get(hiddenpower[0]).icon_position
    type_rect = Rect.new(0, type_number * TYPE_ICON_HEIGHT, TYPE_ICON_WIDTH, TYPE_ICON_HEIGHT)
    overlay.blt(TYPE_ICON_X, TYPE_ICON_Y, @typebitmap.bitmap, type_rect)
  end
end