#===============================================================================
# SISTEMA DE BÚSQUEDA AVANZADA
# Créditos: wrigty12, KRLW890, Zik
#===============================================================================

#-------------------------------------------------------------------------------
# 1. Utilidades de Búsqueda.
#-------------------------------------------------------------------------------

# Removedor de acentos
def pbRemoveAccents(text)
  return "" if text.nil?
  text = text.to_s
  return text.tr(
    "ÀÁÂÃÄÅàáâãäåÈÉÊËèéêëÌÍÎÏìíîïÒÓÔÕÖØòóôõöøÙÚÛÜùúûüÑñÇç",
    "AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOOooooooUUUUuuuuNnCc"
  )
end

# Algoritmo de Levenshtein
def pbLevenshtein(first, second)
  matrix = [(0..first.length).to_a]
  (1..second.length).each do |j|
    matrix << [j] + [0] * first.length
  end

  (1..second.length).each do |i|
    (1..first.length).each do |j|
      if first[j-1] == second[i-1]
        matrix[i][j] = matrix[i-1][j-1]
      else
        matrix[i][j] = [
          matrix[i-1][j],    # Borrado
          matrix[i][j-1],    # Inserción
          matrix[i-1][j-1],  # Sustitución
        ].min + 1
      end
    end
  end
  return matrix.last.last
end

# Lógica de coincidencia por si se escribe mal una palabra
def pbSmartMatch?(text, search_term)
  # Limpieza básica
  text_clean = pbRemoveAccents(text.to_s).downcase
  term_clean = pbRemoveAccents(search_term.to_s).downcase
  
  # Coincidencia exacta parcial
  return true if text_clean.include?(term_clean)
  
  # Si el término es muy corto, exigimos coincidencia exacta
  return false if term_clean.length <= 2
  
  # Tolerancia de errores
  tolerance = (term_clean.length >= 6) ? 2 : 1

  # Dividimos el nombre del objeto en palabras para buscar similitudes
  words = text_clean.split(" ")
  words.each do |word|
     if (word.length - term_clean.length).abs <= tolerance
       dist = pbLevenshtein(word, term_clean)
       return true if dist <= tolerance
     end
  end
  
  # Busqueda de frases completas si las longitudes son similares
  if (text_clean.length - term_clean.length).abs <= tolerance + 2
      dist_full = pbLevenshtein(text_clean, term_clean)
      return true if dist_full <= tolerance
  end
  
  return false
end

def pbOpenGenericListSearch
    term = pbMessageFreeText(_INTL("¿Qué desea buscar?"), "", false, 32)
    return nil if term.nil? || term.empty?
    return term
end

#-------------------------------------------------------------------------------
# 2. pbChooseList command enhancements
#-------------------------------------------------------------------------------
def commands_sortable_handle_input_enhancements(command, cmdwindow, cmdIfCancel, sortable)
  if Input.triggerex?(:F)
    searchTerm = pbOpenGenericListSearch
    if searchTerm
      command = [2, searchTerm]
      return command
    end
  end
end

#-------------------------------------------------------------------------------
# 3. pbListScreen Searcher
#-------------------------------------------------------------------------------
def list_screen_handle_input_enhancements(list, lister, selectedmap, full_original_list, block=false)
  if Input.triggerex?(:F)
    searchTerm = pbOpenGenericListSearch
    if searchTerm
      # Lista Maestra   
      newSearch = full_original_list.select do |cmd|
        cmd_text = cmd.to_s
        if cmd_text =~ /^\d+:\s*(.+)$/
          cmd_text = $1
        end

        cmd_translated = _INTL(cmd_text)        
        pbSmartMatch?(cmd_translated, searchTerm)
      end
          
      unless newSearch.empty?
        lister.commands_override = newSearch
        list.commands = lister.commands
        list.index = 0
        lister.refresh(0)
        selectedmap = -1
      else
        pbMessage(_INTL("No hay resultados."))
      end
    end
  end
end

#-------------------------------------------------------------------------------
# 5. Inyección automática de búsqueda en los Listers
#-------------------------------------------------------------------------------

# Para no repetir código, y agregar facilmente futuros listers si se requiere
TARGET_LISTERS = [
  :SpeciesLister,
  :ItemLister,
  :MoveLister,
  :AbilityLister,
  :TrainerTypeLister,
  :TrainerBattleLister,
  :MapLister,
  :GraphicsLister,
  :MusicFileLister
]

TARGET_LISTERS.each do |klass_name|
  next unless Object.const_defined?(klass_name)
  klass = Object.const_get(klass_name)
  
  klass.class_eval do
    def commands_override=(value)
      @commands_override = value
      @needs_id_refresh = true
    end

    # Alias del método original
    unless method_defined?(:commands_original_for_search)
      alias_method :commands_original_for_search, :commands
    end

    def commands
      if @commands_override
        if @needs_id_refresh
          new_ids = []
          new_maps = []

          # Obtenemos la lista completa original
          original_cmds = commands_original_for_search
          original_offset = (defined?(@addGlobalOffset)) ? @addGlobalOffset : 0
          
          # Reconstruimos los IDs basándonos en el índice original
          @commands_override.each do |cmd| 
            original_index = original_cmds.index(cmd)
            if original_index
              if defined?(@ids) && @ids
                  new_ids.push(@ids[original_index]) 
              end
            if defined?(@maps) && @maps
                # Calculamos el índice real en el array @maps original
                map_real_index = original_index - original_offset
                if map_real_index >= 0 && map_real_index < @maps.length
                  new_maps.push(@maps[map_real_index])
                end
              end
            end
          end
            
          if defined?(@ids) && @ids
              @ids = new_ids
          end
          if defined?(@maps) && @maps
            @maps = new_maps
            @addGlobalOffset = 0 if defined?(@addGlobalOffset)
          end
          @needs_id_refresh = false
        end
        return @commands_override 
      end
      return commands_original_for_search
    end
  end
end