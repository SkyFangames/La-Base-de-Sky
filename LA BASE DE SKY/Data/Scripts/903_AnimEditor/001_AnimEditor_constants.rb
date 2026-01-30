#===============================================================================
#
#===============================================================================
class AnimationEditor
  CONTAINER_BORDER = 3
  WINDOW_WIDTH     = Settings::SCREEN_WIDTH + (256 * 2) + (CONTAINER_BORDER * 6)   # 256 is MENU_BAR_WIDTH and BATCH_EDITS_WIDTH
  WINDOW_HEIGHT    = Settings::SCREEN_HEIGHT + 540 + (CONTAINER_BORDER * 4)   # 540 is arbitrary but large
  WINDOW_HEIGHT    = [WINDOW_HEIGHT, Graphics.display_height - 100].min   # 100 is ~ height of window title bar and taskbar
  WINDOW_HEIGHT    = [WINDOW_HEIGHT, Settings::SCREEN_HEIGHT + 150 + (CONTAINER_BORDER * 4)].max   # 150 is arbitrary; shows 4 particle rows

  # Minimum and maximum values the editor allows for certain properties. Only
  # properties that can be interpolated are here, and not :color or :tone
  # because those have string values.
  PROPERTY_RANGES = {   # Min, max
    :x       => [ -999,  999],
    :y       => [ -999,  999],
    :z       => [  -50,   50],
    :zoom_x  => [    0, 1000],
    :zoom_y  => [    0, 1000],
    :angle   => [-9999, 9999],
    :opacity => [    0,  255],
    :frame   => [    0,   99]
  }

  #-----------------------------------------------------------------------------

  # This list of animations was gathered manually by looking at all instances of
  # pbCommonAnimation.
  COMMON_ANIMATIONS = [
    # Weather
    "Hail", "Rain", "Sandstorm", "ShadowSky", "Snowstorm", "Sun",
    "HarshSun", "HeavyRain", "StrongWinds",
    # Terrain
    "ElectricTerrain", "GrassyTerrain", "MistyTerrain", "PsychicTerrain",
    # HP and stats
    "HealthDown", "HealthUp",
    "CriticalHitRateUp", "StatDown", "StatUp",
    # Status conditions
    "Burn", "Frozen", "Paralysis", "Poison", "Sleep", "Toxic",
    "Attract", "Confusion",
    # Upon entering battle
    "HealingWish", "LunarDance", "Shadow", "Shiny", "SuperShiny",
    # Transformation
    "MegaEvolution", "MegaEvolution2",
    "PrimalGroudon", "PrimalGroudon2", "PrimalKyogre", "PrimalKyogre2",
    # Readying an attack
    "BeakBlast", "FocusPunch", "ShellTrap",
    # Protections
    "BanefulBunker", "BurningBulwark", "CraftyShield", "KingsShield",
    "Obstruct", "Protect", "QuickGuard", "SilkTrap", "SpikyShield", "WideGuard",
    # Pledge moves
    "Rainbow", "RainbowOpp", "SeaOfFire", "SeaOfFireOpp", "Swamp", "SwampOpp",
    # EOR
    "AquaRing", "Curse", "Ingrain", "LeechSeed", "Nightmare", "SaltCure",
    "Octolock", "SyrupBomb",
    # EOR trapping
    "Bind", "Clamp", "FireSpin", "Infestation", "MagmaStorm", "SandTomb", "Wrap",
    # Items
    "EatBerry", "UseItem",
    # Misc.
    "Commander",
    "LevelUp",
    "ParentalBond",
    "Powder"
  ]
end
