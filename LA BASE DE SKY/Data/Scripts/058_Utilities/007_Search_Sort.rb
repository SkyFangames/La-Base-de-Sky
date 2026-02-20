$:.push File.join(Dir.pwd, "Ruby Library 3.3.0")


# Define a mapping of accented characters to unaccented characters
ACCENTED_CHARACTERS = {
  'á' => 'a', 'Á' => 'A', 'à' => 'a', 'ä' => 'a', 'â' => 'a', 'ã' => 'a', 'å' => 'a', 
  'é' => 'e', 'É' => 'E', 'è' => 'e', 'ë' => 'e', 'ê' => 'e',
  'í' => 'i', 'Í' => 'I', 'ì' => 'i', 'ï' => 'i', 'î' => 'i',
  'ó' => 'o', 'Ó' => 'O', 'ò' => 'o', 'ö' => 'o', 'ô' => 'o', 'õ' => 'o',
  'ú' => 'u', 'Ú' => 'U', 'ù' => 'u', 'ü' => 'u', 'û' => 'u',
  'ç' => 'c'
}


############### Workaround para el ordenamiento en JoiPlay ###############
def remove_accents_joiplay(str)
  str.chars.map { |char| ACCENTED_CHARACTERS[char] || char }.join
end

# Natural sort comparison method 
def natural_sort_key_joiplay(str)
  # Remove accents and non-alphanumeric characters, and split into chunks of numbers and non-numbers
  str = remove_accents_joiplay(str).downcase
  remove_accents_joiplay(str).gsub(/[^a-z0-9]/, '').scan(/\d+|\D+/).map { |chunk| chunk =~ /\d/ ? chunk.to_i : chunk }
end
############### Workaround para el ordenamiento en JoiPlay ###############


def json_remove_comments(json_str)
  json_str.gsub(/\/\/.*$/, '').gsub(/\/\*.*?\*\//m, '')
end

# Helper function to remove accents from a string using Unicode normalization
def remove_accents(str)
  return remove_accents_joiplay(str) if $joiplay
  str.unicode_normalize(:nfd).gsub(/[^\u0000-\u007F]/, '') # Remove non-ASCII characters after normalization
end
  
# Natural sort comparison method
def natural_sort_key(str)
  return natural_sort_key_joiplay(str) if $joiplay
  # Remove accents, non-alphanumeric characters, and split into chunks of numbers and non-numbers
  remove_accents(str.downcase).gsub(/[^a-z0-9]/, '').scan(/\d+|\D+/).map { |chunk| chunk.match?(/\d/) ? chunk.to_i : chunk }
end
