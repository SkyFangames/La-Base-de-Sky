#===============================================================================
# Menu code for the application of battle rules via the debug menu.
#===============================================================================
class BattleRulesDebug
  def pbDebugMenu
    @commands = pbGetBattleRuleList
    viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    viewport.z = 99999
    sprites = {}
    sprites["textbox"] = pbCreateMessageWindow
    sprites["textbox"].letterbyletter = false
    sprites["cmdwindow"] = Window_CommandPokemonEx.new(@commands.list)
    cmdwindow = sprites["cmdwindow"]
    cmdwindow.x        = 0
    cmdwindow.y        = 0
    cmdwindow.width    = Graphics.width
    cmdwindow.height   = Graphics.height - sprites["textbox"].height
    cmdwindow.viewport = viewport
    cmdwindow.visible  = true
    sprites["textbox"].text = @commands.getDesc(cmdwindow.index)
    refresh = true
    @selecting = false
    loop do
      if refresh
        @commands = pbGetBattleRuleList
        cmdwindow.commands = @commands.list
        cmdwindow.index = 0
        refresh = false
      end
      cmdwindow.update
      sprites["textbox"].text = @commands.getDesc(cmdwindow.index)
      Graphics.update
      Input.update
      if Input.trigger?(Input::BACK)
        if @selecting
          pbPlayCancelSE
          @selecting = false
          refresh = true
        else
          break
        end
      elsif Input.trigger?(Input::USE)
        pbPlayDecisionSE
        cmd = @commands.getCommand(cmdwindow.index)
        if @selecting || [:add_new_rule, :clear_all_rules].include?(cmd)
          refresh = pbSetBattleRule(cmd)
        else
          options = [_INTL("Edit"), _INTL("Remove"), _INTL("Cancel")]
          case pbMessage(_INTL("Do what with this rule?"), options, 3)
          when 0
            pbPlayDecisionSE
            refresh = pbSetBattleRule(cmd)
          when 1
            pbPlayDecisionSE
            refresh = pbRemoveBattleRule(cmdwindow.index)
          when 2
            pbPlayCancelSE
          end
        end
      end
    end
    pbDisposeMessageWindow(sprites["textbox"])
    pbDisposeSpriteHash(sprites)
    viewport.dispose
  end

  def pbGetBattleRuleList
    commands = CommandMenuList.new
    commands.currentList = :set_battle_rules
    battleRules = $game_temp.battle_rules
    MenuHandlers.each_available(:battle_rules_menu) do |option, hash, name|
      rule = hash["rule"]
      value = battleRules[rule].clone
      next if @selecting && (rule.nil? || !value.nil?)
      next if !@selecting && !rule.nil? && value.nil?
      if @selecting
        name = rule
      else
        case rule
        when "tempParty" then value = sprintf("%d PkMn", value.length / 2)
        when "tempBag"   then value = sprintf("%d Items", value.length / 2)
        else
          case value
          when Array  then value = value.join(",")
          when Symbol then value = value.to_s
          when String then value = "None" if nil_or_empty?(value)
          end
          if value.is_a?(String)
            value = value[0..12] + "..." if value.length > 16
          end
        end
        name = _INTL(name, value)
      end
      commands.add_rule(option, hash, name)
    end
    return commands
  end
  
  def pbSetBattleRule(cmd)
    if MenuHandlers.call(:battle_rules_menu, cmd, "effect", self)
      @selecting = (cmd == :add_new_rule) ? true : false
      commands = pbGetBattleRuleList
      if cmd == :add_new_rule
        @selecting = true
        commands = pbGetBattleRuleList
        if commands.list.empty?
          pbMessage(_INTL("There are no remaining battle rules to add."))
          @selecting = false
          return false
        end
      end
      return true
    end
    return false
  end
  
  def pbRemoveBattleRule(index)
    rule = @commands.getRule(index)
    return false if $game_temp.battle_rules[rule].nil?
    $game_temp.battle_rules.delete(rule)
    return true
  end
end

class CommandMenuList
  def add_rule(option, hash, name)
    @commands.push([option, hash["parent"], name || hash["name"], hash["description"], hash["rule"]])
  end
  
  def getRule(index)
    count = 0
    @commands.each do |cmd|
      next if cmd[1] != @currentList
      return cmd[4] if count == index && cmd[4]
      break if count == index
      count += 1
    end
    return "<No rule available>"
  end
end

#===============================================================================
# Generic utility for setting battle rules during gameplay.
#===============================================================================
def pbApplyBattleRule(rule, value_type, set_value, msg = "")
  if nil_or_empty?(rule)
    pbMessage(_INTL("Selected battle rule is invalid."))
    return false
  end
  pbPlayDecisionSE
  value = nil
  battleRule = $game_temp.battle_rules[rule]
  case value_type
  when :Toggle
    if battleRule.nil?
      pbMessage(msg) if !nil_or_empty?(msg)
      value = set_value
    else
      $game_temp.battle_rules.delete(rule)
      pbMessage(_INTL("Battle rule inverted."))
      return true
    end
  when :Boolean
    case pbMessage(msg, [_INTL("True"), _INTL("False")], -1)
    when 0 then value = true
    when 1 then value = false
    end
  when :String, :Symbol
    value = pbMessageFreeText(msg, "", false, 250, Graphics.width)
    case value_type
    when :String
      if set_value && value == set_value
        value = ""
      elsif nil_or_empty?(value)
        value = nil
      end
    when :Symbol
      value = (nil_or_empty?(value)) ? nil : value.to_sym
    end
  when :Integer
    minVal = set_value || 0
    initVal = battleRule || minVal
    params = ChooseNumberParams.new
    params.setRange(minVal, 999)
    params.setInitialValue(initVal)
    params.setCancelValue(initVal)
    value = pbMessageChooseNumber(msg, params)
    if value == initVal || value == minVal
      if !battleRule.nil? && value == minVal
        pbPlayDecisionSE
        $game_temp.battle_rules.delete(rule)
		return true
      end
      value = nil
    end
  when :Data
    return false if !set_value || !set_value.is_a?(Symbol)
    pbMessage(msg) if !nil_or_empty?(msg)
    case set_value
    when :Species
      value = pbChooseSpeciesList
    else
      value = pbChooseFromGameDataList(set_value)
    end
  when :Choose
    return false if !set_value || !set_value.is_a?(Array)
    ids = []
    commands = []
    set_value.each do |data| 
      ids.push(data)
      commands.push(_INTL("{1}", data))
    end
    value = pbMessage(msg, commands, -1)
    value = (value == -1) ? nil : ids[value]
  end
  if !value.nil? && battleRule != value
    pbPlayDecisionSE
    $game_temp.battle_rules[rule] = value
    return true
  end
  return false
end


################################################################################
#
# Debug options.
#
################################################################################

#===============================================================================
# Main debug menu option for the Deluxe Battle Kit and supported plugins.
#===============================================================================
MenuHandlers.add(:debug_menu, :deluxe_plugins_menu, {
  "name"        => _INTL("Deluxe plugin settings..."),
  "parent"      => :main,
  "description" => _INTL("Settings added by the Deluxe Battle Kit and other add-on plugins."),
  "always_show" => false
})

#===============================================================================
# Main menu.
#===============================================================================
MenuHandlers.add(:debug_menu, :set_battle_rules, {
  "name"        => _INTL("Set battle rules..."),
  "parent"      => :deluxe_plugins_menu,
  "description" => _INTL("Set battle rules to apply to the next encounter."),
  "effect"      => proc {
    pbPlayDecisionSE
    scr = BattleRulesDebug.new
    scr.pbDebugMenu
    next false
  }
})

MenuHandlers.add(:debug_menu, :set_partner, {
  "name"        => _INTL("Set partner trainer"),
  "parent"      => :deluxe_plugins_menu,
  "description" => _INTL("Set a partner trainer to accompany the player in battle."),
  "effect"      => proc {
    endProc = false
    if $PokemonGlobal.partner
      trname = $PokemonGlobal.partner[1]
      commands = [_INTL("Remove"), _INTL("Replace"), _INTL("Cancel")]
      case pbMessage(
        "\\ts[]" + _INTL("Do what with the player's existing partner? ({1})", trname), commands, 3)
      when 0
        pbMessage(_INTL("Removed {1} as partner.", trname))
        pbDeregisterPartner
        endProc = true
      when 1
        pbMessage(_INTL("Choose a new partner."))
      when 2
        endProc = true
      end
    end
    if !endProc
      trdata = pbListScreen(_INTL("PARTNER TRAINER"), TrainerBattleLister.new(0, false))
      next false if !trdata
      backSprite = false
      if trdata[2] > 0 && pbResolveBitmap(sprintf("Graphics/Trainers/%s_%s_back", trdata[0], trdata[2]))
        backSprite = true
      end
      if !backSprite && pbResolveBitmap(sprintf("Graphics/Trainers/%s_back", trdata[0]))
        backSprite = true
      end
      if backSprite
        pbRegisterPartner(*trdata)
        pbMessage(_INTL("Registered {1} as partner.", trdata[1]))
      else
        pbMessage(_INTL("Trainer is missing a back sprite.\nUnable to set as partner."))
      end
    end
    next false
  }
})

MenuHandlers.add(:debug_menu, :deluxe_gimmick_toggles, {
  "name"        => _INTL("Toggle battle gimmicks..."),
  "parent"      => :deluxe_plugins_menu,
  "description" => _INTL("Toggles for various battle gimmicks such as Mega Evolution.")
})

MenuHandlers.add(:debug_menu, :deluxe_mega, {
  "name"        => _INTL("Toggle Mega Evolution"),
  "parent"      => :deluxe_gimmick_toggles,
  "description" => _INTL("Toggles the availability of Mega Evolution functionality."),
  "effect"      => proc {
    $game_switches[Settings::NO_MEGA_EVOLUTION] = !$game_switches[Settings::NO_MEGA_EVOLUTION]
    toggle = ($game_switches[Settings::NO_MEGA_EVOLUTION]) ? "disabled" : "enabled"
    pbMessage(_INTL("Mega Evolution {1}.", toggle))
  }
})


################################################################################
#
# Battle Rule debug options. (Main)
#
################################################################################

MenuHandlers.add(:battle_rules_menu, :add_new_rule, {
  "name"        => _INTL("[ADD NEW RULE]"),
  "order"       => 0,
  "parent"      => :set_battle_rules,
  "description" => _INTL("Select a new battle rule to apply."),
  "effect"      => proc { |menu|
    next true
  }
})

MenuHandlers.add(:battle_rules_menu, :clear_all_rules, {
  "name"        => _INTL("[CLEAR ALL RULES]"),
  "order"       => 1,
  "parent"      => :set_battle_rules,
  "description" => _INTL("Clear all active battle rules."),
  "effect"      => proc { |menu|
    if $game_temp.battle_rules.empty?
      pbMessage(_INTL("No battle active battle rules to clear."))
    elsif pbConfirmMessage(_INTL("Are you sure you want to clear all active battle rules?"))
      pbPlayDecisionSE
      $game_temp.battle_rules.clear
      next true
    end
    next false
  }
})

################################################################################
#
# Battle Rule debug options. (Essentials)
#
################################################################################

MenuHandlers.add(:battle_rules_menu, :size, {
  "name"        => "Battle size: [{1}]",
  "rule"        => "size",
  "order"       => 25,
  "parent"      => :set_battle_rules,
  "description" => _INTL("Determines the number of battlers on each side of the field."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("size", :Choose, 
      ["single", "1v1", "1v2", "1v3", "2v1", "3v1", "double", "2v2", "2v3", "3v2", "triple", "3v3"],
      _INTL("Set the battle size."))
  }
})

MenuHandlers.add(:battle_rules_menu, :noPartner, {
  "name"        => "No partner: [{1}]",
  "rule"        => "noPartner",
  "order"       => 50,
  "parent"      => :set_battle_rules,
  "description" => _INTL("The player's partner trainer will not participate in battle."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("noPartner", :Toggle, true)
  }
})

MenuHandlers.add(:battle_rules_menu, :canLose, {
  "name"        => "Can lose: [{1}]",
  "rule"        => "canLose",
  "order"       => 75,
  "parent"      => :set_battle_rules,
  "description" => _INTL("The game will continue even if the player loses the battle."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("canLose", :Toggle, true)
  }
})

MenuHandlers.add(:battle_rules_menu, :canRun, {
  "name"        => "Can run: [{1}]",
  "rule"        => "canRun",
  "order"       => 100,
  "parent"      => :set_battle_rules,
  "description" => _INTL("The player will be unable to select the Run command."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("canRun", :Toggle, false)
  }
})

MenuHandlers.add(:battle_rules_menu, :roamerFlees, {
  "name"        => "Wild Pokémon flee: [{1}]",
  "rule"        => "roamerFlees",
  "order"       => 125,
  "parent"      => :set_battle_rules,
  "description" => _INTL("Wild Pokémon will always attempt to flee as their first action."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("roamerFlees", :Toggle, true)
  }
})

MenuHandlers.add(:battle_rules_menu, :canSwitch, {
  "name"        => "Can switch: [{1}]",
  "rule"        => "canSwitch",
  "order"       => 150,
  "parent"      => :set_battle_rules,
  "description" => _INTL("Trainers will be unable to manually switch out Pokémon."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("canSwitch", :Toggle, false)
  }
})

MenuHandlers.add(:battle_rules_menu, :switchStyle, {
  "name"        => "Switch style: [{1}]",
  "rule"        => "switchStyle",
  "order"       => 175,
  "parent"      => :set_battle_rules,
  "description" => _INTL("Determines whether or not switch mode is enabled."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("switchStyle", :Boolean, nil, 
      _INTL("Set whether switch mode should be enabled. (Trainer battles only)"))
  }
})

MenuHandlers.add(:battle_rules_menu, :expGain, {
  "name"        => "Gain exp.: [{1}]",
  "rule"        => "expGain",
  "order"       => 200,
  "parent"      => :set_battle_rules,
  "description" => _INTL("The player's Pokémon will not gain any experience."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("expGain", :Toggle, false)
  }
})

MenuHandlers.add(:battle_rules_menu, :moneyGain, {
  "name"        => "Gain money: [{1}]",
  "rule"        => "moneyGain",
  "order"       => 225,
  "parent"      => :set_battle_rules,
  "description" => _INTL("The player will not lose or receive any prize money."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("moneyGain", :Toggle, false)
  }
})

MenuHandlers.add(:battle_rules_menu, :defaultWeather, {
  "name"        => "Weather: [{1}]",
  "rule"        => "defaultWeather",
  "order"       => 250,
  "parent"      => :set_battle_rules,
  "description" => _INTL("Determines the default battle weather."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("defaultWeather", :Data, :BattleWeather,
      _INTL("Set the default battle weather."))
  }
})

MenuHandlers.add(:battle_rules_menu, :defaultTerrain, {
  "name"        => "Terrain: [{1}]",
  "rule"        => "defaultTerrain",
  "order"       => 275,
  "parent"      => :set_battle_rules,
  "description" => _INTL("Determines the default battle terrain."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("defaultTerrain", :Data, :BattleTerrain,
      _INTL("Set the default battle terrain."))
  }
})

MenuHandlers.add(:battle_rules_menu, :environment, {
  "name"        => "Environment: [{1}]",
  "rule"        => "environment",
  "order"       => 300,
  "parent"      => :set_battle_rules,
  "description" => _INTL("Determines the battle environment."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("environment", :Data, :Environment,
      _INTL("Set the battle environment."))
  }
})

MenuHandlers.add(:battle_rules_menu, :disablePokeBalls, {
  "name"        => "Poké Balls disabled: [{1}]",
  "rule"        => "disablePokeBalls",
  "order"       => 325,
  "parent"      => :set_battle_rules,
  "description" => _INTL("Poké Balls will be unable to be selected from the bag."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("disablePokeBalls", :Toggle, true)
  }
})

MenuHandlers.add(:battle_rules_menu, :forceCatchIntoParty, {
  "name"        => "Catch goes to party: [{1}]",
  "rule"        => "forceCatchIntoParty",
  "order"       => 350,
  "parent"      => :set_battle_rules,
  "description" => _INTL("Any captured Pokémon must be added to the party."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("forceCatchIntoParty", :Toggle, true)
  }
})

MenuHandlers.add(:battle_rules_menu, :battleAnims, {
  "name"        => "Show battle anims: [{1}]",
  "rule"        => "battleAnims",
  "order"       => 375,
  "parent"      => :set_battle_rules,
  "description" => _INTL("Determines whether or not battle animations are enabled."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("battleAnims", :Boolean, nil, 
      _INTL("Set whether battle animations should be enabled."))
  }
})

MenuHandlers.add(:battle_rules_menu, :backdrop, {
  "name"        => "Backdrop: [{1}]",
  "rule"        => "backdrop",
  "order"       => 400,
  "parent"      => :set_battle_rules,
  "description" => _INTL("Determines the graphic used for the battle background."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("backdrop", :String, nil, 
      _INTL("Set the name of the background graphic."))
  }
})

MenuHandlers.add(:battle_rules_menu, :base, {
  "name"        => "Bases: [{1}]",
  "rule"        => "base",
  "order"       => 425,
  "parent"      => :set_battle_rules,
  "description" => _INTL("Determines the graphics used for the battle bases."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("base", :String, nil, 
      _INTL("Set the name of the battle base graphics."))
  }
})

MenuHandlers.add(:battle_rules_menu, :outcomeVar, {
  "name"        => "Outcome variable: [{1}]",
  "rule"        => "outcomeVar",
  "order"       => 450,
  "parent"      => :set_battle_rules,
  "description" => _INTL("The variable number used to store the battle outcome."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("outcomeVar", :Integer, 1, 
      _INTL("Set a variable number."))
  }
})

################################################################################
#
# Battle Rule debug options (DBK).
#
################################################################################

MenuHandlers.add(:battle_rules_menu, :tempPlayer, {
  "name"        => "Temp player: [{1}]",
  "rule"        => "tempPlayer",
  "order"       => 301,
  "parent"      => :set_battle_rules,
  "description" => _INTL("Determines temporary player attributes."),
  "effect"      => proc { |menu|
    name = pbMessageFreeText(
      _INTL("Enter the player's temporary display name."), $player.name, false, 250, Graphics.width)
    if !nil_or_empty?(name)
      params = ChooseNumberParams.new
      params.setRange(0, 999)
      params.setInitialValue($player.outfit)
      params.setCancelValue(0)
      outfit = pbMessageChooseNumber(_INTL("Set the player's temporary outfit number."), params)
      next false if $player.name == name && $player.outfit == outfit
      next false if $game_temp.battle_rules["tempPlayer"] == [name, outfit]
      $game_temp.battle_rules["tempPlayer"] = [name, outfit]
      next true
    end
    next false
  }
})

MenuHandlers.add(:battle_rules_menu, :tempParty, {
  "name"        => "Temp party: [{1}]",
  "rule"        => "tempParty",
  "order"       => 302,
  "parent"      => :set_battle_rules,
  "description" => _INTL("Determines the player's temporary party."),
  "effect"      => proc { |menu|
    party = []
    Settings::MAX_PARTY_SIZE.times do |i|
      pbMessage(_INTL("Add a temporary party member (slot {1}).\n(Exit menu to end early)", i + 1))
      species = pbChooseSpeciesList
      break if !species
      name = GameData::Species.get(species).name
      params = ChooseNumberParams.new
      params.setRange(1, Settings::MAXIMUM_LEVEL)
      params.setInitialValue(1)
      params.setCancelValue(1)
      level = pbMessageChooseNumber(_INTL("Set a level for {1}.", name), params)
      party.push(species, level)
    end
    if !party.empty? && $game_temp.battle_rules["tempParty"] != party
      pbMessage(_INTL("Set a temporary party of {1}.", party.length / 2))
      $game_temp.battle_rules["tempParty"] = party
      next true
    end
    next false
  }
})

MenuHandlers.add(:battle_rules_menu, :tempBag, {
  "name"        => "Temp bag: [{1}]",
  "rule"        => "tempBag",
  "order"       => 303,
  "parent"      => :set_battle_rules,
  "description" => _INTL("Determines the player's temporary inventory."),
  "effect"      => proc { |menu|
    bag = []
    loop do
      pbMessage(_INTL("Add a new item to the temporary bag.\n(Exit menu to end)"))
      item = pbChooseFromGameDataList(:Item) do |data|
        next (bag.include?(data.id)) ? nil : data.real_name
      end
      break if !item
      data = GameData::Item.get(item)
      maxRange = (data.is_important?) ? 1 : 999
      params = ChooseNumberParams.new
      params.setRange(1, maxRange)
      params.setInitialValue(1)
      params.setCancelValue(1)
      qty = pbMessageChooseNumber(_INTL("Set the number of {1} to add.", data.name_plural), params)
      bag.push(item, qty)
    end
    if !bag.empty? && $game_temp.battle_rules["tempBag"] != bag
      pbMessage(_INTL("Set a temporary inventory of {1} items.", bag.length / 2))
      $game_temp.battle_rules["tempBag"] = bag
      next true
    end
    next false
  }
})

MenuHandlers.add(:battle_rules_menu, :noBag, {
  "name"        => "No items: [{1}]",
  "rule"        => "noBag",
  "order"       => 304,
  "parent"      => :set_battle_rules,
  "description" => _INTL("Trainers are unable to use any items from their inventories."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("noBag", :Toggle, true)
  }
})

MenuHandlers.add(:battle_rules_menu, :noMegaEvolution, {
  "name"        => "No Mega Evolution: [{1}]",
  "rule"        => "noMegaEvolution",
  "order"       => 305,
  "parent"      => :set_battle_rules,
  "description" => _INTL("Determines which side Mega Evolution is disabled for."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("noMegaEvolution", :Choose, [:All, :Player, :Opponent], 
      _INTL("Choose a side to disable Mega Evolution for."))
  }
})

MenuHandlers.add(:battle_rules_menu, :autoBattle, {
  "name"        => "Auto battle: [{1}]",
  "rule"        => "autoBattle",
  "order"       => 310,
  "parent"      => :set_battle_rules,
  "description" => _INTL("The AI will control the player's commands."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("autoBattle", :Toggle, true)
  }
})

MenuHandlers.add(:battle_rules_menu, :internalBattle, {
  "name"        => "PvE battle: [{1}]",
  "rule"        => "internalBattle",
  "order"       => 311,
  "parent"      => :set_battle_rules,
  "description" => _INTL("The battle functions like a Battle Tower or PvP battle."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("internalBattle", :Toggle, false)
  }
})

MenuHandlers.add(:battle_rules_menu, :inverseBattle, {
  "name"        => "Inverse battle: [{1}]",
  "rule"        => "inverseBattle",
  "order"       => 312,
  "parent"      => :set_battle_rules,
  "description" => _INTL("Type effectiveness will be inverted."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("inverseBattle", :Toggle, true)
  }
})

MenuHandlers.add(:battle_rules_menu, :wildBattleMode, {
  "name"        => "Wild gimmick: [{1}]",
  "rule"        => "wildBattleMode",
  "order"       => 320,
  "parent"      => :set_battle_rules,
  "description" => _INTL("Determines a battle gimmick to be used by wild Pokémon."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("wildBattleMode", :Choose, [:mega, :zmove, :ultra, :dynamax, :tera], 
      _INTL("Choose a battle gimmick for wild Pokémon to use."))
  }
})

MenuHandlers.add(:battle_rules_menu, :captureSuccess, {
  "name"        => "Capture success: [{1}]",
  "rule"        => "captureSuccess",
  "order"       => 351,
  "parent"      => :set_battle_rules,
  "description" => _INTL("Determines whether Poké Balls always succeeed or fail."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("captureSuccess", :Boolean, nil, 
      _INTL("Set whether Poké Balls will always succeed or fail."))
  }
})

MenuHandlers.add(:battle_rules_menu, :captureTutorial, {
  "name"        => "Tutorial capture: [{1}]",
  "rule"        => "captureTutorial",
  "order"       => 352,
  "parent"      => :set_battle_rules,
  "description" => _INTL("Captured Pokémon will not be kept or registered in the Pokédex."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("captureTutorial", :Toggle, true)
  }
})

MenuHandlers.add(:battle_rules_menu, :raidStyleCapture, {
  "name"        => "Raid-style capture: [{1}]",
  "rule"        => "raidStyleCapture",
  "order"       => 353,
  "parent"      => :set_battle_rules,
  "description" => _INTL("You're prompted to capture a wild Pokémon when its HP drops to zero."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("raidStyleCapture", :Toggle, true)
  }
})

MenuHandlers.add(:battle_rules_menu, :captureME, {
  "name"        => "Capture ME: [{1}]",
  "rule"        => "captureME",
  "order"       => 354,
  "parent"      => :set_battle_rules,
  "description" => _INTL("Determines the music effect upon capturing a Pokémon."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("captureME", :String, nil, 
      _INTL("Set the music effect that plays upon capturing a Pokémon."))
  }
})

MenuHandlers.add(:battle_rules_menu, :battleBGM, {
  "name"        => "Battle BGM: [{1}]",
  "rule"        => "battleBGM",
  "order"       => 355,
  "parent"      => :set_battle_rules,
  "description" => _INTL("Determines the battle background music."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("battleBGM", :String, "None", 
      _INTL("Set the battle background music. (Set to None to disable)"))
  }
})

MenuHandlers.add(:battle_rules_menu, :victoryBGM, {
  "name"        => "Victory BGM: [{1}]",
  "rule"        => "victoryBGM",
  "order"       => 356,
  "parent"      => :set_battle_rules,
  "description" => _INTL("Determines the battle victory music."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("victoryBGM", :String, "None", 
      _INTL("Set the battle victory music. (Set to None to disable)"))
  }
})

MenuHandlers.add(:battle_rules_menu, :lowHealthBGM, {
  "name"        => "Low HP BGM: [{1}]",
  "rule"        => "lowHealthBGM",
  "order"       => 357,
  "parent"      => :set_battle_rules,
  "description" => _INTL("Determines the low HP background music."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("lowHealthBGM", :String, "None", 
      _INTL("Set the low HP background music. (Set to None to disable)"))
  }
})

MenuHandlers.add(:battle_rules_menu, :battleIntroText, {
  "name"        => "Intro text: [{1}]",
  "rule"        => "battleIntroText",
  "order"       => 358,
  "parent"      => :set_battle_rules,
  "description" => _INTL("Determines the text displayed at the start of an encounter."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("battleIntroText", :String, nil, 
      _INTL("Set the displayed encounter text."))
  }
})

MenuHandlers.add(:battle_rules_menu, :opposingWinText, {
  "name"        => "Foe win speech: [{1}]",
  "rule"        => "opposingWinText",
  "order"       => 359,
  "parent"      => :set_battle_rules,
  "description" => _INTL("Determines the opposing trainer's win speech."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("opposingWinText", :String, nil, 
      _INTL("Set the opposing trainer's win speech. (PvP-style battles only)"))
  }
})

MenuHandlers.add(:battle_rules_menu, :opposingLoseText, {
  "name"        => "Foe lose speech: [{1}]",
  "rule"        => "opposingLoseText",
  "order"       => 360,
  "parent"      => :set_battle_rules,
  "description" => _INTL("Determines the opposing trainer's lose speech."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("opposingLoseText", :String, nil, 
      _INTL("Set the opposing trainer's lose speech."))
  }
})

MenuHandlers.add(:battle_rules_menu, :slideSpriteStyle, {
  "name"        => "Foe entrance: [{1}]",
  "rule"        => "slideSpriteStyle",
  "order"       => 426,
  "parent"      => :set_battle_rules,
  "description" => _INTL("Determines the way opponents slide on screen when encountered."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("slideSpriteStyle", :Choose,
      ["side", "side_hideBase", "top", "top_hideBase", "bottom", "bottom_hideBase", "still", "still_hideBase"], 
      _INTL("Set the way opponents slide on screen."))
  }
})

MenuHandlers.add(:battle_rules_menu, :databoxStyle, {
  "name"        => "Databox style: [{1}]",
  "rule"        => "databoxStyle",
  "order"       => 427,
  "parent"      => :set_battle_rules,
  "description" => _INTL("Determines the style of the displayed databoxes."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("databoxStyle", :Data, :DataboxStyle,
      _INTL("Set the databox style to display."))
  }
})

MenuHandlers.add(:battle_rules_menu, :midbattleScript, {
  "name"        => "Midbattle script: [{1}]",
  "rule"        => "midbattleScript",
  "order"       => 451,
  "parent"      => :set_battle_rules,
  "description" => _INTL("Determines which mid-battle script to run."),
  "effect"      => proc { |menu|
    commands = []
    scripts = MidbattleHandlers.script_keys
    MidbattleScripts.constants.each { |script| scripts.push(script.to_sym) }
    if scripts.empty?
      pbMessage(_INTL("No valid midbattle scripts found."))
      next false
    end
    scripts.each { |script| commands.push(_INTL("{1}", script)) }
    cmd = pbMessage(_INTL("Set a mid-battle script to run."), commands, -1)
    script = scripts[cmd]
    if cmd >= 0 && $game_temp.battle_rules["midbattleScript"] != script
      $game_temp.battle_rules["midbattleScript"] = script
      pbPlayDecisionSE
      next true
    end
    next false
  }
})