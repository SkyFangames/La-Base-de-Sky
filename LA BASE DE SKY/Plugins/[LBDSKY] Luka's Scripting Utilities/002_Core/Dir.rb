#===============================================================================
#  Luka's Scripting Utilities
#
#  Core extensions for the `Dir` class
#===============================================================================
class ::Dir
  class << self
    # Creates all the required directories for filename path
    # @param path [String]
    def create(path)
      return if path.nil? || path.empty?
      full = ''
      path_gsub = path.gsub!('\\', '/')
      if path_gsub.nil? 
        mkdir(path) unless safe?(path)
      else
        path_gsub.split('/').each do |dir|
          full << dir + '/'

          # creates directories
          mkdir(full) unless safe?(full)
        end
      end
    end

    # Generates entire file/folder tree from a certain directory
    # @param path [String]
    def all_dirs(path)
      # sets variables for starting
      dirs = [].tap do |dir_array|
        get(path, '*', true).each do |file|
          # engages in recursion to read the entire folder tree
          dir_array << all_dirs(file) if safe?(file)
        end
      end
      # returns all found directories
      dirs.empty? ? [path] : (dirs + [path])
    end

    # Deletes all the files in a directory and all the sub directories (allows for non-empty dirs)
    # @param path [String]
    def delete_all(path)
      # delete all files in dir
      all(path).each { |f| File.delete(f) }

      # delete all dirs in dir
      all_dirs(path).each { |f| Dir.delete(f) }
    end
  end
end
