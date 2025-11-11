#===============================================================================
# Clase que crea la lista desplegable de nombres de misiones
#===============================================================================
class Window_Quest < Window_DrawableCommand

  def initialize(x,y,width,height,viewport)
    @quests = []
    super(x,y,width,height,viewport)
    self.windowskin = nil
    @selarrow = AnimatedBitmap.new("Graphics/UI/sel_arrow")
    RPG::Cache.retain("Graphics/UI/sel_arrow")
  end

  def quests=(value)
    @quests = value
    refresh
  end

  def itemCount
    return @quests.length
  end

  def drawItem(index,_count,rect)
    return if index>=self.top_row+self.page_item_max
    rect = Rect.new(rect.x+16,rect.y,rect.width-16,rect.height)
    name = $quest_data.getName(@quests[index].id)
    name = "<b>" + "#{name}" + "</b>" if @quests[index].story
    base = self.baseColor
    shadow = self.shadowColor
    col = @quests[index].color
    drawFormattedTextEx(self.contents,rect.x,rect.y+2,
      436,"<c2=#{col}>#{name}</c2>",base,shadow)
    pbDrawImagePositions(self.contents,[[sprintf("Graphics/UI/QuestUI/new"),rect.width-16,rect.y+4]]) if @quests[index].new
  end

  def refresh
    @item_max = itemCount
    dwidth  = self.width-self.borderX
    dheight = self.height-self.borderY
    self.contents = pbDoEnsureBitmap(self.contents,dwidth,dheight)
    self.contents.clear
    for i in 0...@item_max
      next if i<self.top_item || i>self.top_item+self.page_item_max
      drawItem(i,@item_max,itemRect(i))
    end
    drawCursor(self.index,itemRect(self.index)) if itemCount >0
  end

  def update
    super
    @uparrow.visible   = false
    @downarrow.visible = false
  end
end

#===============================================================================
# Clase que controla la interfaz de usuario
#===============================================================================
class QuestList_Scene

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @base = Color.new(80,80,88)
    @shadow = Color.new(160,160,168)
    addBackgroundPlane(@sprites,"bg","QuestUI/bg_1",@viewport)
    @sprites["base"] = IconSprite.new(0,0,@viewport)
    @sprites["base"].setBitmap("Graphics/UI/QuestUI/bg_2")
    @sprites["page_icon1"] = IconSprite.new(0,4,@viewport)
    if SHOW_FAILED_QUESTS
      @sprites["page_icon1"].setBitmap("Graphics/UI/QuestUI/page_icon1a")
    else
      @sprites["page_icon1"].setBitmap("Graphics/UI/QuestUI/page_icon1b")
    end
    @sprites["page_icon1"].x = Graphics.width - @sprites["page_icon1"].bitmap.width - 10
    @sprites["page_icon2"] = IconSprite.new(0,4,@viewport)
    @sprites["page_icon2"].setBitmap("Graphics/UI/QuestUI/page_icon2")
    @sprites["page_icon2"].x = Graphics.width - @sprites["page_icon2"].bitmap.width - 10
    @sprites["page_icon2"].opacity = 0
    @sprites["pageIcon"] = IconSprite.new(@sprites["page_icon1"].x,4,@viewport)
    @sprites["pageIcon"].setBitmap("Graphics/UI/QuestUI/pageIcon")
    @quests = [
      $PokemonGlobal.quests.active_quests,
      $PokemonGlobal.quests.completed_quests
    ]
    @quests_text = ["activas", "completadas"]
    if SHOW_FAILED_QUESTS
      @quests.push($PokemonGlobal.quests.failed_quests)
      @quests_text.push("fallidas")
    end
	###
	if SORT_STORY
	  @quests.each do |s|
	    s.sort_by! {|x| [x.story ? 0 : 1, x.time]}
	  end
  elsif SORT_ID
    @quests.each do |s|
	    s.sort_by! {|x| x.id}
    end
  end
	###
    @current_quest = 0
    @sprites["itemlist"] = Window_Quest.new(10,36,Graphics.width-22,Graphics.height-80,@viewport)
    @sprites["itemlist"].index = 0
    @sprites["itemlist"].baseColor = @base
    @sprites["itemlist"].shadowColor = @shadow
    @sprites["itemlist"].quests = @quests[@current_quest]
    @sprites["overlay1"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    pbSetSystemFont(@sprites["overlay1"].bitmap)
    @sprites["overlay2"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    @sprites["overlay2"].opacity = 0
    pbSetSystemFont(@sprites["overlay2"].bitmap)
    @sprites["overlay3"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    @sprites["overlay3"].opacity = 0
    pbSetSystemFont(@sprites["overlay3"].bitmap)
    @sprites["overlay_control"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    pbSetSystemFont(@sprites["overlay_control"].bitmap)
    pbDrawTextPositions(@sprites["overlay1"].bitmap,[
      [_INTL("Misiones {1}", @quests_text[@current_quest]),6,6,0,Color.new(248,248,248),Color.new(0,0,0),true]
    ])

    pbDrawImagePositions(@sprites["overlay_control"].bitmap,[
      [sprintf("Graphics/UI/QuestUI/arrows"),24,298]
    ])
    drawFormattedTextEx(@sprites["overlay_control"].bitmap,170,304,
      436,"Navegar",@base,@shadow)
    pbDrawImagePositions(@sprites["overlay_control"].bitmap,[
      [sprintf("Graphics/UI/QuestUI/as"),24,334]
    ])
    drawFormattedTextEx(@sprites["overlay_control"].bitmap,100,344,
       436,"Subir/Bajar",@base,@shadow)
    drawFormattedTextEx(@sprites["overlay_control"].bitmap,326,304,
       436,"<c2=#{colorQuest("rojo")}>Nueva tarea:</c2>",@base,@shadow)
    pbDrawImagePositions(@sprites["overlay_control"].bitmap,[
      [sprintf("Graphics/UI/QuestUI/new"),460,298]
    ])
    @sprites["ow"] = IconSprite.new(70,102,@viewport)
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbScene
    @sprites["base"].setBitmap("Graphics/UI/QuestUI/bg_2")
    loop do
      selected = @sprites["itemlist"].index
      @sprites["itemlist"].active = true
      dorefresh = false
      Graphics.update

      Input.update
      pbUpdate
      if Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::USE)
        if @quests[@current_quest].length==0
          pbPlayBuzzerSE
        else
          pbPlayDecisionSE
          fadeContent
          @sprites["itemlist"].active = false
          pbQuest(@quests[@current_quest][selected])
          showContent
        end
      elsif Input.trigger?(Input::RIGHT)
        pbPlayCursorSE
        @current_quest +=1; @current_quest = 0 if @current_quest > @quests.length-1
        dorefresh = true
      elsif Input.trigger?(Input::LEFT)
        pbPlayCursorSE
        @current_quest -=1; @current_quest = @quests.length-1 if @current_quest < 0
        dorefresh = true
      end
      swapQuestType if dorefresh
    end
  end

  def swapQuestType
    @sprites["overlay1"].bitmap.clear
    @sprites["base"].setBitmap("Graphics/UI/QuestUI/bg_2")
    @sprites["itemlist"].index = 0 # Reinicia la posición del cursor
    @sprites["itemlist"].quests = @quests[@current_quest]
    @sprites["pageIcon"].x = @sprites["page_icon1"].x + 32*@current_quest
    pbDrawTextPositions(@sprites["overlay1"].bitmap,[
      [_INTL("Misiones {1}", @quests_text[@current_quest]),6,6,0,Color.new(248,248,248),Color.new(0,0,0),true]
    ])
  end

  def fadeContent
    @sprites["base"].setBitmap("Graphics/UI/QuestUI/bg_2")
    @sprites["ow"].visible = false
    15.times do
      Graphics.update
      @sprites["itemlist"].contents_opacity -= 17
      @sprites["overlay1"].opacity -= 17; @sprites["overlay_control"].opacity -= 17
      @sprites["page_icon1"].opacity -= 17; @sprites["pageIcon"].opacity -= 17
    end
  end

  def showContent
    @sprites["base"].setBitmap("Graphics/UI/QuestUI/bg_2")
    @sprites["ow"].visible = false
    15.times do
      Graphics.update
      @sprites["itemlist"].contents_opacity += 17
      @sprites["overlay1"].opacity += 17; @sprites["overlay_control"].opacity += 17
      @sprites["page_icon1"].opacity += 17; @sprites["pageIcon"].opacity += 17
    end
  end

  def pbQuest(quest)
    @sprites["base"].setBitmap("Graphics/UI/QuestUI/bg_3")
    quest.new = false
    drawQuestDesc(quest)
    15.times do
      Graphics.update
      @sprites["overlay2"].opacity += 17; @sprites["overlay3"].opacity += 17; @sprites["page_icon2"].opacity += 17
    end
    page = 1
    loop do
      Graphics.update
      Input.update
      pbUpdate
      showOtherInfo = false
      if Input.trigger?(Input::RIGHT) && page==1
        pbPlayCursorSE
        page += 1
        @sprites["page_icon2"].mirror = true
        drawOtherInfo(quest)
      elsif Input.trigger?(Input::LEFT) && page==2
        pbPlayCursorSE
        page -= 1
        @sprites["page_icon2"].mirror = false
        drawQuestDesc(quest)
      elsif Input.trigger?(Input::BACK)
        pbPlayCloseMenuSE
        break
      end
    end
    15.times do
      Graphics.update
      @sprites["overlay2"].opacity -= 17; @sprites["overlay3"].opacity -= 17; @sprites["page_icon2"].opacity -= 17
    end
    @sprites["page_icon2"].mirror = false
    @sprites["itemlist"].refresh
  end

  def drawQuestDesc(quest)
    @sprites["overlay2"].bitmap.clear; @sprites["overlay3"].bitmap.clear
    # Nombre de la misión
    questName = $quest_data.getName(quest.id)
    pbDrawTextPositions(@sprites["overlay2"].bitmap,[
      ["#{questName}",6,6,0,Color.new(248,248,248),Color.new(0,0,0),true]
    ])
    # Descripción de la misión
    questDesc = "<c2=#{colorQuest("azul")}>Descripción:</c2> #{$quest_data.getQuestDescription(quest.id)}"
    drawFormattedTextEx(@sprites["overlay3"].bitmap,178,62,
      312,questDesc,@base,@shadow)
    # Descripción de la etapa
    questStageDesc = $quest_data.getStageDescription(quest.id,quest.stage)
    drawFormattedTextEx(@sprites["overlay3"].bitmap,24,250,
      436,"Etapa #{quest.stage}/#{$quest_data.getMaxStagesForQuest(quest.id)}",@base,@shadow)
    drawFormattedTextEx(@sprites["overlay3"].bitmap,24,304,
      436,"<c2=#{colorQuest("naranja")}>Tarea:</c2> #{questStageDesc}",@base,@shadow)
    # Gráfico del personaje que otrorga la misión
    owname = sprintf("#{$quest_data.getQuestGiverOW(quest.id)}")
    if owname=="nil" || owname==""
      owname = sprintf("Graphics/UI/QuestUI/000")
    end
    @sprites["ow"].setBitmap(owname)
    charwidth  = @sprites["ow"].bitmap.width
    charheight = @sprites["ow"].bitmap.height
    @sprites["ow"].x = 82 - (charwidth / 8)
    @sprites["ow"].y = 146 - (charheight / 8)
    @sprites["ow"].src_rect = Rect.new(0, 0, charwidth / 4, charheight / 4)
    @sprites["ow"].visible = true
  end

  def drawOtherInfo(quest)
    @sprites["overlay3"].bitmap.clear
    # Guest giver
    questGiver = $quest_data.getQuestGiver(quest.id)
    # Si es nulo 'nil' o falta, se configura como '???'
    if questGiver=="nil" || questGiver==""
      questGiver = "???"
    end
    # Número total de estapas de la misión
    questLength = $quest_data.getMaxStagesForQuest(quest.id)
    # La misión del mapa se inició originalmente
    originalMap = quest.location
    # Formato del temporizador
    time = quest.time.strftime("%H:%M del %d/%m/%Y")
    if getActiveQuests.include?(quest.id)
      time_text = "iniciada"
    elsif getCompletedQuests.include?(quest.id)
      time_text = "completada"
    else
      time_text = "fallida"
    end
    # Recompensa de la misión
    questReward = $quest_data.getQuestReward(quest.id)
	active_quests = getActiveQuests
    if questReward=="nil" || questReward=="" || active_quests.include?(quest.id)
      questReward = "???"
    end
    # Localización de la etapa
    questStageLocation = $quest_data.getStageLocation(quest.id,quest.stage)
    # Si es nulo 'nil' o falta, no aparece
    if questStageLocation=="nil" || questStageLocation==""
      questStageLocation = "???"
    end
    
    if TIME_VISIBLE
      textpos = [
        [sprintf("Etapa %d/%d",quest.stage,questLength),24,248,0,@base,@shadow],
        ["#{questGiver}",178,90,0,@base,@shadow],
        ["#{originalMap}",178,162,0,@base,@shadow],
        ["#{time}",178,234,0,@base,@shadow]
      ]
    else
      textpos = [
        [sprintf("Etapa %d/%d",quest.stage,questLength),24,248,0,@base,@shadow],
        ["#{questGiver}",178,90,0,@base,@shadow],
        ["#{originalMap}",178,162,0,@base,@shadow]
      ]
    end
    
    drawFormattedTextEx(@sprites["overlay3"].bitmap,178,60,
      312,"<c2=#{colorQuest("cian")}>Misión entregada por:</c2>",@base,@shadow)
    drawFormattedTextEx(@sprites["overlay3"].bitmap,178,132,
      312,"<c2=#{colorQuest("magenta")}>Misión descubierta en:</c2>",@base,@shadow)
    if TIME_VISIBLE
      drawFormattedTextEx(@sprites["overlay3"].bitmap,178,204,
        312,"<c2=#{colorQuest("verde")}>Misión #{time_text} a las:</c2>",@base,@shadow)
    end
    drawFormattedTextEx(@sprites["overlay3"].bitmap,24,304,  #Lugar
      436,"<c2=#{colorQuest("morado")}>Lugar:</c2> #{questStageLocation}",@base,@shadow)
    drawFormattedTextEx(@sprites["overlay3"].bitmap,24,344, #Recompensa
      436,"<c2=#{colorQuest("rojo")}>Recompensa:</c2> #{questReward}",@base,@shadow)
    pbDrawTextPositions(@sprites["overlay3"].bitmap,textpos)
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

#===============================================================================
# Clase para llamar a la interfaz de usuario
#===============================================================================
class QuestList_Screen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen
    @scene.pbStartScene
    @scene.pbScene
    @scene.pbEndScene
  end
end

# Método de utilidad para llamar a la interfaz de usuario
def pbViewQuests
  scene = QuestList_Scene.new
  screen = QuestList_Screen.new(scene)
  screen.pbStartScreen
end

#===============================================================================
# Añadido para acceder a la interfaz de usuario desde el menú de pausa
#===============================================================================

if PAUSE_MENU
  MenuHandlers.add(:pause_menu, :quests, {
    "name"      => _INTL("Misiones"),
    "order"     => 81, # 81 será justo arriba del boton de salir, en el menú normal de la base
    "condition" => proc { next hasAnyQuests? },
    "effect"    => proc { |menu|
      menu.pbHideMenu
      pbViewQuests
      menu.pbRefresh
      menu.pbShowMenu
      next false
    }
  })
end
# Para que se acceda desde el menú del pokegear se debe reemplazar :pause_menu por :pokegear_menu
# y reemplazar el order con la posición que se desee.

#===============================================================================
# Añadido para acceder a la interfaz de usuario desde un objeto clave
#===============================================================================

if KEY_ITEM
  ItemHandlers::UseFromBag.add(:MISIONGUIDE, proc { |item|
    pbViewQuests
    next 1
  })

  ItemHandlers::UseInField.add(:MISIONGUIDE, proc { |item|
    pbViewQuests
    next true
  })
end
# Para añadir el objeto clave se debe añadir el siguiente texto en items.txt
#-------------------------------
# [MISIONGUIDE]
# Name = Libro de Misiones
# NamePlural = Libro de Misiones
# Pocket = 8
# Price = 0
# FieldUse = Direct
# Flags = KeyItem
# Description = Cuaderno que almacena todas las misiones vistas hasta el momento.
#-------------------------------