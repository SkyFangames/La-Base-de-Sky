#===============================================================================
# Settings.
#===============================================================================
module Settings
  # Definidos en PluginSettings
end


#===============================================================================
# Initializes Battle UI elements.
#===============================================================================
class Battle::Scene
  #-----------------------------------------------------------------------------
  # White text.
  #-----------------------------------------------------------------------------
  BASE_LIGHT     = Color.new(232, 232, 232)
  SHADOW_LIGHT   = Color.new(32, 32, 32)
  #-----------------------------------------------------------------------------
  # Black text.
  #-----------------------------------------------------------------------------
  BASE_DARK      = Color.new(56, 56, 56)
  SHADOW_DARK    = Color.new(184, 184, 184)
  #-----------------------------------------------------------------------------
  # Green text. Used to display bonuses.
  #-----------------------------------------------------------------------------
  BASE_RAISED    = Color.new(50, 205, 50)
  SHADOW_RAISED  = Color.new(9, 121, 105)
  #-----------------------------------------------------------------------------
  # Red text. Used to display penalties.
  #-----------------------------------------------------------------------------
  BASE_LOWERED   = Color.new(248, 72, 72)
  SHADOW_LOWERED = Color.new(136, 48, 48)

  #-----------------------------------------------------------------------------
  # Aliased to initilize UI elements.
  #-----------------------------------------------------------------------------
  alias enhanced_pbInitSprites pbInitSprites
  def pbInitSprites
    enhanced_pbInitSprites
    if !pbInSafari?
      @path = Settings::BATTLE_UI_GRAPHICS_PATH
      @enhancedUIToggle = nil
      @sprites["enhancedUIPrompts"] = EnhancedUIPrompt.new(nil, @battle, COMMAND_BOX, @viewport)
      @sprites["enhancedUI"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
      @sprites["enhancedUI"].z = 300
      @sprites["enhancedUI"].visible = false
      pbSetSmallFont(@sprites["enhancedUI"].bitmap)
      @enhancedUIOverlay = @sprites["enhancedUI"].bitmap
      @sprites["leftarrow"] = AnimatedSprite.new("Graphics/UI/left_arrow", 8, 40, 28, 2, @viewport)
      @sprites["leftarrow"].x = -2
      @sprites["leftarrow"].y = 71
      @sprites["leftarrow"].z = 300
      @sprites["leftarrow"].play
      @sprites["leftarrow"].visible = false
      @sprites["rightarrow"] = AnimatedSprite.new("Graphics/UI/right_arrow", 8, 40, 28, 2, @viewport)
      @sprites["rightarrow"].x = Graphics.width - 38
      @sprites["rightarrow"].y = 71
      @sprites["rightarrow"].z = 300
      @sprites["rightarrow"].play
      @sprites["rightarrow"].visible = false
      @battle.allBattlers.each do |b|
        @sprites["info_icon#{b.index}"] = PokemonIconSprite.new(b.pokemon, @viewport)
        @sprites["info_icon#{b.index}"].setOffset(PictureOrigin::CENTER)
        @sprites["info_icon#{b.index}"].visible = false
        @sprites["info_icon#{b.index}"].z = 300
        pbAddSpriteOutline(["info_icon#{b.index}", @viewport, b.pokemon, PictureOrigin::CENTER])
      end
      ballY = @sprites["messageBox"].y - 58
      5.times do |i|
        case i
        when 0 then ballX = 64
        when 1 then ballX = 146
        when 2 then ballX = 256
        when 3 then ballX = 366
        when 4 then ballX = 448
        end
        @sprites["ball_icon#{i}"] = ItemIconSprite.new(ballX, ballY, nil, @viewport)
        @sprites["ball_icon#{i}"].visible = false
        @sprites["ball_icon#{i}"].z = 300
        pbAddSpriteOutline(["ball_icon#{i}", @viewport, nil, PictureOrigin::CENTER])
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Utility for updating UI elements.
  #-----------------------------------------------------------------------------
  def pbUpdateInfoSprites
    @sprites["leftarrow"].update
    @sprites["rightarrow"].update
    @sprites.each_key do |key|
      next if !key.include?("info_icon")
      next if @sprites[key].disposed?
      @sprites[key].update
    end
  end
  
  #-----------------------------------------------------------------------------
  # Utilities for displaying UI elements.
  #-----------------------------------------------------------------------------
  def pbHideInfoUI
    return if pbInSafari?
    @enhancedUIToggle = nil
    @sprites["enhancedUI"].visible = false
    @enhancedUIOverlay.clear
    @battle.allBattlers.each do |b|
      @sprites["info_icon#{b.index}"].visible = false
    end
    5.times { |i| pbUpdateBallIcon(i, nil, true) }
  end
  
  def pbRefreshUIPrompt(idxBattler = nil, window = nil)
    return if Settings::UI_PROMPT_DISPLAY == 0
    return if !@sprites["enhancedUIPrompts"]
    return if idxBattler && !@battle.pbOwnedByPlayer?(idxBattler)
    @sprites["enhancedUIPrompts"].window = window if window
    @sprites["enhancedUIPrompts"].battler = idxBattler if idxBattler
    if @sprites["enhancedUIPrompts"].round >= @battle.turnCount
      @sprites["enhancedUIPrompts"].x = 0
      @sprites["enhancedUIPrompts"].visible = true
    else
      @sprites["enhancedUIPrompts"].round = @battle.turnCount
      promptAnim = Animation::EnhancedUIPromptAppear.new(@sprites, @viewport)
      loop do
        promptAnim.update
        pbUpdate
        break if promptAnim.animDone?
      end
      promptAnim.dispose
    end
  end
  
  def pbToggleUIPrompt(toggle = false)
    return if pbInSafari?
    if toggle
      return if !@sprites["commandWindow"].visible
      pbRefreshUIPrompt
    else
      return if !@sprites["enhancedUIPrompts"].visible
      promptAnim = Animation::EnhancedUIPromptDisappear.new(@sprites, @viewport)
      loop do
        promptAnim.update
        pbUpdate
        break if promptAnim.animDone?
      end
      promptAnim.dispose
    end
  end

  def pbShowingPrompt?
    return false if pbInSafari?
    return @sprites["enhancedUIPrompts"] && @sprites["enhancedUIPrompts"].visible
  end
  
  def pbHideUIPrompt
    return if !@sprites["enhancedUIPrompts"] || !@sprites["enhancedUIPrompts"].visible
    @sprites["enhancedUIPrompts"].visible = false
    @sprites["enhancedUIPrompts"].x = -164
  end
  
  #-----------------------------------------------------------------------------
  # Aliased for displaying UI prompts.
  #-----------------------------------------------------------------------------
  alias enhanced_pbShowWindow pbShowWindow
  def pbShowWindow(windowType)
    enhanced_pbShowWindow(windowType)
    case windowType
    when MESSAGE_BOX, TARGET_BOX
      pbHideUIPrompt
    when FIGHT_BOX, COMMAND_BOX
      return if @sprites["fightWindow"].visible && @sprites["enhancedUI"].visible
      pbRefreshUIPrompt(nil, windowType)
    end
  end
  
  #-----------------------------------------------------------------------------
  # Aliased for toggling the display of UI elements in the fight menu.
  #-----------------------------------------------------------------------------
  alias enhanced_pbFightMenu_Confirm pbFightMenu_Confirm
  def pbFightMenu_Confirm(*args)
    pbHideInfoUI
    enhanced_pbFightMenu_Confirm(*args)
  end
  
  alias enhanced_pbFightMenu_Cancel pbFightMenu_Cancel
  def pbFightMenu_Cancel(*args)
    pbHideInfoUI
    enhanced_pbFightMenu_Cancel(*args)
  end
  
  alias enhanced_pbFightMenu_Shift pbFightMenu_Shift
  def pbFightMenu_Shift(*args)
    pbHideInfoUI
    enhanced_pbFightMenu_Shift(*args)
  end
  
  alias enhanced_pbFightMenu_Action pbFightMenu_Action
  def pbFightMenu_Action(*args)
    enhanced_pbFightMenu_Action(*args)
    pbUpdateMoveInfoWindow(*args)
  end
  
  alias enhanced_pbFightMenu_Update pbFightMenu_Update
  def pbFightMenu_Update(*args)
    pbUpdateMoveInfoWindow(*args)
  end
  
  alias enhanced_pbFightMenu_Extra pbFightMenu_Extra
  def pbFightMenu_Extra(*args)
    return if pbInSafari?
    if Input.trigger?(Input::JUMPUP)
      pbToggleBattleInfo
    elsif Input.trigger?(Input::JUMPDOWN)
      pbToggleMoveInfo(*args)
    end
  end
  
  alias enhanced_pbFightMenu_End pbFightMenu_End
  def pbFightMenu_End(*args)
    pbHideInfoUI
  end
end

#===============================================================================
# Animations for sliding the UI prompts on screen.
#===============================================================================
class Battle::Scene::Animation::EnhancedUIPromptAppear < Battle::Scene::Animation
  def createProcesses
    return if !@sprites["enhancedUIPrompts"] || @sprites["enhancedUIPrompts"].visible
    prompt = addSprite(@sprites["enhancedUIPrompts"])
    prompt.setVisible(0, true)
    prompt.moveDelta(0, 6, 164, 0)
  end
end

class Battle::Scene::Animation::EnhancedUIPromptDisappear < Battle::Scene::Animation
  def createProcesses
    return if !@sprites["enhancedUIPrompts"] || !@sprites["enhancedUIPrompts"].visible
    prompt = addSprite(@sprites["enhancedUIPrompts"])
    prompt.moveDelta(0, 6, -164, 0)
    prompt.setVisible(6, false)
  end
end

#===============================================================================
# UI prompt object.
#===============================================================================
class Battle::Scene::EnhancedUIPrompt < Sprite
  attr_reader :round, :window, :battler
  
  TEXT_BASE_COLOR   = Color.new(248, 248, 248)
  TEXT_SHADOW_COLOR = Color.new(0, 0, 0)
  
  def initialize(battler, battle, window, viewport = nil)
    super(viewport) 
    offset    = 0
    @round    = -1
    @window   = window
    @battle   = battle
    @battler  = battler
    @bgBitmap = AnimatedBitmap.new(Settings::BATTLE_UI_GRAPHICS_PATH + "menu_prompts")
    @bgSprite = Sprite.new(viewport)
    @bgSprite.bitmap = @bgBitmap.bitmap
    case @window
    when Battle::Scene::FIGHT_BOX
      @bgSprite.src_rect.y = @bgBitmap.height / 2
      @bgSprite.src_rect.height = @bgBitmap.height / 2
      offset = -46 if @battler && @battle.pbCanShift?(@battler)
    else
      @bgSprite.src_rect.y = 0
      if @battle.pbCanUsePokeBall?(@battler)
        @bgSprite.src_rect.height = @bgBitmap.height / 2
      else
        @bgSprite.src_rect.height = 28
        offset = 24
      end
    end
    @contents = Bitmap.new(@bgBitmap.width, @bgBitmap.height / 2)
    self.bitmap = @contents
    pbSetSmallFont(self.bitmap)
    self.x       = -164
    self.y       = 236 + offset
    self.z       = 120
    self.visible = false
  end

  def dispose
    @bgSprite.dispose
    @bgBitmap.dispose
    super
  end

  def x=(value)
    super
    @bgSprite.x = value
  end

  def y=(value)
    super
    @bgSprite.y = value
  end

  def z=(value)
    super
    @bgSprite.z = value - 1
  end

  def opacity=(value)
    super
    @bgSprite.opacity = value
  end

  def visible=(value)
    super
    @bgSprite.visible = value
  end

  def color=(value)
    super
    @bgSprite.color = value
  end
  
  def round=(value)
    @round = value
  end

  def window=(value)
    @window = value
    refresh
  end
  
  def battler=(value)
    @battler = value
    refresh
  end

  def refresh
    return if !@battler
    offset = 0
    textPos = [
      #[_INTL(": A"), 68, 7,  :left, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR, :outline],
      #[_INTL(": S"), 68, 31, :left, TEXT_BASE_COLOR, TEXT_SHADOW_COLOR, :outline]
    ]
    case @window
    when Battle::Scene::FIGHT_BOX
      @bgSprite.src_rect.y = @bgBitmap.height / 2
      @bgSprite.src_rect.height = @bgBitmap.height / 2
      offset = -46 if @battle.pbCanShift?(@battler)
    else
      @bgSprite.src_rect.y = 0
      if @battle.pbCanUsePokeBall?(@battler)
        @bgSprite.src_rect.height = @bgBitmap.height / 2
      else
        @bgSprite.src_rect.height = 28
        textPos.delete_at(1)
        offset = 24
      end
    end
    self.y = 236 + offset
    self.bitmap.clear
    pbDrawTextPositions(self.bitmap, textPos)
  end

  def update
    super
    @bgSprite.update
  end
end

#===============================================================================
# Allows the display of correct move category for moves that change their category.
#===============================================================================
class Battle::Move
  attr_accessor :calcCategory
end