#===============================================================================
# Storage Grabber
# By Swdfm
# Used For Storage Utilities
#===============================================================================
class StorageGrabber
  def initialize
    clear
  end
  
  #===============================================================================
  # Adds hovered over pokemon to held pokemon
  #===============================================================================
  def add_to(position, position_1)
    @mons.push([position, position_1])
  end

  #===============================================================================
  # Is the grabber holding a Pokemon?
  #===============================================================================
  def holding_anything?
    return !@mons.empty?
  end
  
  #===============================================================================
  # Sets the pivot (top left Pokemon)
  #===============================================================================
  def setPivot(selection)
    @pivot      = selection
    @mock_pivot = selection
  end
  
  #===============================================================================
  # Begins hovering phase
  #===============================================================================
  def do_with(selection)
    p_col = @pivot % PokemonBox::BOX_WIDTH
    p_row = (@pivot / PokemonBox::BOX_WIDTH).floor
    s_col = selection % PokemonBox::BOX_WIDTH
    s_row = (selection / PokemonBox::BOX_WIDTH).floor
    @mons = []
    f_row = [p_row, s_row].min # F stands for flow
    f_col = [p_col, s_col].min
    @mock_pivot = f_col + f_row * PokemonBox::BOX_WIDTH
    for i in 0...PokemonBox::BOX_WIDTH
      next if (i < p_col && i < s_col) || (i > p_col && i > s_col)
      for j in 0...PokemonBox::BOX_HEIGHT
        next if (j < p_row && j < s_row) || (j > p_row && j > s_row)
        add_to(i - f_col,  j - f_row)
      end
    end
  end
  
  #===============================================================================
  # Is the grabber carrying?
  #===============================================================================
  def carrying
    return @carrying
  end
  
  def carrying=(value)
    @carrying = value
  end
  
  #===============================================================================
  # Adds Pokémon and their positions (relative to top left) to @carried_mons
  #===============================================================================
  def pack_up(storage, box_num)
    ret   = []
    p_col = @mock_pivot % PokemonBox::BOX_WIDTH
    p_row = (@mock_pivot / PokemonBox::BOX_WIDTH).floor
    for i in @mons
      x, y = i
      sel  = (p_row + y) * PokemonBox::BOX_WIDTH + (p_col + x)
      pkmn = storage[box_num, sel]
      ret.push([pkmn, x, y])
    end
    @carried_mons = ret
  end
  
  #===============================================================================
  # Gets storage index of carried mons for deletion
  #===============================================================================
  def get_carried_mons
    ret   = []
    p_col = @mock_pivot % PokemonBox::BOX_WIDTH
    p_row = (@mock_pivot / PokemonBox::BOX_WIDTH).floor
    for i in @carried_mons
      x = i[1] + p_col
      y = i[2] + p_row
      ret.push(y * PokemonBox::BOX_WIDTH + x)
    end
    return ret
  end
  
  #===============================================================================
  # Places mons in those positions
  # STOPS IF THERE IS NOT A SPACE FOR EVERY MON
  #===============================================================================
  def place_with_positions(storage, box_num, selection)
    s_col = selection % PokemonBox::BOX_WIDTH
    s_row = (selection / PokemonBox::BOX_WIDTH).floor
    can_place = true
    for i in @carried_mons
      col = s_col + i[1]
      if col >= PokemonBox::BOX_WIDTH
        can_place = false 
        next
      end
      row = s_row + i[2]
      if row >= PokemonBox::BOX_HEIGHT
        can_place = false
        next
      end
      pseudo_sel = row * PokemonBox::BOX_WIDTH + col
      can_place = false if storage[box_num, pseudo_sel] # Occupied
    end
    return can_place
  end
  
  #===============================================================================
  # Gets index number of mons proposed to be put in boxes in above def.
  #===============================================================================
  def get_new_carried_mons(selection)
    
    ret   = []
    s_col = selection % PokemonBox::BOX_WIDTH
    s_row = (selection / PokemonBox::BOX_WIDTH).floor
    for i in @carried_mons
      col = s_col + i[1]
      row = s_row + i[2]
      pseudo_sel = row * PokemonBox::BOX_WIDTH + col
      ret.push([pseudo_sel, i[0]])
    end
    return ret
  end
  
  #===============================================================================
  # Removes any poured Pokemon
  #===============================================================================
  def pour(count)
    return if count == 0
    to_del = get_new_carried_mons(0)
	to_del = to_del.sort{ |a, b| a[0] <=> b[0] }
	ret = @carried_mons.clone
	count.times do
	  ret.pop
	end
	@carried_mons = ret
  end
  
  #===============================================================================
  # Clears everything
  #===============================================================================
  def clear
    @mons         = []
    @pivot        = nil
    @mock_pivot   = nil
    @carrying     = false
    @carried_mons = []
  end
  
  #===============================================================================
  # Utilities
  #===============================================================================
  def mons
    return @mons
  end
  
  def mock_pivot
    return @mock_pivot
  end
  
  def contains_an_egg?
    for i in @carried_mons
      return true if i[0].egg?
    end
    return false
  end
  
  def carried_mons
    return @carried_mons
  end
end

#===============================================================================
# PokemonStorage override
#===============================================================================
class PokemonStorage
  def swap(one, two)
    t = @boxes[one]
    @boxes[one] = @boxes[two]
    @boxes[two] = t
  end
end

#===============================================================================
# Storage System Utilities
# By Swdfm
# Works For Both Essentials Version 20 and 21
#===============================================================================
# Opciones de configuración en PluginSettings

#===============================================================================
# Using Version 21 or not?
#===============================================================================
def pbVersion21?
  return Essentials::VERSION.include?("21")
end

#===============================================================================
# Nitty Gritty below here!
# Don't touch unless you knwo what you're doing!
#===============================================================================
# PokemonBoxIcon Overrides
#===============================================================================
class PokemonBoxIcon < IconSprite
  #===============================================================================
  # Turns the sprite(s) into a certain colour
  #===============================================================================
  def make_clear
    @type = :Clear
  end
  def make_green
    @type = :Green
  end
  def make_grey
    @type = :Grey
  end
  
  #===============================================================================
  # update Override
  #===============================================================================
  def update
    super
    @type = :Clear if !@type
	return update_21 if pbVersion21?
    @release.update
    do_colours
    dispose if @startRelease && !releasing?
  end
  
  def update_21
    do_colours
    if releasing?
      time_now = System.uptime
      self.zoom_x = lerp(1.0, 0.0, 1.5, @release_timer_start, System.uptime)
      self.zoom_y = self.zoom_x
      self.opacity = lerp(255, 0, 1.5, @release_timer_start, System.uptime)
      if self.opacity == 0
        @release_timer_start = nil
        dispose
      end
    end
  end
  
  def do_colours
    case @type
    when :Clear
      self.color = Color.new(0, 0, 0, 0)
    when :Green
      self.color = Color.new(0, 128, 0, 192)
    when :Grey
      self.color = Color.new(128, 128, 128, 255)
    end
  end
end

#===============================================================================
# PokemonBoxArrow Override
#===============================================================================
class PokemonBoxArrow < Sprite
  attr_accessor :multi
  
  #===============================================================================
  # initialize Add On
  #===============================================================================
  alias swdfm_init initialize
  def initialize(viewport = nil)
    swdfm_init(viewport)
	@path  = STORAGE_ARROW_PATH
	if @path == ""
      @path  = "Graphics/Pictures/Storage/"
      @path  = "Graphics/UI/Storage/" if pbVersion21?
	end
    @multi = false
    @handsprite.addBitmap("point1g", @path + "cursor_point_1_g")
    @handsprite.addBitmap("point2g", @path + "cursor_point_2_g")
    @handsprite.addBitmap("grabg", @path + "cursor_grab_g")
    @handsprite.addBitmap("fistg", @path + "cursor_fist_g")
  end
  
  #===============================================================================
  # update Override (v20)
  #===============================================================================
  def update
    @updating = true
    super
	return update_21 if pbVersion21?
    heldpkmn = heldPokemon
    heldpkmn&.update
    @handsprite.update
    @holding = false if !heldpkmn
    t = @tension
    b = @multi ? "g" : (@quickswap ? "q" : "")
    if @grabbingState > 0
      if @grabbingState <= 4 * Graphics.frame_rate / 20
        @handsprite.changeBitmap("grab" + b)
        self.y = @spriteY + (4.0 * @grabbingState * 20 / Graphics.frame_rate)
        @grabbingState += 1
      elsif @grabbingState <= 8 * Graphics.frame_rate / 20
        @holding = true
        @handsprite.changeBitmap("fist" + b)
        self.y = @spriteY + (4 * ((8 * Graphics.frame_rate / 20) - @grabbingState) * 20 / Graphics.frame_rate)
        @grabbingState += 1
      else
        @grabbingState = 0
      end
    elsif @placingState > 0
      if @placingState <= 4 * Graphics.frame_rate / 20
        @handsprite.changeBitmap("fist" + b)
        self.y = @spriteY + (4.0 * @placingState * 20 / Graphics.frame_rate)
		@placingState += 1
      elsif @placingState <= 8 * Graphics.frame_rate / 20
        @holding = false
        @heldpkmn = nil
        @handsprite.changeBitmap("grab" + b)
        self.y = @spriteY + (4 * ((8 * Graphics.frame_rate / 20) - @placingState) * 20 / Graphics.frame_rate)
		@placingState += 1
	  else
        @placingState = 0
      end
    elsif holding?
      @handsprite.changeBitmap("fist" + b)
    elsif t == :Selecting
      @handsprite.changeBitmap("grab" + b)
    elsif t == :Moving
      @handsprite.changeBitmap("fist" + b)
    else   # Idling
      self.x = @spriteX
      self.y = @spriteY
      if @frame < Graphics.frame_rate / 2
        @handsprite.changeBitmap("point1" + b)
      else
        @handsprite.changeBitmap("point2" + b)
      end
    end
    @frame += 1
    @frame = 0 if @frame >= Graphics.frame_rate
    @updating = false
  end
  
  #===============================================================================
  # update Override (v21)
  #===============================================================================
  def update_21
    heldpkmn = heldPokemon
    heldpkmn&.update
    @handsprite.update
    @holding = false if !heldpkmn
    t = @tension
    b = @multi ? "g" : (@quickswap ? "q" : "")
    if @grabbing_timer_start
      if System.uptime - @grabbing_timer_start <= GRAB_TIME / 2
        @handsprite.changeBitmap("grab" + b)
        self.y = @spriteY + lerp(0, 16, GRAB_TIME / 2, @grabbing_timer_start, System.uptime)
      else
        @holding = true
        @handsprite.changeBitmap("fist" + b)
        delta_y = lerp(16, 0, GRAB_TIME / 2, @grabbing_timer_start + (GRAB_TIME / 2), System.uptime)
        self.y = @spriteY + delta_y
        @grabbing_timer_start = nil if delta_y == 0
      end
    elsif @placing_timer_start
      if System.uptime - @placing_timer_start <= GRAB_TIME / 2
        @handsprite.changeBitmap("fist" + b)
        self.y = @spriteY + lerp(0, 16, GRAB_TIME / 2, @placing_timer_start, System.uptime)
      else
        @holding = false
        @heldpkmn = nil
        @handsprite.changeBitmap("grab" + b)
        delta_y = lerp(16, 0, GRAB_TIME / 2, @placing_timer_start + (GRAB_TIME / 2), System.uptime)
        self.y = @spriteY + delta_y
        @placing_timer_start = nil if delta_y == 0
      end
    elsif holding?
      @handsprite.changeBitmap("fist" + b)
    elsif t == :Selecting
      @handsprite.changeBitmap("grab" + b)
    elsif t == :Moving
      @handsprite.changeBitmap("fist" + b)
    else   # Idling
      self.x = @spriteX
      self.y = @spriteY
      if (System.uptime / 0.5).to_i.even?   # Changes every 0.5 seconds
        @handsprite.changeBitmap("point1" + b)
      else
        @handsprite.changeBitmap("point2" + b)
      end
    end
    @updating = false
  end
  
  #===============================================================================
  # Additional methods: Tension
  # Used For Multiple Grabbing
  #===============================================================================
  def set_tension
    @tension = :Selecting # 1
  end
  
  def start_tension
    @tension = :Moving # 2
  end
  
  def release_tension
    @tension = :None # 0
  end
end

#===============================================================================
# PokemonStorageScene Override
#===============================================================================
class PokemonStorageScene
  attr_reader :multi
  
  #===============================================================================
  # pbStartBox Addition
  #===============================================================================
  alias swdfm_start_box pbStartBox
  def pbStartBox(*args)
    @grabber = StorageGrabber.new
    swdfm_start_box(*args)
  end
  
  #===============================================================================
  # pbSetArrow Addition
  #===============================================================================
  alias swdfm_set_arrow pbSetArrow
  def pbSetArrow(arrow, selection)
    swdfm_set_arrow(arrow, selection)
    return unless selection >= 0
    t = @multi && @grabber.holding_anything? && !@grabber.carrying
    return unless t
    @grabber.do_with(selection)
    do_green
  end
  
  #===============================================================================
  # pbChangeSelection Addition
  #===============================================================================
  alias swdfm_change_sel pbChangeSelection
  def pbChangeSelection(key, selection)
    skip = @multi && @grabber.holding_anything? && !@grabber.carrying
    case key
    when Input::UP
      case selection
      when -1   # Box name
        selection = -2
      when -2   # Party
        selection = PokemonBox::BOX_SIZE - 1 - (PokemonBox::BOX_WIDTH * 2 / 3)   # 25
      when -3   # Close Box
        selection = PokemonBox::BOX_SIZE - (PokemonBox::BOX_WIDTH / 3)   # 28
      else
        selection -= PokemonBox::BOX_WIDTH
		if skip && selection < 0
          selection += PokemonBox::BOX_SIZE
		elsif selection < 0
          selection = -1
        end
      end
    when Input::DOWN
      case selection
      when -1   # Box name
        selection = PokemonBox::BOX_WIDTH / 3   # 2
      when -2   # Party
        selection = -1
      when -3   # Close Box
        selection = -1
      else
        selection += PokemonBox::BOX_WIDTH
        if skip && selection >= PokemonBox::BOX_SIZE
          selection -= PokemonBox::BOX_SIZE
        elsif selection >= PokemonBox::BOX_SIZE
          if selection < PokemonBox::BOX_SIZE + (PokemonBox::BOX_WIDTH / 2)
            selection = -2   # Party
          else
            selection = -3   # Close Box
          end
        end
      end
    when Input::LEFT, Input::RIGHT
      selection = swdfm_change_sel(key, selection)
    end
    return selection
  end
  
  #===============================================================================
  # pbSelectBoxInternal Override
  #===============================================================================
  def pbSelectBoxInternal(_party)
    selection = @selection
    pbSetArrow(@sprites["arrow"], selection)
    pbUpdateOverlay(selection)
    pbSetMosaic(selection)
    loop do
      Graphics.update
      Input.update
      key = -1
      key = Input::DOWN if Input.repeat?(Input::DOWN)
      key = Input::RIGHT if Input.repeat?(Input::RIGHT)
      key = Input::LEFT if Input.repeat?(Input::LEFT)
      key = Input::UP if Input.repeat?(Input::UP)
      if key >= 0
        pbPlayCursorSE
        selection = pbChangeSelection(key, selection)
        pbSetArrow(@sprites["arrow"], selection)
        case selection
        when -4
          nextbox = (@storage.currentBox + @storage.maxBoxes - 1) % @storage.maxBoxes
          pbSwitchBoxToLeft(nextbox)
          @storage.currentBox = nextbox
        when -5
          nextbox = (@storage.currentBox + 1) % @storage.maxBoxes
          pbSwitchBoxToRight(nextbox)
          @storage.currentBox = nextbox
        end
        selection = -1 if [-4, -5].include?(selection)
        pbUpdateOverlay(selection)
        pbSetMosaic(selection)
      end
      self.update
      t = @grabber.holding_anything? && !@grabber.carrying
      if Input.trigger?(Input::JUMPUP) && !t
        pbPlayCursorSE
        nextbox = (@storage.currentBox + @storage.maxBoxes - 1) % @storage.maxBoxes
        pbSwitchBoxToLeft(nextbox)
        @storage.currentBox = nextbox
        pbUpdateOverlay(selection)
        pbSetMosaic(selection)
      elsif Input.trigger?(Input::JUMPDOWN) && !t
        pbPlayCursorSE
        nextbox = (@storage.currentBox + 1) % @storage.maxBoxes
        pbSwitchBoxToRight(nextbox)
        @storage.currentBox = nextbox
        pbUpdateOverlay(selection)
        pbSetMosaic(selection)
      elsif Input.trigger?(Input::SPECIAL) && !t   # Jump to box name
        if selection != -1
          pbPlayCursorSE
          selection = -1
          pbSetArrow(@sprites["arrow"], selection)
          pbUpdateOverlay(selection)
          pbSetMosaic(selection)
        end
      elsif Input.trigger?(Input::ACTION) && @command == 0   # Organize only
        if !t && !@grabber.carrying
          pbPlayDecisionSE
          pbSetQuickSwap(!@quickswap)
        elsif @grabber.carrying && CAN_MASS_RELEASE
          pbMassRelease
        end
      elsif Input.trigger?(Input::BACK)
        @selection = selection
        return nil
      elsif Input.trigger?(Input::USE)
        @selection = selection
        if selection >= 0
          return [@storage.currentBox, selection]
        elsif selection == -1   # Box name
          return [-4, -1]
        elsif selection == -2   # Party Pokémon
          return [-2, -1] if !@multi
        elsif selection == -3   # Close Box
          return [-3, -1]
        end
      end
    end
  end
  
  #===============================================================================
  # pbSelectPartyInternal Override
  #===============================================================================
  def pbSelectPartyInternal(party, depositing)
    selection = @selection
    pbPartySetArrow(@sprites["arrow"], selection)
    pbUpdateOverlay(selection, party)
    pbSetMosaic(selection)
    lastsel = 1
    loop do
      Graphics.update
      Input.update
      key = -1
      key = Input::DOWN if Input.repeat?(Input::DOWN)
      key = Input::RIGHT if Input.repeat?(Input::RIGHT)
      key = Input::LEFT if Input.repeat?(Input::LEFT)
      key = Input::UP if Input.repeat?(Input::UP)
      if key >= 0
        pbPlayCursorSE
        newselection = pbPartyChangeSelection(key, selection)
        case newselection
        when -1
          return -1 if !depositing
        when -2
          selection = lastsel
        else
          selection = newselection
        end
        pbPartySetArrow(@sprites["arrow"], selection)
        lastsel = selection if selection > 0
        pbUpdateOverlay(selection, party)
        pbSetMosaic(selection)
      end
      self.update
      if Input.trigger?(Input::ACTION) && @command == 0   # Organize only
        pbPlayDecisionSE
        pbSetQuickSwap(!@quickswap, true)
      elsif Input.trigger?(Input::BACK)
        @selection = selection
        return -1
      elsif Input.trigger?(Input::USE)
        if selection >= 0 && selection < Settings::MAX_PARTY_SIZE
          @selection = selection
          return selection
        elsif selection == Settings::MAX_PARTY_SIZE   # Close Box
          @selection = selection
          return (depositing) ? -3 : -1
        end
      end
    end
  end
  
  #===============================================================================
  # New Method To Swap Boxes
  #===============================================================================
  def pbSwapBoxes(newbox)
    return if @storage.currentBox == newbox
	@storage.swap(newbox, @storage.currentBox)
	@sprites["box"].update
	refresh_box_sprites
  end
  
  #===============================================================================
  # pbSetQuickSwap Override
  #===============================================================================
  def pbSetQuickSwap(value, ignore_multi = false)
    ignore_multi = true if !CAN_MULTI_SELECT
    # Set to Quickswap
    if !@quickswap && !@multi
      @quickswap = true
      @multi     = false
    elsif @quickswap && !@multi && !ignore_multi
      @quickswap = false
      @multi     = true
    # Set to white
    else
      @quickswap = false
      @multi     = false
    end
    @sprites["arrow"].quickswap = @quickswap
    @sprites["arrow"].multi = @multi
  end
  
  #===============================================================================
  # pbChooseBox
  #===============================================================================
  def pbChooseBox(msg, swapping = false)
    commands = []
    @storage.maxBoxes.times do |i|
      box = @storage[i]
      if box
	    if swapping  && i == @storage.currentBox
          commands.push("No intercambiar")
		  next
		end
		commands.push(_INTL("{1} ({2}/{3})", box.name, box.nitems, box.length))
      end
    end
    return pbShowCommands(msg, commands, @storage.currentBox)
  end
  
  #===============================================================================
  # Additional methods
  #===============================================================================  
  # Tension: Used For Multiple Grabbing
  #===============================================================================
  def grabber
    return @grabber
  end
  
  def set_tension
    @sprites["arrow"].set_tension
  end
  
  def start_tension
    @sprites["arrow"].start_tension
  end
  
  def release_tension
    @sprites["arrow"].release_tension
  end
  
  #===============================================================================
  # Sets all necessary sprites to green
  #===============================================================================
  def do_green
    piv   = @grabber.mock_pivot
    piv_x = piv % PokemonBox::BOX_WIDTH
    piv_y = (piv / PokemonBox::BOX_WIDTH).floor
    sels = []
    for i in @grabber.mons
      x = i[0] + piv_x
      y = i[1] + piv_y
      sel = x + PokemonBox::BOX_WIDTH * y
      sels.push(sel)
    end
    for i in 0...PokemonBox::BOX_SIZE
      boxpokesprite = @sprites["box"].getPokemon(i)
      if sels.include?(i)
        boxpokesprite.make_green
      else
        boxpokesprite.make_clear
      end
    end
  end
  
  #===============================================================================
  # Method to refresh all box sprites
  #===============================================================================
  def refresh_box_sprites
    @sprites["box"].refreshSprites = true
    @sprites["box"].refreshBox = true
    pbHardRefresh
  end
  
  #===============================================================================
  # Changes from wherever the anchor is to the top left of the selection
  #===============================================================================
  def quick_change(selection)
    pbSetArrow(@sprites["arrow"], selection)
    pbUpdateOverlay(selection)
    pbSetMosaic(selection)
    @selection = selection
  end
  
  #===============================================================================
  # Shortcut to mass release
  #===============================================================================
  def pbMassRelease
    @screen.pbMassRelease
  end
  
  #===============================================================================
  # Greys all necessary sprites
  #===============================================================================
  def do_greys(ableProc = nil)
    return if !ableProc
    for i in 0...(PokemonBox::BOX_SIZE + PokemonBox::BOX_WIDTH)
      if i < PokemonBox::BOX_SIZE
        boxpokesprite = @sprites["box"].getPokemon(i)
      else
        boxpokesprite = @sprites["boxparty"].getPokemon(i-30)
      end
      next if !boxpokesprite
      next if !boxpokesprite.getPokemon
      if ableProc.call(boxpokesprite.getPokemon)
        boxpokesprite.make_clear
      else
        boxpokesprite.make_grey
      end
    end
  end
end

#===============================================================================
# PokemonStorageScreen Override
#===============================================================================
class PokemonStorageScreen
  
  #===============================================================================
  # pbBoxCommands Override
  #===============================================================================
  def pbBoxCommands
    c_consts = [:JUMP]
	c_consts.push(:SWAP) if CAN_SWAP_BOXES
	c_consts.push(:WALL, :NAME, :CANCEL)
    commands = [
      _INTL("Saltar")
	]
    commands.push(_INTL("Intercambiar")) if CAN_SWAP_BOXES
    commands.push(
      _INTL("Fondo"),
      _INTL("Nombre"),
      _INTL("Cancelar")
    )
    command = pbShowCommands(_INTL("¿Qué quieres hacer?"), commands)
    case c_consts[command]
    when :JUMP
      destbox = @scene.pbChooseBox(_INTL("¿Saltar a qué Caja?"))
      @scene.pbJumpToBox(destbox) if destbox >= 0
    when :SWAP
      destbox = @scene.pbChooseBox(_INTL("¿Intercambiar con qué Caja?"), true)
      @scene.pbSwapBoxes(destbox) if destbox >= 0
    when :WALL
      papers = @storage.availableWallpapers
      index = 0
      papers[1].length.times do |i|
        if papers[1][i] == @storage[@storage.currentBox].background
          index = i
          break
        end
      end
      wpaper = pbShowCommands(_INTL("Elige el fondo."), papers[0], index)
      @scene.pbChangeBackground(papers[1][wpaper]) if wpaper >= 0
    when :NAME
      @scene.pbBoxName(_INTL("¿Nombre de la Caja?"), 0, 12)
    end
  end
  
  #===============================================================================
  # ***Additional methods***
  #===============================================================================
  def pbHold_Multi(selected)
    box, index = selected
    if box == -1 && pbAble?(@storage[box, index]) && pbAbleCount <= 1
      pbPlayBuzzerSE
      pbDisplay(_INTL("¡Es tu último Pokémon!"))
      return
    end
    for i in @scene.grabber.get_carried_mons
      @storage.pbDelete(box, i)
    end
    index = @scene.grabber.get_carried_mons[0]
    @heldpkmn = @storage[box, index]
    @scene.refresh_box_sprites
    @scene.pbRefresh
  end
  
  def pbPlace_Multi(selected)
    box, index = selected
    for i in @scene.grabber.get_new_carried_mons(index)
      this_index = i[0]
      if @storage[box, this_index]
        raise _INTL("La posición {1}, {2} no está vacía...", box, this_index)
      end
      if box != -1 && this_index >= @storage.maxPokemon(box)
        pbDisplay("No se puede dejar ahí.")
        return
      end
      this_pkmn = i[1]
      if box >= 0 && this_pkmn
        this_pkmn.formTime = nil if this_pkmn.respond_to?("formTime")
        this_pkmn.form     = 0 if this_pkmn.isSpecies?(:SHAYMIN)
        this_pkmn.heal
      end
      @storage[box,this_index] = this_pkmn
      if box==-1
        @storage.party.compact!
      end
    end
    @scene.refresh_box_sprites
    @scene.pbRefresh
    @heldpkmn = nil
  end
  
  #===============================================================================
  # Puts all held Pokemon into available slots in a box
  #===============================================================================
  def pbPour(selected)
    box = @storage.currentBox
	mons_to_place = @scene.grabber.carried_mons.clone
	count = 0
	for i in 0...PokemonBox::BOX_SIZE
	  next if @storage[box, i]
	  m_t_p = mons_to_place.pop
	  @storage[box, i] = m_t_p[0]
	  count += 1
	  break if mons_to_place.empty?
	end
	emptied = mons_to_place.empty?
	@scene.grabber.pour(count)
    @scene.refresh_box_sprites
    @scene.pbRefresh
	@heldpkmn = nil if emptied
	return emptied
  end
  
  #===============================================================================
  # Releases all held Pokemon
  #===============================================================================
  def pbMassRelease
    if @scene.grabber.contains_an_egg?
      pbDisplay(_INTL("¡No puedes liberar un Huevo!"))
      return false
    end
    # NOTE: No need to stop if last mon because this cannot be done in party!
    pbDisplay(_INTL("¡ATENCIÓN! Has elegido la opción de liberar todos los Pokémon elegidos."))
    command = pbShowCommands(_INTL("¿Quieres liberar estos Pokémon?"), [_INTL("No"), _INTL("Sí")])
    return unless command == 1
    command = pbShowCommands(_INTL("¿Estás seguro?"), [_INTL("No"), _INTL("Sí")])
    return unless command == 1
    @scene.grabber.clear
    @scene.pbRefresh
    pbDisplay(_INTL("Los Pokémon han sido liberados."))
    pbDisplay(_INTL("¡Sed libres, Pokémon!"))
    @scene.pbRefresh
    @scene.grabber.carrying = false
    @scene.release_tension
  end
end

