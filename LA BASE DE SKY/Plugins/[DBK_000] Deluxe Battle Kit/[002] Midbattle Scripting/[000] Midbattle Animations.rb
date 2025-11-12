#===============================================================================
# Midbattle animations & utilities.
#===============================================================================
class Battle::Scene
  #-----------------------------------------------------------------------------
  # Initializes properties for midbattle speech.
  #-----------------------------------------------------------------------------
  alias dx_pbInitSprites pbInitSprites
  def pbInitSprites
    dx_pbInitSprites
    nameWindow = Window_AdvancedTextPokemon.new
    nameWindow.baseColor      = MESSAGE_BASE_COLOR
    nameWindow.shadowColor    = MESSAGE_SHADOW_COLOR
    nameWindow.viewport       = @viewport
    nameWindow.letterbyletter = false
    nameWindow.visible        = false
    nameWindow.x              = 16
    nameWindow.y              = Graphics.height - 158
    nameWindow.z              = 200
    @sprites["nameWindow"]    = nameWindow
    @speaker                  = $player
    @showSpeaker              = false
    @showWindows              = false
    defaultFile = GameData::TrainerType.front_sprite_filename($player.trainer_type)
    spriteX, spriteY = Battle::Scene.pbTrainerPosition(1)
    sprite = pbAddSprite("midbattle_speaker", spriteX, spriteY, defaultFile, @viewport)
    return if !sprite.bitmap
    sprite.z = 7
    sprite.ox = sprite.src_rect.width / 2
    sprite.oy = sprite.bitmap.height
    sprite.visible = false
  end
  
  #-----------------------------------------------------------------------------
  # Updates the current speaker during midbattle speech.
  #-----------------------------------------------------------------------------
  def pbUpdateSpeaker(*args)
    id = args[0]
    speaker = nil
    @showSpeaker = true
    case id
    when Battle::Battler
      speaker = id.pokemon
      id = id.species
      @showSpeaker = false
    when Integer
      battler = @battle.battlers[id]
      trainer = (battler.opposes?) ? @battle.opponent : @battle.player
      if trainer.nil?
        speaker = battler.pokemon
        id = battler.species
        @showSpeaker = false
      else
        idxTrainer = @battle.pbGetOwnerIndexFromBattlerIndex(id)
        speaker = trainer[idxTrainer]
        id = speaker.trainer_type
        @showSpeaker = false if !battler.opposes?
      end
    end
    spriteX, spriteY = Battle::Scene.pbTrainerPosition(1)
    if GameData::Species.exists?(id)
      if !speaker
        speaker = Pokemon.new(id, 1)
        if !speaker.singleGendered?
          speaker.gender = args[1] || 0
        end
        speaker.form = args[2] || 0
        speaker.shiny = args[3] || false
        speaker.makeShadow if args[4]
      end
      sprite = PokemonSprite.new(@viewport)
      sprite.setPokemonBitmap(speaker)
      sprite.setOffset(PictureOrigin::BOTTOM)
      sprite.x = spriteX
      sprite.y = spriteY - 6
      sprite.ox = sprite.src_rect.width / 2
      sprite.oy = sprite.bitmap.height
      speaker.species_data.apply_metrics_to_sprite(sprite, 1)
    elsif GameData::TrainerType.exists?(id)
      speaker = GameData::TrainerType.get(id) if !speaker
      sprite = IconSprite.new(spriteX, spriteY, @viewport)
      sprite.setBitmap("Graphics/Trainers/#{id}")
      sprite.to_last_frame if defined?(sprite.to_last_frame)
      sprite.ox = sprite.src_rect.width / 2
      sprite.oy = sprite.bitmap.height
    end
    sprite.z = 7
    sprite.visible = false
    @sprites["midbattle_speaker"] = sprite
    @speaker = speaker
  end
  
  #-----------------------------------------------------------------------------
  # Updates the name plate and text boxes for the current speaker.
  #-----------------------------------------------------------------------------
  def pbUpdateSpeakerWindows(speaker = "", windowskin = "")
    if !speaker.is_a?(String)
      speaker = @speaker if speaker.nil?
      windowskin = speaker.gender if nil_or_empty?(windowskin)
      speaker = speaker.name
    end
    if windowskin.is_a?(Integer)
      case windowskin
      when 0 then windowskin = Settings::MENU_WINDOWSKINS[4]
      when 1 then windowskin = Settings::MENU_WINDOWSKINS[2]
      else        windowskin = Settings::MENU_WINDOWSKINS[0]
      end
    end
    @sprites["nameWindow"].text = speaker
    @sprites["nameWindow"].setSkin("Graphics/Windowskins/#{windowskin}")
    @sprites["nameWindow"].resizeToFit(speaker)
    @sprites["messageWindow"].setSkin("Graphics/Windowskins/#{windowskin}")
    colors = getDefaultTextColors(@sprites["messageWindow"].windowskin)
    @sprites["messageWindow"].baseColor = colors[0]
    @sprites["messageWindow"].shadowColor = colors[1]
    if @showWindows
      @sprites["nameWindow"].visible = true
      @sprites["messageWindow"].opacity = 255
    else
      @sprites["nameWindow"].visible = false
      @sprites["messageWindow"].opacity = 0
    end
  end
  
  #-----------------------------------------------------------------------------
  # Updates and shows the speaker's message boxes.
  #-----------------------------------------------------------------------------
  def pbShowSpeakerWindows(speaker = "", windowskin = "")
    @showWindows = true
    pbUpdateSpeakerWindows(speaker, windowskin)
  end
  
  #-----------------------------------------------------------------------------
  # Updates and hides the speaker's message boxes.
  #-----------------------------------------------------------------------------
  def pbHideSpeakerWindows(inSpeech = false)
    @showWindows = false
    pbUpdateSpeakerWindows
    @sprites["messageWindow"].text = ""
    if inSpeech
      @sprites["messageWindow"].baseColor = MessageConfig::LIGHT_TEXT_MAIN_COLOR
      @sprites["messageWindow"].shadowColor = MessageConfig::LIGHT_TEXT_SHADOW_COLOR
    else
      @sprites["messageWindow"].baseColor = MESSAGE_BASE_COLOR
      @sprites["messageWindow"].shadowColor = MESSAGE_SHADOW_COLOR
    end
  end
  
  #-----------------------------------------------------------------------------
  # Used for obtaining the appropriate speaker for speech text.
  #-----------------------------------------------------------------------------
  def pbGetSpeaker(idxBattler = nil)
    return @speaker if idxBattler.nil? || idxBattler.is_a?(Symbol)
    return idxBattler if idxBattler.respond_to?("name")
    if idxBattler.is_a?(Integer)
      battler = @battle.battlers[idxBattler]
      idxTrainer = @battle.pbGetOwnerIndexFromBattlerIndex(idxBattler)
      return @battle.player[0] if !battler
      if battler.opposes?
        return (@battle.opponent.nil?) ? battler : @battle.opponent[idxTrainer]
      else
        return (@battle.player.nil?) ? battler : @battle.player[idxTrainer]
      end
    else
      return @battle.player[0]
    end
  end
  
  #-----------------------------------------------------------------------------
  # Used for converting a symbol or integer into an eligible battler index.
  # Symbols => [:Player, :Ally, :Ally2, :Opposing, :OpposingAlly, :OpposingAlly2]
  #-----------------------------------------------------------------------------
  def pbConvertBattlerIndex(idxBattler, idxTarget, newid)
    if newid.is_a?(Integer) || newid.is_a?(Symbol) && [:Self, :Ally, :Ally2, :Opposing, :OpposingAlly, :OpposingAlly2].include?(newid)
      battler_params = [:midbattle_triggers, "setBattler", @battle, idxBattler, idxTarget, newid]
      battler = MidbattleHandlers.trigger(*battler_params)
      return battler.index
    end
    return newid
  end
  
  #-----------------------------------------------------------------------------
  # Returns true if cinematic speech is currently in progress.
  #-----------------------------------------------------------------------------
  def pbInCinematicSpeech?
    return @sprites["bottomBar"] && @sprites["bottomBar"].opacity > 0
  end
  
  #-----------------------------------------------------------------------------
  # Begins cinematic speech if necessary and returns a speaker.
  #-----------------------------------------------------------------------------
  def pbStartSpeech(idxBattler)
    return pbGetSpeaker if pbInCinematicSpeech?
    speaker = pbGetSpeaker(idxBattler)
    pbToggleDataboxes
    pbToggleBlackBars(true)
    pbShowSpeaker(idxBattler)
    pbShowSpeakerWindows(speaker)
    return speaker
  end
  
  #-----------------------------------------------------------------------------
  # Forces cinematic speech to end.
  #-----------------------------------------------------------------------------
  def pbForceEndSpeech
    return if !pbInCinematicSpeech?
    pbHideSpeaker(@battle.decision > 0)
    pbToggleBlackBars
    pbToggleDataboxes(true)
  end
  
  #-----------------------------------------------------------------------------
  # Handles the display of all midbattle text and speech.
  #-----------------------------------------------------------------------------
  def pbProcessText(idxBattler, idxTarget, isSpeech, params)
    msg, choices, responses = "", [], []
    swapSpeaker = false
    speaker = pbGetSpeaker(idxBattler)
    battler = @battle.battlers[idxBattler]
    battlerName = battler.name if isSpeech
    params.each_with_index do |param, t|
      case param
      when :Choices
        @battle.midbattleChoices.each do |ch|
          case ch
          when String
            choices.push(ch)
          when Hash
            choices = ch.keys
            responses = ch.values
            break
          end
        end
      when Integer, Symbol
        msg = ""
        index = pbConvertBattlerIndex(idxBattler, idxTarget, param)
        battler = @battle.battlers[index]
        battlerName = battler.name if isSpeech
        speaker = pbGetSpeaker(battler.index)
        swapSpeaker = true
        next
      when String
        if !isSpeech
          lowercase = (param[0] == "{" && param[1] == "1") ? false : true
          battlerName = battler.pbThis(lowercase)
        else
          if !pbInCinematicSpeech?
            pbStartSpeech(battler.index)
          elsif swapSpeaker
            pbHideSpeaker
            pbShowSpeaker(battler.index, idxTarget)
            pbShowSpeakerWindows(nil)
          end
        end
        msg = _INTL("#{param}", battlerName, speaker.name)
        msg.gsub!(/\\PN/i, @battle.pbPlayer.name)
      end
      next if params[t + 1] == :Choices
      next if nil_or_empty?(msg)
      if choices.empty?
        pbDisplayPausedMessage(msg)
      else
        cmd = pbShowCommands(msg, choices, -1)
        @battle.midbattleDecision = cmd + 1
        dec = @battle.midbattleDecision
        case @battle.midbattleChoices[1]
        when nil then decision = ""
        when dec then decision = "Mining found all"
        else          decision = "Anim/buzzer"
        end
        if responses[cmd]
          param = responses[cmd]
          if !isSpeech
              lowercase = (param[0] == "{" && param[1] == "1") ? false : true
            battlerName = battler.pbThis(lowercase)
          end
          msg = _INTL("#{param}", battlerName, speaker.name)
          msg.gsub!(/\\PN/i, @battle.pbPlayer.name)
          pbDisplayPausedMessage(msg) { pbSEPlay(decision) }
          responses.clear
        else
          pbSEPlay(decision)
        end
        choices.clear
      end
      swapSpeaker = false
      speaker = pbGetSpeaker(idxBattler)
      battler = @battle.battlers[idxBattler]
      battlerName = battler.name if isSpeech
    end
  end
  
  #-----------------------------------------------------------------------------
  # Calls the animations for sliding an opposing speaker on and off screen.
  #-----------------------------------------------------------------------------
  def pbShowSpeaker(idxBattler, idxTarget = nil, params = nil)
    params = pbConvertBattlerIndex(idxBattler, idxTarget, params)
    params = idxBattler if !params
    pbUpdateSpeaker(*params)
    return if !@showSpeaker
    appearAnim = Animation::SlideSpriteAppear.new(@sprites, @viewport, @battle)
    @animations.push(appearAnim)
    while inPartyAnimation?
      pbUpdate
    end
  end

  def pbHideSpeaker(endBattle = false)
    pbHideSpeakerWindows
    hideAnim = Animation::SlideSpriteDisappear.new(@sprites, @viewport, @battle, endBattle)
    @animations.push(hideAnim)
    while inPartyAnimation?
      pbUpdate
    end
  end
  
  #-----------------------------------------------------------------------------
  # Calls an animation for updating a speaker's sprite with a new one.
  #-----------------------------------------------------------------------------
  def pbUpdateSpeakerSprite(*args)
    oldSprite = @sprites["midbattle_speaker"]
    return if !oldSprite.visible
    id = args[0]
    if GameData::TrainerType.exists?(id)
      filename = "Graphics/Trainers/#{id}"
    elsif GameData::Species.exists?(id)
      filename = GameData::Species.front_sprite_filename(*args)
    end
    return if !pbResolveBitmap(filename)
    oldSpeaker = @speaker
    pbUpdateSpeaker(*args)
    @speaker = oldSpeaker
    @sprites["midbattle_speaker"].visible = true
    @sprites["midbattle_speaker"].x += @sprites["midbattle_speaker"].width / 2
    updateAnim = Animation::SlideSpriteUpdate.new(@sprites, @viewport, oldSprite, filename)
    @animations.push(updateAnim)
    while inPartyAnimation?
      pbUpdate
    end
  end
  
  #-----------------------------------------------------------------------------
  # Calls an animation for toggling databox visibility for midbattle speech.
  #-----------------------------------------------------------------------------
  def pbToggleDataboxes(toggle = false)
    pbToggleUIPrompt(toggle) if defined?(pbToggleUIPrompt)
    dataBoxAnim = Animation::ToggleDataBoxes.new(@sprites, @viewport, @battle.battlers, toggle)
    loop do
      dataBoxAnim.update
      pbUpdate
      break if dataBoxAnim.animDone?
    end
    dataBoxAnim.dispose
  end
  
  #-----------------------------------------------------------------------------
  # Calls an animation for toggling black bars for midbattle speech.
  #-----------------------------------------------------------------------------
  def pbToggleBlackBars(toggle = false)
    path = Settings::DELUXE_GRAPHICS_PATH
    pbAddSprite("topBar", Graphics.width, 0, path + "blackbar_top", @viewport) if !@sprites["topBar"]
    pbAddSprite("bottomBar", 0, Graphics.height, path + "blackbar_bottom", @viewport) if !@sprites["bottomBar"]
    blackBarAnim = Animation::ToggleBlackBars.new(@sprites, @viewport, toggle)
    loop do
      blackBarAnim.update
      pbUpdate
      break if blackBarAnim.animDone?
    end
    blackBarAnim.dispose
    @sprites["messageWindow"].text = ""
    if toggle
      @sprites["messageWindow"].z += 1
    else
      @sprites["messageWindow"].z -= 1
    end
  end
end

#-------------------------------------------------------------------------------
# Animation used to slide a speaker on screen.
#-------------------------------------------------------------------------------
class Battle::Scene::Animation::SlideSpriteAppear < Battle::Scene::Animation
  def initialize(sprites, viewport, battle)
    @battle = battle
    super(sprites, viewport)
  end

  def createProcesses
    delay = 0
    if !@sprites["midbattle_speaker"].visible
      darkenBattlefield(@battle, delay)
      @battle.allOtherSideBattlers.each do |b|
        battler = addSprite(@sprites["pokemon_#{b.index}"], PictureOrigin::BOTTOM)
        shadow = addSprite(@sprites["shadow_#{b.index}"], PictureOrigin::CENTER)
        #battler.moveOpacity(delay, 6, 100) ## Comentado para que no se ponga translúcido el sprite del Pokémon.
        #shadow.moveOpacity(delay, 6, 100)
      end
      if @battle.opponent
        @battle.opponent.length.times do |i|
          sprite = @sprites["trainer_#{i + 1}"]
          next if !sprite.visible
          @sprites["midbattle_speaker"].name = sprite.name
          @sprites["midbattle_speaker"].x    = sprite.x
          @sprites["midbattle_speaker"].y    = sprite.y
          @sprites["midbattle_speaker"].z    = sprite.z
          @sprites["midbattle_speaker"].ox   = sprite.ox
          @sprites["midbattle_speaker"].oy   = sprite.oy
          @sprites["midbattle_speaker"].visible = true
          if defined?(@sprites["midbattle_speaker"].to_last_frame)
            @sprites["midbattle_speaker"].to_last_frame
          end
          oldTrainer = addSprite(sprite, PictureOrigin::BOTTOM)
          oldTrainer.setVisible(delay, false)
          break
        end
      end
      slideSprite = addSprite(@sprites["midbattle_speaker"], PictureOrigin::BOTTOM)
      return if @sprites["midbattle_speaker"].visible
      slideSprite.setVisible(delay, true)
      trainerX, trainerY = Battle::Scene.pbTrainerPosition(1)
      trainerX += 64 + (Graphics.width / 4)
      slideSprite.setXY(delay, trainerX, trainerY)
      slideSprite.setZ(delay, @sprites["pokemon_1"].z - 1)
      slideSprite.moveDelta(delay, 8, -Graphics.width / 4, 0)
    end
  end
end

#-------------------------------------------------------------------------------
# Animation used to slide a speaker off screen.
#-------------------------------------------------------------------------------
class Battle::Scene::Animation::SlideSpriteDisappear < Battle::Scene::Animation
  def initialize(sprites, viewport, battle, endBattle)
    @battle = battle
    @endBattle = endBattle
    super(sprites, viewport)
  end

  def createProcesses
    delay = 0
    if @sprites["midbattle_speaker"].visible
      revertBattlefield(@battle, delay)
      slideSprite = addSprite(@sprites["midbattle_speaker"], PictureOrigin::BOTTOM)
      return if @endBattle
      slideSprite.moveDelta(delay, 8, Graphics.width / 4, 0)
      slideSprite.setVisible(delay + 8, false)
      slideSprite.setZ(delay + 8, @sprites["pokemon_1"].z - 1)
    end
  end
end

#-------------------------------------------------------------------------------
# Animation used to update a speaker's sprite.
#-------------------------------------------------------------------------------
class Battle::Scene::Animation::SlideSpriteUpdate < Battle::Scene::Animation
  def initialize(sprites, viewport, oldSprite, filename)
    @filename = filename
    @oldSprite = oldSprite
    super(sprites, viewport)
  end

  def createProcesses
    delay = 0
    sprite = @sprites["midbattle_speaker"]
    picture = addSprite(@oldSprite, PictureOrigin::BOTTOM)
    picture.setXY(delay, sprite.x, sprite.y)
    picture.setZ(delay, sprite.z)
    picture.setZoomXY(delay, sprite.zoom_x, sprite.zoom_y)
    picture.setName(delay, @filename)
  end
end

#-------------------------------------------------------------------------------
# Animation used to toggle visibility of data boxes.
#-------------------------------------------------------------------------------
class Battle::Scene::Animation::ToggleDataBoxes < Battle::Scene::Animation
  def initialize(sprites, viewport, battlers, toggle)
    @battlers = battlers
    @toggle = toggle
    super(sprites, viewport)
  end

  def createProcesses
    delay = 0
    opacity = (@toggle) ? 255 : 0
    2.times do |side|
      bar = addSprite(@sprites["abilityBar_#{side}"])
      party = addSprite(@sprites["partyBar_#{side}"])
      if @sprites["abilityBar_#{side}"].visible
        bar.moveOpacity(delay, 3, opacity)
      end
      if @sprites["partyBar_#{side}"].visible
        Battle::Scene::NUM_BALLS.times do |i|
          next if !@sprites["partyBall_#{side}_#{i}"].visible
          ball = addSprite(@sprites["partyBall_#{side}_#{i}"])
          ball.moveOpacity(delay, 3, opacity)
        end
        party.moveOpacity(delay, 3, opacity)
      end
    end
    @battlers.each do |b|
      next if !b || b.fainted? && !@sprites["pokemon_#{b.index}"].visible
      if @sprites["dataBox_#{b.index}"].visible
        box = addSprite(@sprites["dataBox_#{b.index}"])
        box.moveOpacity(delay, 3, opacity)
      end
    end
  end
end

#-------------------------------------------------------------------------------
# Animation used to toggle black bars during trainer speech.
#-------------------------------------------------------------------------------
class Battle::Scene::Animation::ToggleBlackBars < Battle::Scene::Animation
  def initialize(sprites, viewport, toggle)
    @toggle = toggle
    super(sprites, viewport)
  end

  def createProcesses
    delay = 5
    topBar = addSprite(@sprites["topBar"], PictureOrigin::TOP_LEFT)
    topBar.setZ(0, 200)
    bottomBar = addSprite(@sprites["bottomBar"], PictureOrigin::BOTTOM_RIGHT)
    bottomBar.setZ(0, 200)
    if @toggle
      toMoveBottom = [@sprites["bottomBar"].bitmap.width, Graphics.width].max
      toMoveTop = [@sprites["topBar"].bitmap.width, Graphics.width].max
      topBar.setOpacity(0, 255)
      bottomBar.setOpacity(0, 255)
      topBar.setXY(0, Graphics.width, 0)
      bottomBar.setXY(0, 0, Graphics.height)
      topBar.moveXY(delay, 5, (Graphics.width - toMoveTop), 0)
      bottomBar.moveXY(delay, 5, toMoveBottom, Graphics.height)
    else
      topBar.moveOpacity(delay, 4, 0)
      bottomBar.moveOpacity(delay, 4, 0)
      topBar.setXY(delay + 5, Graphics.width, 0)
      bottomBar.setXY(delay + 5, 0, Graphics.height)
    end
  end
end