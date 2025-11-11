#===============================================================================
# Minijuego de Ordenar Fotogramas para Pokémon Essentials v21
# Script completo corregido — Noviembre 2025 (navegación mejorada con fila inferior)
#===============================================================================

class FilmFrame
  attr_accessor :x, :y, :width, :height, :id, :origin_x, :origin_y
  attr_accessor :placed, :current_slot, :correct_slot, :filename, :filename_large

  def initialize(id, correct_slot, origin_x, origin_y, filename, filename_large)
    @id = id
    @correct_slot = correct_slot
    @width = 44
    @height = 84
    @origin_x = origin_x
    @origin_y = origin_y
    @filename = filename
    @filename_large = filename_large
    @x = origin_x
    @y = origin_y
    @placed = false
    @current_slot = nil
  end

  def is_correct_position?
    @placed && @current_slot == @correct_slot
  end
end

class FilmFrameScene
  SLOT_START_X = 0
  SLOT_START_Y = 300
  SLOT_WIDTH = 44
  SLOT_HEIGHT = 88
  SLOT_SPACING = 0

  PREVIEW_X = 170
  PREVIEW_Y = 40
  PREVIEW_WIDTH = 340
  PREVIEW_HEIGHT = 256

  GRID_ROWS = 3
  GRID_COLS = 4
  TOTAL_ROWS = 4
  BOTTOM_ROW_COLS = 12

  def initialize
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999

    @sprites = {}
    @frames = []
    @cursor_row = 0
    @cursor_col = 0
    @completed = false
    @dragging = false
    @bottom_slots = Array.new(12, nil)
    @selected_frame = nil
    @debug_mode = false
    @just_picked_up = false

    setup_background
    setup_preview_area
    setup_frames
    setup_bottom_slots

    @origin_positions = [
      [2, 40], [44, 40], [86, 40], [128, 40],
      [2, 126], [44, 126], [86, 126], [128, 126],
      [2, 212], [44, 212], [86, 212], [128, 212]
    ]

    @cursor_row = 0
    @cursor_col = 0

    setup_cursor
  end

  def setup_background
    @sprites["bg"] = Sprite.new(@viewport)
    @sprites["bg"].z = 0

    begin
      @sprites["bg"].bitmap = Bitmap.new("Graphics/Pictures/juicio/FondoFotogramas")
    rescue
      @sprites["bg"].bitmap = Bitmap.new(Graphics.width, Graphics.height)
      bmp = @sprites["bg"].bitmap

      dark_red = Color.new(80, 20, 20)
      bmp.fill_rect(0, 0, Graphics.width, 40, dark_red)

      gray = Color.new(90, 85, 80)
      bmp.fill_rect(0, 40, Graphics.width, Graphics.height - 40, gray)

      dark_gray = Color.new(60, 58, 55)
      y_positions = [40, 130, 220]
      for i in 0...3
        for j in 0...4
          x = j * 44
          y = y_positions[i]
          bmp.fill_rect(x, y, 44, 88, dark_gray)
          bmp.fill_rect(x + 2, y + 2, 40, 84, Color.new(70, 68, 65))
        end
      end

      bmp.fill_rect(PREVIEW_X - 2, PREVIEW_Y - 2, PREVIEW_WIDTH + 4, PREVIEW_HEIGHT + 4, Color.new(40, 38, 35))
      bmp.fill_rect(PREVIEW_X, PREVIEW_Y, PREVIEW_WIDTH, PREVIEW_HEIGHT, Color.new(70, 68, 65))

      for i in 0...12
        x = SLOT_START_X + (i * (SLOT_WIDTH + SLOT_SPACING))
        y = SLOT_START_Y
        bmp.fill_rect(x, y, 44, 88, dark_gray)
        bmp.fill_rect(x + 2, y + 2, 40, 84, Color.new(70, 68, 65))

        bmp.font.size = 20
        bmp.font.bold = true
        bmp.font.color = Color.new(180, 60, 60)
        text = "#{i + 1}"
        text_width = bmp.text_size(text).width
        text_x = x + 2 + (40 - text_width) / 2
        bmp.draw_text(text_x, y + 64, 40, 20, text)
      end

      puts "Advertencia: No se encontró Graphics/Pictures/juicio/FondoFotogramas.png — usando fondo de respaldo."
    end
  end

  def setup_preview_area
    @sprites["preview"] = Sprite.new(@viewport)
    @sprites["preview"].x = PREVIEW_X
    @sprites["preview"].y = PREVIEW_Y
    @sprites["preview"].z = 50
    @sprites["preview"].visible = false
  end

  def setup_frames
    frames_data = [
      [1, 1, 0, 42, "Fotograma1SalaVacia", "Fotograma1SalaVaciaGrande"],
      [2, 3, 44, 42, "Fotograma2SalaCerradaLlave", "Fotograma2SalaCerradaLlaveGrande"],
      [3, 2, 88, 42, "Fotograma3SalaCerradaPlan", "Fotograma3SalaCerradaPlanGrande"],
      [4, 5, 132, 42, "Fotograma4TaquillasPreaSesinato", "Fotograma4TaquillasPreaSesinatoGrande"],
      [5, 4, 0, 132, "Fotograma5SalaPintura", "Fotograma5SalaPinturaGrande"],
      [6, 7, 44, 132, "Fotograma6SalaCadaver", "Fotograma6SalaCadaverGrande"],
      [7, 9, 88, 132, "Fotograma7TaquillasPostAsesinato", "Fotograma7TaquillasPostAsesinatoGrande"],
      [8, 6, 132, 132, "Fotograma8SalaConserjePreCrimen", "Fotograma8SalaConserjePreCrimenGrande"],
      [9, 8, 0, 222, "Fotograma9SalaConserjePostCrimen", "Fotograma9SalaConserjePostCrimenGrande"],
      [10, 11, 44, 222, "Fotograma10SalaVaciaMechon", "Fotograma10SalaVaciaMechonGrande"],
      [11, 10, 88, 222, "Fotograma11ConductoEnsangrentado", "Fotograma11ConductoEnsangrentadoGrande"],
      [12, 12, 132, 222, "Fotograma12Salida", "Fotograma12SalidaGrande"]
    ]

    origin_positions = [
      [2, 40], [44, 40], [86, 40], [128, 40],
      [2, 126], [44, 126], [86, 126], [128, 126],
      [2, 212], [44, 212], [86, 212], [128, 212]
    ]

    origin_positions.shuffle!

    frames_data.each_with_index do |data, index|
      id, correct_slot, _, _, filename, filename_large = data
      ox, oy = origin_positions[index]

      frame = FilmFrame.new(id, correct_slot, ox, oy, filename, filename_large)
      @frames << frame

      sprite = Sprite.new(@viewport)
      begin
        sprite.bitmap = Bitmap.new("Graphics/Pictures/juicio/#{filename}")
      rescue
        sprite.bitmap = Bitmap.new(44, 84)
        sprite.bitmap.fill_rect(0, 0, 44, 84, Color.new(100, 80, 60))
        sprite.bitmap.fill_rect(2, 2, 40, 80, Color.new(120, 100, 80))
        sprite.bitmap.font.size = 16
        sprite.bitmap.font.bold = true
        sprite.bitmap.font.color = Color.new(255, 255, 255)
        sprite.bitmap.draw_text(0, 36, 44, 20, "#{id}", 1)
        puts "Advertencia: No se encontró Graphics/Pictures/juicio/#{filename}.png"
      end

      sprite.x = ox
      sprite.y = oy
      sprite.z = 100
      @sprites["frame_#{id}"] = sprite
    end
  end

  def setup_bottom_slots
  end

  def setup_cursor
    @sprites["cursor"] = Sprite.new(@viewport)
    @sprites["cursor"].z = 2000
    cursor_w = 44
    cursor_h = 84
    thickness = 2
    @sprites["cursor"].bitmap = Bitmap.new(cursor_w, cursor_h)
    yellow = Color.new(255, 220, 80)
    bmp = @sprites["cursor"].bitmap
    bmp.fill_rect(0, 0, cursor_w, thickness, yellow)
    bmp.fill_rect(0, cursor_h - thickness, cursor_w, thickness, yellow)
    bmp.fill_rect(0, 0, thickness, cursor_h, yellow)
    bmp.fill_rect(cursor_w - thickness, 0, thickness, cursor_h, yellow)
    @sprites["cursor"].visible = true

    @sprites["counter"] = Sprite.new(@viewport)
    @sprites["counter"].bitmap = Bitmap.new(512, 40)
    @sprites["counter"].x = 0
    @sprites["counter"].y = 0
    @sprites["counter"].z = 1500
    update_counter_text

    @sprites["debug"] = Sprite.new(@viewport)
    @sprites["debug"].bitmap = Bitmap.new(Graphics.width, Graphics.height)
    @sprites["debug"].z = 3000
    @sprites["debug"].visible = false

    update_cursor_visual
  end

  def get_frame_row(frame)
    y = frame.origin_y || frame.y
    row = ((y - 40) / 86).to_i
    [[0, row].max, 2].min
  end

  def get_frame_col(frame)
    x = frame.origin_x || frame.x
    col = ((x - 2) / (SLOT_WIDTH)).to_i
    [[0, col].max, 3].min
  end

  def update_counter_text
    @sprites["counter"].bitmap.clear

    correct_count = @frames.count { |f| f.is_correct_position? }
    total = @frames.length

    text = "ORDENADOS: #{correct_count}/#{total}"

    @sprites["counter"].bitmap.font.size = 24
    @sprites["counter"].bitmap.font.bold = true

    shadow = Color.new(0, 0, 0)
    base = Color.new(255, 220, 180)

    @sprites["counter"].bitmap.font.color = shadow
    @sprites["counter"].bitmap.draw_text(12, 12, 512, 32, text)

    @sprites["counter"].bitmap.font.color = base
    @sprites["counter"].bitmap.draw_text(10, 10, 512, 32, text)
  end

  def update
    Graphics.update
    Input.update

    if Input.trigger?(Input::AUX1)
      @debug_mode = !@debug_mode
      @sprites["debug"].visible = @debug_mode
      update_debug_display if @debug_mode
      pbSEPlay("GUI menu open") rescue nil
    end

    if @completed
      if Input.trigger?(Input::USE) || Input.trigger?(Input::BACK)
        return false
      end
      return true
    end

    if @dragging
      update_dragging
      return true
    else
      result = update_selection
      return result if result == false
    end

    update_debug_display if @debug_mode
    check_completion
    return true
  end

  def grid_index_to_coords(row, col)
    idx = row * GRID_COLS + col
    @origin_positions[idx]
  end

  def frame_at_grid(row, col)
    if row == 3
      slot_index = col
      frame_id = @bottom_slots[slot_index]
      return nil unless frame_id
      frame = @frames.find { |f| f.id == frame_id }
      return (frame && !frame.is_correct_position?) ? frame : nil
    end

    target_x, target_y = grid_index_to_coords(row, col)
    @frames.find do |f|
      next false if f.placed
      (f.x - target_x).abs <= 6 && (f.y - target_y).abs <= 6
    end
  end

  def find_next_occupied_slot(start_col, direction)
    current = start_col + direction

    while current >= 0 && current < 12
      frame_id = @bottom_slots[current]
      if frame_id
        frame = @frames.find { |f| f.id == frame_id }
        return current if frame && !frame.is_correct_position?
      end
      current += direction
    end

    nil
  end

  def find_closest_occupied_slot(reference_col)
    occupied = []
    12.times do |i|
      frame_id = @bottom_slots[i]
      if frame_id
        frame = @frames.find { |f| f.id == frame_id }
        occupied << i if frame && !frame.is_correct_position?
      end
    end

    return nil if occupied.empty?

    closest = occupied.min_by { |slot| (slot - reference_col).abs }
    closest
  end

  def update_selection
    old_row = @cursor_row
    old_col = @cursor_col

    if Input.repeat?(Input::RIGHT)
      if @cursor_row == 3
        next_slot = find_next_occupied_slot(@cursor_col, 1)
        @cursor_col = next_slot if next_slot
      else
        @cursor_col = (@cursor_col + 1) % GRID_COLS
      end
    elsif Input.repeat?(Input::LEFT)
      if @cursor_row == 3
        next_slot = find_next_occupied_slot(@cursor_col, -1)
        @cursor_col = next_slot if next_slot
      else
        @cursor_col = (@cursor_col - 1) % GRID_COLS
      end
    elsif Input.repeat?(Input::DOWN)
      if @cursor_row < 3
        new_row = @cursor_row + 1
        if new_row == 3
          closest_slot = find_closest_occupied_slot(@cursor_col)
          if closest_slot
            @cursor_row = 3
            @cursor_col = closest_slot
          end
        else
          @cursor_row = new_row
        end
      end
    elsif Input.repeat?(Input::UP)
      if @cursor_row == 3
        @cursor_row = 2
        @cursor_col = [@cursor_col / 3, 3].min
      else
        @cursor_row = (@cursor_row - 1) % GRID_ROWS
      end
    end

    update_cursor_visual if old_row != @cursor_row || old_col != @cursor_col

    frame = frame_at_grid(@cursor_row, @cursor_col)
    show_preview(frame) if frame

    if Input.trigger?(Input::USE)
      frame = frame_at_grid(@cursor_row, @cursor_col)

      if frame.nil?
        pbSEPlay("GUI buzzer") rescue nil
        return true
      end

      if frame.placed && frame.is_correct_position?
        pbSEPlay("GUI buzzer") rescue nil
        return true
      end

      if frame.placed
        slot_index = frame.current_slot - 1
        @bottom_slots[slot_index] = nil
        frame.placed = false
        frame.current_slot = nil
      end

      @dragging = true
      @selected_frame = frame
      @just_picked_up = true

      @sprites["frame_#{frame.id}"].z = 500
      @sprites["cursor"].z = 501

      pbSEPlay("GUI sel cursor") rescue nil
    end

    if Input.trigger?(Input::BACK)
      pbSEPlay("GUI menu close") rescue nil
      return false
    end

    return true
  end

  def update_cursor_visual
    if @cursor_row == 3
      slot_x = SLOT_START_X + (@cursor_col * (SLOT_WIDTH + SLOT_SPACING))
      slot_y = SLOT_START_Y

      frame_id = @bottom_slots[@cursor_col]
      if frame_id
        frame = @frames.find { |f| f.id == frame_id }
        if frame
          fsprite = @sprites["frame_#{frame.id}"]
          @sprites["cursor"].x = fsprite.x
          @sprites["cursor"].y = fsprite.y
          @sprites["cursor"].z = fsprite.z + 1
          return
        end
      end

      @sprites["cursor"].x = slot_x + 2
      @sprites["cursor"].y = slot_y + 2
      @sprites["cursor"].z = 1000
      return
    end

    target_x, target_y = grid_index_to_coords(@cursor_row, @cursor_col)

    frame = frame_at_grid(@cursor_row, @cursor_col)
    if frame
      fsprite = @sprites["frame_#{frame.id}"] rescue nil
      if fsprite
        @sprites["cursor"].x = fsprite.x
        @sprites["cursor"].y = fsprite.y
        @sprites["cursor"].z = fsprite.z + 1
        return
      end
    end

    @sprites["cursor"].x = target_x
    @sprites["cursor"].y = target_y
    @sprites["cursor"].z = 1000
  end

  def show_preview(frame)
    return unless frame

    begin
      @sprites["preview"].bitmap.dispose if @sprites["preview"].bitmap
      @sprites["preview"].bitmap = Bitmap.new("Graphics/Pictures/juicio/#{frame.filename_large}")
      @sprites["preview"].visible = true
    rescue
      @sprites["preview"].bitmap = Bitmap.new(PREVIEW_WIDTH, PREVIEW_HEIGHT)
      @sprites["preview"].bitmap.fill_rect(0, 0, PREVIEW_WIDTH, PREVIEW_HEIGHT, Color.new(120, 100, 80))
      @sprites["preview"].bitmap.fill_rect(10, 10, PREVIEW_WIDTH - 20, PREVIEW_HEIGHT - 20, Color.new(140, 120, 100))

      @sprites["preview"].bitmap.font.size = 32
      @sprites["preview"].bitmap.font.bold = true
      @sprites["preview"].bitmap.font.color = Color.new(255, 255, 255)
      text = "Fotograma #{frame.id}"
      @sprites["preview"].bitmap.draw_text(0, PREVIEW_HEIGHT / 2 - 16, PREVIEW_WIDTH, 32, text, 1)

      @sprites["preview"].visible = true

      puts "Advertencia: No se encontró Graphics/Pictures/juicio/#{frame.filename_large}.png"
    end
  end

  def hide_preview
    @sprites["preview"].visible = false
  end

  def update_dragging
    frame = @selected_frame
    sprite = @sprites["frame_#{frame.id}"]

    move_speed = 4

    if Input.press?(Input::LEFT)
      new_x = frame.x - move_speed
      if new_x >= 0
        frame.x = new_x
        sprite.x = frame.x
        @sprites["cursor"].x = frame.x
      end
      @just_picked_up = false
    elsif Input.press?(Input::RIGHT)
      new_x = frame.x + move_speed
      if new_x <= Graphics.width - frame.width
        frame.x = new_x
        sprite.x = frame.x
        @sprites["cursor"].x = frame.x
      end
      @just_picked_up = false
    end

    if Input.press?(Input::UP)
      new_y = frame.y - move_speed
      if new_y >= 40
        frame.y = new_y
        sprite.y = frame.y
        @sprites["cursor"].y = frame.y
      end
      @just_picked_up = false
    elsif Input.press?(Input::DOWN)
      new_y = frame.y + move_speed
      if new_y <= Graphics.height - frame.height
        frame.y = new_y
        sprite.y = frame.y
        @sprites["cursor"].y = frame.y
      end
      @just_picked_up = false
    end

    if Input.trigger?(Input::USE)
      if @just_picked_up
        @just_picked_up = false
        return
      end
      
      @dragging = false
      sprite.z = 100
      @sprites["cursor"].z = 1000
      place_in_slot(frame)
      hide_preview
      update_cursor_visual
      @selected_frame = nil
      @just_picked_up = false
    end

    if Input.trigger?(Input::BACK)
      @dragging = false
      sprite.z = 100
      @sprites["cursor"].z = 1000
      frame.x = frame.origin_x
      frame.y = frame.origin_y
      sprite.x = frame.origin_x
      sprite.y = frame.origin_y
      hide_preview
      update_cursor_visual
      @selected_frame = nil
      @just_picked_up = false
      pbSEPlay("GUI menu close") rescue nil
    end
  end

  def move_to_adjacent_slot(direction)
    return unless @selected_frame

    empty_slots = []
    @bottom_slots.each_with_index do |slot_content, index|
      empty_slots << index if slot_content.nil?
    end

    return if empty_slots.empty?

    if direction < 0
      target_slot = empty_slots.reverse.first
    else
      target_slot = empty_slots.first
    end

    frame = @selected_frame
    sprite = @sprites["frame_#{frame.id}"]

    target_x = SLOT_START_X + (target_slot * (SLOT_WIDTH + SLOT_SPACING)) + 2
    target_y = SLOT_START_Y + 2

    sprite.x = target_x
    sprite.y = target_y
    frame.x = target_x
    frame.y = target_y

    @sprites["cursor"].x = target_x
    @sprites["cursor"].y = target_y

    pbSEPlay("GUI sel cursor") rescue nil
  end

  def place_in_slot(frame)
    slot_index = find_nearest_slot(frame)

    if slot_index && @bottom_slots[slot_index].nil?
      @bottom_slots[slot_index] = frame.id
      frame.current_slot = slot_index + 1
      frame.placed = true

      bottom_positions = [
        [2, 298],   [44, 298],  [86, 298],  [128, 298],
        [170, 298], [212, 298], [254, 298], [296, 298],
        [338, 298], [380, 298], [422, 298], [464, 298]
      ]

      target_x, target_y = bottom_positions[slot_index]

      frame.x = target_x
      frame.y = target_y

      sprite = @sprites["frame_#{frame.id}"]
      sprite.x = target_x
      sprite.y = target_y

      update_counter_text

      if frame.is_correct_position?
        pbSEPlay("GUI party switch") rescue nil
      else
        pbSEPlay("GUI menu open") rescue nil
      end
    else
      sprite = @sprites["frame_#{frame.id}"]
      frame.x = frame.origin_x
      frame.y = frame.origin_y
      sprite.x = frame.origin_x
      sprite.y = frame.origin_y
      pbSEPlay("GUI buzzer") rescue nil
    end
  end

  def find_nearest_slot(frame)
    x = frame.x
    y = frame.y
    
    # Solo considerar si está cerca de la fila de slots (Y entre 270 y 350)
    return nil if y < 270 || y > 350
    
    best_slot = nil
    best_distance = Float::INFINITY

    12.times do |i|
      next if @bottom_slots[i]

      # Calcular el inicio de cada slot
      slot_x = SLOT_START_X + (i * (SLOT_WIDTH + SLOT_SPACING))
      
      # Calcular distancia desde el borde izquierdo del fotograma al inicio del slot
      distance = (x - slot_x).abs

      if distance < best_distance && distance < 25
        best_slot = i
        best_distance = distance
      end
    end

    best_slot
  end

  def check_completion
    return if @completed

    correct_count = @frames.count { |f| f.is_correct_position? }

    if correct_count == 12
      @completed = true
      pbSEPlay("GUI trainer victory") rescue nil
      show_completion_message
    end
  end

  def update_debug_display
    bmp = @sprites["debug"].bitmap
    bmp.clear

    bmp.font.size = 14
    bmp.font.bold = true

    green = Color.new(100, 255, 100)
    red = Color.new(255, 100, 100)
    yellow = Color.new(255, 255, 100)
    white = Color.new(255, 255, 255)
    black = Color.new(0, 0, 0)

    bmp.font.color = black
    bmp.draw_text(11, 391, 500, 20, "=== MODO DEPURACIÓN (F5 para ocultar) ===")
    bmp.font.color = yellow
    bmp.draw_text(10, 390, 500, 20, "=== MODO DEPURACIÓN (F5 para ocultar) ===")

    y_offset = 410
    bmp.font.color = black
    bmp.draw_text(11, y_offset + 1, 500, 20, "SLOTS INFERIORES:")
    bmp.font.color = white
    bmp.draw_text(10, y_offset, 500, 20, "SLOTS INFERIORES:")
    y_offset += 20

    12.times do |i|
      slot_x = SLOT_START_X + (i * (SLOT_WIDTH + SLOT_SPACING))
      slot_y = SLOT_START_Y

      text = "Slot #{i + 1}: X=#{slot_x}, Y=#{slot_y}"

      if @bottom_slots[i]
        frame = @frames.find { |f| f.id == @bottom_slots[i] }
        if frame && frame.is_correct_position?
          text += " [CORRECTO]"
          color = green
        else
          text += " [INCORRECTO]"
          color = red
        end
      else
        text += " [VACÍO]"
        color = white
      end

      bmp.font.color = black
      bmp.draw_text(11, y_offset + 1, 500, 16, text)
      bmp.font.color = color
      bmp.draw_text(10, y_offset, 500, 16, text)
      y_offset += 16
    end

    y_offset += 10

    if @selected_frame
      frame = @selected_frame
      bmp.font.color = black
      bmp.draw_text(11, y_offset + 1, 500, 20, "FRAME SELECCIONADO:")
      bmp.font.color = yellow
      bmp.draw_text(10, y_offset, 500, 20, "FRAME SELECCIONADO:")
      y_offset += 20

      info = [
        "ID: #{frame.id}",
        "Posición actual: X=#{frame.x}, Y=#{frame.y}",
        "Slot correcto: #{frame.correct_slot}",
        "Slot actual: #{frame.current_slot || 'Ninguno'}",
        "¿Colocado?: #{frame.placed ? 'Sí' : 'No'}",
        "Just picked up: #{@just_picked_up}"
      ]

      info.each do |line|
        bmp.font.color = black
        bmp.draw_text(11, y_offset + 1, 500, 16, line)
        bmp.font.color = white
        bmp.draw_text(10, y_offset, 500, 16, line)
        y_offset += 16
      end
    end

    12.times do |i|
      slot_x = SLOT_START_X + (i * (SLOT_WIDTH + SLOT_SPACING))
      slot_y = SLOT_START_Y

      if @bottom_slots[i]
        frame = @frames.find { |f| f.id == @bottom_slots[i] }
        border_color = frame && frame.is_correct_position? ? green : red
      else
        border_color = yellow
      end

      thickness = 2
      bmp.fill_rect(slot_x, slot_y, SLOT_WIDTH, thickness, border_color)
      bmp.fill_rect(slot_x, slot_y + SLOT_HEIGHT - thickness, SLOT_WIDTH, thickness, border_color)
      bmp.fill_rect(slot_x, slot_y, thickness, SLOT_HEIGHT, border_color)
      bmp.fill_rect(slot_x + SLOT_WIDTH - thickness, slot_y, thickness, SLOT_HEIGHT, border_color)
    end
  end

  def show_completion_message
    @sprites["overlay"] = Sprite.new(@viewport)
    @sprites["overlay"].bitmap = Bitmap.new(Graphics.width, Graphics.height)
    @sprites["overlay"].bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.new(0, 0, 0, 180))
    @sprites["overlay"].z = 2000

    @sprites["msgbox"] = Sprite.new(@viewport)
    @sprites["msgbox"].bitmap = Bitmap.new(350, 120)
    @sprites["msgbox"].bitmap.fill_rect(0, 0, 350, 120, Color.new(255, 255, 255))
    @sprites["msgbox"].bitmap.fill_rect(4, 4, 342, 112, Color.new(80, 20, 20))

    base = Color.new(255, 220, 180)
    shadow = Color.new(0, 0, 0)
    @sprites["msgbox"].bitmap.font.size = 28
    @sprites["msgbox"].bitmap.font.bold = true

    textpos = [
      ["¡SECUENCIA", 175, 25, 2, base, shadow],
      ["COMPLETA!", 175, 55, 2, base, shadow],
      ["Presiona X para salir", 175, 85, 2, base, shadow]
    ]

    textpos.each do |text_data|
      text, x, y, align, color, shadow_color = text_data
      @sprites["msgbox"].bitmap.font.color = shadow_color
      if align == 2
        text_width = @sprites["msgbox"].bitmap.text_size(text).width
        @sprites["msgbox"].bitmap.draw_text(x - text_width/2 + 2, y + 2, 350, 32, text)
        @sprites["msgbox"].bitmap.font.color = color
        @sprites["msgbox"].bitmap.draw_text(x - text_width/2, y, 350, 32, text)
      end
    end

    @sprites["msgbox"].x = (Graphics.width - 350) / 2
    @sprites["msgbox"].y = (Graphics.height - 120) / 2
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

def pbFilmFrame
  scene = FilmFrameScene.new
  loop do
    should_continue = scene.update
    break unless should_continue
  end
  completed = scene.instance_variable_get(:@completed)
  scene.dispose

  return completed
end

def start_film_frame
  pbFilmFrame
end