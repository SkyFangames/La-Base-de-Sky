#!/usr/bin/env ruby
# encoding: utf-8
#===============================================================================
# Find Missing Translations
#
# Scans all .rb files under Plugins/ and Data/Scripts/ for _INTL("...")
# calls, compares them against the TEXT column in translations.csv, and
# outputs any missing entries to missing_translations.csv.
#
# Run from the project root:
#   ruby Plugins/AdvancedTranslationSystem/find_missing_translations.rb
#===============================================================================

require 'set'

SCRIPTS_PATHS = ["Plugins", "Data/Scripts"]
CSV_PATH = "Plugins/AdvancedTranslationSystem/translations.csv"
OUTPUT_PATH = "Plugins/AdvancedTranslationSystem/missing_translations.csv"

# Converts CSV escape sequences into actual characters so they match
# what Ruby evaluates at runtime (e.g. literal \n → newline).
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

puts "=" * 80
puts "FINDING MISSING TRANSLATIONS"
puts "=" * 80
puts ""

#-----------------------------------------------------------------------
# Step 1: Load existing TEXT keys from translations.csv
#-----------------------------------------------------------------------
existing_translations = Set.new

if File.exist?(CSV_PATH)
  puts "[1/3] Loading existing translations from CSV..."
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
    text_key = parts[0]  # Preserve leading/trailing spaces — they're significant
    text_key = unescape(text_key) if text_key
    existing_translations.add(text_key) if text_key && !text_key.empty?
  end

  puts "   Found #{existing_translations.size} existing translations"
else
  puts "[1/3] CSV not found — will find ALL translations"
end

#-----------------------------------------------------------------------
# Step 2: Scan .rb files for _INTL() calls
#-----------------------------------------------------------------------
puts ""
puts "[2/3] Scanning script files for _INTL() calls..."

found_texts = {}  # unescaped_text => { original: escaped_text, locations: [...] }
file_count = 0

# Regex: matches _INTL("...") and _INTL('...'), including escaped quotes
# and multi-line strings. Two capture groups: one for double-quoted, one
# for single-quoted.
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
# Step 3: Find missing translations
#-----------------------------------------------------------------------
puts ""
puts "[3/3] Comparing with CSV (case-sensitive)..."

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
puts "Total _INTL strings found: #{found_texts.size}"
puts "Already in CSV:            #{found_texts.size - missing.size}"
puts "MISSING from CSV:          #{missing.size}"
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
