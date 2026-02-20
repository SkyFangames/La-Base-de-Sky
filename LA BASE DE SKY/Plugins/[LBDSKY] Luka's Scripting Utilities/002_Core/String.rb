#===============================================================================
#  Luka's Scripting Utilities
#
#  Core extensions for the `String` class
#===============================================================================
class ::String
  # Turns string into an actual Ruby object
  # @return [Object]
  def constantize
    Object.const_get(self)
  end

  # Turns string into an actual Ruby object if exists
  # @return [Object]
  def safe_constantize
    Object.const_get(self) if Object.const_defined?(self)
  end

  # @return [String] capitalized first letter
  def capitalize
    sub(/^\w/) { ::Regexp.last_match(0).upcase }
  end

  # @return [String] to camel case
  def camelize
    downcase.split('_').map(&:capitalize).join('')
  end

  # @return [String] to snake case
  def underscore
    return downcase if match(/\A[A-Z]+\z/)

    gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').gsub(/([a-z])([A-Z])/, '\1_\2').tr('-', '_').downcase
  end

  # @return [String] without leading module names
  def demodulize
    split('::').last
  end

  # @return [Boolean]
  def blank?
    eql?('') || chars.all? { |c| c.eql?(' ') }
  end

  # @return [Boolean]
  def present?
    !blank?
  end

  # @return [String]
  def preposition
    first = chars.first&.downcase
    return 'a' unless first
    return 'an' if ['a', 'e', 'i', 'o', 'u'].any? { |char| first.eql?(char) }

    'a'
  end

  # Tag string with color values
  # @return [String]
  def red
    "#{shadowctag(Color.new(232, 32, 16), Color.new(248, 168, 184))}#{self}</c2>"
  end

  # @return [String]
  def green
    "#{shadowctag(Color.new(96, 176, 72), Color.new(174, 208, 144))}#{self}</c2>"
  end

  # @return [String]
  def blue
    "#{shadowctag(Color.new(0, 112, 248), Color.new(120, 184, 232))}#{self}</c2>"
  end

  # @return [String]
  def cyan
    "#{shadowctag(Color.new(72, 216, 216), Color.new(168, 224, 224))}#{self}</c2>"
  end

  # @return [String]
  def magenta
    "#{shadowctag(Color.new(208, 56, 184), Color.new(232, 160, 224))}#{self}</c2>"
  end

  # @return [String]
  def yellow
    "#{shadowctag(Color.new(232, 208, 32), Color.new(248, 232, 136))}#{self}</c2>"
  end

  # @return [String]
  def purple
    "#{shadowctag(Color.new(114, 64, 232), Color.new(184, 168, 224))}#{self}</c2>"
  end

  # @return [String]
  def orange
    "#{shadowctag(Color.new(248, 152, 24), Color.new(248, 200, 152))}#{self}</c2>"
  end
end
