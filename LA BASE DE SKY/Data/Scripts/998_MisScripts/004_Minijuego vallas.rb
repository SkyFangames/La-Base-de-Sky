#===============================================================================
# Minijuego: Salto de Valla para Pokemon Essentials v21.1
# Autor: Scream
# Versión mejorada sin recuadros negros y con teleport simplificado
# MODIFICADO: Teleport al mapa 025, coordenadas (29,9)
#===============================================================================

class MinijuegoSaltoValla
  ANCHO_PANTALLA = Graphics.width
  ALTO_PANTALLA = Graphics.height
  
  def initialize
    @sprites = {}
    @viewport = Viewport.new(0, 0, ANCHO_PANTALLA, ALTO_PANTALLA)
    @viewport.z = 99999
    
    # Variables del jugador
    @jugador_y_base = ALTO_PANTALLA - 320  # Posición base (suelo)
    @jugador_y = @jugador_y_base           # Posición actual
    @jugador_x = 100                       # Posición fija horizontal
    
    # FÍSICA DE SALTO REDUCIDA
    @saltando = false
    @velocidad_salto = 0
    @gravedad_inicial = 0.8
    @gravedad_maxima = 2.2
    @gravedad_actual = @gravedad_inicial
    @aceleracion_gravedad = 0.08
    @fuerza_salto = -16        # REDUCIDO: Era -22, ahora -18 para salto más bajo
    @altura_maxima = 0
    @en_descenso = false
    
    # Control de curva de salto más pequeña
    @tiempo_salto = 0
    @duracion_salto_completo = 60  # REDUCIDO: Era 65, ahora 60 para caída más rápida
    
    # Vallas (AUMENTADO: Más velocidad y aparición más frecuente)
    @vallas = []
    @velocidad_vallas = 8           # AUMENTADO: Era 6, ahora 8 para mayor velocidad
    @contador_vallas = 0
    @distancia_vallas = 120         # REDUCIDO: Era 150, ahora 120 para aparición más frecuente
    
    # Puntuación y estado
    @puntuacion = 0
    @vidas = 6
    @juego_activo = true
    @tiempo_invulnerable = 0
    
    # Sistema de timer
    @tiempo_restante = 60.0
    @penalizacion_tiempo = 5.0
    @tiempo_maximo = 60.0
    @frames_por_segundo = 60
    
    # Control de vallas - CORREGIDO para manejar colisiones
    @vallas_objetivo = 15
    @vallas_totales_generadas = 0
    @vallas_superadas = 0          # Total de vallas que han pasado completamente
    @vallas_saltadas_exitosas = 0  # Solo las saltadas sin colisión
    
    # Variables de dificultad (mantenidas pero no mostradas)
    @nivel = 1
    @vallas_pasadas = 0
    
    # NUEVO: Variable para controlar el sonido de advertencia
    @sonido_falta_reproducido = false
    
    crear_sprites
    crear_primera_valla
  end
  
  def crear_sprites
    # Fondo del minijuego
    @sprites["fondo"] = Sprite.new(@viewport)
    begin
      @sprites["fondo"].bitmap = Bitmap.new("Graphics/Pictures/Vallas/vallas_fondo")
      @sprites["fondo"].zoom_x = ANCHO_PANTALLA.to_f / @sprites["fondo"].bitmap.width
      @sprites["fondo"].zoom_y = ALTO_PANTALLA.to_f / @sprites["fondo"].bitmap.height
    rescue
      pbMessage("No se pudo cargar 'Graphics/Pictures/Vallas/vallas_fondo', usando fondo simple.")
      @sprites["fondo"].bitmap = Bitmap.new(ANCHO_PANTALLA, ALTO_PANTALLA)
      @sprites["fondo"].bitmap.fill_rect(0, 0, ANCHO_PANTALLA, ALTO_PANTALLA, Color.new(135, 206, 235))
      @sprites["fondo"].bitmap.fill_rect(0, ALTO_PANTALLA - 80, ANCHO_PANTALLA, 80, Color.new(34, 139, 34))
    end
    
    # Jugador
    @sprites["jugador"] = Sprite.new(@viewport)
    begin
      @sprites["jugador"].bitmap = Bitmap.new("Graphics/Characters/trchar001")
      
      @frame_ancho = 64
      @frame_alto = 64
      @direccion_derecha = 2
      @frame_actual = 0
      @contador_animacion = 0
      @frames_salto = 1
      
      @sprites["jugador"].src_rect = Rect.new(0, @direccion_derecha * @frame_alto, @frame_ancho, @frame_alto)
      @sprites["jugador"].ox = @frame_ancho / 2
      @sprites["jugador"].oy = @frame_alto / 2
    rescue
      @sprites["jugador"].bitmap = Bitmap.new(40, 40)
      @sprites["jugador"].bitmap.fill_rect(0, 0, 40, 40, Color.new(255, 255, 0))
      @sprites["jugador"].ox = 20
      @sprites["jugador"].oy = 20
      @usando_overworld = false
    else
      @usando_overworld = true
    end
    actualizar_posicion_jugador
    
    # UI - Puntuación (SIN FONDO NEGRO)
    @sprites["puntuacion"] = Sprite.new(@viewport)
    @sprites["puntuacion"].bitmap = Bitmap.new(200, 100)
    @sprites["puntuacion"].x = 10
    @sprites["puntuacion"].y = 10
    
    # UI - Vidas con corazón personalizado (SIN FONDO NEGRO)
    @sprites["vidas"] = Sprite.new(@viewport)
    @sprites["vidas"].bitmap = Bitmap.new(220, 50)
    @sprites["vidas"].x = ANCHO_PANTALLA - 240
    @sprites["vidas"].y = 10
    
    # Cargar sprite del corazón personalizado
    @corazon_bitmap = nil
    begin
      @corazon_bitmap = Bitmap.new("Graphics/Pictures/Vallas/Corazon")
      puts "Corazón personalizado cargado correctamente"
    rescue
      puts "No se pudo cargar el corazón personalizado, usando texto"
      @corazon_bitmap = nil
    end
    
    # Instrucciones CENTRADAS (SIN FONDO NEGRO)
    @sprites["instrucciones"] = Sprite.new(@viewport)
    @sprites["instrucciones"].bitmap = Bitmap.new(400, 60)
    @sprites["instrucciones"].x = (ANCHO_PANTALLA - 400) / 2
    @sprites["instrucciones"].y = ALTO_PANTALLA - 120
    
    # Crear texto de instrucciones con SOMBRA (SIN FONDO NEGRO)
    @sprites["instrucciones"].bitmap.font.size = 18
    # Sombra negra para "Pulsa ESPACIO o C para saltar"
    @sprites["instrucciones"].bitmap.font.color = Color.new(0, 0, 0, 255)
    @sprites["instrucciones"].bitmap.draw_text(2, 7, 400, 20, "Pulsa ESPACIO o C para saltar", 1)
    # Texto principal amarillo
    @sprites["instrucciones"].bitmap.font.color = Color.new(255, 255, 0)
    @sprites["instrucciones"].bitmap.draw_text(0, 5, 400, 20, "Pulsa ESPACIO o C para saltar", 1)
    
    # Sombra negra para "¡Evita las colisiones!"
    @sprites["instrucciones"].bitmap.font.color = Color.new(0, 0, 0, 255)
    @sprites["instrucciones"].bitmap.draw_text(2, 27, 400, 20, "¡Evita las colisiones!", 1)
    # Texto principal rojo
    @sprites["instrucciones"].bitmap.font.color = Color.new(255, 100, 100)
    @sprites["instrucciones"].bitmap.draw_text(0, 25, 400, 20, "¡Evita las colisiones!", 1)
    
    # Reproducir BGM del minijuego
    begin
      pbBGMPlay("Sonic Minijuego vallas")
      puts "Música del minijuego iniciada"
    rescue
      puts "No se pudo reproducir la música del minijuego"
    end
    
    actualizar_ui
  end
  
  def crear_valla(x = ANCHO_PANTALLA + 150)  # ADELANTADO: Aparecen 100 píxeles antes (era +50)
    valla = {
      x: x,
      y: @jugador_y_base - 50,
      ancho: 20,
      alto: 60,
      pasada: false,
      procesada: false,
      colisionada: false,  # NUEVO: Marca si hubo colisión con esta valla
      paso_durante_invulnerabilidad: false  # NUEVO: Marca si pasó cerca durante invulnerabilidad
    }
    @vallas.push(valla)
    @vallas_totales_generadas += 1
  end
  
  def crear_primera_valla
    crear_valla(ANCHO_PANTALLA / 2 + 100)  # ADELANTADO: Aparece 100 píxeles antes
  end
  
  def actualizar_posicion_jugador
    @sprites["jugador"].x = @jugador_x
    @sprites["jugador"].y = @jugador_y
    
    # Efectos visuales durante el salto
    if @saltando
      progreso_salto = @tiempo_salto.to_f / @duracion_salto_completo
      if progreso_salto <= 0.5
        @sprites["jugador"].angle = -5 * Math.sin(progreso_salto * Math::PI)
      else
        @sprites["jugador"].angle = 5 * Math.sin((progreso_salto - 0.5) * Math::PI)
      end
      
      escala = 1.0 + 0.1 * Math.sin(progreso_salto * Math::PI)
      @sprites["jugador"].zoom_x = escala
      @sprites["jugador"].zoom_y = escala
    else
      @sprites["jugador"].angle = 0
      @sprites["jugador"].zoom_x = 1.0
      @sprites["jugador"].zoom_y = 1.0
    end
    
    if @usando_overworld
      actualizar_animacion_jugador
    end
  end
  
  def actualizar_animacion_jugador
    if @saltando
      @sprites["jugador"].src_rect.x = @frames_salto * @frame_ancho
    else
      @contador_animacion += 1
      if @contador_animacion >= 8
        @contador_animacion = 0
        case @frame_actual
        when 0
          @frame_actual = 1
        when 1
          @frame_actual = 2
        when 2
          @frame_actual = 1
        when 3
          @frame_actual = 0
        else
          @frame_actual = 0
        end
      end
      @sprites["jugador"].src_rect.x = @frame_actual * @frame_ancho
    end
    
    @sprites["jugador"].src_rect.y = @direccion_derecha * @frame_alto
  end
  
  def actualizar_ui
    # Actualizar puntuación (SIN FONDO NEGRO)
    @sprites["puntuacion"].bitmap.clear
    
    # Crear función auxiliar para dibujar texto con sombra
    def dibujar_texto_con_sombra(bitmap, x, y, ancho, alto, texto, alineacion, color_sombra = Color.new(0, 0, 0, 255), color_texto = Color.new(255, 255, 255))
      # Sombra
      bitmap.font.color = color_sombra
      bitmap.draw_text(x + 2, y + 2, ancho, alto, texto, alineacion)
      # Texto principal
      bitmap.font.color = color_texto
      bitmap.draw_text(x, y, ancho, alto, texto, alineacion)
    end
    
    @sprites["puntuacion"].bitmap.font.size = 20
    dibujar_texto_con_sombra(@sprites["puntuacion"].bitmap, 5, 5, 190, 20, "Puntos: #{@puntuacion}", 0, Color.new(0, 0, 0, 255), Color.new(255, 255, 0))
    
    # Mostrar progreso de vallas SALTADAS (solo exitosas)
    dibujar_texto_con_sombra(@sprites["puntuacion"].bitmap, 5, 25, 190, 20, "Saltadas: #{@vallas_pasadas}/#{@vallas_objetivo}", 0, Color.new(0, 0, 0, 255), Color.new(100, 255, 100))
    
    # Verificar si está a partir de la décima valla y reproducir sonido de advertencia
    if @vallas_pasadas >= 10 && !@sonido_falta_reproducido
      pbSEPlay("Pkmn level up")
      @sonido_falta_reproducido = true
    end
    
    # Mostrar timer con colores dinámicos
    tiempo_mostrar = [@tiempo_restante, 0].max
    minutos = (tiempo_mostrar / 60).floor
    segundos = (tiempo_mostrar % 60).floor
    decimas = ((tiempo_mostrar % 1) * 10).floor
    
    if @tiempo_restante <= 5
      color_timer = Color.new(255, 50, 50)
    elsif @tiempo_restante <= 10
      color_timer = Color.new(255, 150, 50)
    else
      color_timer = Color.new(100, 255, 255)
    end
    
    dibujar_texto_con_sombra(@sprites["puntuacion"].bitmap, 5, 45, 190, 20, "Tiempo: #{minutos}:#{segundos.to_s.rjust(2, '0')}.#{decimas}", 0, Color.new(0, 0, 0, 255), color_timer)
    
    # Actualizar vidas con corazón personalizado (SIN FONDO NEGRO)
    @sprites["vidas"].bitmap.clear
    
    if @corazon_bitmap && !@corazon_bitmap.disposed?
      # Usar el corazón personalizado
      # Calcular escala para que el corazón no sea más grande que 32x32
      escala_x = 32.0 / @corazon_bitmap.width if @corazon_bitmap.width > 32
      escala_y = 32.0 / @corazon_bitmap.height if @corazon_bitmap.height > 32
      escala = [escala_x || 1.0, escala_y || 1.0, 1.0].min
      
      # Crear rectángulo para el corazón escalado
      ancho_final = (@corazon_bitmap.width * escala).to_i
      alto_final = (@corazon_bitmap.height * escala).to_i
      
      # Posición centrada verticalmente
      pos_y = (50 - alto_final) / 2
      pos_x = 20
      
      # Si necesita escala, crear bitmap temporal
      if escala < 1.0
        temp_bitmap = Bitmap.new(ancho_final, alto_final)
        temp_bitmap.stretch_blt(Rect.new(0, 0, ancho_final, alto_final), @corazon_bitmap, Rect.new(0, 0, @corazon_bitmap.width, @corazon_bitmap.height))
        @sprites["vidas"].bitmap.blt(pos_x, pos_y, temp_bitmap, Rect.new(0, 0, ancho_final, alto_final))
        temp_bitmap.dispose
      else
        @sprites["vidas"].bitmap.blt(pos_x, pos_y, @corazon_bitmap, Rect.new(0, 0, @corazon_bitmap.width, @corazon_bitmap.height))
      end
      
      # Dibujar contador de vidas con sombra
      pos_x_texto = pos_x + ancho_final + 15
      @sprites["vidas"].bitmap.font.size = 22
      # Sombra negra
      @sprites["vidas"].bitmap.font.color = Color.new(0, 0, 0, 255)
      @sprites["vidas"].bitmap.draw_text(pos_x_texto + 2, 17, 120, 25, "x #{@vidas}", 0)
      # Texto principal blanco
      @sprites["vidas"].bitmap.font.color = Color.new(255, 255, 255)
      @sprites["vidas"].bitmap.draw_text(pos_x_texto, 15, 120, 25, "x #{@vidas}", 0)
    else
      # Fallback: usar corazón de texto si no se pudo cargar la imagen
      @sprites["vidas"].bitmap.font.size = 28
      # Sombra del corazón
      @sprites["vidas"].bitmap.font.color = Color.new(0, 0, 0, 255)
      @sprites["vidas"].bitmap.draw_text(22, 10, 35, 35, "♥", 1)
      # Corazón principal
      @sprites["vidas"].bitmap.font.color = Color.new(255, 50, 50)
      @sprites["vidas"].bitmap.draw_text(20, 8, 35, 35, "♥", 1)
      
      @sprites["vidas"].bitmap.font.size = 22
      # Sombra del texto
      @sprites["vidas"].bitmap.font.color = Color.new(0, 0, 0, 255)
      @sprites["vidas"].bitmap.draw_text(68, 17, 120, 25, "x #{@vidas}", 0)
      # Texto principal
      @sprites["vidas"].bitmap.font.color = Color.new(255, 255, 255)
      @sprites["vidas"].bitmap.draw_text(66, 15, 120, 25, "x #{@vidas}", 0)
    end
  end
  
  def dibujar_vallas
    @vallas.each do |valla|
      unless valla[:sprite]
        valla[:sprite] = Sprite.new(@viewport)
        begin
          valla[:sprite].bitmap = Bitmap.new("Graphics/Pictures/Vallas/valla")
          valla[:ancho] = valla[:sprite].bitmap.width
          valla[:alto] = valla[:sprite].bitmap.height
        rescue
          valla[:sprite].bitmap = Bitmap.new(valla[:ancho], valla[:alto])
          valla[:sprite].bitmap.fill_rect(0, 0, valla[:ancho], valla[:alto], Color.new(139, 69, 19))
        end
      end
      
      valla[:sprite].x = valla[:x]
      valla[:sprite].y = valla[:y]
    end
  end
  
  def saltar
    if !@saltando && @velocidad_salto == 0
      @saltando = true
      @velocidad_salto = @fuerza_salto
      @gravedad_actual = @gravedad_inicial
      @altura_maxima = @jugador_y
      @en_descenso = false
      @tiempo_salto = 0
      pbSEPlay("jump1")
    end
  end
  
  def actualizar_fisica_jugador
    if @saltando || @velocidad_salto != 0
      @tiempo_salto += 1
      
      # Física de salto REDUCIDA
      progreso = [@tiempo_salto.to_f / @duracion_salto_completo, 1.0].min
      
      # REDUCIDO: Altura máxima de 80 píxeles (era 100)
      altura_relativa = Math.sin(progreso * Math::PI) * 80
      @jugador_y = @jugador_y_base - altura_relativa
      
      @en_descenso = progreso > 0.5
      
      if progreso >= 1.0
        @jugador_y = @jugador_y_base
        @velocidad_salto = 0
        @saltando = false
        @tiempo_salto = 0
        @gravedad_actual = @gravedad_inicial
      end
    end
    
    actualizar_posicion_jugador
  end
  
  def actualizar_vallas
    @vallas.each_with_index do |valla, index|
      valla[:x] -= @velocidad_vallas
      
      # Solo contar como saltada si pasa SIN colisión Y jugador NO está invulnerable
      if !valla[:procesada] && valla[:x] + valla[:ancho] < @jugador_x - 30
        valla[:procesada] = true
        @vallas_superadas += 1
        
        # Solo contar como saltada exitosa si NO hubo colisión Y no estaba invulnerable cuando la valla estaba cerca
        if !valla[:colisionada] && (!valla[:paso_durante_invulnerabilidad])
          @puntuacion += 10
          @vallas_pasadas += 1
          valla[:pasada] = true
        end
        
        # Verificar que alcance exactamente 15 vallas
        if @vallas_pasadas >= @vallas_objetivo
          @juego_activo = false
          @victoria = true
          return
        end
        
        # Aumentar dificultad cada 3 vallas EXITOSAS
        if @vallas_pasadas % 3 == 0 && @vallas_pasadas > 0
          @nivel += 1
          @velocidad_vallas += 1.0
          @distancia_vallas = [@distancia_vallas - 20, 80].max
          pbSEPlay("Pkmn level up")
        end
      end
      
      # Marcar vallas que pasan cerca del jugador durante invulnerabilidad
      if @tiempo_invulnerable > 0 && !valla[:paso_durante_invulnerabilidad]
        # Si la valla está en el área del jugador mientras está invulnerable
        if (valla[:x] - @jugador_x).abs < 50 && !valla[:colisionada]
          valla[:paso_durante_invulnerabilidad] = true
        end
      end
    end
    
    @vallas.reject! do |valla|
      if valla[:x] + valla[:ancho] < -50
        valla[:sprite].dispose if valla[:sprite]
        true
      else
        false
      end
    end
    
    # Seguir generando vallas mientras no se hayan saltado 15 exitosamente
    if @vallas_pasadas < @vallas_objetivo && @juego_activo
      @contador_vallas += 1
      if @contador_vallas >= @distancia_vallas
        crear_valla
        @contador_vallas = 0
      end
    end
    
    dibujar_vallas
  end
  
  def verificar_colisiones
    return if @tiempo_invulnerable > 0
    
    jugador_rect = Rect.new(@jugador_x - 10, @jugador_y - 10, 20, 20)
    
    @vallas.each do |valla|
      # No verificar colisión si ya está marcada como colisionada
      next if valla[:colisionada]
      
      margen = 12
      valla_rect = Rect.new(valla[:x] + margen, valla[:y] + margen, 
                            valla[:ancho] - (margen * 2), valla[:alto] - (margen * 2))
      
      if jugador_rect.x < valla_rect.x + valla_rect.width &&
         jugador_rect.x + jugador_rect.width > valla_rect.x &&
         jugador_rect.y < valla_rect.y + valla_rect.height &&
         jugador_rect.y + jugador_rect.height > valla_rect.y
        
        # Marcar esta valla como colisionada
        valla[:colisionada] = true
        perder_vida
        break
      end
    end
  end
  
  def perder_vida
    @vidas -= 1
    @tiempo_invulnerable = 120
    
    @tiempo_restante -= @penalizacion_tiempo
    @tiempo_restante = [@tiempo_restante, 0].max
    
    pbSEPlay("Pkmn fainted")
    
    crear_mensaje_penalizacion
    
    if @vidas <= 0
      @vidas = 0
      @juego_activo = false
      @game_over = true
      @motivo_game_over = "vidas"
    end
  end
  
  def actualizar_invulnerabilidad
    if @tiempo_invulnerable > 0
      @tiempo_invulnerable -= 1
      @sprites["jugador"].opacity = (@tiempo_invulnerable % 10 < 5) ? 128 : 255
    else
      @sprites["jugador"].opacity = 255
    end
  end
  
  def crear_mensaje_penalizacion
    if @sprites["penalizacion"]
      @sprites["penalizacion"].dispose
    end
    
    @sprites["penalizacion"] = Sprite.new(@viewport)
    @sprites["penalizacion"].bitmap = Bitmap.new(200, 40)
    @sprites["penalizacion"].x = (ANCHO_PANTALLA - 200) / 2
    @sprites["penalizacion"].y = ALTO_PANTALLA / 2 - 100
    
    # Crear mensaje de penalización con sombra (SIN FONDO NEGRO)
    @sprites["penalizacion"].bitmap.font.size = 18
    # Sombra negra
    @sprites["penalizacion"].bitmap.font.color = Color.new(0, 0, 0, 255)
    @sprites["penalizacion"].bitmap.draw_text(2, 12, 200, 20, "-5 SEGUNDOS!", 1)
    # Texto principal rojo brillante
    @sprites["penalizacion"].bitmap.font.color = Color.new(255, 50, 50)
    @sprites["penalizacion"].bitmap.draw_text(0, 10, 200, 20, "-5 SEGUNDOS!", 1)
    
    @tiempo_mensaje_penalizacion = 90
  end
  
  def actualizar_timer
    @tiempo_restante -= 1.0 / @frames_por_segundo
    
    if @tiempo_restante <= 0
      @tiempo_restante = 0
      @juego_activo = false
      @game_over = true
      @motivo_game_over = "tiempo"
      pbSEPlay("Pkmn fainted")
    end
    
    if @tiempo_mensaje_penalizacion && @tiempo_mensaje_penalizacion > 0
      @tiempo_mensaje_penalizacion -= 1
      if @tiempo_mensaje_penalizacion <= 0
        if @sprites["penalizacion"]
          @sprites["penalizacion"].dispose
          @sprites["penalizacion"] = nil
        end
        @tiempo_mensaje_penalizacion = nil
      end
    end
  end
  
  def manejar_input
    if Input.trigger?(Input::USE) || Input.trigger?(Input::ACTION)
      if @juego_activo
        saltar
      else
        return false
      end
    end
    
    return true
  end
  
  def actualizar
    return false unless manejar_input
    
    if @juego_activo
      actualizar_timer
      actualizar_fisica_jugador
      actualizar_vallas
      verificar_colisiones
      actualizar_invulnerabilidad
      actualizar_ui
    else
      mostrar_resultado_final
    end
    
    Graphics.update
    Input.update
    return true
  end
  
  def mostrar_resultado_final
    unless @resultado_mostrado
      @sprites["resultado"] = Sprite.new(@viewport)
      @sprites["resultado"].bitmap = Bitmap.new(400, 250)
      @sprites["resultado"].x = (ANCHO_PANTALLA - 400) / 2
      @sprites["resultado"].y = (ALTO_PANTALLA - 250) / 2
      
      # Crear fondo semi-transparente con bordes redondeados visuales
      @sprites["resultado"].bitmap.fill_rect(0, 0, 400, 250, Color.new(0, 0, 0, 200))
      @sprites["resultado"].bitmap.fill_rect(2, 2, 396, 246, Color.new(50, 50, 150, 180))
      
      # Función auxiliar para texto con sombra en resultados
      def dibujar_resultado_con_sombra(bitmap, x, y, ancho, alto, texto, alineacion, color_sombra = Color.new(0, 0, 0, 255), color_texto = Color.new(255, 255, 255))
        # Sombra
        bitmap.font.color = color_sombra
        bitmap.draw_text(x + 2, y + 2, ancho, alto, texto, alineacion)
        # Texto principal
        bitmap.font.color = color_texto
        bitmap.draw_text(x, y, ancho, alto, texto, alineacion)
      end
      
      if @victoria
        @sprites["resultado"].bitmap.font.size = 32
        dibujar_resultado_con_sombra(@sprites["resultado"].bitmap, 0, 100, 400, 30, "Vallas saltadas: #{@vallas_pasadas}/15", 1, Color.new(0, 0, 0, 255), Color.new(255, 255, 0))
        dibujar_resultado_con_sombra(@sprites["resultado"].bitmap, 0, 130, 400, 30, "Puntuación Final: #{@puntuacion}", 1, Color.new(0, 0, 0, 255), Color.new(255, 255, 0))
      elsif @game_over
        @sprites["resultado"].bitmap.font.size = 32
        if @motivo_game_over == "tiempo"
          dibujar_resultado_con_sombra(@sprites["resultado"].bitmap, 0, 20, 400, 40, "¡TIEMPO AGOTADO!", 1, Color.new(0, 0, 0, 255), Color.new(255, 100, 100))
        else
          dibujar_resultado_con_sombra(@sprites["resultado"].bitmap, 0, 20, 400, 40, "¡GAME OVER!", 1, Color.new(0, 0, 0, 255), Color.new(255, 100, 100))
        end
        @sprites["resultado"].bitmap.font.size = 24
        if @motivo_game_over == "tiempo"
          dibujar_resultado_con_sombra(@sprites["resultado"].bitmap, 0, 70, 400, 30, "¡Se acabó el tiempo!", 1, Color.new(0, 0, 0, 255), Color.new(255, 255, 0))
        else
          dibujar_resultado_con_sombra(@sprites["resultado"].bitmap, 0, 70, 400, 30, "¡Perdiste todas las vidas!", 1, Color.new(0, 0, 0, 255), Color.new(255, 255, 0))
        end
        dibujar_resultado_con_sombra(@sprites["resultado"].bitmap, 0, 100, 400, 30, "Vallas saltadas: #{@vallas_pasadas}/#{@vallas_objetivo}", 1, Color.new(0, 0, 0, 255), Color.new(255, 255, 0))
        dibujar_resultado_con_sombra(@sprites["resultado"].bitmap, 0, 130, 400, 30, "Puntuación Final: #{@puntuacion}", 1, Color.new(0, 0, 0, 255), Color.new(255, 255, 0))
      else
        @sprites["resultado"].bitmap.font.size = 32
        dibujar_resultado_con_sombra(@sprites["resultado"].bitmap, 0, 20, 400, 40, "¡Juego Terminado!", 1, Color.new(0, 0, 0, 255), Color.new(255, 100, 100))
        @sprites["resultado"].bitmap.font.size = 24
        dibujar_resultado_con_sombra(@sprites["resultado"].bitmap, 0, 70, 400, 30, "Vallas saltadas: #{@vallas_pasadas}/#{@vallas_objetivo}", 1, Color.new(0, 0, 0, 255), Color.new(255, 255, 0))
        dibujar_resultado_con_sombra(@sprites["resultado"].bitmap, 0, 100, 400, 30, "Puntuación Final: #{@puntuacion}", 1, Color.new(0, 0, 0, 255), Color.new(255, 255, 0))
      end
      
      @sprites["resultado"].bitmap.font.size = 18
      dibujar_resultado_con_sombra(@sprites["resultado"].bitmap, 0, 180, 400, 30, "Presiona C para continuar", 1, Color.new(0, 0, 0, 255), Color.new(200, 200, 200))
      
      @resultado_mostrado = true
      determinar_recompensa
    end
  end
  
  def determinar_recompensa
    # Solo dar recompensa si completa el minijuego (victoria)
    if @victoria
      @recompensa = { 
        objeto: :FULLRESTORE, 
        cantidad: 1, 
        mensaje: "¡Felicidades! ¡Completaste la primera prueba de la academia!",
        victoria: true
      }
    else
      # Para game over, no dar recompensa de objetos
      if @game_over
        if @motivo_game_over == "tiempo"
          @recompensa = { 
            mensaje: "¡Se acabó el tiempo! ¿Esto es todo lo que puedes hacer como policía?",
            game_over: true,
            motivo: "tiempo"
          }
        else
          @recompensa = { 
            mensaje: "¡Game Over! Inténtalo de nuevo para superar la prueba.",
            game_over: true,
            motivo: "vidas"
          }
        end
      else
        @recompensa = { 
          mensaje: "¡Inténtalo de nuevo para completar el desafío!",
          incompleto: true
        }
      end
    end
    
    @recompensa[:vallas_superadas] = @vallas_superadas
    @recompensa[:vallas_exitosas] = @vallas_pasadas
    @recompensa[:puntuacion] = @puntuacion
    @recompensa[:exito_rate] = (@vallas_pasadas.to_f / [@vallas_superadas, 1].max.to_f * 100).round
    @recompensa[:motivo_game_over] = @motivo_game_over if @game_over
  end
  
  def obtener_recompensa
    return @recompensa
  end
  
  def limpiar
    # Detener BGM correctamente
    begin
      pbBGMStop
      # Restaurar BGM anterior
      pbBGMPlay($game_system.bgm_memorize) if $game_system.bgm_memorize
    rescue
      puts "Error al restaurar BGM, continuando..."
    end
    
    # Limpiar bitmap del corazón
    @corazon_bitmap.dispose if @corazon_bitmap && !@corazon_bitmap.disposed?
    @corazon_bitmap = nil
    
    @sprites.each_value do |sprite| 
      if sprite && !sprite.disposed?
        sprite.bitmap.dispose if sprite.bitmap && !sprite.bitmap.disposed?
        sprite.dispose 
      end
    end
    @viewport.dispose if @viewport && !@viewport.disposed?
  end
  
  # Método principal para ejecutar el minijuego
  def self.jugar
    juego = MinijuegoSaltoValla.new
    
    loop do
      break unless juego.actualizar
    end
    
    recompensa = juego.obtener_recompensa
    juego.limpiar
    
    if recompensa
      if recompensa[:victoria]
        # Solo dar objeto al completar
        $bag.add(recompensa[:objeto], recompensa[:cantidad])
        pbMessage("¡Felicidades! ¡Has superado la primera prueba de la Academia Eón!")
      else
        # Solo mostrar mensaje sin dar objetos
        pbMessage(recompensa[:mensaje])
        if recompensa[:vallas_exitosas] && recompensa[:vallas_exitosas] > 0
          pbMessage("Progreso: #{recompensa[:vallas_exitosas]}/15 vallas saltadas exitosamente")
        end
      end
    end
    
    return recompensa
  end
end

#===============================================================================
# FUNCIÓN PARA LLAMAR EL MINIJUEGO DESDE EVENTOS CON TELEPORT MODIFICADO
#===============================================================================

def pbMinijuegoSaltoValla
  pbMessage("¡Debes completar 15 vallas antes de que se acabe el tiempo!")
  pbMessage("Empiezas con 60 segundos")
  pbMessage("Cada colisión te quita 5 segundos")
  pbMessage("Tienes 6 vidas - Si las pierdes todas, GAME OVER!")
  pbMessage("Usa ESPACIO o C para saltar")
  
  resultado = MinijuegoSaltoValla.jugar
  
  pbMessage("¡Gracias por jugar!")
  
  # TELEPORT MODIFICADO: Mapa 025, coordenadas (29,9), mirando a la derecha
  pbFadeOutIn do
    $game_map.setup(025)  # Mapa 025 con formato correcto
    $game_player.moveto(29, 9)  # Coordenadas (29,9)
    $game_player.direction = 6  # Dirección 6 = derecha (método correcto para v21)
    $game_map.autoplay
    $game_map.refresh
  end
  
  return resultado
end

#===============================================================================
# EJEMPLO DE USO EN EVENTOS:
#===============================================================================
# 
# Simplemente llama: pbMinijuegoSaltoValla
# 
# El minijuego se ejecutará y al terminar (sin importar el resultado)
# el jugador será teleportado al MAPA 025, coordenadas (29,9) mirando a la derecha
#
#===============================================================================do_con_sombra(@sprites["resultado"].bitmap, 0, 20, 400, 40, "¡COMPLETADO!", 1, Color.new(0, 0, 0, 255), Color.new(100, 255, 100))
    