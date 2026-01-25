#===============================================================================
# Image Placer - Sistema de colocación de imágenes en pantalla
# Por Sky
# Versión mejorada para Pokémon Essentials v21
#===============================================================================

module ImagePlacer
  PICTURES_PATH = "Graphics/Pictures/"
  
  class ImageData
    attr_accessor :filename, :sprite, :x, :y, :zoom, :opacity, :blend_type
    
    def initialize(filename)
      @filename = filename
      @x = 0
      @y = 0
      @zoom = 100
      @opacity = 255
      @blend_type = 0
    end
    
    def create_sprite(viewport)
      @sprite = IconSprite.new(0, 0, viewport)
      @sprite.setBitmap(PICTURES_PATH + @filename)
      @sprite.z = 99999
      update_sprite
    end
    
    def update_sprite
      return unless @sprite
      @sprite.x = @x
      @sprite.y = @y
      @sprite.zoom_x = @zoom / 100.0
      @sprite.zoom_y = @zoom / 100.0
      @sprite.opacity = @opacity
      @sprite.blend_type = @blend_type
    end
    
    def dispose
      @sprite&.dispose
      @sprite = nil
    end
    
    def get_info_text
      blend_names = ["Normal", "Add", "Sub"]
      return "Pos: (#{@x}, #{@y}), #{@zoom}%, opacidad: #{@opacity}/255, blend: #{blend_names[@blend_type]}."
    end
  end
end

#===============================================================================
# Selector de archivos
#===============================================================================
def pbPictureFileSelection
  files = []
  Dir.glob(ImagePlacer::PICTURES_PATH + "*.{png,PNG}").each do |file|
    filename = File.basename(file, ".*")
    files.push(filename) unless files.include?(filename)
  end
  files.sort!
  
  if files.empty?
    pbMessage("No se encontraron imágenes en #{ImagePlacer::PICTURES_PATH}")
    return nil
  end
  
  commands = files + ["Cancelar"]
  choice = pbShowCommands(nil, commands, -1)
  
  return nil if choice < 0 || choice >= files.length
  return files[choice]
end

#===============================================================================
# Escena principal del editor de imágenes
#===============================================================================
class ImagePlacerScene
  def pbStartScene
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99998
    @images = []
  end
  
  def pbMain
    loop do
      commands = ["Añadir imagen", "Editar imagen", "Salir"]
      choice = pbMessage("Bienvenido al Image Placer. Elige una opción.", commands, -1)
      
      case choice
      when 0 # Añadir imagen
        pbAddImage
      when 1 # Editar imagen
        if @images.length > 0
          pbEditImage
        else
          pbMessage("No hay imágenes para editar.")
        end
      else # Salir
        break if pbConfirmMessage("¿Salir del editor?")
      end
    end
  end
  
  def pbAddImage
    filename = pbPictureFileSelection
    return if !filename
    
    # Verificar que el archivo existe
    full_path = ImagePlacer::PICTURES_PATH + filename
    if !pbResolveBitmap(full_path)
      pbMessage("No se pudo cargar la imagen '#{filename}'.")
      return
    end
    
    image_data = ImagePlacer::ImageData.new(filename)
    begin
      image_data.create_sprite(@viewport)
      @images.push(image_data)
      pbMessage("Imagen '#{filename}' añadida en (0, 0).")
    rescue
      pbMessage("Error al cargar la imagen '#{filename}'.")
    end
  end
  
  def pbEditImage
    # Seleccionar imagen
    commands = @images.map.with_index { |img, i| "#{i + 1}. #{img.filename} (#{img.x}, #{img.y})" }
    commands.push("Cancelar")
    
    choice = pbShowCommands(nil, commands, -1)
    return if choice < 0 || choice >= @images.length
    
    selected_image = @images[choice]
    
    # Menú de edición
    loop do
      info = selected_image.get_info_text
      edit_commands = [
        "Posición",
        "Zoom",
        "Opacidad",
        "Blending",
        "Quitar imagen",
        "Volver"
      ]
      
      edit_choice = pbMessage(info, edit_commands, -1)
      
      case edit_choice
      when 0 # Posición
        pbEditPosition(selected_image)
      when 1 # Zoom
        pbEditZoom(selected_image)
      when 2 # Opacidad
        pbEditOpacity(selected_image)
      when 3 # Blending
        pbEditBlending(selected_image)
      when 4 # Quitar imagen
        if pbConfirmMessage("¿Quitar la imagen '#{selected_image.filename}'?")
          selected_image.dispose
          @images.delete(selected_image)
          pbMessage("Imagen eliminada.")
          break
        end
      else # Volver
        break
      end
    end
  end
  
  def pbEditPosition(image)
    msgwindow = pbCreateMessageWindow
    pbMessageDisplay(msgwindow, "\\l[1]Posición: (#{image.x}, #{image.y})", false)
    
    loop do
      Graphics.update
      Input.update
      pbUpdateSceneMap
      
      moved = false
      
      if Input.press?(Input::LEFT)
        image.x -= 1
        moved = true
      elsif Input.press?(Input::RIGHT)
        image.x += 1
        moved = true
      elsif Input.press?(Input::UP)
        image.y -= 1
        moved = true
      elsif Input.press?(Input::DOWN)
        image.y += 1
        moved = true
      end
      
      if moved
        image.update_sprite
        pbMessageDisplay(msgwindow, "\\l[1]Posición: (#{image.x}, #{image.y})", false)
      end
      
      if Input.trigger?(Input::USE)
        pbPlayDecisionSE
        break
      elsif Input.trigger?(Input::BACK)
        pbPlayCancelSE
        break
      end
    end
    
    pbDisposeMessageWindow(msgwindow)
    pbMessage("Posición final: (#{image.x}, #{image.y})")
  end
  
  def pbEditZoom(image)
    msgwindow = pbCreateMessageWindow
    pbMessageDisplay(msgwindow, "\\l[1]Zoom: #{image.zoom}%.", false)
    
    loop do
      Graphics.update
      Input.update
      pbUpdateSceneMap
      
      changed = false
      
      if Input.repeat?(Input::UP)
        image.zoom += 1
        image.zoom = [image.zoom, 500].min
        changed = true
      elsif Input.repeat?(Input::DOWN)
        image.zoom -= 1
        image.zoom = [image.zoom, 1].max
        changed = true
      end
      
      if changed
        image.update_sprite
        pbMessageDisplay(msgwindow, "\\l[1]Zoom: #{image.zoom}%.", false)
      end
      
      if Input.trigger?(Input::USE)
        pbPlayDecisionSE
        break
      elsif Input.trigger?(Input::BACK)
        pbPlayCancelSE
        break
      end
    end
    
    pbDisposeMessageWindow(msgwindow)
  end
  
  def pbEditOpacity(image)
    msgwindow = pbCreateMessageWindow
    pbMessageDisplay(msgwindow, "Opacidad: #{image.opacity}/255\nUsa ARRIBA/ABAJO para ajustar. ENTER para confirmar.", false)
    
    loop do
      Graphics.update
      Input.update
      pbUpdateMsgWindow(msgwindow)
      
      changed = false
      
      if Input.repeat?(Input::UP)
        image.opacity += 5
        image.opacity = [image.opacity, 255].min
        changed = true
      elsif Input.repeat?(Input::DOWN)
        image.opacity -= 5
        image.opacity = [image.opacity, 0].max
        changed = true
      end
      
      if changed
        image.update_sprite
        pbMessageDisplay(msgwindow, "Opacidad: #{image.opacity}/255\nUsa ARRIBA/ABAJO para ajustar. ENTER para confirmar.", false)
      end
      
      if Input.trigger?(Input::USE)
        pbPlayDecisionSE
        break
      elsif Input.trigger?(Input::BACK)
        pbPlayCancelSE
        break
      end
    end
    
    pbDisposeMessageWindow(msgwindow)
  end
  
  def pbEditBlending(image)
    blend_names = ["Normal", "Add", "Sub"]
    
    loop do
      commands = blend_names.map.with_index do |name, i|
        image.blend_type == i ? "#{name} ◀" : name
      end
      commands.push("Confirmar")
      
      choice = pbShowCommands(nil, commands, -1)
      
      if choice >= 0 && choice < 3
        image.blend_type = choice
        image.update_sprite
      else
        break
      end
    end
  end
  
  def pbEndScene
    @images.each { |img| img.dispose }
    @images.clear
    @viewport.dispose
  end
end

class ImagePlacerScreen
  def initialize(scene)
    @scene = scene
  end
  
  def pbStartScreen
    @scene.pbStartScene
    @scene.pbMain
    @scene.pbEndScene
  end
end

#===============================================================================
# Método para llamar desde eventos
#===============================================================================
def pbImagePlacer
  scene = ImagePlacerScene.new
  screen = ImagePlacerScreen.new(scene)
  screen.pbStartScreen
end