#===============================================================================
# Menú de Juicio Estilo Danganronpa para Pokémon Essentials v21
# Creado para el sistema de juicios personalizado
# VERSIÓN CON CONFIRMACIÓN - Incluye menú Sí/No antes de empezar el juicio
#===============================================================================

class DanganronpaTrialMenu
  def initialize
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @index = 0 # 0=Abrir Cuaderno, 1=Cambiar Dificultad, 2=Empezar Juicio
    @trial_completed = false  # Si es true, se acaba el minijuego y se puede salir.
    
    # Cargamos las imágenes del menú principal
    @menu_images = [
      "Graphics/Pictures/juicio/FondoAntejuicioSeleccionCuardeno.png", # Abrir Cuaderno seleccionado
      "Graphics/Pictures/juicio/FondoAntejuicioSeleccionDificultad.png", # Cambiar Dificultad seleccionado  
      "Graphics/Pictures/juicio/FondoAntejuicoEMPEZAR.png", # Empezar Juicio seleccionado
      "Graphics/Pictures/juicio/FondoAntejuiciopreparacion.png"  # Menú sin selección
    ]
    
    create_main_menu
    refresh_selection
  end
  
  def create_main_menu
    # Sprite del fondo del menú
    @sprites["background"] = IconSprite.new(0, 0, @viewport)
    @sprites["background"].setBitmap(@menu_images[3]) # Imagen por defecto
  end
  
  def refresh_selection
    # Cambiar la imagen según la opción seleccionada
    @sprites["background"].setBitmap(@menu_images[@index])
  end
  
  def update
    Graphics.update
    Input.update
    
    if Input.trigger?(Input::UP)
      pbPlayCursorSE
      @index = (@index - 1) % 3
      refresh_selection
    elsif Input.trigger?(Input::DOWN)
      pbPlayCursorSE
      @index = (@index + 1) % 3
      refresh_selection
    elsif Input.trigger?(Input::USE)
      pbPlayDecisionSE
      case @index
      when 0
        open_evidence_notebook
      when 1
        open_difficulty_menu
      when 2
        # Abrir menú de confirmación para empezar juicio
        open_trial_confirmation
      end
    end
    
    # Solo permitir salir si el juicio se completó
    return !@trial_completed
  end
  
  def open_evidence_notebook
    dispose_main_menu
    evidence_menu = EvidenceNotebookMenu.new
    evidence_menu.main
    evidence_menu.dispose
    create_main_menu
    refresh_selection
    @index = 0 # Restaurar a la opción por defecto (Abrir Cuaderno)
  end
  
  def open_difficulty_menu
    dispose_main_menu
    difficulty_menu = DifficultySelectionMenu.new
    difficulty_menu.main
    difficulty_menu.dispose
    create_main_menu
    refresh_selection
    @index = 1 # Restaurar a "Cambiar Dificultad" como opción seleccionada al regresar
  end
  
  def open_trial_confirmation
    dispose_main_menu
    confirmation_menu = TrialConfirmationMenu.new
    result = confirmation_menu.main
    confirmation_menu.dispose
    
    if result == :start_trial
      # Iniciar el juicio escolar
      start_school_trial
    else
      # Volver al menú principal
      create_main_menu
      refresh_selection
      @index = 2 # Mantener seleccionado "Empezar Juicio"
    end
  end
  
  def start_school_trial
    # Aquí va la lógica del juicio escolar
    dispose_main_menu
    trial_game = SchoolTrialGame.new
    @trial_completed = trial_game.main
    trial_game.dispose
    
    if @trial_completed
      pbMessage("\\PN[¡Juicio completado exitosamente!]")
    else
      # Si el juicio no se completó, volver al menú principal
      create_main_menu
      refresh_selection
      @index = 2
    end
  end
  
  def complete_trial
    @trial_completed = true
    pbMessage("\\PN[¡Juicio completado! Ahora puedes salir.]")
  end
  
  def dispose_main_menu
    @sprites.each_value { |sprite| sprite.dispose }
    @sprites.clear
  end
  
  def main
    loop do
      break unless update
    end
    dispose
  end
  
  def dispose
    dispose_main_menu
    @viewport.dispose
  end
end


#===============================================================================
# Menú del Cuaderno de Evidencias (Sistema de Selección Visual) - CORREGIDO
#===============================================================================

class EvidenceNotebookMenu
  def initialize
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @index = 0
    @showing_details = false

    @evidence_list = [
      {
        name: "Sala Cadáver",
        brief_description: "El cadáver fue encontrado en la sala de Brenda.",
        detailed_description: "El cadáver fue encontrado en la sala de Brenda. La víctima presenta una herida en la cabeza, producida por un objeto contundente. No hay signos de lucha, lo que sugiere que la víctima fue sorprendida.",
        image_selected: "Graphics/Pictures/juicio/CuardernoJuicioSelecCadaver",
        image_normal: "Graphics/Pictures/juicio/CuardernoJuicio"
      },
      {
        name: "Barra de Metal",
        brief_description: "Una Barra metálica con rastros de sangre.",
        detailed_description: "Una Barra metálica con rastros de sangre. Encontrada como si fuese una fregona. No hay huellas en ella, lo que indica que el asesino usó \\c[2]guantes\\c[0] o limpió el arma después del ataque.",
        image_selected: "Graphics/Pictures/juicio/CuardernoJuicioSelecBarrar",
        image_normal: "Graphics/Pictures/juicio/CuardernoJuicio"
      },
      {
        name: "Traumatismo",
        brief_description: "Evidencia médica que indica traumatismo severo en la cabeza de la víctima",
        detailed_description: "Evidencia médica que indica traumatismo severo en la cabeza de la víctima. La herida fue causada con un objeto contundente.Parece que la víctima fue atacada por la espalda.",
        image_selected: "Graphics/Pictures/juicio/CuardernoJuicioSelecTraumatismor",
        image_normal: "Graphics/Pictures/juicio/CuardernoJuicio"
      },
      {
        name: "Uniforme XXL",
        brief_description: "Uniforme de Morrigan de talla XXL ensangrentado.",
        detailed_description: "Uniforme de Morrigan de talla XXL ensangrentado.Fue encontrado en su taquilla. Las manchas de sangre indican que fue usado durante el asesinato por alguien que no esta acostumbrado a los uniformes.",
        image_selected: "Graphics/Pictures/juicio/CuardernoJuicioSelecUniforme",
        image_normal: "Graphics/Pictures/juicio/CuardernoJuicio"
      },
      {
        name: "Bote Pintura",
        brief_description: "Bote de pintura desparramado en la Sala de Pintura.",
        detailed_description: "Bote de pintura desparramado en la Sala de Pintura.Parece que el asesino derramo el bote sin querer y manchó algo.",
        image_selected: "Graphics/Pictures/juicio/CuardernoJuicioSelecBote",
        image_normal: "Graphics/Pictures/juicio/CuardernoJuicio"
      },
      {
        name: "Bata Manchada",
        brief_description: "Bata Manchada de la Sala de Pintura.",
        detailed_description: "Bata Manchada de la Sala de Pintura. Las manchas han sido identificadas con pintura morada. Seguramente fue salpicada por el bote de pintura derramado.",
        image_selected: "Graphics/Pictures/juicio/CuardernoJuicioSelecBata",
        image_normal: "Graphics/Pictures/juicio/CuardernoJuicio"
      },
      {
        name: "Mensaje Póstumo",
        brief_description: "Un mensaje dejado por la víctima antes de su muerte.",
        detailed_description: "Un mensaje dejado por la víctima antes de su muerte. Las palabras escritas con sangre podrían revelar la identidad del asesino.",
        image_selected: "Graphics/Pictures/juicio/CuardernoJuicioSelecMensaje",
        image_normal: "Graphics/Pictures/juicio/CuardernoJuicio"
      },
      {
        name: "Mechón Largo",
        brief_description: "Mechón largo de pelo  encontrado en la sala Vacia.",
        detailed_description: "Mechón largo de pelo encontrado en la sala Vacia. El mechón parece que voló desde el conducto de ventilación. No se puede saber de quién es.",
        image_selected: "Graphics/Pictures/juicio/CuardernoJuicioSelecMechon",
        image_normal: "Graphics/Pictures/juicio/CuardernoJuicio"
      },
      {
        name: "Conducto",
        brief_description: "Sistema de conducto de ventilación.",
        detailed_description: "Sistema de conducto de ventilación. Podría haber sido usado por el asesino para volver a la sala Vacia.",
        image_selected: "Graphics/Pictures/juicio/CuardernoJuicioSelecConducto",
        image_normal: "Graphics/Pictures/juicio/CuardernoJuicio"
      },
      {
        name: "Plano Sótano",
        brief_description: "Plano del sótano donde ocurrió el crimen.",
        detailed_description: "Plano del sótano donde ocurrió el crimen. Muestra rutas de escape secretas, además de indicar una ruta de escape planificada.",
        image_selected: "Graphics/Pictures/juicio/CuardernoJuicioSelecPlanoSotano",
        image_normal: "Graphics/Pictures/juicio/CuardernoJuicio"
      },
      {
        name: "Llave Maestra",
        brief_description: "Llave maestra que abre todas las habitaciones cerradas de la Academia.",
        detailed_description: "Llave maestra que abre todas las habitaciones cerradas de la Academia. Solo el conserje Jensen tiene acceso a esta llaves. Fue encontrada en una de las mesas de la Sala Cerrada.",
        image_selected: "Graphics/Pictures/juicio/CuardernoJuicioSelecLlaveMaestra",
        image_normal: "Graphics/Pictures/juicio/CuardernoJuicio"
      },
      {
        name: "Plan Asesinato",
        brief_description: "Documento que muestra con exactitud el plan de asesinato paso a paso de manera muy simplifada y detallada.",
        detailed_description: "Documento que muestra con exactitud el plan de asesinato paso a paso de manera muy simplifada y detallada. Fue encontrado en la Sala Cerrada. Parece que alguien lo escribrio para el asesino",
        image_selected: "Graphics/Pictures/juicio/CuardernoJuicioSelecPlanAsesinato",
        image_normal: "Graphics/Pictures/juicio/CuardernoJuicio"
      },
      {
        name: "Guantes",
        brief_description: "Guantes de jardinería usados por el asesino.",
        detailed_description: "Guantes de jardinería usados por el asesino. Contienen residuos de sangre y pintura que los vinculan al crimen. Estos guantes pertenecen al Jardinero de la Academia.",
        image_selected: "Graphics/Pictures/juicio/CuardernoJuicioSelecGuantes",
        image_normal: "Graphics/Pictures/juicio/CuardernoJuicio"
      },
      {
        name: "Trébol",
        brief_description: "Pin con forma de Trébol.",
        detailed_description: "Pin con forma de Trébol.Fue encontrado en los Almacenes del Comedor.Parece ser del Profesor Clover. Tal vez, fue dejado intencionalmente por el asesino.",
        image_selected: "Graphics/Pictures/juicio/CuardernoJuicioSelecTrebol",
        image_normal: "Graphics/Pictures/juicio/CuardernoJuicio"
      }
    ]

    create_evidence_menu
    refresh_evidence_display
  end

  def create_evidence_menu
    @sprites["background"] = IconSprite.new(0, 0, @viewport)
    @sprites["description_window"] = Window_AdvancedTextPokemon.new("")
    @sprites["description_window"].viewport = @viewport
    @sprites["description_window"].width = 320
    @sprites["description_window"].height = 180
    @sprites["description_window"].x = 186
    @sprites["description_window"].y = 219
    @sprites["description_window"].baseColor = Color.new(255, 255, 255)
    @sprites["description_window"].shadowColor = Color.new(0, 0, 0)
    @sprites["description_window"].visible = true
    @sprites["description_window"].windowskin = nil
    @sprites["description_window"].back_opacity = 0
    @sprites["description_window"].contents_opacity = 255
    @sprites["description_window"].contents.font.size = 20
    @sprites["description_window"].lineHeight = 22
  end

  def refresh_evidence_display
    evidence = @evidence_list[@index]
    # Mostramos imagen según si estamos en detalles o no; si no existe el bitmap, usamos el fallback
    if @showing_details && evidence[:image_selected] && pbResolveBitmap(evidence[:image_selected])
      @sprites["background"].setBitmap(evidence[:image_selected])
    elsif evidence[:image_normal] && pbResolveBitmap(evidence[:image_normal])
      @sprites["background"].setBitmap(evidence[:image_normal])
    else
      @sprites["background"].setBitmap("Graphics/Pictures/juicio/CuardernoJuicio")
    end

    if @showing_details
      @sprites["description_window"].text = evidence[:detailed_description]
    else
      @sprites["description_window"].text = evidence[:brief_description]
    end
  end

  def toggle_details
    @showing_details = !@showing_details
    refresh_evidence_display
  end

  def update
    Graphics.update
    Input.update

    # --- Salir con X o ESC ---
    if Input.trigger?(Input::B)
      pbPlayCancelSE
      return SceneManager.return
    end

    # --- Navegación (UP/DOWN) ---
    if Input.trigger?(Input::UP)
      pbPlayCursorSE
      @showing_details = false
      @index = (@index - 1) % @evidence_list.length
      refresh_evidence_display
    elsif Input.trigger?(Input::DOWN)
      pbPlayCursorSE
      @showing_details = false
      @index = (@index + 1) % @evidence_list.length
      refresh_evidence_display
    elsif Input.trigger?(Input::C) # Z, Enter o Espacio
      if @showing_details
        pbPlayDecisionSE
        # Si ya estabas viendo detalles, al pulsar otra vez salimos del menú
        return SceneManager.return
      else
        pbPlayDecisionSE
        toggle_details
      end
    end

    return true
  end

  def main
    loop do
      result = update
      break unless result
    end
    dispose
  end

  def dispose
    @sprites.each_value { |sprite| sprite.dispose if sprite && !sprite.disposed? rescue sprite.dispose }
    @sprites.clear
    @viewport.dispose if @viewport && !@viewport.disposed? rescue @viewport.dispose
  end
end

#===============================================================================
# Menú de Dificultad JUICIO (Lógica y Acción)   
#===============================================================================
class DifficultySelectionMenu
  def initialize
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    
    # Dificultades iniciales
    @logic_difficulty  = :media
    @action_difficulty = :media

    # Posición del selector (fila y columna)
    @row = 0      # 0 = lógica, 1 = acción, 2 = continuar
    @col = 1      # 0 = piadosa, 1 = media, 2 = sherlock

    # Crear sprite del fondo
    @sprites["background"] = IconSprite.new(0, 0, @viewport)
    
    # Crear selector para dificultades (pequeño)
    @sprites["selector"] = IconSprite.new(0, 0, @viewport)
    @sprites["selector"].setBitmap("Graphics/Pictures/juicio/SelectorDificultad")
    @sprites["selector"].z = 100000
    
    # Crear selector para continuar (grande)
    @sprites["selector_continuar"] = IconSprite.new(0, 0, @viewport)
    begin
      @sprites["selector_continuar"].setBitmap("Graphics/Pictures/juicio/SelectorContinuar")
      @sprites["selector_continuar"].z = 100000
      @sprites["selector_continuar"].visible = false
      puts "Debug: Selector Continuar creado correctamente"
    rescue => e
      puts "Debug: ERROR creando selector continuar: #{e.message}"
      @sprites["selector_continuar"] = @sprites["selector"].clone
      @sprites["selector_continuar"].visible = false
    end
    
    refresh_background
    refresh_selector
  end

  def main
    loop do
      Graphics.update
      Input.update
      result = update
      break if result == :exit
    end
    dispose
  end

  def update
    # Navegación entre filas
    if Input.trigger?(Input::UP) && @row > 0
      @row -= 1
      puts "Debug: UP pressed, new row: #{@row}"
      pbPlayCursorSE
      refresh_selector
    elsif Input.trigger?(Input::DOWN) && @row < 2
      @row += 1
      puts "Debug: DOWN pressed, new row: #{@row}"
      pbPlayCursorSE
      refresh_selector
    end

    # Navegación entre columnas (solo filas 0 y 1)
    if @row < 2
      if Input.trigger?(Input::LEFT) && @col > 0
        @col -= 1
        puts "Debug: LEFT pressed, new col: #{@col}"
        pbPlayCursorSE
        refresh_selector
      elsif Input.trigger?(Input::RIGHT) && @col < 2
        @col += 1
        puts "Debug: RIGHT pressed, new col: #{@col}"
        pbPlayCursorSE
        refresh_selector
      end
    end

    # Confirmar selección
    if Input.trigger?(Input::USE)
      pbPlayDecisionSE
      puts "Debug: USE pressed at row #{@row}, col #{@col}"
      
      if @row == 0   # Confirmar lógica
        @logic_difficulty = [:piadosa, :media, :sherlock][@col]
        puts "Debug: Logic difficulty set to #{@logic_difficulty}"
        refresh_background
      elsif @row == 1 # Confirmar acción
        @action_difficulty = [:piadosa, :media, :sherlock][@col]
        puts "Debug: Action difficulty set to #{@action_difficulty}"
        refresh_background
      elsif @row == 2 # Continuar
        puts "Debug: Continuing with difficulties - Logic: #{@logic_difficulty}, Action: #{@action_difficulty}"
        $game_variables[100] = difficulty_to_number(@logic_difficulty)
        $game_variables[101] = difficulty_to_number(@action_difficulty)
        return :exit
      end
    elsif Input.trigger?(Input::BACK)
      pbPlayCancelSE
      return :exit
    end

    return :continue
  end

  def difficulty_to_number(difficulty)
    case difficulty
    when :piadosa then 0
    when :media   then 1
    when :sherlock then 2
    else 1
    end
  end

  def refresh_background
    case [@logic_difficulty, @action_difficulty]
    when [:media, :media]
      @sprites["background"].setBitmap("Graphics/Pictures/juicio/EleccionDificultadMediaDificultadlogicaYAccion")
    when [:piadosa, :media]
      @sprites["background"].setBitmap("Graphics/Pictures/juicio/EleccionDificultadPiadosaDificultadlogicayMEDIAACCION")
    when [:sherlock, :media]
      @sprites["background"].setBitmap("Graphics/Pictures/juicio/EleccionDificultadSherlockDificultadlogicaYmEDIAACCION")
    when [:media, :piadosa]
      @sprites["background"].setBitmap("Graphics/Pictures/juicio/EleccionDificultadMediaDificultadlogicayPiadosaACCION")
    when [:media, :sherlock]
      @sprites["background"].setBitmap("Graphics/Pictures/juicio/EleccionDificultadMediaAccionySherlockaccion")
    when [:piadosa, :sherlock]
      @sprites["background"].setBitmap("Graphics/Pictures/juicio/EleccionDificultadPiadosaDificultadlogicaysherlockAccioon")
    when [:sherlock, :piadosa]
      @sprites["background"].setBitmap("Graphics/Pictures/juicio/EleccionDificultadSherlockDificultadlogicayPiadosaAccion")
    when [:piadosa, :piadosa]
      @sprites["background"].setBitmap("Graphics/Pictures/juicio/EleccionDificultadPiadosaDificultadlogicaYAccion")
    when [:sherlock, :sherlock]
      @sprites["background"].setBitmap("Graphics/Pictures/juicio/EleccionDificultadSherlockDificultadlogicaYaccion")
    else
      @sprites["background"].setBitmap("Graphics/Pictures/juicio/EleccionDificultadMediaDificultadlogicaYAccion")
    end
  end

  def refresh_selector
    begin
      puts "Debug: Entrando a refresh_selector - Row: #{@row}, Col: #{@col}"
      Graphics.update
      
      if @row == 0
        @sprites["selector"].visible = true
        @sprites["selector_continuar"].visible = false
        case @col
        when 0
          @sprites["selector"].x = -145
          @sprites["selector"].y = 0
        when 1
          @sprites["selector"].x = 0
          @sprites["selector"].y = 0
        when 2
          @sprites["selector"].x = 145
          @sprites["selector"].y = 0
        end
        
      elsif @row == 1
        @sprites["selector"].visible = true
        @sprites["selector_continuar"].visible = false
        case @col
        when 0
          @sprites["selector"].x = -145
          @sprites["selector"].y = 126
        when 1
          @sprites["selector"].x = 0
          @sprites["selector"].y = 126
        when 2
          @sprites["selector"].x = 145
          @sprites["selector"].y = 126
        end
        
      elsif @row == 2
        puts "Debug: *** CONFIGURANDO SELECTOR CONTINUAR ***"
        @sprites["selector"].visible = false
        @sprites["selector_continuar"].visible = true

        if @sprites["selector_continuar"].bitmap
          @sprites["selector_continuar"].ox = @sprites["selector_continuar"].bitmap.width / 2
          @sprites["selector_continuar"].oy = @sprites["selector_continuar"].bitmap.height / 2
        end

        @sprites["selector_continuar"].x = Graphics.width / 2
        @sprites["selector_continuar"].y = 192
      end

      Graphics.update
      puts "Debug: refresh_selector completado exitosamente"
      
    rescue => e
      puts "Debug: ERROR en refresh_selector: #{e.message}"
      @sprites["selector"].visible = true
      @sprites["selector_continuar"].visible = false
    end
  end

  def dispose
    @sprites.each_value do |sprite| 
      sprite.dispose if sprite && !sprite.disposed?
    end
    @sprites.clear
    @viewport.dispose if @viewport && !@viewport.disposed?
  end
end


#===============================================================================
# Menú de Confirmación para Empezar Juicio (Sí/No)
#===============================================================================

class TrialConfirmationMenu
  def initialize
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @index = 1 # 0 = Sí, 1 = No (empezamos con No seleccionado por seguridad)

    # Imagen previa antes de mostrar Sí/No
    @default_image = "Graphics/Pictures/juicio/PantallaAntesAvanzar"

    # Imágenes del menú de confirmación
    @confirmation_images = [
      "Graphics/Pictures/juicio/PantallaAntesAvanzarSI", # Sí seleccionado
      "Graphics/Pictures/juicio/PantallaAntesAvanzaNO"  # No seleccionado
    ]

    create_confirmation_menu
    show_default_screen
  end

  def create_confirmation_menu
    @sprites["background"] = IconSprite.new(0, 0, @viewport)
  end

  def show_default_screen
    # Mostrar imagen por defecto
    @sprites["background"].setBitmap(@default_image)

    # Texto flotante con indicación
    create_hint_text

    loop do
      Graphics.update
      Input.update
      update_hint_animation

      if Input.trigger?(Input::UP) || Input.trigger?(Input::DOWN)
        pbPlayCursorSE
        @index = (Input.trigger?(Input::UP)) ? 0 : 1
        refresh_confirmation_display
        break
      elsif Input.trigger?(Input::USE) || Input.trigger?(Input::ACTION) || Input.trigger?(Input::C)
        pbPlayDecisionSE
        dispose_hint
        refresh_confirmation_display
        break
      elsif Input.trigger?(Input::BACK)
        pbPlayCancelSE
        dispose_hint
        @cancelled = true
        break
      end
    end
  end

  # Crear el texto flotante
  def create_hint_text
    @sprites["hint"] = Sprite.new(@viewport)
    @sprites["hint"].bitmap = Bitmap.new(Graphics.width, 40)
    @sprites["hint"].bitmap.font.name = "Verdana"
    @sprites["hint"].bitmap.font.size = 26
    text = "Usa ↑/↓ para seleccionar una opción"

    # Dibujar sombra (negra, desplazada 2px)
    @sprites["hint"].bitmap.font.color = Color.new(0, 0, 0)
    @sprites["hint"].bitmap.draw_text(2, 2, Graphics.width, 40, text, 1)

    # Dibujar texto principal (blanco encima)
    @sprites["hint"].bitmap.font.color = Color.new(255, 255, 255)
    @sprites["hint"].bitmap.draw_text(0, 0, Graphics.width, 40, text, 1)

    # 📍 Subimos más el texto flotante
    @sprites["hint"].y = Graphics.height - 185
    @sprites["hint"].opacity = 255
    @hint_opacity_dir = -5
  end

  # Animación de parpadeo
  def update_hint_animation
    return unless @sprites["hint"]
    @sprites["hint"].opacity += @hint_opacity_dir
    if @sprites["hint"].opacity <= 100 || @sprites["hint"].opacity >= 255
      @hint_opacity_dir *= -1
    end
  end

  def dispose_hint
    if @sprites["hint"]
      @sprites["hint"].bitmap.dispose
      @sprites["hint"].dispose
      @sprites.delete("hint")
    end
  end

  def refresh_confirmation_display
    # Cambiar imagen según la selección
    @sprites["background"].setBitmap(@confirmation_images[@index])
  end

  def main
    return :cancel if @cancelled # Si se salió en la pantalla default

    result = nil
    loop do
      Graphics.update
      Input.update
      update_hint_animation

      if Input.trigger?(Input::UP) || Input.trigger?(Input::DOWN)
        pbPlayCursorSE
        @index = (@index == 0) ? 1 : 0
        refresh_confirmation_display
      elsif Input.trigger?(Input::USE)
        pbPlayDecisionSE
        dispose_hint
        if @index == 0 # Sí seleccionado
          result = :start_trial
          break
        else # No seleccionado
          result = :cancel
          break
        end
      elsif Input.trigger?(Input::BACK)
        pbPlayCancelSE
        dispose_hint
        result = :cancel
        break
      end
    end

    return result
  end

  def dispose
    @sprites.each_value { |sprite| sprite.dispose }
    @sprites.clear
    @viewport.dispose
  end
end
    
#===============================================================================
# Juicio Escolar - Sistema de Danganronpa con Bucles y Saltos (MANUAL ÚNICAMENTE)
#===============================================================================
class SchoolTrialGame
  def initialize
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @dialogue_index = 0
    @trial_completed = nil
    @player_health = 6
    
    # Variables para la animación del título
    @title_x = -400
    @title_speed = 2
    @title_fade_start = Graphics.width * 0.7
    @title_reset_x = Graphics.width + 50

    # Variables para el sistema de avance - Solo manual
    @dialogue_showing = false
    @waiting_for_contradiction = false

    # Variables para el sistema de bucles/saltos
    @current_section = :intro
    @loop_sections = {}  # Almacena el índice de inicio de cada sección de bucle
    @contradictions_resolved = []
    @intro_completed = false

    # Variables para la animación del texto de evidencias
    @evidence_text_alpha = 0
    @evidence_text_fade_speed = 3
    @evidence_text_pulse = 0
    @evidence_text_pulse_speed = 0.08

    setup_trial_scene
    start_trial
  end

  def setup_trial_scene
    # Fondo
    @sprites["background"] = IconSprite.new(0, 0, @viewport)
    @sprites["background"].setBitmap("Graphics/Pictures/juicio/PantallaHablaPersonajesdefault")

    # Título animado
    @sprites["title"] = IconSprite.new(@title_x, 10, @viewport)
    @sprites["title"].setBitmap("Graphics/Pictures/juicio/JuicioEscolarMoviendose")
    @sprites["title"].visible = true
    @sprites["title"].z = 99997

    # Overlay
    @sprites["overlay"] = IconSprite.new(0, 0, @viewport)
    @sprites["overlay"].setBitmap("Graphics/Pictures/juicio/OverlayJuicio")
    @sprites["overlay"].visible = true
    @sprites["overlay"].z = 99998

    # Barra de vida con imágenes
    create_health_overlay

    # Mugshot
    @sprites["mugshot"] = IconSprite.new(8, 121, @viewport)
    @sprites["mugshot"].visible = false

    # Namebox (speaker)
    @sprites["speaker"] = Sprite.new(@viewport)
    @sprites["speaker"].bitmap = Bitmap.new(350, 40)
    @sprites["speaker"].bitmap.font.size = 24
    @sprites["speaker"].bitmap.font.name = "Arial"
    @sprites["speaker"].bitmap.font.color = Color.new(255,255,255)
    @sprites["speaker"].x = 16
    @sprites["speaker"].y = 250
    @sprites["speaker"].visible = true

    # Diálogo
    @sprites["dialogue"] = Window_AdvancedTextPokemon.new("")
    @sprites["dialogue"].viewport = @viewport
    @sprites["dialogue"].width = Graphics.width - 10
    @sprites["dialogue"].height = 140
    @sprites["dialogue"].x = 0
    @sprites["dialogue"].y = Graphics.height - 100
    @sprites["dialogue"].baseColor = Color.new(255,255,255)
    @sprites["dialogue"].shadowColor = Color.new(0,0,0)
    @sprites["dialogue"].windowskin = nil
    @sprites["dialogue"].back_opacity = 0
    @sprites["dialogue"].contents.font.size = 20
    @sprites["dialogue"].contents.font.name = "Arial"
    @sprites["dialogue"].visible = true

    # Indicadores de progreso y controles
    create_progress_indicators

    # Nuevo texto de evidencias animado
    create_evidence_prompt

    setup_trial_dialogues

    # Minijuego Geminis
    #start_puzzle_minigame
  end


  def create_health_overlay
    @sprites["health_overlay"] = IconSprite.new(Graphics.width - 200, 10, @viewport)
    @sprites["health_overlay"].z = 100000
    update_health_display
  end

  def create_progress_indicators
    @sprites["progress_info"] = Sprite.new(@viewport)
    @sprites["progress_info"].bitmap = Bitmap.new(400, 60)
    @sprites["progress_info"].bitmap.font.size = 16
    @sprites["progress_info"].bitmap.font.color = Color.new(255,255,0)
    @sprites["progress_info"].x = 10
    @sprites["progress_info"].y = 50
    @sprites["progress_info"].z = 100001
    
    
   @sprites["c_button_prompt"] = IconSprite.new(Graphics.width - 30, Graphics.height - 20, @viewport)     
   @sprites["c_button_prompt"].setBitmap("Graphics/Pictures/juicio/LetraC")
   @sprites["c_button_prompt"].ox = 16  # 32 / 2
   @sprites["c_button_prompt"].oy = 16  # 32 / 2
   @sprites["c_button_prompt"].visible = false
   @sprites["c_button_prompt"].z = 100003




    # Variables para animación de la tecla C
    @c_button_scale = 1.0
    @c_button_scale_direction = 1
    @c_button_scale_speed = 0.015
  end
def update_progress_indicators
  @sprites["progress_info"].bitmap.clear
  
  if @dialogue_showing
    @sprites["progress_info"].bitmap.font.color = Color.new(255,255,0)
    @sprites["c_button_prompt"].visible = true
    update_c_button_animation
  else
    @sprites["c_button_prompt"].visible = false
  end
end

def update_c_button_animation
  @c_button_scale += @c_button_scale_speed * @c_button_scale_direction
  
  if @c_button_scale >= 1.2
    @c_button_scale_direction = -1
  elsif @c_button_scale <= 0.8
    @c_button_scale_direction = 1
  end
  
  @sprites["c_button_prompt"].zoom_x = @c_button_scale
  @sprites["c_button_prompt"].zoom_y = @c_button_scale
end

  def create_evidence_prompt
    @sprites["evidence_prompt"] = Sprite.new(@viewport)
    @sprites["evidence_prompt"].bitmap = Bitmap.new(350, 40)
    @sprites["evidence_prompt"].bitmap.font.size = 20
    @sprites["evidence_prompt"].bitmap.font.name = "Arial"
    @sprites["evidence_prompt"].bitmap.font.bold = true
    @sprites["evidence_prompt"].x = 140
    @sprites["evidence_prompt"].y = 217
    @sprites["evidence_prompt"].z = 100002
    @sprites["evidence_prompt"].visible = false
  end

  def update_health_display
    health_image = case @player_health
                   when 6 then "OverlayVIDAS6"
                   when 5 then "OverlayVIDAS5"
                   when 4 then "OverlayVIDAS4"
                   when 3 then "OverlayVIDAS3"
                   when 2 then "OverlayVIDAS2"
                   when 1 then "OverlayVIDAS1"
                   when 0 then "OverlayVIDAS0"
                   else "OverlayVIDAS0"
                   end
    
    @sprites["health_overlay"].setBitmap("Graphics/Pictures/juicio/#{health_image}")
    @sprites["health_overlay"].visible = true
  end

 

  
  def update_evidence_prompt
    # Solo mostrar en secciones de debate (bucles)
    should_show = @dialogue_showing && is_debate_section?(@current_section)
    
    return unless should_show

    # Actualizar animación de pulso
    @evidence_text_pulse += @evidence_text_pulse_speed
    @evidence_text_pulse = 0 if @evidence_text_pulse >= Math::PI * 2
    
    # Calcular alpha con efecto de pulso
    pulse_factor = (Math.sin(@evidence_text_pulse) + 1) / 2
    target_alpha = should_show ? 255 : 0
    
    # Fade in/out suave
    if @evidence_text_alpha < target_alpha
      @evidence_text_alpha = [@evidence_text_alpha + @evidence_text_fade_speed, target_alpha].min
    elsif @evidence_text_alpha > target_alpha
      @evidence_text_alpha = [@evidence_text_alpha - @evidence_text_fade_speed, target_alpha].max
    end
    
    # Aplicar pulso al alpha final
    final_alpha = (@evidence_text_alpha * (0.7 + pulse_factor * 0.3)).to_i
    
    # Actualizar sprite
    @sprites["evidence_prompt"].bitmap.clear
    @sprites["evidence_prompt"].bitmap.font.color = Color.new(255, 255, 255, final_alpha)
    @sprites["evidence_prompt"].bitmap.draw_text(0, 10, 350, 25, "Presiona D para abrir el cuaderno de pruebas", 0)
    @sprites["evidence_prompt"].visible = @evidence_text_alpha > 0
  end

  def is_debate_section?(section)
    # Verificar si la sección empieza con "debate_loop"
    section.to_s.start_with?("debate_loop")
  end


   #AMARILLO = #<c3=FFFF00FF,6b6b06FF></c3>
  def setup_trial_dialogues
    @dialogues = [
      # === INTRODUCCIÓN ===
      { speaker: "Hooper-Kuma", text: "Bueno, comencemos con una explicación sencilla del juicio escolar.*Pu* *Pu* *Pu*", mugshot: "MugshootHooper-kuma", section: :intro },
      { speaker: "Hooper-Kuma", text: "Durante el juicio escolar, argumentaréis quién creéis que es el asesino y votaréis al culpable.", mugshot: "MugshootHooper-kuma", section: :intro },
      { speaker: "Hooper-Kuma", text: "Señalad al verdadero culpable, y el solo será castigado. Pero si os equivocáis...", mugshot: "MugshootHooper-kuma", section: :intro },
      { speaker: "Hooper-Kuma", text: "Suspenderéis el juicio escolar y vuestro sueño de ser policia se desvanecerá. *Pu* *Pu* *Pu*", mugshot: "MugshootHooper-kuma", section: :intro },
      { speaker: "Hooper-Kuma", text: "A cambio, el verdadero asesino disfrutará de un mes de vacaciones a cargo de la Academia.", mugshot: "MugshootHooper-kuma", section: :intro },
      { speaker: "Redmond", text: "Solo para asegurarme antes de que empecemos...¿De verdad es uno de nosotros?", mugshot: "MugshootRivalRedmond", section: :intro },
      { speaker: "Hooper-Kuma", text: "Efectivamente. El asesino es uno de los trabajadores de la Academia. A mi no me mires..", mugshot: "MugshootHooper-kuma", section: :intro },
      { speaker: "Hooper-Kuma", text: "En el Juicio Escolar, yo solo soy el moderador. *Pu* *Pu* *Pu*", mugshot: "MugshootHooper-kuma", section: :intro },
      { speaker: "Ailyn", text: "¿¿Como que vamos a empezar?? ", mugshot: "MugshootRivalAilynSorprendia", section: :intro },
      { speaker: "Ailyn", text: "¡Ni siquiera se de que va el crimen!", mugshot: "MugshootRivalAilynSorprendia", section: :intro },
      { speaker: "Redmond", text: "Tampoco esperaba mucha ayuda de ti, Ailyn. ", mugshot: "MugshootRivalRedmond", section: :intro },
      { speaker: "Redmond", text: " No eres precisamente la más lista del grupo.", mugshot: "MugshootRivalRedmond", section: :intro },
      { speaker: "Redmond", text: "Espero que Mara haya hecho los deberes....", mugshot: "MugshootRivalRedmond", section: :intro },
      { speaker: "Mara", text: "Esa no es la mejor forma de decir las cosas, Redmond.", mugshot: "Mugshoot Mara Triste", section: :intro },
      { speaker: "Mara", text: " (Además, yo también estoy un poco perdida.... No se quién ha podido ser. Deberé ordenar mi mente para hallar las respuestas)", mugshot: "MugshootMaraSeria", section: :intro, end_intro: true },
     
      # === BUCLE DE DEBATE PRINCIPAL 0 ===
      { speaker: "Hooper-Kuma", text: "Sin más preámbulos, empecemos con el juicio escolar. *Pu* *Pu* *Pu*", mugshot: "MugshootHooper-kuma", section: :debate_loop, loop_start: true },
      { speaker: "Ailyn", text: "Empezaré yo. Lo primero que debiramos aclarar es..... ", mugshot: "MugshootRivalAilynSonriente", section: :debate_loop },
      { speaker: "Ailyn", text:"¿Cuando empieza la cena?. Tengo ganas de cenar tus platos, chef Pandary.", mugshot: "MugshootRivalAilynSonriente", section: :debate_loop },
      { speaker: "Chef Pandary", text: "¡¡Oh!! Me halagas jovencita. Terminad pronto el juicio escolar y os prepararé un banquete digno de reyes.", mugshot: "MugshootPandary", section: :debate_loop },
      { speaker: "Ailyn", text: "Centremonos entoces, equipo. Estoy con mucha energía y quiero resolver este caso cuanto antes.", mugshot: "MugshootRivalAilynSonriente", section: :debate_loop },
      { speaker: "Redmond", text: "Ahora que Ailyn ha dejado de pensar en comida, podemos empezar. Es imperativo qué se aclaren las dudas respecto al cadáver.", mugshot: "MugshootRivalRedmond", section: :debate_loop },
      { speaker: "Redmond", text: "¿Dónde se cometió el asesinato?", mugshot: "MugshootRivalRedmond", section: :debate_loop },
      { speaker: "Hermano Para", text: "La víctima fue asesinada en la <c3=FFFF00FF,6b6b06FF>Sala de las Taquillas</c3> dónde se guardan los uniformes, por eso había sangre en ella.", mugshot: "MugshootHermanoPara", section: :debate_loop, requires_evidence: true, correct_evidence: "Sala Cadáver" },
      { speaker: "Hermano Doja", text: "Ese sería un buen lugar para cometer el crimen, ya que es una sala donde no hay cámaras de seguridad.", mugshot: "MugshootHermanoDoja", section: :debate_loop },
      { speaker: "Ailyn", text: "Si es un cadaver como el del Inspector Morrigan.... ¡No creo que cupiera en esas taquillas! ja ja ja.", mugshot: "MugshootRivalAilynSonriente", section: :debate_loop },
      { speaker: "Inspector Morrigan", text: "Jovencita, no es momento de bromas a la autoridad.", mugshot: "MugshootInspectorMorrigan", section: :debate_loop },
      { speaker: "Mara", text: "(Entoces.... ¿Donde se encontró el cadáver? Tengo que pensarlo bien)", mugshot: "Mugshoot Mara Triste", section: :debate_loop, loop_back: true },

      # === POST CONTRADICCIÓN 0 SALA CADAVER ===
      { speaker: "Mara", text: "El cadáver fue encontrado en la Sala del Crimen, donde se encontraba Brenda.", mugshot: "MugshootMaraProtesto", section: :post_contradiction },
      { speaker: "Mara", text: "A parte, cuando empezo la prueba Brenda dijo: Os espero en la Sala del crimen.Allí podreís examinar al cadáver.", mugshot: "MugshootMaraSeria", section: :post_contradiction },
      { speaker: "Mara", text: "Yo hubiese pensado en  la Sala de Pintura como si fuese una estatua. ", mugshot: "MugshootRivalAilynSorprendia", section: :post_contradiction },
      { speaker: "Redmond", text: "Menos mal que no eres tu la que elijes.", mugshot: "MugshootRivalRedmond", section: :post_contradiction },
      { speaker: "Profesor Clover", text: "Entoces fue Brenda quien cometió el asesinato.", mugshot: "MugshootProfesorClover", section: :post_contradiction},
      { speaker: "Conserje Jensen", text: "Y encima tengo que recogerlo yo luego.", mugshot: "MugshootConserjeJensen", section: :post_contradiction },
      { speaker: "Redmond", text: "Muy bien, Mara.", mugshot: "MugshootRivalRedmond", section: :post_contradiction},
      { speaker: "Hermano Doja", text: "¡Oye! A lo mejor movieron el cadáver a la  Sala de las Taquillas como decía mi hermano y lo encontrasteis en la Sala del Crimen.", mugshot: "MugshootHermanoDoja", section: :post_contradiction},
      { speaker: "Redmond", text: "Si se hubiese dado ese vaticinio, habría múltiples rastros de sangre, y no es el caso. Calla o aporta algo útil ", mugshot: "MugshootRivalRedmond", section: :post_contradiction},
      { speaker: "Hooper-Kuma", text: "Efectivamente, el cadáver estaba en la Sala del Crimen donde se encontraba Brenda.", mugshot: "MugshootHooper-kuma", section: :post_contradiction},
      { speaker: "Ailyn", text: "¡Toma ya! Sigamos así chicos y en nada cenamos.*Pu* *Pu* *Pu*", mugshot: "MugshootRivalAilynSonriente", section: :post_contradiction},
     
      # === PRIMER BUCLE DE DEBATE 1 ===
      { speaker: "Redmond", text: "Ahora que hemos aclarado el lugar, hablemos del arma del crimen.", mugshot: "MugshootRivalRedmond", section: :debate_loop_1, loop_start: true },
      { speaker: "Conserje Jensen", text: "La victima fue asesinada seguramente con algún cuchillo o elemento de la Cocina.", mugshot: "MugshootConserjeJensen", section: :debate_loop_1 },
      { speaker: "Conserje Jensen", text: "Son típicos los asesinatos con ellos, además de que se pueden esconder fácilmente y a simple vista.", mugshot: "MugshootConserjeJensen", section: :debate_loop_1 },
      { speaker: "Chef Pandary", text: "¡Imposible! Mis cuchillos están todos en su sitio y no hay rastro de sangre en ellos.", mugshot: "MugshootPandary", section: :debate_loop_1 },
      { speaker: "Dino Lobo de Mar", text: "La víctima fue asesinada por la espalda por <c3=FFFF00FF,6b6b06FF> algo contundente en la cabeza/c3>.", mugshot: "MugshootDino", section: :debate_loop_1, requires_evidence: true, correct_evidence: "Traumatismo" },
      { speaker: "Hermano Para", text: "O.... le tiraron contra la pared. A veces pasa.", mugshot: "MugshootHermanoPara", section: :debate_loop_1 },
      { speaker: "Hermano Doja", text: "Pero para eso debe ser contundente, y estas paredes.... Se hiceron con material barato, hermano.", mugshot: "MugshootHermanoPara", section: :debate_loop_1 },
      { speaker: "Redmond", text: "Vosotros dos si que os habeís dado fuerte contra la pared. Vaya par de inutiles.", mugshot: "MugshootRivalRedmond", section: :debate_loop_1, loop_back: true },

      # === POST CONTRADICCIÓN 1 TRAUMATISMO ===
      { speaker: "Mara", text: "La victima sufrió un #<c3=FFFF00FF,6b6b06FF>traumatismo en la cabeza</c3> por la espalda con algo contundente. ", mugshot: "MugshootMaraProtesto", section: :post_contradiction_1},
      { speaker: "Profesor Clover", text: "Ya lo decia el dicho: Es importante tener las espaldas cubiertas. ", mugshot: "MugshootProfesorClover", section: :post_contradiction_1},
      { speaker: "Ailyn", text: "Es mejor tener el estomago cubierto. *Je* *Je* *Je* ", mugshot: "MugshootRivalAilynSonriente", section: :post_contradiction_1},
      { speaker: "Chef Pandary", text: "Eso es lo más importante de todo.", mugshot: "MugshootPandary", section: :post_contradiction_1},
       { speaker: "Hooper-Kuma", text: "Otro acierto más. *Pu* *Pu* *Pu*  Vais por buen camino.", mugshot: "MugshootHooper-kuma", section: :post_contradiction_1 },
      { speaker: "Redmond", text: "¿Que fue lo que usó el asesino para producir ese traumatismo? ", mugshot: "MugshootRivalRedmond", section: :post_contradiction_1},

      # === SEGUNDO BUCLE DE DEBATE 2 ===

      { speaker: "Dino Lobo de Mar", text: "Seguramente con una <c3=FFFF00FF,6b6b06FF>pala para plantar árboles/c3>.", mugshot: "MugshootDino", section: :debate_loop_2, requires_evidence: true, correct_evidence: "Barra de Metal" },
      { speaker: "Artista Evie", text: "¡Qué inspiradourr! Me ha dadoo una idea para un retratou. Lo llamage Le barre del amour y de la vie.", mugshot: "MugshootArtistaEvie", section: :debate_loop_2 },
      { speaker: "Jardinero Elisio", text: "¡Mis herramientas no son para eso!", mugshot: "MugshootJardinero", section: :debate_loop_2 },
      { speaker: "Inspector Morrigan", text: "Yo alguna vez las he usado para rascarme la espalda con ellas. *je* *je*", mugshot: "MugshootInspectorMorrigan", section: :debate_loop_2 },
      { speaker: "Ailyn", text: "Entonces... ¿Qué arma se usó realmente?", mugshot: "MugshootRivalAilynSorprendia", section: :debate_loop_2, loop_back: true },

      # === POST CONTRADICCIÓN BARRA DE METAL 2 ===
      { speaker: "Mara", text: "El asesino mató a la víctima con una barra de metal.", mugshot: "MugshootMaraProtesto", section: :post_contradiction_2 },
      { speaker: "Profesor Clover", text: "El jardinero Elisio seguro que la utiliza para enderezar las plantas.", mugshot: "MugshootProfesorClover", section: :post_contradiction_2 },
      { speaker: "Jardinero Elisio", text: "Con eso no se puede enderezar las plantas. Además no tengo ninguna barra de metal en mis bayeros.", mugshot: "MugshootJardinero", section: :post_contradiction_2 },
      { speaker: "Conserje Jensen", text: "Eso es mentira. Usas una para hacer agüjeros perfectos en la tierra.", mugshot: "MugshootConserjeJensen", section: :post_contradiction_2 },
      { speaker: "Ayudante Brenda", text: "Algo falla en tu argumento, Mara. ", mugshot: "", section: :post_contradiction_2 },
      { speaker: "Ayudante Brenda", text: "Una barra de metal sería dificil de esconder a simple vista.", mugshot: "MugshootAyudanteBrendaSeria", section: :post_contradiction_2 },
      { speaker: "Mara", text: "Efectivamente. Estaba escondida a simple vista. Estaba en un cubo simulando ser una fregona. Además el agua estaba con un color rojizo.", mugshot: "", section: :post_contradiction_2 },
      { speaker: "Hooper-Kuma", text: "Otro acierto más. *Pu* *Pu* *Pu*  No os olvideis de los que llevaís.", mugshot: "MugshootHooper-kuma", section: :post_contradiction_2 },
     
      # === TERCER BUCLE DE DEBATE 3 ===
      { speaker: "Ailyn", text: "Genial, equipo. Seguimagos con nuestra racha.", mugshot: "MugshootRivalAilynSonriente", section: :debate_loop_3, loop_start: true },
      { speaker: "Ailyn", text: "De momento, para que me entere.... La víctima murió en la sala del crimen por la barra de metal, pero entoces.... ¿No habría huellas en ella?", mugshot: "MugshootRivalAilyn", section: :debate_loop_3},
      { speaker: "Inspector Morrigan", text: "El asesino pudo haberlas limpiado. Es algo normal en la serie de asesinatos que veo.   ", mugshot: "MugshootHermanoDoja", section: :debate_loop_3},
      { speaker: "Ailyn", text: "Esas series molán mucho. Sobretodo, una que veo de un niño pequeño con un traje y una pajarita roja que ayuda a su tio a resolver los casos. ", mugshot: "MugshootRivalAilynSonriente", section: :debate_loop_3},
      { speaker: "Recepcionista Litty", text: "Yo si hubiese sido la asesina seguramente se me pasaría limpiarlas. *Ja* *Ja* *Ja* ", mugshot: "MugshootRecepcionistaLitty", section: :debate_loop_3},
      { speaker: "Recepcionista Litty", text: "Menos mal que tendría a Vitty para ayudarme con eso.  ", mugshot: "MugshootRecepcionistaLitty", section: :debate_loop_3},
      { speaker: "Recepcionista Vitty", text: "Como siempre, tendría que decirte lo que hacer. Sin mi no sabrías hacer nada, hermana. ", mugshot: "MugshootRecepcionistaVitty", section: :debate_loop_3},
      { speaker: "Recepcionista Litty", text: "No me preocupa,Vitty. Me gusta hacerlo todo juntas. ", mugshot: "MugshootRecepcionistaLitty", section: :debate_loop_3},
      { speaker: "Redmond", text: "Dejando a un lado esta entrañable conversación entre hermanas....<c3=FFFF00FF,6b6b06FF>¿Por qué no hay huellas en la barra de metal?</c3> ", mugshot: "MugshootRivalRedmond", section: :debate_loop_3,requires_evidence: true, correct_evidence: "Guantes" },
      { speaker: "Mara", text: "(Entoces.... ¿Qué uso el asesino para no dejar huellas en la barra de metal? Tengo que pensarlo bien)", mugshot: "Mugshoot Mara Triste", section: :debate_loop_3, loop_back: true },
   
      # === POST CONTRADICCIÓN GUANTES 3 ===
      { speaker: "Mara", text: "El asesino utilizó guantes de jardineria para no dejar huellas en la barra de metal.", mugshot: "MugshootMaraProtesto", section: :post_contradiction_3 },
      { speaker: "Profesor Clover", text: "Vaya,vaya.... Otra prueba que incrimina al Jardinero Elisio...", mugshot: "MugshootProfesorClover", section: :post_contradiction_3 },
      { speaker: "Jardinero Elisio", text: "¡Deja de incriminarme! ¡Soy inocente! Con lo agusto que estaba yo con mis plantitas... Y tengo que estar aqui. *Ains*", mugshot: "MugshootJardinero", section: :post_contradiction_3 },
      { speaker: "Jardinero Elisio", text: "Hablando de Plantitas... Tu Trébol estaba en el Almacen de Comida. Eso es muy sospechoso.", mugshot: "MugshootJardinero", section: :post_contradiction_3 },
      { speaker: "Profesor Clover", text: "¡Lo han puesto ahí para incriminarme!", mugshot: "MugshootProfesorClover", section: :post_contradiction_3 },
      { speaker: "Jardinero Elisio", text: "Parece que no nos libranos ninguno de las acusaciones.", mugshot: "MugshootJardinero", section: :post_contradiction_3 },
      { speaker: "Ailyn", text: "Bueno, chicos, cada vez estamos más cerca de encontrar al asesino.", mugshot: "MugshootRivalAilynSonriente", section: :post_contradiction_3 },
      { speaker: "Redmond", text: "No te precipites,Ailyn.", mugshot: "MugshootRivalRedmond", section: :post_contradiction_3 },
      { speaker: "Hooper-Kuma", text: "Otro acierto más. *Pu* *Pu* *Pu* ", mugshot: "MugshootHooper-kuma", section: :post_contradiction_3 },

      # ===  CUARTO BUCLE DE DEBATE 4 ===
      { speaker: "Artista Evie", text: " Menoss mal qeu los artistes no tenemos qeu usag guantes paga pintag.", mugshot: "MugshootArtistaEvie", section: :debate_loop_4, loop_start: true },
      { speaker: "Artista Evie", text: " Nosotros los agtistas, solemos utilizag batas para pintag los cuadros,pego yo lo hago desnuda. ", mugshot: "MugshootArtistaEvie", section: :debate_loop_4, },
      { speaker: "Hermano Para", text: "Habrá que ver como pintas tus increibles cuadros, Evie.", mugshot: "MugshootHermanoPara", section: :debate_loop_4, },
      { speaker: "Hermano Doja", text: "Para nosotros dos sería un gran orgulloso poder ver todo el proceso que lleva.", mugshot: "MugshootHermanoDoja", section: :debate_loop_4, },
      { speaker: "Artista Evie", text: "Pog supuesto, Chicos. Siempre doy la bienvenie a quién quiege disfrutag del agtee.", mugshot: "MugshootArtistaEvie", section: :debate_loop_4, },
      { speaker: "Hermano Para", text: "(Nosotros si que disfrutariamos del arte *je* *je* *je*)", mugshot: "MugshootHermanoPara", section: :debate_loop_4, },
      { speaker: "Ailyn", text: " Ahora qué hablas de batas, Evie. ¿No había una bata manchada en la Sala de Pintura de morado?", mugshot: "MugshootRivalAilynSorprendia", section: :debate_loop_4, },
      { speaker: "Redmond", text: "Veo que a veces te fijas en las cosas, Ailyn. Quién lo diria....", mugshot: "MugshootRivalRedmond", section: :debate_loop_4, },
      { speaker: "Artista Evie", text: "¿Cómo ess possiblee? Si yo pinto desnuda. ", mugshot: "MugshootArtistaEvie", section: :debate_loop_4, },
      { speaker: "Artista Evie", text: "<c3=FFFF00FF,6b6b06FF>Algún alumno la habgá utigizado</c3> para pintag.", mugshot: "MugshootArtistaEvie", section: :debate_loop_4, requires_evidence: true, correct_evidence: "Bote Pintura"  },
      { speaker: "Profesor Clover", text: "O lo habrá usado el Chef Pandary a modo de delantal.", mugshot: "MugshootProfesorClover", section: :debate_loop_4, },
      { speaker: "Mara", text: "(Entoces.... ¿Por qué se manchó la bata? Tengo que pensarlo bien)", mugshot: "Mugshoot Mara Triste", section: :debate_loop_4, loop_back: true },
 
      
      # === POST CONTRADICCIÓN BOTE DERRAMADO 4 ===
      { speaker: "Mara", text: "La bata fue manchada por el bote derramado de pintura. Eso es seguro.", mugshot: "MugshootMaraProtesto", section: :post_contradiction_4 },
      { speaker: "Ailyn", text: "Y... ¿Qué pasó?", mugshot: "MugshootRivalAilyn", section: :post_contradiction_4 },
      { speaker: "Dino Lobo de Mar", text: "Seguramente fue sin querer.", mugshot: "MugshootDino", section: :post_contradiction_4 },
      { speaker: "Dino Lobo de Mar", text: "El asesino entraría a la Sala de pintura a por una Bata, para no mancharse con el crimen.", mugshot: "MugshootDino", section: :post_contradiction_4 },
      { speaker: "Dino Lobo de Mar", text: "Pero algo paso para que no la cogiera y derramara el bote.", mugshot: "MugshootDino", section: :post_contradiction_4 },
      { speaker: "Redmond", text: "Se encontró con la Artista Evie observando el mural con el mensaje: La Luz ilumina el camino.", mugshot: "MugshootRivalRedmond", section: :post_contradiction_4 },
      { speaker: "Redmond", text: "Como Evie estaba absorta con el mensaje, chocó con el bote abierto y manchó accidentalmente la bata que iba a usar el asesino.", mugshot: "MugshootRivalRedmond", section: :post_contradiction_4 },
      { speaker: "Redmond", text: "Por tanto, el asesino fue a encontrar otra forma de no mancharse con el crimen.", mugshot: "MugshootRivalRedmond", section: :post_contradiction_4 },


      # ===  QUINTO BUCLE DE DEBATE 5 ===
      { speaker: "Dino Lobo de Mar", text: " Por eso no utilizó la bata para el asesinato. Muy astuto, Redmond.", mugshot: "MugshootDino", section: :debate_loop_5, loop_start: true },
      { speaker: "Ailyn", text: "Entonces.... ¿Qué es lo que pudo haber #<c3=FFFF00FF,6b6b06FF>utilizado</c3>?", mugshot: "MugshootRivalAilyn", section: :debate_loop_5,  requires_evidence: true, correct_evidence: "Uniforme XXL"  },
      { speaker: "Ailyn", text: "A mí se me ocurre que al principio del debate, se dijo que una de las taquillas estaba manchada… Pero... ¿Por qué? ", mugshot: "MugshootRivalAilyn", section: :debate_loop_5, },
      { speaker: "Profesor Clover", text: "Quizás Evie quiso darle un toque artístico a la taquilla. ", mugshot: "MugshootProfesorClover", section: :debate_loop_5, },
      { speaker: "Artista Evie", text: "Yo sogo pinto cuadruos, jovie. No pinto taquilas ni otgas cosas. Sogo cuadruos.", mugshot: "MugshootArtistaEvie", section: :debate_loop_5, },
      { speaker: "Hermano Para", text: "Os lo dije, eso es por que el cadáver estaba dentro de la taquilla, y por eso salía la sangre de ella..", mugshot: "MugshootHermanoPara", section: :debate_loop_5, },
      { speaker: "Hermano Doja", text: "¡Entoces mi Hermano tenía la razón!", mugshot: "MugshootHermanoDoja", section: :debate_loop_5, },
      { speaker: "Ayudante Brenda", text: "Otra cosa qué no has limpiado, Jensen.", mugshot: "MugshootAyudanteBrendaSeria", section: :debate_loop_5, },
      { speaker: "Conserje Jensen", text: "Me llevó mucho tiempo lo qué me pidió, la Recepcionista Vitty.", mugshot: "MugshootConserjeJensen", section: :debate_loop_5, },
      { speaker: "Ayudante Brenda", text: " Sigue sin hacer tu trabajo, que durará más el juicio qué tu trabajo con nosotros..", mugshot: "MugshootAyudanteBrendaSeria", section: :debate_loop_5, },
      { speaker: "Mara", text: "(Entoces.... ¿Qué usó el asesino para no mancharse con el crimen? Tengo que pensarlo bien)", mugshot: "Mugshoot Mara Triste", section: :debate_loop_5, loop_back: true },


      # === POST CONTRADICCIÓN UNIFORME XXL 5 ===
      { speaker: "Mara", text: " Como se ha comentado antes, el cadáver estaba en la sala del crimen, lo que contenía la taquilla manchada es un uniforme de policía de la talla XXL. ", mugshot: "MugshootMaraProtesto", section: :post_contradiction_5 },
      { speaker: "Hermano Para", text: " Pues eso. Qué algo había ahí dentro. ", mugshot: "MugshootHermanoPara", section: :post_contradiction_5 },
      { speaker: "Ailyn", text: " Pero no el cadáver.  *Pu* *Pu* *Pu* ", mugshot: "MugshootRivalAilynSonriente", section: :post_contradiction_5 },
      { speaker: "Redmond", text: " Seguir con el debate. Ya han hecho su alivio cómico. ", mugshot: "MugshootRivalRedmond", section: :post_contradiction_5 },
      { speaker: "Inspector Morrigan", text: " Como iba a decir, ese uniforme no es mio. Yo le llevo puesto.", mugshot: "MugshootInspectorMorrigan", section: :post_contradiction_5 },
      { speaker: "Chef Pandary", text: "Es uno de tus Uniformes de Repuesto. Tienes 3, el que llevas puesto, el que se está lavando manchado de salsa de Tacos y este de la Taquilla ensangrentado.", mugshot: "MugshootPandary", section: :post_contradiction_5 },
      { speaker: "Mara", text: "Es de la sangre de la Víctima.Por lo tanto, es lo que usó el asesino para no mancharse con el crimen, aunque observando bien el uniforme.... ", mugshot: "MugshootMaraProtesto", section: :post_contradiction_5 },
      { speaker: "Mara", text: "Le quedaba demasiado grande. ", mugshot: "MugshootMaraSeria", section: :post_contradiction_5 },
      { speaker: "Ailyn", text: " Y.... ¿Cómo sabía el asesino la contraseña de la taquilla? ", mugshot: "MugshootRivalAilyn", section: :post_contradiction_5 },
      { speaker: "Redmond", text: "Hay poca gente que lo sepa. Descubridlo. ", mugshot: "MugshootRivalRedmond", section: :post_contradiction_5 },
      { speaker: "Mara", text: "Que sepamos, el Chef Pandary comentó en el Comedor: Siempre le tengo que llevar la comida y la ropa de recambio a su despacho. ", mugshot: "MugshootMaraProtesto", section: :post_contradiction_5 },
      { speaker: "Ailyn", text: " Pero también el Inspector Morrigan le entregó una hoja con la contraseña en el Comedor. ", mugshot: "MugshootRivalAilyn", section: :post_contradiction_5 },
      { speaker: "Mara", text: "Como dijo, Redmond, las personas que lo saben no necesitarían un papel con la contraseña,segurante las recepcionistas lo sepan y quizas... ¿Brenda? ", mugshot: "MugshootMaraProtesto", section: :post_contradiction_5 },
      { speaker: "Ayudante Brenda", text: "Efectivamente. Se su contraseña, como todo de el, pero yo no iría a su taquilla si necesitase su uniforme.", mugshot: "MugshootAyudanteBrendaSeria", section: :post_contradiction_5 },
      { speaker: "Ayudante Brenda", text: " Yo lo cogería del despacho directamente, como..... ¡Su ropa interior sudada! *Mmm*  ", mugshot: "MugshootAyudanteBrendaSeria", section: :post_contradiction_5 },
      { speaker: "Ailyn", text: "*Puaj* Es verdad que los tenia en su habitación... ", mugshot: "MugshootRivalAilyn", section: :post_contradiction_5 },
      { speaker: "Dino Lobo de Mar", text: "Os estaís desviando. Os voy a ayudar.", mugshot: "MugshootDino", section: :post_contradiction_5 },
      { speaker: "Dino Lobo de Mar", text: "El asesino después de asesinar a la víctima dejó el uniforme en su sitio para evitar qué lo encontrásemos, con la mala suerte de qué estaba empapado de sangre y chorreaba por las rendijas de la taquilla. ", mugshot: "MugshootDino", section: :post_contradiction_5 },
      { speaker: "Hooper-Kuma", text: "Otro acierto más. Pero, no les ayudes más, Dino. Ultimo aviso.", mugshot: "MugshootHooper-kuma", section: :post_contradiction_5 },

      # ===  SEXTO BUCLE DE DEBATE 6 ===
      { speaker: "Ailyn", text: "¡¡Ya nos quedan pocas pistas, chicos!!  ", mugshot: "MugshootRivalAilyn", section: :debate_loop_6, loop_start: true },
      { speaker: "Ailyn", text: "Había una sala qué estaba cerrada. No pude entrar ni pegando patadas.", mugshot: "MugshootRivalAilyn", section: :debate_loop_6,},
      { speaker: "Conserje Jensen", text: "¡Oye! ¡No intentes romper el inmobiliario de la Academia!", mugshot: "MugshootConserjeJensen", section: :debate_loop_6,},
      { speaker: "Profesor Clover", text: "Yo si pude entrar. Pero... #<c3=FFFF00FF,6b6b06FF>no precisamente por la puerta</c3>.", mugshot: "MugshootProfesorClover", section: :debate_loop_6, requires_evidence: true, correct_evidence: "Conducto" },
      { speaker: "Ailyn", text: "Entonces no me lo explico.", mugshot: "MugshootRivalAilyn", section: :debate_loop_6,},
      { speaker: "Mara", text: "(Entonces.... ¿Por dónde entró el Profesor Clover a la Sala Cerrada? Tengo que pensarlo bien)", mugshot: "Mugshoot Mara Triste", section: :debate_loop_6, loop_back: true },

      # === POST CONTRADICCIÓN CONDUCTO 6 ===
      { speaker: "Mara", text: "Clover entró por el Conducto de Ventilación, al igual que yo. ", mugshot: "MugshootMaraProtesto", section: :post_contradiction_6 },
      { speaker: "Redmond", text: "No habéis sido los únicos. ¿Por qué crees que estaba allí?", mugshot: "MugshootRivalRedmond", section: :post_contradiction_6 },
      { speaker: "Profesor Clover", text: "La verdad que el Conducto estaba bastante limpio. Como si alguien ya lo hubiese usado antes que nosotros.", mugshot: "MugshootProfesorClover", section: :post_contradiction_6 },
      { speaker: "Ayudante Brenda", text: "Diría que Jensen no lo ha limpiado nunca.", mugshot: "MugshootAyudanteBrendaSeria", section: :post_contradiction_6 },
      { speaker: "Ailyn", text: "Entonces lo usó el asesino para entrar a la Sala Cerrada, como vosotros.", mugshot: "MugshootRivalAilyn", section: :post_contradiction_6 },
     
      # ===  SEPTIMO BUCLE DE DEBATE 7 ===
      { speaker: "Profesor Clover", text: "En la Sala Cerrada, había varias cosas: Una Llave Maestra,Un Plano del Sótano y un Plan de Asesinato.", mugshot: "MugshootProfesorClover", section: :debate_loop_7, loop_start: true },
      { speaker: "Profesor Clover", text: "El Plano del Sótano y el Plan de Asesinato no me interesaron mucho, lo que si usé fue una #<c3=FFFF00FF,6b6b06FF>Llave</c3> para salir de la Sala.", mugshot: "MugshootProfesorClover", section: :debate_loop_7,requires_evidence: true, correct_evidence: "Llave Maestra" },
      { speaker: "Redmond", text: "Es una Llave Maestra de la Academia Eón. Con ella se abren todas las puertas. Cuando acabe el juicio, deberías probarla,Mara.", mugshot: "MugshootRivalRedmond", section: :debate_loop_7,},
      { speaker: "Ailyn", text: "Muy sospechoso que estuvieses tu solo en esa sala.", mugshot: "MugshootRivalAilyn", section: :debate_loop_7,},
      { speaker: "Conserje Jensen", text: "¡Oye! ¡Esa es mi Llave! ¡Devuélvela!", mugshot: "MugshootConserjeJensen", section: :debate_loop_7,},
      { speaker: "Mara", text: "(Entonces.... ¿Cómo salió el Profesor Clover de la Sala Cerrada? Tengo que pensarlo bien)", mugshot: "Mugshoot Mara Triste", section: :debate_loop_7, loop_back: true },

      # === POST CONTRADICCIÓN LLAVE MAESTRA 7 ===
      { speaker: "Mara", text: "Exacto. El asesino usó la llave maestra para abrir la puerta de la Sala Cerrada, pero previamente, había entrado en la Sala Vacía metiéndose por el Conducto hacia la Sala Cerrada.", mugshot: "MugshootMaraProtesto", section: :post_contradiction_7 },
      { speaker: "Mara", text: "Pero antes de salir, observó el Plano del Sótano y cómo tenía que realizar el Plan de Asesinato.", mugshot: "MugshootMaraSonriente", section: :post_contradiction_7 },
      { speaker: "Redmond", text: "Acordaos, del Mechón de Pelo que se encontraba fuera del conducto. No habéis hablado de ello. ", mugshot: "MugshootRivalRedmond", section: :post_contradiction_7 },
      { speaker: "Ailyn", text: "Pero ese Mechón de Pelo no nos dice nada si no sabemos de quién es.", mugshot: "MugshootRivalAilyn", section: :post_contradiction_7,},
      { speaker: "Redmond", text: "Pero te ayuda a descartar sospechosos. Ya sabéis que quién no tenga pelo no pudieron ser los asesinos. ", mugshot: "MugshootRivalRedmond", section: :post_contradiction_7 },
      { speaker: "Hermano Doja", text: "Con una peluca bastaría para romper tu argumento.", mugshot: "MugshootHermanoDoja", section: :post_contradiction_7,},
      { speaker: "Redmond", text: "Ya te gustaría que ocurriese eso. Pero el Mechón era de pelo natural.", mugshot: "MugshootRivalRedmond", section: :post_contradiction_7 },
      { speaker: "Redmond", text: "Última pista que os doy. La clave para resolver el caso se encuentra en el Mensaje Póstumo.", mugshot: "MugshootRivalRedmond", section: :post_contradiction_7 },
      { speaker: "Mara", text: "Voy a concentrarme en mi mente a ver si soy capaz de averiguarlo.", mugshot: "MugshootMaraSeria", section: :post_contradiction_7 },
      ]  

    # Mapear índices de bucles por sección
    @dialogues.each_with_index do |dialogue, index|
      if dialogue[:loop_start]
        @loop_sections[dialogue[:section]] = index
      end
    end
  end

  def start_trial
    @dialogue_index = 0
    @current_section = :intro
    @intro_completed = false
    show_next_dialogue
  end

  def show_next_dialogue
    return end_trial_success if @dialogue_index >= @dialogues.length

    entry = @dialogues[@dialogue_index]
    
    # Actualizar sección actual
    @current_section = entry[:section] if entry[:section]
    
    # Marcar intro como completada
    @intro_completed = true if entry[:end_intro]

    # Speaker
    @sprites["speaker"].bitmap.clear
    @sprites["speaker"].bitmap.draw_text(0,5,400,50,entry[:speaker],0)
    @sprites["speaker"].visible = true

        # Mugshot
    if entry[:mugshot]
      @sprites["mugshot"].setBitmap("Graphics\\Pictures\\juicio\\#{entry[:mugshot]}")
      @sprites["mugshot"].visible = true
    else
      @sprites["mugshot"].visible = false
    end

    # Texto
   
    @sprites["dialogue"].text = entry[:text]
    @sprites["dialogue"].visible = true

    # Lógica de contradicción y bucles
    if entry[:requires_evidence]
      @waiting_for_contradiction = true
    elsif entry[:loop_back]
      if !all_contradictions_resolved_in_section(@current_section)
        jump_to_loop_start(@current_section)
        return
      end
    end

    @dialogue_showing = true
  end

  def all_contradictions_resolved_in_section(section)
    section_contradictions = @dialogues.select { |d| d[:section] == section && d[:requires_evidence] }
    resolved_in_section = @contradictions_resolved.select { |c| c[:section] == section }
    
    return resolved_in_section.length >= section_contradictions.length
  end

  def jump_to_loop_start(section)
    if @loop_sections[section]
      @dialogue_index = @loop_sections[section]
      show_next_dialogue
    else
      advance_to_next_dialogue
    end
  end

  def advance_to_next_dialogue
    @dialogue_index += 1
    @dialogue_showing = false
    @waiting_for_contradiction = false
    show_next_dialogue
  end

  def open_evidence_menu
    menu = EvidenceNotebookMenu.new
    selected = menu.main
    menu.dispose
    selected
  end

  def handle_contradiction
    entry = @dialogues[@dialogue_index]
    
    selected_evidence = open_evidence_menu

    if entry[:requires_evidence] && selected_evidence && selected_evidence == entry[:correct_evidence]
      pbPlayDecisionSE
      pbMessage("\\PN[¡CORRECTO! Esa es la evidencia que contradice la declaración!]")
      @contradictions_resolved << entry
      @waiting_for_contradiction = false
      advance_to_next_dialogue
      true
    elsif entry[:requires_evidence] && selected_evidence && selected_evidence != entry[:correct_evidence]
      pbPlayBuzzerSE
      @player_health -= 1
      update_health_display
      if @player_health <= 0
        end_trial_failure
        return false
      else
        pbMessage("\\PN[Esa no es la prueba correcta... Pierdes vida!]")
        @waiting_for_contradiction = false
        if @intro_completed
          jump_to_loop_start(@current_section)
        else
          @dialogue_index = 0
          show_next_dialogue
        end
        return false
      end
    elsif selected_evidence
      pbPlayBuzzerSE
      @player_health -= 1
      update_health_display
      if @player_health <= 0
        end_trial_failure
        return false
      else
        pbMessage("\\PN[No hay contradicción en este momento. ¡Pierdes vida por presentar evidencia incorrectamente!]")
        return false
      end
    else
      return false
    end
  end

  def end_trial_success
    pbMessage("\\PN[¡Excelente trabajo! Has resuelto el caso correctamente.]")
    @trial_completed = true
  end

  def end_trial_failure
    pbMessage("\\PN[¡Te has quedado sin vida! Volviendo al menú principal...]")
    @trial_completed = false
  end

  def update_title_animation
    @title_x += @title_speed
    @sprites["title"].x = @title_x
    if @title_x < @title_fade_start
      @sprites["title"].opacity = 255
    elsif @title_x < @title_reset_x
      fade_distance = @title_reset_x - @title_fade_start
      current_fade_progress = (@title_x - @title_fade_start).to_f / fade_distance
      @sprites["title"].opacity = (255*(1-current_fade_progress)).to_i
    else
      @title_x = -400
      @sprites["title"].x = @title_x
      @sprites["title"].opacity = 255
    end
  end

  def update
    Graphics.update
    Input.update
    update_title_animation
    update_progress_indicators
    update_evidence_prompt

    return false if @player_health <= 0
    return false if @trial_completed != nil

    if @dialogue_showing
      # Tecla Z solo para evidencias y solo en secciones de debate
      if Input.trigger?(Input::Z) && is_debate_section?(@current_section)
        handle_contradiction
      end

      # Tecla C para avance manual
      if Input.trigger?(Input::C)
        advance_to_next_dialogue
      end
    end

    true
  end

  def main
    loop { break unless update }
    dispose
    return @trial_completed
  end

  def dispose
    @sprites.each_value { |s| s&.dispose }
    @sprites.clear
    @viewport&.dispose
  end
end

#===============================================================================
# Menú del Cuaderno de Evidencias Mejorado
#===============================================================================
class EvidenceNotebookMenu
  def initialize
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @index = 0
    @showing_details = false
    @selected_evidence = nil

    @evidence_list = [
      { name: "Sala Cadáver", brief_description: "El cadáver fue encontrado en la sala de Brenda.", detailed_description: "El cadáver fue encontrado en la sala de Brenda. La víctima presenta una herida en la cabeza, producida por un objeto contundente. No hay signos de lucha, lo que sugiere que la víctima fue sorprendida.", image_selected: "Graphics/Pictures/juicio/CuardernoJuicioSelecCadaver", image_normal: "Graphics/Pictures/juicio/CuardernoJuicio" },
      { name: "Barra de Metal", brief_description: "Una Barra metálica con rastros de sangre.", detailed_description: "Una Barra metálica con rastros de sangre. Encontrada como si fuese una fregona. No hay huellas en ella, lo que indica que el asesino usó \\c[2]guantes\\c[0] o limpió el arma después del ataque.", image_selected: "Graphics/Pictures/juicio/CuardernoJuicioSelecBarrar", image_normal: "Graphics/Pictures/juicio/CuardernoJuicio" },
      { name: "Traumatismo", brief_description: "Evidencia médica que indica traumatismo severo en la cabeza de la víctima", detailed_description: "Evidencia médica que indica traumatismo severo en la cabeza de la víctima. La herida fue causada con un objeto contundente.Parece que la víctima fue atacada por la espalda.", image_selected: "Graphics/Pictures/juicio/CuardernoJuicioSelecTraumatismor", image_normal: "Graphics/Pictures/juicio/CuardernoJuicio" },
      { name: "Uniforme XXL", brief_description: "Uniforme de Morrigan de talla XXL ensangrentado.", detailed_description: "Uniforme de Morrigan de talla XXL ensangrentado.Fue encontrado en su taquilla. Las manchas de sangre indican que fue usado durante el asesinato por alguien que no esta acostumbrado a los uniformes.", image_selected: "Graphics/Pictures/juicio/CuardernoJuicioSelecUniforme", image_normal: "Graphics/Pictures/juicio/CuardernoJuicio" },
      { name: "Bote Pintura", brief_description: "Bote de pintura desparramado en la Sala de Pintura.", detailed_description: "Bote de pintura desparramado en la Sala de Pintura.Parece que el asesino derramo el bote sin querer y manchó algo.", image_selected: "Graphics/Pictures/juicio/CuardernoJuicioSelecBote", image_normal: "Graphics/Pictures/juicio/CuardernoJuicio" },
      { name: "Bata Manchada", brief_description: "Bata Manchada de la Sala de Pintura.", detailed_description: "Bata Manchada de la Sala de Pintura. Las manchas han sido identificadas con pintura morada. Seguramente fue salpicada por el bote de pintura derramado.", image_selected: "Graphics/Pictures/juicio/CuardernoJuicioSelecBata", image_normal: "Graphics/Pictures/juicio/CuardernoJuicio" },
      { name: "Mensaje Póstumo", brief_description: "Un mensaje dejado por la víctima antes de su muerte.", detailed_description: "Un mensaje dejado por la víctima antes de su muerte. Las palabras escritas con sangre podrían revelar la identidad del asesino.", image_selected: "Graphics/Pictures/juicio/CuardernoJuicioSelecMensaje", image_normal: "Graphics/Pictures/juicio/CuardernoJuicio" },
      { name: "Mechón Largo", brief_description: "Mechón largo de pelo encontrado en la sala Vacia.", detailed_description: "Mechón largo de pelo encontrado en la sala Vacia. El mechón parece que voló desde el conducto de ventilación. No se puede saber de quién es.", image_selected: "Graphics/Pictures/juicio/CuardernoJuicioSelecMechon", image_normal: "Graphics/Pictures/juicio/CuardernoJuicio" },
      { name: "Conducto", brief_description: "Sistema de conducto de ventilación.", detailed_description: "Sistema de conducto de ventilación. Podría haber sido usado por el asesino para volver a la sala Vacia.", image_selected: "Graphics/Pictures/juicio/CuardernoJuicioSelecConducto", image_normal: "Graphics/Pictures/juicio/CuardernoJuicio" },
      { name: "Plano Sótano", brief_description: "Plano del sótano donde ocurrió el crimen.", detailed_description: "Plano del sótano donde ocurrió el crimen. Muestra rutas de escape secretas, además de indicar una ruta de escape planificada.", image_selected: "Graphics/Pictures/juicio/CuardernoJuicioSelecPlanoSotano", image_normal: "Graphics/Pictures/juicio/CuardernoJuicio" },
      { name: "Llave Maestra", brief_description: "Llave maestra que abre todas las habitaciones cerradas de la Academia.", detailed_description: "Llave maestra que abre todas las habitaciones cerradas de la Academia. Solo el conserje Jensen tiene acceso a esta llaves. Fue encontrada en una de las mesas de la Sala Cerrada.", image_selected: "Graphics/Pictures/juicio/CuardernoJuicioSelecLlaveMaestra", image_normal: "Graphics/Pictures/juicio/CuardernoJuicio" },
      { name: "Plan Asesinato", brief_description: "Documento que muestra con exactitud el plan de asesinato paso a paso de manera muy simplifada y detallada.", detailed_description: "Documento que muestra con exactitud el plan de asesinato paso a paso de manera muy simplifada y detallada. Fue encontrado en la Sala Cerrada. Parece que alguien lo escribrio para el asesino", image_selected: "Graphics/Pictures/juicio/CuardernoJuicioSelecPlanAsesinato", image_normal: "Graphics/Pictures/juicio/CuardernoJuicio" },
      { name: "Guantes", brief_description: "Guantes de jardinería usados por el asesino.", detailed_description: "Guantes de jardinería usados por el asesino. Contienen residuos de sangre y pintura que los vinculan al crimen. Estos guantes pertenecen al Jardinero de la Academia.", image_selected: "Graphics/Pictures/juicio/CuardernoJuicioSelecGuantes", image_normal: "Graphics/Pictures/juicio/CuardernoJuicio" },
      { name: "Trébol", brief_description: "Pin con forma de Trébol.", detailed_description: "Pin con forma de Trébol.Fue encontrado en los Almacenes del Comedor.Parece ser del Profesor Clover. Tal vez, fue dejado intencionalmente por el asesino.", image_selected: "Graphics/Pictures/juicio/CuardernoJuicioSelecTrebol", image_normal: "Graphics/Pictures/juicio/CuardernoJuicio" }
    ]

    create_evidence_menu
    refresh_evidence_display
  end

  def create_evidence_menu
    @sprites["background"] = IconSprite.new(0,0,@viewport)

    @sprites["description_window"] = Window_AdvancedTextPokemon.new("")
    @sprites["description_window"].viewport = @viewport
    @sprites["description_window"].width = 320
    @sprites["description_window"].height = 180
    @sprites["description_window"].x = 186
    @sprites["description_window"].y = 219
    @sprites["description_window"].baseColor = Color.new(255,255,255)
    @sprites["description_window"].shadowColor = Color.new(0,0,0)
    @sprites["description_window"].visible = true
    @sprites["description_window"].windowskin = nil
    @sprites["description_window"].back_opacity = 0
    @sprites["description_window"].contents_opacity = 255
    @sprites["description_window"].contents.font.size = 20
    @sprites["description_window"].lineHeight = 22

    @sprites["instructions"] = Sprite.new(@viewport)
    @sprites["instructions"].bitmap = Bitmap.new(Graphics.width,40)
    @sprites["instructions"].bitmap.font.size = 22
    @sprites["instructions"].bitmap.font.color = Color.new(255,255,255)
    @sprites["instructions"].bitmap.draw_text(0,0,Graphics.width,40,"↑↓: Navegar | Z: Seleccionar",2)
    @sprites["instructions"].y = 48
  end

  def refresh_evidence_display
    evidence = @evidence_list[@index]
    if pbResolveBitmap(evidence[:image_selected])
      @sprites["background"].setBitmap(evidence[:image_selected])
    else
      @sprites["background"].setBitmap("Graphics/Pictures/juicio/CuardernoJuicio")
    end

    @sprites["description_window"].text = @showing_details ? evidence[:detailed_description] : evidence[:brief_description]
  end

  def toggle_details
    @showing_details = !@showing_details
    refresh_evidence_display
  end

  def update
    Graphics.update
    Input.update

    if Input.trigger?(Input::UP)
      if @index > 0
        pbPlayCursorSE
        @showing_details = false
        @index -= 1
        refresh_evidence_display
      end
    elsif Input.trigger?(Input::DOWN)
      if @index < @evidence_list.length - 1
        pbPlayCursorSE
        @showing_details = false
        @index += 1
        refresh_evidence_display
      end
    elsif Input.trigger?(Input::USE)
      pbPlayDecisionSE
      toggle_details
    elsif Input.trigger?(Input::ACTION)
      pbPlayDecisionSE
      @selected_evidence = @evidence_list[@index][:name]
      return false
    end

    true
  end

  def main
    loop { break unless update }
    @selected_evidence
  end

  def dispose
    @sprites.each_value { |s| s.dispose }
    @sprites.clear
    @viewport.dispose
  end
end

# MINIJUEGO DE COLOCAR CORRECTAMENTE PUZZLE  DE GEMINIS  SCRIPT 2===

def start_puzzle_minigame
  puzzleMinigame = PuzzlePiece.new
  puzzleMinigame.main
  puzzleMinigame.dispose
end

#pbMessage("¡Lo tengo! El Mensaje Póstumo se refería al símbolo de Géminis. Haciendo referencia a la Dualidad, Gemelas. Lo que tengo que adivinar es quién de las dos fue la que realizó el crimen.")

#FIN MINIJUEGO




#FIN MINIJUEGO


# MINIJUEGO DE SELECCIONAR AL CULPABLE  SCRIPT 2===

 

 

#FIN MINIJUEGO


#===============================================================================
# Función para llamar al menú desde eventos
#===============================================================================

def pbDanganronpaTrialMenu
  menu = DanganronpaTrialMenu.new
  menu.main
  menu.dispose
end

#===============================================================================
# Ejemplo de uso en un evento:
# pbDanganronpaTrialMenu
#===============================================================================