#==============================================================================
# * Scene_Controls
#------------------------------------------------------------------------------
# Muestra una pantalla de ayuda que enumera los controles del teclado.
# Mostrar con:
#      pbEventScreen(ButtonEventScene)
#==============================================================================
class ButtonEventScene < EventScene

  F1_IMAGE_X = 44
  F1_IMAGE_Y = 80
  F8_IMAGE_X = 44
  F8_IMAGE_Y = 278
  WARNING_TEXT_X = 134
  WARNING_TEXT_Y = 30
  WARNING_TEXT_WIDTH = 352
  SCREENSHOT_TEXT_X = 134
  SCREENSHOT_TEXT_Y = 270
  SCREENSHOT_TEXT_WIDTH = 352
  ARROWS_IMAGE_X = 16
  ARROWS_IMAGE_Y = 158
  ARROWS_TEXT_X = 134
  ARROWS_TEXT_Y = 100
  ARROWS_TEXT_WIDTH = 352
  USEKEY_IMAGE_X = 16
  USEKEY_IMAGE_Y = 90
  BACKKEY_IMAGE_X = 16
  BACKKEY_IMAGE_Y = 236
  USEKEY_TEXT_X = 134
  USEKEY_TEXT_Y = 34
  USEKEY_TEXT_WIDTH = 352
  BACKKEY_TEXT_X = 134
  BACKKEY_TEXT_Y = 214
  BACKKEY_TEXT_WIDTH = 352
  ACTIONKEY_IMAGE_X = 16
  ACTIONKEY_IMAGE_Y = 90
  SPECIALKEY_IMAGE_X = 16
  SPECIALKEY_IMAGE_Y = 236
  ACTIONKEY_TEXT_X = 134
  ACTIONKEY_TEXT_Y = 28
  ACTIONKEY_TEXT_WIDTH = 352
  SPECIALKEY_TEXT_X = 134
  SPECIALKEY_TEXT_Y = 200
  SPECIALKEY_TEXT_WIDTH = 352

  def initialize(viewport = nil)
    super
    Graphics.freeze
    @current_screen = 1
    addImage(0, 0, "Graphics/UI/Controls help/bg")
    @labels = []
    @label_screens = []
    @keys = []
    @key_screens = []

    addImageForScreen(1, F1_IMAGE_X, F1_IMAGE_Y, _INTL("Graphics/UI/Controls help/help_f1"))
    addImageForScreen(1, F8_IMAGE_X, F8_IMAGE_Y, _INTL("Graphics/UI/Controls help/help_f8"))
    addLabelForScreen(1, WARNING_TEXT_X, WARNING_TEXT_Y, WARNING_TEXT_WIDTH, _INTL("IMPORTANTE: Pulsa esta tecla en cualquier momento para ver los controles. Abre la ventana de Asignación de teclas, donde elegir qué teclas de teclado usar para cada control. También detecta un mando."))
    addLabelForScreen(1, SCREENSHOT_TEXT_X, SCREENSHOT_TEXT_Y, SCREENSHOT_TEXT_WIDTH, _INTL("Toma una captura de pantalla. Se guarda en la misma carpeta que el archivo de guardado."))

    addImageForScreen(2, ARROWS_IMAGE_X, ARROWS_IMAGE_Y, _INTL("Graphics/UI/Controls help/help_arrows"))
    addLabelForScreen(2, ARROWS_TEXT_X, ARROWS_TEXT_Y, ARROWS_TEXT_WIDTH, _INTL("Utiliza las teclas de flecha para mover al personaje principal.\n\nTambién puedes usar las teclas de flecha para seleccionar entradas y navegar por los menús."))

    addImageForScreen(3, USEKEY_IMAGE_X, USEKEY_IMAGE_Y, _INTL("Graphics/UI/Controls help/help_usekey"))
    addImageForScreen(3, BACKKEY_IMAGE_X, BACKKEY_IMAGE_Y, _INTL("Graphics/UI/Controls help/help_backkey"))
    addLabelForScreen(3, USEKEY_TEXT_X, USEKEY_TEXT_Y, USEKEY_TEXT_WIDTH, _INTL("Usado para confirmar una elección, interactuar con personas y cosas, y avanzar a través del texto. (Predeterminado: C)"))
    addLabelForScreen(3, BACKKEY_TEXT_X, BACKKEY_TEXT_Y, BACKKEY_TEXT_WIDTH, _INTL("Usado para salir, cancelar una elección y cancelar un modo. También abre el menú de Pausa. (Predeterminado: X)"))

    addImageForScreen(4, ACTIONKEY_IMAGE_X, ACTIONKEY_IMAGE_Y, _INTL("Graphics/UI/Controls help/help_actionkey"))
    addImageForScreen(4, SPECIALKEY_IMAGE_X, SPECIALKEY_IMAGE_Y, _INTL("Graphics/UI/Controls help/help_specialkey"))
    addLabelForScreen(4, ACTIONKEY_TEXT_X, ACTIONKEY_TEXT_Y, ACTIONKEY_TEXT_WIDTH, _INTL("Mientras te mueves, mantenlo presionado para moverte a una velocidad diferente. También tiene varias funciones según el contexto. (Predeterminado: Z)"))
    addLabelForScreen(4, SPECIALKEY_TEXT_X, SPECIALKEY_TEXT_Y, SPECIALKEY_TEXT_WIDTH, _INTL("Presiona para abrir el Menú de preparación, donde se pueden usar objetos registrados y movimientos disponibles en el campo. (Predeterminado: D)"))

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

