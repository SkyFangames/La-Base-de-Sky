#===============================================================================
# Edits compiler code to allow for female sprite metrics.
#===============================================================================
module Compiler
  module_function
  
  #-----------------------------------------------------------------------------
  # Aliased to automatically apply flag for all species with female sprites.
  #-----------------------------------------------------------------------------
  Compiler.singleton_class.alias_method :gendered_validate_all_compiled_pokemon, :validate_all_compiled_pokemon
  def validate_all_compiled_pokemon
    changes_made = false
    GameData::Species.each do |sp|
      next if [:Genderless, :AlwaysMale, :AlwaysFemale].include?(sp.gender_ratio)
      file1 = GameData::Species.front_sprite_filename(sp.species, 0)
      if file1 == GameData::Species.front_sprite_filename(sp.species, 0, 1)
        next if !sp.flags.include?("HasGenderedSprites")
        sp.flags.delete("HasGenderedSprites")
        changes_made = true
      else
        next if sp.flags.include?("HasGenderedSprites")
        sp.flags.push("HasGenderedSprites")
        changes_made = true
      end
    end
    write_pokemon if changes_made
    gendered_validate_all_compiled_pokemon	
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to automatically apply flag for all forms with female sprites.
  #-----------------------------------------------------------------------------
  Compiler.singleton_class.alias_method :gendered_validate_all_compiled_pokemon_forms, :validate_all_compiled_pokemon_forms
  def validate_all_compiled_pokemon_forms
    changes_made = false
    GameData::Species.each do |sp|
      next if sp.form == 0
      next if [:Genderless, :AlwaysMale, :AlwaysFemale].include?(sp.gender_ratio)
      file1 = GameData::Species.front_sprite_filename(sp.species, sp.form)
      if file1 == GameData::Species.front_sprite_filename(sp.species, sp.form, 1)
        next if !sp.flags.include?("HasGenderedSprites")
        sp.flags.delete("HasGenderedSprites")
        changes_made = true if !sp.flags.empty?
      else
        next if sp.flags.include?("HasGenderedSprites")
        sp.flags.push("HasGenderedSprites")
        changes_made = true
      end
    end
    write_pokemon_forms if changes_made
    gendered_validate_all_compiled_pokemon_forms	
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to validate metrics data for female sprites.
  #-----------------------------------------------------------------------------
  def validate_compiled_pokemon_metrics(hash)
    if hash[:id].is_a?(Array)
      hash[:species] = hash[:id][0]
      hash[:form] = hash[:id][1] || 0
      hash[:female] = hash[:id][2] || false
      gender = (hash[:female]) ? "_female" : ""
      if hash[:form] == 0
        hash[:id] = sprintf("%s%s", hash[:species].to_s, gender).to_sym
      else
        hash[:id] = sprintf("%s_%d%s", hash[:species].to_s, hash[:form], gender).to_sym
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Rewritten to include checks for new metrics data added by this plugin.
  #-----------------------------------------------------------------------------
  def write_pokemon_metrics
    paths = [""]
    GameData::SpeciesMetrics.each do |element|
      next if element.form == 0
      paths.push(element.pbs_file_suffix) if !paths.include?(element.pbs_file_suffix)
    end
    paths.each_with_index do |element, i|
      paths[i] = [sprintf("PBS/%s.txt", GameData::SpeciesMetrics::PBS_BASE_FILENAME), element]
      if !nil_or_empty?(element)
        paths[i][0] = sprintf("PBS/%s_%s.txt", GameData::SpeciesMetrics::PBS_BASE_FILENAME, element)
      end
    end
    schema = GameData::SpeciesMetrics.schema
    idx = 0
    paths.each do |path|
      write_pbs_file_message_start(path[0])
      File.open(path[0], "wb") do |f|
        add_PBS_header_to_file(f)
        GameData::SpeciesMetrics.each do |element|
          next if element.pbs_file_suffix != path[1]
          if element.form > 0 || element.female
            if element.female
              id = (element.form > 0) ? (element.species.to_s + "_" + element.form.to_s).to_sym : element.species
              base_element = GameData::SpeciesMetrics.try_get(id)
            elsif element.species == :ALCREMIE && element.form > 0
              base_element = GameData::SpeciesMetrics.try_get(:ALCREMIE_7)
              base_element = GameData::SpeciesMetrics.try_get(:ALCREMIE) if !base_element
            else
              base_element = GameData::SpeciesMetrics.try_get(element.species)
            end
            next if !base_element
            next if element.back_sprite == base_element.back_sprite &&
                    element.front_sprite == base_element.front_sprite &&
                    element.front_sprite_altitude == base_element.front_sprite_altitude &&
                    element.shadow_x == base_element.shadow_x &&
                    element.shadow_size == base_element.shadow_size &&
                    element.shadow_sprite == base_element.shadow_sprite &&
                    element.animation_speed == base_element.animation_speed &&
                    element.super_shiny_hue == base_element.super_shiny_hue
          end
          echo "." if idx % 100 == 0
          Graphics.update if idx % 500 == 0
          idx += 1
          f.write("\#-------------------------------\r\n")
          if schema["SectionName"]
            f.write("[")
            pbWriteCsvRecord(element.get_property_for_PBS("SectionName"), f, schema["SectionName"])
            f.write("]\r\n")
          else
            f.write("[#{element.id}]\r\n")
          end
          schema.each_key do |key|
            next if key == "SectionName"
            val = element.get_property_for_PBS(key)
            next if val.nil?
            if schema[key][1][0] == "^" && val.is_a?(Array)
              val.each do |sub_val|
                f.write(sprintf("%s = ", key))
                pbWriteCsvRecord(sub_val, f, schema[key])
                f.write("\r\n")
              end
            else
              f.write(sprintf("%s = ", key))
              pbWriteCsvRecord(val, f, schema[key])
              f.write("\r\n")
            end
          end
        end
      end
      process_pbs_file_message_end
    end
  end
end