#===============================================================================
# Adds/edits various Summary utilities.
#===============================================================================
class PokemonSummary_Scene

  TOTAL_LABEL_X = 381
  TOTAL_LABEL_Y = 94
  IV_LABEL_X    = 428
  IV_LABEL_Y    = 94
  EV_LABEL_X    = 473
  EV_LABEL_Y    = 94
  HP_LABEL_X    = 240
  HP_LABEL_Y    = 126
  HP_VALUE_X    = 400
  HP_VALUE_Y    = 126
  HP_IV_X       = 440
  HP_IV_Y       = 126
  HP_EV_X       = 480
  HP_EV_Y       = 126
  ATK_LABEL_X   = 240
  ATK_LABEL_Y   = 158
  ATK_VALUE_X   = 400
  ATK_VALUE_Y   = 158
  ATK_IV_X      = 440
  ATK_IV_Y      = 158
  ATK_EV_X      = 480
  ATK_EV_Y      = 158
  DEF_LABEL_X   = 240
  DEF_LABEL_Y   = 190
  DEF_VALUE_X   = 400
  DEF_VALUE_Y   = 190
  DEF_IV_X      = 440
  DEF_IV_Y      = 190
  DEF_EV_X      = 480
  DEF_EV_Y      = 190
  SPA_LABEL_X   = 240
  SPA_LABEL_Y   = 222
  SPA_VALUE_X   = 400
  SPA_VALUE_Y   = 222
  SPA_IV_X      = 440
  SPA_IV_Y      = 222
  SPA_EV_X      = 480
  SPA_EV_Y      = 222
  SPDEF_LABEL_X  = 240
  SPDEF_LABEL_Y  = 254
  SPDEF_VALUE_X  = 400
  SPDEF_VALUE_Y  = 254
  SPDEF_IV_X     = 440
  SPDEF_IV_Y     = 254
  SPDEF_EV_X     = 480
  SPDEF_EV_Y     = 254
  SPEED_LABEL_X   = 240
  SPEED_LABEL_Y   = 286
  SPEED_VALUE_X   = 400
  SPEED_VALUE_Y   = 286
  SPEED_IV_X      = 440
  SPEED_IV_Y      = 286
  SPEED_EV_X      = 480
  SPEED_EV_Y      = 286
  TOTAL_EVS_LABEL_X = 224
  TOTAL_EVS_LABEL_Y = 324
  TOTAL_EVS_VALUE_X = 435
  TOTAL_EVS_VALUE_Y = 324
  HIDDEN_POWER_LABEL_X = 220
  HIDDEN_POWER_LABEL_Y = 356
  HIDDEN_POWER_ICON_X  = 405
  HIDDEN_POWER_ICON_Y  = 351
  TYPE_ICON_HEIGHT    = 28
  TYPE_ICON_WIDTH     = 64

  COLOR_TEXTO_BASE = Color.new(248, 248, 248)
  COLOR_TEXTO_SOMBRA = Color.new(104, 104, 104)

  COLOR_NUMERO_BASE = Color.new(64, 64, 64)
  COLOR_NUMERO_SOMBRA = Color.new(176, 176, 176)

  
  def drawPageAllStats
    overlay = @sprites["overlay"].bitmap
    shadow = COLOR_TEXTO_SOMBRA

    ev_total = 0
    # Determine which stats are boosted and lowered by the Pokémon's nature
    statshadows = {}
    GameData::Stat.each_main { |s| statshadows[s.id] = shadow; ev_total += @pokemon.ev[s.id] }
    if !@pokemon.shadowPokemon? || @pokemon.heartStage <= 3
      @pokemon.nature_for_stats.stat_changes.each do |change|
        statshadows[change[0]] = Color.new(136, 96, 72) if change[1] > 0
        statshadows[change[0]] = Color.new(64, 120, 152) if change[1] < 0
      end
    end
    # Write various bits of text
    textpos = [
      [_INTL("Total"), TOTAL_LABEL_X, TOTAL_LABEL_Y, :center, COLOR_TEXTO_BASE, COLOR_TEXTO_SOMBRA],
      [_INTL("IV"), IV_LABEL_X, IV_LABEL_Y, :center, COLOR_TEXTO_BASE, COLOR_TEXTO_SOMBRA],
      [_INTL("EV"), EV_LABEL_X, EV_LABEL_Y, :center, COLOR_TEXTO_BASE, COLOR_TEXTO_SOMBRA],
      [_INTL("PS"), HP_LABEL_X, HP_LABEL_Y, :left, COLOR_TEXTO_BASE, statshadows[:HP]],
      [@pokemon.totalhp.to_s, HP_VALUE_X, HP_VALUE_Y, :right, COLOR_NUMERO_BASE, COLOR_NUMERO_SOMBRA],
      #[sprintf("%d", @pokemon.baseStats[:HP]), 408, 126, :right, COLOR_NUMERO_BASE, COLOR_NUMERO_SOMBRA],
      [sprintf("%d", @pokemon.iv[:HP]), HP_IV_X, HP_IV_Y, :right, COLOR_NUMERO_BASE, COLOR_NUMERO_SOMBRA],
      [sprintf("%d", @pokemon.ev[:HP]), HP_EV_X, HP_EV_Y, :right, COLOR_NUMERO_BASE, COLOR_NUMERO_SOMBRA],
      [_INTL("Ataque"), ATK_LABEL_X, ATK_LABEL_Y, :left, COLOR_TEXTO_BASE, statshadows[:ATTACK]],
      [@pokemon.attack.to_s, ATK_VALUE_X, ATK_VALUE_Y, :right, COLOR_NUMERO_BASE, COLOR_NUMERO_SOMBRA],
      #[sprintf("%d", @pokemon.baseStats[:ATTACK]), 408, 158, :right, COLOR_NUMERO_BASE, COLOR_NUMERO_SOMBRA],
      [sprintf("%d", @pokemon.iv[:ATTACK]), ATK_IV_X, ATK_IV_Y, :right, COLOR_NUMERO_BASE, COLOR_NUMERO_SOMBRA],
      [sprintf("%d", @pokemon.ev[:ATTACK]), ATK_EV_X, ATK_EV_Y, :right, COLOR_NUMERO_BASE, COLOR_NUMERO_SOMBRA],
      [_INTL("Defensa"), DEF_LABEL_X, DEF_LABEL_Y, :left, COLOR_TEXTO_BASE, statshadows[:DEFENSE]],
      [@pokemon.defense.to_s, DEF_VALUE_X, DEF_VALUE_Y, :right, COLOR_NUMERO_BASE, COLOR_NUMERO_SOMBRA],
      #[sprintf("%d", @pokemon.baseStats[:DEFENSE]), 408, 190, :right, COLOR_NUMERO_BASE, COLOR_NUMERO_SOMBRA],
      [sprintf("%d", @pokemon.iv[:DEFENSE]), DEF_IV_X, DEF_IV_Y, :right, COLOR_NUMERO_BASE, COLOR_NUMERO_SOMBRA],
      [sprintf("%d", @pokemon.ev[:DEFENSE]), DEF_EV_X, DEF_EV_Y, :right, COLOR_NUMERO_BASE, COLOR_NUMERO_SOMBRA],
      [_INTL("At. Esp."), SPA_LABEL_X, SPA_LABEL_Y, :left, COLOR_TEXTO_BASE, statshadows[:SPECIAL_ATTACK]],
      [@pokemon.spatk.to_s, SPA_VALUE_X, SPA_VALUE_Y, :right, COLOR_NUMERO_BASE, COLOR_NUMERO_SOMBRA],
      #[sprintf("%d", @pokemon.baseStats[:SPECIAL_ATTACK]), 408, 222, :right, COLOR_NUMERO_BASE, COLOR_NUMERO_SOMBRA],
      [sprintf("%d", @pokemon.iv[:SPECIAL_ATTACK]), SPA_IV_X, SPA_IV_Y, :right, COLOR_NUMERO_BASE, COLOR_NUMERO_SOMBRA],
      [sprintf("%d", @pokemon.ev[:SPECIAL_ATTACK]), SPA_EV_X, SPA_EV_Y, :right, COLOR_NUMERO_BASE, COLOR_NUMERO_SOMBRA],
      [_INTL("Def Esp."), SPDEF_LABEL_X, SPDEF_LABEL_Y, :left, COLOR_TEXTO_BASE, statshadows[:SPECIAL_DEFENSE]],
      [@pokemon.spdef.to_s, SPDEF_VALUE_X, SPDEF_VALUE_Y, :right, COLOR_NUMERO_BASE, COLOR_NUMERO_SOMBRA],
      #[sprintf("%d", @pokemon.baseStats[:SPECIAL_DEFENSE]), 408, 254, :right, COLOR_NUMERO_BASE, COLOR_NUMERO_SOMBRA],
      [sprintf("%d", @pokemon.iv[:SPECIAL_DEFENSE]), SPDEF_IV_X, SPDEF_IV_Y, :right, COLOR_NUMERO_BASE, COLOR_NUMERO_SOMBRA],
      [sprintf("%d", @pokemon.ev[:SPECIAL_DEFENSE]), SPDEF_EV_X, SPDEF_EV_Y, :right, COLOR_NUMERO_BASE, COLOR_NUMERO_SOMBRA],
      [_INTL("Velocidad"), SPEED_LABEL_X, SPEED_LABEL_Y, :left, COLOR_TEXTO_BASE, statshadows[:SPEED]],
      [@pokemon.speed.to_s, SPEED_VALUE_X, SPEED_VALUE_Y, :right, COLOR_NUMERO_BASE, COLOR_NUMERO_SOMBRA],
      #[sprintf("%d", @pokemon.baseStats[:SPEED]), 408, 286, :right, COLOR_NUMERO_BASE, COLOR_NUMERO_SOMBRA],
      [sprintf("%d", @pokemon.iv[:SPEED]), SPEED_IV_X, SPEED_IV_Y, :right, COLOR_NUMERO_BASE, COLOR_NUMERO_SOMBRA],
      [sprintf("%d", @pokemon.ev[:SPEED]), SPEED_EV_X, SPEED_EV_Y, :right, COLOR_NUMERO_BASE, COLOR_NUMERO_SOMBRA],
      [_INTL("EVs Totales"), TOTAL_EVS_LABEL_X, TOTAL_EVS_LABEL_Y, :left, COLOR_TEXTO_BASE, COLOR_TEXTO_SOMBRA],
      [sprintf("%d/%d", ev_total, Pokemon::EV_LIMIT), TOTAL_EVS_VALUE_X, TOTAL_EVS_VALUE_Y, :center, COLOR_NUMERO_BASE, COLOR_NUMERO_SOMBRA],
      [_INTL("Poder Oculto"), HIDDEN_POWER_LABEL_X, HIDDEN_POWER_LABEL_Y, :left, COLOR_TEXTO_BASE, COLOR_TEXTO_SOMBRA]
    ]
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    hiddenpower = pbHiddenPower(@pokemon)
    type_number = GameData::Type.get(hiddenpower[0]).icon_position
    type_rect = Rect.new(0, type_number * TYPE_ICON_HEIGHT, TYPE_ICON_WIDTH, TYPE_ICON_HEIGHT)
    overlay.blt(HIDDEN_POWER_ICON_X, HIDDEN_POWER_ICON_Y, @typebitmap.bitmap, type_rect)
  end
end