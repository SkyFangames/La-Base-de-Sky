#===============================================================================
# This compiler code is used to automatically write in new lines of PBS data to
# each relevant file based on what's contained in the PBS/Plugins folder.
# This allows supported plugins to add new data they require as soon as they are
# detected and the game is recompiled.
#===============================================================================
module Compiler
  module_function
  
  #-----------------------------------------------------------------------------
  # Used for cleaning schema of enumerals before they exist during compiling.
  #-----------------------------------------------------------------------------
  def simplify_schema(schema)
    new_schema = {}
    schema.each do |key, val|
      new_value = []
      val.each_with_index do |data, i|
        case data
        when Symbol
          new_value.push(0) if i == 0
          next
        when String
          new_string = ""
          data.chars.each do |str|
            case str
            when "e" then str = "m"
            when "E" then str = "M"
            end
            new_string += str
          end
          new_value.push(new_string)
        else
          new_value.push(data) if !data.nil?
        end
      end
      new_schema[key] = new_value
    end
    return new_schema
  end
  
  #-----------------------------------------------------------------------------
  # Rewritten to automatically modify PBS files with plugin information.
  #-----------------------------------------------------------------------------
  def edit_and_rewrite_pbs_file_text(filename)
    return if !block_given?
    lines = []
    File.open(filename, "rb") do |f|
      f.each_line do |line| 
        line += "\r\n" if !line.include?("\r\n")
        lines.push(line)
      end
    end
    @line_rewrites = []
    @line_additions = []
    @file_line_length = lines.length
    @plugin_change = nil
    changed = false
    lines.each { |line| changed = true if yield line }
    if !@line_rewrites.empty?
      @line_rewrites.each do |rewrite|
        section = false
        lines.each_with_index do |line, i|
          section = true if line.include?("[#{rewrite[0]}]")
          if section && line.include?("#{rewrite[1]} = ")
            lines[i] = rewrite[2]
            break
          end
        end
      end
      changed = true
    end
    if !@line_additions.empty?
      @line_additions.reverse.each { |i| lines.insert(i[1], i[2]) }
      changed = true
    end
    if changed
      if @plugin_change
        msg = "Changes made to file #{filename} by plugin [#{@plugin_change}]."
      else
        msg = "Changes made to file #{filename}."
      end
      echoln Console.markup_style(msg, text: :yellow)
      File.open(filename, "wb") do |f|
        lines.each { |line| f.write(line) }
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Rewritten to detect if an installed plugin needs to edit a PBS file.
  #-----------------------------------------------------------------------------
  def modify_pbs_file_contents_before_compiling
    edit_and_rewrite_pbs_file_text("PBS/trainer_types.txt") do |line|
      next line.gsub!(/^\s*VictoryME\s*=/, "VictoryBGM =")
    end
    edit_and_rewrite_pbs_file_text("PBS/moves.txt") do |line|
      next line.gsub!(/^\s*BaseDamage\s*=/, "Power =")
    end
    #---------------------------------------------------------------------------
    # Checks each viable plugin for any PBS/Plugins files that need changing.
    #---------------------------------------------------------------------------
    force_rewrites = Input.press?(Input::SHIFT)
    text_files = get_all_pbs_files_to_compile
    PluginManager.plugins.each do |plugin|
      next if !plugin.include?("[DBK]")
      text_files.each_key do |data_type|
        case data_type
        when :Type               then game_data = GameData::Type
        when :Ability            then game_data = GameData::Ability
        when :Move               then game_data = GameData::Move
        when :Item               then game_data = GameData::Item
        when :Species, :Species1 then game_data = GameData::Species
        when :SpeciesMetrics     then game_data = GameData::SpeciesMetrics
        when :Ribbon             then game_data = GameData::Ribbon
        when :TrainerType        then game_data = GameData::TrainerType
        when :MapMetadata        then game_data = GameData::MapMetadata
        end
        next if !game_data
        schema = (data_type == :Species1) ? game_data.schema(true) : game_data.schema
        schema = simplify_schema(schema)
        #-----------------------------------------------------------------------
        # Compiles a data hash for each text file found in PBS/Plugins/#{plugin}.
        #-----------------------------------------------------------------------
        next if !text_files[data_type] || text_files[data_type][1].empty?
        text_files[data_type][1].each do |file_name|
          file_path = file_name.split("/")[1]
          path = "PBS/Plugins/#{plugin}/#{file_path}"
          next if !FileTest.exist?(path)
          can_skip_rewrites = false
          File.open(path, "rb") do |f|
            f.each_line do |line|
              if line == "### Apply changes by holding SHIFT while compiling. ###\r\n"
                can_skip_rewrites = true
              end
              break
            end
          end
          next if can_skip_rewrites && !force_rewrites
          data_hash = {}
          File.open(path, "rb") do |f|
            FileLineData.file = path
            pbEachFileSection(f, schema) do |contents, section_name|
              data_hash[section_name] = {}
              schema.each_key do |key|
                FileLineData.setSection(section_name, key, contents[key])
                next if contents[key].nil?
                if schema[key][1][0] == "^"
                  contents[key].each do |val|
                    value = get_csv_record(val, schema[key])
                    value = nil if value.is_a?(Array) && value.empty?
                    data_hash[section_name][key] ||= []
                    data_hash[section_name][key].push(value)
                  end
                  data_hash[section_name][key].compact!
                else
                  value = get_csv_record(contents[key], schema[key])
                  value = nil if value.is_a?(Array) && value.empty?
                  data_hash[section_name][key] = value
                end
              end
            end
          end
          #---------------------------------------------------------------------
          # Determines which lines need to be added to each PBS file.
          #---------------------------------------------------------------------
          if !data_hash.empty?
            idx = 0
            section_name = old_section = nil
            edit_and_rewrite_pbs_file_text("#{file_name}") do |line|
              next if !force_rewrites && 
              line == "### Apply changes by holding SHIFT while compiling. ###\r\n"
              if line[/^\s*\[\s*(.*)\s*\]\s*$/]
                old_section = section_name
                section_name = $~[1]
              elsif line.first == "["
                old_section = section_name
                section_name = line.split("[")[1]
                section_name = section_name.split("]")[0]
              elsif section_name && data_hash[section_name]
                line_data = line.split(" = ")
                property = line_data[0]
                if data_hash[section_name].has_key?(property)
                  old_value = line_data[1].split("\r\n")[0]
                  new_value = data_hash[section_name][property]
                  case new_value
                  when Array
                    case property
                    when "TutorMoves", "EggMoves", "Flags"
                      new_array = old_value.split(",")
                      new_value.each do |val|
                        next if new_array.include?(val.to_s)
                        new_array.push(val.to_s)
                      end
                      new_line = property + " = " + new_array.join(",") + "\r\n"
                    else
                      new_line = property + " = " + new_value.flatten.join(",") + "\r\n"
                    end
                  else
                    new_line = property + " = " + new_value.to_s + "\r\n"
                  end
                  if new_line != line
                    @line_rewrites.push([section_name, property, new_line])
                    @plugin_change = plugin
                  end
                  data_hash[section_name].delete(property)
                  data_hash.delete(section_name) if data_hash[section_name].empty?
                end
              end
              last_section = idx >= @file_line_length - 1
              section = (last_section) ? section_name : old_section
              if section && data_hash[section] && !data_hash[section].empty?
                i = (last_section) ? @file_line_length : idx - 1
                data_hash[section].each do |key, value|
                  case value
                  when Array
                    @line_additions.push([section, i, key + " = " + value.flatten.join(",") + "\r\n"])
                  else
                    @line_additions.push([section, i, key + " = " + value.to_s + "\r\n"])
                  end
                end
                @plugin_change = plugin
                data_hash.delete(section)
              end
              idx += 1
              next false
            end
          end
          if @plugin_change
            edit_and_rewrite_pbs_file_text(path) do |line|
            next line.gsub!("### Changes will apply automatically. ###", 
                            "### Apply changes by holding SHIFT while compiling. ###")
            end
          end
        end
      end
    end
  end
end


#===============================================================================
# Plugin manager.
#===============================================================================
module PluginManager
  PluginManager.singleton_class.alias_method :dbk_register, :register
  def self.register(options)
    dbk_register(options)
    self.plugin_check_DBK
  end
  
  #-----------------------------------------------------------------------------
  # Used to ensure all plugins that rely on Deluxe Battle Kit are up to date.
  #-----------------------------------------------------------------------------
  def self.plugin_check_DBK(version = "1.2.7")
    if self.installed?("Deluxe Battle Kit", version, true)
      {"[DBK] Enhanced Battle UI"      => "2.0.8",
       "[DBK] SOS Battles"             => "1.1.1",
       "[DBK] Raid Battles"            => "1.0",
       "[DBK] Z-Power"                 => "1.1.1",
       "[DBK] Dynamax"                 => "1.1.2",
       "[DBK] Terastallization"        => "1.1.5",
       "[DBK] Improved Item AI"        => "1.0.1",
       "[DBK] Wonder Launcher"         => "1.0.6",
       "[DBK] Animated Pokémon System" => "1.1",
	   "[DBK] Animated Trainer Intros" => "1.0.1",
       "[MUI] Improved Mementos"       => "1.0.4"
      }.each do |p_name, v_num|
        next if !self.installed?(p_name)
        p_ver = self.version(p_name)
        valid = self.compare_versions(p_ver, v_num)
        next if valid > -1
        link = self.link(p_name)
        self.error("Plugin '#{p_name}' is out of date.\nPlease download the latest version at:\n#{link}")
      end
    end
  end
end