################################################################################
#
# Battle scene
#
################################################################################

class Battle::Scene
  #-----------------------------------------------------------------------------
  # Updates whether the battler's sprite or Substitute doll should be displayed.
  #-----------------------------------------------------------------------------
  def pbUpdateSubstituteSprite(idxBattler, mode)
    battler = (idxBattler.respond_to?("index")) ? idxBattler : @battle.battlers[idxBattler]
    pkmnSprite = battler.battlerSprite
    if [:create, :show].include?(mode)
      return if battler.effects[PBEffects::Substitute] <= 0
      pkmnSprite.substitute = true
    else
      pkmnSprite.substitute = false
    end
  end
  
  #-----------------------------------------------------------------------------
  # Handles all animations related to the Substitute doll.
  #-----------------------------------------------------------------------------
  def pbAnimateSubstitute(idxBattler, mode, delay = false)
    return if pbInSafari? || !idxBattler || @battle.decision > 0
    battler = (idxBattler.respond_to?("index")) ? idxBattler : @battle.battlers[idxBattler]
    return if battler.semiInvulnerable? || @battle.pbAllFainted?(battler.pbDirectOpposing.index)
    return if battler.effects[PBEffects::Substitute] == 0 && mode != :broken
    pbPauseScene if delay
    case mode
    when :create then substituteAnim = Animation::SubstituteAppear.new(@sprites, @viewport, battler)
    when :show   then substituteAnim = Animation::SubstituteSwapIn.new(@sprites, @viewport, battler)
    when :hide   then substituteAnim = Animation::SubstituteSwapOut.new(@sprites, @viewport, battler)
    when :broken then substituteAnim = Animation::SubstituteSwapOut.new(@sprites, @viewport, battler, true)
    end
    loop do
      substituteAnim.update
      pbUpdate
      break if substituteAnim.animDone?
    end
    substituteAnim.dispose
    pbUpdateSubstituteSprite(battler, mode)
    @sprites["pokemon_#{battler.index}"].visible = true
    pbChangePokemon(battler.index, battler.visiblePokemon)
  end
  
  #-----------------------------------------------------------------------------
  # Rewritten to ensure state of Substitute doll is also updated.
  #-----------------------------------------------------------------------------
  def pbRefreshEverything
    pbCreateBackdropSprites
    @battle.battlers.each_with_index do |battler, i|
      next if !battler
      mode = (battler.effects[PBEffects::Substitute] > 0) ? :show : :hide
      pbUpdateSubstituteSprite(battler.index, mode)
      pbChangePokemon(i, battler.visiblePokemon)
      @sprites["dataBox_#{i}"].initializeDataBoxGraphic(@battle.pbSideSize(i))
      @sprites["dataBox_#{i}"].refresh
    end
  end
end


################################################################################
#
# Substitute doll (triggers)
#
################################################################################

class Battle::Battler
  #-----------------------------------------------------------------------------
  # Aliased for animating the Substitute doll before/after move usage.
  #-----------------------------------------------------------------------------
  alias substitute_pbUseMove pbUseMove
  def pbUseMove(choice, specialUsage = false)
    @battle.scene.pbAnimateSubstitute(self, :hide)
    substitute_pbUseMove(choice, specialUsage)
    @battle.scene.pbAnimateSubstitute(self, :show, true)
  end
  
  #-----------------------------------------------------------------------------
  # Aliased for animating the Substitute doll before/after form changing.
  #-----------------------------------------------------------------------------
  alias substitute_pbChangeForm pbChangeForm
  def pbChangeForm(newForm, msg)
    return if fainted? || @effects[PBEffects::Transform] || @form == newForm
    @battle.scene.pbAnimateSubstitute(self, :hide)
    substitute_pbChangeForm(newForm, msg)
    @battle.scene.pbAnimateSubstitute(self, :show, true)
  end
end

class Battle::Move
  #-----------------------------------------------------------------------------
  # Aliased for animating the Substitute doll upon being broken.
  #-----------------------------------------------------------------------------
  alias substitute_pbHitEffectivenessMessages pbHitEffectivenessMessages
  def pbHitEffectivenessMessages(user, target, numTargets = 1)
    substitute_pbHitEffectivenessMessages(user, target, numTargets)
    if target.damageState.substitute && target.effects[PBEffects::Substitute] == 0
      @battle.scene.pbAnimateSubstitute(target, :broken)
    end
  end
end

class Battle
  #-----------------------------------------------------------------------------
  # Aliased for updating the Substitute doll upon switching out.
  #-----------------------------------------------------------------------------
  alias substitute_pbSendOut pbSendOut
  def pbSendOut(sendOuts, startBattle = false)
    sendOuts.each { |b| @scene.pbUpdateSubstituteSprite(b[0], :hide) }
    substitute_pbSendOut(sendOuts, startBattle)
    sendOuts.each { |b| @scene.pbAnimateSubstitute(b[0], :show) }
  end
end


################################################################################
#
# Substitute doll (moves)
#
################################################################################

#===============================================================================
# Substitute
#-------------------------------------------------------------------------------
# Animates the creation of a Substitute doll.
#-------------------------------------------------------------------------------
class Battle::Move::UserMakeSubstitute < Battle::Move  
  def pbEndOfMoveUsageEffect(user, targets, numHits, switchedBattlers)
    if user.effects[PBEffects::Substitute] > 0
      @battle.scene.pbAnimateSubstitute(user, :create)
    end
  end
end

#===============================================================================
# Shed Tail
#-------------------------------------------------------------------------------
# Animates the creation of a Substitute doll after switching in a new Pokemon.
#-------------------------------------------------------------------------------
class Battle::Move::UserMakeSubstituteSwitchOut < Battle::Move
  alias substitute_pbEndOfMoveUsageEffect pbEndOfMoveUsageEffect
  def pbEndOfMoveUsageEffect(user, targets, numHits, switchedBattlers)
    substitute_pbEndOfMoveUsageEffect(user, targets, numHits, switchedBattlers)
    if user.effects[PBEffects::Substitute] > 0
      @battle.scene.pbAnimateSubstitute(user, :create)
    end
  end
end


################################################################################
#
# Substitute doll (animations)
#
################################################################################

#===============================================================================
# Animation for the creation of a Substitute doll.
#===============================================================================
class Battle::Scene::Animation::SubstituteAppear < Battle::Scene::Animation
  def initialize(sprites, viewport, battler)
    @battler = battler
    @filename = "Graphics/Pokemon/substitute"
    @filename += "_back" if !@battler.opposes?
    super(sprites, viewport)
  end

  def createProcesses
    delay = 0
    batSprite = @battler.battlerSprite
    return if batSprite.substitute
    pos = Battle::Scene.pbBattlerPosition(batSprite.index, batSprite.sideSize)
    offset = (@battler.opposes?) ? Settings::SUBSTITUTE_DOLL_METRICS[1] : Settings::SUBSTITUTE_DOLL_METRICS[0]
    substitute = addNewSprite(pos[0], pos[1] + offset - 128, @filename, PictureOrigin::BOTTOM)
    substitute.setZ(delay, batSprite.z)
    substitute.setOpacity(delay, 0)
    zoom_mult = (@battler.opposes?) ? Settings::FRONT_BATTLER_SPRITE_SCALE : Settings::BACK_BATTLER_SPRITE_SCALE
    substitute.setZoom(delay, zoom_mult * 100)
    shadow = addSprite(@sprites["shadow_#{@battler.index}"], PictureOrigin::CENTER)
    shadow.setVisible(delay, false)
    battler = addSprite(batSprite, PictureOrigin::BOTTOM)
    dir = (@battler.opposes?) ? Graphics.width / 2 : -Graphics.width / 2
    battler.moveDelta(delay, 6, dir, 0)
    battler.setSE(delay, "GUI party switch")
    delay = battler.totalDuration
    substitute.moveDelta(delay, 6, 0, 128)
    substitute.moveOpacity(delay, 6, 255)
    substitute.setSE(delay + 4, "Anim/Substitute")
    delay = substitute.totalDuration
    4.times do |i|
      offset = (i < 2) ? 50 : 20
      offset = -offset if i.even?
      duration = 4 - i
      substitute.moveDelta(delay, duration, 0, offset)
      delay = substitute.totalDuration
    end
  end
end

#===============================================================================
# Animation for a Substitute doll swapping in to replace a battler.
#===============================================================================
class Battle::Scene::Animation::SubstituteSwapIn < Battle::Scene::Animation
  def initialize(sprites, viewport, battler)
    @battler = battler
    @filename = "Graphics/Pokemon/substitute"
    @filename += "_back" if !@battler.opposes?
    super(sprites, viewport)
  end

  def createProcesses
    delay = 0
    batSprite = @battler.battlerSprite
    return if batSprite.substitute
    pos = Battle::Scene.pbBattlerPosition(batSprite.index, batSprite.sideSize)
    offset = (@battler.opposes?) ? Settings::SUBSTITUTE_DOLL_METRICS[1] : Settings::SUBSTITUTE_DOLL_METRICS[0]
    substitute = addNewSprite(pos[0], pos[1] + offset, @filename, PictureOrigin::BOTTOM)
    sprite = @pictureEx.length - 1
    dir = (@battler.opposes?) ? Graphics.width / 2 : -Graphics.width / 2
    substitute.setXY(delay, @pictureSprites[sprite].x + dir, @pictureSprites[sprite].y)
    substitute.setZ(delay, batSprite.z)
    substitute.setVisible(delay, false)
    zoom_mult = (@battler.opposes?) ? Settings::FRONT_BATTLER_SPRITE_SCALE : Settings::BACK_BATTLER_SPRITE_SCALE
    substitute.setZoom(delay, zoom_mult * 100)
    shadow = addSprite(@sprites["shadow_#{@battler.index}"], PictureOrigin::CENTER)
    shadow.setVisible(delay, false)
    battler = addSprite(batSprite, PictureOrigin::BOTTOM)
    battler.moveDelta(delay, 6, dir, 0)
    battler.setSE(delay, "GUI party switch")
    delay = battler.totalDuration
    battler.setVisible(delay, false)
    substitute.setVisible(delay, true)
    substitute.moveDelta(delay, 6, -dir, 0)
  end
end

#===============================================================================
# Animation for a Substitute doll swapping out to be replaced by a battler.
#===============================================================================
class Battle::Scene::Animation::SubstituteSwapOut < Battle::Scene::Animation
  def initialize(sprites, viewport, battler, broken = false)
    @broken = broken
    @battler = battler
    @pkmn = @battler.visiblePokemon
    super(sprites, viewport)
  end

  def createProcesses
    delay = 0
    batSprite = @battler.battlerSprite
    return if !batSprite.substitute
    pos = Battle::Scene.pbBattlerPosition(batSprite.index, batSprite.sideSize)
    pokemon = addPokeSprite(@pkmn, !@battler.opposes?, PictureOrigin::BOTTOM)
    sprite = @pictureEx.length - 1
    @pictureSprites[sprite].x = pos[0]
    @pictureSprites[sprite].y = pos[1]
    metrics_data = GameData::SpeciesMetrics.get_species_form(@pkmn.species, @pkmn.form, @pkmn.female?)
    metrics_data.apply_metrics_to_sprite(@pictureSprites[sprite], batSprite.index)
    dir = (@battler.opposes?) ? Graphics.width / 2 : -Graphics.width / 2
    pokemon.setXY(delay, @pictureSprites[sprite].x + dir, @pictureSprites[sprite].y)
    pokemon.setZ(delay, batSprite.z)
    pokemon.setVisible(delay, false)
    shadow = addSprite(@sprites["shadow_#{@battler.index}"], PictureOrigin::CENTER)
    shadow.setVisible(delay, false)
    battler = addSprite(batSprite, PictureOrigin::BOTTOM)
    if @broken
      battler.moveOpacity(delay, 8, 0)
    else
      battler.moveDelta(delay, 6, dir, 0)
      battler.setSE(delay, "GUI party switch")
    end
    delay = battler.totalDuration
    battler.setVisible(delay, false)
    battler.setOpacity(delay, 255)
    pokemon.setVisible(delay, true)
    pokemon.moveDelta(delay, 6, -dir, 0)
  end
end