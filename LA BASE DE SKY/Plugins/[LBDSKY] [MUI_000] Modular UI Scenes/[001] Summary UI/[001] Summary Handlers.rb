#===============================================================================
# Summary page handlers. You may use the following keys in each hash:
#-------------------------------------------------------------------------------
# "name"      => A string used as the header for this page. (Required)
# "suffix"    => The suffix for this page's icon/background sprites. (Required)
# "order"     => The order this page appears relative to the other pages. (Required)
# "onlyEggs"  => When true, this page is only viewable for Eggs. (Optional)
# "condition" => A proc that will hide this page unless certain conditions are met. (Optional)
# "plugin"    => An array containing a plugin name and a boolean to determine if this
#                page should be viewable if a certain plugin is installed or not. (Optional)
# "options"   => An array of commands that appear in the Options menu while on this page.
#                This may be omitted if the USE key has a different use on this page. (Optional)
#                These are the symbols used for each menu command:
#                   :item     => You may equip/remove held items on this page.
#                   :nickname => You may nickname the Pokemon on this page. (Gen 9+ only)
#                   :pokedex  => You may view the dex entry for this species on this page.  
#                   :moves    => You may look at move details on this page. (Gen 9+ only)
#                   :remember => You may relearn past moves on this page. (Gen 9+ only)
#                   :forget   => You may forget a known move on this page. (Gen 9+ only)
#                   :tms      => You may directly use a TM from the bag on this page. (Gen 9+ only)
#                   :mark     => You may place marks on the Pokemon on this page.
# "layout"    => The script that is triggered to draw this page. (Required)
#===============================================================================


#-------------------------------------------------------------------------------
# Pokemon Summary handlers.
#-------------------------------------------------------------------------------

# Info page.
UIHandlers.add(:summary, :page_info, { 
  "name"      => "INFORMACIÓN",
  "suffix"    => "info",
  "order"     => 10,
  "options"   => [:item, :nickname, :pokedex, :mark, :legacy],
  "layout"    => proc { |pkmn, scene| scene.drawPageOne }
})

# Memo page.
UIHandlers.add(:summary, :page_memo, {
  "name"      => "NOTAS ENTREN.",
  "suffix"    => "memo",
  "order"     => 20,
  "options"   => [:item, :nickname, :pokedex, :mark, :legacy],
  "layout"    => proc { |pkmn, scene| scene.drawPageTwo }
})

# Stat page.
UIHandlers.add(:summary, :page_skills, {
  "name"      => "ESTADÍSTICAS",
  "suffix"    => "skills",
  "order"     => 30,
  "options"   => [:item, :nickname, :pokedex, :mark],
  "layout"    => proc { |pkmn, scene| scene.drawPageThree }
})

# Moves page.
UIHandlers.add(:summary, :page_moves, {
  "name"      => "MOVIMIENTOS",
  "suffix"    => "moves",
  "order"     => 40,
  "options"   => [:moves, :remember, :forget, :tms],
  "layout"    => proc { |pkmn, scene| scene.drawPageFour }
})

# Ribbons page.
UIHandlers.add(:summary, :page_ribbons, {
  "name"      => "CINTAS",
  "suffix"    => "ribbons",
  "order"     => 50,
  "layout"    => proc { |pkmn, scene| scene.drawPageFive }
})

#-------------------------------------------------------------------------------
# Egg Summary handlers.
#-------------------------------------------------------------------------------

# Info page.
UIHandlers.add(:summary, :page_egg, {
  "name"      => "NOTAS ENTREN.",
  "suffix"    => "egg",
  "order"     => 10,
  "onlyEggs"  => true,
  "options"   => [:mark],
  "layout"    => proc { |pkmn, scene| scene.drawPageOneEgg }
})
