#==============================================================================
# * Scene_Controls
#------------------------------------------------------------------------------
# Muestra una pantalla de ayuda que enumera los controles del teclado.
# Mostrar con:
#      pbEventScreen(ButtonEventScene)
#==============================================================================
class ButtonEventScene < EventScene
  def initialize(viewport = nil)
    super
    Graphics.freeze
    @current_screen = 1
    addImage(0, 0, "Graphics/UI/Controls help/bg")
    @labels = []
    @label_screens = []
    @keys = []
    @key_screens = []

    addImageForScreen(1, 44, 80, _INTL("Graphics/UI/Controls help/help_f1"))
    addImageForScreen(1, 44, 278, _INTL("Graphics/UI/Controls help/help_f8"))
    addLabelForScreen(1, 134, 30, 352, _INTL("IMPORTANTE: Pulsa esta tecla en cualquier momento para ver los controles. Abre la ventana de Asignación de teclas, donde elegir qué teclas de teclado usar para cada control. También detecta un mando."))
    addLabelForScreen(1, 134, 270, 352, _INTL("Toma una captura de pantalla. Se guarda en la misma carpeta que el archivo de guardado."))

    addImageForScreen(2, 16, 158, _INTL("Graphics/UI/Controls help/help_arrows"))
    addLabelForScreen(2, 134, 100, 352, _INTL("Utiliza las teclas de flecha para mover al personaje principal.\n\nTambién puedes usar las teclas de flecha para seleccionar entradas y navegar por los menús."))

    addImageForScreen(3, 16, 90, _INTL("Graphics/UI/Controls help/help_usekey"))
    addImageForScreen(3, 16, 236, _INTL("Graphics/UI/Controls help/help_backkey"))
    addLabelForScreen(3, 134, 34, 352, _INTL("Usado para confirmar una elección, interactuar con personas y cosas, y avanzar a través del texto. (Predeterminado: C)"))
    addLabelForScreen(3, 134, 214, 352, _INTL("Usado para salir, cancelar una elección y cancelar un modo. También abre el menú de Pausa. (Predeterminado: X)"))

    addImageForScreen(4, 16, 90, _INTL("Graphics/UI/Controls help/help_actionkey"))
    addImageForScreen(4, 16, 236, _INTL("Graphics/UI/Controls help/help_specialkey"))
    addLabelForScreen(4, 134, 28, 352, _INTL("Mientras te mueves, mantenlo presionado para moverte a una velocidad diferente. También tiene varias funciones según el contexto. (Predeterminado: Z)"))
    addLabelForScreen(4, 134, 200, 352, _INTL("Presiona para abrir el Menú de preparación, donde se pueden usar objetos registrados y movimientos disponibles en el campo. (Predeterminado: D)"))

    set_up_screen(@current_screen)
    Graphics.transition
    # Ir a la siguiente pantalla cuando el usuario presiona USAR
    onCTrigger.set(method(:pbOnScreenEnd))
  end

  def addLabelForScreen(number, x, y, width, text)
    @labels.push(addLabel(x, y, width, text))
    @label_screens.push(number)
    @picturesprites[@picturesprites.length - 1].opacity = 0
  end

  def addImageForScreen(number, x, y, filename)
    @keys.push(addImage(x, y, filename))
    @key_screens.push(number)
    @picturesprites[@picturesprites.length - 1].opacity = 0
  end

  def set_up_screen(number)
    @label_screens.each_with_index do |screen, i|
      @labels[i].moveOpacity((screen == number) ? 10 : 0, 10, (screen == number) ? 255 : 0)
    end
    @key_screens.each_with_index do |screen, i|
      @keys[i].moveOpacity((screen == number) ? 10 : 0, 10, (screen == number) ? 255 : 0)
    end
    pictureWait   # Actualizar escena de evento con los cambios
  end

  def pbOnScreenEnd(scene, *args)
    last_screen = [@label_screens.max, @key_screens.max].max
    if @current_screen >= last_screen
      # Terminar escena
      $game_temp.background_bitmap = Graphics.snap_to_bitmap
      Graphics.freeze
      @viewport.color = Color.black  # Asegurarse de que la pantalla esté en negro
      Graphics.transition(8, "fadetoblack")
      $game_temp.background_bitmap.dispose
      scene.dispose
    else
      # Siguiente pantalla
      @current_screen += 1
      onCTrigger.clear
      set_up_screen(@current_screen)
      onCTrigger.set(method(:pbOnScreenEnd))
    end
  end
end

