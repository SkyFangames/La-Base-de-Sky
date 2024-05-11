#===============================================================================
# Pokedex page handlers. You may use the following keys in each hash:
#-------------------------------------------------------------------------------
# "name"      => A string used to identify this page. (Required)
# "suffix"    => The suffix for this page's icon/background sprites. (Required)
# "order"     => The order this page appears relative to the other pages. (Required)
# "onlyOwned" => When true, this page is only viewable for owned species. (Optional)
# "condition" => A proc that will hide this page unless certain conditions are met. (Optional)
# "plugin"    => An array containing a plugin name and a boolean to determine if this
#                page should be viewable if a certain plugin is installed or not. (Optional)
# "layout"    => The script that is triggered to draw this page. (Required)
#===============================================================================


#-------------------------------------------------------------------------------
# Pokedex page handlers.
#-------------------------------------------------------------------------------

# Info page.
UIHandlers.add(:pokedex, :page_info, { 
  "name"      => "INFO",
  "suffix"    => "info",
  "order"     => 10,
  "layout"    => proc { |species, scene| scene.drawPageInfo }
})

# Area page.
UIHandlers.add(:pokedex, :page_area, { 
  "name"      => "AREA",
  "suffix"    => "area",
  "order"     => 20,
  "layout"    => proc { |species, scene| scene.drawPageArea }
})

# Forms page.
UIHandlers.add(:pokedex, :page_forms, { 
  "name"      => "FORMS",
  "suffix"    => "forms",
  "order"     => 30,
  "layout"    => proc { |species, scene| scene.drawPageForms }
})