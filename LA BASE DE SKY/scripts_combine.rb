require 'zlib'

class Numeric
  def to_digits(num = 3)
    str = to_s
    (num - str.size).times { str = str.prepend("0") }
    str
  end
end

module Scripts
  def self.from_folder(path = "Data/Scripts", rxdata = "Data/Scripts.rxdata")
    scripts = File.open(rxdata, 'rb') { |f| Marshal.load(f) } if File.exist?(rxdata)
    if scripts && scripts.length > 10
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

    Dir.foreach(path) do |entry|
      next if entry == '.' || entry == '..'

      full_path = File.join(path, entry)
      if File.directory?(full_path)
        folders << entry
      else
        files << entry
      end
    end

    # Aggregate individual script files into Scripts.rxdata
    files.sort!
    file_id = 0
    files.each do |f|
      file_id += 1
      section_id = filename_to_id(f)
      file_id = [file_id, section_id].max
      section_name = filename_to_title(f)
      content = File.open(File.join(path, f), "rb:UTF-8") { |f2| f2.read }
      scripts << [rand(999_999), section_name, Zlib::Deflate.deflate(content)]
    end

    # Add separator before each folder
    folders.sort!
    folders.each do |folder|
      section_name = filename_to_title(folder)
      if level.zero?
        scripts << [rand(999_999), "==================", Zlib::Deflate.deflate("")]
      end
      scripts << [rand(999_999), "[[ " + section_name + " ]]", Zlib::Deflate.deflate("")]
      aggregate_from_folder(File.join(path, folder), scripts, level + 1)
    end
  end

  def self.filename_to_id(filename)
    filename = filename.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
    if filename[/^[^_]*_(\d+)/]
      $1.to_i
    else
      0
    end
  end

  def self.filename_to_title(filename)
    filename = filename.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
    title = File.basename(filename, File.extname(filename)).split('_', 2).last || "unnamed"
    title.strip!
    title.empty? ? "unnamed" : title
  end
end

Scripts.from_folder