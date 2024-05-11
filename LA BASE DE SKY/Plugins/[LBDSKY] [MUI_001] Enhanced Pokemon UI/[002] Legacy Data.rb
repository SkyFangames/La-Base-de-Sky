#===============================================================================
# Adds various trackers for Legacy data.
#===============================================================================

#-------------------------------------------------------------------------------
# Tracks item consumption.
#-------------------------------------------------------------------------------
module ItemHandlers
  def self.triggerUseOnPokemon(item, qty, pkmn, scene)
    return false if !UseOnPokemon[item]
    ret = UseOnPokemon.trigger(item, qty, pkmn, scene)
    if GameData::Item.get(item).consumed_after_use?
      pkmn.legacy_data[:item_count] += qty
    end
    return ret
  end
  
  def self.triggerBattleUseOnBattler(item, battler, scene)
    return false if !BattleUseOnBattler[item]
    ret = BattleUseOnBattler.trigger(item, battler, scene)
    if ret && GameData::Item.get(item).consumed_after_use?
      battler.pokemon.legacy_data[:item_count] += 1
    end
    return ret
  end

  def self.triggerBattleUseOnPokemon(item, pkmn, battler, choices, scene)
    return false if !BattleUseOnPokemon[item]
    ret = BattleUseOnPokemon.trigger(item, pkmn, battler, choices, scene)
    if ret && GameData::Item.get(item).consumed_after_use?
      pkmn.legacy_data[:item_count] += 1
    end
    return ret
  end
end

class Battle::Battler
  alias legacy_pbConsumeItem pbConsumeItem
  def pbConsumeItem(*args)
    @pokemon.legacy_data[:item_count] += 1
    legacy_pbConsumeItem(*args)
  end
end

#-------------------------------------------------------------------------------
# Tracks moves learned.
#-------------------------------------------------------------------------------
class Pokemon
  alias legacy_learn_move learn_move
  def learn_move(move_id)
    if GameData::Move.exists?(move_id) && !@moves.include?(move_id)
      legacy_data[:move_count] += 1
    end
    legacy_learn_move(move_id)
  end
end

class Battle::Scene
  alias legacy_pbForgetMove pbForgetMove
  def pbForgetMove(pkmn, moveToLearn)
    ret = legacy_pbForgetMove(pkmn, moveToLearn)
    pkmn.legacy_data[:move_count] += 1 if ret >= 0
    return ret
  end
end

alias legacy_pbForgetMove pbForgetMove
def pbForgetMove(pkmn, moveToLearn)
  ret = legacy_pbForgetMove(pkmn, moveToLearn)
  pkmn.legacy_data[:move_count] += 1 if ret >= 0
  return ret
end

#-------------------------------------------------------------------------------
# Tracks eggs produced.
#-------------------------------------------------------------------------------
class DayCare
  class DayCareSlot
    def add_egg_count(amt = 1)
      @pokemon.legacy_data[:egg_count] += amt
    end
  end
  
  def update_on_step_taken
    @step_counter += 1
    if @step_counter >= 256
      @step_counter = 0
      if !@egg_generated && count == 2
        compat = compatibility
        egg_chance = [0, 20, 50, 70][compat]
        egg_chance = [0, 40, 80, 88][compat] if $bag.has?(:OVALCHARM)
        @egg_generated = true if rand(100) < egg_chance
        @slots.each { |slot| slot.add_egg_count }
      end
      share_egg_move if @share_egg_moves && rand(100) < 50
    end
    if @gain_exp
      @slots.each { |slot| slot.add_exp }
    end
  end
  
  def egg_generated=(value)
    @egg_generated = value
    if @egg_generated
      @slots.each { |slot| slot.add_egg_count }
    end
  end
end

#-------------------------------------------------------------------------------
# Tracks number of trades.
#-------------------------------------------------------------------------------
def pbStartTrade(pokemonIndex, newpoke, nickname, trainerName, trainerGender = 0)
  $stats.trade_count += 1
  myPokemon = $player.party[pokemonIndex]
  myPokemon.legacy_data[:trade_count] += 1
  yourPokemon = nil
  resetmoves = true
  if newpoke.is_a?(Pokemon)
    newpoke.owner = Pokemon::Owner.new_foreign(trainerName, trainerGender)
    yourPokemon = newpoke
    resetmoves = false
  else
    species_data = GameData::Species.try_get(newpoke)
    raise _INTL("Species {1} does not exist.", newpoke) if !species_data
    yourPokemon = Pokemon.new(species_data.id, myPokemon.level)
    yourPokemon.owner = Pokemon::Owner.new_foreign(trainerName, trainerGender)
  end
  yourPokemon.name          = nickname
  yourPokemon.obtain_method = 2
  yourPokemon.reset_moves if resetmoves
  yourPokemon.record_first_moves
  yourPokemon.legacy_data[:trade_count] += 1
  pbFadeOutInWithMusic do
    evo = PokemonTrade_Scene.new
    evo.pbStartScreen(myPokemon, yourPokemon, $player.name, trainerName)
    evo.pbTrade
    evo.pbEndScreen
  end
  $player.party[pokemonIndex] = yourPokemon
end

#-------------------------------------------------------------------------------
# Tracks opponents defeated.
#-------------------------------------------------------------------------------
class Battle::Battler
  alias legacy_pbEffectsOnMakingHit pbEffectsOnMakingHit
  def pbEffectsOnMakingHit(move, user, target)
    legacy_pbEffectsOnMakingHit(move, user, target)
    if target.opposes?(user) && target.damageState.calcDamage > 0 && target.fainted?
      user.pokemon.legacy_data[:defeated_count] += 1
    end
  end
  
#-------------------------------------------------------------------------------
# Tracks number of times fainted.
#-------------------------------------------------------------------------------
  alias legacy_pbFaint pbFaint
  def pbFaint(showMessage = true)
    preFainted = pbOwnedByPlayer? && fainted? && !@fainted
    legacy_pbFaint(showMessage)
    @pokemon.legacy_data[:fainted_count] += 1 if preFainted
  end
end

#-------------------------------------------------------------------------------
# Tracks supereffective hits dealt.
#-------------------------------------------------------------------------------
class Battle::Move
  alias legacy_pbEffectivenessMessage pbEffectivenessMessage
  def pbEffectivenessMessage(user, target, numTargets = 1)
    legacy_pbEffectivenessMessage(user, target, numTargets = 1)
    return if self.is_a?(Battle::Move::FixedDamageMove)
    return if target.damageState.disguise || target.damageState.iceFace
    if Effectiveness.super_effective?(target.damageState.typeMod)
      user.pokemon.legacy_data[:supereff_count] += 1
    end
  end

#-------------------------------------------------------------------------------
# Tracks critical hits dealt.
#-------------------------------------------------------------------------------
  alias legacy_pbHitEffectivenessMessages pbHitEffectivenessMessages
  def pbHitEffectivenessMessages(user, target, numTargets = 1)
    legacy_pbHitEffectivenessMessages(user, target, numTargets = 1)
    return if target.damageState.disguise || target.damageState.iceFace
    if target.damageState.critical
      user.pokemon.legacy_data[:critical_count] += 1
    end
  end
end

#-------------------------------------------------------------------------------
# Tracks number of times retreated.
#-------------------------------------------------------------------------------
class Battle
  alias legacy_pbRun pbRun
  def pbRun(idxBattler, duringBattle = false)
    ret = legacy_pbRun(idxBattler, duringBattle)
    pkmn = @battlers[idxBattler].pokemon
    pkmn.legacy_data[:retreat_count] += 1 if ret == 1 && !pkmn.fainted?
    return ret
  end
  
  alias legacy_pbMessageOnRecall pbMessageOnRecall
  def pbMessageOnRecall(battler)
    legacy_pbMessageOnRecall(battler)
    if battler.pbOwnedByPlayer?
      battler.pokemon.legacy_data[:retreat_count] += 1
    end
  end
  
#-------------------------------------------------------------------------------
# Tracks a variety of statistics.
#-------------------------------------------------------------------------------
  alias legacy_pbEndOfBattle pbEndOfBattle
  def pbEndOfBattle
    ret = legacy_pbEndOfBattle
    case ret
    when 1
      #-------------------------------------------------------------------------
      # Tracks trainer and Gym Leader battle victories.
      #-------------------------------------------------------------------------
      if trainerBattle?
        @opponent.each_with_index do |trainer, i|
          ttype = trainer.trainer_type
          tname = GameData::TrainerType.get(ttype).name
          pbParty(0).each_with_index do |pkmn, i|
            next if !pkmn || pkmn.egg?
            pkmn.legacy_data[:trainer_count] += 1
            if tname == _INTL("Gym Leader")
              pkmn.legacy_data[:leader_count] += 1
            end
          end
        end
      #-------------------------------------------------------------------------
      # Tracks wild legendary battle victories. (defeated)
      #-------------------------------------------------------------------------
      else
        pbParty(1).each do |foe|
          sp_data = foe.species_data
          if sp_data.has_flag?("Legendary") || sp_data.has_flag?("Mythical")
            pbParty(0).each_with_index do |pkmn, i|
              next if !pkmn || pkmn.egg?
              pkmn.legacy_data[:legend_count] += 1
            end
          end
        end
      end
    when 2, 5
      #-------------------------------------------------------------------------
      # Tracks total draws/losses.
      #-------------------------------------------------------------------------
      pbParty(0).each_with_index do |pkmn, i|
        next if !pkmn || pkmn.egg?
        pkmn.legacy_data[:loss_count] += 1
      end
    end
    return ret
  end
end

#-------------------------------------------------------------------------------
# Tracks wild legendary battle victories. (captured)
#-------------------------------------------------------------------------------
module Battle::CatchAndStoreMixin
  alias legacy_pbRecordAndStoreCaughtPokemon pbRecordAndStoreCaughtPokemon
  def pbRecordAndStoreCaughtPokemon
    @caughtPokemon.each do |caught|
      sp_data = caught.species_data
      if sp_data.has_flag?("Legendary") || sp_data.has_flag?("Mythical")
        pbParty(0).each_with_index do |pkmn, i|
          next if !pkmn || pkmn.egg?
          pkmn.legacy_data[:legend_count] += 1
        end
      end
    end
    legacy_pbRecordAndStoreCaughtPokemon
  end
end

#-------------------------------------------------------------------------------
# Tracks inductions into Hall of Fame.
#-------------------------------------------------------------------------------
alias legacy_pbHallOfFameEntry pbHallOfFameEntry
def pbHallOfFameEntry
  legacy_pbHallOfFameEntry
  $player.pokemon_party.each do |pkmn|
    pkmn.legacy_data[:champion_count] += 1
  end
end

#-------------------------------------------------------------------------------
# Tracks time spent in party.
#-------------------------------------------------------------------------------
class Player < Trainer
  def update_party_time
    @party.each { |p| p.update_party_time }
  end
  
  def last_update_time(time = nil)
    time = System.uptime if !time
    @party.each { |p| p.last_update_time = time}
  end
end

#-------------------------------------------------------------------------------
# Resets last update time when saved game is loaded.
#-------------------------------------------------------------------------------
alias legacy_pbAutoplayOnSave pbAutoplayOnSave
def pbAutoplayOnSave
  legacy_pbAutoplayOnSave
  $player.last_update_time(System.uptime)
end

#-------------------------------------------------------------------------------
# Recalculates party time whenever the pause menu is opened.
#-------------------------------------------------------------------------------
class PokemonPauseMenu
  alias legacy_pbStartPokemonMenu pbStartPokemonMenu
  def pbStartPokemonMenu
    $player.update_party_time
    legacy_pbStartPokemonMenu
    $player.last_update_time(System.uptime)
  end
end

#-------------------------------------------------------------------------------
# Recalculates party time whenever the storage screen is opened.
#-------------------------------------------------------------------------------
class PokemonStorageScreen
  alias legacy_pbStartScreen pbStartScreen
  def pbStartScreen(command)
    $player.update_party_time
    legacy_pbStartScreen(command)
    $player.last_update_time(System.uptime)
  end
end

#-------------------------------------------------------------------------------
# Recalculates party time whenever depositing/withdrawing from Day Care.
#-------------------------------------------------------------------------------
class DayCare
  def self.deposit(party_index)
    $stats.day_care_deposits += 1
    day_care = $PokemonGlobal.day_care
    pkmn = $player.party[party_index]
    pkmn.update_party_time
    raise _INTL("No Pokémon at index {1} in party.", party_index) if pkmn.nil?
    day_care.slots.each do |slot|
      next if slot.filled?
      slot.deposit(pkmn)
      $player.party.delete_at(party_index)
      day_care.reset_egg_counters
      return
    end
    raise _INTL("No room to deposit a Pokémon.")
  end

  def self.withdraw(index)
    day_care = $PokemonGlobal.day_care
    slot = day_care[index]
    if !slot.filled?
      raise _INTL("No Pokémon found in slot {1}.", index)
    elsif $player.party_full?
      raise _INTL("No room in party for Pokémon.")
    end
    $stats.day_care_levels_gained += slot.level_gain
    slot.pokemon.last_update_time = System.uptime
    $player.party.push(slot.pokemon)
    slot.reset
    day_care.reset_egg_counters
  end
end


#===============================================================================
# Pokemon data.
#===============================================================================
class Pokemon
  #-----------------------------------------------------------------------------
  # Shiny leaf data.
  #-----------------------------------------------------------------------------
  attr_accessor :shiny_leaf
  
  def shiny_leaf;   return @shiny_leaf || 0; end
  def shiny_leaf?;  return shiny_leaf > 0;   end
  def shiny_crown?; return shiny_leaf == 6;  end
  
  def shiny_leaf=(value)
    @shiny_leaf = value.clamp(0, 6)
  end
  
  #-----------------------------------------------------------------------------
  # Tracks time spent in party.
  #-----------------------------------------------------------------------------
  def last_update_time
    return @last_update_time || 0.0
  end
  
  def last_update_time=(value)
    @last_update_time = value
  end
  
  def update_party_time
    now = System.uptime
    legacy_data[:party_time] += (now - self.last_update_time)
  end
  
  #-----------------------------------------------------------------------------
  # Default Legacy data.
  #-----------------------------------------------------------------------------
  def legacy_data
    if !@legacy_data
      @legacy_data = {
        :party_time     => 0,
        :item_count     => 0,
        :move_count     => 0,
        :egg_count      => 0,
        :trade_count    => 0,
        :defeated_count => 0,
        :fainted_count  => 0,
        :supereff_count => 0,
        :critical_count => 0,
        :retreat_count  => 0,
        :trainer_count  => 0,
        :leader_count   => 0,
        :legend_count   => 0,
        :champion_count => 0,
        :loss_count     => 0
      }
    end
    return @legacy_data
  end
  
  #-----------------------------------------------------------------------------
  # Initializes new data.
  #-----------------------------------------------------------------------------
  alias enhanced_initialize initialize  
  def initialize(*args)
    enhanced_initialize(*args)
    @shiny_leaf = 0
    @last_update_time = 0.0
    legacy_data
  end
end