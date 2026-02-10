#===============================================================================
# _INTL and _MAPINTL Override
# Replaces the global _INTL and _MAPINTL functions so every string — both
# hardcoded in scripts and written in RPG Maker events — is looked up in
# translations.csv at runtime.
#
# CSV Format: TEXT;LANG1;LANG2;...
# - TEXT  = original string (case-sensitive key)
# - LANG* = translation columns (any language codes, read from header)
#
# The active language is determined by TranslationSystem.current_language.
# If a translation is missing for the active language, the first language
# column is used as fallback.
#===============================================================================

module AdvancedTranslation
  @@original_intl = nil
  @@translation_map = nil   # TEXT => { "LANG1" => str, "LANG2" => str, ... }
  @@lang_columns = []       # Language codes read from CSV header

  # Captures the original _INTL before we override it, so we can fall back.
  def self.setup_original_intl
    return if @@original_intl
    if defined?(Kernel.method(:_INTL))
      @@original_intl = Kernel.method(:_INTL)
    end
  end

  #---------------------------------------------------------------------------
  # Main entry point — called by the global _INTL override below.
  #---------------------------------------------------------------------------
  def self.intl(msgId, *params)
    build_translation_map if !@@translation_map

    if @@translation_map.has_key?(msgId)
      entry = @@translation_map[msgId]
      lang = TranslationSystem.current_language.to_s.upcase

      translated = entry[lang]
      translated = entry[@@lang_columns[0]] if translated.nil? || translated.empty?
      translated = msgId if translated.nil? || translated.empty?

      if params.length > 0
        text = translated.dup
        params.each_with_index do |param, i|
          text.gsub!("{#{i + 1}}", param.to_s)
        end
        return text
      end

      return translated
    end

    # Not in our CSV — delegate to original _INTL or do basic substitution
    if @@original_intl
      return @@original_intl.call(msgId, *params)
    end

    text = msgId.dup
    params.each_with_index do |param, i|
      text.gsub!("{#{i + 1}}", param.to_s)
    end
    return text
  end

  # Forces the CSV to be re-read on next _INTL call.
  def self.reset
    @@translation_map = nil
    @@lang_columns = []
  end

  private

  # Converts CSV escape sequences (literal \n, \t, etc.) into actual characters.
  def self.unescape_string(str)
    return str if str.nil? || str.empty?
    str.gsub(/\\(.)/) do |m|
      case $1
      when 'n' then "\n"
      when 't' then "\t"
      when 'r' then "\r"
      when '"' then '"'
      when "'" then "'"
      when '\\' then '\\'
      when ';' then ';'
      else m
      end
    end
  end

  #---------------------------------------------------------------------------
  # Reads translations.csv and populates @@translation_map.
  #---------------------------------------------------------------------------
  def self.build_translation_map
    @@translation_map = {}
    @@lang_columns = []

    csv_path = TranslationSystem::TRANSLATIONS_CSV_PATH
    if !File.file?(csv_path)
      puts "[Translation] WARNING: CSV not found at #{csv_path}"
      return
    end

    begin
      lines = File.readlines(csv_path, encoding: 'BOM|UTF-8')
      return if lines.empty?

      header = lines[0].strip.split(';').map(&:strip)

      if header[0] != "TEXT" || header.length < 2
        puts "[Translation] ERROR: Invalid CSV format. Expected 'TEXT;LANG1;LANG2;...', got '#{header.join(';')}'"
        return
      end

      @@lang_columns = header[1..-1]

      lines[1..-1].each do |line|
        next if line.strip.empty?

        # Use chomp to preserve significant leading/trailing spaces in fields
        parts = line.chomp.split(';', header.length)
        next if parts.length < 2

        text_key = parts[0]
        next if !text_key || text_key.strip.empty?
        text_key = unescape_string(text_key)

        entry = {}
        @@lang_columns.each_with_index do |lang_code, i|
          val = parts[i + 1]
          val = unescape_string(val) if val
          entry[lang_code] = (val && !val.strip.empty?) ? val : text_key
        end

        @@translation_map[text_key] = entry
      end

      puts "[Translation] Loaded #{@@translation_map.size} translations for #{@@lang_columns.join(', ')}" if $DEBUG
    rescue => e
      puts "[Translation] ERROR loading translations: #{e.message}"
      puts e.backtrace.first(5).join("\n") if $DEBUG
    end
  end
end

# Capture original _INTL, then replace it
AdvancedTranslation.setup_original_intl

def _INTL(*args)
  AdvancedTranslation.intl(*args)
end

# Override _MAPINTL so RPG Maker event texts (Show Text, Show Choices)
# are also translated through our CSV.
# The first argument is the map_id (ignored), the rest is text + params.
def _MAPINTL(_mapid, *args)
  AdvancedTranslation.intl(*args)
end
