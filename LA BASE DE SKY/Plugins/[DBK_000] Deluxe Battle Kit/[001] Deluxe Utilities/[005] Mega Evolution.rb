#===============================================================================
# All changes in code related to Mega Evolution.
# This is used to standardize the Mega Evolution mechanic with the same features
# included with other battle mechanics added by supported plugins.
#===============================================================================


#-------------------------------------------------------------------------------
# Game stat tracking for wild Mega battles.
#-------------------------------------------------------------------------------
class GameStats
  alias mega_initialize initialize
  def initialize
    mega_initialize
    @wild_mega_battles_won = 0
  end

  def wild_mega_battles_won
    return @wild_mega_battles_won || 0
  end
  
  def wild_mega_battles_won=(value)
    @wild_mega_battles_won = 0 if !@wild_mega_battles_won
    @wild_mega_battles_won = value
  end
end

#-------------------------------------------------------------------------------
# Displays a held item icon for Mega Stones in the Party menu.
#-------------------------------------------------------------------------------
module GameData
  class Item
    Item.singleton_class.alias_method :mega_held_icon_filename, :held_icon_filename
    def self.held_icon_filename(item)
      ret = self.mega_held_icon_filename(item)
      item_data = self.try_get(item)
      if item_data && item_data.is_mega_stone?
        base = "Graphics/UI/Party/icon_"
        new_ret = base + "mega_#{item_data.id}"
        return new_ret if pbResolveBitmap(new_ret)
        new_ret = base + "mega"
        return new_ret if pbResolveBitmap(new_ret)
      end
      return ret
    end
  end
end

#-------------------------------------------------------------------------------
# Updates to Mega Evolution battle scripts.
#-------------------------------------------------------------------------------
class Battle
  attr_reader :mega_rings

  def pbAttackPhaseMegaEvolution
    pbPriority.each do |b|
      next unless @choices[b.index][0] == :UseMove && !b.fainted?
      owner = pbGetOwnerIndexFromBattlerIndex(b.index)
      next if @megaEvolution[b.idxOwnSide][owner] != b.index
      pbMegaEvolve(b.index)
    end
  end
  
  alias dx_pbHasMegaRing? pbHasMegaRing?
  def pbHasMegaRing?(idxBattler)
    return true if @battlers[idxBattler].wild?
    dx_pbHasMegaRing?(idxBattler)
  end

  def pbCanMegaEvolve?(idxBattler)
    battler = @battlers[idxBattler]
    return false if $game_switches[Settings::NO_MEGA_EVOLUTION]
    return false if !battler.hasMega?
    return true if $DEBUG && Input.press?(Input::CTRL) && !battler.wild?
    return false if battler.effects[PBEffects::SkyDrop] >= 0
    return false if !pbHasMegaRing?(idxBattler)
    side  = battler.idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    return @megaEvolution[side][owner] == -1
  end
  
  def pbMegaEvolve(idxBattler)
    battler = @battlers[idxBattler]
    return if !battler || !battler.pokemon
    return if !battler.hasMega? || battler.mega?
    $stats.mega_evolution_count += 1 if battler.pbOwnedByPlayer?
    pbDeluxeTriggers(idxBattler, nil, "BeforeMegaEvolution", battler.species, *battler.pokemon.types)
    @scene.pbAnimateSubstitute(idxBattler, :hide)
    old_ability = battler.ability_id
    if battler.hasActiveAbility?(:ILLUSION)
      Battle::AbilityEffects.triggerOnBeingHit(battler.ability, nil, battler, nil, self)
    end
    if battler.wild?
      case battler.pokemon.megaMessage
      when 1
        pbDisplay(_INTL("¡{1} irradia energía!", battler.pbThis))
      else
        pbDisplay(_INTL("¡{2} de {2} irradia energía!", battler.pbThis, battler.itemName))
      end
    else
      trainerName = pbGetOwnerName(idxBattler)
      case battler.pokemon.megaMessage
      when 1
        pbDisplay(_INTL("¡El deseo ferviente de {1} ha alcanzado a {2}!", trainerName, battler.pbThis))
      else
        pbDisplay(_INTL("¡{2} de {1} está reaccionando a {4} de {3}!",
                        battler.pbThis(true), battler.itemName, trainerName, pbGetMegaRingName(idxBattler)))
      end
    end
    pbAnimateMegaEvolution(battler)
    megaName = battler.pokemon.megaName
    megaName = _INTL("Mega {1}", battler.pokemon.speciesName) if nil_or_empty?(megaName)
    pbDisplay(_INTL("¡{1} ha megaevolucionado en {2}!", battler.pbThis, megaName))
    side  = battler.idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    @megaEvolution[side][owner] = -2
    if battler.isSpecies?(:GENGAR) && battler.mega?
      battler.effects[PBEffects::Telekinesis] = 0
    end
    battler.pbOnLosingAbility(old_ability)
    battler.pbTriggerAbilityOnGainingIt
    pbCalculatePriority(false, [idxBattler]) if Settings::RECALCULATE_TURN_ORDER_AFTER_MEGA_EVOLUTION
    pbDeluxeTriggers(idxBattler, nil, "AfterMegaEvolution", battler.species, *battler.pokemon.types)
    @scene.pbAnimateSubstitute(idxBattler, :show)
  end
  
  def pbAnimateMegaEvolution(battler)
    if @scene.pbCommonAnimationExists?("MegaEvolution") && !Settings::SHOW_MEGA_ANIM
      pbCommonAnimation("MegaEvolution", battler)
      battler.pokemon.makeMega
      battler.form_update(true)
      pbCommonAnimation("MegaEvolution2", battler)
    else 
      if Settings::SHOW_MEGA_ANIM && $PokemonSystem.battlescene == 0
        @scene.pbShowMegaEvolution(battler.index)
        battler.pokemon.makeMega
        battler.form_update(true)
      else
        @scene.pbRevertBattlerStart(battler.index)
        battler.pokemon.makeMega
        battler.form_update(true)
        @scene.pbRevertBattlerEnd
      end
    end
  end
end

#-------------------------------------------------------------------------------
# Mega Evolution battler eligibility check.
#-------------------------------------------------------------------------------
class Battle::Battler
  def hasMega?
    return false if shadowPokemon? || @effects[PBEffects::Transform]
    return false if wild? && @battle.wildBattleMode != :mega
    return false if @battle.raidBattle? && @battle.raidRules[:style] != :Basic
    return false if !getActiveState.nil?
    return false if hasEligibleAction?(:primal, :zmove, :ultra, :zodiac)
    return @pokemon&.hasMegaForm?
  end
  
  def unMega
    @battle.scene.pbRevertBattlerStart(@index)
    @pokemon.makeUnmega if mega?
    self.form_update(true)
    @battle.scene.pbRevertBattlerEnd
  end
end

#-------------------------------------------------------------------------------
# Displays a new Mega Evolution icon on battler databoxes.
#-------------------------------------------------------------------------------
class Battle::Scene::PokemonDataBox < Sprite
  def draw_special_form_icon
    specialX = (@battler.opposes?(0)) ? 208 : -28
    if @battler.shadowPokemon? && @battler.inHyperMode?
      specialY = 8
      filename = "Graphics/UI/Battle/icon_hyper_mode"
    elsif @battler.mega?
      specialY = 8
      base_file = "Graphics/UI/Battle/icon_mega"
      try_file = base_file + "_" + @battler.pokemon.speciesName
      filename = (pbResolveBitmap(try_file)) ? try_file : base_file
    elsif @battler.primal?
      specialY = 4
      base_file = "Graphics/UI/Battle/icon_primal"
      try_file = base_file + "_" + @battler.pokemon.speciesName
      filename = (pbResolveBitmap(try_file)) ? try_file : base_file
    end
    pbDrawImagePositions(self.bitmap, [[filename, @spriteBaseX + specialX, specialY]]) if filename
  end
end

#===============================================================================
# Battle animation for triggering Mega Evolution.
#===============================================================================
class Battle::Scene::Animation::BattlerMegaEvolve < Battle::Scene::Animation
  #-----------------------------------------------------------------------------
  # Initializes data used for the animation.
  #-----------------------------------------------------------------------------
  def initialize(sprites, viewport, idxBattler, battle)
    #---------------------------------------------------------------------------
    # Gets Pokemon data from battler index.
    @battle = battle
    @battler = @battle.battlers[idxBattler]
    @opposes = @battle.opposes?(idxBattler)
    @pkmn = @battler.pokemon
    @mega = {
      :pokemon => @pkmn,
      :species => @pkmn.species,
      :gender  => @pkmn.gender,
      :form    => @pkmn.getMegaForm,
      :shiny   => @pkmn.shiny?,
      :shadow  => @pkmn.shadowPokemon?,
      :hue     => @pkmn.super_shiny_hue
    }
    @cry_file = GameData::Species.cry_filename(@mega[:species], @mega[:form])
    if @battler.item && @battler.item.is_mega_stone?
      @megastone_file = "Graphics/Items/" + @battler.item_id.to_s
    end
    #---------------------------------------------------------------------------
    # Gets trainer data from battler index (non-wild only).
    if !@battler.wild?
      trainer_item = :MEGARING
      trainer = @battle.pbGetOwnerFromBattlerIndex(idxBattler)
      if @battle.pbOwnedByPlayer?(idxBattler)
        @trainer_file = GameData::TrainerType.player_front_sprite_filename(trainer.trainer_type)
        @battle.mega_rings.each do |item|
          next if !$bag.has?(item)
          trainer_item = item
        end
      else
	    @trainer_file = GameData::TrainerType.front_sprite_filename(trainer.trainer_type)
        trainer_items = @battle.pbGetOwnerItems(idxBattler)
        @battle.mega_rings.each do |item|
          next if !trainer_items&.include?(item)
          trainer_item = item
        end
      end
      @item_file = "Graphics/Items/" + trainer_item.to_s
    end
    #---------------------------------------------------------------------------
    # Gets background and animation data.
    @path = Settings::DELUXE_GRAPHICS_PATH
    backdropFilename, baseFilename = @battle.pbGetBattlefieldFiles
    @bg_file   = "Graphics/Battlebacks/" + backdropFilename + "_bg"
    @base_file = "Graphics/Battlebacks/" + baseFilename + "_base1"
    super(sprites, viewport)
  end
  
  #-----------------------------------------------------------------------------
  # Plays the animation.
  #-----------------------------------------------------------------------------
  def createProcesses
    delay = 0
    center_x, center_y = Graphics.width / 2, Graphics.height / 2
    #---------------------------------------------------------------------------
    # Sets up background.
    bgData = dxSetBackdrop(@path + "Mega/bg", @bg_file, delay)
    picBG, sprBG = bgData[0], bgData[1]
    #---------------------------------------------------------------------------
    # Sets up bases.
    baseData = dxSetBases(@path + "Mega/base", @base_file, delay, center_x, center_y, !@battler.wild?)
    arrBASES, base_width = baseData[0], baseData[1]
    #---------------------------------------------------------------------------
    # Sets up trainer & Mega Ring                                          
    if !@battler.wild?
      trData = dxSetTrainerWithItem(@trainer_file, @item_file, delay, !@opposes, base_width)
      picTRAINER, arrITEM = trData[0], trData[1]
    end
    #---------------------------------------------------------------------------
    # Sets up overlay.
    overlayData = dxSetOverlay(@path + "burst", delay)
    picOVERLAY, sprOVERLAY = overlayData[0], overlayData[1]
    #---------------------------------------------------------------------------
    # Sets up battler.
    pokeData = dxSetPokemon(@pkmn, delay, !@opposes, !@battler.wild?)
    picPOKE, sprPOKE = pokeData[0], pokeData[1]
    #---------------------------------------------------------------------------
    # Sets up Mega Stone.
    pkmnsprite = @pictureSprites[sprPOKE]
    item_y = pkmnsprite.y - pkmnsprite.bitmap.height + findTop(pkmnsprite.bitmap)
    arrSTONE = dxSetSpriteWithOutline(@megastone_file, delay, center_x, item_y)
    #---------------------------------------------------------------------------
    # Animation objects.
    offset_y = (@battler.wild?) ? center_y : center_y + 20
    orbData = dxSetSprite(@path + "Mega/orb_1", delay, center_x, offset_y, PictureOrigin::CENTER, 0, 0)
    picORB, sprORB = orbData[0], orbData[1]
    shineData = dxSetSprite(@path + "Mega/shine", delay, center_x, offset_y)
    picSHINE, sprSHINE = shineData[0], shineData[1]
    #---------------------------------------------------------------------------
    # Sets up Mega Pokemon.
    arrPOKE = dxSetPokemonWithOutline(@mega, delay, !@opposes, !@battler.wild?)
    arrPOKE.last[0].setColor(delay, Color.white)
    #---------------------------------------------------------------------------
    # Animation objects.
    orb2Data = dxSetSprite(@path + "Mega/orb_2", delay, center_x, offset_y, PictureOrigin::CENTER, 0)
    picORB2, sprORB2 = orb2Data[0], orb2Data[1]
    arrPARTICLES = dxSetParticles(@path + "particle", delay, center_x, center_y, 200)
    pulseData = dxSetSprite(@path + "pulse", delay, center_x, offset_y, PictureOrigin::CENTER, 100, 50)
    picPULSE, sprPULSE = pulseData[0], pulseData[1]
    #---------------------------------------------------------------------------
    # Sets up Mega icon.
    pkmnsprite = @pictureSprites[arrPOKE.last[1]]
    icon_y = pkmnsprite.y - pkmnsprite.bitmap.height + findTop(pkmnsprite.bitmap) - 20
    iconData = dxSetSprite(@path + "Mega/icon", delay, center_x, icon_y, PictureOrigin::BOTTOM, 0)
    picICON, sprICON = iconData[0], iconData[1]
    #---------------------------------------------------------------------------
    # Sets up skip button & fade out.
    picBUTTON = dxSetSkipButton(delay)
    picFADE = dxSetFade(delay)
    ############################################################################
    # Animation start.
    ############################################################################
    # Fades in scene.
    picFADE.moveOpacity(delay, 8, 255)
    delay = picFADE.totalDuration
    picBG.setVisible(delay, true)
    arrBASES.last.setVisible(delay, true)
    picPOKE.setVisible(delay, true)
    picFADE.moveOpacity(delay, 8, 0)
    delay = picFADE.totalDuration
    picBUTTON.moveDelta(delay, 6, 0, -38)
    picBUTTON.moveDelta(delay + 36, 6, 0, 38)
    #---------------------------------------------------------------------------
    # Slides trainer on screen with base (non-wild only).
    if !@battler.wild?
      picTRAINER.setVisible(delay + 4, true)
      arrBASES.first.setVisible(delay + 4, true)
      delta = (base_width.to_f * 0.75).to_i
      delta = -delta if @opposes
      picTRAINER.moveDelta(delay + 4, 8, delta, 0)
      arrBASES.first.moveDelta(delay + 4, 8, delta, 0)
      delay = picTRAINER.totalDuration + 1
      #-------------------------------------------------------------------------
      # Mega Ring appears with outline; slide upwards.
      picTRAINER.setSE(delay, "DX Action")
      arrITEM.each do |p, s|
        p.setVisible(delay, true)
        p.moveDelta(delay, 15, 0, -20)
        p.moveOpacity(delay, 15, 255)
        p.moveOpacity(delay + 15, 8, 0)
      end
      delay = picTRAINER.totalDuration
    end
    #---------------------------------------------------------------------------
    # Mega Stone appears with outline; slide upwards.
    arrSTONE.each do |p, s| 
      p.setVisible(delay, true)
      p.moveDelta(delay, 15, 0, -20)
      p.moveOpacity(delay, 15, 255)
      p.moveOpacity(delay + 15, 8, 0)
    end
    #---------------------------------------------------------------------------
    # Darkens background/base tone; brightens Pokemon to white.
    picBG.setSE(delay, "DX Power Up") if @battler.wild?
    picBG.moveTone(delay, 15, Tone.new(-200, -200, -200))
    arrBASES.each { |p| p.moveTone(delay, 15, Tone.new(-200, -200, -200)) }
    picPOKE.moveTone(delay, 8, Tone.new(-255, -255, -255, 255))
    picPOKE.moveColor(delay + 8, 6, Color.white)
    #---------------------------------------------------------------------------
    # Particles begin drawing in to Pokemon.
    repeat = delay
    2.times do |t|
      repeat -= 4 if t > 0
      arrPARTICLES.each_with_index do |p, i|
        p[0].setVisible(repeat + i, true)
        p[0].moveXY(repeat + i, 4, center_x, center_y)
        repeat = p[0].totalDuration
        p[0].setVisible(repeat + i, false)
        p[0].setXY(repeat + i, p[1], p[2])
        p[0].setZoom(repeat + i, 100)
        repeat = p[0].totalDuration - 2
      end
    end
    particleEnd = arrPARTICLES.last[0].totalDuration
    delay = picPOKE.totalDuration + 4
    #---------------------------------------------------------------------------
    # White orb engulfs Pokemon; cracks appear; orb expands away from Pokemon.
    picORB.setVisible(delay, true)
    picORB2.setVisible(delay, true)
    picORB.setSE(delay, "Anim/Psych Up")
    picORB.moveZoom(delay, 12, 100)
    picORB.moveOpacity(delay, 12, 255)
    picORB2.moveOpacity(particleEnd, 16, 255)
    delay = picORB2.totalDuration
    picSHINE.setVisible(delay, true)
    picSHINE.moveOpacity(delay, 4, 255)
    picPOKE.setVisible(delay, false)
    t = 0.5
    16.times do |i|
      picORB.moveXY(delay, t, @pictureSprites[sprORB].x + 2, @pictureSprites[sprORB].y)
      picORB2.moveXY(delay, t, @pictureSprites[sprORB2].x + 2, @pictureSprites[sprORB2].y)
      picORB.moveXY(delay + t, t, @pictureSprites[sprORB].x - 2, @pictureSprites[sprORB].y)
      picORB2.moveXY(delay + t, t, @pictureSprites[sprORB2].x - 2, @pictureSprites[sprORB2].y)
      delay = picORB2.totalDuration
    end
    picORB2.setSE(delay, "Anim/fog2")
    picORB2.moveZoom(delay, 8, 1000)
    picORB2.moveOpacity(delay, 8, 0)
    arrPOKE.each { |p, s| p.setVisible(delay + 6, true) }
    picORB.moveZoom(delay + 6, 8, 1000)
    picORB.moveOpacity(delay + 6, 8, 0)
    #---------------------------------------------------------------------------
    # White screen flash; shows silhouette of Mega Pokemon.
    picFADE.setColor(delay + 4, Color.white)
    picFADE.moveOpacity(delay + 4, 12, 255)
    delay = picFADE.totalDuration
    arrPOKE.last[0].setColor(delay, Color.black)
    picFADE.moveOpacity(delay, 6, 0)
    picFADE.setColor(delay + 6, Color.black)
    delay = picFADE.totalDuration
    #---------------------------------------------------------------------------
    # Mega Pokemon revealed; pulse expands outwards; overlay & Mega icon shown.
    picOVERLAY.setVisible(delay, true)
    picOVERLAY.moveOpacity(delay, 5, 0)
    picSHINE.setVisible(delay, true)
    picICON.setVisible(delay, true)
    picICON.moveOpacity(delay + 4, 8, 255)
    picPULSE.setVisible(delay, true)
    picPULSE.moveZoom(delay, 5, 1000)
    picPULSE.moveOpacity(delay + 2, 5, 0)
    arrPOKE.last[0].moveColor(delay, 8, Color.new(0, 0, 0, 0))
    #---------------------------------------------------------------------------
    # Shakes Pokemon; plays cry; flashes overlay. Fades out.
    16.times do |i|
      if i > 0
        arrPOKE.each { |p, s| p.moveXY(delay, t, @pictureSprites[s].x, @pictureSprites[s].y + 2) }
        arrPOKE.each { |p, s| p.moveXY(delay + t, t, @pictureSprites[s].x, @pictureSprites[s].y - 2) }
        picOVERLAY.moveOpacity(delay + t, 2, 160)
        picSHINE.moveOpacity(delay + t, 2, 160)
      else
        picPOKE.setSE(delay + t, @cry_file) if @cry_file
      end
      picOVERLAY.moveOpacity(delay + t, 2, 240)
      picSHINE.moveOpacity(delay + t, 2, 240)
      delay = arrPOKE.last[0].totalDuration
    end
    picOVERLAY.moveOpacity(delay, 4, 0)
    picSHINE.moveOpacity(delay, 4, 0)
    picFADE.moveOpacity(delay + 20, 8, 255)
  end
end

#-------------------------------------------------------------------------------
# Calls the animation.
#-------------------------------------------------------------------------------
class Battle::Scene
  def pbShowMegaEvolution(idxBattler)
    megaAnim = Animation::BattlerMegaEvolve.new(@sprites, @viewport, idxBattler, @battle)
    loop do
      if Input.press?(Input::ACTION)
        pbPlayCancelSE
        break 
      end
      megaAnim.update
      pbUpdate
      break if megaAnim.animDone?
    end
    megaAnim.dispose
  end
end