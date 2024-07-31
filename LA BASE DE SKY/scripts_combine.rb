require 'zlib'

class Numeric
  def to_digits(num = 3)
    str = to_s
    (num - str.size).times { str = str.prepend("0") }
    return str
  end
end

module Scripts
  def self.from_folder(path = "Data/Scripts", rxdata = "Data/Scripts.rxdata")
    scripts = File.open(rxdata, 'rb') { |f| Marshal.load(f) }
    if scripts.length > 10
      p "Scripts.rxdata ya tiene bastantes scripts dentro. No se pueden añadir nuevos ya que se perderían."
      p "Debes extraer primero los scripts y vaciar los del juego para poder añadir nuevos desde fuera."
      return
    end

    scripts = []
    aggregate_from_folder(path, scripts)
    # Save scripts to file
    File.open(rxdata, "wb") do |f|
      Marshal.dump(scripts, f)
    end
  end

  def self.aggregate_from_folder(path, scripts, level = 0)
    files = []
    folders = []
    Dir.foreach(path) do |f|
      next if f == '.' || f == '..'

      if File.directory?(path + "/" + f)
        folders.push(f)
      else
        files.push(f)
      end
    end
    # Aggregate individual script files into Scripts.rxdata
    files.sort!
    file_id = 0
    files.each do |f|
      file_id += 1
      section_id = filename_to_id(f)
      if file_id < section_id
        file_id = section_id
      end
      section_name = filename_to_title(f)
      content = File.open(path + "/" + f, "rb") { |f2| f2.read }
      scripts << [rand(999_999), section_name, Zlib::Deflate.deflate(content)]
    end
    # Add separator before each folder
    folders.sort!
    folders.each do |f|
      section_name = filename_to_title(f)
      if level == 0
        scripts << [rand(999_999), "==================", Zlib::Deflate.deflate("")]
      end
      scripts << [rand(999_999), "[[ " + section_name + " ]]", Zlib::Deflate.deflate("")]
      aggregate_from_folder(path + "/" + f, scripts, level + 1)
    end    
  end

  def self.filename_to_id(filename)
    filename = filename.bytes.pack('U*')
    id = 0
    if filename[/^[^_]*_(.+)$/]
      sid = $~[0].to_i
      return sid
    end
    return id
  end

  def self.filename_to_title(filename)
    filename = filename.bytes.pack('U*')
    title = ""
    if filename[/^[^_]*_(.+)$/]
      title = $~[1]
      title = title[0..-4] if title.end_with?(".rb")
      title = title.strip
    end
    title = "unnamed" if !title || title.empty?
    title.gsub!(/&bs;/, "\\")
    title.gsub!(/&fs;/, "/")
    title.gsub!(/&cn;/, ":")
    title.gsub!(/&as;/, "*")
    title.gsub!(/&qm;/, "?")
    title.gsub!(/&dq;/, "\"")
    title.gsub!(/&lt;/, "<")
    title.gsub!(/&gt;/, ">")
    title.gsub!(/&po;/, "|")
    return title
  end
end

Scripts.from_folder
