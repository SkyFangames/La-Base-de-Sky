#!/usr/bin/env ruby
# encoding: utf-8
#===============================================================================
# Find Missing Translations
#
# Scans two sources for translatable strings:
#   1. All .rb files under Plugins/ and Data/Scripts/ for _INTL() calls
#   2. All map .rxdata files under Data/ for Show Text and Show Choices events
#
# Compares found strings against the TEXT column in translations.csv and
# outputs any missing entries to missing_translations.csv.
#
# Run from the project root:
#   ruby Plugins/AdvancedTranslationSystem/find_missing_translations.rb
#===============================================================================

if __FILE__ == $0  # Only run when executed directly, not when loaded by the game

require 'set'

SCRIPTS_PATHS = ["Plugins", "Data/Scripts"]
MAPS_PATH     = "Data"
CSV_PATH      = "Plugins/AdvancedTranslationSystem/translations.csv"
OUTPUT_PATH   = "Plugins/AdvancedTranslationSystem/missing_translations.csv"

# Converts CSV escape sequences into actual characters so they match
# what Ruby evaluates at runtime (e.g. literal \n -> newline).
def unescape(str)
  return str if str.nil?
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

# Escapes special characters for CSV output (keeps text on a single line).
def escape_for_csv(str)
  return str if str.nil?
  result = str.dup
  result.gsub!('\\', '\\\\\\\\')  # \ -> \\
  result.gsub!(';', '\\;')        # ; -> \;
  result.gsub!("\n", '\\n')       # newline -> \n
  result.gsub!("\t", '\\t')       # tab -> \t
  result.gsub!("\r", '\\r')       # cr -> \r
  result
end

#===============================================================================
# Stub classes so Marshal can deserialize RPG Maker XP map files
#===============================================================================
module RPG
  class Map; end
  class Event
    class Page
      class Condition; end
      class Graphic; end
    end
  end
  class EventCommand; end
  class AudioFile; end
  class MoveRoute; end
  class MoveCommand; end
end
class Table;  def self._load(_data); new(0); end; end
class Tone;   def self._load(_data); new(0,0,0,0); end; end
class Color;  def self._load(_data); new(0,0,0,0); end; end

puts "=" * 80
puts "FINDING MISSING TRANSLATIONS"
puts "=" * 80
puts ""

#-----------------------------------------------------------------------
# Step 1: Load existing TEXT keys from translations.csv
#-----------------------------------------------------------------------
existing_translations = Set.new

if File.exist?(CSV_PATH)
  puts "[1/4] Loading existing translations from CSV..."
  lines = File.readlines(CSV_PATH, encoding: 'BOM|UTF-8')

  header = lines[0].strip.split(';').map(&:strip)

  if header[0] != "TEXT"
    puts "   ERROR: Invalid CSV format. Expected 'TEXT;LANG1;LANG2;...' but got '#{header.join(';')}'"
    exit(1)
  end

  lines[1..-1].each do |line|
    next if line.strip.empty?
    line = line.chomp
    parts = line.split(';', 2)
    text_key = parts[0]  # Preserve leading/trailing spaces
    text_key = unescape(text_key) if text_key
    existing_translations.add(text_key) if text_key && !text_key.empty?
  end

  puts "   Found #{existing_translations.size} existing translations"
else
  puts "[1/4] CSV not found - will find ALL translations"
end

#-----------------------------------------------------------------------
# Step 2: Scan .rb files for _INTL() calls
#-----------------------------------------------------------------------
puts ""
puts "[2/4] Scanning script files for _INTL() calls..."

found_texts = {}  # unescaped_text => { original: escaped_text, locations: [...] }
file_count = 0

INTL_REGEX = /_INTL\s*\(\s*(?:"((?:[^"\\]|\\.)*)"|'((?:[^'\\]|\\.)*)')/m

SCRIPTS_PATHS.each do |scripts_path|
  next unless Dir.exist?(scripts_path)
  puts "   Scanning: #{scripts_path}/"

  Dir.glob("#{scripts_path}/**/*.rb").each do |file|
    file_count += 1
    content = File.read(file, encoding: 'UTF-8')

    match_pos = 0
    while match_data = content.match(INTL_REGEX, match_pos)
      original_text = match_data[1] || match_data[2]
      match_pos = match_data.end(0)

      next if original_text.nil? || original_text.empty?

      begin
        unescaped_text = unescape(original_text)
        next if unescaped_text.empty?

        line_num = content[0...match_data.begin(0)].count("\n") + 1
        location = "#{File.basename(file)}:#{line_num}"

        found_texts[unescaped_text] ||= { original: original_text, locations: [] }
        found_texts[unescaped_text][:locations] << location unless found_texts[unescaped_text][:locations].include?(location)
      rescue
        next
      end
    end
  end
end

puts "   Scanned #{file_count} files"
puts "   Found #{found_texts.size} unique _INTL() strings"

#-----------------------------------------------------------------------
# Step 3: Scan map .rxdata files for event texts
#-----------------------------------------------------------------------
puts ""
puts "[3/4] Scanning map events for Show Text / Show Choices..."

event_texts = {}  # text => { original: text, locations: [...] }
map_count = 0
map_errors = 0

Dir.glob("#{MAPS_PATH}/Map[0-9]*.rxdata").sort.each do |map_file|
  begin
    data = Marshal.load(File.binread(map_file))
    events = data.instance_variable_get(:@events)
    next if !events

    map_name = File.basename(map_file, '.rxdata')
    map_count += 1

    events.each do |event_id, event|
      pages = event.instance_variable_get(:@pages)
      next if !pages

      pages.each_with_index do |page, page_idx|
        list = page.instance_variable_get(:@list)
        next if !list

        i = 0
        while i < list.length
          cmd = list[i]
          code = cmd.instance_variable_get(:@code)
          params = cmd.instance_variable_get(:@parameters)

          if code == 101
            # Show Text: join with continuation lines (401), same as the interpreter
            message = params[0].to_s.force_encoding('UTF-8')
            j = i + 1
            while j < list.length
              next_cmd = list[j]
              next_code = next_cmd.instance_variable_get(:@code)
              break if next_code != 401
              next_text = next_cmd.instance_variable_get(:@parameters)[0].to_s.force_encoding('UTF-8')
              message += " " if next_text != "" && message[-1] != " "
              message += next_text
              j += 1
            end
            i = j

            # Skip empty or purely escape-code messages (e.g. "\e[...]")
            clean = message.gsub(/\\[a-zA-Z]+(\[[^\]]*\])?/, '').strip
            next if clean.empty?

            location = "#{map_name} Ev#{event_id} P#{page_idx}"
            event_texts[message] ||= { original: escape_for_csv(message), locations: [] }
            event_texts[message][:locations] << location unless event_texts[message][:locations].include?(location)

          elsif code == 102
            # Show Choices: each choice is a separate translatable string
            choices = params[0]
            if choices.is_a?(Array)
              choices.each do |choice_text|
                choice_text = choice_text.to_s.force_encoding('UTF-8')
                next if choice_text.strip.empty?

                location = "#{map_name} Ev#{event_id} P#{page_idx} (choice)"
                event_texts[choice_text] ||= { original: escape_for_csv(choice_text), locations: [] }
                event_texts[choice_text][:locations] << location unless event_texts[choice_text][:locations].include?(location)
              end
            end
            i += 1
          else
            i += 1
          end
        end
      end
    end
  rescue => e
    map_errors += 1
    # Skip files that can't be loaded (e.g. MapInfos.rxdata)
  end
end

puts "   Scanned #{map_count} maps" + (map_errors > 0 ? " (#{map_errors} skipped)" : "")
puts "   Found #{event_texts.size} unique event strings"

# Merge event texts into found_texts
event_texts.each do |text, data|
  if found_texts.key?(text)
    # Already found via _INTL, just add the event locations
    data[:locations].each do |loc|
      found_texts[text][:locations] << loc unless found_texts[text][:locations].include?(loc)
    end
  else
    found_texts[text] = data
  end
end

puts "   Total unique strings: #{found_texts.size}"

#-----------------------------------------------------------------------
# Step 4: Find missing translations
#-----------------------------------------------------------------------
puts ""
puts "[4/4] Comparing with CSV (case-sensitive)..."

missing = {}
found_texts.each do |unescaped_text, data|
  next if existing_translations.include?(unescaped_text)
  missing[unescaped_text] = data
end

puts ""
puts "=" * 80
puts "RESULTS"
puts "=" * 80
puts ""
puts "Total translatable strings: #{found_texts.size}"
puts "Already in CSV:             #{found_texts.size - missing.size}"
puts "MISSING from CSV:           #{missing.size}"
puts ""

if missing.empty?
  puts "All translations are already in your CSV!"
else
  puts "Found #{missing.size} missing translations"
  puts ""
  puts "Generating missing_translations.csv..."

  File.open(OUTPUT_PATH, 'w:UTF-8') do |f|
    f.puts "TEXT;ES;EN"
    missing.each do |unescaped_text, data|
      safe_text = data[:original].gsub(';', '\\;')
      f.puts "#{safe_text};;"
    end
  end

  puts ""
  puts "Created: #{OUTPUT_PATH}"
  puts ""
  puts "Next steps:"
  puts "1. Open missing_translations.csv"
  puts "2. Fill in the language columns"
  puts "3. Merge into translations.csv"
  puts ""
  puts "Preview (first 10):"
  puts "-" * 80

  missing.first(10).each do |unescaped_text, data|
    puts "\"#{data[:original]}\""
    puts "  Found in: #{data[:locations].first}"
    puts ""
  end

  if missing.size > 10
    puts "... and #{missing.size - 10} more (see missing_translations.csv)"
  end
end

puts ""
puts "=" * 80
puts "DONE"
puts "=" * 80

end # if __FILE__ == $0
