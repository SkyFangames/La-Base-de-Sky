if Settings::RESTORE_HELD_ITEMS_AFTER_BATTLE
  class Battle::Battler
    alias pbConsumeItem_restore pbConsumeItem
    def pbConsumeItem(recoverable = true, symbiosis = true, belch = true)
      @battle.used_items << [self.pokemon, @item_id] if @battle.used_items && pbOwnedByPlayer?
      pbConsumeItem_restore(recoverable, symbiosis, belch)
    end
  end

  class Battle
    attr_accessor :used_items # Items used by Pokémon during battle

    alias initialize_restore initialize
    def initialize(scene, p1, p2, player, opponent)
      initialize_restore(scene, p1, p2, player, opponent)
      @used_items = []
    end

    def pbRestoreUsedItems
      @used_items.each do |obj|
        pokemon = obj[0]
        next if !pokemon || !pokemon.item.nil? || Settings::RESTORE_HELD_ITEMS_BLACKLIST.include?(obj[1])

        item = obj[1]
        pokemon.item = item
      end
    end

    alias pbEndOfBattle_restore pbEndOfBattle
    def pbEndOfBattle
      decision = pbEndOfBattle_restore
      pbRestoreUsedItems
      decision
    end
  end
end
