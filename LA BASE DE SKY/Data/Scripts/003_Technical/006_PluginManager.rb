#==============================================================================#
#                                Gestor de Plugins                             #
#                                   por Marin                                  #
#               Soporte para scripts de plugins externos por Luka S.J.         #
#                              Modificado por Maruno                           #
#------------------------------------------------------------------------------#
#   Proporciona una interfaz simple que permite a los plugins requerir         #
#   dependencias en versiones específicas y especificar incompatibilidades     #
#   entre plugins.                                                             #
#   Admite scripts externos que se encuentran en archivos .rb en carpetas      #
#   dentro de la carpeta "El plugins".                                         #
#------------------------------------------------------------------------------#
#                                   Uso:                                       #
#                                                                              #
# Cada plugin debe tener su propia carpeta en la carpeta "El plugins" que se   #
# encuentra en el directorio principal. La carpeta "El plugins" es similar en  #
# concepto a la carpeta "PBS", en el sentido de que su contenido se compila    #
# y registra como existente. El archivo de script(s) del plugin se coloca en   #
# su carpeta; deben ser archivos .rb.                                          #
#                                                                              #
# La carpeta de un plugin también debe contener un archivo "meta.txt". Este    #
# archivo es lo que hace que Essentials reconozca que el plugin existe y       #
# contiene información importante sobre el plugin; si este archivo no existe,  #
# el contenido de la carpeta se ignora. Cada línea en este archivo es una      #
# propiedad.                                                                   #
#                                                                              #
# Líneas obligatorias:                                                         #
#                                                                              #
#     Name       = Simple Extension                          Nombre del plugin #
#     Version    = 1.0                                      Versión del plugin #
#     Essentials = 19.1,20             Versión(es) compatible(s) de Essentials #
#     Link       = https://reliccastle.com/link-to-the-plugin/                 #
#     Credits    = Luka S.J.,Maruno,Marin                    Uno o más nombres #
#                                                                              #
# La versión de un plugin debe estar en el formato X o X.Y o X.Y.Z, donde X/Y/Z#
# son números. También puedes usar Xa, Xb, Xc, Ya, etc. Lo importante es que   #
# uses números de versión de manera consistente para tu plugin. Una versión    #
# posterior será alfanuméricamente mayor que una versión más antigua.          #
#                                                                              #
# Los plugins pueden interactuar entre sí de varias maneras, como requerir     #
# que otro exista o chocar entre sí. Estas interacciones se conocen como       #
# dependencias y conflictos. Las líneas a continuación son opcionales y se     #
# colocan en "meta.txt" para definir cómo funciona (o no funciona) tu plugin   #
# con otros. Puedes tener múltiples líneas de cada una de estas.               #
#                                                                              #
#     Requires   = Basic Plugin     Debe tener este plugin (cualquier versión) #
#     Requires   = Useful Utils,1.1      Debe tener este plugin/versión mínima #
#     Exact      = Scene Tweaks,2               Debe tener este plugin/versión #
#     Optional   = Extended Windows,1.2   Si este plugin existe, cárgalo antes #
#     Conflicts  = Complex Extension                       Plugin incompatible #
#                                                                              #
# Un plugin que depende de otro ("Requires"/"Exact"/"Optional") hará que       #
# ese otro plugin se cargue primero. La línea "Optional" es para un plugin     #
# que no es necesario, pero si existe en el mismo proyecto, debe estar en la   #
# versión indicada o superior.                                                 #
#                                                                              #
# Cuando los plugins se compilan, sus scripts se almacenan en el archivo       #
# "El pluginScripts.rxdata" en la carpeta "Data". Las dependencias definidas   #
# anteriormente garantizarán que se carguen en un orden adecuado. Los scripts  #
# dentro de un plugin se cargan alfanuméricamente, recorriendo las subcarpetas #
# en profundidad primero.                                                      #
#                                                                              #
# La carpeta "El plugins" debe eliminarse cuando se lance el juego. Los scripts#
# dentro de ella se compilan, pero cualquier otro archivo utilizado por un     #
# plugin (gráficos/sonido) debe colocarse en otras carpetas y no en la carpeta #
# del plugin.                                                                  #
#                                                                              #
#------------------------------------------------------------------------------#
#                           El código detrás de los plugins:                   #
#                                                                              #
# Cuando se lee el archivo "meta.txt" de un plugin, su contenido se registra   #
# en el PluginManager. Un ejemplo simple de registrar un plugin es:            #
#                                                                              #
#     PluginManager.register({                                                 #
#       :name       => "Basic Plugin",                                         #
#       :version    => "1.0",                                                  #
#       :essentials => "20",                                                   #
#       :link       => "https://reliccastle.com/link-to-the-plugin/",          #
#       :credits    => ["Marin"]                                               #
#     })                                                                       #
#                                                                              #
# El valor :link es opcional, pero recomendado. Esto se mostrará en el mensaje #
# si el PluginManager detecta que este plugin necesita actualizarse.           #
#                                                                              #
# Aquí está el mismo ejemplo pero también con dependencias y conflictos:       #
#                                                                              #
#     PluginManager.register({                                                 #
#       :name       => "Basic Plugin",                                         #
#       :version    => "1.0",                                                  #
#       :essentials => "20",                                                   #
#       :link       => "https://reliccastle.com/link-to-the-plugin/",          #
#       :credits    => ["Marin"],                                              #
#       :dependencies => ["Basic Plugin",                                      #
#                         ["Useful Utils", "1.1"],                             #
#                         [:exact, "Scene Tweaks", "2"],                       #
#                         [:optional, "Extended Windows", "1.2"],              #
#                        ],                                                    #
#       :incompatibilities => ["Simple Extension"]                             #
#     })                                                                       #
#                                                                              #
# Las dependencias/conflictos del ejemplo son las mismas que los ejemplos      #
# mostrados anteriormente para las líneas en "meta.txt". :optional_exact es    #
# una combinación de :exact y :optional, y no hay forma de aprovechar su       #
# funcionalidad combinada a través de "meta.txt".                              #
#                                                                              #
#------------------------------------------------------------------------------#
#                    Por favor, da créditos al usar esto.                      #
#==============================================================================#

module PluginManager
  # Contiene todos los datos registrados de los plugins.
  @@Plugins = {}

  # Registra un plugin y prueba sus dependencias e incompatibilidades.
  def self.register(options)
    name         = nil
    version      = nil
    essentials   = nil
    link         = nil
    dependencies = nil
    incompats    = nil
    credits      = []
    order = [:name, :version, :essentials, :link, :dependencies, :incompatibilities, :credits]
    # Asegura que primero lea el nombre del plugin, que se utiliza en la notificación de errores,
    # ordenando las claves
    keys = options.keys.sort do |a, b|
      idx_a = order.index(a) || order.size
      idx_b = order.index(b) || order.size
      next idx_a <=> idx_b
    end
    keys.each do |key|
      value = options[key]
      case key
      when :name   # Nombre del plugin
        if nil_or_empty?(value)
          self.error("El nombre del plugin debe ser una cadena que no esté vacía.")
        end
        if !@@Plugins[value].nil?
          self.error("Ya existe un plugin llamado '#{value}'.")
        end
        name = value
      when :version   # Versión del plugin
        self.error("La versión del plugin debe ser una cadena.") if nil_or_empty?(value)
        version = value
      when :essentials
        essentials = value
      when :link   # Sitio web del plugin
        if nil_or_empty?(value)
          self.error("El enlace del plugin debe ser una cadena no vacía.")
        end
        link = value
      when :dependencies   # Dependencias del plugin
        dependencies = value
        dependencies = [dependencies] if !dependencies.is_a?(Array) || !dependencies[0].is_a?(Array)
        value.each do |dep|
          case dep
          when String   # "plugin name"
            if !self.installed?(dep)
              self.error("El plugin '#{name}' requiere que el plugin '#{dep}' esté instalado antes que él.")
            end
          when Array
            case dep.size
            when 1   # ["nombre del plugin"]
              if dep[0].is_a?(String)
                dep_name = dep[0]
                if !self.installed?(dep_name)
                  self.error("El plugin '#{name}' requiere que el plugin '#{dep_name}' esté instalado antes que él.")
                end
              else
                self.error("Se esperaba el nombre del plugin como una cadena, pero se obtuvo #{dep[0].inspect}.")
              end
            when 2   # ["nombre del plugin", "versión"]
              if dep[0].is_a?(Symbol)
                self.error("Se proporcionó un símbolo comparador de versión de plugin pero no se proporcionó una versión.")
              elsif dep[0].is_a?(String) && dep[1].is_a?(String)
                dep_name    = dep[0]
                dep_version = dep[1]
                next if self.installed?(dep_name, dep_version)
                if self.installed?(dep_name)   # Tiene el plugin pero en una versión más baja
                  msg = "El plugin '#{name}' requiere que el plugin '#{dep_name}' sea la versión #{dep_version} o superior, " +
                        "pero la versión instalada es #{self.version(dep_name)}."
                  dep_link = self.link(dep_name)
                  if dep_link
                    msg += "\r\nVerifica #{dep_link} para obtener una actualización del plugin '#{dep_name}'."
                  end
                  
                  
                  
                  
                  self.error(msg)
                else   # No tiene el plugin
                  self.error("El plugin '#{name}' requiere que el plugin '#{dep_name}' sea la versión #{dep_version} " +
                      "o superior para estar instalado antes que él.")
                end
              end
            when 3   # [:optional/:exact/:optional_exact, "plugin name", "version"]
              if !dep[0].is_a?(Symbol)
                self.error("Se esperaba que el primer argumento de la dependencia fuera un símbolo, pero se obtuvo #{dep[0].inspect}.")
              end
              if !dep[1].is_a?(String)
                self.error("Se esperaba que el segundo argumento de la dependencia fuera el nombre del plugin, pero se obtuvo #{dep[1].inspect}.")
              end
              if !dep[2].is_a?(String)
                self.error("Se esperaba que el tercer argumento de la dependencia fuera la versión del plugin, pero se obtuvo #{dep[2].inspect}.")
              end
              dep_arg     = dep[0]
              dep_name    = dep[1]
              dep_version = dep[2]
              optional    = false
              exact       = false
              case dep_arg
              when :optional
                optional = true
              when :exact
                exact = true
              when :optional_exact
                optional = true
                exact = true
              else
                self.error("Se esperaba que el primer argumento de la dependencia fuera uno de " +
                           ":optional, :exact o :optional_exact, pero se obtuvo #{dep_arg.inspect}.")
              end
              if optional
                if self.installed?(dep_name) &&   # Tiene el plugin pero en una versión más baja
                   !self.installed?(dep_name, dep_version, exact)
                  msg = "El plugin '#{name}' requiere que el plugin '#{dep_name}', si está instalado, sea la version #{dep_version}"
                  msg << " o superior" if !exact
                  msg << ", pero la versión instalada es #{self.version(dep_name)}."
                  dep_link = self.link(dep_name)
                  if dep_link
                    msg << "\r\nVerifica #{dep_link} para obtener una actualización del plugin '#{dep_name}'."
                  end
                  self.error(msg)
                end
              elsif !self.installed?(dep_name, dep_version, exact)
                if self.installed?(dep_name)   # Tiene el plugin pero en una versión más baja
                  msg = "El plugin '#{name}' requiere que el plugin '#{dep_name}' sea la versión #{dep_version}"
                  msg << " o posterior" if !exact
                  msg << ", but the installed version was #{self.version(dep_name)}."
                  dep_link = self.link(dep_name)
                  if dep_link
                    msg << "\r\nCheck #{dep_link} for an update to plugin '#{dep_name}'."
                  end
                else   # Don't have plugin
                  msg = "El plugin '#{name}' requires plugin '#{dep_name}' version #{dep_version} "
                  msg << "or later " if !exact
                  msg << "para estar instalado antes que él."
                end
                self.error(msg)
              end
            end
          end
        end
      when :incompatibilities   # Incompatibilidades del plugin
        incompats = value
        incompats = [incompats] if !incompats.is_a?(Array)
        incompats.each do |incompat|
          if self.installed?(incompat)
            self.error("El plugin '#{name}' es incompatible con '#{incompat}'. No pueden usarse al mismo tiempo.")
          end
        end
      when :credits # Créditos del plugin
        value = [value] if value.is_a?(String)
        if value.is_a?(Array)
          value.each do |entry|
            if entry.is_a?(String)
              credits << entry
            else
              self.error("El array de créditos del plugin '#{name}' contiene un valor que no es una cadena.")
            end
          end
        else
          self.error("El campo de créditos del plugin '#{name}' debe contener una cadena o una matriz de cadenas.")
        end
      when :disabled # Requerido para que no tire error.
      else
        self.error("Clave de registro de plugin no válida '#{key}'.")
      end
    end
    @@Plugins.each_value do |plugin|
      if plugin[:incompatibilities]&.include?(name)
        self.error("El plugin '#{plugin[:name]}' es incompatible con '#{name}'. No pueden usarse al mismo tiempo.")
      end
    end
    # Agrega el plugin a la variable de clase
    @@Plugins[name] = {
      :name              => name,
      :version           => version,
      :essentials        => essentials,
      :link              => link,
      :dependencies      => dependencies,
      :incompatibilities => incompats,
      :credits           => credits
    }
  end

  # Lanza un mensaje de error puro sin rastreo de la pila u otra información inútil.
  def self.error(msg)
    Graphics.update
    t = Thread.new do
      Console.echo_error("Error del plugin:\r\n#{msg}")
      print("Error del plugin:\r\n#{msg}")
      Thread.exit
    end
    while t.status
      Graphics.update
    end
    Kernel.exit! true
  end

  # Devuelve true si el plugin especificado está instalado.
  # Si se especifica la versión, se tiene en cuenta esa versión.
  # Si mustequal es true, la versión debe coincidir con la versión especificada.
  def self.installed?(plugin_name, plugin_version = nil, mustequal = false)
    plugin = @@Plugins[plugin_name]
    return false if plugin.nil?
    return true if plugin_version.nil?
    comparison = compare_versions(plugin[:version], plugin_version)
    return true if !mustequal && comparison >= 0
    return true if mustequal && comparison == 0
  end

  # Devuelve los nombres de cadena de todos los plugin instalados.
  def self.plugins
    return @@Plugins.keys
  end

  # Devuelve la versión instalada del plugin especificado.
  def self.version(plugin_name)
    return if !installed?(plugin_name)
    return @@Plugins[plugin_name][:version]
  end

  # Devuelve el enlace del plugin especificado.
  def self.link(plugin_name)
    return if !installed?(plugin_name)
    return @@Plugins[plugin_name][:link]
  end

  # Devuelve los créditos del plugin especificado.
  def self.credits(plugin_name)
    return if !installed?(plugin_name)
    return @@Plugins[plugin_name][:credits]
  end

  # Compara dos versiones dadas en forma de cadena. v1 debería ser la versión del plugin
  # que realmente tienes, y v2 debería ser la versión mínima/deseada del plugin.
  # Valores de retorno:
  #     1 si v1 es mayor que v2
  #     0 si v1 es igual a v2
  #     -1 si v1 es menor que v2
  def self.compare_versions(v1, v2)
    d1 = v1.chars
    d1.insert(0, "0") if d1[0] == "."   # Convierte ".123" en "0.123"
    while d1[-1] == "."                 # Convierte "123." en "123"
      d1 = d1[0..-2]
    end
    d2 = v2.chars
    d2.insert(0, "0") if d2[0] == "."   # Convierte ".123" en "0.123"
    while d2[-1] == "."                 # Convierte "123." into "123"
      d2 = d2[0..-2]
    end
    [d1.size, d2.size].max.times do |i| # Compara cada dígito por turno
      c1 = d1[i]
      c2 = d2[i]
      if c1
        return 1 if !c2
        return 1 if c1.to_i(16) > c2.to_i(16)
        return -1 if c1.to_i(16) < c2.to_i(16)
      elsif c2
        return -1
      end
    end
    return 0
  end

  # Formatea el mensaje de error
  def self.pluginErrorMsg(name, script)
    e = $!
    # comenzar formateo del mensaje
    message = "[Pokémon Essentials versión #{Essentials::VERSION}]\r\n"
    message += "#{Essentials::ERROR_TEXT}\r\n"   # Para que los scripts de terceros lo añadan
    message += "Error en el Plugin: [#{name}]\r\n"
    message += "Excepción: #{e.class}\r\n"
    message += "Mensaje: "
    message += e.message
    # muestra las últimas 10 líneas de la traza de llamadas
    message += "\r\n\r\nTraza de llamadas:\r\n"
    e.backtrace[0, 10].each { |i| message += "#{i}\r\n" }
    # salida al registro de errores
    errorlog = "errorlog.txt"
    errorlog = RTP.getSaveFileName("errorlog.txt") if (Object.const_defined?(:RTP) rescue false)
    File.open(errorlog, "ab") do |f|
      f.write("\r\n=================\r\n\r\n[#{Time.now}]\r\n")
      f.write(message)
    end
    # formatea/censura el directorio del registro de errores
    errorlogline = errorlog.gsub("/", "\\")
    errorlogline.sub!(Dir.pwd + "\\", "")
    errorlogline.sub!(pbGetUserName, "USERNAME")
    errorlogline = "\r\n" + errorlogline if errorlogline.length > 20
    # output message
    print("#{message}\r\nEsta excepción fue registrada en #{errorlogline}.\r\nnMantén presionada la tecla Ctrl al cerrar este mensaje para copiarlo al portapapeles.")
    # Dar aproximadamente 500 ms para empezar a presionar Ctrl
    t = System.uptime
    until System.uptime - t >= 0.5
      Input.update
      if Input.press?(Input::CTRL)
        Input.clipboard = message
        break
      end
    end
  end
  
  
  # Utilizado para leer el archivo de metadatos
  def self.readMeta(dir, file)
    filename = "#{dir}/#{file}"
    meta = {}
    # lee el archivo
    Compiler.pbCompilerEachPreppedLine(filename) do |line, line_no|
      # split line up into property name and values
      if !line[/^\s*(\w+)\s*=\s*(.*)$/]
        raise _INTL("Sintaxis de línea incorrecta (se esperaba una sintaxis como XXX=YYY)\n{1}", FileLineData.linereport)
      end
      property = $~[1].upcase
      data = $~[2].split(",")
      data.each_with_index { |value, i| data[i] = value.strip }
      # comienza el formato del hash de datos
      case property
      when "ESSENTIALS"
        meta[:essentials] = [] if !meta[:essentials]
        data.each { |ver| meta[:essentials].push(ver) }
      when "REQUIRES"
        meta[:dependencies] = [] if !meta[:dependencies]
        if data.length < 2   # No se proporciona una versión, solo se agrega el nombre de la dependencia del plugin
          meta[:dependencies].push(data[0])
          next
        elsif data.length == 2   # Se agrega el nombre y la versión de la dependencia del plugin
          meta[:dependencies].push([data[0], data[1]])
        else   # Se agrega el tipo de dependencia, nombre y versión de la dependencia del plugin
          meta[:dependencies].push([data[2].downcase.to_sym, data[0], data[1]])
        end
      when "EXACT"
        next if data.length < 2   # Las dependencias exactas deben tener una versión proporcionada; se ignoran si no la tienen
        meta[:dependencies] = [] if !meta[:dependencies]
        meta[:dependencies].push([:exact, data[0], data[1]])
      when "OPTIONAL"
        next if data.length < 2   # Las dependencias opcionales deben tener una versión proporcionada; se ignoran si no la tienen
        meta[:dependencies] = [] if !meta[:dependencies]
        meta[:dependencies].push([:optional, data[0], data[1]])
      when "CONFLICTS"
        meta[:incompatibilities] = [] if !meta[:incompatibilities]
        data.each { |value| meta[:incompatibilities].push(value) if value && !value.empty? }
      when "SCRIPTS"
        meta[:scripts] = [] if !meta[:scripts]
        data.each { |scr| meta[:scripts].push(scr) }
      when "CREDITS"
        meta[:credits] = data
      when "LINK", "WEBSITE"
        meta[:link] = data[0]
      when "DISABLED"
        meta[:disabled] = data[0] if data[0]
      else
        meta[property.downcase.to_sym] = data[0]
      end
    end
    # Genera una lista de todos los archivos de script que se cargarán, en el orden en el que deben
    # cargarse (los archivos listados en el archivo meta se cargan primero)
    meta[:scripts] = [] if !meta[:scripts]
    # obtén todos los archivos de script del directorio del plugin
    Dir.all(dir).each do |fl|
      next if !fl.include?(".rb")
      meta[:scripts].push(fl.gsub("#{dir}/", ""))
    end
    # asegúrate de que no haya archivos de script duplicados en la cola
    meta[:scripts].uniq!
    # devuelve el hash de meta
    return meta
  end

  # Obtiene una lista de todos los directorios de plugins para inspeccionar
  def self.listAll
    return [] if !$DEBUG || FileTest.exist?("Game.rgssad") || !Dir.safe?("Plugins")
    # obtén una lista de todos los directorios en la carpeta `Plugins/`
    dirs = []
    Dir.get("Plugins").each { |d| dirs.push(d) if Dir.safe?(d) }
    # devuelve todos los plugins
    return dirs
  end

  # Captura cualquier posible bucle con dependencias y genera un error
  def self.validateDependencies(name, meta, og = nil)
    # salir si no hay dependencia registrada
    return nil if !meta[name] || !meta[name][:dependencies]
    og = [name] if !og
    # recorrer todas las dependencias
    meta[name][:dependencies].each do |dname|
      # limpiar el nombre a una cadena simple
      dname = dname[0] if dname.is_a?(Array) && dname.length == 2
      dname = dname[1] if dname.is_a?(Array) && dname.length == 3
      # capturar problema de bucle con dependencia
      self.error("El plugin '#{og[0]}' tiene dependencias en bucle que no se pueden resolver automáticamente.") if !og.nil? && og.include?(dname)
      new_og = og.clone
      new_og.push(dname)
      self.validateDependencies(dname, meta, new_og)
    end
    return name
  end

  # Ordena el orden de carga basándose en las dependencias (esto termina en orden inverso)
  def self.sortLoadOrder(order, plugins)
    # recorrer el orden de carga
    order.each do |o|
      next if !plugins[o] || !plugins[o][:dependencies]
      # recorrer todas las dependencias
      plugins[o][:dependencies].each do |dname|
        optional = false
        # limpiar el nombre a una cadena simple
        if dname.is_a?(Array)
          optional = [:optional, :optional_exact].include?(dname[0])
          dname = dname[dname.length - 2]
        end
        # capturar dependencia faltante
        if !order.include?(dname)
          next if optional
          self.error("El plugin '#{o}' requiere que el plugin '#{dname}' esté presente para funcionar correctamente.")
        end
        # saltar si ya está ordenado
        next if order.index(dname) > order.index(o)
        # capturar problema de bucle con dependencia
        order.swap(o, dname)
        order = self.sortLoadOrder(order, plugins)
      end
    end
    return order
  end

  # Obtener el orden en el que se cargarán los plugins
  def self.getPluginOrder
    plugins = {}
    order = []
    # Encontrar todas las carpetas de plugins que tengan un meta.txt y agregarlas a la lista de
    # plugins.
    self.listAll.each do |dir|
      # omitir si no hay archivo meta
      next if !FileTest.exist?(dir + "/meta.txt")
      ndx = order.length
      meta = self.readMeta(dir, "meta.txt")
      meta[:dir] = dir
      # generar error si no se define un nombre para el plugin
      self.error("No se ha definido metadatos 'Name' para el plugin ubicado en '#{dir}'.") if !meta[:name]
      # generar error si no se define un script para el plugin
      self.error("No se han definido metadatos 'Scripts' para el plugin ubicado en '#{dir}'.") if !meta[:scripts]
      plugins[meta[:name]] = meta
      # generar error si ya existe un plugin con el mismo nombre
      self.error("Ya existe un plugin llamado '#{meta[:name]}' en el orden de carga.") if order.include?(meta[:name])
      order.insert(ndx, meta[:name])
    end
    # validar todas las dependencias
    order.each { |o| self.validateDependencies(o, plugins) }
    # ordenar el orden de carga
    return self.sortLoadOrder(order, plugins).reverse, plugins
  end

  # Comprobar si los plugins necesitan compilarse
  def self.needCompiling?(order, plugins)
    # acciones fijas
    return false if !$DEBUG || FileTest.exist?("Game.rgssad")
    return true if !FileTest.exist?("Data/PluginScripts.rxdata")
    Input.update
    return true if Input.press?(Input::SHIFT) || Input.press?(Input::CTRL)
    # analizar si se debe presionar o no la recompilación
    mtime = File.mtime("Data/PluginScripts.rxdata")
    order.each do |o|
      # revisar todos los scripts de complementos registrados
      scr = plugins[o][:scripts]
      dir = plugins[o][:dir]
      scr.each do |sc|
        return true if File.mtime("#{dir}/#{sc}") > mtime
      end
      return true if File.mtime("#{dir}/meta.txt") > mtime
    end
    return false
  end
  
  # Compruebe si es necesario compilar los complementos
  def self.compilePlugins(order, plugins)
    Console.echo_li("Compilando scripts de plugins...")
    scripts = []
    # recorrer todo el orden uno por uno
    order.each do |o|
      # guardar nombre, metadatos y array de scripts
      meta = plugins[o].clone
      meta.delete(:scripts)
      meta.delete(:dir)
      dat = [o, meta, []]
      # iterar a través de cada archivo para desinflar
      plugins[o][:scripts].each do |file|
        File.open("#{plugins[o][:dir]}/#{file}", "rb") do |f|
          dat[2].push([file, Zlib::Deflate.deflate(f.read)])
        end
      end
      # agregar al array principal de scripts
      scripts.push(dat)
    end
    # guardar en el archivo principal `PluginScripts.rxdata`
    File.open("Data/PluginScripts.rxdata", "wb") { |f| Marshal.dump(scripts, f) }
    # recolectar basura
    GC.start
    Console.echo_done(true)
  end

  # Comprobar si los plugins necesitan compilarse
  def self.runPlugins
    Console.echo_h1("Comprobando plugins")
    # obtener el orden de los plugins a interpretar
    order, plugins = self.getPluginOrder
    # compilar si es necesario
    if self.needCompiling?(order, plugins)
      self.compilePlugins(order, plugins)
    else
      Console.echoln_li("Los plugins no se han tenido que recompilar")
    end
    # load plugins
    scripts = load_data("Data/PluginScripts.rxdata")
    echoed_plugins = []
    skipped_plugins = 0
    scripts.each do |plugin|
      
      # get the required data
      name, meta, script = plugin
      
      # Skip disabled scripts 
      if meta.key?(:disabled) && [true,'true','verdadero','si', 'x'].include?(meta[:disabled].downcase)
        skipped_plugins+=1
        next
      end
      
      if !meta[:essentials] || !meta[:essentials].include?(Essentials::VERSION)
        Console.echo_warn("El plugin '#{name}' puede no ser compatible con Essentials v#{Essentials::VERSION}. Intentando cargar de todos modos.")
      end
      
      # registrar plugin
      self.register(meta)
      # recorrer cada script e interpretar
      script.each do |scr|
        # convertir el código a texto plano
        code = Zlib::Inflate.inflate(scr[1]).force_encoding(Encoding::UTF_8)
        # deshacerse de las tabulaciones
        code.gsub!("\t", "  ")
        # construir el nombre del archivo
        sname = scr[0].gsub("\\", "/").split("/")[-1]
        fname = "[#{name}] #{sname}"
        # intentar ejecutar el código
        begin
          eval(code, TOPLEVEL_BINDING, fname)
          Console.echoln_li("Plugin cargado: ==#{name}== (ver. #{meta[:version]})") if !echoed_plugins.include?(name)
          echoed_plugins.push(name)
        rescue Exception   # formatear el mensaje de error para mostrar
          self.pluginErrorMsg(name, sname)
          Kernel.exit! true
        end
      end
    end
    if scripts.length > 0
      Console.echoln_li_done("Se cargaron correctamente #{scripts.length - skipped_plugins} plugin(s)")
    else
      Console.echoln_li_done("No se ha encontrado ningún plugin")
    end
  end

  # Obtener directorio de plugin a partir del nombre basado en entradas de metadatos
  def self.findDirectory(name)
    # ecorrer la carpeta de plugins
    Dir.get("Plugins").each do |dir|
      next if !Dir.safe?(dir)
      next if !FileTest.exist?(dir + "/meta.txt")
      # leer meta
      meta = self.readMeta(dir, "meta.txt")
      return dir if meta[:name] == name
    end
    # Devuelve nil si no encuentra la carpeta de plugins
    return nil
  end
end

