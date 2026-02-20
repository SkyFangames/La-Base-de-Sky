if defined?(PluginManager)
  PluginManager.register({
    :name       => "Save File Calls",
    :essentials => "21.1",
    :version    => "1.0",
    :credits    => ["TechSkylander1518", "DPertierra"]
  })
end

def pbSaveFile(name, ver = 21, save_prefix = 'Game')
  case ver
  when 21, 20, 19
    location = File.join("C:/Users", System.user_name, "AppData/Roaming", name)
    return [] unless File.directory?(location)
    pattern = File.join(location, "#{save_prefix}*.rxdata")
    files = Dir.glob(pattern)
    return [] if files.empty?
    
    save_data = files.map do |file|
      SaveData.get_data_from_file(file) if File.file?(file)
    end.compact
  when 18
    home = ENV['HOME'] || ENV['HOMEPATH']
    return [] if home.nil?
    location = File.join(home, 'Saved Games', name)
    return [] unless File.directory?(location)
    pattern = File.join(location, "#{save_prefix}*.rxdata")
    files = Dir.glob(pattern)
    return [] if files.empty?
    
    save_data = files.map do |file|
      next unless File.file?(file)
      data = SaveData.get_data_from_file(file).clone
      data = SaveData.to_hash_format(data) if data.is_a?(Array)
      data
    end.compact
  end
  return save_data
end

def pbSaveTest(name, test, param = nil, ver = 20, save_prefix = 'Game')
  saves = pbSaveFile(name, ver, save_prefix)
  return false if saves.empty?
  
  result = false
  test = test.capitalize
  
  # Check if ANY save matches the criteria
  saves.each do |save|
    case test
    when "Exist"
      result = true
    when "Map"
      result = (save[:map_factory].map.map_id == param)
    when "Name"
      result = (save[:player].name == param)
    when "Switch"
      result = save[:switches][param]
    when "Variable"
      varnum = param[0]
      varval = param[1]
      if varval.is_a?(Numeric)
        result = (save[:variables][varnum] >= varval)
      else
        result = (save[:variables][varnum] == varval)
      end
    when "Party"
      result = save[:player].party.any? { |poke| poke.species == param }
    when "Seen"
      case ver
      when 19, 20, 21
        result = save[:player].pokedex.seen?(param)
      else
        result = save[:player].seen[param]
      end
    when "Owned"
      case ver
      when 19, 20, 21
        result = save[:player].pokedex.owned?(param)
      else
        result = save[:player].pokedex.owned?(param)
      end
    when "Item"
      case ver
      when 19, 20, 21
        result = save[:bag].has?(param)
      else
        result = save[:bag].pockets.any? do |pocket|
          pocket.any? { |item| item[0] == param }
        end
      end
    end
    break if result  # Stop checking other saves if we found a match
  end
  return result
end

# Old utilities to convert prior data
class PokeBattle_Trainer
  attr_accessor :trainertype, :name, :id, :metaID, :outfit, :language
  attr_accessor :party, :badges, :money
  attr_accessor :seen, :owned, :formseen, :formlastseen, :shadowcaught
  attr_accessor :pokedex, :pokegear
  attr_accessor :mysterygiftaccess, :mysterygift

  def self.convert(trainer)
    validate trainer => self
    ret = Player.new(trainer.name, trainer.trainertype)
    ret.id           = trainer.id
    ret.character_ID = trainer.metaID if trainer.metaID
    ret.outfit       = trainer.outfit if trainer.outfit
    ret.language     = trainer.language if trainer.language
    trainer.party.each { |p| ret.party.push(PokeBattle_Pokemon.convert(p)) }
    ret.badges       = trainer.badges.clone
    ret.money        = trainer.money
    trainer.seen.each_with_index { |value, i| ret.pokedex.set_seen(i, false) if value }
    trainer.owned.each_with_index { |value, i| ret.pokedex.set_owned(i, false) if value }
    trainer.formseen.each_with_index do |value, i|
      species_id = GameData::Species.try_get(i)&.species
      next if species_id.nil? || value.nil?
      ret.pokedex.seen_forms[species_id] = [value[0].clone, value[1].clone] if value
    end
    trainer.formlastseen.each_with_index do |value, i|
      species_id = GameData::Species.try_get(i)&.species
      next if species_id.nil? || value.nil?
      ret.pokedex.set_last_form_seen(species_id, value[0], value[1]) if value
    end
    if trainer.shadowcaught
      trainer.shadowcaught.each_with_index do |value, i|
        ret.pokedex.set_shadow_pokemon_owned(i) if value
      end
    end
    ret.pokedex.refresh_accessible_dexes
    ret.has_pokedex           = trainer.pokedex
    ret.has_pokegear          = trainer.pokegear
    ret.mystery_gift_unlocked = trainer.mysterygiftaccess if trainer.mysterygiftaccess
    ret.mystery_gifts         = trainer.mysterygift.clone if trainer.mysterygift
    return ret
  end
end

class PokeBattle_Pokemon
  attr_accessor :name, :species, :form, :formTime, :forcedForm, :fused
  attr_accessor :personalID, :exp, :hp, :status, :statusCount
  attr_accessor :abilityflag, :genderflag, :natureflag, :natureOverride, :shinyflag
  attr_accessor :moves, :firstmoves
  attr_accessor :item, :mail
  attr_accessor :iv, :ivMaxed, :ev
  attr_accessor :happiness, :eggsteps, :pokerus
  attr_accessor :ballused, :markings, :ribbons
  attr_accessor :obtainMode, :obtainMap, :obtainText, :obtainLevel, :hatchedMap
  attr_accessor :timeReceived, :timeEggHatched
  attr_accessor :cool, :beauty, :cute, :smart, :tough, :sheen
  attr_accessor :trainerID, :ot, :otgender, :language
  attr_accessor :shadow, :heartgauge, :savedexp, :savedev, :hypermode, :shadowmoves

  def initialize(*args)
    raise "PokeBattle_Pokemon.new is deprecated. Use Pokemon.new instead."
  end

  def self.convert(pkmn)
    return pkmn if pkmn.is_a?(Pokemon)
    owner = Pokemon::Owner.new(pkmn.trainerID, pkmn.ot, pkmn.otgender, pkmn.language)
    natdex = [:NONE]
    GameData::Species.each_species { |s| natdex.push(s.id) }
    pkmn.species = natdex[pkmn.species]
    # Set level to 1 initially, as it will be recalculated later
    ret = Pokemon.new(pkmn.species, 1, owner, false, false)
    ret.forced_form    = pkmn.forcedForm if pkmn.forcedForm
    ret.time_form_set  = pkmn.formTime
    ret.exp            = pkmn.exp
    ret.steps_to_hatch = pkmn.eggsteps
    GameData::Status.each do |s|
      pkmn.status = s.id if s.icon_position == pkmn.status
    end
    ret.status           = pkmn.status
    ret.statusCount      = pkmn.statusCount
    ret.gender           = pkmn.genderflag
    ret.shiny            = pkmn.shinyflag
    ret.ability_index    = pkmn.abilityflag
    ret.nature           = pkmn.natureflag
    ret.nature_for_stats = pkmn.natureOverride
    ret.item             = pkmn.item
    ret.mail             = PokemonMail.convert(pkmn.mail) if pkmn.mail
    pkmn.moves.each { |m| ret.moves.push(PBMove.convert(m)) if m && m.id > 0 }
    if pkmn.firstmoves
      pkmn.firstmoves.each { |m| ret.add_first_move(m) }
    end
    if pkmn.ribbons
      pkmn.ribbons.each { |r| ret.giveRibbon(r) }
    end
    ret.cool             = pkmn.cool if pkmn.cool
    ret.beauty           = pkmn.beauty if pkmn.beauty
    ret.cute             = pkmn.cute if pkmn.cute
    ret.smart            = pkmn.smart if pkmn.smart
    ret.tough            = pkmn.tough if pkmn.tough
    ret.sheen            = pkmn.sheen if pkmn.sheen
    ret.pokerus          = pkmn.pokerus if pkmn.pokerus
    ret.name             = pkmn.name if pkmn.name != ret.speciesName
    ret.happiness        = pkmn.happiness
    ret.poke_ball        = pbBallTypeToItem(pkmn.ballused).id
    ret.markings         = pkmn.markings if pkmn.markings
    GameData::Stat.each_main do |s|
      ret.iv[s.id]      = pkmn.iv[s.id_number]
      ret.ivMaxed[s.id] = pkmn.ivMaxed[s.id_number] if pkmn.ivMaxed
      ret.ev[s.id]      = pkmn.ev[s.id_number]
    end
    ret.obtain_method  = pkmn.obtainMode
    ret.obtain_map     = pkmn.obtainMap
    ret.obtain_text    = pkmn.obtainText
    ret.obtain_level   = pkmn.obtainLevel if pkmn.obtainLevel
    ret.hatched_map    = pkmn.hatchedMap
    ret.timeReceived   = pkmn.timeReceived
    ret.timeEggHatched = pkmn.timeEggHatched
    if pkmn.fused
      ret.fused = PokeBattle_Pokemon.convert(pkmn.fused) if pkmn.fused.is_a?(PokeBattle_Pokemon)
      ret.fused = pkmn.fused if pkmn.fused.is_a?(Pokemon)
    end
    ret.personalID = pkmn.personalID
    ret.hp         = pkmn.hp
    if pkmn.shadow
      ret.shadow      = pkmn.shadow
      ret.heart_gauge = pkmn.heartgauge
      ret.hyper_mode  = pkmn.hypermode
      ret.saved_exp   = pkmn.savedexp
      if pkmn.savedev
        GameData::Stat.each_main { |s| ret.saved_ev[s.id] = pkmn.savedev[s.pbs_order] if s.pbs_order >= 0 }
      end
      ret.shadow_moves = []
      pkmn.shadowmoves.each_with_index do |move, i|
        ret.shadow_moves[i] = GameData::Move.get(move).id if move
      end
    end
    # NOTE: Intentionally set last, as it recalculates stats.
    ret.form_simple = pkmn.form || 0
    return ret
  end
end

class PBMove
  attr_accessor :id, :pp, :ppup

  def self.convert(move)
    ret = Pokemon::Move.new(move.id)
    ret.ppup = move.ppup
    ret.pp = move.pp
    return ret
  end
end

class PokemonMail
  attr_accessor :item, :message, :sender, :poke1, :poke2, :poke3

  def self.convert(mail)
    return mail if mail.is_a?(Mail)
    mail.poke1[0] = GameData::Species.get(mail.poke1[0]).id if mail.poke1
    mail.poke2[0] = GameData::Species.get(mail.poke2[0]).id if mail.poke2
    mail.poke3[0] = GameData::Species.get(mail.poke3[0]).id if mail.poke3
    return Mail.new(mail.item, mail.message, mail.sender, mail.poke1, mail.poke2, mail.poke3)
  end
end