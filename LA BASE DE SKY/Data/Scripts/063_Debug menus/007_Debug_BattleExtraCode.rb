#===============================================================================
# Valores de efectos que se pueden editar a través del menú debug de combate.
#===============================================================================
module Battle::DebugVariables
  BATTLER_EFFECTS = {
    PBEffects::AquaRing       => {name: "Se aplica Acua aro",                              default: false},
    PBEffects::Attract        => {name: "Pokémon al que este se siente atraído",           default: -1},   # Battler index
    PBEffects::BanefulBunker  => {name: "Se aplica Búnker en esta ronda",                  default: false},
#    PBEffects::BeakBlast - only applies to use of specific move, not suitable for setting via debug
    PBEffects::Bide           => {name: "Rondas que quedan de venganza",                   default: 0},
    PBEffects::BideDamage     => {name: "Daño acumulado de venganza",                      default: 0, max: 999},
    PBEffects::BideTarget     => {name: "Último combatiente que le pegó con venganza",     default: -1},   # Battler index
    PBEffects::BurnUp         => {name: "Llama final ha eliminado el tipo fuego del Pkmn", default: false},
    PBEffects::Charge         => {name: "Número de rondas restantes de Carga",             default: 0},
    PBEffects::ChoiceBand     => {name: "Movimiento bloqueado por objetos elegidos",       default: nil, type: :move},
    PBEffects::Confusion      => {name: "Número de rondas restantes de Confusión",         default: 0},
#    PBEffects::Counter - not suitable for setting via debug
#    PBEffects::CounterTarget - not suitable for setting via debug
    PBEffects::Curse          => {name: "Se aplica daño de Maldición",                     default: false},
#    PBEffects::Dancer - only used while Dancer is running, not suitable for setting via debug
    PBEffects::DefenseCurl    => {name: "Has usado Rizo defensa",                          default: false},
#    PBEffects::DestinyBond - not suitable for setting via debug
#    PBEffects::DestinyBondPrevious - not suitable for setting via debug
#    PBEffects::DestinyBondTarget - not suitable for setting via debug
    PBEffects::Disable        => {name: "Número de rondas restantes de Anulación",         default: 0},
    PBEffects::DisableMove    => {name: "Movimiento Anulado",                              default: nil, type: :move},
    PBEffects::Electrify      => {name: "Electrificación vuelve los ataques eléctricos",   default: false},
    PBEffects::Embargo        => {name: "Rondas que quedan de embargo",                    default: 0},
    PBEffects::Encore         => {name: "Número de turnos que quedan de Otra vez",         default: 0},
    PBEffects::EncoreMove     => {name: "Movimiento afectado por Otra vez",                default: nil, type: :move},
    PBEffects::Endure         => {name: "Aguanta todos los movimientos que lo matan este turno",default: false},
#    PBEffects::FirstPledge - only applies to use of specific move, not suitable for setting via debug
    PBEffects::FlashFire      => {name: "Absorber Fuego potencia los mov. de Fuego",       default: false},
    PBEffects::Flinch         => {name: "Hará retroceder este turno",                      default: false},
    PBEffects::FocusEnergy    => {name: "Etapa de crítico de Foco energía (0-4)",          default: 0, max: 4},
#    PBEffects::FocusPunch - only applies to use of specific move, not suitable for setting via debug
    PBEffects::FollowMe       => {name: "Señuelo atrayendo ataques a él (si 1+)",          default: 0},   # Order of use, lowest takes priority
    PBEffects::RagePowder     => {name: "Se aplica Polvo Ira (usar con Señuelo)",          default: false},
    PBEffects::Foresight      => {name: "Se aplica premonición (Fantasma pierde inmunidad)",default: false},
    PBEffects::FuryCutter     => {name: "Multiplicador de poder de Corte Furia 2**x (0-4)",default: 0, max: 4},
    PBEffects::GastroAcid     => {name: "Bilis ignora su habilidad",                       default: false},
#    PBEffects::GemConsumed - only applies during use of move, not suitable for setting via debug
    PBEffects::Grudge         => {name: "Rabia se aplica si el usuario se debilita",       default: false},
    PBEffects::HealBlock      => {name: "Turnos restantes de Anticura",                    default: 0},
    PBEffects::HelpingHand    => {name: "Refuerzo aumenta los movimientos del pokémon",    default: false},
    PBEffects::HyperBeam      => {name: "Turnos restantes de recarga de Hiperrayo",        default: 0},
#    PBEffects::Illusion - is a Pokémon object, too complex to be worth bothering with
    PBEffects::Imprison       => {name: "Sellar anula los movimientos de otros que él sepa",   default: false},
    PBEffects::Ingrain        => {name: "Aplica Arraigo",                                  default: false},
#    PBEffects::Instruct - only used while Instruct is running, not suitable for setting via debug
#    PBEffects::Instructed - only used while Instruct is running, not suitable for setting via debug
    PBEffects::JawLock        => {name: "El comabtiente se atrapa con Presa maxilar",      default: -1},   # Battler index
    PBEffects::KingsShield    => {name: "Escudo Real se aplica este turno",                default: false},
    PBEffects::LaserFocus     => {name: "Duración de críticos aumentados de Aguzar",       default: 0},
    PBEffects::LeechSeed      => {name: "Combatiente que ha usado Drenadores en el Pkmn",  default: -1},   # Battler index
    PBEffects::LockOn         => {name: "Turnos restantes de Fijar blanco",                default: 0},
    PBEffects::LockOnPos      => {name: "Combatiente al que el Pkmn está fijando con Fijar Blanco",default: -1},   # Battler index
#    PBEffects::MagicBounce - only applies during use of move, not suitable for setting via debug
#    PBEffects::MagicCoat - only applies to use of specific move, not suitable for setting via debug
    PBEffects::MagnetRise     => {name: "Número de turnos restantes de Levitón",           default: 0},
    PBEffects::MeanLook       => {name: "Combatienete que está atrapando al Pokémon con Mal de ojo, etc.",default: -1},   # Battler index
#    PBEffects::MeFirst - only applies to use of specific move, not suitable for setting via debug
    PBEffects::Metronome      => {name: "Multiplicador del objeto Metrónomo 1 + 0.2*x (0-5)",default: 0, max: 5},
    PBEffects::MicleBerry     => {name: "Baya Lagro aumentando la precisión del siguiente movimiento",default: false},
    PBEffects::Minimize       => {name: "Ha usado Reducción",                              default: false},
    PBEffects::MiracleEye     => {name: "Se ha aplicado Gran ojo (Siniestro pierde inmunidad)",default: false},
#    PBEffects::MirrorCoat - not suitable for setting via debug
#    PBEffects::MirrorCoatTarget - not suitable for setting via debug
#    PBEffects::MoveNext - not suitable for setting via debug
    PBEffects::MudSport       => {name: "Se ha usado Chapoteo lodo (Gen 5 y posterior)",   default: false},
    PBEffects::Nightmare      => {name: "Recibiendo daño de Pesadilla",                    default: false},
    PBEffects::NoRetreat      => {name: "Bastión Final atrapando al Pokémon en batalla",   default: false},
    PBEffects::Obstruct       => {name: "Obstrucción se aplica esta ronda",                default: false},
    PBEffects::Octolock       => {name: "Combatiente atrapándose a sí mismo con Octopresa",default: -1},   # Battler index
    PBEffects::Outrage        => {name: "Turnos restantes de Enfado",                      default: 0},
#    PBEffects::ParentalBond - only applies during use of move, not suitable for setting via debug
    PBEffects::PerishSong     => {name: "Turnos restantes de Canto Mortal",                default: 0},
    PBEffects::PerishSongUser => {name: "Combatiente que ha usado Canto Mortal en sí mismo",default: -1},   # Battler index
    PBEffects::PickupItem     => {name: "Objeto recuperable con Recogida",                 default: nil, type: :item},
    PBEffects::PickupUse      => {name: "Tiempo de objeto de recogida consumido (más alto=más reciente)",  default: 0},
    PBEffects::Pinch          => {name: "(Palacio Batalla) Comportamiento cambiado con <50% PS",default: false},
    PBEffects::Powder         => {name: "Polvo Explosivo explotará los movimientos de Fuego del Pkmn esta turno", default: false},
#    PBEffects::PowerTrick - doesn't actually swap the stats therefore does nothing, not suitable for setting via debug
#    PBEffects::Prankster - not suitable for setting via debug
#    PBEffects::PriorityAbility - not suitable for setting via debug
#    PBEffects::PriorityItem - not suitable for setting via debug
    PBEffects::Protect        => {name: "Protección se aplica este turno",                 default: false},
    PBEffects::ProtectRate    => {name: "Probabilida de acierto de Protección 1/x",        default: 1, max: 999},
#    PBEffects::Quash - not suitable for setting via debug
#    PBEffects::Rage - only applies to use of specific move, not suitable for setting via debug
    PBEffects::Rollout        => {name: "Rondas restantes de Desenrollar/Rodar (menor=más fuerte)",default: 0},
    PBEffects::Roost          => {name: "Respiro eliminando el tipo Volador este turno",   default: false},
#    PBEffects::ShellTrap - only applies to use of specific move, not suitable for setting via debug
#    PBEffects::SkyDrop - only applies to use of specific move, not suitable for setting via debug
    PBEffects::SlowStart      => {name: "Turnos restantes de Inicio Lento",                default: 0},
    PBEffects::SmackDown      => {name: "Antiaéreo hace que esté en el suelo",             default: false},
#    PBEffects::Snatch - only applies to use of specific move, not suitable for setting via debug
    PBEffects::SpikyShield    => {name: "Barrera espinosa se aplica este turno",           default: false},
    PBEffects::Spotlight      => {name: "Foco atrayendo ataques (si 1+)",                  default: 0},
    PBEffects::Stockpile      => {name: "Contador de Reserva (0-3)",                       default: 0, max: 3},
    PBEffects::StockpileDef   => {name: "Cambios de Defensa ganados por Reserva (0-12)",   default: 0, max: 12},
    PBEffects::StockpileSpDef => {name: "Cambios de Def. Esp ganados por Reserva (0-12)",  default: 0, max: 12},
    PBEffects::Substitute     => {name: "PS del sustituto",                                default: 0, max: 999},
    PBEffects::TarShot        => {name: "Alquitranazo haciendo al Pkmn débil al Fuego",    default: false},
    PBEffects::Taunt          => {name: "Turnos restantes de Mofa",                        default: 0},
    PBEffects::Telekinesis    => {name: "Turnos restantes de Telequinesis",                default: 0},
    PBEffects::ThroatChop     => {name: "Turnos restantes de Golpe Mordaza",               default: 0},
    PBEffects::Torment        => {name: "Tormento evitando que se repitan movimientos",    default: false},
#    PBEffects::Toxic - set elsewhere
#    PBEffects::Transform - too complex to be worth bothering with
#    PBEffects::TransformSpecies - too complex to be worth bothering with
    PBEffects::Trapping       => {name: "Turnos restantes de quedarse atrapado",           default: 0},
    PBEffects::TrappingMove   => {name: "Movimiento que está atrapando al Pkmn",           default: nil, type: :move},
    PBEffects::TrappingUser   => {name: "Combatiente atrapando al Pkmn (para Banda Atadura)",default: -1},   # Battler index
    PBEffects::Truant         => {name: "Pereza haciendo que no haga nada este turno",     default: false},
#    PBEffects::TwoTurnAttack - only applies to use of specific moves, not suitable for setting via debug
#    PBEffects::ExtraType - set elsewhere
    PBEffects::Unburden       => {name: "El usuario ha perdido su objeto (para Liviano)",  default: false},
    PBEffects::Uproar         => {name: "Turnos restantes de Alboroto",                    default: 0},
    PBEffects::WaterSport     => {name: "Se ha usado Hidrochorro (Gen 5 y posterior)",     default: false},
    PBEffects::WeightChange   => {name: "Cambio de peso +0.1*x kg",                        default: 0, min: -99_999, max: 99_999},
    PBEffects::Yawn           => {name: "Rondas restantes de Bostezo hasta dormirse",      default: 0}
  }

  SIDE_EFFECTS = {
    PBEffects::AuroraVeil         => {name: "Duración de Velo aurora",                default: 0},
    PBEffects::CraftyShield       => {name: "Truco defensa se aplica esta ronda",     default: false},
    PBEffects::EchoedVoiceCounter => {name: "Rondas usando Eco voz (máx. 5)",         default: 0, max: 5},
    PBEffects::EchoedVoiceUsed    => {name: "Eco voz usado este turno",               default: false},
    PBEffects::LastRoundFainted   => {name: "Ronda en la que el compañero se ha debilitado",default: -2},   # Treated as -1, isn't a battler index
    PBEffects::LightScreen        => {name: "Duración de Pantalla luz",               default: 0},
    PBEffects::LuckyChant         => {name: "Duración de Conjuro",                    default: 0},
    PBEffects::MatBlock           => {name: "Escudo tatami aplicado este turno",      default: false},
    PBEffects::Mist               => {name: "Duración de Niebla",                     default: 0},
    PBEffects::QuickGuard         => {name: "Anticipo aplicado este turno",           default: false},
    PBEffects::Rainbow            => {name: "Duración de Arcoíris (por los votos)",   default: 0},
    PBEffects::Reflect            => {name: "Duración de Reflejo",                    default: 0},
    PBEffects::Round              => {name: "Canon se ha usado este turno",           default: false},
    PBEffects::Safeguard          => {name: "Duración de Vastaguardia",               default: 0},
    PBEffects::SeaOfFire          => {name: "Duración de Mar de Fuego (por los votos)",default: 0},
    PBEffects::Spikes             => {name: "Capas de Púas (0-3)",                    default: 0, max: 3},
    PBEffects::StealthRock        => {name: "Hay Trampa rocas",                       default: false},
    PBEffects::StickyWeb          => {name: "Hay Red viscosa",                        default: false},
    PBEffects::Swamp              => {name: "Duración de Pantano (por los votos)",    default: 0},
    PBEffects::Tailwind           => {name: "Duración de Viento afín",                default: 0},
    PBEffects::ToxicSpikes        => {name: "Capas de Púas tóxicas (0-2)",            default: 0, max: 2},
    PBEffects::WideGuard          => {name: "Vasta guardia se aplica este turno",     default: false}
  }

  FIELD_EFFECTS = {
    PBEffects::AmuletCoin      => {name: "Mon. Amuleto duplica el dinero al ganar",default: false},
    PBEffects::FairyLock       => {name: "Duración de atrapar de Cerrojo feérico",default: 0},
    PBEffects::FusionBolt      => {name: "Se ha usado Rayo fusión",          default: false},
    PBEffects::FusionFlare     => {name: "Se ha usado Llama fusión",         default: false},
    PBEffects::Gravity         => {name: "Duración de Gravedad",             default: 0},
    PBEffects::HappyHour       => {name: "Paga extra duplica el dinero al ganar",default: false},
    PBEffects::IonDeluge       => {name: "Cortina plasma volviendo los movs. eléctricos",default: false},
    PBEffects::MagicRoom       => {name: "Duración de Zona mágica",          default: 0},
    PBEffects::MudSportField   => {name: "Duración de Chapoteo lodo (Gen 6+)",default: 0},
    PBEffects::PayDay          => {name: "Dinero extra de Día de pago",      default: 0, max: Settings::MAX_MONEY},
    PBEffects::TrickRoom       => {name: "Duración de Espacio raro",         default: 0},
    PBEffects::WaterSportField => {name: "Duración de Hidrochorro (Gen 6+)", default: 0},
    PBEffects::WonderRoom      => {name: "Duración de Zona extraña",         default: 0}
  }

  POSITION_EFFECTS = {
#    PBEffects::FutureSightCounter - too complex to be worth bothering with
#    PBEffects::FutureSightMove - too complex to be worth bothering with
#    PBEffects::FutureSightUserIndex - too complex to be worth bothering with
#    PBEffects::FutureSightUserPartyIndex - too complex to be worth bothering with
    PBEffects::HealingWish => {name: "Si Deseo cura está esperando para ser aplicado", default: false},
    PBEffects::LunarDance  => {name: "Si Danza lunar está esperando para ser aplicado",  default: false}
#    PBEffects::Wish - too complex to be worth bothering with
#    PBEffects::WishAmount - too complex to be worth bothering with
#    PBEffects::WishMaker - too complex to be worth bothering with
  }
  
  BATTLER_EFFECTS[PBEffects::AllySwitch]      = { name: "Ally Switch applies this round",                default: false }
  BATTLER_EFFECTS[PBEffects::CudChew]         = { name: "Cud Chew number of rounds until active",        default: 0 }
  BATTLER_EFFECTS[PBEffects::DoubleShock]     = { name: "Double Shock has removed self's Electric type", default: false }
  BATTLER_EFFECTS[PBEffects::GlaiveRush]      = { name: "Glaive Rush vulnerability rounds remaining",    default: 0 }
  BATTLER_EFFECTS[PBEffects::ParadoxStat]     = { name: "Protosynthesis/Quark Drive stat boosted",       default: nil, type: :stat }
  BATTLER_EFFECTS[PBEffects::BoosterEnergy]   = { name: "Booster Energy applies",                        default: false }
  BATTLER_EFFECTS[PBEffects::SaltCure]        = { name: "Salt Cure applies",                             default: false }
  BATTLER_EFFECTS[PBEffects::SilkTrap]        = { name: "Silk Trap applies this round",                  default: false }
  BATTLER_EFFECTS[PBEffects::Splinters]       = { name: "Splinters number of rounds remaining",          default: 0 }
  BATTLER_EFFECTS[PBEffects::SplintersType]   = { name: "Splinters damage typing",                       default: nil, type: :type }
  BATTLER_EFFECTS[PBEffects::SupremeOverlord] = { name: "Supreme Overlord multiplier 1 + 0.1*x (0-5)",   default: 0, max: 5 }
  BATTLER_EFFECTS[PBEffects::Syrupy]          = { name: "Syrupy turns remaining",                        default: 0 }
  BATTLER_EFFECTS[PBEffects::SyrupyUser]      = { name: "Battler syruped self",                          default: -1 }
  BATTLER_EFFECTS[PBEffects::BurningBulwark]  = { name: "Burning Bulwark applies this round",            default: false }
end

#===============================================================================
# Screen for listing the above battle variables for modifying.
#===============================================================================
class SpriteWindow_DebugBattleFieldEffects < Window_DrawableCommand
  BASE_TEXT_COLOR   = Color.new(96, 96, 96)
  RED_TEXT_COLOR    = Color.new(168, 48, 56)
  GREEN_TEXT_COLOR  = Color.new(0, 144, 0)
  TEXT_SHADOW_COLOR = Color.new(208, 208, 200)

  def initialize(viewport, battle, variables, variables_data)
    @battle         = battle
    @variables      = variables
    @variables_data = variables_data
    super(0, 0, Graphics.width, Graphics.height, viewport)
  end

  def itemCount
    return @variables_data.length
  end

  def shadowtext(x, y, w, h, t, align = 0, colors = 0)
    width = self.contents.text_size(t).width
    case align
    when 1   # Right aligned
      x += w - width
    when 2   # Centre aligned
      x += (w - width) / 2
    end
    base_color = BASE_TEXT_COLOR
    case colors
    when 1 then base_color = RED_TEXT_COLOR
    when 2 then base_color = GREEN_TEXT_COLOR
    end
    pbDrawShadowText(self.contents, x, y, [width, w].max, h, t, base_color, TEXT_SHADOW_COLOR)
  end

  def drawItem(index, _count, rect)
    pbSetNarrowFont(self.contents)
    variable_data = @variables_data[@variables_data.keys[index]]
    variable = @variables[@variables_data.keys[index]]
    # Variables which aren't their default value are colored differently
    default = variable_data[:default]
    default = -1 if default == -2
    different = (variable || default) != default
    color = (different) ? 2 : 0
    # Draw cursor
    rect = drawCursor(index, rect)
    # Get value's text to draw
    variable_text = variable.to_s
    case variable_data[:default]
    when -1   # Battler
      if variable >= 0
        battler_name = @battle.battlers[variable].name
        battler_name = "-" if nil_or_empty?(battler_name)
        variable_text = sprintf("[%d] %s", variable, battler_name)
      else
        variable_text = _INTL("[Ninguno]")
      end
    when nil   # Move, item
      variable_text = _INTL("[Ninguno]") if !variable
    end
    # Draw text
    total_width = rect.width
    name_width  = total_width * 80 / 100
    value_width = total_width * 20 / 100
    self.shadowtext(rect.x, rect.y + 8, name_width, rect.height, variable_data[:name], 0, color)
    self.shadowtext(rect.x + name_width, rect.y + 8, value_width, rect.height, variable_text, 1, color)
  end
end

#===============================================================================
#
#===============================================================================
class Battle::DebugSetEffects
  def initialize(battle, mode, side = 0)
    @battle = battle
    @mode = mode
    @side = side
    case @mode
    when :field
      @variables_data = Battle::DebugVariables::FIELD_EFFECTS
      @variables = @battle.field.effects
    when :side
      @variables_data = Battle::DebugVariables::SIDE_EFFECTS
      @variables = @battle.sides[@side].effects
    when :position
      @variables_data = Battle::DebugVariables::POSITION_EFFECTS
      @variables = @battle.positions[@side].effects
    when :battler
      @variables_data = Battle::DebugVariables::BATTLER_EFFECTS
      @variables = @battle.battlers[@side].effects
    end
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @window = SpriteWindow_DebugBattleFieldEffects.new(@viewport, @battle, @variables, @variables_data)
    @window.active = true
  end

  def dispose
    @window.dispose
    @viewport.dispose
  end

  def choose_number(default, min, max)
    params = ChooseNumberParams.new
    params.setRange(min, max)
    params.setDefaultValue(default)
    params.setNegativesAllowed(true) if min < 0
    return pbMessageChooseNumber(_INTL("Elige valor ({1}-{2}).", min, max), params)
  end

  def choose_battler(default)
    commands = [_INTL("[Ninguno]")]
    cmds = [-1]
    cmd = 0
    @battle.battlers.each_with_index do |battler, i|
      next if battler.nil?   # Position doesn't exist
      name = battler.pbThis
      name = "-" if battler.fainted? || nil_or_empty?(name)
      commands.push(sprintf("[%d] %s", i, name))
      cmds.push(i)
      cmd = cmds.length - 1 if default == i
    end
    cmd = pbMessage("\\ts[]" + _INTL("Choose a battler/position."), commands, -1, nil, cmd)
    return (cmd >= 0) ? cmds[cmd] : default
  end

  def update_input_for_boolean(effect, variable_data)
    if Input.trigger?(Input::USE)
      pbPlayDecisionSE
      @variables[effect] = !@variables[effect]
      return true
    elsif Input.trigger?(Input::ACTION) && @variables[effect]
      pbPlayDecisionSE
      @variables[effect] = false
      return true
    elsif Input.repeat?(Input::LEFT) && @variables[effect]
      pbPlayCursorSE
      @variables[effect] = false
      return true
    elsif Input.repeat?(Input::RIGHT) && !@variables[effect]
      pbPlayCursorSE
      @variables[effect] = true
      return true
    end
    return false
  end

  def update_input_for_integer(effect, default, variable_data)
    true_default = (default == -2) ? -1 : default
    min = variable_data[:min] || true_default
    max = variable_data[:max] || 99
    if Input.trigger?(Input::USE)
      pbPlayDecisionSE
      new_value = choose_number(@variables[effect], min, max)
      if new_value != @variables[effect]
        @variables[effect] = new_value
        return true
      end
    elsif Input.trigger?(Input::ACTION) && @variables[effect] != true_default
      pbPlayDecisionSE
      @variables[effect] = true_default
      return true
    elsif Input.repeat?(Input::LEFT) && @variables[effect] > min
      pbPlayCursorSE
      @variables[effect] -= 1
      return true
    elsif Input.repeat?(Input::RIGHT) && @variables[effect] < max
      pbPlayCursorSE
      @variables[effect] += 1
      return true
    end
    return false
  end

  def update_input_for_battler_index(effect, variable_data)
    if Input.trigger?(Input::USE)
      pbPlayDecisionSE
      new_value = choose_battler(@variables[effect])
      if new_value != @variables[effect]
        @variables[effect] = new_value
        return true
      end
    elsif Input.trigger?(Input::ACTION) && @variables[effect] != -1
      pbPlayDecisionSE
      @variables[effect] = -1
      return true
    elsif Input.repeat?(Input::LEFT)
      if @variables[effect] > -1
        pbPlayCursorSE
        loop do
          @variables[effect] -= 1
          break if @variables[effect] == -1 || @battle.battlers[@variables[effect]]
        end
        return true
      end
    elsif Input.repeat?(Input::RIGHT)
      if @variables[effect] < @battle.battlers.length - 1
        pbPlayCursorSE
        loop do
          @variables[effect] += 1
          break if @battle.battlers[@variables[effect]]
        end
        return true
      end
    end
    return false
  end

  def update_input_for_move(effect, variable_data)
    if Input.trigger?(Input::USE)
      pbPlayDecisionSE
      new_value = pbChooseMoveList(@variables[effect])
      if new_value && new_value != @variables[effect]
        @variables[effect] = new_value
        return true
      end
    elsif Input.trigger?(Input::ACTION) && @variables[effect]
      pbPlayDecisionSE
      @variables[effect] = nil
      return true
    end
    return false
  end

  def update_input_for_item(effect, variable_data)
    if Input.trigger?(Input::USE)
      pbPlayDecisionSE
      new_value = pbChooseItemList(@variables[effect])
      if new_value && new_value != @variables[effect]
        @variables[effect] = new_value
        return true
      end
    elsif Input.trigger?(Input::ACTION) && @variables[effect]
      pbPlayDecisionSE
      @variables[effect] = nil
      return true
    end
    return false
  end
  
  def update_input_for_stat(effect, variable_data)
    if Input.trigger?(Input::USE)
      pbPlayDecisionSE
      new_value = pbChooseStatList(:main_battle, @variables[effect])
      if new_value && new_value != @variables[effect]
        @variables[effect] = new_value
        return true
      end
    elsif Input.trigger?(Input::ACTION) && @variables[effect]
      pbPlayDecisionSE
      @variables[effect] = nil
      return true
    end
    return false
  end
  
  def update_input_for_type(effect, variable_data)
    if Input.trigger?(Input::USE)
      pbPlayDecisionSE
      new_value = pbChooseTypeList(@variables[effect])
      if new_value && new_value != @variables[effect]
        @variables[effect] = new_value
        return true
      end
    elsif Input.trigger?(Input::ACTION) && @variables[effect]
      pbPlayDecisionSE
      @variables[effect] = nil
      return true
    end
    return false
  end

  def update
    loop do
      Graphics.update
      Input.update
      @window.update
      if Input.trigger?(Input::BACK)
        pbPlayCancelSE
        break
      end
      index = @window.index
      effect = @variables_data.keys[index]
      variable_data = @variables_data[effect]
      if variable_data[:default] == false
        @window.refresh if update_input_for_boolean(effect, variable_data)
      elsif [0, 1, -2].include?(variable_data[:default])
        @window.refresh if update_input_for_integer(effect, variable_data[:default], variable_data)
      elsif variable_data[:default] == -1
        @window.refresh if update_input_for_battler_index(effect, variable_data)
      elsif variable_data[:default].nil?
        case variable_data[:type]
        when :move
          @window.refresh if update_input_for_move(effect, variable_data)
        when :item
          @window.refresh if update_input_for_item(effect, variable_data)
        when :stat
          @window.refresh if update_input_for_stat(effect, variable_data)
        when :type
          @window.refresh if update_input_for_type(effect, variable_data)
        else
          raise "¡Tipo de variable desconocido!"
        end
      else
        raise "¡Tipo de variable desconocido!"
      end
    end
  end
end

