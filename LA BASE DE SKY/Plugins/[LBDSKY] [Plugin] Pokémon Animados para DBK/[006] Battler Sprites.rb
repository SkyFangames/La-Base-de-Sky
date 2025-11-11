################################################################################
#
# Pokemon mosaic sprite mixin.
#
################################################################################
module PokemonSprite::MosaicSprite
  attr_accessor :prepare_mosaic

  INITIAL_MOSAIC = 10

  def initialize_mosaic
    @mosaic = 0
    @prepare_mosaic = false
    @inrefresh = false
    @mosaicbitmap = nil
    @mosaicbitmap2 = nil
    @oldbitmap = self.bitmap
  end

  def dispose_mosaic
    @mosaicbitmap&.dispose
    @mosaicbitmap = nil
    @mosaicbitmap2&.dispose
    @mosaicbitmap2 = nil
  end
  
  def mosaic=(value)
    @mosaic = value
    @mosaic = 0 if @mosaic < 0
    @start_mosaic = @mosaic if !@start_mosaic
  end

  def mosaic_duration=(val)
    @mosaic_duration = val
    @mosaic_duration = 0 if @mosaic_duration < 0
    @mosaic_timer_start = System.uptime if @mosaic_duration > 0
  end
  
  def update_mosaic
    if @mosaic_timer_start
      @start_mosaic = INITIAL_MOSAIC if !@start_mosaic || @start_mosaic == 0
      new_mosaic = lerp(@start_mosaic, 0, @mosaic_duration, @mosaic_timer_start, System.uptime).to_i
      self.mosaic = new_mosaic
      mosaicRefresh(@oldbitmap)
      if new_mosaic == 0
        @mosaic_timer_start = nil
        @start_mosaic = nil
      end
    end
  end

  def mosaicRefresh(bitmap)
    return if @inrefresh || !bitmap
    @inrefresh = true
    @oldbitmap = bitmap
    if @mosaic <= 0 || !@oldbitmap
      @mosaicbitmap&.dispose
      @mosaicbitmap = nil
      @mosaicbitmap2&.dispose
      @mosaicbitmap2 = nil
      self.bitmap = @oldbitmap
    else
      newWidth  = [(@oldbitmap.width / @mosaic), 1].max
      newHeight = [(@oldbitmap.height / @mosaic), 1].max
      @mosaicbitmap2&.dispose
      @mosaicbitmap = pbDoEnsureBitmap(@mosaicbitmap, newWidth, newHeight)
      @mosaicbitmap.clear
      @mosaicbitmap2 = pbDoEnsureBitmap(@mosaicbitmap2, @oldbitmap.width, @oldbitmap.height)
      @mosaicbitmap2.clear
      @mosaicbitmap.stretch_blt(Rect.new(0, 0, newWidth, newHeight), @oldbitmap, @oldbitmap.rect)
      @mosaicbitmap2.stretch_blt(
        Rect.new((-@mosaic / 2) + 1, (-@mosaic / 2) + 1, @mosaicbitmap2.width, @mosaicbitmap2.height),
        @mosaicbitmap, Rect.new(0, 0, newWidth, newHeight)
      )
      self.bitmap = @mosaicbitmap2
    end
    @inrefresh = false
  end
end


################################################################################
#
# Pokemon sprites (Battle)
#
################################################################################
class Battle::Scene::BattlerSprite < RPG::Sprite
  include PokemonSprite::MosaicSprite
  attr_accessor :shadowVisible, :vanishMode, :substitute
  
  #-----------------------------------------------------------------------------
  # Edits to general utilities for shadow sprite and/or mosaic properties.
  #-----------------------------------------------------------------------------
  alias animated_initialize initialize
  def initialize(*args)
    animated_initialize(*args)
    @vanishMode = 0
    initialize_mosaic
  end
  
  def dispose
    super
    dispose_mosaic
  end
  
  def bitmap=(value)
    super
    mosaicRefresh(value)
  end
  
  #-----------------------------------------------------------------------------
  # Animation-related sprite utilities.
  #-----------------------------------------------------------------------------
  def animated?
    return !@_iconBitmap.nil? && @_iconBitmap.is_a?(DeluxeBitmapWrapper)
  end
  
  def static?
    return true if !animated?
    return @_iconBitmap.length <= 1
  end
  
  def finished?
    return true if !animated?
    return @_iconBitmap.finished?
  end
  
  def play
    return if !animated?
    @_iconBitmap.play
    self.bitmap = @_iconBitmap.bitmap
    if shadowSprite
      shadowSprite.iconBitmap.play
      shadowSprite.bitmap = shadowSprite.iconBitmap.bitmap
    end
  end
  
  def deanimate
    return if !animated?
    @_iconBitmap.deanimate
    self.bitmap = @_iconBitmap.bitmap
    if shadowSprite
      shadowSprite.iconBitmap.deanimate
      shadowSprite.bitmap = shadowSprite.iconBitmap.bitmap
    end
  end
  
  def to_first_frame
    return if !animated?
    @_iconBitmap.to_frame(0)
    self.bitmap = @_iconBitmap.bitmap
    if shadowSprite
      shadowSprite.iconBitmap.to_frame(0)
      shadowSprite.bitmap = shadowSprite.iconBitmap.bitmap
    end
  end
  
  def to_last_frame
    return if !animated?
    @_iconBitmap.to_frame("last")
    self.bitmap = @_iconBitmap.bitmap
    if shadowSprite
      shadowSprite.iconBitmap.to_frame("last")
      shadowSprite.bitmap = shadowSprite.iconBitmap.bitmap
    end
  end
  
  def speed
    return (animated?) ? @_iconBitmap.speed : -1
  end
    
  def speed=(value)
    return if !animated?
    @_iconBitmap.update_pokemon_sprite(value)
    self.bitmap = @_iconBitmap.bitmap
    if shadowSprite
      shadowSprite.iconBitmap.update_pokemon_sprite(value)
      shadowSprite.bitmap = shadowSprite.iconBitmap.bitmap
    end
  end
  
  def reversed?
    return false if !animated?
    return @_iconBitmap.reversed
  end
  
  def reversed=(value)
    return if !animated?
    @_iconBitmap.update_pokemon_sprite(nil, value)
    self.bitmap = @_iconBitmap.bitmap
    if shadowSprite
      shadowSprite.iconBitmap.update_pokemon_sprite(nil, value)
      shadowSprite.bitmap = shadowSprite.iconBitmap.bitmap
    end
  end
  
  def hue=(value)
    return if !animated?
    return if @pkmn.super_shiny? && @_iconBitmap.changedHue?
    value = 255 if value > 255
    value = -255 if value < -255
    @_iconBitmap.hue_change(value)
    self.bitmap = @_iconBitmap.bitmap
  end
  
  def iconBitmap; return @_iconBitmap; end
  
  #-----------------------------------------------------------------------------
  # Used to access a battler's shadow sprite, if one exists.
  #-----------------------------------------------------------------------------
  def shadowSprite
    return if !@battler || @battler.fainted?
    return @battler.shadowSprite
  end
  
  def fullRefresh
    self.update
    shadowSprite.update if shadowSprite
  end
  
  #-----------------------------------------------------------------------------
  # Edited to set properties for animated sprite, shadow sprite, or Substitute doll.
  #-----------------------------------------------------------------------------
  def setPokemonBitmap(pkmn, battler, back = false)
    @pkmn = pkmn
    @battler = battler
    @_iconBitmap&.dispose
    if @substitute
      @_iconBitmap = GameData::Species.substitute_sprite_bitmap(back)
      self.bitmap = (@_iconBitmap) ? @_iconBitmap.bitmap : nil
      self.pattern = nil
      self.pattern_type = nil
      @shadowVisible = @index.odd? || Settings::SHOW_PLAYER_SIDE_SHADOW_SPRITES
    else
      @_iconBitmap = GameData::Species.sprite_bitmap_from_pokemon(@pkmn, back)
      @_iconBitmap.setPokemon(@battler, back)
      self.bitmap = (@_iconBitmap) ? @_iconBitmap.bitmap : nil
      self.set_plugin_pattern(@battler)
      @shadowVisible = @pkmn.species_data.shows_shadow?(back)
    end
    pbSetPosition
  end
  
  #-----------------------------------------------------------------------------
  # Edits to utilities related to sprite positioning for setting shadow sprite position.
  #-----------------------------------------------------------------------------
  def pbSetPosition
    return if !@_iconBitmap
    pbSetOrigin
    if @index.even?
      self.z = 50 + (5 * @index / 2)
    else
      self.z = 50 - (5 * (@index + 1) / 2)
    end
    p = Battle::Scene.pbBattlerPosition(@index, @sideSize)
    @spriteX = p[0]
    @spriteY = p[1]
    if @substitute
      side = (@index.even?) ? 0 : 1
      self.y += Settings::SUBSTITUTE_DOLL_METRICS[side]
    elsif PluginManager.installed?("[DBK] Dynamax")
      pbApplyMetricsToSprite
    else
      @pkmn.species_data.apply_metrics_to_sprite(self, @index)
    end
  end

  #-----------------------------------------------------------------------------
  # Rewritten for updating sprite animations and patterns.
  # Turns off sprite bobbing if sprites are animated.
  #-----------------------------------------------------------------------------
  def update
    return if !@_iconBitmap
    @updating = true
    @_iconBitmap.update
    self.bitmap = @_iconBitmap.bitmap
    @spriteYExtra = 0
    if @selected == 1 && COMMAND_BOBBING_DURATION && $PokemonSystem.animated_sprites > 0
      bob_delta = System.uptime % COMMAND_BOBBING_DURATION
      bob_frame = (4 * bob_delta / COMMAND_BOBBING_DURATION).floor
      case bob_frame
      when 1 then @spriteYExtra = 2
      when 3 then @spriteYExtra = -2
      end
    end
    self.x = self.x
    self.y = self.y
    self.visible = @spriteVisible
    if @selected == 2 && @spriteVisible && TARGET_BLINKING_DURATION
      blink_delta = System.uptime % TARGET_BLINKING_DURATION
      blink_frame = (3 * blink_delta / TARGET_BLINKING_DURATION).floor
      self.visible = (blink_frame != 0)
    end
    @updating = false
    self.set_status_pattern(@battler) if !@substitute
    self.update_plugin_pattern
    update_mosaic
  end
end

#===============================================================================
# Shadow sprite for Pokémon (used in battle)
#===============================================================================
class Battle::Scene::BattlerShadowSprite < RPG::Sprite

  alias animated_initialize initialize
  def initialize(*args)
    animated_initialize(*args)
    @substitute = false
    self.color = Color.black
    self.opacity = 100
  end
  
  def opacity=(value)
    super
    if self.opacity > 100
      self.opacity = 100
    end
  end
  
  def iconBitmap; return @_iconBitmap; end
  
  def pbSetPosition
    return if !@_iconBitmap
    pbSetOrigin
    self.z = 3
    p = Battle::Scene.pbBattlerPosition(@index, @sideSize)
    self.x = p[0]
    self.y = p[1] 
    return if @substitute
    self.y -= (self.height / 4).round
    if PluginManager.installed?("[DBK] Dynamax")
      self.y = p[1] - ((self.height * 1.5) / 4).round if @pkmn.dynamax?
      pbApplyMetricsToSprite(true)
    else
      @pkmn.species_data.apply_metrics_to_sprite(self, @index, true)
    end
  end

  def setPokemonBitmap(pkmn, battler_sprite)
    @pkmn = pkmn
    @_iconBitmap&.dispose
    @_iconBitmap = battler_sprite.iconBitmap.clone
    self.bitmap = (@_iconBitmap) ? @_iconBitmap.bitmap : nil
    return if !@_iconBitmap
    @substitute = battler_sprite.substitute
    pbSetPosition
    refresh(battler_sprite)
  end
  
  def refresh(battler_sprite)
    return if battler_sprite.nil? || !@pkmn
    if battler_sprite.shadowVisible
      if battler_sprite.substitute
        shadow_size = 1
      else
        metrics = GameData::SpeciesMetrics.get_species_form(@pkmn.species, @pkmn.form, @pkmn.female?)
        shadow_size = metrics.shadow_size
        shadow_size -= 1 if shadow_size > 0
      end
      shadow_size -= 3 if battler_sprite.vanishMode == 2
      self.zoom_x = battler_sprite.zoom_x + (shadow_size * 0.1)
      self.zoom_y = battler_sprite.zoom_y * 0.25 + (shadow_size * 0.025)
      self.visible = true
    else
      self.visible = false
    end
  end
end


################################################################################
#
# Implements new battler sprites.
#
################################################################################

#===============================================================================
# Battle::Scene
#===============================================================================
class Battle::Scene
  #-----------------------------------------------------------------------------
  # Rewritten to update new Pokemon sprites and shadows.
  #-----------------------------------------------------------------------------
  def pbChangePokemon(idxBattler, pkmn, vanishMode = nil)
    idxBattler = idxBattler.index if idxBattler.respond_to?("index")
    pkmnSprite   = @sprites["pokemon_#{idxBattler}"]
    shadowSprite = @sprites["shadow_#{idxBattler}"]
    back = !@battle.opposes?(idxBattler)
    pkmn = pbGetDynamaxPokemon(idxBattler, pkmn) if PluginManager.installed?("[DBK] Dynamax")
    battler = @battle.battlers[idxBattler]
    pkmnSprite.setPokemonBitmap(pkmn, battler, back)
    shadowSprite.setPokemonBitmap(pkmn, pkmnSprite)
    if pkmnSprite.prepare_mosaic && pkmnSprite.vanishMode == 0
      pkmnSprite.mosaic_duration = 0.50 
      pkmnSprite.prepare_mosaic = false
    end
    return if vanishMode.nil? || pkmnSprite.vanishMode == vanishMode
    pkmnSprite.vanishMode = vanishMode
    case pkmnSprite.vanishMode
    #-----------------------------------------------------------------------------
    when 0 # Pokemon is not vanished off screen.
      pkmnSprite.visible = true
      shadowSprite.refresh(pkmnSprite)
    #-----------------------------------------------------------------------------
    when 1 # Pokemon has vanished completely off screen.
      pkmnSprite.visible = false
      shadowSprite.visible = false
    #-----------------------------------------------------------------------------
    when 2 # Pokemon has vanished off screen high in the air.
      pkmnSprite.visible = false
      shadowSprite.refresh(pkmnSprite)
    end
  end
    
  #-----------------------------------------------------------------------------
  # Aliased to prevent animations for battlers who have vanished off screen.
  #-----------------------------------------------------------------------------
  alias animated_pbAnimationCore pbAnimationCore
  def pbAnimationCore(animation, user, target, oppMove = false)
    return if user && user.battlerSprite.vanishMode > 0
    return if target && target.battlerSprite.vanishMode > 0
    animated_pbAnimationCore(animation, user, target, oppMove)
  end
end

#===============================================================================
# Battle::Battler
#===============================================================================
class Battle::Battler
  #-----------------------------------------------------------------------------
  # Utility for getting a battler's sprite.
  #-----------------------------------------------------------------------------
  def battlerSprite
    return @battle.scene.sprites["pokemon_#{self.index}"]
  end
  
  def shadowSprite
    return @battle.scene.sprites["shadow_#{self.index}"]
  end
  
  #-----------------------------------------------------------------------------
  # Aliased so mosaic is triggered upon a battler changing form.
  #-----------------------------------------------------------------------------
  alias animated_pbChangeForm pbChangeForm
  def pbChangeForm(newForm, msg)
    return if fainted? || @effects[PBEffects::Transform] || @form == newForm
    self.battlerSprite.prepare_mosaic = true
    animated_pbChangeForm(newForm, msg)
  end
  
  #-----------------------------------------------------------------------------
  # Aliased so mosaic is triggered upon a battler losing the Illusion ability.
  #-----------------------------------------------------------------------------
  alias animated_pbOnLosingAbility pbOnLosingAbility
  def pbOnLosingAbility(oldAbil, suppressed = false)
    if oldAbil == :ILLUSION && @effects[PBEffects::Illusion] && !@effects[PBEffects::Transform]
      self.battlerSprite.prepare_mosaic = true
    end
    animated_pbOnLosingAbility(oldAbil, suppressed)
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to properly reset Sky Drop if the move fails.
  #-----------------------------------------------------------------------------
  alias animated_pbCancelMoves pbCancelMoves
  def pbCancelMoves(full_cancel = false)
    tryMove = GameData::Move.try_get(@effects[PBEffects::TwoTurnAttack])
    if tryMove && tryMove.function_code == "TwoTurnAttackInvulnerableInSkyTargetCannotAct"
      self.allOpposing.each do |b|
        next if b.effects[PBEffects::SkyDrop] != @index
        b.effects[PBEffects::SkyDrop] = -1
        @battle.scene.pbChangePokemon(b, b.visiblePokemon, 0)
      end
    end
    animated_pbCancelMoves(full_cancel)
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to refresh the sprites of vanished battlers each turn.
  #-----------------------------------------------------------------------------
  alias animated_pbEndTurn pbEndTurn
  def pbEndTurn(_choice)
    if self.battlerSprite.vanishMode > 0 &&
	   !(semiInvulnerable? || @effects[PBEffects::SkyDrop] >= 0)
      @battle.scene.pbChangePokemon(self, self.visiblePokemon, 0)
    end
    animated_pbEndTurn(_choice)
  end
end


################################################################################
#
# Animation tweaks for abilities and moves.
#
################################################################################

#===============================================================================
# Illusion
#===============================================================================
# Rewritten so that mosaic is triggered upon Illusion ending upon being hit.
#-------------------------------------------------------------------------------
Battle::AbilityEffects::OnBeingHit.add(:ILLUSION,
  proc { |ability, user, target, move, battle|
    next if !target.effects[PBEffects::Illusion]
    battle.scene.pbAnimateSubstitute(target, :hide)
    target.effects[PBEffects::Illusion] = nil
    target.battlerSprite.prepare_mosaic = true
    battle.scene.pbChangePokemon(target, target.pokemon)
    battle.pbDisplay(_INTL("¡La ilusión de {1} desapareció!", target.pbThis(true)))
    battle.pbSetSeen(target)
    battle.scene.pbAnimateSubstitute(target, :show, true)
  }
)

#===============================================================================
# Two-Turn Attacks
#===============================================================================
# Edited to toggle visibility of vanished battlers.
#-------------------------------------------------------------------------------
class Battle::Move::TwoTurnMove < Battle::Move
  def pbShowAnimation(id, user, targets, hitNum = 0, showAnimation = true)
    hitNum = 1 if @chargingTurn && !@damagingTurn
    case @function_code
    #-----------------------------------------------------------------------------
    # These moves completely vanish the user during the charging turn.
    when "TwoTurnAttackInvulnerableUnderground",         # Dig
         "TwoTurnAttackInvulnerableUnderwater",          # Dive
         "TwoTurnAttackInvulnerableRemoveProtections"    # Phantom Force/Shadow Force
      vanishMode = 1
    #-----------------------------------------------------------------------------
    # These moves vanish the user but still casts its shadow during the charging turn.
    when "TwoTurnAttackInvulnerableInSky",               # Fly
         "TwoTurnAttackInvulnerableInSkyParalyzeTarget", # Bounce
         "TwoTurnAttackInvulnerableInSkyTargetCannotAct" # Sky Drop
      vanishMode = 2
    #-----------------------------------------------------------------------------
    # All other two-turn moves do not vanish the user.
    else
      vanishMode = 0
    end
    if vanishMode > 0
	  #-----------------------------------------------------------------------------
	  # Vanishes during the charging turn.
      if hitNum == 1
        @battle.scene.pbChangePokemon(user, user.visiblePokemon, vanishMode)
        if @function_code == "TwoTurnAttackInvulnerableInSkyTargetCannotAct"  # Sky Drop also vanishes the targets.
          targets.each do |b|
          @battle.scene.pbChangePokemon(b, b.visiblePokemon, vanishMode)
        end
          end
      #-----------------------------------------------------------------------------
      # Reappears during the attacking turn.
        else
          @battle.scene.pbChangePokemon(user, user.visiblePokemon, 0)
          if @function_code == "TwoTurnAttackInvulnerableInSkyTargetCannotAct"  # Targets of Sky Drop also reappear.
            targets.each do |b|
            @battle.scene.pbChangePokemon(b, b.visiblePokemon, 0)
          end
        end
      end
    end
    super
  end
end

#===============================================================================
# Sky Drop
#===============================================================================
# Edited to ensure visibility of released targets is restored.
#-------------------------------------------------------------------------------
class Battle::Move::TwoTurnAttackInvulnerableInSkyTargetCannotAct < Battle::Move::TwoTurnMove
  def pbAttackingTurnMessage(user, targets)
    @battle.pbDisplay(_INTL("¡{1} se liberó de Caída Libre!", targets[0].pbThis))
    targets.each do |b|
      next if b.effects[PBEffects::SkyDrop] != user.index
      b.effects[PBEffects::SkyDrop] = -1
      @battle.scene.pbChangePokemon(b, b.visiblePokemon, 0)
    end
  end
end

#===============================================================================
# Smack Down, Thousand Arrows
#===============================================================================
# Edited to ensure visibility of grounded targets is restored.
#-------------------------------------------------------------------------------
class Battle::Move::HitsTargetInSkyGroundsTarget < Battle::Move
  alias animated_pbEffectAfterAllHits pbEffectAfterAllHits
  def pbEffectAfterAllHits(user, target)
    animated_pbEffectAfterAllHits(user, target)
    if target.effects[PBEffects::SmackDown] && target.battlerSprite.vanishMode == 2
      @battle.scene.pbChangePokemon(target, target.visiblePokemon, 0)
    end
  end
end

#===============================================================================
# Gravity
#===============================================================================
# Edited to ensure visibility of grounded targets is restored.
#-------------------------------------------------------------------------------
class Battle::Move::StartGravity < Battle::Move
  alias animated_pbEffectGeneral pbEffectGeneral
  def pbEffectGeneral(user)
    animated_pbEffectGeneral(user)
    @battle.allBattlers.each do |b|
      next if b.battlerSprite.vanishMode != 2
      @battle.scene.pbChangePokemon(b, b.visiblePokemon, 0)
    end
  end
end


################################################################################
#
# Animation fixes for shadow sprites.
#
################################################################################

#===============================================================================
# Utility for handling shadow sprites during switching/capture animations.
#===============================================================================
module Battle::Scene::Animation::BallAnimationMixin
  def shadowAppear(battler, delay, shadow = nil)
    batSprite = battler.battlerSprite
    return if !batSprite.shadowVisible
    if !shadow
      shadow = addSprite(@sprites["shadow_#{battler.index}"], PictureOrigin::CENTER)
      shadow.setVisible(0, false)
    end
    if batSprite.substitute
      shadow_size = 1
    else
      pkmn = batSprite.pkmn
      metrics = GameData::SpeciesMetrics.get_species_form(pkmn.species, pkmn.form, pkmn.female?)
      shadow_size = metrics.shadow_size
      shadow_size -= 1 if shadow_size > 0
    end
    zoomX = 100 * (1 + shadow_size * 0.1)
    zoomY = 100 * (1 * 0.25 + (shadow_size * 0.025))
    shadow.setZoomXY(delay, zoomX, zoomY)
    shadow.setOpacity(delay, 0)
    shadow.setVisible(delay, true)
    shadow.moveOpacity(delay + 5, 10, 100)
  end
end

#===============================================================================
# Rewrites of animations to support animated shadow sprites.
#===============================================================================
# Player send out.
#-------------------------------------------------------------------------------
class Battle::Scene::Animation::PokeballPlayerSendOut < Battle::Scene::Animation
  def createProcesses
    batSprite = @sprites["pokemon_#{@battler.index}"]
    traSprite = @sprites["player_#{@idxTrainer}"]
    poke_ball = (batSprite.pkmn) ? batSprite.pkmn.poke_ball : nil
    col = getBattlerColorFromPokeBall(poke_ball)
    col.alpha = 255
    ballPos = Battle::Scene.pbBattlerPosition(@battler.index, batSprite.sideSize)
    battlerStartX = ballPos[0]
    battlerStartY = ballPos[1]
    battlerEndX = batSprite.x
    battlerEndY = batSprite.y
    ballStartX = -6
    ballStartY = 202
    ballMidX = 0
    ballMidY = battlerStartY - 144
    ball = addBallSprite(ballStartX, ballStartY, poke_ball)
    ball.setZ(0, 25)
    ball.setVisible(0, false)
    if @showingTrainer && traSprite && traSprite.x > 0
      ball.setZ(0, traSprite.z - 1)
      ballStartX, ballStartY = ballTracksHand(ball, traSprite)
    end
    delay = ball.totalDuration
    createBallTrajectory(ball, delay, 12,
                         ballStartX, ballStartY, ballMidX, ballMidY, battlerStartX, battlerStartY - 18)
    ball.setZ(9, batSprite.z - 1)
    delay = ball.totalDuration + 4
    delay += 10 * @idxOrder
    ballOpenUp(ball, delay - 2, poke_ball)
    ballBurst(delay, ball, battlerStartX, battlerStartY - 18, poke_ball)
    ball.moveOpacity(delay + 2, 2, 0)
    battler = addSprite(batSprite, PictureOrigin::BOTTOM)
    battler.setXY(0, battlerStartX, battlerStartY)
    battler.setZoom(0, 0)
    battler.setColor(0, col)
    battlerAppear(battler, delay, battlerEndX, battlerEndY, batSprite, col)
    shadowAppear(@battler, delay)
  end
end

#-------------------------------------------------------------------------------
# Trainer send out.
#-------------------------------------------------------------------------------
class Battle::Scene::Animation::PokeballTrainerSendOut < Battle::Scene::Animation
  def createProcesses
    batSprite = @sprites["pokemon_#{@battler.index}"]
    poke_ball = (batSprite.pkmn) ? batSprite.pkmn.poke_ball : nil
    col = getBattlerColorFromPokeBall(poke_ball)
    col.alpha = 255
    ballPos = Battle::Scene.pbBattlerPosition(@battler.index, batSprite.sideSize)
    battlerStartX = ballPos[0]
    battlerStartY = ballPos[1]
    battlerEndX = batSprite.x
    battlerEndY = batSprite.y
    ball = addBallSprite(0, 0, poke_ball)
    ball.setZ(0, batSprite.z - 1)
    createBallTrajectory(ball, battlerStartX, battlerStartY)
    delay = ball.totalDuration + 6
    delay += 10 if @showingTrainer
    delay += 10 * @idxOrder
    ballOpenUp(ball, delay - 2, poke_ball)
    ballBurst(delay, ball, battlerStartX, battlerStartY - 18, poke_ball)
    ball.moveOpacity(delay + 2, 2, 0)
    battler = addSprite(batSprite, PictureOrigin::BOTTOM)
    battler.setXY(0, battlerStartX, battlerStartY)
    battler.setZoom(0, 0)
    battler.setColor(0, col)
    battlerAppear(battler, delay, battlerEndX, battlerEndY, batSprite, col)
    shadowAppear(@battler, delay)
  end
end

#-------------------------------------------------------------------------------
# Battler recall.
#-------------------------------------------------------------------------------
class Battle::Scene::Animation::BattlerRecall < Battle::Scene::Animation
  def createProcesses
    batSprite = @sprites["pokemon_#{@idxBattler}"]
    shaSprite = @sprites["shadow_#{@idxBattler}"]
    poke_ball = (batSprite.pkmn) ? batSprite.pkmn.poke_ball : nil
    col = getBattlerColorFromPokeBall(poke_ball)
    col.alpha = 0
    ballPos = Battle::Scene.pbBattlerPosition(@idxBattler, batSprite.sideSize)
    battlerEndX = ballPos[0]
    battlerEndY = ballPos[1]
    battler = addSprite(batSprite, PictureOrigin::BOTTOM)
    battler.setVisible(0, true)
    battler.setColor(0, col)
    ball = addBallSprite(battlerEndX, battlerEndY, poke_ball)
    ball.setZ(0, batSprite.z + 1)
    ballOpenUp(ball, 0, poke_ball)
    delay = ball.totalDuration
    ballBurstRecall(delay, ball, battlerEndX, battlerEndY, poke_ball)
    ball.moveOpacity(10, 2, 0)
    battlerAbsorb(battler, delay, battlerEndX, battlerEndY, col)
    if shaSprite.visible
      shadow = addSprite(shaSprite, PictureOrigin::CENTER)
      shadow.setVisible(delay, false)
    end
  end
end

#-------------------------------------------------------------------------------
# Capturing wild Pokemon.
#-------------------------------------------------------------------------------
class Battle::Scene::Animation::PokeballThrowCapture < Battle::Scene::Animation
  def createProcesses
    batSprite = @sprites["pokemon_#{@battler.index}"]
    shaSprite = @sprites["shadow_#{@battler.index}"]
    traSprite = @sprites["player_1"]
    ballPos = Battle::Scene.pbBattlerPosition(@battler.index, batSprite.sideSize)
    battlerStartX = batSprite.x
    battlerStartY = batSprite.y
    ballStartX = -6
    ballStartY = 246
    ballMidX   = 0
    ballMidY   = 78
    ballEndX   = ballPos[0]
    ballEndY   = 112
    ballGroundY = ballPos[1] - 4
    ball = addBallSprite(ballStartX, ballStartY, @poke_ball)
    ball.setZ(0, batSprite.z + 1)
    @ballSpriteIndex = (@success) ? @tempSprites.length - 1 : -1
    if @showingTrainer && traSprite && traSprite.bitmap.width >= traSprite.bitmap.height * 2
      trainer = addSprite(traSprite, PictureOrigin::BOTTOM)
      ballStartX, ballStartY = trainerThrowingFrames(ball, trainer, traSprite)
    end
    delay = ball.totalDuration
    if @critCapture
      ball.setSE(delay, "Battle critical catch throw")
    else
      ball.setSE(delay, "Battle throw")
    end
    createBallTrajectory(ball, delay, 16,
                         ballStartX, ballStartY, ballMidX, ballMidY, ballEndX, ballEndY)
    ball.setZ(9, batSprite.z + 1)
    ball.setSE(delay + 16, "Battle ball hit")
    delay = ball.totalDuration + 6
    ballOpenUp(ball, delay, @poke_ball, true, false)
    battler = addSprite(batSprite, PictureOrigin::BOTTOM)
    delay = ball.totalDuration
    ballBurstCapture(delay, ball, ballEndX, ballEndY, @poke_ball)
    battler.setSE(delay, "Battle jump to ball")
    battler.moveXY(delay, 5, ballEndX, ballEndY)
    battler.moveZoom(delay, 5, 0)
    battler.setVisible(delay + 5, false)
    if @shadowVisible
      shadow = addSprite(shaSprite, PictureOrigin::CENTER)
      shadow.moveOpacity(delay, 5, 0)
      shadow.moveZoom(delay, 5, 0)
      shadow.setVisible(delay + 5, false)
    end
    delay = ball.totalDuration
    ballSetClosed(ball, delay, @poke_ball)
    ball.moveTone(delay, 3, Tone.new(96, 64, -160, 160))
    ball.moveTone(delay + 5, 3, Tone.new(0, 0, 0, 0))
    delay = ball.totalDuration + 3
    if @critCapture
      ball.setSE(delay, "Battle ball shake")
      ball.moveXY(delay, 1, ballEndX + 4, ballEndY)
      ball.moveXY(delay + 1, 2, ballEndX - 4, ballEndY)
      ball.moveXY(delay + 3, 2, ballEndX + 4, ballEndY)
      ball.setSE(delay + 4, "Battle ball shake")
      ball.moveXY(delay + 5, 2, ballEndX - 4, ballEndY)
      ball.moveXY(delay + 7, 1, ballEndX, ballEndY)
      delay = ball.totalDuration + 3
    end
    4.times do |i|
      t = [4, 4, 3, 2][i]
      d = [1, 2, 4, 8][i]
      delay -= t if i == 0
      if i > 0
        ball.setZoomXY(delay, 100 + (5 * (5 - i)), 100 - (5 * (5 - i)))
        ball.moveZoom(delay, 2, 100)
        ball.moveXY(delay, t, ballEndX, ballGroundY - ((ballGroundY - ballEndY) / d))
      end
      ball.moveXY(delay + t, t, ballEndX, ballGroundY)
      ball.setSE(delay + (2 * t), "Battle ball drop", 100 - (i * 7))
      delay = ball.totalDuration
    end
    battler.setXY(ball.totalDuration, ballEndX, ballGroundY)
    delay = ball.totalDuration + 12
    [@numShakes, 3].min.times do |i|
      ball.setSE(delay, "Battle ball shake")
      ball.moveXY(delay, 2, ballEndX - (2 * (4 - i)), ballGroundY)
      ball.moveAngle(delay, 2, 5 * (4 - i))
      ball.moveXY(delay + 2, 4, ballEndX + (2 * (4 - i)), ballGroundY)
      ball.moveAngle(delay + 2, 4, -5 * (4 - i))
      ball.moveXY(delay + 6, 2, ballEndX, ballGroundY)
      ball.moveAngle(delay + 6, 2, 0)
      delay = ball.totalDuration + 8
    end
    if @success
      ballCaptureSuccess(ball, delay, ballEndX, ballGroundY)
    else
      ball.setZ(delay, batSprite.z - 1)
      ballOpenUp(ball, delay, @poke_ball, false)
      ballBurst(delay, ball, ballEndX, ballGroundY, @poke_ball)
      ball.moveOpacity(delay + 2, 2, 0)
      col = getBattlerColorFromPokeBall(@poke_ball)
      col.alpha = 255
      battler.setColor(delay, col)
      battlerAppear(battler, delay, battlerStartX, battlerStartY, batSprite, col)
      shadowAppear(@battler, delay, shadow)
    end
  end
end