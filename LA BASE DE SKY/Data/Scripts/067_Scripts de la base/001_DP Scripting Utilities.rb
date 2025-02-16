$:.push File.join(Dir.pwd, "Ruby Library 3.3.0")

def json_remove_comments(json_str)
  json_str.gsub(/\/\/.*$/, '').gsub(/\/\*.*?\*\//m, '')
end

# Helper function to remove accents from a string using Unicode normalization
def remove_accents(str)
  str.unicode_normalize(:nfd).gsub(/[^\u0000-\u007F]/, '') # Remove non-ASCII characters after normalization
end
  
# Natural sort comparison method
def natural_sort_key(str)
  # Remove accents, non-alphanumeric characters, and split into chunks of numbers and non-numbers
  remove_accents(str.downcase).gsub(/[^a-z0-9]/, '').scan(/\d+|\D+/).map { |chunk| chunk.match?(/\d/) ? chunk.to_i : chunk }
end
