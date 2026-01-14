#==============================================================================
# * Scene_Credits
#------------------------------------------------------------------------------
# Desplaza los créditos que escribas debajo. Autor original desconocido.
#
## Editado por MiDas Mike para que no se reproduzca sobre el Título, sino que se
# ejecute llamando a lo siguiente:
#    $scene = Scene_Credits.new
#
## Nueva Edición 3/6/2007 11:14 PM por AvatarMonkeyKirby.
# Bueno, lo que he hecho es cambiar la parte del script que supuestamente hacía
# que los créditos terminaran automáticamente ¡para que realmente terminen! Sí, 
# terminarán de verdad cuando los créditos hayan terminado. Así que, las 
# personas a las que ahora debes dar crédito son: Desconocido, MiDas Mike y 
# AvatarMonkeyKirby.
#        - sinceramente tuyo,
#            Tu Amado
# Ah, sí, y también añadí una línea de código que atenúa el BGM para que se 
# desvanezca más rápido y suavemente.
#
## Nueva Edición 24/1/2012 por Maruno.
# Se añadió la capacidad de dividir una línea en dos mitades con <s>, con cada
# mitad alineada hacia el centro. Por favor, también dame créditos si se utiliza.
#
## Nueva Edición 22/2/2012 por Maruno.
# Los créditos ahora se desplazan correctamente cuando se reproducen con un 
# factor de zoom de 0.5. Se puede definir la música ahora. Los créditos no 
# pueden ser omitidos durante su primera reproducción.
#
## Nueva Edición 25/3/2020 por Maruno.
# La velocidad de desplazamiento ahora es independiente de la frecuencia de 
# cuadros. Ahora admite valores no enteros para SCROLL_SPEED.
#
## Nueva Edición 21/8/2020 por Marin.
# Ahora inserta automáticamente los créditos de los complementos que han sido
# registrados a través del módulo PluginManager.
#==============================================================================
class Scene_Credits
  # Backgrounds to show in credits. Found in Graphics/Titles/ folder
  BACKGROUNDS_LIST       = ["credits1", "credits2", "credits3", "credits4", "credits5"]
  CREDITS_BGM                    = "Credits"
  SCROLL_SPEED           = 40   # Pixels per second
  SECONDS_PER_BACKGROUND = 11
  TEXT_OUTLINE_COLOR     = Color.new(0, 0, 128, 255)
  TEXT_BASE_COLOR        = Color.new(255, 255, 255, 255)
  TEXT_SHADOW_COLOR      = Color.new(0, 0, 0, 100)

  # Constantes de layout y temporización
  # Altura en píxeles de cada línea de crédito
  LINE_HEIGHT = 32
  # Relleno vertical añadido al bitmap de créditos
  BITMAP_PADDING = 16
  # Factor de recorte para calcular el trim: Graphics.height / TRIM_DIVISOR
  TRIM_DIVISOR = 10
  # Margen usado al dividir una línea en dos mitades con <s>
  SPLIT_MARGIN = 20
  # Desplazamientos Y usados para dibujar sombras/contornos/texto base
  TEXT_Y_SHADOW = 12
  TEXT_Y_OUTLINE_TOP = 2
  TEXT_Y_BASE = 4
  TEXT_Y_OUTLINE_BOTTOM = 6
  # Desplazamiento X para contornos (izquierda/derecha)
  TEXT_X_OFFSET = 2

  # Z para viewports y sprites usados en créditos
  VIEWPORT_Z = 99999
  TEXT_VIEWPORT_Z = 99999
  CREDIT_SPRITE_Z = 9998

  # Duraciones usadas para fundidos y transiciones
  BGM_FADE_DURATION = 2.0
  TRANSITION_FADE_DURATION = 8

  def add_names_to_credits(credits, names, with_final_new_line = true)
    if names.length >= 5
      i = 0
      loop do
        credits.push(names[i] + "<s>" + (names[i + 1] || ""))
        i += 2
        break if i >= names.length
      end
    else
      names.each { |name| credits.push(name) }
    end
    credits.push("") if with_final_new_line
  end

  def get_text
    ret = Settings.game_credits || []
    # Add plugin credits
    if PluginManager.plugins.length > 0
      ret.push("", "", "")
      PluginManager.plugins.each do |plugin|
        pcred = PluginManager.credits(plugin)
        ret.push(_INTL("\"{1}\" v.{2} por:", plugin, PluginManager.version(plugin)))
        add_names_to_credits(ret, pcred)
      end
    end
    # Add Essentials credits
    ret.push("", "", "")
    ret.push(_INTL("\"Pokémon Essentials\" ha sido creado por:"))
    add_names_to_credits(ret, [
      "Poccil (Peter O.)",
      "Maruno",
      _INTL("Inspirado en el trabajo de Flameguru")
    ])
    ret.push(_INTL("Con contribuciones de:"))
    add_names_to_credits(ret, [
      "AvatarMonkeyKirby", "Boushy", "Brother1440", "FL.", "Genzai Kawakami",
      "Golisopod User", "help-14", "IceGod64", "Jacob O. Wobbrock", "KitsuneKouta",
      "Lisa Anthony", "Luka S.J.", "Marin", "MiDas Mike", "Near Fantastica",
      "PinkMan", "Popper", "Rataime", "Savordez", "SoundSpawn",
      "the__end", "Venom12", "Wachunga"
    ], false)
    ret.push(_INTL("y todos los demás que han ayudado"))
    ret.push("")
    ret.push(_INTL("\"mkxp-z\" por:"))
    add_names_to_credits(ret, [
      "Roza",
      _INTL("Basado en \"mkxp\" por Ancurio et al.")
    ])
    ret.push(_INTL("\"RPG Maker XP\" por:"))
    add_names_to_credits(ret, ["Enterbrain"])
    ret.push(_INTL("Pokémon es propiedad de:"))
    add_names_to_credits(ret, [
      "The Pokémon Company",
      "Nintendo",
      _INTL("Afilicado con Game Freak")
    ])
    ret.push("", "")
    ret.push(_INTL("Esto es un fan juego sin ánimo de lucro."),
             _INTL("No se pretende infringir los derechos de autor."),
             _INTL("¡Por favor, apoya los juegos oficiales!"))
    return ret
  end

  def main
    @quit = false
    #-------------------------------
    # Animated Background Setup
    #-------------------------------
    @timer_start = System.uptime   # Time when the credits started
    @bg_index = 0
    @bitmap_height = Graphics.height   # For a single credits text bitmap
    @trim = Graphics.height / TRIM_DIVISOR
    # Number of game frames per background frame
    @realOY = -(Graphics.height - @trim)
    #-------------------------------
    # Credits text Setup
    #-------------------------------
    credit_lines = get_text
    #-------------------------------
    # Make background and text sprites
    #-------------------------------
    viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    viewport.z = VIEWPORT_Z
    text_viewport = Viewport.new(0, @trim, Graphics.width, Graphics.height - (@trim * 2))
    text_viewport.z = TEXT_VIEWPORT_Z
    @background_sprite = IconSprite.new(0, 0)
    @background_sprite.setBitmap("Graphics/Titles/" + BACKGROUNDS_LIST[0])
    @credit_sprites = []
    @total_height = credit_lines.size * LINE_HEIGHT
    lines_per_bitmap = @bitmap_height / LINE_HEIGHT
    num_bitmaps = (credit_lines.size.to_f / lines_per_bitmap).ceil
    num_bitmaps.times do |i|
      credit_bitmap = Bitmap.new(Graphics.width, @bitmap_height + BITMAP_PADDING)
      pbSetSystemFont(credit_bitmap)
      lines_per_bitmap.times do |j|
        line = credit_lines[(i * lines_per_bitmap) + j]
        next if !line
        line += " " if line.end_with?("<s>")
        line = line.split("<s>")
        xpos = 0
        align = 1   # Centre align
        linewidth = Graphics.width
        line.length.times do |k|
          text = line[k].strip
          if line.length > 1
            xpos = (k == 0) ? 0 : SPLIT_MARGIN + (Graphics.width / 2)
            align = (k == 0) ? 2 : 0   # Right align : left align
            linewidth = (Graphics.width / 2) - SPLIT_MARGIN
          end
          credit_bitmap.font.color = TEXT_SHADOW_COLOR
          credit_bitmap.draw_text(xpos, (j * LINE_HEIGHT) + TEXT_Y_SHADOW, linewidth, LINE_HEIGHT, text, align)
          credit_bitmap.font.color = TEXT_OUTLINE_COLOR
          credit_bitmap.draw_text(xpos + TEXT_X_OFFSET, (j * LINE_HEIGHT) + TEXT_Y_OUTLINE_TOP, linewidth, LINE_HEIGHT, text, align)
          credit_bitmap.draw_text(xpos,                   (j * LINE_HEIGHT) + TEXT_Y_OUTLINE_TOP, linewidth, LINE_HEIGHT, text, align)
          credit_bitmap.draw_text(xpos - TEXT_X_OFFSET, (j * LINE_HEIGHT) + TEXT_Y_OUTLINE_TOP, linewidth, LINE_HEIGHT, text, align)
          credit_bitmap.draw_text(xpos + TEXT_X_OFFSET, (j * LINE_HEIGHT) + TEXT_Y_BASE, linewidth, LINE_HEIGHT, text, align)
          credit_bitmap.draw_text(xpos - TEXT_X_OFFSET, (j * LINE_HEIGHT) + TEXT_Y_BASE, linewidth, LINE_HEIGHT, text, align)
          credit_bitmap.draw_text(xpos + TEXT_X_OFFSET, (j * LINE_HEIGHT) + TEXT_Y_OUTLINE_BOTTOM, linewidth, LINE_HEIGHT, text, align)
          credit_bitmap.draw_text(xpos,                   (j * LINE_HEIGHT) + TEXT_Y_OUTLINE_BOTTOM, linewidth, LINE_HEIGHT, text, align)
          credit_bitmap.draw_text(xpos - TEXT_X_OFFSET, (j * LINE_HEIGHT) + TEXT_Y_OUTLINE_BOTTOM, linewidth, LINE_HEIGHT, text, align)
          credit_bitmap.font.color = TEXT_BASE_COLOR
          credit_bitmap.draw_text(xpos, (j * LINE_HEIGHT) + TEXT_Y_BASE, linewidth, LINE_HEIGHT, text, align)
        end
      end
      credit_sprite = Sprite.new(text_viewport)
      credit_sprite.bitmap = credit_bitmap
      credit_sprite.z      = CREDIT_SPRITE_Z
      credit_sprite.oy     = @realOY - (@bitmap_height * i)
      @credit_sprites[i] = credit_sprite
    end
    #-------------------------------
    # Setup
    #-------------------------------
    # Stops all audio but background music
    previousBGM = $game_system.getPlayingBGM
    pbMEStop
    pbBGSStop
    pbSEStop
    pbBGMFade(BGM_FADE_DURATION)
    pbBGMPlay(CREDITS_BGM)
    Graphics.transition
    loop do
      Graphics.update
      Input.update
      update
      break if @quit
    end
    $game_temp.background_bitmap = Graphics.snap_to_bitmap
    pbBGMFade(BGM_FADE_DURATION)
    Graphics.freeze
    viewport.color = Color.black   # Ensure screen is black
    text_viewport.color = Color.black   # Ensure screen is black
    Graphics.transition(TRANSITION_FADE_DURATION, "fadetoblack")
    $game_temp.background_bitmap.dispose
    @background_sprite.dispose
    @credit_sprites.each { |s| s&.dispose }
    viewport.dispose
    text_viewport.dispose
    $PokemonGlobal.creditsPlayed = true
    pbBGMPlay(previousBGM)
    $scene = ($game_map) ? Scene_Map.new : nil
  end

  # Check if the credits should be cancelled
  def cancel?
    @quit = true if Input.trigger?(Input::USE) && $PokemonGlobal.creditsPlayed
    return @quit
  end

  # Checks if credits bitmap has reached its ending point
  def last?
    @quit = true if @realOY > @total_height + @trim
    return @quit
  end

  def update
    # Go to next slide
    new_bg_index = ((System.uptime - @timer_start) / SECONDS_PER_BACKGROUND) % BACKGROUNDS_LIST.length
    if @bg_index != new_bg_index
      @bg_index = new_bg_index
      @background_sprite.setBitmap("Graphics/Titles/" + BACKGROUNDS_LIST[@bg_index])
    end
    return if cancel?
    return if last?
    @realOY = (SCROLL_SPEED * (System.uptime - @timer_start)) - Graphics.height + @trim
    @credit_sprites.each_with_index { |s, i| s.oy = @realOY - (@bitmap_height * i) }
  end
end

