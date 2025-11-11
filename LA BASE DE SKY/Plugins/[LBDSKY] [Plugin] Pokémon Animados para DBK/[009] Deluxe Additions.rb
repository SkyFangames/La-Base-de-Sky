#===============================================================================
# Global midbattle script for species-specific animations.
#===============================================================================
MidbattleHandlers.add(:midbattle_global, :sprite_animations,
  proc { |battle, idxBattler, idxTarget, trigger|
    next if $PokemonSystem.animated_sprites > 0
    battler = battle.battlers[idxBattler]
    next if !battler || battler.fainted?
    case trigger
      when "TargetWeakToMove_WATER"
      if battler.isSpecies?(:SUDOWOODO)
        next if battler.effects[PBEffects::Transform] || battler.effects[PBEffects::Illusion]
        next if [:SLEEP, :FROZEN].include?(battler.status)
        sprite = battler.battlerSprite
        next if sprite.substitute || sprite.vanishMode > 0
        if sprite.speed == 0
          sprite.speed = 1 
          sprite.fullRefresh
          battle.scene.pbPauseScene
          sprite.speed = 0
          sprite.deanimate
          sprite.fullRefresh
        end
      end
    when "AfterMove_SHIFTGEAR"
      if battler.isSpecies?(:KLINK) || battler.isSpecies?(:KLANG) || battler.isSpecies?(:KLINKLANG)
        next if battler.effects[PBEffects::Transform] || battler.effects[PBEffects::Illusion]
        sprite = battler.battlerSprite
        sprite.reversed = !sprite.reversed?
      end
    end
  }
)

#===============================================================================
# Forces a sprite to animate at a desired speed.
#===============================================================================
MidbattleHandlers.add(:midbattle_triggers, "spriteSpeed",
  proc { |battle, idxBattler, idxTarget, params|
    next if $PokemonSystem.animated_sprites > 0
    battler = battle.battlers[idxBattler]
    next if !battler || battler.fainted?
    sprite = battler.battlerSprite
    next if sprite.substitute || sprite.vanishMode > 0
    params = 0 if params < 0
    params = 4 if params > 4
    sprite.speed = params
    sprite.fullRefresh
    PBDebug.log("     'spriteSpeed': setting sprite animation speed for #{battler.name} (#{battler.index})")
  }
)

#===============================================================================
# Forces a sprite to reverse its animation.
#===============================================================================
MidbattleHandlers.add(:midbattle_triggers, "spriteReverse",
  proc { |battle, idxBattler, idxTarget, params|
    next if $PokemonSystem.animated_sprites > 0
    battler = battle.battlers[idxBattler]
    next if !battler || battler.fainted?
    sprite = battler.battlerSprite
    next if sprite.substitute || sprite.vanishMode > 0
    sprite.reversed = params
    sprite.fullRefresh
    PBDebug.log("     'spriteReverse': reversing sprite animation for #{battler.name} (#{battler.index})")
  }
)

#===============================================================================
# Manually sets a sprite's hue.
#===============================================================================
MidbattleHandlers.add(:midbattle_triggers, "spriteHue",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler || battler.fainted?
    sprite = battler.battlerSprite
    next if sprite.substitute || sprite.vanishMode > 0
    sprite.hue = params
    PBDebug.log("     'spriteHue': setting sprite hue for #{battler.name} (#{battler.index})")
  }
)