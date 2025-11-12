class Battle::Scene::PokemonDataBox

  alias __types__initializeOtherGraphics initializeOtherGraphics unless method_defined?(:__types__initializeOtherGraphics)  
  def initializeOtherGraphics(*args)
    @types_x = (@battler.opposes?(0)) ? 210 : 0 # 1era variable oponente 2da variable jugador
    @types_bitmap = AnimatedBitmap.new("Graphics/UI/Battle/types_ico")
    @types_sprite = Sprite.new(viewport)
    height_per_icon = @types_bitmap.height / GameData::Type.count
    separacion_extra = 2 # Ajusta este valor según necesites
  
    # Calcula el alto total necesario para el bitmap de @types_sprite
    # Esto asume que @battler puede tener hasta 2 tipos, ajusta según sea necesario
    # total_height = @battler.types.size * height_per_icon + (@battler.types.size - 1) * separacion_extra
  
    # Ajusta la posición inicial en Y para @types_sprite si es necesario
    @types_y = (@battler.types.size == 1) ? 10 : 0  #-total_height + 68
    total_height = (height_per_icon + separacion_extra) * 2 
    # Crea el bitmap de @types_sprite con el ancho y alto adecuados
    @types_sprite.bitmap = Bitmap.new(@databoxBitmap.width - @types_x, total_height)
    @types_sprite.x = @types_x
    @types_sprite.y = @types_y
  
    @sprites["types_sprite"] = @types_sprite
  
    # Llama al método original para continuar la inicialización
    __types__initializeOtherGraphics(*args)
  end
  
  alias __types__dispose dispose unless method_defined?(:__types__dispose)  
  def dispose(*args)
    __types__dispose(*args)
    @types_bitmap.dispose
  end

  alias __types__set_x x= unless method_defined?(:__types__set_x)
  def x=(value)
    __types__set_x(value)
    extra = (@battler.opposes?(0)) ? 10 : 0
    @types_sprite.x = value + @types_x + 10 + extra
  end

  alias __types__set_y y= unless method_defined?(:__types__set_y)
  def y=(value)
    __types__set_y(value)
    if @battler.opposes?(0)
      extra = 5
    else
      extra = 0
    end
    # extra = -5
    # if @battler&.types.length == 1
    #   extra = -30
    # end

    @types_sprite.y = value + extra #+ @types_y
    #echoln "y #{@types_sprite.y}"
  end

  alias __types__set_z z= unless method_defined?(:__types__set_z)
  def z=(value)
    __types__set_z(value)
    @types_sprite.z = value + 1
  end

  alias __databox__refresh refresh unless method_defined?(:__databox__refresh)
  def refresh
    # self.bitmap.clear
    return if !@battler.pokemon
    __databox__refresh
    draw_type_icons
  end

  def draw_type_icons
    # Dibuja los tipos del Pokémon
    @types_sprite.bitmap.clear
    
    height_per_icon = @types_bitmap.height / GameData::Type.count
    separacion_extra = 2 # Ajusta este valor según necesites

    # Si hacemos esto siempre refresca los iconos y se ve feo, entonces lo hacemos solo en las excepciones que a un poke se le agregó un tipo adicional
    # if @battler.types.size > 2       
      # Calcula el alto total necesario para el bitmap de @types_sprite
      total_height = @battler.types.size * height_per_icon + (@battler.types.size - 1) * separacion_extra
    
      # Ajusta la posición inicial en Y para @types_sprite si es necesario
      @types_y = -total_height + 68
    
      # Crea el bitmap de @types_sprite con el ancho y alto adecuados
      @types_sprite.bitmap = Bitmap.new(@databoxBitmap.width - @types_x, total_height)
      @types_sprite.x = @types_x
      @types_sprite.y = @types_y
    # end
    # @sprites["types_sprite"] = @types_sprite

    
    # Calcula el ancho y la altura de cada type
    width  = @types_bitmap.width
    height = @types_bitmap.height / GameData::Type.count
    separacion_extra = 0 # Aumenta este valor para más separación entre íconos
    types = @battler.effects[PBEffects::Illusion] ? @battler.effects[PBEffects::Illusion].types : @battler.types
    types.each_with_index do |type, i|
      # Obtener el objeto tipo y la posición de su icono
      type_number = GameData::Type.get(type).icon_position
      # Ancho y alto del icono
      type_rect = Rect.new(0, type_number * height, width, height)
      # Ajusta la posición Y del ícono basándote en el índice y la separación extra
      y_position = i * (height + separacion_extra)

      # Dibuja el íconos
      @types_sprite.bitmap.blt(0, y_position, @types_bitmap.bitmap, type_rect)
    end
    @sprites["types_sprite"] = @types_sprite
  end
  
end
