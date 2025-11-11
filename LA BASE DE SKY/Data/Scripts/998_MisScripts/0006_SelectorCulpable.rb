#===============================================================================
# Killer Selection Menu para Pokemon Essentials v21
#===============================================================================

class KillerSelectionMenu
  SUSPECTS = [
    "EVIE", "Brenda", "Jensen", "DOJA", "PARA",
    "DINO", "CLOVER", "Pandary", "jardinero", "HOOPER",
    "RECEPC_VITTY", "RECEPC_LITTY", "redmond", "AILYN", "MARA"
  ]
  
  MUGSHOT_NAMES = [
    "MugshootArtistaEvie", "MugshootAyudanteBrendaSeria", "MugshootConserjeJensen", 
    "MugshootHermanoDoja", "MugshootHermanoPara", "MugshootDino", 
    "MugshootProfesorClover", "MugshootPandary", "MugshootJardinero", 
    "MugshootHooper-kuma", "MugshootRecepcionistaVitty", "MugshootRecepcionistaLitty", 
    "MugshootRivalRedmond", "MugshootRivalAilyn", "MugshootMaraProtesto"
  ]
  
  SUSPECT_NAMES = [
    "Artista Evie", "Ayudante Brenda", "Conserje Jensen", "Hermano Doja", "Hermano Para",
    "Dino Lobo de Mar", "Profesor Clover", "Chef Pandary", "Jardinero Elisio", "Hooper-Kuma",
    "Recepcionista Vitty", "Recepcionista Litty", "Redmond", "Ailyn", "Mara"
  ]
  
  CORRECT_INDEX = 11 # RECEPC_LITTY (índice empieza en 0)
  
  DIALOG_RESPONSES = {
    0 => "No me mires así, yo no tuve nada que ver.",
    1 => "No fui yo, estaba ocupada con mis experimentos.",
    2 => "No fui yo, búscalo en otro lado.",
    3 => "¿Qué? No tengo idea de qué hablas.",
    4 => "No tengo tiempo para estas acusaciones.",
    5 => "Yo no hice nada, ¡lo juro!",
    6 => "¿Me culpas a mí? Qué ofensa...",
    7 => "No me involucres en esto.",
    8 => "Solo cuido las plantas, nada más.",
    9 => "¡Ey! Yo estaba en otro lado cuando pasó.",
    10 => "¿Yo? Para nada, estaba atendiendo clientes.",
    11 => "S-sí... fui yo. Lo siento mucho...",
    12 => "No tengo tiempo para estas acusaciones.",
    13 => "¿Yo? ¡Imposible! Estaba en el laboratorio todo el día.",
    14 => "¿Yo? Estás muy equivocado."
  }

  def initialize
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @index = 0
    @selection_made = false
    @in_dialogue = false
    @show_victory = false
    @show_retry = false
    
    # Variables para animación de la tecla C
    @c_button_scale = 1.0
    @c_button_scale_direction = 1
    @c_button_scale_speed = 0.015
    
    create_sprites
  end

  def create_sprites
    # Background
    @sprites["bg"] = IconSprite.new(0, 0, @viewport)
    @sprites["bg"].setBitmap("Graphics/Pictures/juicio/SeletorCulpableDefault")
    
    # Selector cursor
    @sprites["cursor"] = IconSprite.new(0, 0, @viewport)
    @sprites["cursor"].setBitmap("Graphics/Pictures/juicio/SelectorCulpable")
    @sprites["cursor"].z = 2
    
    # Título
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    @sprites["overlay"].z = 3
    pbSetSystemFont(@sprites["overlay"].bitmap)
    
    # Mugshot
    @sprites["mugshot"] = IconSprite.new(8, 121, @viewport)
    @sprites["mugshot"].visible = false
    @sprites["mugshot"].z = 5
    
    # Namebox (speaker)
    @sprites["speaker"] = Sprite.new(@viewport)
    @sprites["speaker"].bitmap = Bitmap.new(350, 40)
    @sprites["speaker"].bitmap.font.size = 24
    @sprites["speaker"].bitmap.font.name = "Arial"
    @sprites["speaker"].bitmap.font.color = Color.new(255, 255, 255)
    @sprites["speaker"].x = 16
    @sprites["speaker"].y = 250
    @sprites["speaker"].visible = false
    @sprites["speaker"].z = 5
    
    # Diálogo
    @sprites["dialogue"] = Window_AdvancedTextPokemon.new("")
    @sprites["dialogue"].viewport = @viewport
    @sprites["dialogue"].width = Graphics.width - 10
    @sprites["dialogue"].height = 140
    @sprites["dialogue"].x = 0
    @sprites["dialogue"].y = Graphics.height - 100
    @sprites["dialogue"].baseColor = Color.new(255, 255, 255)
    @sprites["dialogue"].shadowColor = Color.new(0, 0, 0)
    @sprites["dialogue"].windowskin = nil
    @sprites["dialogue"].back_opacity = 0
    @sprites["dialogue"].contents.font.size = 20
    @sprites["dialogue"].contents.font.name = "Arial"
    @sprites["dialogue"].visible = false
    @sprites["dialogue"].z = 5
    
    # Botón C
    @sprites["c_button_prompt"] = IconSprite.new(Graphics.width - 30, Graphics.height - 20, @viewport)
    @sprites["c_button_prompt"].setBitmap("Graphics/Pictures/juicio/LetraC")
    @sprites["c_button_prompt"].ox = 16  # 32 / 2
    @sprites["c_button_prompt"].oy = 16  # 32 / 2
    @sprites["c_button_prompt"].visible = false
    @sprites["c_button_prompt"].z = 100003
    
    draw_title
    update_cursor_position
  end
  
  def draw_title
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    
    text = "¿Quién es el verdadero asesino?"
    textpos = [
      [text, Graphics.width / 2, 20, 2, Color.new(248, 248, 248), Color.new(0, 0, 0)]
    ]
    
    pbDrawTextPositions(overlay, textpos)
  end

  def update_cursor_position
    # Grid: 5 columnas x 3 filas
    col = @index % 5
    row = @index / 5
    
    # Posiciones basadas en la imagen (ajusta según sea necesario)
    base_x = 35
    base_y = 95
    spacing_x = 95
    spacing_y = 95
    
    @sprites["cursor"].x = base_x + (col * spacing_x)
    @sprites["cursor"].y = base_y + (row * spacing_y)
  end

def pbStartScreen
  pbSEPlay("GUI menu open")
  result = nil
  loop do
    Graphics.update
    Input.update
    update
    break if @selection_made
  end
  result = @current_is_correct
  dispose
  Input.update   # 👈 limpia la última tecla pulsada
  return result
end
  def update
    if @in_dialogue
      update_dialogue
    else
      update_selection
    end
  end
  
  def update_selection
    if Input.trigger?(Input::USE)
      pbSEPlay("GUI menu choose")
      show_suspect_response
    elsif Input.trigger?(Input::BACK)
      pbSEPlay("GUI menu close")
      @selection_made = true
    elsif Input.repeat?(Input::LEFT)
      if @index % 5 > 0
        @index -= 1
        pbSEPlay("GUI menu cursor")
        update_cursor_position
      end
    elsif Input.repeat?(Input::RIGHT)
      if @index % 5 < 4 && @index < SUSPECTS.length - 1
        @index += 1
        pbSEPlay("GUI menu cursor")
        update_cursor_position
      end
    elsif Input.repeat?(Input::UP)
      if @index >= 5
        @index -= 5
        pbSEPlay("GUI menu cursor")
        update_cursor_position
      end
    elsif Input.repeat?(Input::DOWN)
      if @index + 5 < SUSPECTS.length
        @index += 5
        pbSEPlay("GUI menu cursor")
        update_cursor_position
      end
    end
  end
  
  def update_dialogue
    @sprites["dialogue"].update
    
    # Animar botón C
    @c_button_scale += @c_button_scale_speed * @c_button_scale_direction
    if @c_button_scale >= 1.2
      @c_button_scale = 1.2
      @c_button_scale_direction = -1
    elsif @c_button_scale <= 0.8
      @c_button_scale = 0.8
      @c_button_scale_direction = 1
    end
    
    @sprites["c_button_prompt"].zoom_x = @c_button_scale
    @sprites["c_button_prompt"].zoom_y = @c_button_scale
    
    if Input.trigger?(Input::USE) || Input.trigger?(Input::BACK)
      if @sprites["dialogue"].busy?
        @sprites["dialogue"].resume if @sprites["dialogue"].paused?
      else
        # Cerrar el diálogo actual
       if @show_victory
         @in_dialogue = false
        @selection_made = true
        return
        elsif @show_retry
  # Termina el diálogo de reintento y vuelve al selector
  @sprites["dialogue"].visible = false
  @sprites["c_button_prompt"].visible = false
  @sprites["speaker"].visible = false
  @sprites["mugshot"].visible = false   # 👈 añadir esto

  # Restaurar fondo y UI del selector
  @sprites["bg"].setBitmap("Graphics/Pictures/juicio/SeletorCulpableDefault")
  @sprites["overlay"].visible = true
  @sprites["cursor"].visible = true

  @in_dialogue = false
  @show_retry = false
        else
          # Es el primer diálogo del sospechoso, pasar al siguiente mensaje
          close_dialogue
        end
      end
    end
  end

  def show_suspect_response
    suspect_name = SUSPECTS[@index]
    mugshot_name = MUGSHOT_NAMES[@index]
    speaker_name = SUSPECT_NAMES[@index]
    
    # Cambiar al fondo PantallaHablaPersonajes
    @sprites["bg"].setBitmap("Graphics/Pictures/juicio/PantallaHablaPersonajesdefault")
    
    # Ocultar título y cursor
    @sprites["overlay"].visible = false
    @sprites["cursor"].visible = false
    
    # Mostrar mugshot del sospechoso
    @sprites["mugshot"].setBitmap("Graphics/Pictures/juicio/#{mugshot_name}")
    @sprites["mugshot"].visible = true
    
    # Mostrar speaker
    @sprites["speaker"].visible = true
    @sprites["speaker"].bitmap.clear
    @sprites["speaker"].bitmap.draw_text(0, 0, 350, 40, speaker_name, 0)
    
    # Mostrar diálogo
    @sprites["dialogue"].visible = true
    response = DIALOG_RESPONSES[@index] || "..."
    @sprites["dialogue"].text = response
    
    # Mostrar botón C
    @sprites["c_button_prompt"].visible = true
    
    @in_dialogue = true
    @current_is_correct = (@index == CORRECT_INDEX)
    
    Graphics.update
  end
  
  def close_dialogue
    # No cambiar @in_dialogue aquí, lo haremos en cada caso
    
    # Ocultar elementos del primer diálogo
    @sprites["mugshot"].visible = false
    @sprites["speaker"].visible = false
    @sprites["dialogue"].visible = false
    @sprites["c_button_prompt"].visible = false
    
    if @current_is_correct
      # Culpable correcto - mostrar mensaje de victoria con el sistema de diálogo
      show_victory_message
    else
      # Respuesta incorrecta - mostrar mensaje de reintentar
      show_retry_message
    end
  end
  
  def show_victory_message

    @sprites["mugshot"].setBitmap("Graphics/Pictures/juicio/MugshootHooper-kuma")
    @sprites["mugshot"].visible = true
    
    # Actualizar speaker
    @sprites["speaker"].visible = true
    @sprites["speaker"].bitmap.clear
    @sprites["speaker"].bitmap.draw_text(0, 0, 350, 40, "Hooper-Kuma", 0)
    
    # Mostrar mensaje de victoria
    @sprites["dialogue"].visible = true
    @sprites["dialogue"].text = "¡Has identificado correctamente al culpable!"
    
    # Mostrar botón C
    @sprites["c_button_prompt"].visible = true
    
    @in_dialogue = true
    @show_victory = true
    Graphics.update
  end
  
 def show_retry_message
  # Fondo de diálogo
  @sprites["bg"].setBitmap("Graphics/Pictures/juicio/PantallaHablaPersonajesdefault")
  @sprites["overlay"].visible = false
  @sprites["cursor"].visible = false

  # Mostrar mugshot de Hooper-Kuma
  @sprites["mugshot"].setBitmap("Graphics/Pictures/juicio/MugshootHooper-kuma")
  @sprites["mugshot"].visible = true

  # Speaker
  @sprites["speaker"].visible = true
  @sprites["speaker"].bitmap.clear
  @sprites["speaker"].bitmap.draw_text(0, 0, 350, 40, "Hooper-Kuma", 0)

  # Diálogo
  @sprites["dialogue"].visible = true
  @sprites["dialogue"].text = "Vuelve a intentarlo. ¿Quién será el culpable?"

  # Botón C
  @sprites["c_button_prompt"].visible = true

  @in_dialogue = true
  @show_retry = true

  Graphics.update
end
  def dispose
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

#===============================================================================
# Función para llamar desde eventos
#===============================================================================
def pbKillerSelectionMenu
  scene = KillerSelectionMenu.new
  scene.pbStartScreen
end