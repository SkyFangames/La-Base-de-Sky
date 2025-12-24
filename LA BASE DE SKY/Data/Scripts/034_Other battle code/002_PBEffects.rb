#===============================================================================
#
#===============================================================================
module PBEffects
  #-----------------------------------------------------------------------------
  # These effects apply to a battler.
  #-----------------------------------------------------------------------------

  AllySwitchRate      = 0
  AquaRing            = 1
  Attract             = 2
  BanefulBunker       = 3
  BeakBlast           = 4
  Bide                = 5
  BideDamage          = 6
  BideTarget          = 7
  BoosterEnergy       = 8
  BurningBulwark      = 9
  BurnUp              = 10
  Charge              = 11
  ChoiceBand          = 12
  CommandedBy         = 13
  Commanding          = 14
  Confusion           = 15
  Counter             = 16
  CounterTarget       = 17
  CudChewBerry        = 18
  CudChewCounter      = 19
  Curse               = 20
  Dancer              = 21
  DefenseCurl         = 22
  DestinyBond         = 23
  DestinyBondPrevious = 24
  DestinyBondTarget   = 25
  Disable             = 26
  DisableMove         = 27
  DoubleShock         = 28
  Electrify           = 29
  Embargo             = 30
  Encore              = 31
  EncoreMove          = 32
  Endure              = 33
  ExtraType           = 34
  FirstPledge         = 35
  FlashFire           = 36
  Flinch              = 37
  FocusEnergy         = 38
  FocusPunch          = 39
  FollowMe            = 40
  Foresight           = 41
  FuryCutter          = 42
  GastroAcid          = 43
  GemConsumed         = 44
  GigatonHammer       = 45
  Grudge              = 46
  HealBlock           = 47
  HelpingHand         = 48
  HyperBeam           = 49
  Illusion            = 50
  Imprison            = 51
  Ingrain             = 52
  Instruct            = 53
  Instructed          = 54
  JawLock             = 55
  KingsShield         = 56
  LaserFocus          = 57
  LeechSeed           = 58
  LockOn              = 59
  LockOnPos           = 60
  MagicBounce         = 61
  MagicCoat           = 62
  MagnetRise          = 63
  MeanLook            = 64
  MeFirst             = 65
  Metronome           = 66
  MicleBerry          = 67
  Minimize            = 68
  MiracleEye          = 69
  MirrorCoat          = 70
  MirrorCoatTarget    = 71
  MoveNext            = 72
  MudSport            = 73
  Nightmare           = 74
  NoRetreat           = 75
  Obstruct            = 76
  Octolock            = 77
  Outrage             = 78
  ParentalBond        = 79
  PerishSong          = 80
  PerishSongUser      = 81
  PickupItem          = 82
  PickupUse           = 83
  Pinch               = 84   # Battle Palace only
  Powder              = 85
  PowerTrick          = 86
  Prankster           = 87
  PriorityAbility     = 88
  PriorityItem        = 89
  Protect             = 90
  ProtectRate         = 91
  ProtosynthesisStat  = 92
  Quash               = 93
  Rage                = 94
  RagePowder          = 95   # Used along with FollowMe
  Rollout             = 96
  Roost               = 97
  SaltCure            = 98
  ShedTail            = 99   # Just prevents Substitute resetting upon switch
  ShellTrap           = 100
  SilkTrap            = 101
  SkyDrop             = 102
  SlowStart           = 103
  SmackDown           = 104
  Snatch              = 105
  SpikyShield         = 106
  Spotlight           = 107
  Stockpile           = 108
  StockpileDef        = 109
  StockpileSpDef      = 110
  Substitute          = 111
  SyrupBomb           = 112
  SyrupBombUser       = 113
  TarShot             = 114
  Taunt               = 115
  Telekinesis         = 116
  ThroatChop          = 117
  Torment             = 118
  Toxic               = 119
  Transform           = 120
  TransformSpecies    = 121
  Trapping            = 122   # Trapping move that deals EOR damage
  TrappingMove        = 123
  TrappingUser        = 124
  Truant              = 125
  TwoTurnAttack       = 126
  Unburden            = 127
  Uproar              = 128
  Vulnerable          = 129
  WaterSport          = 130
  WeightChange        = 131
  Yawn                = 132

  #-----------------------------------------------------------------------------
  # These effects apply to a battler position.
  #-----------------------------------------------------------------------------

  FutureSightCounter        = 700
  FutureSightMove           = 701
  FutureSightUserIndex      = 702
  FutureSightUserPartyIndex = 703
  HealingWish               = 704
  LunarDance                = 705
  Wish                      = 706
  WishAmount                = 707
  WishMaker                 = 708

  #-----------------------------------------------------------------------------
  # These effects apply to a side.
  #-----------------------------------------------------------------------------

  AuroraVeil         = 800
  CraftyShield       = 801
  EchoedVoiceCounter = 802
  EchoedVoiceUsed    = 803
  LastRoundFainted   = 804
  LightScreen        = 805
  LuckyChant         = 806
  MatBlock           = 807
  Mist               = 808
  QuickGuard         = 809
  Rainbow            = 810
  Reflect            = 811
  Round              = 812
  Safeguard          = 813
  SeaOfFire          = 814
  Spikes             = 815
  StealthRock        = 816
  StickyWeb          = 817
  Swamp              = 818
  Tailwind           = 819
  ToxicSpikes        = 820
  WideGuard          = 821

  #-----------------------------------------------------------------------------
  # These effects apply to the battle (i.e. both sides).
  #-----------------------------------------------------------------------------

  AmuletCoin      = 900
  FairyLock       = 901
  FusionBolt      = 902
  FusionFlare     = 903
  Gravity         = 904
  HappyHour       = 905
  IonDeluge       = 906
  MagicRoom       = 907
  MudSportField   = 908
  PayDay          = 909
  TrickRoom       = 910
  WaterSportField = 911
  WonderRoom      = 912
end
