#===============================================================================
# Implements new Battle Rules.
#===============================================================================
class Game_Temp
  attr_accessor :old_player_data, :old_player_bag, :old_player_party, :inverse_battle
  
  alias dx_add_battle_rule add_battle_rule
  def add_battle_rule(rule, var = nil)
    rules = self.battle_rules
    case rule.to_s.downcase
    when "alwayscapture"     then rules["captureSuccess"]    = true
    when "nevercapture"      then rules["captureSuccess"]    = false
    when "tutorialcapture"   then rules["captureTutorial"]   = true
    when "autobattle"        then rules["autoBattle"]        = true
    when "towerbattle"       then rules["internalBattle"]       = false
    when "inversebattle"     then rules["inverseBattle"]     = true
    when "nobag"             then rules["noBag"]             = true
    when "wildmegaevolution" then rules["wildBattleMode"]    = :mega
    when "raidstylecapture"  then rules["raidStyleCapture"]  = var
    when "setslidesprite"    then rules["slideSpriteStyle"]  = var
    when "databoxstyle"      then rules["databoxStyle"]      = var
    when "battleintrotext"   then rules["battleIntroText"]   = var
    when "opponentwintext"   then rules["opposingWinText"]   = var
    when "opponentlosetext"  then rules["opposingLoseText"]  = var
    when "tempplayer"        then rules["tempPlayer"]        = var
    when "tempbag"           then rules["tempBag"]           = var
    when "tempparty"         then rules["tempParty"]         = var
    when "battlebgm"         then rules["battleBGM"]         = var
    when "victorybgm"        then rules["victoryBGM"]        = var
    when "captureme"         then rules["captureME"]         = var
    when "lowhealthbgm"      then rules["lowHealthBGM"]      = var
    when "editwildpokemon"   then rules["editWildPokemon"]   = var
    when "editwildpokemon2"  then rules["editWildPokemon2"]  = var
    when "editwildpokemon3"  then rules["editWildPokemon3"]  = var
    when "nomegaevolution"   then rules["noMegaEvolution"]   = var
    when "midbattlescript"   then rules["midbattleScript"]   = var
    else
      dx_add_battle_rule(rule, var)
    end
  end
end

def setBattleRule(*args)
  r = nil
  args.each do |arg|
    if r
      case r
      when "editWildPokemon2"
        if !$game_temp.battle_rules["editWildPokemon"]
          $game_temp.add_battle_rule("editWildPokemon", {})
        end
      when "editWildPokemon3"
        if !$game_temp.battle_rules["editWildPokemon"]
          $game_temp.add_battle_rule("editWildPokemon", {})
        end
        if !$game_temp.battle_rules["editWildPokemon2"]
          $game_temp.add_battle_rule("editWildPokemon2", {})
        end
      end
      $game_temp.add_battle_rule(r, arg)
      r = nil
    else
      case arg.downcase
      when "terrain", "weather", "environment", "environ", "backdrop",
           "battleback", "base", "outcome", "outcomevar"
        r = arg
        next
      end
      if additionalRules.include?(arg.downcase)
        r = arg
        next
      end
      $game_temp.add_battle_rule(arg)
    end
  end
  raise _INTL("Argument {1} expected a variable after it but didn't have one.", r) if r
end


def additionalRules
  return [
    "raidstylecapture", "setslidesprite", "databoxstyle",
    "battleintrotext", "opponentwintext", "opponentlosetext",
    "tempplayer", "tempbag", "tempparty", 
    "battlebgm", "victorybgm", "captureme", "lowhealthbgm", 
    "editwildpokemon", "editwildpokemon2", "editwildpokemon3", 
    "midbattlescript", "nomegaevolution"
  ]
end

#===============================================================================
# Sets new Battle Rules during battle prep.
#===============================================================================
module BattleCreationHelperMethods
  module_function
  
  BattleCreationHelperMethods.singleton_class.alias_method :dx_prepare_battle, :prepare_battle
  def prepare_battle(battle)
    return BattleCreationHelperMethods.dx_prepare_battle(battle) if pbInSafari?
    battleRules = $game_temp.battle_rules
    battle.captureSuccess     = battleRules["captureSuccess"]   if !battleRules["captureSuccess"].nil?
    battle.tutorialCapture    = battleRules["captureTutorial"]  if !battleRules["captureTutorial"].nil?
    battle.raidStyleCapture   = battleRules["raidStyleCapture"] if !battleRules["raidStyleCapture"].nil?
    battle.wildBattleMode     = battleRules["wildBattleMode"]   if !battleRules["wildBattleMode"].nil?
    battle.controlPlayer      = battleRules["autoBattle"]       if !battleRules["autoBattle"].nil?
    battle.internalBattle     = battleRules["internalBattle"]   if !battleRules["internalBattle"].nil?
    battle.noBag              = battleRules["noBag"]            if !battleRules["noBag"].nil?
    battle.introText          = battleRules["battleIntroText"]  if !battleRules["battleIntroText"].nil?
    battle.slideSpriteStyle   = battleRules["slideSpriteStyle"] if !battleRules["slideSpriteStyle"].nil?
    battle.databoxStyle       = battleRules["databoxStyle"]     if !battleRules["databoxStyle"].nil?
    if !battleRules["midbattleScript"].nil?
      script = battleRules["midbattleScript"]
      if script.is_a?(Symbol)
        if MidbattleHandlers.exists?(:midbattle_scripts, script)
          battle.midbattleScript = script
        elsif hasConst?(MidbattleScripts, script)
          battle.midbattleScript = getConst(MidbattleScripts, script).clone
        end
      else
        battle.midbattleScript = script
      end
    end
    if battle.opponent
      if battleRules["opposingWinText"]
        case battleRules["opposingWinText"]
        when String
          battle.opponent[0].win_text = battleRules["opposingWinText"]
        when Array
          battleRules["opposingWinText"].each_with_index do |text, i|
            next if !text || !battle.opponent[i]
            battle.opponent[i].win_text = text
          end
        end
      end
      if battleRules["opposingLoseText"]
        case battleRules["opposingLoseText"]
        when String
          battle.opponent[0].lose_text = battleRules["opposingLoseText"]
        when Array
          battleRules["opposingLoseText"].each_with_index do |text, i|
            next if !text || !battle.opponent[i]
            battle.opponent[i].lose_text = text
          end
        end
      end
    end
    specialActions = [
      "noMegaEvolution",          
      "noZMoves", "noUltraBurst", # Z-Power Add-on
      "noDynamax",                # Dynamax Add-on
      "noTerastallize",           # Terastallization Add-on
      #"noBattleStyles",           # PLA Battle Styles (TBD)
      #"noZodiacPowers",           # Pokemon Birthsigns (TBD)
      #"noFocusMeter"              # Focus Meter System (TBD)
    ]
    specialActions.each do |rule|
      next if !battleRules[rule]
      case rule
      when "noMegaEvolution" then action = battle.megaEvolution
      when "noZMoves"        then action = battle.zMove
      when "noUltraBurst"    then action = battle.ultraBurst
      when "noDynamax"       then action = battle.dynamax
      when "noTerastallize"  then action = battle.terastallize
      #when "noBattleStyles"  then action = battle.style
      #when "noZodiacPowers"  then action = battle.zodiac
      #when "noFocusMeter"    then action = battle.focus
      end
      case battleRules[rule]
      when :All      then sides = [0, 1]
      when :Player   then sides = [0]
      when :Opponent then sides = [1]
      else                sides = []
      end
      sides.each do |side|
        action[side].length.times do |i|
          action[side][i] = -2
        end
      end
    end
    BattleCreationHelperMethods.dx_prepare_battle(battle)
    $PokemonGlobal.nextBattleBGM          = battleRules["battleBGM"]    if !battleRules["battleBGM"].nil?
    $PokemonGlobal.nextBattleVictoryBGM   = battleRules["victoryBGM"]   if !battleRules["victoryBGM"].nil?
    $PokemonGlobal.nextBattleCaptureME    = battleRules["captureME"]    if !battleRules["captureME"].nil?
    battle.low_hp_bgm = battleRules["lowHealthBGM"] if !battleRules["lowHealthBGM"].nil?
    track = (battle.wildBattle?) ? pbGetWildBattleBGM(battle.pbParty(1)) : pbGetTrainerBattleBGM(battle.opponent)
    battle.default_bgm = (track.is_a?(String)) ? track : track&.name
    battle.playing_bgm = battle.default_bgm
  end
end

#===============================================================================
# Edits for Battle Rules related to capturing Pokemon.
#===============================================================================
module Battle::CatchAndStoreMixin
  alias dx_pbCaptureCalc pbCaptureCalc
  def pbCaptureCalc(*args)
    case @captureSuccess
    when nil   then ret = dx_pbCaptureCalc(*args) 
    when true  then ret = 4
    when false then ret = 0
    end
    @poke_ball_failed = false if ret == 4
    return ret
  end
  
  alias dx_pbRecordAndStoreCaughtPokemon pbRecordAndStoreCaughtPokemon
  def pbRecordAndStoreCaughtPokemon
    return if @tutorialCapture
    dx_pbRecordAndStoreCaughtPokemon
  end
  
  alias dx_pbStorePokemon pbStorePokemon
  def pbStorePokemon(pkmn)
    pkmn.makeUnmega
    pkmn.makeUnprimal
    pkmn.makeUnUltra if pkmn.ultra?
    pkmn.dynamax       = false if pkmn.dynamax?
    pkmn.terastallized = false if pkmn.tera?
    if pkmn.hp_level > 0
      pkmn.hp_level = 0
      pkmn.calc_stats
      pkmn.hp = pkmn.hp.clamp(1, pkmn.totalhp)
    end
    raidBoss = pkmn.immunities.include?(:RAIDBOSS)
    pkmn.immunities = nil
    pkmn.name = nil if pkmn.nicknamed?
    pbResetRaidProperties(pkmn) if raidBoss
    return if raidBoss
    if @raidStyleCapture && !@caughtPokemon.empty?
      if Settings::HEAL_STORED_POKEMON
        old_ready_evo = pkmn.ready_to_evolve
        pkmn.heal
        pkmn.ready_to_evolve = old_ready_evo
      else
        pkmn.hp = 1
      end
      stored_box = $PokemonStorage.pbStoreCaught(pkmn)
      box_name = @peer.pbBoxName(stored_box)
      pbDisplayPaused(_INTL("{1} has been sent to Box \"{2}\"!", pkmn.name, box_name))
    else
      dx_pbStorePokemon(pkmn)
    end
  end
end

#===============================================================================
# Utilities for battle_rules["raidStyleCapture"].
#===============================================================================
class Battle::Battler
  def pbRaidStyleCapture(target, chance = nil, fleeMsg = nil, bgm = nil)
    fainted_count = 0
    @battle.battlers.each do |b|
      next if !b || !b.opposes?(target) || b.hp > 0
      fainted_count += 1
    end
    return if fainted_count >= @battle.pbSideSize(0)
    if @battle.pbAbleCount(target.index) <= 1
      @battle.raidCaptureMode = true
      @battle.field.initialize
      2.times { |i| @battle.sides[i].initialize }
      @battle.eachSameSideBattler do |b|
        b.pbInitEffects(false)
        @battle.positions[b.index].initialize
      end
    end
    @battle.pbPauseAndPlayBGM(bgm)
    @battle.scene.pbHideDatabox(target.index)
    @battle.scene.pbToggleDataboxes if @battle.raidBattle?
    @battle.pbDisplayPaused(_INTL("{1} is weak!\nThrow a Poké Ball now!", target.pbThis))
    @battle.scene.pbRevertBattlerStart
    @battle.scene.pbPauseScene(0.5)
    cmd = @battle.pbShowCommands(
      _INTL("Capture {1}?", target.pbThis(true)), ["Catch", "Don't Catch"], 1)
    pbPlayDecisionSE
    @battle.scene.pbRevertBattlerEnd
    case cmd
    when 0
      @battle.sendToBoxes = 1
      if $PokemonStorage.full?
        @battle.pbDisplay(_INTL("But there is no room left in the PC!"))
        target.wild_flee(fleeMsg)
      else
        ball = nil
        pbFadeOutIn {
          scene  = PokemonBag_Scene.new
          screen = PokemonBagScreen.new(scene, $bag)
          ball   = screen.pbChooseItemScreen(Proc.new{ |item| GameData::Item.get(item).is_poke_ball? })
        }
        if ball
          $bag.remove(ball, 1)
          if !chance.nil? && chance > 0
            r = rand(100)
            capture = r < chance || ball == :MASTERBALL || ($DEBUG && Input.press?(Input::CTRL))
            @battle.captureSuccess = capture
          end
          @battle.pbThrowPokeBall(target.index, ball)
          target.wild_flee(fleeMsg) if @battle.poke_ball_failed
        else
          target.wild_flee(fleeMsg)
        end
      end
    else
      target.wild_flee(fleeMsg)
    end
  end
  
  def canRaidCapture?
    return false if !@battle.raidStyleCapture # Only if raid style capture enabled.
    return false if @battle.trainerBattle?    # Only in wild battles.
    return false if @battle.decision > 0      # Only if battle outcome hasn't already been decided.
    return false if @battle.pbAllFainted?     # Only if the player still has usable Pokemon.
    return false if !self.wild?               # Only if battler is a wild Pokemon.
    return false if self.hp > 0               # Only if battler's HP has reached zero.
    return false if @fainted                  # Only if battler hasn't already properly fainted.
    return true
  end
  
  def wild_flee(fleeMsg = nil)
    return if !wild?
    @battle.scene.pbBattlerFlee(self, fleeMsg)
    @hp = 0
    pbInitEffects(false)
    @status = :NONE
    @statusCount = 0
    @battle.pbClearChoice(@index)
    if @battle.pbAbleCount(@index) > 1
      @battle.pbEndPrimordialWeather
      @battle.pbRemoveFromParty(@index, @pokemonIndex)
    else
      @battle.decision = (self.isRaidBoss?) ? 1 : 3
    end
  end
  
  alias dx_pbFaint pbFaint
  def pbFaint(showMessage = true)
    if self.canRaidCapture?
      self.hp = 1
      if defined?(@vanished)
        @battle.scene.pbAnimateSubstitute(@index, :hide)
        @effects[PBEffects::Substitute]    = 0
        @effects[PBEffects::SkyDrop]       = -1
        @effects[PBEffects::TwoTurnAttack] = nil
        @battle.scene.pbChangePokemon(self, self.visiblePokemon, true)
      end
      raid = @battle.raidStyleCapture
      if raid.is_a?(Hash)
        pbRaidStyleCapture(self, raid[:capture_chance], raid[:flee_msg], raid[:capture_bgm])
      else
        pbRaidStyleCapture(self)
      end
    else
      dx_pbFaint(showMessage)
      if @battle.pbAllFainted? && @battle.raidStyleCapture && !@battle.canLose
        @battle.caughtPokemon.clear
      end
    end
  end

  alias dx_itemActive? itemActive?
  def itemActive?(ignoreFainted = false)
    return false if @battle.raidCaptureMode
    return dx_itemActive?(ignoreFainted)
  end
  
  alias dx_abilityActive? abilityActive?
  def abilityActive?(ignore_fainted = false, check_ability = nil)
    return false if @battle.raidCaptureMode
    return dx_abilityActive?(ignore_fainted, check_ability)
  end
end

#===============================================================================
# Edited for battle_rules["inverseBattle"].
#===============================================================================
module GameData
  class Type
    alias dx_effectiveness effectiveness
    def effectiveness(other_type)
      return Effectiveness::NORMAL_EFFECTIVE_ONE if !other_type
      ret = dx_effectiveness(other_type)
      if $game_temp.inverse_battle
        case ret
        when Effectiveness::INEFFECTIVE, Effectiveness::NOT_VERY_EFFECTIVE
          ret = Effectiveness::SUPER_EFFECTIVE
        when Effectiveness::SUPER_EFFECTIVE
          ret = Effectiveness::NOT_VERY_EFFECTIVE
        end
      end
      return ret
    end
  end
end

#===============================================================================
# Adds new Battle Rules to the Battle class.
#===============================================================================
class Battle
  attr_accessor :caughtPokemon, :captureSuccess, :tutorialCapture, :raidStyleCapture, :raidCaptureMode
  attr_accessor :wildBattleMode, :noBag
  attr_accessor :introText, :slideSpriteStyle, :databoxStyle
  attr_accessor :default_bgm, :playing_bgm, :bgm_paused, :bgm_position, :low_hp_bgm
  
  alias dx_initialize initialize
  def initialize(*args)
    dx_initialize(*args)
    @captureSuccess   = nil
    @tutorialCapture  = false
    @raidStyleCapture = false
    @raidCaptureMode  = false
    @wildBattleMode   = nil
    @noBag            = false
    @introText        = nil
    @slideSpriteStyle = nil
    @databoxStyle     = nil
    @bgm_paused       = false
    @bgm_position     = 0
    @default_bgm      = nil
    @playing_bgm      = nil
    @low_hp_bgm       = "Battle low HP"
  end
  
  #-----------------------------------------------------------------------------
  # Battle music utilities.
  #-----------------------------------------------------------------------------
  def pbGetBattleBGM
    return nil if nil_or_empty?(@default_bgm)
    return pbResolveAudioFile(@default_bgm)
  end
  
  def pbGetBattleLowHealthBGM
    return "" if nil_or_empty?(@low_hp_bgm)
    return pbResolveAudioFile(@low_hp_bgm)
  end
  
  def pbResumeBattleBGM
    return if !@bgm_paused
    track = pbGetBattleBGM
    return if !track.is_a?(RPG::AudioFile)
    track_name = canonicalize("Audio/BGM/" + track.name)
    $game_system.bgm_play_internal2(track_name, track.volume, track.pitch, @bgm_position)
    @bgm_position = 0
    @bgm_paused = false
    @playing_bgm = track.name
    Graphics.frame_reset
  end
  
  def pbPauseAndPlayBGM(track)
    return if @bgm_paused
    track = pbResolveAudioFile(track) if track != ""
    return if !track.is_a?(RPG::AudioFile)
    pos = Audio.bgm_pos rescue 0
    @bgm_position = pos
    @bgm_paused = true
    track_name = canonicalize("Audio/BGM/" + track.name)
    $game_system.bgm_play_internal2(track_name, track.volume, track.pitch, 0)
    @playing_bgm = track.name
    Graphics.frame_reset
  end
  
  #-----------------------------------------------------------------------------
  # Aliased for battle_rules["noBag"]
  #-----------------------------------------------------------------------------
  alias dx_pbItemMenu pbItemMenu
  def pbItemMenu(idxBattler, firstAction)
    if @noBag
      pbDisplay(_INTL("Items can't be used in this battle."))
      return false
    end
    return dx_pbItemMenu(idxBattler, firstAction)
  end

  #-----------------------------------------------------------------------------
  # Aliased for battle_rules["raidStyleCapture"]
  #-----------------------------------------------------------------------------
  alias dx_pbEORStatusProblemDamage pbEORStatusProblemDamage
  def pbEORStatusProblemDamage(priority)
    return if @raidCaptureMode
    dx_pbEORStatusProblemDamage(priority)
  end
  
  #-----------------------------------------------------------------------------
  # Aliased for battle_rules["battleIntroText"]
  #-----------------------------------------------------------------------------
  alias dx_pbStartBattleSendOut pbStartBattleSendOut
  def pbStartBattleSendOut(sendOuts)
    @scene.pbAnimateTrainerIntros if defined?(@scene.pbAnimateTrainerIntros)
    if @introText
      foes = @opponent || pbParty(1)
      foe_names = []
      foes.each do |foe|
        name = (wildBattle?) ? foe.name : foe.full_name
        foe_names.push(name)
      end
      pbDisplayPaused(_INTL("#{@introText}", *foe_names))
      [1, 0].each do |side|
        next if side == 1 && wildBattle?
        msg = ""
        toSendOut = []
        trainers = (side == 0) ? @player.reverse : @opponent
        trainers.each_with_index do |t, i|
          msg += "\r\n" if msg.length > 0
          if side == 0 && i == trainers.length - 1
            msg += "Go! "
            sent = sendOuts[side][0]
          else
            msg += "#{t.full_name} sent out "
            sent = (side == 0) ? sendOuts[0][1] : sendOuts[1][i]
          end
          sent.each_with_index do |idxBattler, j|
            if j > 0
              msg += (j == sent.length - 1) ? " and " : ", "
            end
            if defined?(@battlers[idxBattler].name_title)
              msg += @battlers[idxBattler].name_title
            else
              msg += @battlers[idxBattler].name
            end
          end
          msg += "!"
          toSendOut.concat(sent)
        end
        pbDisplayBrief(_INTL("{1}", msg)) if msg.length > 0
        animSendOuts = []
        toSendOut.each do |idxBattler|
          animSendOuts.push([idxBattler, @battlers[idxBattler].pokemon])
        end
        pbSendOut(animSendOuts, true)
      end
    elsif defined?(pbStartBattleSendOut_WithTitles)
      pbStartBattleSendOut_WithTitles(sendOuts)
    else
      dx_pbStartBattleSendOut(sendOuts)
    end
  end
end

#===============================================================================
# Edited to allow the opponent's sprite to slide on screen in various ways.
#===============================================================================
class Battle::Scene::Animation::Intro < Battle::Scene::Animation
  def makeSlideSprite(spriteName, deltaMult, appearTime, origin = nil)
    return if !@sprites[spriteName]
    s = addSprite(@sprites[spriteName], origin)
    style = (pbInSafari?) ? nil : @battle.slideSpriteStyle
    if !style.nil? && deltaMult < 0
      style = style.split("_")
      base = spriteName.include?("base_") || spriteName.include?("shadow_")
      hideBase = style[1] == "hideBase"
      case style[0]
      #-------------------------------------------------------------------------
      when "still"  # Sprite doesn't slide in.
        s.setVisible(0, false) if base && hideBase
        s.setDelta(0, 0, (Graphics.height * deltaMult).floor)
        s.moveDelta(0, 0, 0, (-Graphics.height * deltaMult).floor)
      #-------------------------------------------------------------------------
      when "side"   # Sprite slides in from the side.
        s.setVisible(0, false) if base && hideBase
        s.setDelta(0, (Graphics.width * deltaMult).floor, 0)
        s.moveDelta(0, appearTime, (-Graphics.width * deltaMult).floor, 0)
      #-------------------------------------------------------------------------
      when "top"    # Sprite slides in from top.
        if hideBase
          s.setVisible(0, false) if base
        elsif spriteName.include?("shadow_")
          s.setOpacity(0, 0)
          s.moveOpacity(0, appearTime, 255)
        end
        appearTime = 0 if base
        s.setDelta(0, 0, (Graphics.height * deltaMult).floor)
        s.moveDelta(0, appearTime, 0, (-Graphics.height * deltaMult).floor)
      #-------------------------------------------------------------------------
      when "bottom" # Sprite slides in from bottom.
        if spriteName.include?("base_")
          s.setVisible(0, false) if hideBase
          s.setDelta(0, 0, (Graphics.height * deltaMult).floor)
          s.moveDelta(0, 0, 0, (-Graphics.height * deltaMult).floor)
        elsif spriteName.include?("shadow_")
          s.setVisible(0, false)
          s.setDelta(0, 0, (Graphics.height * deltaMult).floor)
          s.moveDelta(0, 0, 0, (-Graphics.height * deltaMult).floor)
          s.setVisible(appearTime, true) if !hideBase
        else
          bitmap = @sprites[spriteName].bitmap
          f = 0
          w = bitmap.width
          h = bitmap.height
          deltaY = h - findTop(bitmap)
          s.setDelta(0, 0, deltaY)
          s.moveDelta(0, appearTime - 3, 0, (deltaY * deltaMult).floor)
          appearTime.times do |i|
            if i + 1 < appearTime
              s.setSrcSize(i, w, f)
              f += (h / appearTime).floor
            else
              s.setSrcSize(i, w, h)
            end
          end
        end
      end
      #-------------------------------------------------------------------------
    else
      s.setDelta(0, (Graphics.width * deltaMult).floor, 0)
      s.moveDelta(0, appearTime, (-Graphics.width * deltaMult).floor, 0)
    end
  end
end

def findTop(bitmap)
  return 0 if !bitmap
  (1..bitmap.height).each do |i|
    bitmap.width.times do |j|
      return i if bitmap.get_pixel(j, i).alpha > 0
    end
  end
  return 0
end

#===============================================================================
# Methods used for setting wild attributes via Battle Rules.
#===============================================================================
class Pokemon
  def moves=(value)
    return if !value
    value = [value] if !value.is_a?(Array)
    @moves.clear if !value.empty?
    value.each do |move|
      break if @moves.length >= MAX_MOVES
	  case move
	  when Pokemon::Move
	    new_move = move.clone
      else
	    new_move = Pokemon::Move.new(move)
	  end
      next if !@moves.empty? && @moves.any? { |m| m.id == new_move.id }
      @moves.push(new_move)
    end
  end
  
  def ribbons=(value)
    value = [value] if !value.is_a?(Array)
    @ribbons.clear if !value.empty?
    value.each do |ribbon|
      next if @ribbons.include?(ribbon)
      @ribbons.push(ribbon)
    end
  end
  
  def pokerus=(value)
    case value
    when false   then @pokerus = 0
    when true    then @pokerus = 1
    when Integer then @pokerus = value
    end
  end
  
  def iv=(value)
    case value
    when Integer
      @iv.each_key do |stat|
        @iv[stat] = value.clamp(0, IV_STAT_LIMIT)
      end
    when Array
      GameData::Stat.each_main do |stat|
        val = value[stat.pbs_order].clamp(0, IV_STAT_LIMIT)
        @iv[stat.id] = val
      end
    when Hash
      value.each do |stat, val|
        @iv[stat] = val.clamp(0, IV_STAT_LIMIT)
      end
    end
  end
  
  def ev=(value)
    total_ev = 0
    @ev.each_key { |stat| @ev[stat] = 0 }
    case value
    when Integer
      val = value.clamp(0, EV_STAT_LIMIT)
      @ev.each_key do |stat|
        @ev[stat] = val
        total_ev += val
        total_ev = [total_ev, EV_LIMIT].min
        val = [val, EV_LIMIT - total_ev].min
      end
    when Array
      GameData::Stat.each_main do |stat|
        val = value[stat.pbs_order].clamp(0, EV_STAT_LIMIT)
        total_ev += val
        total_ev = [total_ev, EV_LIMIT].min
        val = [val, EV_LIMIT - total_ev].min
        @ev[stat.id] = val
      end
    when Hash
      value.each do |stat, val|
        val = val.clamp(0, EV_STAT_LIMIT)
        total_ev += val
        total_ev = [total_ev, EV_LIMIT].min
        val = [val, EV_LIMIT - total_ev].min
        @ev[stat] = val
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Fixes for cloning Pokemon objects.
  #-----------------------------------------------------------------------------
  def set_moves=(value)
    @moves = value
  end
  
  def set_ribbons=(value)
    @ribbons = value
  end
  
  def set_ivs=(value)
    @iv = value
  end
  
  def set_evs=(value)
    @ev = value
  end
  
  def clone
    ret = super
    ret.set_ivs = {}
    ret.ivMaxed = {}
    ret.set_evs = {}
    GameData::Stat.each_main do |s|
      ret.iv[s.id]      = @iv[s.id]
      ret.ivMaxed[s.id] = @ivMaxed[s.id]
      ret.ev[s.id]      = @ev[s.id]
    end
    ret.set_moves   = []
    @moves.each_with_index { |m, i| ret.moves[i] = m.clone }
    ret.first_moves = @first_moves.clone
    ret.owner       = @owner.clone
    ret.set_ribbons = @ribbons.clone
    return ret
  end
end

#===============================================================================
# Event handlers.
#===============================================================================

#-------------------------------------------------------------------------------
# Used for battle_rules["editWildPokemon"].
#-------------------------------------------------------------------------------
EventHandlers.add(:on_wild_pokemon_created, :edit_wild_pokemon,
  proc { |pkmn|
    battleRules = $game_temp.battle_rules
    ["editWildPokemon", "editWildPokemon2", "editWildPokemon3"].each do |rule|
      next if !battleRules[rule]
      battleRules[rule].each do |property, value|
        next if value.nil?
        if pkmn.respond_to?(property.to_s) || [:shiny, :super_shiny].include?(property)
          pkmn.send("#{property}=", value)
        end
      end
      pkmn.calc_stats
      battleRules.delete(rule)
      break
    end
  }
)

#-------------------------------------------------------------------------------
# Used for battle_rules["tempPlayer"], ["tempBag"], ["tempParty"] and ["inverseBattle"].
#-------------------------------------------------------------------------------
EventHandlers.add(:on_start_battle, :change_player_and_party,
  proc {
    battleRules = $game_temp.battle_rules
    old_player_data = nil
    old_player_bag = nil
    old_player_party = nil
    if battleRules["tempPlayer"]
      old_player_data = [$player.name, $player.outfit]
      rule = battleRules["tempPlayer"]
      case rule
      when String  then $player.name = rule 
      when Integer then $player.outfit = rule
      when Array
        rule.each do |r|
          $player.name   = r if r.is_a?(String)
          $player.outfit = r if r.is_a?(Integer)
        end
      end
    end
    if battleRules["tempBag"]
      old_player_bag = $bag.clone
      bag = battleRules["tempBag"]
      $bag = PokemonBag.new
      if bag.is_a?(Array)
        bag.each_with_index do |item, i| 
          next if !item.is_a?(Symbol)
          qty = bag[i + 1]
          qty = 1 if !qty.is_a?(Integer)
          $bag.add(item, qty)
        end
      else
        $bag = bag
      end
    end
    if battleRules["tempParty"]
      old_player_party = $player.party.clone
      new_party = []
      species = nil
      battleRules["tempParty"].each do |data|
        case data
        when Pokemon
          new_party.push(data)
        when Symbol
          next if !GameData::Species.exists?(data)
          species = data
        when Integer
          next if !species
          new_party.push(Pokemon.new(species, data))
          species = nil
        end
      end
      $player.party = new_party if !new_party.empty?
    end
    $game_temp.old_player_data = old_player_data
    $game_temp.old_player_bag = old_player_bag
    $game_temp.old_player_party = old_player_party
    $game_temp.inverse_battle = battleRules["inverseBattle"]
  }
)

#-------------------------------------------------------------------------------
# Reverts battle_rules["tempPlayer"], ["tempBag"], ["tempParty"] and ["inverseBattle"].
#-------------------------------------------------------------------------------
EventHandlers.add(:on_end_battle, :revert_player_and_party,
  proc { |decision, canLose|
    if $game_temp.old_player_data
      $player.name = $game_temp.old_player_data[0]
      $player.outfit = $game_temp.old_player_data[1]
      $game_temp.old_player_data = nil
    end
    if $game_temp.old_player_bag
      $bag = PokemonBag.new
      $bag = $game_temp.old_player_bag
      $game_temp.old_player_bag = nil
    end
    if $game_temp.old_player_party
      $player.party = $game_temp.old_player_party
      $game_temp.old_player_party = nil
    end
    $game_temp.inverse_battle = nil
  }
)