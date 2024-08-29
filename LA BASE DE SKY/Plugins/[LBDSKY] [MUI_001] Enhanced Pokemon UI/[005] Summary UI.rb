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
    coords = (PluginManager.installed?("BW Summary Screen")) ? [Graphics.width - 18, 114] : [182, 124]
    pbDisplayShinyLeaf(@pokemon, overlay, coords[0], coords[1])
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to add happiness meter display.
  #-----------------------------------------------------------------------------
  alias enhanced_drawPageOne drawPageOne
  def drawPageOne
    enhanced_drawPageOne
    return if !Settings::SUMMARY_HAPPINESS_METER
    overlay = @sprites["overlay"].bitmap
    coords = [242, 346]
    pbDisplayHappiness(@pokemon, overlay, coords[0], coords[1])
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to add IV rankings display.
  #-----------------------------------------------------------------------------
  alias enhanced_drawPageThree drawPageThree
  def drawPageThree
    (@statToggle) ? drawEnhancedStats : enhanced_drawPageThree
    return if !Settings::SUMMARY_IV_RATINGS
    overlay = @sprites["overlay"].bitmap
    coords = (PluginManager.installed?("BW Summary Screen")) ? [110, 83] : [465, 83]
    pbDisplayIVRating(@pokemon, overlay, coords[0], coords[1])
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
    @sprites["legacyicon"].x = 64
    @sprites["legacyicon"].y = ypos + 64
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
        textpos.push([_INTL("HISTÓRICO DE {1}", @pokemon.name.upcase), 295, ypos + 38, :center, base2, shadow2],
                     [name, Graphics.width / 2, ypos + 90, :center, base, shadow])
        addltext.each_with_index do |txt, i|
          textY = ypos + 134 + (i * 32)
          textpos.push([txt[0], 38, textY, :left, base, shadow])
          textpos.push([_INTL("{1}", txt[1]), Graphics.width - 38, textY, :right, base, shadow])
        end
        imagepos.push([path + "bg_legacy", 0, ypos])
        if index > 0
          imagepos.push([path + "arrows_legacy", 118, ypos + 84, 0, 0, 32, 32])
        end
        if index < TOTAL_LEGACY_PAGES - 1
          imagepos.push([path + "arrows_legacy", 362, ypos + 84, 32, 0, 32, 32])
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
      when :HP then xpos, ypos, align = 292, 82, :center
      else xpos, ypos, align = 248, 94 + (32 * index), :left
      end
      name = (s.id == :SPECIAL_ATTACK) ? "Sp. Atk" : (s.id == :SPECIAL_DEFENSE) ? "Sp. Def" : s.name
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
        [_INTL("|"), 424, ypos, :right, base2, shadow2],
        [@pokemon.ev[s.id].to_s, 408, ypos, :right, base2, shadow2],
        [@pokemon.iv[s.id].to_s, 456, ypos, :right, base2, shadow2]
      )
      ev_total += @pokemon.ev[s.id]
      iv_total += @pokemon.iv[s.id]
      index += 1
    end
    textpos.push(
      [_INTL("EV/IV Totales"), 224, 290, :left, base, shadow],
      [sprintf("%d  |  %d", ev_total, iv_total), 434, 290, :center, base2, shadow2],
      [_INTL("EVs restantes:"), 224, 322, :left, base2, shadow2],
      [sprintf("%d/%d", Pokemon::EV_LIMIT - ev_total, Pokemon::EV_LIMIT), 444, 322, :center, base2, shadow2],
      [_INTL("Tipo de Poder Oculto:"), 224, 354, :left, base2, shadow2]
    )
    pbDrawTextPositions(overlay, textpos)
    if @pokemon.hp > 0
      w = @pokemon.hp * 96 / @pokemon.totalhp.to_f
      w = 1 if w < 1
      w = ((w / 2).round) * 2
      hpzone = 0
      hpzone = 1 if @pokemon.hp <= (@pokemon.totalhp / 2).floor
      hpzone = 2 if @pokemon.hp <= (@pokemon.totalhp / 4).floor
      imagepos = [
        ["Graphics/UI/Summary/overlay_hp", 360, 110, 0, hpzone * 6, w, 6]
      ]
      pbDrawImagePositions(overlay, imagepos)
    end
    hiddenpower = pbHiddenPower(@pokemon)
    type_number = GameData::Type.get(hiddenpower[0]).icon_position
    type_rect = Rect.new(0, type_number * 28, 64, 28)
    overlay.blt(428, 351, @typebitmap.bitmap, type_rect)
  end
end