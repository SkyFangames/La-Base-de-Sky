module SaveData
  # Contiene objetos Value para cada elemento de guardado.
  # Se llena durante el tiempo de ejecución mediante las llamadas a 
  # SaveData.register.
  # @type [Array<Value>]
  @values = []

  # Un error generado si se intenta guardar o cargar un valor de guardado no 
  # válido.
  class InvalidValueError < RuntimeError; end

  #=============================================================================
  # Representa un único valor en los datos de guardado.
  # Se añaden nuevos valores utilizando {SaveData.register}.
  class Value
    # @return [Symbol] el ID del valor
    attr_reader :id

    # @param id [Symbol] ID del valor
    def initialize(id, &block)
      validate id => Symbol, block => Proc
      @id = id
      @loaded = false
      @load_in_bootup = false
      @reset_on_new_game = false
      instance_eval(&block)
      raise "No save_value defined for save value #{id.inspect}" if @save_proc.nil?
      raise "No load_value defined for save value #{id.inspect}" if @load_proc.nil?
    end

    # @param value [Object] valor a verificar
    # @return [Boolean] si el valor proporcionado es válido
    def valid?(value)
      return true if @ensured_class.nil?
      return value.is_a?(Object.const_get(@ensured_class))
    end

    # Llama al procedimiento de guardado del valor y devuelve su valor.
    # @return [Object] valor del procedimiento de guardado
    # @raise [InvalidValueError] si se está guardando un valor no válido
    def load(value)
      validate_value(value)
      @load_proc.call(value)
      @loaded = true
    end

    # Llama al procedimiento de guardado del valor y devuelve su valor.
    # @return [Object] valor del procedimiento de guardado
    # @raise [InvalidValueError] si se está guardando un valor no válido
    def save
      value = @save_proc.call
      validate_value(value)
      return value
    end

    # @return [Boolean] si el valor tiene un procedimiento de nuevo juego 
    # definido
    def has_new_game_proc?
      return @new_game_value_proc.is_a?(Proc)
    end

    # Llama al procedimiento de carga del valor de guardado con el valor obtenido
    # del procedimiento de nuevo juego definido.
    # @raise (ver #load)
    def load_new_game_value
      unless self.has_new_game_proc?
        raise "Save value #{@id.inspect} has no new_game_value defined"
      end
      self.load(@new_game_value_proc.call)
    end

    # @return [Boolean] si el valor debe cargarse durante el arranque
    def load_in_bootup?
      return @load_in_bootup
    end

    def reset_on_new_game
      @reset_on_new_game = true
    end

    def reset_on_new_game?
      return @reset_on_new_game
    end

    # @return [Boolean] si el valor ha sido cargado
    def loaded?
      return @loaded
    end

    # Marca el valor como no cargado.
    def mark_as_unloaded
      @loaded = false
    end

    # Utiliza el procedimiento {#from_old_format} para seleccionar los datos correctos de
    # +old_format+ y devolverlos.
    # Devuelve nil si el procedimiento no está definido.
    # @param old_format [Array] formato antiguo para cargar el valor
    # @return [Object] datos del formato antiguo
    def get_from_old_format(old_format)
      return nil if @old_format_get_proc.nil?
      return @old_format_get_proc.call(old_format)
    end

    #---------------------------------------------------------------------------

    private

    # Genera un {InvalidValueError} si el valor proporcionado no es válido.
    # @param value [Object] valor a verificar
    # @raise [InvalidValueError] si el valor no es válido
    def validate_value(value)
      return if self.valid?(value)
      raise InvalidValueError, "El valor de guardado #{@id.inspect} no es un #{@ensured_class} (se proporcionó #{value.class.name})"
    end

    # @!group Configuración

    # Si está presente, asegura que el valor sea de la clase proporcionada.
    # @param class_name [Symbol] clase a asegurar
    # @see SaveData.register
    def ensure_class(class_name)
      validate class_name => Symbol
      @ensured_class = class_name
    end

    # Define cómo se coloca el valor cargado en una variable global.
    # Requiere un bloque con el valor cargado como parámetro.
    # @see SaveData.register
    def load_value(&block)
      raise ArgumentError, "No se proporcionó un bloque para load_value" unless block_given?
      @load_proc = block
    end

    # Define qué se guarda en los datos de guardado. Requiere un bloque.
    # @see SaveData.register
    def save_value(&block)
      raise ArgumentError, "No se proporcionó un bloque para save_value" unless block_given?
      @save_proc = block
    end

    # Si está presente, define a qué se establece el valor al comienzo de un nuevo juego.
    # @see SaveData.register
    def new_game_value(&block)
      raise ArgumentError, "No se proporcionó un bloque para new_game_value" unless block_given?
      @new_game_value_proc = block
    end

    # Si está presente, establece que el valor se cargue durante el arranque.
    # @see SaveData.register
    def load_in_bootup
      @load_in_bootup = true
    end

    # Si está presente, define cómo se debe obtener el valor del formato de guardado
    # anterior a la versión 19. Requiere un bloque con el antiguo formato como parámetro.
    # @see SaveData.register
    def from_old_format(&block)
      raise ArgumentError, "No se proporcionó un bloque para from_old_format" unless block_given?
      @old_format_get_proc = block
    end

    # @!endgroup
  end

  #=============================================================================
  # Registra un {Value} para ser guardado en los datos de guardado.
  # Toma un bloque que define los procedimientos de guardado ({Value#save_value})
  # y carga ({Value#load_value}) del valor.
  #
  # También es posible proporcionar un procedimiento para obtener el valor
  # del formato de guardado anterior a la versión 19 ({Value#from_old_format}),
  # definir un valor que se establecerá al iniciar un nuevo juego con {Value#new_game_value}
  # y asegurarse de que el valor guardado y cargado sea de la clase correcta con {Value#ensure_class}.
  #
  # Los valores se pueden registrar para cargarse durante el arranque con
  # {Value#load_in_bootup}. Si se define un procedimiento new_game_value, se
  # llamará cuando se lance el juego por primera vez,
  # o si los datos de guardado no contienen el valor en cuestión.
  #
  # @example Registrando un nuevo valor
  #   SaveData.register(:foo) do
  #     ensure_class :Foo
  #     save_value { $foo }
  #     load_value { |value| $foo = value }
  #     new_game_value { Foo.new }
  #   end
  # @example Registrando un valor para cargarse durante el arranque
  #   SaveData.register(:bar) do
  #     load_in_bootup
  #     save_value { $bar }
  #     load_value { |value| $bar = value }
  #     new_game_value { Bar.new }
  #   end
  # @param id [Symbol] id del valor
  # @yield el bloque de código que se guardará como un Value
  def self.register(id, &block)
    validate id => Symbol
    unless block_given?
      raise ArgumentError, "No se proporcionó un bloque para SaveData.register"
    end
    @values << Value.new(id, &block)
  end

  def self.unregister(id)
    validate id => Symbol
    @values.delete_if { |value| value.id == id }
  end

  # @param save_data [Hash] datos de guardado para validar
  # @return [Boolean] si los datos de guardado dados son válidos
  def self.valid?(save_data)
    validate save_data => Hash
    return @values.all? { |value| value.valid?(save_data[value.id]) }
  end

  # Carga valores desde los datos de guardado proporcionados.
  # Se puede pasar una condición opcional.
  # @param save_data [Hash] datos de guardado para cargar
  # @param condition_block [Proc] condición opcional
  # @api privado
  def self.load_values(save_data, &condition_block)
    @values.each do |value|
      next if block_given? && !condition_block.call(value)
      if save_data.has_key?(value.id)
        value.load(save_data[value.id])
      elsif value.has_new_game_proc?
        value.load_new_game_value
      end
    end
  end

  # Carga los valores desde los datos de guardado proporcionados
  # llamando al procedimiento {Value#load_value} de cada objeto {Value}.
  # Se omiten los valores que ya están cargados.
  # Si un valor no existe en los datos de guardado y tiene
  # un procedimiento {Value#new_game_value} definido, ese valor
  # se carga en su lugar.
  # @param save_data [Hash] datos de guardado para cargar
  # @raise [InvalidValueError] si se está cargando un valor no válido
  def self.load_all_values(save_data)
    validate save_data => Hash
    load_values(save_data) { |value| !value.loaded? }
  end

  # Marca como no cargados todos los valores que no están cargados al iniciar.
  def self.mark_values_as_unloaded
    @values.each do |value|
      value.mark_as_unloaded if !value.load_in_bootup? || value.reset_on_new_game?
    end
  end

  # Carga cada valor desde los datos de guardado que se ha
  # establecido para ser cargado durante el arranque. Se realiza cuando existe un archivo de guardado.
  # @param save_data [Hash] datos de guardado para cargar
  # @raise [InvalidValueError] si se está cargando un valor no válido
  def self.load_bootup_values(save_data)
    validate save_data => Hash
    load_values(save_data) { |value| !value.loaded? && value.load_in_bootup? }
  end

  # Recorre cada valor con {Value#load_in_bootup} habilitado y carga su
  # valor de nuevo juego, si está definido. Se realiza cuando no existe un 
  # archivo de guardado.
  def self.initialize_bootup_values
    @values.each do |value|
      next unless value.load_in_bootup?
      value.load_new_game_value if value.has_new_game_proc? && !value.loaded?
    end
  end

  # Carga el valor de nuevo juego de cada {Value}, si está definido. Se realiza
  # al comenzar un nuevo juego.
  def self.load_new_game_values
    @values.each do |value|
      value.load_new_game_value if value.has_new_game_proc? && (!value.loaded? || value.reset_on_new_game?)
    end
  end

  # @return [Hash{Symbol => Object}] una representación en forma de hash de los
  # datos de guardado
  # @raise [InvalidValueError] si se está guardando un valor no válido
  def self.compile_save_hash
    save_data = {}
    @values.each { |value| save_data[value.id] = value.save }
    return save_data
  end
end

