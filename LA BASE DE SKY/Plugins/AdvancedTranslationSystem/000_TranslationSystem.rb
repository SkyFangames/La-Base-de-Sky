#===============================================================================
# Advanced Translation System - Core
# Loads translations from CSV and provides language detection/selection.
#
# CSV Format: TEXT;LANG1;LANG2;...
# - TEXT column is the lookup key (case-sensitive, matches _INTL strings)
# - Remaining columns are language translations (e.g. ES, EN, FR, DE...)
# - Languages are read dynamically from the header
# - If OS language doesn't match any column, the first language is used
#===============================================================================

module TranslationSystem
  TRANSLATIONS_CSV_PATH = "Plugins/AdvancedTranslationSystem/translations.csv"
  DIALOGUES_CSV_PATH = "Plugins/AdvancedTranslationSystem/dialogues.csv"

  @@translations = {}
  @@languages = []
  @@current_language = nil
  @@cached_system_language = nil

  #-----------------------------------------------------------------------------
  # Converts CSV escape sequences (literal \n, \t, etc.) into actual characters.
  #-----------------------------------------------------------------------------
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

  #-----------------------------------------------------------------------------
  # Loads translations from CSV. Called once, then cached.
  #-----------------------------------------------------------------------------
  def self.load_translations
    return if @@translations && !@@translations.empty?

    csv_path = TRANSLATIONS_CSV_PATH
    return if !File.file?(csv_path)

    begin
      lines = File.readlines(csv_path, encoding: 'BOM|UTF-8')
      return if lines.empty?

      header = lines[0].strip.split(';').map { |h| h.strip }

      if header.length < 2 || header[0] != "TEXT"
        puts "ERROR: Invalid CSV format. Expected 'TEXT;LANG1;LANG2;...' but got '#{header.join(';')}'"
        return
      end

      # Language columns are everything after TEXT
      @@languages = header[1..-1]

      lines[1..-1].each do |line|
        next if line.strip.empty?
        line = line.encode('UTF-8', 'UTF-8', invalid: :replace, undef: :replace, replace: '')

        # Use chomp to preserve significant leading/trailing spaces in fields
        fields = line.chomp.split(';', header.length)
        next if fields[0].nil? || fields[0].strip.empty?

        text_key = unescape_string(fields[0])

        @@translations[text_key] = {}
        @@languages.each_with_index do |lang, i|
          text = unescape_string(fields[i + 1].to_s)
          @@translations[text_key][lang] = text
        end
      end

      puts "Loaded #{@@translations.length} translations in #{@@languages.length} languages: #{@@languages.join(', ')}"
    rescue => e
      puts "ERROR loading translations: #{e.message}"
      puts e.backtrace.first(3).join("\n")
    end
  end

  #-----------------------------------------------------------------------------
  # Returns the translated text for the given key in the current language.
  # Falls back to the first language, then to the raw key.
  #-----------------------------------------------------------------------------
  def self.get(id, *args)
    load_translations if @@translations.empty?

    translation = @@translations[id]
    return id if !translation

    lang = current_language
    text = translation[lang] || translation[@@languages[0]] || id

    args.each_with_index do |arg, i|
      text = text.gsub("{#{i + 1}}", arg.to_s)
    end

    return text
  end

  #-----------------------------------------------------------------------------
  # Returns the active language code. Resolves from $PokemonSystem setting,
  # falling back to OS detection.
  #-----------------------------------------------------------------------------
  def self.current_language
    return @@current_language if @@current_language

    load_translations if @@languages.empty?

    if defined?($PokemonSystem) && $PokemonSystem.respond_to?(:dialogue_language)
      if $PokemonSystem.dialogue_language && $PokemonSystem.dialogue_language >= 0
        @@current_language = @@languages[$PokemonSystem.dialogue_language] if $PokemonSystem.dialogue_language < @@languages.length
        return @@current_language if @@current_language
      elsif $PokemonSystem.dialogue_language && $PokemonSystem.dialogue_language < 0
        @@current_language = system_default_language
        return @@current_language
      end
    end

    @@current_language = system_default_language
    return @@current_language
  end

  def self.set_language(lang_code)
    @@current_language = lang_code
  end

  # Forces current_language to be re-evaluated on next access.
  def self.reset_current_language
    @@current_language = nil
  end

  def self.available_languages
    load_translations if @@languages.empty?
    return @@languages
  end

  #-----------------------------------------------------------------------------
  # Detects OS language and caches the result. If the OS language isn't among
  # the available CSV languages, returns the first language column.
  #-----------------------------------------------------------------------------
  def self.system_default_language
    return @@cached_system_language if @@cached_system_language
    load_translations if @@languages.empty?
    @@cached_system_language = detect_os_language
    return @@cached_system_language
  end

  def self.default_language
    load_translations if @@languages.empty?
    return @@languages[0] || "EN"
  end

  private

  def self.detect_os_language
    begin
      if System.is_really_windows?
        locale = `powershell -Command "[System.Globalization.CultureInfo]::CurrentUICulture.TwoLetterISOLanguageName"`.strip.upcase
        return locale if !locale.empty? && @@languages.include?(locale)
      end

      lang_env = ENV['LANG'] || ENV['LANGUAGE'] || ENV['LC_ALL'] || ENV['LC_MESSAGES']
      if lang_env
        lang_code = lang_env[0..1].upcase
        return lang_code if @@languages.include?(lang_code)
      end
    rescue => e
      puts "Could not detect OS language: #{e.message}"
    end

    return @@languages[0] if !@@languages.empty?
    return "EN"
  end
end

#===============================================================================
# Global helper — safe wrapper around TranslationSystem.get
#===============================================================================
def pbTranslate(id, *args)
  begin
    TranslationSystem.get(id, *args)
  rescue => e
    puts "Translation error for '#{id}': #{e.message}"
    return id.to_s
  end
end

#===============================================================================
# Preload translations as early as possible
#===============================================================================
EventHandlers.add(:on_game_start, :load_translations,
  proc {
    TranslationSystem.load_translations
    TranslationSystem.system_default_language
  }
)

# Also load at plugin init time (runs before on_game_start)
if defined?(PluginManager)
  TranslationSystem.load_translations
  TranslationSystem.system_default_language
  puts "[Translation] System language detected: #{TranslationSystem.system_default_language}" if $DEBUG
end
