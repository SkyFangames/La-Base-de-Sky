# El módulo SaveData se utiliza para manipular los datos de guardado. Contiene 
# los {Value}s que conforman los datos de guardado y {Conversion}s para resolver
# incompatibilidades entre Essentials y las versiones del juego.
# @see SaveData.register
# @see SaveData.register_conversion
module SaveData
  # Contiene la ruta del archivo de guardado.
  FILE_PATH = if File.directory?(System.data_directory)
                System.data_directory + "/Game.rxdata"
              else
                "./Game.rxdata"
              end

  # @return [Boolean] si el archivo de guardado existe
  def self.exists?
    return File.file?(FILE_PATH)
  end

  # Obtiene los datos de guardado del archivo proporcionado.
  # Devuelve un Array en el caso de un archivo de guardado anterior a la 
  # versión 19.
  # @param file_path [String] ruta del archivo desde el que cargar
  # @return [Hash, Array] datos de guardado cargados
  # @raise [IOError, SystemCallError] si falla la apertura del archivo
  def self.get_data_from_file(file_path)
    validate file_path => String
    save_data = nil
    File.open(file_path) do |file|
      data = Marshal.load(file)
      if data.is_a?(Hash)
        save_data = data
        next
      end
      save_data = [data]
      save_data << Marshal.load(file) until file.eof?
    end
    return save_data
  end

  # Obtiene los datos de guardado del archivo proporcionado. Si necesita 
  # conversión, lo vuelve a guardar.
  # @param file_path [String] ruta del archivo desde el que leer
  # @return [Hash] datos de guardado en formato Hash
  # @raise (ver .get_data_from_file)
  def self.read_from_file(file_path)
    validate file_path => String
    save_data = get_data_from_file(file_path)
    save_data = to_hash_format(save_data) if save_data.is_a?(Array)
    if !save_data.empty? && run_conversions(save_data)
      File.open(file_path, "wb") { |file| Marshal.dump(save_data, file) }
    end
    return save_data
  end

  # Compila los datos de guardado y guarda una versión marshaled de ellos en
  # el archivo proporcionado.
  # @param file_path [String] ruta del archivo donde guardar
  # @raise [InvalidValueError] si se está guardando un valor no válido
  def self.save_to_file(file_path)
    validate file_path => String
    save_data = self.compile_save_hash
    File.open(file_path, "wb") { |file| Marshal.dump(save_data, file) }
  end

  # Elimina el archivo de guardado (y un posible archivo de respaldo .bak 
  # si existe)
  # @raise [Error::ENOENT]
  def self.delete_file
    File.delete(FILE_PATH)
    File.delete(FILE_PATH + ".bak") if File.file?(FILE_PATH + ".bak")
  end

  # Convierte los datos de formato anterior a la versión 19 al nuevo formato.
  # @param old_format [Array] datos de guardado en formato anterior a la 
  # versión 19
  # @return [Hash] datos de guardado en el nuevo formato
  def self.to_hash_format(old_format)
    validate old_format => Array
    hash = {}
    @values.each do |value|
      data = value.get_from_old_format(old_format)
      hash[value.id] = data unless data.nil?
    end
    return hash
  end
end

