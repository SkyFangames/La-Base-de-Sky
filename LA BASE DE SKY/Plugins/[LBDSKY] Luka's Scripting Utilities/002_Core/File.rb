#===============================================================================
#  Luka's Scripting Utilities
#
#  Core extensions for the `File` class
#===============================================================================
class ::File
  class << self
    # @return [Boolean] safely checks for existing .rxdata file
    def safe_data?(file)
      load_data(file) ? true : false
    rescue StandardError
      false
    end
  end
end
