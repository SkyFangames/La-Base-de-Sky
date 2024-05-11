#===============================================================================
#  Lee archivos de cierto formato desde un directorio
#===============================================================================
class Dir
  # Lee todos los archivos en un directorio
  def self.get(dir, filters = "*", full = true)
    files = []
    filters = [filters] if !filters.is_a?(Array)
    self.chdir(dir) do
      filters.each do |filter|
        self.glob(filter) { |f| files.push(full ? (dir + "/" + f) : f) }
      end
    end
    return files.sort
  end

  # Genera un árbol completo de archivos/carpetas desde un determinado directorio
  def self.all(dir, filters = "*", full = true)
    # establece variables para comenzar
    files = []
    subfolders = []
    self.get(dir, filters, full).each do |file|
      # participa en recursividad para leer todo el árbol de archivos
      if self.safe?(file)   # Es un directorio
        subfolders += self.all(file, filters, full)
      else   # es un archivo
        files += [file]
      end
    end
    # devuelve todos los archivos encontrados
    return files + subfolders
  end

  # Comprueba el directorio existente
  def self.safe?(dir)
    return FileTest.directory?(dir)
  end

  # Crea todos los directorios necesarios para la ruta del nombre del archivo
  def self.create(path)
    path.gsub!("\\", "/")   # Compatibilidad con Windows
    # obtener árbol de ruta
    dirs = path.split("/")
    full = ""
    dirs.each do |dir|
      full += dir + "/"
      # crea directorios
      self.mkdir(full) if !self.safe?(full)
    end
  end

  # Genera un árbol de carpetas completo a partir de un directorio determinado
  def self.all_dirs(dir)
    # establece variables para comenzar
    dirs = []
    self.get(dir, "*", true).each do |file|
      # participa en recursividad para leer todo el árbol de carpetas
      dirs += self.all_dirs(file) if self.safe?(file)
    end
    # devuelve todos los directorios encontrados
    return dirs.length > 0 ? (dirs + [dir]) : [dir]
  end

  # Elimina todos los archivos de un directorio y todos los subdirectorios (permite directorios que no estén vacíos)
  def self.delete_all(dir)
    # Eliminar todas las dirs en dir
    self.all(dir).each { |f| File.delete(f) }
    # Eliminar todas las dirs en dir
    self.all_dirs(dir).each { |f| Dir.delete(f) }
  end
end

#===============================================================================
# Comprobando archivos y directorios
#===============================================================================
# Soluciona un problema con FileTest.directory si el directorio contiene marcas de acento
# @deprecated Este método está programado para ser eliminado en la versión v22.
def safeIsDirectory?(f)
  Deprecation.warn_method("safeIsDirectory?(f)", "v22", "FileTest.directory?(f)")
  return FileTest.directory?(f)
end

# @deprecated This method is slated to be removed in v22.
def safeExists?(f)
  Deprecation.warn_method("safeExists?(f)", "v22", "FileTest.exist?(f)")
  return FileTest.exist?(f)
end

# Similar a "Dir.glob", pero diseñado para solucionar un problema al acceder
# a archivos si una ruta contiene marcas de acento.
# "dir" es la ruta del directorio, "wildcard" es el patrón de nombre de archivo
# a coincidir.
def safeGlob(dir, wildcard)
  ret = []
  afterChdir = false
  begin
    Dir.chdir(dir) do
      afterChdir = true
      Dir.glob(wildcard) { |f| ret.push(dir + "/" + f) }
    end
  rescue Errno::ENOENT
    raise if afterChdir
  end
  if block_given?
    ret.each { |f| yield(f) }
  end
  return (block_given?) ? nil : ret
end

def pbResolveAudioSE(file)
  return nil if !file
  if RTP.exists?("Audio/SE/" + file, ["", ".wav", ".ogg"])   # ".mp3"
    return RTP.getPath("Audio/SE/" + file, ["", ".wav", ".ogg"])   # ".mp3"
  end
  return nil
end

# Encuentra la ruta real para un archivo de imagen. Esto incluye rutas en archivos
# cifrados. Devuelve nil si no se puede encontrar la ruta.

def pbResolveBitmap(x)
  return nil if !x
  noext = x.gsub(/\.(bmp|png|gif|jpg|jpeg)$/, "")
  filename = nil
#  RTP.eachPathFor(x) { |path|
#    filename = pbTryString(path) if !filename
#    filename = pbTryString(path + ".gif") if !filename
#  }
  RTP.eachPathFor(noext) do |path|
    filename = pbTryString(path + ".png") if !filename
    filename = pbTryString(path + ".gif") if !filename
#    filename = pbTryString(path + ".jpg") if !filename
#    filename = pbTryString(path + ".jpeg") if !filename
#    filename = pbTryString(path + ".bmp") if !filename
  end
  return filename
end

# Encuentra la ruta real para un archivo de imagen. Esto incluye rutas en archivos
# cifrados. Devuelve _x_ si no se puede encontrar la ruta.
def pbBitmapName(x)
  ret = pbResolveBitmap(x)
  return (ret) ? ret : x
end

def strsplit(str, re)
  ret = []
  tstr = str
  while re =~ tstr
    ret[ret.length] = $~.pre_match
    tstr = $~.post_match
  end
  ret[ret.length] = tstr if ret.length
  return ret
end

def canonicalize(c)
  csplit = strsplit(c, /[\/\\]/)
  pos = -1
  ret = []
  retstr = ""
  csplit.each do |x|
    if x == ".."
      if pos >= 0
        ret.delete_at(pos)
        pos -= 1
      end
    elsif x != "."
      ret.push(x)
      pos += 1
    end
  end
  ret.length.times do |i|
    retstr += "/" if i > 0
    retstr += ret[i]
  end
  return retstr
end

#===============================================================================
#
#===============================================================================
module RTP
  @rtpPaths = nil

  def self.exists?(filename, extensions = [])
    return false if nil_or_empty?(filename)
    eachPathFor(filename) do |path|
      return true if FileTest.exist?(path)
      extensions.each do |ext|
        return true if FileTest.exist?(path + ext)
      end
    end
    return false
  end

  def self.getImagePath(filename)
    return self.getPath(filename, ["", ".png", ".gif"])   # ".jpg", ".jpeg", ".bmp"
  end

  def self.getAudioPath(filename)
    return self.getPath(filename, ["", ".wav", ".wma", ".mid", ".ogg", ".midi"])   # ".mp3"
  end

  def self.getPath(filename, extensions = [])
    return filename if nil_or_empty?(filename)
    eachPathFor(filename) do |path|
      return path if FileTest.exist?(path)
      extensions.each do |ext|
        file = path + ext
        return file if FileTest.exist?(file)
      end
    end
    return filename
  end

  # Obtiene las rutas RGSS absolutas para el nombre de archivo dado
  def self.eachPathFor(filename)
    return if !filename
    if filename[/^[A-Za-z]\:[\/\\]/] || filename[/^[\/\\]/]
      # El nombre del archivo ya es absoluto.
      yield filename
    else
      # dirección relativa
      RTP.eachPath do |path|
        if path == "./"
          yield filename
        else
          yield path + filename
        end
      end
    end
  end

  # Obtiene todos los caminos de búsqueda de RGSS.
  # Esta función prácticamente no hace nada ahora, porque
  # el paso del tiempo y la introducción de MKXP la hacen
  # inútil, pero se deja por razones de compatibilidad
  def self.eachPath
    # XXX: Usa "." en lugar de Dir.pwd debido a problemas para recuperar archivos si
    # el directorio actual contiene una tilde
    yield ".".gsub(/[\/\\]/, "/").gsub(/[\/\\]$/, "") + "/"
  end

  def self.getSaveFileName(fileName)
    File.join(getSaveFolder, fileName)
  end

  def self.getSaveFolder
    # MKXP se asegura de que esta carpeta se haya creado
    # una vez que comienza. La ubicación difiere según
    # el sistema operativo:
    # Windows: %APPDATA%
    # Linux: $HOME/.local/share
    # macOS (unsandboxed): $HOME/Library/Application Support
    System.data_directory
  end
end

#===============================================================================
#
#===============================================================================
module FileTest
  IMAGE_EXTENSIONS = [".png", ".gif"]   # ".jpg", ".jpeg", ".bmp",
  AUDIO_EXTENSIONS = [".mid", ".midi", ".ogg", ".wav", ".wma"]   # ".mp3"

  def self.audio_exist?(filename)
    return RTP.exists?(filename, AUDIO_EXTENSIONS)
  end

  def self.image_exist?(filename)
    return RTP.exists?(filename, IMAGE_EXTENSIONS)
  end
end

#===============================================================================
#
#===============================================================================
# Se utiliza para determinar si existe un archivo de datos (en lugar de un archivo de gráficos o audio).
# No verifica RTP, pero sí verifica archivos cifrados.
# NOTA: pbGetFileChar verifica cualquier cosa añadida en la configuración RTP 
# de MKXP, y los puntos de montaje coincidentes añadidos a través de System.mount.
def pbRgssExists?(filename)
  return !pbGetFileChar(filename).nil? if FileTest.exist?("./Game.rgssad")
  filename = canonicalize(filename)
  return FileTest.exist?(filename)
end

# Abre un IO, incluso si el archivo está en un archivo cifrado.
# No verifica RTP para el archivo.
# NOTA: load_data verifica cualquier cosa añadida en la configuración RTP de 
#    MKXP, y los puntos de montaje coincidentes añadidos a través de System.mount.

def pbRgssOpen(file, mode = nil)
  # File.open("debug.txt", "ab") { |fw| fw.write([file, mode, Time.now.to_f].inspect + "\r\n") }
  if !FileTest.exist?("./Game.rgssad")
    if block_given?
      File.open(file, mode) { |f| yield f }
      return nil
    else
      return File.open(file, mode)
    end
  end
  file = canonicalize(file)
  Marshal.neverload = true
  str = load_data(file, true)
  if block_given?
    StringInput.open(str) { |f| yield f }
    return nil
  else
    return StringInput.open(str)
  end
end

# Obtiene al menos el primer byte de un archivo. No verifica RTP, pero sí verifica
# archivos cifrados.
def pbGetFileChar(file)
  canon_file = canonicalize(file)
  if !FileTest.exist?("./Game.rgssad")
    return nil if !FileTest.exist?(canon_file)
    return nil if file.last == "/"   # Es un directorio
    begin
      File.open(canon_file, "rb") { |f| return f.read(1) }   # leer un byte
    rescue Errno::ENOENT, Errno::EINVAL, Errno::EACCES, Errno::EISDIR
      return nil
    end
  end
  str = nil
  begin
    str = load_data(canon_file, true)
  rescue Errno::ENOENT, Errno::EINVAL, Errno::EACCES, Errno::EISDIR, RGSSError, MKXPError
    str = nil
  end
  return str
end

def pbTryString(x)
  ret = pbGetFileChar(x)
  return nil_or_empty?(ret) ? nil : x
end

# Obtiene el contenido de un archivo. No verifica RTP, pero sí verifica
# archivos cifrados.
# NOTA: load_data verificará cualquier cosa agregada en la configuración de RTP 
#       de MKXP, y los puntos de montaje coincidentes agregados a través de 
#       System.mount.

def pbGetFileString(file)
  file = canonicalize(file)
  if !FileTest.exist?("./Game.rgssad")
    return nil if !FileTest.exist?(file)
    begin
      File.open(file, "rb") { |f| return f.read }   # read all data
    rescue Errno::ENOENT, Errno::EINVAL, Errno::EACCES
      return nil
    end
  end
  str = nil
  begin
    str = load_data(file, true)
  rescue Errno::ENOENT, Errno::EINVAL, Errno::EACCES, RGSSError, MKXPError
    str = nil
  end
  return str
end

#===============================================================================
#
#===============================================================================
class StringInput
  include Enumerable

  attr_reader :lineno, :string

  class << self
    def new(str)
      if block_given?
        begin
          f = super
          yield f
        ensure
          f&.close
        end
      else
        super
      end
    end
    alias open new
  end

  def initialize(str)
    @string = str
    @pos = 0
    @closed = false
    @lineno = 0
  end

  def inspect
    return "#<#{self.class}:#{@closed ? 'closed' : 'open'},src=#{@string[0, 30].inspect}>"
  end

  def close
    raise IOError, "closed stream" if @closed
    @pos = nil
    @closed = true
  end

  def closed?; @closed; end

  def pos
    raise IOError, "closed stream" if @closed
    [@pos, @string.size].min
  end

  alias tell pos

  def rewind; seek(0); end

  def pos=(value); seek(value); end

  def seek(offset, whence = IO::SEEK_SET)
    raise IOError, "closed stream" if @closed
    case whence
    when IO::SEEK_SET then @pos = offset
    when IO::SEEK_CUR then @pos += offset
    when IO::SEEK_END then @pos = @string.size - offset
    else
      raise ArgumentError, "unknown seek flag: #{whence}"
    end
    @pos = 0 if @pos < 0
    @pos = [@pos, @string.size + 1].min
    offset
  end

  def eof?
    raise IOError, "closed stream" if @closed
    @pos > @string.size
  end

  def each(&block)
    raise IOError, "closed stream" if @closed
    begin
      @string.each(&block)
    ensure
      @pos = 0
    end
  end

  def gets
    raise IOError, "closed stream" if @closed
    idx = @string.index("\n", @pos)
    if idx
      idx += 1  # "\n".size
      line = @string[@pos...idx]
      @pos = idx
      @pos += 1 if @pos == @string.size
    else
      line = @string[@pos..-1]
      @pos = @string.size + 1
    end
    @lineno += 1
    line
  end

  def getc
    raise IOError, "closed stream" if @closed
    ch = @string[@pos]
    @pos += 1
    @pos += 1 if @pos == @string.size
    ch
  end

  def read(len = nil)
    raise IOError, "closed stream" if @closed
    if !len
      return nil if eof?
      rest = @string[@pos...@string.size]
      @pos = @string.size + 1
      return rest
    end
    str = @string[@pos, len]
    @pos += len
    @pos += 1 if @pos == @string.size
    str
  end
  alias read_all read
  alias sysread read
end

