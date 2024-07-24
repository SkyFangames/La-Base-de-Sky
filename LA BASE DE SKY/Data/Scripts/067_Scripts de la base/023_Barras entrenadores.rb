if Settings::MOSTRAR_BARRAS_ENTRENADORES # << Make true to use this script, false to disable.
#===============================================================================
#
#  Trainer Sensor Script
#  Author     : Drimer
#  Editor     : Skyflyer
#
#===============================================================================

#===============================================================================
#                             **  Settings here! **
#
# RANGE sets the... range of detection! If it is set to 0 it will take the
# value x from 'Trainer(x)' (Event's name!)
#
# BAR_OPACITY is used to set the transparency to the focus bars.
#
# SELF_SWITCH is used to identify those trainers you already fought against of.
#
# BAR_HEIGHT sets the the focus bars' height value.
#
# BAR_GRAPHIC allows you to load your own graphic from 'Graphics/Pictures/'
# if it is set to "" or nil, the system will create them for you. If not, then
# the BAR_HEIGHT will be ignored as well as the BAR_OPACITY constant.
#===============================================================================
RANGE_BARS_TRAINER = 4

module TrainerSensor  
  BAR_OPACITY = 255/8
  SELF_SWITCH = "A"
  BAR_HEIGHT  = Graphics.height/6
  BAR_GRAPHIC = ""
  # If you use EBS, a good option is set this value to "EBS/newBattleMessageBox"
end
  

#===============================================================================
# **  
#===============================================================================
module TrainerSensor
  @top = Sprite.new
  @top.z = 1
  @bottom = Sprite.new
  @bottom.z = 1
  @triggered = false
  @created = false
  entrenadorMasCercano = nil
  #@ultimoCercano = nil
  
  
  def self.create(distance)
    
    if !@created
      # Se crea la barra superior
      @top.bitmap = Bitmap.new(Graphics.width, BAR_HEIGHT)
      @top.bitmap.fill_rect(0,0,@top.bitmap.width,@top.bitmap.height,
        Color.new(-255,-255,-255, BAR_OPACITY*(6-distance)))
      @top.oy = 0 # Posición donde tiene que terminar.      
      @top.y -= BAR_HEIGHT
      @top.x=0 if $PokemonSystem

      # Se crea la barra inferior
      @bottom.bitmap = Bitmap.new(Graphics.width, BAR_HEIGHT)
      @bottom.bitmap.fill_rect(0,0,@bottom.bitmap.width,@bottom.bitmap.height,
        Color.new(-255,-255,-255, BAR_OPACITY*(6-distance)))
      @bottom.oy = BAR_HEIGHT-Graphics.height  # Posición donde tiene que terminar.
      @bottom.y += BAR_HEIGHT
      @bottom.x=0 if $PokemonSystem

      @created = true
      
    else # Modificar la opacidad
      # Rellenamos la barra superior
      @top.bitmap.fill_rect(0,0,@top.bitmap.width,@top.bitmap.height,
        Color.new(-255,-255,-255, BAR_OPACITY*(6-distance)))
      
      # Rellenamos la barra inferior
      @bottom.bitmap.fill_rect(0,0,@bottom.bitmap.width,@bottom.bitmap.height,
        Color.new(-255,-255,-255, BAR_OPACITY*(6-distance)))
    end
  end
  
  
  
  def self.triggered?
    @triggered
  end
  
  def self.show(distancia)
    self.create(distancia) #if !@created
    @triggered = true
  end
  
  def self.hide
    @triggered = false
  end
  
  
  
  # Hacer que aparezcan o desaparezcan progresivamente
  def self.update
    return if !@created
    if @triggered # Que aparezcan deslizándose
      if @top.y <= (- 6)
        @top.y += 6
        @bottom.y -= 6
      end
    else  # Que desaparezcan deslizándose
      if @top.y >= (-BAR_HEIGHT)
        @top.y -= 6
        @bottom.y += 6
      end    
      if @top.y <= (-BAR_HEIGHT)
        @created = false
      end
    end
  end
  
end


def update_trainer_bars
  entrenadorMasCercano = RANGE_BARS_TRAINER+1
  
  for event in $game_map.events.values
    if event.name[/^Trainer\((\d+)\)$/] && event.isOff?(TrainerSensor::SELF_SWITCH)

      # Obtenemos la distancia a la que mira el entrenador.
      rango_entrenador = event.name[8...9].to_i
      
      # Según a dónde mira el trainer, calculamos los espacios a los que mira.
      if event.direction == 8 # Arriba
        for i in 0..rango_entrenador+1
          distance = (($game_player.x-event.x).abs) + (($game_player.y-(event.y-i)).abs)
          if (entrenadorMasCercano>distance)
            entrenadorMasCercano = distance
          end
        end
      elsif event.direction == 2 # Abajo
        for i in 0..rango_entrenador+1
          distance = (($game_player.x-event.x).abs) + (($game_player.y-(event.y+i)).abs)
          if (entrenadorMasCercano>distance)
            entrenadorMasCercano = distance
          end
        end
      elsif event.direction == 6 # Derecha
        for i in 0..rango_entrenador+1
          distance = (($game_player.x-(event.x+i)).abs) + (($game_player.y-event.y).abs)
          if (entrenadorMasCercano>distance)
            entrenadorMasCercano = distance
          end
        end
      elsif event.direction == 4 # Izquierda
        for i in 0..rango_entrenador+1
          distance = (($game_player.x-(event.x-i)).abs) + (($game_player.y-event.y).abs)
          if (entrenadorMasCercano>distance)
            entrenadorMasCercano = distance
          end
        end
      end
    end
  end

  # Actualizamos las barras en base a lo lejos que están los entrenadores.
    if entrenadorMasCercano == RANGE_BARS_TRAINER+1
      TrainerSensor.hide() if TrainerSensor.triggered?
    else 
      TrainerSensor.show(entrenadorMasCercano)
    end
end


module Graphics
  class << self
    alias trainer_detection_update update
    def update
      trainer_detection_update
      TrainerSensor.update if $scene && $scene.is_a?(Scene_Map)
    end
  end
end


class Scene_Map
  alias update_barras update
  def update
    update_barras
    update_trainer_bars
  end
end




# Change it to Events.onStepTaken if you want this to scan the events on each step
# the player gives. Before: Events.onMapUpdate  
EventHandlers.add(:on_step_taken, :barras_entrenadores, proc{|sender,e|
  update_trainer_bars
})


end # if principal
