=begin
Eventos con '#EOT' en sus nombres serán afectados por este script.

  Si la etiqueta '#EOT HIDE' está presente, el evento se ocultará.
  También puedes agregar una tercera etiqueta que debe ser un número y se usará
  como el límite de opacidad del evento (para mostrar u ocultar).

  Ejemplos:
    #EOT HIDE
    #EOT HIDE 100
    #EOT SHOW
    #EOT SHOW 100

  Se debe agregar el item 'LENSOFTRUTH' en la sección de Items en el PBS en la sección de Objetos clave
  para que el script funcione correctamente.
=end

module LensOfTruth
  # Duración en segundos
  DURATION = 20

  # Rango, el máximo es 4  (recomendado no aumentar)
  RANGE = 4
end

class Scene_Map
  attr_accessor :eye_of_truth_time
  
  def initialize
    @eye_of_truth_time = 0
  end
end

class Game_Event
  attr_accessor :event, :opacity, :through, :character_hue
  
  alias _update_lens update
  def update
    # Si el nombre del evento contiene '#EOT'
    if self.name[/#EOT/]
      # Si el nombre del evento contiene 'HIDE'
      if self.name[/HIDE/]
        # Si el evento está dentro del rango y el tiempo de 'eye_of_truth' es mayor a 0
        if InRange?(self.event, LensOfTruth::RANGE%5) &&
            ($scene.is_a?(Scene_Map) ? $scene.eye_of_truth_time > 0 : false)
          # Establece la opacidad según el valor en el nombre del evento o 0 por defecto
          opacity = self.name[/(\d+)/] ? $1.to_i : 0
          self.through = true
          self.opacity -= 25.5 if self.opacity > opacity
        else
          if !onEvent?
            self.through = false
          end
          self.opacity += 25.5 if self.opacity < 255
        end
      # Si el nombre del evento contiene 'SHOW'
      elsif self.name[/SHOW/]
        # Si el evento está dentro del rango y el tiempo de 'eye_of_truth' es mayor a 0
        if InRange?(self.event, LensOfTruth::RANGE%5) &&
            ($scene.is_a?(Scene_Map) ? $scene.eye_of_truth_time > 0 : false)
          # Establece la opacidad según el valor en el nombre del evento o 255 por defecto
          opacity = self.name[/(\d+)/] ? $1.to_i : 255
          if !onEvent?
            self.through = false
          end
          self.opacity += 25.5 if self.opacity < opacity
        else
          self.through = true
          self.opacity -= 25.5 if self.opacity > 0
        end        
      end
    end
    _update_lens
  end
  
  # Comprueba si el evento está dentro del rango especificado
  def InRange?(event, distance)
    return false if distance <= 0
    rad = (Math.hypot((event.x - $game_player.x),(event.y - $game_player.y))).abs
    return true if (rad <= distance)
    return false
  end
end

module Graphics
  class << self
    alias _update_eye update
    def update
      _update_eye
      # Inicializa @eye_graphic si no existe o está eliminado
      if !@eye_graphic || @eye_graphic.disposed?
        @eye_graphic = Sprite.new
        @eye_graphic.z = 3
        @eye_graphic.bitmap = RPG::Cache.load_bitmap("Graphics/Plugins/Lens/", "truth_circle")
        @eye_graphic.ox = @eye_graphic.bitmap.width / 2
        @eye_graphic.oy = (@eye_graphic.bitmap.height / 2)
        @eye_graphic.x = Graphics.width / 2
        @eye_graphic.y = (Graphics.height / 2)
        @eye_graphic.opacity = 0
      end
      # Inicializa @mask si no existe o está eliminado
      if !@mask || @mask.disposed?
        @mask = Sprite.new
        @mask.bitmap = RPG::Cache.load_bitmap("Graphics/Plugins/Lens/", "mask")
        @mask.z = 1
        @mask.ox = @mask.bitmap.width / 2
        @mask.oy = (@mask.bitmap.height / 2)
        @mask.x = Graphics.width / 2
        @mask.y = (Graphics.height / 2)
        @mask.opacity = 0
      end
      # Inicializa @effect si no existe o está eliminado
      if !@effect || @effect.disposed?
        @effect = Sprite.new
        @effect.z = 2
        @effect.bitmap = RPG::Cache.load_bitmap("Graphics/Plugins/Lens/", "wave")
        @effect.ox = @effect.bitmap.width / 2
        @effect.oy = (@effect.bitmap.height / 2)
        @effect.x = Graphics.width / 2
        @effect.y = Graphics.height / 2
        @effect.zoom_x = @effect.zoom_y = 0
      end
      return if $game_temp && $game_temp.in_menu
      # Si el tiempo de 'eye_of_truth' es mayor a 0
      if $scene.is_a?(Scene_Map) && $scene.eye_of_truth_time > 0
        @effect.visible = true if !@effect.visible
        @mask.x = @eye_graphic.x = @effect.x = $game_player.screen_x
        @mask.y = @eye_graphic.y = @effect.y = $game_player.screen_y
        $scene.eye_of_truth_time -= 1
        if @eye_graphic.opacity < 255
          @eye_graphic.opacity += 12.75
          @mask.opacity += 12.75
        end
        if @effect.zoom_x < 1.0
          @effect.zoom_x = @effect.zoom_y += 0.0125
        else
          if @effect.opacity > 0
            @effect.opacity -= 25.5
          else
            @effect.zoom_x = @effect.zoom_y = 0
            @effect.opacity = 255
          end
        end
        @eye_graphic.angle += 0.5
      else
        if @eye_graphic.opacity > 0
          @eye_graphic.angle += 0.5
          @eye_graphic.opacity -= 12.75 
          @mask.opacity -= 12.75
          @effect.visible = false
          @effect.opacity = 255
          @effect.zoom_x = @effect.zoom_y = 0
        end
      end
    end
  end
end

# Función para usar la Lente de la Verdad
def pbLensOfTruth
  if ($scene.eye_of_truth_time == 0)
    return true
  else
    Kernel.pbMessage(_INTL("El objeto ya está en uso."))
    return false
  end
end

# Manejador de uso del objeto Lente de la Verdad en el campo
ItemHandlers::UseInField.add(:LENSOFTRUTH, proc { |item|
  Kernel.pbMessage(_INTL("¡\\PN uso la lente revelacion!"))
  waves = []
  star = Sprite.new
  star.z = 2
  star.bitmap = RPG::Cache.load_bitmap("Graphics/Plugins/Lens/", "part")
  star.ox = star.bitmap.width / 2
  star.oy = (star.bitmap.height / 2)
  star.x = $game_player.screen_x
  star.y = $game_player.screen_y
  star.zoom_x = star.zoom_y = 0
  count = 0
  10.times do
    s = Sprite.new
    s.z = 1
    s.bitmap = RPG::Cache.load_bitmap("Graphics/Plugins/Lens/", "wave")
    s.zoom_x = s.zoom_y = 0
    s.x = $game_player.screen_x
    s.y = $game_player.screen_y
    s.ox = s.bitmap.width / 2
    s.oy = (s.bitmap.height / 2)
    waves.push(s)
  end
  pbSEPlay("shiny")
  # Frames para la animación
  30.times do
    Graphics.update
    star.zoom_x = star.zoom_y += 1.0 / 30.0
    star.angle += 1.5
  end
  pbSEPlay("Saint7")
  60.times do
    Graphics.update
    star.angle += 1.5
    count += 1
    for i in 0...waves.length
      next if !waves[i].visible
      if waves[i].zoom_x >= 1.0
        waves[i].visible = false
      end
      waves[i].zoom_x = waves[i].zoom_y += 0.005 * i
    end
  end
  10.times do
    Graphics.update
    for i in 0...waves.length
      next if !waves[i].visible
      if waves[i].zoom_x >= 1.0
        waves[i].visible = false
      end
      waves[i].zoom_x = waves[i].zoom_y += 0.005 * i
      waves[i].opacity -= 255 / 10
    end
    star.zoom_x = star.zoom_y -= 1.0 / 10.0
    star.angle += 1.5
  end
  waves.each { |i| i.dispose }
  star.dispose
  $scene.eye_of_truth_time = LensOfTruth::DURATION * Graphics.frame_rate if $scene.is_a?(Scene_Map)
})

# Manejador de uso del objeto Lente de la Verdad desde la bolsa
ItemHandlers::UseFromBag.add(:LENSOFTRUTH, proc { |item|
  if pbLensOfTruth
    next 2
  else
    next 0
  end
})