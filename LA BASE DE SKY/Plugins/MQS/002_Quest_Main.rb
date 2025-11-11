#===============================================================================
# Esta clase contiene la información para una misión individual.
#===============================================================================
class Quest
  attr_accessor :id
  attr_accessor :stage
  attr_accessor :time
  attr_accessor :location
  attr_accessor :new
  attr_accessor :color
  attr_accessor :story

  def initialize(id,color,story)
    self.id       = id
    self.stage    = 1
    self.time     = Time.now
    self.location = $game_map.name
    self.new      = true
    self.color    = color
    self.story    = story
  end

  def stage=(value)
    if value > $quest_data.getMaxStagesForQuest(self.id)
      value = $quest_data.getMaxStagesForQuest(self.id)
    end
    @stage = value
  end
end

#===============================================================================
# Esta clase contiene todas las misiones de los entrenadores.
#===============================================================================
class Player_Quests
  attr_accessor :active_quests
  attr_accessor :completed_quests
  attr_accessor :failed_quests
  attr_accessor :selected_quest_id

  def initialize
    @active_quests     = []
    @completed_quests  = []
    @failed_quests     = []
    @selected_quest_id = 0
  end

  # questID debe ser el nombre simbólico de la misión, por ejemplo ':Mision1'
  def activateQuest(quest,color,story)
    if !quest.is_a?(Symbol)
      raise _INTL("El argumento 'quest' debe ser un de la clase 'symbol', por ejemplo ':Mision1'.")
    end
    for i in 0...@active_quests.length
      if @active_quests[i].id == quest
        pbMessage("Ya has comenzado esta misión.")
        return
      end
    end
    for i in 0...@completed_quests.length
      if @completed_quests[i].id == quest
        pbMessage("Ya has completado esta misión.")
        return
      end
    end
    for i in 0...@failed_quests.length
      if @failed_quests[i].id == quest
        pbMessage("Ya has fallado en esta misión.")
        return
      end
    end
    @active_quests.push(Quest.new(quest,color,story))
    pbMessage(_INTL("\\se[{1}]<ac><c2=#{colorQuest("rojo")}>¡Nueva misión descubierta!</c2>\n¡Consulta tu registro de misiones para obtener más detalles!</ac>",QUEST_JINGLE))
  end

  def failQuest(quest,color,story)
    if !quest.is_a?(Symbol)
      raise _INTL("El argumento 'quest' debe ser un de la clase 'symbol', por ejemplo ':Mision1'.")
    end
    found = false
    for i in 0...@completed_quests.length
      if @completed_quests[i].id == quest
        pbMessage("Ya has completado esta misión.")
        return
      end
    end
    for i in 0...@failed_quests.length
      if @failed_quests[i].id == quest
        pbMessage("Ya has fallado en esta misión.")
        return
      end
    end
    for i in 0...@active_quests.length
      if @active_quests[i].id == quest
        temp_quest = @active_quests[i]
        temp_quest.color = color if color != nil
        temp_quest.new = true # Establecer esto en verdadero hace que el icono "!" aparezca cuando se actualiza la misión.
        temp_quest.time = Time.now
        @failed_quests.push(temp_quest)
        @active_quests.delete_at(i)
        found = true
        pbMessage(_INTL("\\se[{1}]<ac><c2=#{colorQuest("rojo")}>¡Misión fallida!</c2>\n¡Tu registro de misiones ha sido actualizado!</ac>",QUEST_FAIL))
        break
      end
    end
    if !found
      color = colorQuest(nil) if color == nil
      @failed_quests.push(Quest.new(quest,color,story))
    end
  end

  def completeQuest(quest,color,story)
    if !quest.is_a?(Symbol)
      raise _INTL("El argumento 'quest' debe ser un de la clase 'symbol', por ejemplo ':Mision1'.")
    end
    found = false
    for i in 0...@completed_quests.length
      if @completed_quests[i].id == quest
        pbMessage("Ya has completado esta misión.")
        return
      end
    end
    for i in 0...@failed_quests.length
      if @failed_quests[i].id == quest
        pbMessage("Ya has fallado en esta misión.")
        return
      end
    end
    for i in 0...@active_quests.length
      if @active_quests[i].id == quest
        temp_quest = @active_quests[i]
        temp_quest.color = color if color != nil
        temp_quest.new = true # Establecer esto en verdadero hace que el icono "!" aparezca cuando se actualiza la misión.
        temp_quest.time = Time.now
        @completed_quests.push(temp_quest)
        @active_quests.delete_at(i)
        found = true
        pbMessage(_INTL("\\se[{1}]<ac><c2=#{colorQuest("rojo")}>¡Misión completada!</c2>\n¡Tu registro de misiones ha sido actualizado!</ac>",QUEST_DONE))
        break
      end
    end
    if !found
      color = colorQuest(nil) if color == nil
      @completed_quests.push(Quest.new(quest,color,story))
    end
  end

  def advanceQuestToStage(quest,stageNum,color,story)
    if !quest.is_a?(Symbol)
      raise _INTL("El argumento 'quest' debe ser un de la clase 'symbol', por ejemplo ':Mision1'.")
    end
    found = false
    for i in 0...@active_quests.length
      if @active_quests[i].id == quest
        @active_quests[i].stage = stageNum
        @active_quests[i].color = color if color != nil
        @active_quests[i].new = true # Establecer esto en verdadero hace que el icono "!" aparezca cuando se actualiza la misión.
        found = true
        pbMessage(_INTL("\\se[{1}]<ac><c2=#{colorQuest("rojo")}>¡Nueva tarea agregada!</c2>\n¡Tu registro de misiones ha sido actualizado!</ac>",QUEST_JINGLE))
      end
      return if found
    end
    if !found
      color = colorQuest(nil) if color == nil
      questNew = Quest.new(quest,color,story)
      questNew.stage = stageNum
      @active_quests.push(questNew)
    end
  end
end

#===============================================================================
# Iniciar datos de misión
#===============================================================================
class PokemonGlobalMetadata
#  attr_writer :quests

  def quests
    @quests = Player_Quests.new if !@quests
    return @quests
  end

  alias quest_init initialize
  def initialize
    quest_init
    @quests = Player_Quests.new
  end
end

#===============================================================================
# Funciones de ayuda y utilidad para gestionar misiones
#===============================================================================

# Función de ayuda para activar misiones
def activateQuest(quest,color=colorQuest(nil),story=false)
  return if !$PokemonGlobal
  $PokemonGlobal.quests.activateQuest(quest,color,story)
end

# Función de ayuda para marcar misiones como completadas
def completeQuest(quest,color=nil,story=false)
  return if !$PokemonGlobal
  $PokemonGlobal.quests.completeQuest(quest,color,story)
end

# Función de ayuda para marcar misiones como fallidas
def failQuest(quest,color=nil,story=false)
  return if !$PokemonGlobal
  $PokemonGlobal.quests.failQuest(quest,color,story)
end

# Función de ayuda para avanzar en misiones a una etapa determinada
def advanceQuestToStage(quest,stageNum,color=nil,story=false)
  return if !$PokemonGlobal
  $PokemonGlobal.quests.advanceQuestToStage(quest,stageNum,color,story)
end

# Función para obtener nombres simbólicos de misiones activas.
# Sin uso
def getActiveQuests
  active = []
  $PokemonGlobal.quests.active_quests.each do |s|
    active.push(s.id)
  end
  return active
end

# Función para obtener nombres simbólicos de misiones completadas.
# Sin uso
def getCompletedQuests
  completed = []
  $PokemonGlobal.quests.completed_quests.each do |s|
    completed.push(s.id)
  end
  return completed
end

# Función para obtener nombres simbólicos de misiones fallidas.
# Sin uso
def getFailedQuests
  failed = []
  $PokemonGlobal.quests.failed_quests.each do |s|
    failed.push(s.id)
  end
  return failed
end

#===============================================================================
# Clase que contiene métodos de utilidad para devolver propiedades de misión
#===============================================================================
class QuestData

  # Función para obtener número de identificación para la misión
  def getID(quest)
    return "#{QuestModule.const_get(quest)[:ID]}"
  end

  # Función para obtener el nombre de la misión
  def getName(quest)
    return "#{QuestModule.const_get(quest)[:Name]}"
  end

  # Función para obtener quien ha entregado la misión
  def getQuestGiver(quest)
    return "#{QuestModule.const_get(quest)[:QuestGiver]}"
  end

  # Función para el OW de quien ha entregado la misión
  def getQuestGiverOW(quest)
    return "#{QuestModule.const_get(quest)[:QuestGiverOW]}"
  end

  # Función para obtener el array de etapas de la misión
  def getQuestStages(quest)
    arr = []
    for key in QuestModule.const_get(quest).keys
      arr.push(key) if key.to_s.include?("Stage")
    end
    return arr
  end

  # Función para obtener la recompensa de la misión
  def getQuestReward(quest)
    return "#{QuestModule.const_get(quest)[:RewardString]}"
  end

  # Función para obtener la descripción de la misión
  def getQuestDescription(quest)
    return "#{QuestModule.const_get(quest)[:QuestDescription]}"
  end

  # Función para obtener la localización de la misión
  def getStageLocation(quest,stage)
    loc = ("Location" + "#{stage}").to_sym
    return "#{QuestModule.const_get(quest)[loc]}"
  end

  # Función para obtener la descripción de la tarea
  def getStageDescription(quest,stage)
    stg = ("Stage" + "#{stage}").to_sym
    return "#{QuestModule.const_get(quest)[stg]}"
  end
### Code for Percy
  # Función para obtener la etiqueta de la etapa actual
  def getStageLabel(quest,stage)
    lab = ("StageLabel" + "#{stage}").to_sym
    return "#{QuestModule.const_get(quest)[lab]}"
  end
###
  # Función para obtener el número máximo de tareas de una misión
  def getMaxStagesForQuest(quest)
    quests = getQuestStages(quest)
    return quests.length
  end

end

# Variable global para facilitar la referencia a los métodos de la clase anterior
$quest_data = QuestData.new

#===============================================================================
# Clase que contiene métodos de utilidad para devolver propiedades de la misión
#===============================================================================

# Función de utilidad para comprobar si el jugador actual tiene alguna misión activa
def hasAnyQuests?
  if $PokemonGlobal.quests.active_quests.length >0 ||
    $PokemonGlobal.quests.completed_quests.length >0 ||
    $PokemonGlobal.quests.failed_quests.length >0
    return true
  end
  return false
end

def getCurrentStage(quest)
  $PokemonGlobal.quests.active_quests.each do |s|
    return s.stage if s.id == quest
  end
  return nil
end

def taskCompleteJingle
  pbMessage(_INTL("\\se[{1}]<ac><c2=#{colorQuest("rojo")}>¡Tarea completada!</c2>\n¡Tu registro de misiones ha sido actualizado!</ac>",QUEST_JINGLE))
end
