#===============================================================================
# Pokemon Summary handlers.
#===============================================================================
UIHandlers.add(:summary, :page_allstats, { 
  "name"      => "ESTADÍSTICAS",
  "suffix"    => "allstats",
  "order"     => 35,
  "condition" => proc { next Settings::SHOW_ADVANCED_STATS },
  "layout"    => proc { |pkmn, scene| scene.drawPageAllStats }
})