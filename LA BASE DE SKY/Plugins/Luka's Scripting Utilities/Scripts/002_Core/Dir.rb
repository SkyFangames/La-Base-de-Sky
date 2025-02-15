#===============================================================================
#  Extensions for the `Dir` class
#===============================================================================
class ::Dir
  class << self
    #---------------------------------------------------------------------------
    #  creates all the required directories for filename path
    #---------------------------------------------------------------------------
    def create(path)
      full = ''

      path.gsub!('\\', '/').split('/').each do |dir|
        full << dir + '/'

        # creates directories
        mkdir(full) unless safe?(full)
      end
    end
    #---------------------------------------------------------------------------
    #  generates entire file/folder tree from a certain directory
    #---------------------------------------------------------------------------
    def all_dirs(dir)
      # sets variables for starting
      dirs = [].tap do |dir_array|
        get(dir, '*', true).each do |file|
          # engages in recursion to read the entire folder tree
          dir_array << all_dirs(file) if safe?(file)
        end
      end
      # returns all found directories
      dirs.empty? ? [dir] : (dirs + [dir])
    end
    #---------------------------------------------------------------------------
    #  deletes all the files in a directory and all the sub directories (allows for non-empty dirs)
    #---------------------------------------------------------------------------
    def delete_all(dir)
      # delete all files in dir
      all(dir).each { |f| File.delete(f) }

      # delete all dirs in dir
      all_dirs(dir).each { |f| Dir.delete(f) }
    end
    #---------------------------------------------------------------------------
  end
end
