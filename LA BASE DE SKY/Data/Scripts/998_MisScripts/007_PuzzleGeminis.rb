#===============================================================================
# Minijuego de Puzzle para Pokémon Essentials v21
# Coloca las piezas en sus posiciones correctas
#===============================================================================

class PuzzlePiece
  attr_accessor :x, :y, :width, :height, :rotation, :correct_positions
  attr_accessor :placed, :id, :origin_x, :origin_y, :filename, :in_origin
  attr_accessor :pair_id
  
  def initialize(id, width, height, correct_positions, origin_x, origin_y, filename, pair_id)
    @id = id
    @width = width
    @height = height
    @correct_positions = correct_positions  # Array de posiciones válidas
    @origin_x = origin_x
    @origin_y = origin_y
    @filename = filename
    @pair_id = pair_id
    @x = origin_x
    @y = origin_y
    @rotation = 0
    @placed = false
    @in_origin = true
    @placed_at = nil  # Guarda en qué posición se colocó
  end
  
  def rotate
    @rotation = (@rotation + 90) % 360
  end
  
  def current_width
    (@rotation == 90 || @rotation == 270) ? @height : @width
  end
  
  def current_height
    (@rotation == 90 || @rotation == 270) ? @width : @height
  end
  
  def is_correct_position?
    return false unless @placed
    return @placed_at != nil
  end
  
  def find_best_position
    return nil unless @rotation == 0
    
    best_pos = nil
    best_distance = Float::INFINITY
    
    @correct_positions.each do |pos|
      dx = (@x - pos[:x]).abs
      dy = (@y - pos[:y]).abs
      distance = Math.sqrt(dx * dx + dy * dy)
      
      if distance < best_distance && distance < 20
        best_pos = pos
        best_distance = distance
      end
    end
    
    best_pos
  end
end

class PuzzleMinigame
  UNIT = 32
  
  def initialize
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    
    @sprites = {}
    @pieces = []
    @cursor_index = 0
    @completed = false
    @dragging = false
    @occupied_positions = {}  # Registra qué posiciones están ocupadas
    
    setup_background
    setup_piece_slots
    setup_pieces
    setup_cursor
  end
  
  def setup_background
    @sprites["bg"] = Sprite.new(@viewport)
    @sprites["bg"].z = 0
    
    begin
      @sprites["bg"].bitmap = Bitmap.new("Graphics/Pictures/juicio/FondoPuzzleGeminis")
    rescue
      @sprites["bg"].bitmap = Bitmap.new(Graphics.width, Graphics.height)
      bmp = @sprites["bg"].bitmap
      gray = Color.new(70, 70, 80)
      dark = Color.new(20, 25, 35)
      
      bmp.fill_rect(0, 0, Graphics.width, Graphics.height, gray)
      
      left_border = Color.new(180, 180, 190)
      bmp.fill_rect(8, 16, 144, 336, dark)
      bmp.fill_rect(6, 14, 148, 340, left_border)
      bmp.fill_rect(8, 16, 144, 336, dark)
      
      bmp.fill_rect(160, 16, 352, 272, dark)
      bmp.fill_rect(158, 14, 356, 276, left_border)
      bmp.fill_rect(160, 16, 352, 272, dark)
      
      bmp.fill_rect(160, 304, 352, 48, dark)
      bmp.fill_rect(158, 302, 356, 52, left_border)
      bmp.fill_rect(160, 304, 352, 48, dark)
      
      puts "Advertencia: No se encontró Graphics/Pictures/juicio/FondoPuzzleGeminis.png"
    end
  end
  
  def setup_piece_slots
    # YA NO NECESITAMOS SLOTS GRISES - el fondo ya los tiene
  end
  
  def setup_pieces
    # Sistema de 8 piezas: 4 pares, cada pieza puede ir en cualquiera de las 2 posiciones de su tipo
    # [id, filename, filename_rojo, ancho, alto, posiciones_correctas, origin_x, origin_y, visible, pair_id]
    pieces_data = [
      # Par 1: Cuadrados 32x32
      [1, "PiezaCuadrada32x32", "PiezaCuadrada32x32Roja", 32, 32, [{x: 449, y: 32}, {x: 480, y: 32}], 65, 64, true, 1],
      [2, "PiezaCuadrada32x32", "PiezaCuadrada32x32Roja", 32, 32, [{x: 449, y: 32}, {x: 480, y: 32}], 65, 64, false, 1],
      
      # Par 2: Rectángulos 96x32
      [3, "PiezaRectangular96x32", "PiezaRectangular96x32Roja", 96, 32, [{x: 256, y: 64}, {x: 288, y: 192}], 32, 128, true, 2],
      [4, "PiezaRectangular96x32", "PiezaRectangular96x32Roja", 96, 32, [{x: 256, y: 64}, {x: 288, y: 192}], 32, 128, false, 2],
      
      # Par 3: Rectángulos de pie 64x64
      [5, "PiezaRectangulardePie64x64", "PiezaRectangulardePie64x64Roja", 64, 64, [{x: 255, y: 97}, {x: 351, y: 125}], 35, 193, true, 3],
      [6, "PiezaRectangulardePie64x64", "PiezaRectangulardePie64x64Roja", 64, 64, [{x: 255, y: 97}, {x: 351, y: 125}], 35, 193, false, 3],
      
      # Par 4: Rectángulos 64x32
      [7, "PiezaRectangular64X32", "PiezaRectangular64X32Roja", 64, 32, [{x: 160, y: 225}, {x: 384, y: 193}], 32, 289, true, 4],
      [8, "PiezaRectangular64X32", "PiezaRectangular64X32Roja", 64, 32, [{x: 160, y: 225}, {x: 384, y: 193}], 32, 289, false, 4]
    ]
    
    pieces_data.each do |data|
      id, filename, filename_rojo, width, height, positions, ox, oy, visible, pair_id = data
      
      piece = PuzzlePiece.new(id, width, height, positions, ox, oy, filename, pair_id)
      piece.in_origin = visible
      piece.instance_variable_set(:@filename_rojo, filename_rojo)
      @pieces << piece
      
      sprite = Sprite.new(@viewport)
      
      begin
        sprite.bitmap = Bitmap.new("Graphics/Pictures/juicio/#{filename}")
      rescue
        sprite.bitmap = Bitmap.new(width, height)
        sprite.bitmap.fill_rect(0, 0, width, height, Color.new(180, 40, 40))
        sprite.bitmap.fill_rect(2, 2, width-4, height-4, Color.new(200, 50, 50))
        puts "Advertencia: No se encontró Graphics/Pictures/juicio/#{filename}.png"
      end
      
      sprite.x = ox
      sprite.y = oy
      sprite.z = 100
      sprite.visible = visible
      @sprites["piece_#{id}"] = sprite
    end
  end
  
  def setup_cursor
    @sprites["cursor"] = Sprite.new(@viewport)
    @sprites["cursor"].z = 1000
    
    @sprites["counter"] = Sprite.new(@viewport)
    @sprites["counter"].bitmap = Bitmap.new(350, 50)
    @sprites["counter"].x = 160
    @sprites["counter"].y = 310
    @sprites["counter"].z = 1500
    update_counter_text
    
    # Sprite para mostrar coordenadas (modo depuración - opcional)
    @sprites["debug"] = Sprite.new(@viewport)
    @sprites["debug"].bitmap = Bitmap.new(250, 30)
    @sprites["debug"].x = 10
    @sprites["debug"].y = Graphics.height - 40
    @sprites["debug"].z = 3000
    @sprites["debug"].visible = false
    
    update_cursor_visual
  end
  
  def update_counter_text
    @sprites["counter"].bitmap.clear
    
    # Contar TODAS las piezas colocadas correctamente (8 en total)
    placed_count = @pieces.count { |p| p.is_correct_position? }
    total = @pieces.length  # Total = 8 piezas
    
    text = "#{placed_count}/#{total} PIEZAS"
    
    @sprites["counter"].bitmap.font.size = 32
    @sprites["counter"].bitmap.font.bold = true
    
    base = Color.new(80, 200, 180)
    shadow = Color.new(20, 80, 70)
    
    text_width = @sprites["counter"].bitmap.text_size(text).width
    x_pos = (@sprites["counter"].bitmap.width - text_width) / 2
    
    @sprites["counter"].bitmap.font.color = shadow
    @sprites["counter"].bitmap.draw_text(x_pos + 2, 12, 350, 32, text)
    
    @sprites["counter"].bitmap.font.color = base
    @sprites["counter"].bitmap.draw_text(x_pos, 10, 350, 32, text)
  end
  
  def update_cursor_visual
    piece = @pieces[@cursor_index]
    
    # No seleccionar piezas ya colocadas correctamente (bloqueadas)
    unless @sprites["piece_#{piece.id}"].visible && !piece.is_correct_position?
      original_index = @cursor_index
      loop do
        @cursor_index = (@cursor_index + 1) % @pieces.length
        piece = @pieces[@cursor_index]
        # Verificar que no esté bloqueada
        is_locked = piece.instance_variable_get(:@locked)
        break if (@sprites["piece_#{piece.id}"].visible && !piece.is_correct_position? && !is_locked) || @cursor_index == original_index
      end
    end
    
    w = piece.current_width
    h = piece.current_height
    
    if w <= 32 && h <= 32
      margin = 4
    elsif w >= 64 || h >= 64
      margin = 8
    else
      margin = 6
    end
    
    cursor_w = w + (margin * 2)
    cursor_h = h + (margin * 2)
    
    @sprites["cursor"].bitmap.dispose if @sprites["cursor"].bitmap
    @sprites["cursor"].bitmap = Bitmap.new(cursor_w, cursor_h)
    
    thickness = (w >= 64 || h >= 64) ? 3 : 2
    
    yellow = Color.new(80, 200, 180)  #Azul turquesa para probar por eso no cambie el yelllow por blue.
    @sprites["cursor"].bitmap.fill_rect(0, 0, cursor_w, thickness, yellow)
    @sprites["cursor"].bitmap.fill_rect(0, cursor_h - thickness, cursor_w, thickness, yellow)
    @sprites["cursor"].bitmap.fill_rect(0, 0, thickness, cursor_h, yellow)
    @sprites["cursor"].bitmap.fill_rect(cursor_w - thickness, 0, thickness, cursor_h, yellow)
    
    if w >= 64 || h >= 64
      corner_size = 8
      @sprites["cursor"].bitmap.fill_rect(0, 0, corner_size, thickness + 1, yellow)
      @sprites["cursor"].bitmap.fill_rect(0, 0, thickness + 1, corner_size, yellow)
      @sprites["cursor"].bitmap.fill_rect(cursor_w - corner_size, 0, corner_size, thickness + 1, yellow)
      @sprites["cursor"].bitmap.fill_rect(cursor_w - thickness - 1, 0, thickness + 1, corner_size, yellow)
      @sprites["cursor"].bitmap.fill_rect(0, cursor_h - thickness - 1, corner_size, thickness + 1, yellow)
      @sprites["cursor"].bitmap.fill_rect(0, cursor_h - corner_size, thickness + 1, corner_size, yellow)
      @sprites["cursor"].bitmap.fill_rect(cursor_w - corner_size, cursor_h - thickness - 1, corner_size, thickness + 1, yellow)
      @sprites["cursor"].bitmap.fill_rect(cursor_w - thickness - 1, cursor_h - corner_size, thickness + 1, corner_size, yellow)
    end
    
    @sprites["cursor"].x = piece.x - margin
    @sprites["cursor"].y = piece.y - margin
  end
  
  def update
    Graphics.update
    Input.update
    
    if @completed
      # Salir automáticamente después de mostrar el mensaje
      if Input.trigger?(Input::USE) || Input.trigger?(Input::BACK)
        return false  # Esto terminará el loop y saldrá del minijuego
      end
      return true
    end
    
    if @dragging
      update_dragging
    else
      update_selection
    end
    
    check_completion
    return true
  end
  
  def update_selection
    old_index = @cursor_index
    
    if Input.repeat?(Input::DOWN) || Input.repeat?(Input::RIGHT)
      loop do
        @cursor_index = (@cursor_index + 1) % @pieces.length
        piece = @pieces[@cursor_index]
        is_locked = piece.instance_variable_get(:@locked)
        break if @cursor_index == old_index || (@sprites["piece_#{piece.id}"].visible && !piece.is_correct_position? && !is_locked)
      end
    elsif Input.repeat?(Input::UP) || Input.repeat?(Input::LEFT)
      loop do
        @cursor_index = (@cursor_index - 1) % @pieces.length
        piece = @pieces[@cursor_index]
        is_locked = piece.instance_variable_get(:@locked)
        break if @cursor_index == old_index || (@sprites["piece_#{piece.id}"].visible && !piece.is_correct_position? && !is_locked)
      end
    end
    
    update_cursor_visual if old_index != @cursor_index
    
    if Input.trigger?(Input::USE)
      piece = @pieces[@cursor_index]
      
      if piece.is_correct_position?
        pbSEPlay("GUI buzzer") rescue nil
        return
      end
      
      @dragging = true
      
      # Mostrar la pieza hermana si esta pieza estaba en origen
      if piece.in_origin
        @pieces.each do |p|
          if p.pair_id == piece.pair_id && p.id != piece.id && !p.placed
            @sprites["piece_#{p.id}"].visible = true
            p.in_origin = true
            break
          end
        end
      end
      
      piece.in_origin = false
      
      @sprites["piece_#{piece.id}"].z = 500
      @sprites["cursor"].z = 501
    end
    
    if Input.trigger?(Input::ACTION)
      piece = @pieces[@cursor_index]
      
      if piece.is_correct_position?
        pbSEPlay("GUI buzzer") rescue nil
        return
      end
      
      rotate_piece(@cursor_index)
    end
    
    if Input.trigger?(Input::BACK)
      return false
    end
  end
  
  def rotate_piece(index)
    piece = @pieces[index]
    sprite = @sprites["piece_#{piece.id}"]
    
    piece.rotate
    
    begin
      original = Bitmap.new("Graphics/Pictures/juicio/#{piece.filename}")
      w = piece.current_width
      h = piece.current_height
      
      sprite.bitmap.dispose
      sprite.bitmap = Bitmap.new(w, h)
      
      case piece.rotation
      when 0
        sprite.bitmap.blt(0, 0, original, Rect.new(0, 0, original.width, original.height))
      when 90
        for x in 0...original.width
          for y in 0...original.height
            sprite.bitmap.set_pixel(original.height - 1 - y, x, original.get_pixel(x, y))
          end
        end
      when 180
        for x in 0...original.width
          for y in 0...original.height
            sprite.bitmap.set_pixel(original.width - 1 - x, original.height - 1 - y, original.get_pixel(x, y))
          end
        end
      when 270
        for x in 0...original.width
          for y in 0...original.height
            sprite.bitmap.set_pixel(y, original.width - 1 - x, original.get_pixel(x, y))
          end
        end
      end
      
      original.dispose
    rescue
      sprite.bitmap.dispose
      sprite.bitmap = Bitmap.new(w, h)
      sprite.bitmap.fill_rect(0, 0, w, h, Color.new(200, 50, 50))
    end
    
    update_cursor_visual
  end
  
  def update_dragging
    piece = @pieces[@cursor_index]
    sprite = @sprites["piece_#{piece.id}"]
    
    # Velocidad mejorada: más lenta para precisión
    speed = Input.press?(Input::SPECIAL) ? 1 : 4
    
    piece.y -= speed if Input.press?(Input::UP)
    piece.y += speed if Input.press?(Input::DOWN)
    piece.x -= speed if Input.press?(Input::LEFT)
    piece.x += speed if Input.press?(Input::RIGHT)
    
    piece.x = [[piece.x, 0].max, Graphics.width - piece.current_width].min
    piece.y = [[piece.y, 0].max, Graphics.height - piece.current_height].min
    
    sprite.x = piece.x
    sprite.y = piece.y
    
    margin = if piece.width <= 32 && piece.height <= 32
               4
             elsif piece.width >= 64 || piece.height >= 64
               8
             else
               6
             end
    
    @sprites["cursor"].x = piece.x - margin
    @sprites["cursor"].y = piece.y - margin
    
    if Input.trigger?(Input::USE)
      @dragging = false
      sprite.z = 100
      @sprites["cursor"].z = 1000
      @sprites["debug"].visible = false
      snap_piece(piece)
      update_cursor_visual
    end
    
    if Input.trigger?(Input::BACK)
      @dragging = false
      return_to_origin(piece)
      sprite.z = 100
      @sprites["cursor"].z = 1000
      @sprites["debug"].visible = false
      update_cursor_visual
    end
  end
  
  def snap_piece(piece)
    # Buscar la mejor posición disponible cerca de la pieza
    best_pos = piece.find_best_position
    
    if best_pos && !is_position_occupied?(best_pos)
      # Colocar la pieza
      piece.x = best_pos[:x]
      piece.y = best_pos[:y]
      piece.placed = true
      piece.instance_variable_set(:@placed_at, best_pos)
      
      # Registrar posición como ocupada
      mark_position_occupied(best_pos, piece.id)
      
      # OCULTAR la pieza original
      @sprites["piece_#{piece.id}"].visible = false
      
      # CREAR un nuevo sprite rojo en la posición correcta
      filename_rojo = piece.instance_variable_get(:@filename_rojo)
      sprite_rojo_key = "piece_placed_#{piece.id}"
      
      @sprites[sprite_rojo_key] = Sprite.new(@viewport)
      @sprites[sprite_rojo_key].x = best_pos[:x]
      @sprites[sprite_rojo_key].y = best_pos[:y]
      @sprites[sprite_rojo_key].z = 150
      
      begin
        @sprites[sprite_rojo_key].bitmap = Bitmap.new("Graphics/Pictures/juicio/#{filename_rojo}")
      rescue
        # Si no existe la imagen roja, crear un rectángulo rojo
        @sprites[sprite_rojo_key].bitmap = Bitmap.new(piece.width, piece.height)
        @sprites[sprite_rojo_key].bitmap.fill_rect(0, 0, piece.width, piece.height, Color.new(220, 50, 50))
        puts "Advertencia: No se encontró Graphics/Pictures/juicio/#{filename_rojo}.png"
      end
      
      # Marcar como bloqueada
      piece.instance_variable_set(:@locked, true)
      
      update_counter_text
      pbSEPlay("GUI party switch") rescue nil
    else
      piece.placed = false
    end
  end
  
  def is_position_occupied?(pos)
    @occupied_positions.key?("#{pos[:x]}_#{pos[:y]}")
  end
  
  def mark_position_occupied(pos, piece_id)
    @occupied_positions["#{pos[:x]}_#{pos[:y]}"] = piece_id
  end
  
  def unmark_position(pos)
    @occupied_positions.delete("#{pos[:x]}_#{pos[:y]}") if pos
  end
  
  def return_to_origin(piece)
    # Liberar la posición que ocupaba
    if piece.instance_variable_get(:@placed_at)
      unmark_position(piece.instance_variable_get(:@placed_at))
      piece.instance_variable_set(:@placed_at, nil)
    end
    
    # Ocultar pieza hermana si está visible y en origen
    @pieces.each do |p|
      if p.pair_id == piece.pair_id && p.id != piece.id && p.in_origin && @sprites["piece_#{p.id}"].visible
        @sprites["piece_#{p.id}"].visible = false
        break
      end
    end
    
    piece.x = piece.origin_x
    piece.y = piece.origin_y
    piece.in_origin = true
    piece.placed = false
    
    @sprites["piece_#{piece.id}"].x = piece.x
    @sprites["piece_#{piece.id}"].y = piece.y
    @sprites["piece_#{piece.id}"].z = 100
    @sprites["piece_#{piece.id}"].visible = true
    
    update_counter_text
  end
  
  def check_completion
    return if @completed
    
    # Verificar que las 8 piezas estén colocadas correctamente
    placed_count = @pieces.count { |p| p.is_correct_position? }
    
    if placed_count == 8
      @completed = true
      pbSEPlay("GUI trainer victory") rescue nil
      show_completion_message
    end
  end
  
  def show_completion_message
    @sprites["overlay"] = Sprite.new(@viewport)
    @sprites["overlay"].bitmap = Bitmap.new(Graphics.width, Graphics.height)
    @sprites["overlay"].bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(0, 0, 0, 180))
    @sprites["overlay"].z = 2000
    
    @sprites["msgbox"] = Sprite.new(@viewport)
    @sprites["msgbox"].bitmap = Bitmap.new(300, 100)
    @sprites["msgbox"].bitmap.fill_rect(0, 0, 300, 100, Color.new(255, 255, 255))
    @sprites["msgbox"].bitmap.fill_rect(4, 4, 292, 92, Color.new(60, 180, 100))
    
    base = Color.new(255, 255, 255)
    shadow = Color.new(0, 100, 50)
    pbSetSystemFont(@sprites["msgbox"].bitmap) rescue nil
    
    textpos = [
      ["¡ENHORABUENA!", 150, 30, 2, base, shadow],
      ["¡COMPLETADO!", 150, 50, 2, base, shadow],
      ["Presiona X para salir", 150, 70, 2, base, shadow]
    ]
    pbDrawTextPositions(@sprites["msgbox"].bitmap, textpos)
    
    @sprites["msgbox"].x = (Graphics.width - 300) / 2
    @sprites["msgbox"].y = (Graphics.height - 100) / 2
    @sprites["msgbox"].z = 2001
  end
  
  def dispose
    @sprites.each_value do |sprite|
      sprite.bitmap&.dispose
      sprite.dispose
    end
    @viewport.dispose
  end
end

def pbPuzzleMinigame
  scene = PuzzleMinigame.new
  loop do
    should_continue = scene.update
    break unless should_continue
  end
  completed = scene.instance_variable_get(:@completed)
  scene.dispose
  
  return completed
end

def start_puzzle_minigame
  pbPuzzleMinigame
end