#===============================================================================
# Adds/edits various Summary utilities.
#===============================================================================
class PokemonSummary_Scene
  def drawPageAllStats
    overlay = @sprites["overlay"].bitmap
    base   = Color.new(248, 248, 248)
    shadow = Color.new(104, 104, 104)
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
      [_INTL("Total"), 381, 94, :center, base, shadow],
      [_INTL("IV"), 428, 94, :center, base, shadow],
      [_INTL("EV"), 473, 94, :center, base, shadow],
      [_INTL("PS"), 240, 126, :left, base, statshadows[:HP]],
      [@pokemon.totalhp.to_s, 400, 126, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      #[sprintf("%d", @pokemon.baseStats[:HP]), 408, 126, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [sprintf("%d", @pokemon.iv[:HP]), 440, 126, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [sprintf("%d", @pokemon.ev[:HP]), 480, 126, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [_INTL("Ataque"), 240, 158, :left, base, statshadows[:ATTACK]],
      [@pokemon.attack.to_s, 400, 158, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      #[sprintf("%d", @pokemon.baseStats[:ATTACK]), 408, 158, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [sprintf("%d", @pokemon.iv[:ATTACK]), 440, 158, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [sprintf("%d", @pokemon.ev[:ATTACK]), 480, 158, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [_INTL("Defensa"), 240, 190, :left, base, statshadows[:DEFENSE]],
      [@pokemon.defense.to_s, 400, 190, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      #[sprintf("%d", @pokemon.baseStats[:DEFENSE]), 408, 190, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [sprintf("%d", @pokemon.iv[:DEFENSE]), 440, 190, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [sprintf("%d", @pokemon.ev[:DEFENSE]), 480, 190, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [_INTL("At. Esp."), 240, 222, :left, base, statshadows[:SPECIAL_ATTACK]],
      [@pokemon.spatk.to_s, 400, 222, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      #[sprintf("%d", @pokemon.baseStats[:SPECIAL_ATTACK]), 408, 222, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [sprintf("%d", @pokemon.iv[:SPECIAL_ATTACK]), 440, 222, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [sprintf("%d", @pokemon.ev[:SPECIAL_ATTACK]), 480, 222, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [_INTL("Def Esp."), 240, 254, :left, base, statshadows[:SPECIAL_DEFENSE]],
      [@pokemon.spdef.to_s, 400, 254, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      #[sprintf("%d", @pokemon.baseStats[:SPECIAL_DEFENSE]), 408, 254, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [sprintf("%d", @pokemon.iv[:SPECIAL_DEFENSE]), 440, 254, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [sprintf("%d", @pokemon.ev[:SPECIAL_DEFENSE]), 480, 254, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [_INTL("Velocidad"), 240, 286, :left, base, statshadows[:SPEED]],
      [@pokemon.speed.to_s, 400, 286, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      #[sprintf("%d", @pokemon.baseStats[:SPEED]), 408, 286, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [sprintf("%d", @pokemon.iv[:SPEED]), 440, 286, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [sprintf("%d", @pokemon.ev[:SPEED]), 480, 286, :right, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [_INTL("EVs Totales"), 224, 324, :left, base, shadow],
      [sprintf("%d/%d", ev_total, Pokemon::EV_LIMIT), 435, 324, :center, Color.new(64, 64, 64), Color.new(176, 176, 176)],
      [_INTL("Poder Oculto"), 220, 356, :left, base, shadow]
    ]
    # Draw all text
    pbDrawTextPositions(overlay, textpos)
    typebitmap = AnimatedBitmap.new(_INTL("Graphics/UI/types"))
    hiddenpower = pbHiddenPower(@pokemon)
    type_number = GameData::Type.get(hiddenpower[0]).icon_position
    type_rect = Rect.new(0, type_number * 28, 64, 28)
    overlay.blt(405, 351, @typebitmap.bitmap, type_rect)
  end
end