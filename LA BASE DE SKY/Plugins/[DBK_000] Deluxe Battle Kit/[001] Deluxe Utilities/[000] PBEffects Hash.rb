#===============================================================================
# Stores and organizes the ID's of all relavent PBEffects.
#===============================================================================
# [:counter] contains effects which store a number which is counted to determine
# its value, such as the number of stacks or number of remaining turns.
# [:boolean] contains effects which are stored as either nil, true, or false.
# [:index] contains effects which store a battler index. Only relevant to
# battler effects.
#-------------------------------------------------------------------------------
$DELUXE_PBEFFECTS = {
  #-----------------------------------------------------------------------------
  # Effects that apply to the entire battlefield.
  #-----------------------------------------------------------------------------
  :field => {
    :counter => [
      :MudSportField,
      :WaterSportField,
      :Gravity,
      :MagicRoom, 
      :TrickRoom, 
      :WonderRoom,
      :FairyLock, 
      :PayDay
    ],
    :boolean => [
      :HappyHour,
      :IonDeluge
    ]
  },
  #-----------------------------------------------------------------------------
  # Effects that apply to one side of the field.
  #-----------------------------------------------------------------------------
  :team => {
    :counter => [
      :AuroraVeil,
      :CheerDefense1,
      :CheerDefense2,
      :CheerDefense3,
      :CheerOffense1,
      :CheerOffense2,
      :CheerOffense3,
      :Reflect,
      :LightScreen,
      :Safeguard,
      :Mist,
      :LuckyChant,
      :Tailwind,
      :Rainbow, 
      :Swamp, 
      :SeaOfFire,
      :Spikes, 
      :ToxicSpikes,
      :Cannonade,
      :VineLash, 
      :Volcalith, 
      :Wildfire
    ],
    :boolean => [
      :StealthRock,
      :Steelsurge,
      :StickyWeb,
      :CraftyShield,
      :MatBlock,
      :QuickGuard,
      :WideGuard
    ]
  },
  #-----------------------------------------------------------------------------
  # Effects that apply to a battler.
  #-----------------------------------------------------------------------------
  :battler => {
    :counter => [
      :MagnetRise,
      :HealBlock,
      :Embargo,
      :Taunt,
      :Disable,
      :Encore,
      :Telekinesis,
      :Splinters,
      :Yawn,
      :ThroatChop,
      :LockOn,
      :LaserFocus,
      :HyperBeam,
      :GlaiveRush,
      :Stockpile,
      :SlowStart,
      :PerishSong,
      :Syrupy,
      :Charge,
      :FocusEnergy,
      :Toxic,
      :Confusion,
      :Outrage,
      :Trapping,
      :Uproar,
      :WeightChange,
      :Substitute,
    ],
    :index => [
      :Attract,
      :LeechSeed,
      :MeanLook,
      :JawLock, 
      :Octolock,
      :SkyDrop
    ],
    :boolean => [
      :TwoTurnAttack,
      :AquaRing,
      :Ingrain,
      :Curse,
      :Nightmare,
      :SaltCure,
      :Rage,
      :Torment,
      :GastroAcid,
      :Imprison,
      :TarShot,
      :Foresight,
      :MiracleEye,
      :Minimize,
      :NoRetreat,
      :MudSport,
      :WaterSport,
      :Flinch,
      :Snatch,
      :Quash,
      :Protect,
      :Obstruct,
      :KingsShield,
      :SpikyShield,
      :BanefulBunker,
      :SilkTrap,
      :BurningBulwark,
      :HelpingHand,
      :PowerTrick, 
      :Endure,
      :Grudge,
      :DestinyBond,
      :Roost,
      :SmackDown,
      :BurnUp,
      :DoubleShock,
      :Electrify,
      :ExtraType,
      :MagicCoat,
      :Powder
    ],
  },
  #-----------------------------------------------------------------------------
  # Effects that apply to a battler position.
  #-----------------------------------------------------------------------------
  :position => {
    :counter => [
      :Wish,
      :FutureSightCounter
    ],
    :boolean => [
      :HealingWish,
      :LunarDance,
      :ZHealing
    ]
  }
}