# The pbs_order value determines the order in which the stats are written in
# several PBS files, where base stats/IVs/EVs/EV yields are defined. Only stats
# which are yielded by the "each_main" method can have stat numbers defined in
# those places. The values of pbs_order defined below should start with 0 and
# increase without skipping any numbers.
module GameData
  class Stat
    attr_reader :id
    attr_reader :real_name
    attr_reader :real_name_brief
    attr_reader :type
    attr_reader :pbs_order

    DATA = {}

    extend ClassMethodsSymbols
    include InstanceMethods

    def self.load; end
    def self.save; end

    # These stats are defined in PBS files, and should have the :pbs_order
    # property.
    def self.each_main
      self.each { |s| yield s if [:main, :main_battle].include?(s.type) }
    end

    def self.each_main_battle
      self.each { |s| yield s if [:main_battle].include?(s.type) }
    end

    # These stats have associated stat stages in battle.
    def self.each_battle
      self.each { |s| yield s if [:main_battle, :battle].include?(s.type) }
    end

    def initialize(hash)
      @id              = hash[:id]
      @real_name       = hash[:name]       || "Sin nombre"
      @real_name_brief = hash[:name_brief] || "Ninguno"
      @type            = hash[:type]       || :none
      @pbs_order       = hash[:pbs_order]  || -1
    end

    # @return [String] the translated name of this stat
    def name
      return _INTL(@real_name)
    end

    # @return [String] the translated brief name of this stat
    def name_brief
      return _INTL(@real_name_brief)
    end
  end
end

#===============================================================================

GameData::Stat.register({
  :id         => :HP,
  :name       => _INTL("PS"),
  :name_brief => _INTL("PS"),
  :type       => :main,
  :pbs_order  => 0
})

GameData::Stat.register({
  :id         => :ATTACK,
  :name       => _INTL("Ataque"),
  :name_brief => _INTL("At"),
  :type       => :main_battle,
  :pbs_order  => 1
})

GameData::Stat.register({
  :id         => :DEFENSE,
  :name       => _INTL("Defensa"),
  :name_brief => _INTL("Def"),
  :type       => :main_battle,
  :pbs_order  => 2
})

GameData::Stat.register({
  :id         => :SPECIAL_ATTACK,
  :name       => _INTL("Ataque Especial"),
  :name_brief => _INTL("AtEsp"),
  :type       => :main_battle,
  :pbs_order  => 4
})

GameData::Stat.register({
  :id         => :SPECIAL_DEFENSE,
  :name       => _INTL("Defensa Especial"),
  :name_brief => _INTL("DefEsp"),
  :type       => :main_battle,
  :pbs_order  => 5
})

GameData::Stat.register({
  :id         => :SPEED,
  :name       => _INTL("Velocidad"),
  :name_brief => _INTL("Vel"),
  :type       => :main_battle,
  :pbs_order  => 3
})

GameData::Stat.register({
  :id         => :ACCURACY,
  :name       => _INTL("Precisión"),
  :name_brief => _INTL("Pre"),
  :type       => :battle
})

GameData::Stat.register({
  :id         => :EVASION,
  :name       => _INTL("Evasión"),
  :name_brief => _INTL("Eva"),
  :type       => :battle
})

