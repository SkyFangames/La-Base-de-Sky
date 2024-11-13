#===============================================================================
# UI module
#===============================================================================
module UIHandlers
  @@handlers = {}

  def self.add(ui, option, hash)
    @@handlers[ui] = HandlerHash.new if !@@handlers.has_key?(ui)
    @@handlers[ui].add(option, hash)
  end

  def self.remove(ui, option)
    @@handlers[ui]&.remove(option)
  end

  def self.clear(ui)
    @@handlers[ui]&.clear
  end

  def self.each(ui)
    return if !@@handlers.has_key?(ui)
    @@handlers[ui].each { |option, hash| yield option, hash }
  end

  def self.each_available(ui, *args)
    return if !@@handlers.has_key?(ui)
    options = @@handlers[ui]
    keys = options.keys
    sorted_keys = keys.sort_by { |option| options[option]["order"] || keys.index(option) }
    sorted_keys.each do |option|
      hash = options[option]
      if hash["plugin"]
        next if PluginManager.installed?(hash["plugin"][0]) && !hash["plugin"][1]
        next if !PluginManager.installed?(hash["plugin"][0]) && hash["plugin"][1]
      end
      next if hash["condition"] && !hash["condition"].call(*args)
      if hash["name"].is_a?(Proc)
        name = hash["name"].call
      else
        name = _INTL(hash["name"])
      end
      icon = _INTL(hash["suffix"])
      menu = hash["options"] || []
      yield option, hash, name, icon, menu
    end
  end

  def self.call(menu, option, function, *args)
    option_hash = @@handlers[menu][option]
    return nil if !option_hash || !option_hash[function]
    return option_hash[function].call(*args)
  end
  
  def self.get_info(menu, option, type = nil)
    option_hash = @@handlers[menu][option]
    return nil if !option_hash
    case type
    when :name    then return _INTL(option_hash["name"])
    when :suffix  then return _INTL(option_hash["suffix"])
    when :options then return option_hash["options"] || []
    end
    return _INTL(option_hash["name"]), _INTL(option_hash["suffix"]), option_hash["options"]
  end

  def self.edit_hash(menu, page, field, new_data)
    hash = @@handlers[menu][page]
    if hash
      old_data = hash[field]
      if old_data != new_data
        hash[field] = new_data
      end
    end
  end
end


#===============================================================================
# Plugin manager.
#===============================================================================
module PluginManager
  PluginManager.singleton_class.alias_method :mui_register, :register
  def self.register(options)
    mui_register(options)
    self.plugin_check_MUI
  end
  
  #-----------------------------------------------------------------------------
  # Used to ensure all plugins that rely on Modular UI Scenes are up to date.
  #-----------------------------------------------------------------------------
  def self.plugin_check_MUI(version = "2.0.8")
    if self.installed?("Modular UI Scenes", version, true)
      {"[MUI] Enhanced Pokemon UI"   => "1.0.6",
       "[MUI] Pokedex Data Page"     => "2.0.1",
       "[MUI] Improved Mementos"     => "1.0.3",
       "[MUI] Improved Field Skills" => "1.0.1",
      }.each do |p_name, v_num|
        next if !self.installed?(p_name)
        p_ver = self.version(p_name)
        valid = self.compare_versions(p_ver, v_num)
        next if valid > -1
        link = self.link(p_name)
        self.error("Plugin '#{p_name}' is out of date.\nPlease download the latest version at:\n#{link}")
      end
    end
  end
end