#===============================================================================
#  Extensions for the `PluginManager`
#===============================================================================
module ::PluginManager
  class << self
    #---------------------------------------------------------------------------
    #  get plugin dir based on meta entries
    #---------------------------------------------------------------------------
    def self.find_dir(plugin)
      # go through the plugins folder
      Dir.get('Plugins').each do |dir|
        next unless Dir.safe?(dir) || safeExists?(dir + '/meta.txt')

        # read meta
        meta = readMeta(dir, 'meta.txt')
        return dir if meta[:name] == plugin
      end

      # return nil if no plugin dir found
      nil
    end
    #---------------------------------------------------------------------------
  end
end
