#===============================================================================
# Animation utilities.
#===============================================================================
class Battle::Scene
  #-----------------------------------------------------------------------------
  # Checks if a common animation exists.
  #-----------------------------------------------------------------------------
  def pbCommonAnimationExists?(animName)
    animations = pbLoadBattleAnimations
    animations.each do |a|
      next if !a || a.name != "Common:" + animName
      return true
    end
    return false
  end
  
  #-----------------------------------------------------------------------------
  # Rewritten to toggle databoxes during move animations.
  #-----------------------------------------------------------------------------
  def pbAnimation(moveID, user, targets, hitNum = 0)
    animID = pbFindMoveAnimation(moveID, user.index, hitNum)
    return if !animID
    anim = animID[0]
    target = (targets.is_a?(Array)) ? targets[0] : targets
    animations = pbLoadBattleAnimations
    return if !animations
    pbToggleDataboxes if Settings::HIDE_DATABOXES_DURING_MOVES
    pbSaveShadows do
      if animID[1]
        pbAnimationCore(animations[anim], target, user, true)
      else
        pbAnimationCore(animations[anim], user, target)
      end
    end
    pbToggleDataboxes(true) if Settings::HIDE_DATABOXES_DURING_MOVES
  end

  #-----------------------------------------------------------------------------
  # Used for hiding a single databox.
  #-----------------------------------------------------------------------------
  def pbHideDatabox(idxBattler)
    dataBoxAnim = Animation::DataBoxDisappear.new(@sprites, @viewport, idxBattler)
    loop do
      dataBoxAnim.update
      pbUpdate
      break if dataBoxAnim.animDone?
    end
    dataBoxAnim.dispose
  end

  #-----------------------------------------------------------------------------
  # Calls a flee animation for wild Pokemon.
  #-----------------------------------------------------------------------------
  def pbBattlerFlee(battler, msg = nil)
    @briefMessage = false
    fleeAnim = Animation::BattlerFlee.new(@sprites, @viewport, battler.index, @battle)
    dataBoxAnim = Animation::DataBoxDisappear.new(@sprites, @viewport, battler.index)
    pbAnimateSubstitute(battler, :break)
    loop do
      fleeAnim.update
      dataBoxAnim.update
      pbUpdate
      break if fleeAnim.animDone? && dataBoxAnim.animDone?
    end
    fleeAnim.dispose
    dataBoxAnim.dispose
    if msg.is_a?(String)
      @battle.pbDisplayPaused(_INTL("#{msg}", battler.pbThis))
    else
      @battle.pbDisplayPaused(_INTL("¡{1} huyó!", battler.pbThis))
    end
  end
 
  #-----------------------------------------------------------------------------
  # Calls animations to revert a battler from various battle states.
  #-----------------------------------------------------------------------------
  def pbRevertBattlerStart(idxBattler = -1)
    reversionAnim = Animation::RevertBattlerStart.new(@sprites, @viewport, idxBattler, @battle)
    loop do
      reversionAnim.update
      pbUpdate
      break if reversionAnim.animDone?
    end
    reversionAnim.dispose
  end
  
  def pbRevertBattlerEnd
    reversionAnim = Animation::RevertBattlerEnd.new(@sprites, @viewport, @battle)
    loop do
      reversionAnim.update
      pbUpdate
      break if reversionAnim.animDone?
    end
    reversionAnim.dispose
  end
  
  #-----------------------------------------------------------------------------
  # Calls animation to use an item on a battler.
  #-----------------------------------------------------------------------------
  def pbItemUseAnimation(idxBattler)
    itemAnim = Animation::UseItem.new(@sprites, @viewport, idxBattler)
    pbAnimateSubstitute(idxBattler, :hide)
    loop do
      itemAnim.update
      pbUpdate
      break if itemAnim.animDone?
    end
    itemAnim.dispose
    pbAnimateSubstitute(idxBattler, :show)
  end
  
  #-----------------------------------------------------------------------------
  # Used for refreshing the entire battle scene with a white flash effect.
  #-----------------------------------------------------------------------------
  def pbFlashRefresh(flash = true)
    pbForceEndSpeech
    timer_start = System.uptime
    loop do
      Graphics.update
      pbUpdate
      tone = lerp(0, 255, 0.7, timer_start, System.uptime)
      @viewport.tone.set(tone, tone, tone, 0) if flash
      break if tone >= 255
      break if !flash
    end
    pbRefreshEverything
    timer_start = System.uptime
    loop do
      Graphics.update
      pbUpdate
      break if System.uptime - timer_start >= 0.25
      break if !flash
    end
    timer_start = System.uptime
    loop do
      Graphics.update
      pbUpdate
      tone = lerp(255, 0, 0.4, timer_start, System.uptime)
      @viewport.tone.set(tone, tone, tone, 0) if flash
      break if tone <= 0
      break if !flash
    end
  end


  def pbFlashBlackRefresh(flash = true)
    pbForceEndSpeech
    timer_start = System.uptime
    loop do
      Graphics.update
      pbUpdate
      tone = lerp(0, -255, 0.3, timer_start, System.uptime)
      @viewport.tone.set(tone, tone, tone, 0) if flash
      break if tone <= -255
      break if !flash
    end
    pbRefreshEverything
    timer_start = System.uptime
    loop do
      Graphics.update
      pbUpdate
      break if System.uptime - timer_start >= 0.25
      break if !flash
    end
    timer_start = System.uptime
    loop do
      Graphics.update
      pbUpdate
      tone = lerp(-255, 0, 0.3, timer_start, System.uptime)
      @viewport.tone.set(tone, tone, tone, 0) if flash
      break if tone >= 0
      break if !flash
    end
  end


  
  #-----------------------------------------------------------------------------
  # Utility for pausing further scene processing for a given number of seconds.
  #-----------------------------------------------------------------------------
  def pbPauseScene(seconds = 1)
    timer_start = System.uptime
    until System.uptime - timer_start >= seconds
      pbUpdate
    end
  end
end

#-------------------------------------------------------------------------------
# Animation code to animate a fleeing battler.
#-------------------------------------------------------------------------------
class Battle::Scene::Animation::BattlerFlee < Battle::Scene::Animation
  def initialize(sprites, viewport, idxBattler, battle)
    @idxBattler = idxBattler
    @battle     = battle
    super(sprites, viewport)
  end

  def createProcesses
    delay = 0
    batSprite = @sprites["pokemon_#{@idxBattler}"]
    shaSprite = @sprites["shadow_#{@idxBattler}"]
    battler = addSprite(batSprite, PictureOrigin::BOTTOM)
    shadow  = addSprite(shaSprite, PictureOrigin::CENTER)
    direction = (@battle.battlers[@idxBattler].opposes?(0)) ? batSprite.x : -batSprite.x    
    shadow.setVisible(delay, false)
    battler.setSE(delay, "Battle flee")
    battler.moveOpacity(delay, 8, 0)
    battler.moveDelta(delay, 28, direction, 0)
    battler.setVisible(delay + 28, false)
  end
end

#-------------------------------------------------------------------------------
# Animation code for reverting battlers from various battle states.
#-------------------------------------------------------------------------------
class Battle::Scene::Animation::RevertBattlerStart < Battle::Scene::Animation
  def initialize(sprites, viewport, idxBattler, battle)
    @battle = battle
    @index = idxBattler
    super(sprites, viewport)
  end

  def createProcesses
    darkenBattlefield(@battle, 0, @index, "Anim/Psych Up")
  end
end

class Battle::Scene::Animation::RevertBattlerEnd < Battle::Scene::Animation
  def initialize(sprites, viewport, battle)
    @battle = battle
    super(sprites, viewport)
  end

  def createProcesses
    revertBattlefield(@battle, 4)
  end
end

#-------------------------------------------------------------------------------
# Animation code to animate the use of an item on a battler.
#-------------------------------------------------------------------------------
class Battle::Scene::Animation::UseItem < Battle::Scene::Animation
  def initialize(sprites, viewport, idxBattler)
    @index = idxBattler
    super(sprites, viewport)
  end

  def createProcesses
    return if !@sprites["pokemon_#{@index}"]
    delay = 0
    xpos  = @sprites["pokemon_#{@index}"].x
    ypos  = @sprites["pokemon_#{@index}"].y
    zpos  = @sprites["pokemon_#{@index}"].z
    pulse = addNewSprite(xpos, ypos - 60, Settings::DELUXE_GRAPHICS_PATH + "pulse", PictureOrigin::CENTER)
    pulse.setZ(delay, zpos)
    pulse.setOpacity(delay, 0)
    pulse2 = addNewSprite(xpos, ypos - 60, Settings::DELUXE_GRAPHICS_PATH + "pulse", PictureOrigin::CENTER)
    pulse2.setZ(delay, zpos)
    pulse2.setOpacity(delay, 0)
    [pulse, pulse2].each_with_index do |p, i|
      p.setSE(delay, "Battle item") if i == 0
      p.moveOpacity(delay, 4, 255)
      p.moveZoom(delay, 8, 0)
      delay += 2
    end
  end
end


#===============================================================================
# Calls fleeing animation for roaming Pokemon.
#===============================================================================
class Battle::Battler
  def pbProcessTurn(choice, tryFlee = true)
    return false if fainted?
    if tryFlee && wild? &&
       @battle.rules["alwaysflee"] && @battle.pbCanRun?(@index)
      pbBeginTurn(choice)
      wild_flee(_INTL("¡{1} huyó del combate!", pbThis))
      pbEndTurn(choice)
      return true
    end
    if choice[0] == :Shift
      idxOther = -1
      case @battle.pbSideSize(@index)
      when 2
        idxOther = (@index + 2) % 4
      when 3
        if @index != 2 && @index != 3
          idxOther = (@index.even?) ? 2 : 3
        end
      end
      if idxOther >= 0
        @battle.pbSwapBattlers(@index, idxOther)
        case @battle.pbSideSize(@index)
        when 2
          @battle.pbDisplay(_INTL("¡{1} se desplazó!", pbThis))
        when 3
          @battle.pbDisplay(_INTL("¡{1} se movió al centro!", pbThis))
        end
      end
      pbBeginTurn(choice)
      pbCancelMoves
      @lastRoundMoved = @battle.turnCount
      return true
    end
    if choice[0] != :UseMove
      pbBeginTurn(choice)
      pbEndTurn(choice)
      return false
    end
    PBDebug.log("[Use move] #{pbThis} (#{@index}) used #{choice[2].name}")
    PBDebug.logonerr { pbUseMove(choice, choice[2] == @battle.struggle) }
    @battle.pbJudge
    @battle.pbCalculatePriority if Settings::RECALCULATE_TURN_ORDER_AFTER_SPEED_CHANGES
    return true
  end
end


#===============================================================================
# Calls fleeing animation for Safari Pokemon.
#===============================================================================
class SafariBattle
  def pbStartBattle
    begin
      pkmn = @party2[0]
      pbSetSeen(pkmn)
      @scene.pbStartBattle(self)
      pbDisplayPaused(_INTL("¡Un {1} salvaje apareció!", pkmn.name))
      @scene.pbSafariStart
      weather_data = GameData::BattleWeather.try_get(@weather)
      @scene.pbCommonAnimation(weather_data.animation) if weather_data
      safariBall = GameData::Item.get(:SAFARIBALL).id
      catch_rate = pkmn.species_data.catch_rate
      catchFactor  = (catch_rate * 100) / 1275
      catchFactor  = [[catchFactor, 3].max, 20].min
      escapeFactor = (pbEscapeRate(catch_rate) * 100) / 1275
      escapeFactor = [[escapeFactor, 2].max, 20].min
      loop do
        cmd = @scene.pbSafariCommandMenu(0)
        case cmd
        when 0
          if pbBoxesFull?
            pbDisplay(_INTL("¡Las cajas están llenas! ¡No puedes capturar más Pokémon!"))
            next
          end
          @ballCount -= 1
          @scene.pbRefresh
          rare = (catchFactor * 1275) / 100
          if safariBall
            pbThrowPokeBall(1, safariBall, rare, true)
            if @caughtPokemon.length > 0
              pbRecordAndStoreCaughtPokemon
              @decision = 4
            end
          end
        when 1
          pbDisplayBrief(_INTL("¡{1} lanzó un poco de cebo a {2}!", self.pbPlayer.name, pkmn.name))
          @scene.pbThrowBait
          catchFactor  /= 2 if pbRandom(100) < 90
          escapeFactor /= 2
        when 2
          pbDisplayBrief(_INTL("¡{1} lanzó una roca a {2}!", self.pbPlayer.name, pkmn.name))
          @scene.pbThrowRock
          catchFactor  *= 2
          escapeFactor *= 2 if pbRandom(100) < 90
        when 3
          pbSEPlay("Battle flee")
          pbDisplayPaused(_INTL("¡Escapaste sin problemas!"))
          @decision = 3
        else
          next
        end
        catchFactor  = [[catchFactor, 3].max, 20].min
        escapeFactor = [[escapeFactor, 2].max, 20].min
        if @decision == 0
          if @ballCount <= 0
            pbSEPlay("Safari Zone end")
            pbDisplay(_INTL("Altavoz: ¡No te quedan Safari Ball! ¡Se acabó!"))
            @decision = 2
          elsif pbRandom(100) < 5 * escapeFactor
            @scene.pbBattlerFlee(@battlers[1])
            @decision = 3
          elsif cmd == 1
            pbDisplay(_INTL("¡{1} está comiendo!", pkmn.name))
          elsif cmd == 2
            pbDisplay(_INTL("¡{1} está enfadado!", pkmn.name))
          else
            pbDisplay(_INTL("¡{1} te mira atentamente!", pkmn.name))
          end
          weather_data = GameData::BattleWeather.try_get(@weather)
          @scene.pbCommonAnimation(weather_data.animation) if weather_data
        end
        break if @decision > 0
      end
      @scene.pbEndBattle(@decision)
    rescue BattleAbortedException
      @decision = 0
      @scene.pbEndBattle(@decision)
    end
    return @decision
  end
end


#===============================================================================
# Utilities for special battle animations, such as Mega Evolution.
#===============================================================================
class Battle::Scene::Animation
  #-----------------------------------------------------------------------------
  # Used for animation compatibility with animated Pokemon sprites.
  #-----------------------------------------------------------------------------  
  def addPokeSprite(poke, back = false, origin = PictureOrigin::BOTTOM)
    case poke
    when Pokemon
      s = PokemonSprite.new(@viewport)
      s.setPokemonBitmap(poke, back)
    when Hash
      s = PokemonSprite.new(@viewport)
      s.setSpeciesBitmap(poke[:species], poke[:gender], poke[:form], poke[:shiny], poke[:shadow], back)
      s.hue = poke[:hue] if defined?(s.hue)
    end
    num = @pictureEx.length
    picture = PictureEx.new(s.z)
    picture.x       = s.x
    picture.y       = s.y
    picture.visible = s.visible
    picture.color   = s.color.clone
    picture.tone    = s.tone.clone
    picture.setOrigin(0, origin)
    @pictureEx[num] = picture
    @pictureSprites[num] = s
    @tempSprites.push(s)
    return picture
  end

  #-----------------------------------------------------------------------------
  # Used to darken all sprites in battle for cinematic animations.
  #-----------------------------------------------------------------------------
  def darkenBattlefield(battle, delay = 0, idxBattler = -1, sound = nil)
    tone = Tone.new(-60, -60, -60, 150)
    battleBG = addSprite(@sprites["battle_bg"])
    battleBG.moveTone(delay, 4, tone)
    battle.allBattlers.each do |b|
      if @sprites["pokemon_#{b.index}"].visible
        battler = addSprite(@sprites["pokemon_#{b.index}"], PictureOrigin::BOTTOM)
        if !PluginManager.installed?("[DBK] Animated Pokémon System")
          shadow = addSprite(@sprites["shadow_#{b.index}"], PictureOrigin::CENTER)
          shadow.moveTone(delay, 4, tone)
        end
        if b.index == idxBattler
          battler.setSE(delay, sound) if sound
          #battler.moveTone(delay, 4, Tone.new(255, 255, 255, 255))
        else
          #battler.moveTone(delay, 4, tone)
        end
      end
      if @sprites["dataBox_#{b.index}"].visible
        box = addSprite(@sprites["dataBox_#{b.index}"])
        box.moveTone(delay, 4, tone)
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Reverts the changes made by darkenBattlefield.
  #-----------------------------------------------------------------------------
  def revertBattlefield(battle, delay)
    tone = Tone.new(0, 0, 0, 0)
    battleBG = addSprite(@sprites["battle_bg"])
    battleBG.moveTone(delay, 6, tone)
    battle.allBattlers.each do |b|
      if @sprites["pokemon_#{b.index}"].visible
        battler = addSprite(@sprites["pokemon_#{b.index}"], PictureOrigin::BOTTOM)
        battler.moveOpacity(delay, 6, 255)
        battler.moveTone(delay, 6, tone) 
        if !PluginManager.installed?("[DBK] Animated Pokémon System")
          shadow = addSprite(@sprites["shadow_#{b.index}"], PictureOrigin::CENTER)
          shadow.moveOpacity(delay, 6, 255)
          shadow.moveTone(delay, 6, tone)
        end
      end
      if @sprites["dataBox_#{b.index}"].visible
        box = addSprite(@sprites["dataBox_#{b.index}"])
        box.moveTone(delay, 6, tone)
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Sets the backdrop.
  #-----------------------------------------------------------------------------
  def dxSetBackdrop(checkfile, default, delay)
    if pbResolveBitmap(checkfile)
      file = checkfile
    elsif pbResolveBitmap(default)
      file = default
    else
      file = "Graphics/Pictures/evolutionbg"
    end
    pictureBG = addNewSprite(0, 0, file)
    pictureBG.setVisible(delay, false)
    spriteBG = @pictureEx.length - 1
    bgheight = @pictureSprites[spriteBG].bitmap.height
    zoom = (bgheight >= Graphics.height) ? 1 : 1.5
    @pictureSprites[spriteBG].z = 999
    pictureBG.setZ(delay, @pictureSprites[spriteBG].z)
    pictureBG.setZoom(delay, 100 * zoom)
    return [pictureBG, spriteBG]
  end
  
  #-----------------------------------------------------------------------------
  # Sets the battle bases. Only sets one if a trainer doesn't appear.
  #-----------------------------------------------------------------------------
  def dxSetBases(checkfile, default, delay, xpos, ypos, offset = false)
    file = (pbResolveBitmap(checkfile)) ? checkfile : default
    pictureBASES = []
    if offset
      base = addNewSprite(0, 0, file, PictureOrigin::TOP)
      base.setVisible(delay, false)
      sprite = @pictureEx.length - 1
      xoffset = @pictureSprites[sprite].bitmap.width / 2
      if @opposes
        @pictureSprites[sprite].x = Graphics.width + xoffset
      else
        @pictureSprites[sprite].x = -xoffset
      end
      @pictureSprites[sprite].y = ypos - 32
      @pictureSprites[sprite].z = 999
      base.setXY(delay, @pictureSprites[sprite].x, @pictureSprites[sprite].y)
      base.setZ(delay, @pictureSprites[sprite].z)
      pictureBASES.push(base)
    end
    base = addNewSprite(0, 0, file, PictureOrigin::TOP)
    base.setVisible(delay, false)
    sprite = @pictureEx.length - 1
    @pictureSprites[sprite].x = xpos
    @pictureSprites[sprite].y = ypos
    @pictureSprites[sprite].y += 20 if offset
    @pictureSprites[sprite].z = 999
    base.setXY(delay, @pictureSprites[sprite].x, @pictureSprites[sprite].y)
    base.setZ(delay, @pictureSprites[sprite].z)
    pictureBASES.push(base)
    return [pictureBASES, @pictureSprites[sprite].bitmap.width]
  end


  #-----------------------------------------------------------------------------
  # Sets up a trainer sprite along with an item sprite to be 'used'.
  #-----------------------------------------------------------------------------
  def dxSetTrainerWithItem(trainer, item, delay, mirror = false, base_width = 0, color = Color.white)
    pictureTRAINER = addNewSprite(0, 0, trainer, PictureOrigin::BOTTOM)
    pictureTRAINER.setVisible(delay, false)
    spriteTRAINER = @pictureEx.length - 1
    @pictureSprites[spriteTRAINER].y = 230
    offsetX = @pictureSprites[spriteTRAINER].bitmap.width / 2
    offsetX += ((base_width - @pictureSprites[spriteTRAINER].bitmap.width) / 2).floor
    delta = (base_width.to_f * 0.75).to_i
    if mirror
      @pictureSprites[spriteTRAINER].mirror = true
      @pictureSprites[spriteTRAINER].x = -offsetX
      trainer_end_x = @pictureSprites[spriteTRAINER].x + delta
    else
      @pictureSprites[spriteTRAINER].x = Graphics.width + offsetX
      trainer_end_x = @pictureSprites[spriteTRAINER].x - delta
    end
    @pictureSprites[spriteTRAINER].z = 999
    trainer_x, trainer_y = @pictureSprites[spriteTRAINER].x, @pictureSprites[spriteTRAINER].y
    pictureTRAINER.setXY(delay, trainer_x, trainer_y)
    pictureTRAINER.setZ(delay, @pictureSprites[spriteTRAINER].z)
    if defined?(@pictureSprites[spriteTRAINER].to_last_frame)
      @pictureSprites[spriteTRAINER].to_last_frame
    end
    pictureITEM = []
    for i in [ [2, 0], [-2, 0], [0, 2], [0, -2], [2, 2], [-2, -2], [2, -2], [-2, 2], [0, 0] ]
      outline = addNewSprite(0, 0, item, PictureOrigin::BOTTOM)
      outline.setVisible(delay, false)
      sprite = @pictureEx.length - 1
      @pictureSprites[sprite].x = trainer_end_x + i[0]
      @pictureSprites[sprite].y = 96 + i[1]
      @pictureSprites[sprite].oy = @pictureSprites[sprite].bitmap.height
      @pictureSprites[sprite].z = 999
      outline.setXY(delay, @pictureSprites[sprite].x, @pictureSprites[sprite].y)
      outline.setZ(delay, @pictureSprites[sprite].z)
      outline.setOpacity(delay, 0)
      outline.setColor(delay, color) if i != [0, 0]
      pictureITEM.push([outline, sprite])
    end
    return [pictureTRAINER, pictureITEM]
  end

  
  #-----------------------------------------------------------------------------
  # Sets a Pokemon sprite.
  #-----------------------------------------------------------------------------
  def dxSetPokemon(poke, delay, mirror = false, offset = false, opacity = 100, zoom = 100)
    battle_pos = Battle::Scene.pbBattlerPosition(1, 1)
    picturePOKE = addPokeSprite(poke, false, PictureOrigin::BOTTOM)
    picturePOKE.setVisible(delay, false)
    spritePOKE = @pictureEx.length - 1
    @pictureSprites[spritePOKE].mirror = mirror
    @pictureSprites[spritePOKE].x = battle_pos[0] - 128
    @pictureSprites[spritePOKE].y = battle_pos[1] + 80
    @pictureSprites[spritePOKE].y += 20 if offset
    @pictureSprites[spritePOKE].z = 999
    case poke
    when Pokemon
      poke.species_data.apply_metrics_to_sprite(@pictureSprites[spritePOKE], 1)
    when Hash
      data = [poke[:species], poke[:form]]
      data.push(poke[:gender] == 1) if PluginManager.installed?("[DBK] Animated Pokémon System")
      metrics_data = GameData::SpeciesMetrics.get_species_form(*data)
      metrics_data.apply_metrics_to_sprite(@pictureSprites[spritePOKE], 1)
    end
    picturePOKE.setXY(delay, @pictureSprites[spritePOKE].x, @pictureSprites[spritePOKE].y)
    picturePOKE.setZ(delay, @pictureSprites[spritePOKE].z)
    picturePOKE.setZoom(delay, zoom) if zoom != 100
    picturePOKE.setOpacity(delay, opacity) if opacity != 100
    return [picturePOKE, spritePOKE]
  end
  
  #-----------------------------------------------------------------------------
  # Sets a Pokemon sprite with an outline.
  #-----------------------------------------------------------------------------
  def dxSetPokemonWithOutline(poke, delay, mirror = false, offset = false, color = Color.white)
    battle_pos = Battle::Scene.pbBattlerPosition(1, 1)
    picturePOKE = []
    for i in [ [2, 0], [-2, 0], [0, 2], [0, -2], [2, 2], [-2, -2], [2, -2], [-2, 2], [0, 0] ]
      outline = addPokeSprite(poke, false, PictureOrigin::BOTTOM)
      outline.setVisible(delay, false)
      sprite = @pictureEx.length - 1
      @pictureSprites[sprite].mirror = mirror
      @pictureSprites[sprite].x = battle_pos[0] + i[0] - 128
      @pictureSprites[sprite].y = battle_pos[1] + i[1] + 80
      @pictureSprites[sprite].y += 20 if offset
      @pictureSprites[sprite].z = 999
      case poke
      when Pokemon
        poke.species_data.apply_metrics_to_sprite(@pictureSprites[sprite], 1)
      when Hash
        data = [poke[:species], poke[:form]]
        data.push(poke[:gender] == 1) if PluginManager.installed?("[DBK] Animated Pokémon System")
        metrics_data = GameData::SpeciesMetrics.get_species_form(*data)
        metrics_data.apply_metrics_to_sprite(@pictureSprites[sprite], 1)
      end
      outline.setXY(delay, @pictureSprites[sprite].x, @pictureSprites[sprite].y)
      outline.setZ(delay, @pictureSprites[sprite].z)
      outline.setColor(delay, color) if i != [0, 0]
      picturePOKE.push([outline, sprite])
    end
    return picturePOKE
  end
  
  #-----------------------------------------------------------------------------
  # Specifically used to reapply spot patterns to Spinda sprites during animations.
  #-----------------------------------------------------------------------------
  def dxSetSpotPatterns(pkmn, sprite)
    alter_bitmap_function = MultipleForms.hasFunction?(pkmn, "alterBitmap")
    return if !alter_bitmap_function
    sprite.setPokemonBitmap(pkmn)
  end
  
  
  #-----------------------------------------------------------------------------
  # Sets a sprite.
  #-----------------------------------------------------------------------------
  def dxSetSprite(file, delay, xpos, ypos, origin = PictureOrigin::CENTER, opacity = 100, zoom = 100)
    pictureSPRITE = addNewSprite(xpos, ypos, file, origin)
    spriteSPRITE = @pictureEx.length - 1
    pictureSPRITE.setXY(delay, xpos, ypos)
    pictureSPRITE.setZ(delay, 999)
    pictureSPRITE.setZoom(delay, zoom) if zoom != 100
    pictureSPRITE.setOpacity(delay, opacity) if opacity != 100
    pictureSPRITE.setVisible(delay, false)
    return [pictureSPRITE, spriteSPRITE]
  end
  
  #-----------------------------------------------------------------------------
  # Sets a sprite with an outline.
  #-----------------------------------------------------------------------------
  def dxSetSpriteWithOutline(file, delay, xpos, ypos, color = Color.white)
    pictureSPRITE = []
    if file && pbResolveBitmap(file)
      for i in [ [2, 0],  [-2, 0], [0, 2],  [0, -2], [2, 2],  [-2, -2], [2, -2], [-2, 2], [0, 0] ]
        outline = addNewSprite(0, 0, file, PictureOrigin::BOTTOM)
        outline.setVisible(delay, false)
        sprite = @pictureEx.length - 1
        @pictureSprites[sprite].x = xpos + i[0]
        @pictureSprites[sprite].y = ypos + i[1]
        @pictureSprites[sprite].z = 999
        outline.setXY(delay, @pictureSprites[sprite].x, @pictureSprites[sprite].y)
        outline.setZ(delay, @pictureSprites[sprite].z)
        outline.setOpacity(delay, 0)
        outline.setColor(delay, color) if i != [0, 0]
        pictureSPRITE.push([outline, sprite])
      end
    end
    return pictureSPRITE
  end
  
  #-----------------------------------------------------------------------------
  # Sets a sprite to act as a title.
  #-----------------------------------------------------------------------------
  def dxSetTitleWithOutline(file, delay, upper = false, color = Color.white)
    pictureTITLE = []
    if file && pbResolveBitmap(file)
      for i in [ [2, 0],  [-2, 0], [0, 2],  [0, -2], [2, 2],  [-2, -2], [2, -2], [-2, 2], [0, 0] ]
        outline = addNewSprite(0, 0, file, PictureOrigin::CENTER)
        outline.setVisible(delay, false)
        sprite = @pictureEx.length - 1
        @pictureSprites[sprite].x = (Graphics.width - @pictureSprites[sprite].bitmap.width / 2) + i[0]
        if upper
          @pictureSprites[sprite].y = @pictureSprites[sprite].bitmap.height / 2 + i[1]
        else
          @pictureSprites[sprite].y = (Graphics.height - @pictureSprites[sprite].bitmap.height / 2) + i[1]
        end
        @pictureSprites[sprite].z = 999
        outline.setXY(delay, @pictureSprites[sprite].x, @pictureSprites[sprite].y)
        outline.setZ(delay, @pictureSprites[sprite].z)
        outline.setZoom(delay, 300)
        outline.setOpacity(delay, 0)
        outline.setColor(delay, color) if i != [0, 0]
        outline.setTone(delay, Tone.new(255, 255, 255, 255))
        pictureTITLE.push([outline, sprite])
      end
    end
    return pictureTITLE
  end
  
  #-----------------------------------------------------------------------------
  # Sets an overlay.
  #-----------------------------------------------------------------------------
  def dxSetOverlay(file, delay)
    pictureOVERLAY = addNewSprite(0, 0, file)
    pictureOVERLAY.setVisible(delay, false)
    spriteOVERLAY = @pictureEx.length - 1
    @pictureSprites[spriteOVERLAY].z = 999
    pictureOVERLAY.setZ(delay, @pictureSprites[spriteOVERLAY].z)
    pictureOVERLAY.setOpacity(delay, 0)
    return [pictureOVERLAY, spriteOVERLAY]
  end
  
  #-----------------------------------------------------------------------------
  # Sets a set of four particle sprites by repeating an image.
  #-----------------------------------------------------------------------------
  def dxSetParticles(file, delay, xpos, ypos, range, offset = false)
    picturePARTICLES = []
    4.times do |i|
      particle = addNewSprite(0, 0, file, PictureOrigin::CENTER)
      particle.setVisible(delay, false)
      sprite = @pictureEx.length - 1
      case i
      when 0
        @pictureSprites[sprite].x = xpos - range
        @pictureSprites[sprite].y = ypos - range
      when 1
        @pictureSprites[sprite].x = xpos + range
        @pictureSprites[sprite].y = ypos - range
      when 2
        @pictureSprites[sprite].x = xpos - range
        @pictureSprites[sprite].y = ypos + range
      when 3
        @pictureSprites[sprite].x = xpos + range
        @pictureSprites[sprite].y = ypos + range
      end
      @pictureSprites[sprite].y += 20 if offset
      @pictureSprites[sprite].z = 999
      origin_x, origin_y = @pictureSprites[sprite].x, @pictureSprites[sprite].y
      particle.setXY(delay, origin_x, origin_y)
      particle.setZ(delay, @pictureSprites[sprite].z)
      picturePARTICLES.push([particle, origin_x, origin_y])
    end
    return picturePARTICLES
  end
  
  #-----------------------------------------------------------------------------
  # Sets a set of four particle sprites cut up from a single image.
  #-----------------------------------------------------------------------------
  def dxSetParticlesRect(file, delay, width, length, range, offset = false, inwards = false, idxBattler = nil)
    picturePARTICLES = []
    if idxBattler
      batSprite = @sprites["pokemon_#{idxBattler}"]
      pos = Battle::Scene.pbBattlerPosition(idxBattler, batSprite.sideSize)
      xpos = pos[0]
      ypos = pos[1] - batSprite.bitmap.width / 2
      zpos = batSprite.z
    else
      xpos = Graphics.width / 2
      ypos = Graphics.height / 2
      zpos = 999
    end
    4.times do |i|
      particle = addNewSprite(0, 0, file, PictureOrigin::CENTER)
      particle.setVisible(delay, false)
      sprite = @pictureEx.length - 1
      hWidth = (width / 2).round
      hLength = (length / 2).round
      case i
      when 0
        particle.setSrc(delay, 0, 0)
        particle.setSrcSize(delay, hWidth, hLength)
        start_x, start_y = xpos - range, ypos - range
        end_x, end_y = -range, -range
      when 1
        particle.setSrc(delay, hWidth, 0)
        particle.setSrcSize(delay, width, hLength)
        start_x, start_y = xpos + hWidth + range, ypos - range
        end_x, end_y = Graphics.width + range, -range
      when 2
        particle.setSrc(delay, 0, hLength)
        particle.setSrcSize(delay, hWidth, length)
        start_x, start_y = xpos - range, ypos + hLength + range
        end_x, end_y = -range, Graphics.height + range
      when 3
        particle.setSrc(delay, hWidth, hLength)
        particle.setSrcSize(delay, width, length)
        start_x, start_y = xpos + hWidth + range, ypos + hLength + range
        end_x, end_y = Graphics.width + range, Graphics.height + range
      end
      @pictureSprites[sprite].z = zpos
      particle.setZ(delay, @pictureSprites[sprite].z)
      if inwards
        start_y += 20 if offset
        @pictureSprites[sprite].x = start_x
        @pictureSprites[sprite].y = start_y
        particle.setXY(delay, @pictureSprites[sprite].x, @pictureSprites[sprite].y)
        picturePARTICLES.push([particle, start_x, start_y])
      else
        @pictureSprites[sprite].x = xpos + (width / 4).round
        @pictureSprites[sprite].y = ypos + (length / 4).round
        @pictureSprites[sprite].y += 20 if offset
        particle.setXY(delay, @pictureSprites[sprite].x, @pictureSprites[sprite].y)
        picturePARTICLES.push([particle, end_x, end_y])
      end
    end
    return picturePARTICLES
  end

  #-----------------------------------------------------------------------------
  # Sets the skip button.
  #-----------------------------------------------------------------------------
  def dxSetSkipButton(delay)
    path = Settings::DELUXE_GRAPHICS_PATH + "skip_button"
    pictureBUTTON = addNewSprite(0, Graphics.height, path)
    sprite = @pictureEx.length - 1
    @pictureSprites[sprite].z = 999
    pictureBUTTON.setZ(delay, @pictureSprites[sprite].z)
    return pictureBUTTON
  end
  
  #-----------------------------------------------------------------------------
  # Sets a fade-in/fade-out overlay.
  #-----------------------------------------------------------------------------
  def dxSetFade(delay)
    path = Settings::DELUXE_GRAPHICS_PATH + "fade"
    pictureFADE = addNewSprite(0, 0, path)
    sprite = @pictureEx.length - 1
    @pictureSprites[sprite].z = 999
    pictureFADE.setZ(delay, @pictureSprites[sprite].z)
    pictureFADE.setOpacity(delay, 0)
    return pictureFADE
  end
end

#-------------------------------------------------------------------------------
# Adds alias for changing Pokemon sprite file names. Used by certain animations.
#-------------------------------------------------------------------------------
class PokemonSprite < Sprite
  attr_reader :name

  def name=(*args)
    case args[0]
    when :Symbol
      setSpeciesBitmap(*args)
    when :Pokemon
      setPokemonBitmap(*args)
    end
  end
end

#-------------------------------------------------------------------------------
# Gets the file names for battle background elements. Used by certain animations.
#-------------------------------------------------------------------------------
class Battle
  def pbGetBattlefieldFiles
    case @time
    when 1 then time = "eve"
    when 2 then time = "night"
    end
    backdropFilename = @backdrop
    baseFilename = @backdrop
    baseFilename = sprintf("%s_%s", baseFilename, @backdropBase) if @backdropBase
    if time
      trialName = sprintf("%s_%s", backdropFilename, time)
      if pbResolveBitmap(sprintf("Graphics/Battlebacks/" + trialName + "_bg"))
        backdropFilename = trialName
      end
      trialName = sprintf("%s_%s", baseFilename, time)
      if pbResolveBitmap(sprintf("Graphics/Battlebacks/" + trialName + "_base1"))
        baseFilename = trialName
      end
    end
    if !pbResolveBitmap(sprintf("Graphics/Battlebacks/" + baseFilename + "_base1")) && @backdropBase
      baseFilename = @backdropBase
      if time
        trialName = sprintf("%s_%s", baseFilename, time)
        if pbResolveBitmap(sprintf("Graphics/Battlebacks/" + trialName + "_base1"))
          baseFilename = trialName
        end
      end
    end
    return backdropFilename, baseFilename
  end
end

#-------------------------------------------------------------------------------
# Gets colors related to each type. Used by certain animations.
#-------------------------------------------------------------------------------
def pbGetTypeColors(type)
  case type
  when :NORMAL   then outline = [216, 216, 192]; bg = [168, 168, 120]
  when :FIGHTING then outline = [240, 128, 48];  bg = [192, 48, 40]
  when :FLYING   then outline = [200, 192, 248]; bg = [168, 144, 240]
  when :POISON   then outline = [216, 128, 184]; bg = [160, 64, 160]
  when :GROUND   then outline = [248, 248, 120]; bg = [224, 192, 104]
  when :ROCK     then outline = [224, 192, 104]; bg = [184, 160, 56]
  when :BUG      then outline = [216, 224, 48];  bg = [168, 184, 32]
  when :GHOST    then outline = [168, 144, 240]; bg = [112, 88, 152]
  when :STEEL    then outline = [216, 216, 192]; bg = [184, 184, 208]
  when :FIRE     then outline = [248, 208, 48];  bg = [240, 128, 48]
  when :WATER    then outline = [152, 216, 216]; bg = [104, 144, 240]
  when :GRASS    then outline = [192, 248, 96];  bg = [120, 200, 80]
  when :ELECTRIC then outline = [248, 248, 120]; bg = [248, 208, 48]
  when :PSYCHIC  then outline = [248, 192, 176]; bg = [248, 88, 136]
  when :ICE      then outline = [208, 248, 232]; bg = [152, 216, 216]
  when :DRAGON   then outline = [184, 160, 248]; bg = [112, 56, 248]
  when :DARK     then outline = [168, 168, 120]; bg = [112, 88, 72]
  when :FAIRY    then outline = [248, 216, 224]; bg = [240, 168, 176]
  else                outline = [255, 255, 255]; bg = [200, 200, 200]
  end
  return outline, bg
end