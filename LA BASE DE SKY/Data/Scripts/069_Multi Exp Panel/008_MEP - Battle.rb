#===============================================================================
# CREDITOS
# Swdfm
#===============================================================================
if MOSTRAR_PANEL_REP_EXP

  class Battle
    def pbGainExp
      values = []
      moves  = {}
      # Play wild victory music if it's the end of the battle (has to be here)
      @scene.pbWildBattleSuccess if wildBattle? && pbAllFainted?(1) && !pbAllFainted?(0)
      return if !@internalBattle || !@expGain
      # Go through each battler in turn to find the Pokémon that participated in
      # battle against it, and award those Pokémon Exp/EVs
      expAll = $player.has_exp_all || $bag.has?(:EXPALL)
      p1 = pbParty(0)
      @battlers.each do |b|
        next unless b&.opposes?   # Can only gain Exp from fainted foes
        next if b.participants.length == 0
        next unless b.fainted? || b.captured
        # Count the number of participants
        numPartic = 0
        b.participants.each do |partic|
          next unless p1[partic]&.able? && pbIsOwner?(0, partic)
          numPartic += 1
        end
        # Find which Pokémon have an Exp Share
        expShare = []
        if !expAll
          eachInTeam(0, 0) do |pkmn, i|
            next if !pkmn.able?
            next if ( !pkmn.hasItem?(:EXPSHARE) && GameData::Item.try_get(@initialItems[0][i]) != :EXPSHARE ) ||  !pkmn&.expshare
            expShare.push(i)
          end
        end
        # Calculate EV and Exp gains for the participants
        if numPartic > 0 || expShare.length > 0 || expAll
          # Gain EVs and Exp for participants
          eachInTeam(0, 0) do |pkmn, i|
            next if !pkmn.able?
            unless b.participants.include?(i) || expShare.include?(i)
              values[i] = 0
              next
            end
            pbGainEVsOne(i, b)
            values[i] = pbGainExpOne_Panel(i, b, numPartic, expShare, expAll, !pkmn.shadowPokemon?)
          end
          # Gain EVs and Exp for all other Pokémon because of Exp All
          if expAll
            showMessage = true
            eachInTeam(0, 0) do |pkmn, i|
              next if !pkmn.able?
              next if b.participants.include?(i) || expShare.include?(i)
              #pbDisplayPaused(_INTL("Your other Pokémon also gained Exp. Points!")) if showMessage
              showMessage = false
              pbGainEVsOne(i, b)
              values[i] = pbGainExpOne_Panel(i, b, numPartic, expShare, expAll, false)
            end
          end
        end
        vr = []
        for v in values
          t_v = v ? v : 0
          vr.push(t_v)
        end
        values = vr
        s = Swdfm_Exp_Screen.new(values)
        # Clear the participants array
        for i in 0...$player.party.size
          next if values[i] == 0 || !values[i]
          pbActualLevelUpAndGatherMoves(i, values[i])
        end
        b.participants = []
      end
    end
    
    def pbGainExpOne_Panel(idxParty, defeatedBattler, numPartic, expShare, expAll, showMessages = true)
      pkmn = pbParty(0)[idxParty]   # The Pokémon gaining Exp from defeatedBattler
      growth_rate = pkmn.growth_rate
      # Don't bother calculating if gainer is already at max Exp
      if pkmn.exp >= growth_rate.maximum_exp
        pkmn.calc_stats   # To ensure new EVs still have an effect
        return 0
      end
      isPartic    = defeatedBattler.participants.include?(idxParty)
      hasExpShare = expShare.include?(idxParty)
      level = defeatedBattler.level
      # Main Exp calculation
      exp = 0
      a   = level * defeatedBattler.pokemon.base_exp
      if expShare.length > 0 && (isPartic || hasExpShare)
        if numPartic == 0   # No participants, all Exp goes to Exp Share holders
          exp = a / (Settings::SPLIT_EXP_BETWEEN_GAINERS ? expShare.length : 1)
        elsif Settings::SPLIT_EXP_BETWEEN_GAINERS   # Gain from participating and/or Exp Share
          exp = a / (2 * numPartic) if isPartic
          exp += a / (2 * expShare.length) if hasExpShare
        else   # Gain from participating and/or Exp Share (Exp not split)
          exp = (isPartic) ? a : a / 2
        end
      elsif isPartic   # Participated in battle, no Exp Shares held by anyone
        exp = a / (Settings::SPLIT_EXP_BETWEEN_GAINERS ? numPartic : 1)
      elsif expAll   # Didn't participate in battle, gaining Exp due to Exp All
        # NOTE: Exp All works like the Exp Share from Gen 6+, not like the Exp All
        #       from Gen 1, i.e. Exp isn't split between all Pokémon gaining it.
        exp = a / 2
      end
      return 0 if exp <= 0
      # Pokémon gain more Exp from trainer battles
      exp = (exp * 1.5).floor if trainerBattle?
      # Scale the gained Exp based on the gainer's level (or not)
      if Settings::SCALED_EXP_FORMULA
        exp /= 5
        levelAdjust = ((2 * level) + 10.0) / (pkmn.level + level + 10.0)
        levelAdjust = levelAdjust**5
        levelAdjust = Math.sqrt(levelAdjust)
        exp *= levelAdjust
        exp = exp.floor
        exp += 1 if isPartic || hasExpShare
      else
        exp /= 7
      end
      # Foreign Pokémon gain more Exp
      isOutsider = (pkmn.owner.id != pbPlayer.id ||
                   (pkmn.owner.language != 0 && pkmn.owner.language != pbPlayer.language))
      if isOutsider
        if pkmn.owner.language != 0 && pkmn.owner.language != pbPlayer.language
          exp = (exp * 1.7).floor
        else
          exp = (exp * 1.5).floor
        end
      end
      # Exp. Charm increases Exp gained
      exp = exp * 3 / 2 if $bag.has?(:EXPCHARM)
      # Modify Exp gain based on pkmn's held item
      i = Battle::ItemEffects.triggerExpGainModifier(pkmn.item, pkmn, exp)
      if i < 0
        i = Battle::ItemEffects.triggerExpGainModifier(@initialItems[0][idxParty], pkmn, exp)
      end
      exp = i if i >= 0
      # Boost Exp gained with high affection
      if Settings::AFFECTION_EFFECTS && @internalBattle && pkmn.affection_level >= 4 && !pkmn.mega?
        exp = exp * 6 / 5
        isOutsider = true   # To show the "boosted Exp" message
      end
      # Make sure Exp doesn't exceed the maximum
      expFinal = growth_rate.add_exp(pkmn.exp, exp)
      expGained = expFinal - pkmn.exp
      return 0 if expGained <= 0
      return expGained
    end
    
    def pbActualLevelUpAndGatherMoves(idxParty, expGained)
      pkmn = pbParty(0)[idxParty]
      $stats.total_exp_gained += expGained
      battler  = pbFindBattler(idxParty)
      new_lvl  = pkmn.growth_rate.level_from_exp(pkmn.exp + expGained)
      moves    = []
      moveList = pkmn.getMoveList
      for level in (pkmn.level + 1)..new_lvl
        pkmn.changeHappiness("levelup")
        moveList.each { |m| moves.push(m[1]) if m[0] == level }
      end
      # Actual adding of exp
      pkmn.exp = pkmn.exp + expGained
      pkmn.calc_stats
      battler&.pbUpdate(false)
      @scene.pbRefreshOne(battler.index) if battler
      return if moves.empty?
    moves.each { |m|
        pbLearnMove(idxParty, m)
    }
    end
  end

end
