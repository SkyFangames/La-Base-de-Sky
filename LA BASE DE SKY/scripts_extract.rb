require 'zlib'

class Numeric
  def to_digits(num = 3)
    str = to_s
    (num - str.size).times { str = str.prepend("0") }
    str
  end
end

module Scripts
  def self.dump(path = "Data/Scripts", rxdata = "Data/Scripts.rxdata")
    # Load scripts from rxdata
    scripts = File.open(rxdata, 'rb') { |f| Marshal.load(f) }
    if scripts.length < 10
      p "Scripts appear to already be extracted. Skipping extraction."
      return
    end

    # Ensure directory exists and is empty
    create_directory(path)
    clear_directory(path)

    folder_id = [1, 1]
    file_id = 1
    folder_path = path
    level = 0   # 0=main path, 1=subfolder, 2=sub-subfolder

    scripts.each_with_index do |entry, index|
      _, title, script = entry
      title = title_to_filename(title).strip
      script = Zlib::Inflate.inflate(script)

      # Skip titles with only '=' characters and more than three of them
      next if title.match?(/^=+$/) && title.length > 3

      if title.match?(/\[\[\s*(.+)\s*\]\]$/) # Section for folder creation
        # Extract the section name
        section_name = title[/\[\[\s*(.+)\s*\]\]$/, 1]&.strip || "Unnamed Section"

        # Folder logic: Create folder, then reset path for next section
        folder_num   = (index < scripts.length - 2) ? folder_id[level].to_digits(3) : "999"
        folder_name  = "#{folder_num}_#{section_name}"
        folder_path = File.join(path, folder_name)
        create_directory(folder_path)

        # Reset for the next set of scripts in this folder
        folder_id[level] += 1
        file_id = 1 # Reset file numbering for the new folder
      else
        next if script.empty? # Skip empty scripts
        file_num = file_id.to_digits(3)
        file_name = "#{file_num}_#{title}.rb"
        create_script(File.join(folder_path, file_name), script)
        file_id += 1
      end
    end

    # Backup the original Scripts.rxdata
    File.open("Data/ScriptsBackup.rxdata", "wb") { |f| Marshal.dump(scripts, f) }

    # Replace Scripts.rxdata with a loader script
    create_loader_scripts(rxdata)
  end

  def self.create_loader_scripts(rxdata)
    txt = "x\x9C}SM\x8F\xDA0\x10\xBD#\xF1\x1F\x86,Rb-2\xCB\xB1\x95\xE8\x1E\xBAm\xD5S\xAB\x85\e\xA0\xC8$\x13p7\xD8\x91\xED\x94n\t\xFF\xBD\xB6C0\xE9\xD7\xC5\xF2\xCCx\xDE\xCC\xBCy\xBE\x83\xE5\x9Ek\xC8%j\x10\xD2\xC0Q\xAA\x17\xE0\x05\x98=\xC2\x8E\x1D\x10l\x10E\xA6^+\x83\xF9h8\x18\x0Er\xB4Q\xC52\xDC\xB2\xEC%UXIe\x86\x03\x00gz?\xCCa<\xA2W\x93f\xA5\x14\xD8{A\x91e\xFB\x134[\xD38\xBF\x8D\x18\xAA\xEB\xED(\x99\xAEO\xC9:\xBF'\xEB\xF3\x94\xC0)Z\xDD\x9D\xC6\xB3\xF3\xC6\x9E\xCF\x9F\x16\x8Bt\xF1\xFE\xF9\xF3\xD7\xE5b5\x9EQ#S\xBEY\xCD6\xE7\xE8\xEC\x10\xFC\xA1\xD0\xD4J\xB8\xDA\a\xD4\x9A\xED\x10\xEE!Z\x8B\xB5\x88\xEC%\xD4\xFE&\xB9H\xAC?\"\xC3\x01\x8A\xBC\eI1\xAE1\r\x83\xA1RR9XKF\x80\xA4\x9A\xFFDx7\x877\x0F\x0Fm\xEB\x1Fy\x89TV(\x92\xF8\x9ALK\xB9\x8B'\x10\x1Fc;\x054E\x03\x05=*n0\x19\x8FH\xDB,\xB4\x05!^vI\x8Ei#%l\xF9\x8E\xC2\x97\xDAT\xB5\x01.\xA0\x0F\xEAR\xB1\xD4x\x03\xE1]n\x8E\x9BaJ\xC9\xF2Tg\x8AWF\xA7\x85\x92\x87\xB4\x90e\x8E*\xA9\x98\xD9\x13\x97Q\xD8\xB6\xB5\x85\x98\xC3j\xE3m\x1F\xD7W\xFB\x89+ZH\xE5\x16\xD5&Y\x89\xB8I\xDA\xC2\x02\x7F\x18GL\x01\xF39\xC44\x86\xA6\xE9\xEE4n\x9F$\x9E\x98\x9C+\xCC\x8CT\xAF\x8F\x1E\xC5md\xEA\xD6Q\x10\x02\x8F]QZ\xD5z\x9F\x14\x04\xDE^\xFA\xEA\x1C\xD7\xD1:\xBF\xB6Z\e\x05\xD3u\xD7\xEB+\x93\xB9\x93_\xD8I\xBF\xE8\x04\"\x15\xB5+\xB1/\x1A\x8FB\xED\x8Cy\xB7\x93-\xEE\xB8h\xAF\xB6\xF2wV&\x0Eq\x02\x82\x97\x13h\xFBq:\xD3Y\x8D\xB0\xF0\xF4~\xE8d\x12Vz\x13\xA0\x02\x8FIPO\x0F\xA0K\xBA\x15\x97\xFB\x03\xC1\x9E\xFC\xF1\xCFH\xAF\xD2\xDF\xD4z%\xAC\xE3\xEDBq`\xEE\xE2\b\xDCy\xC7\x85\xC0\xFF\n'\x10\xE9}\xE4w\xE5\xFD39zb\x86M[^tD~\x01LYX\x94"
    File.open(rxdata, "wb") { |f| Marshal.dump([[62054200, "Main", txt]], f) }
  end

  def self.title_to_filename(title)
    title.gsub(/\\/, "&bs;")
         .gsub(/\//, "&fs;")
         .gsub(/:/, "&cn;")
         .gsub(/\*/, "&as;")
         .gsub(/\?/, "&qm;")
         .gsub(/"/, "&dq;")
         .gsub(/</, "&lt;")
         .gsub(/>/, "&gt;")
         .gsub(/\|/, "&po;")
  end

  def self.create_script(path, content)
    create_directory(File.dirname(path)) # Ensure the directory exists
    File.open(path, "wb") { |f| f.write(content) }
  end

  def self.clear_directory(path, delete_current = false)
    Dir.foreach(path) do |entry|
      next if entry == '.' || entry == '..'
      full_path = File.join(path, entry)
      if File.directory?(full_path)
        clear_directory(full_path, true)
      else
        File.delete(full_path)
      end
    end
    Dir.delete(path) if delete_current
  end

  def self.create_directory(path)
    parts = path.split(File::SEPARATOR)
    (1..parts.length).each do |i|
      sub_path = File.join(parts[0...i])
      Dir.mkdir(sub_path) unless File.directory?(sub_path)
    end
  end
end

Scripts.dump
