class Pokemon
  attr_accessor :previous_form   # For tracking form changes
  #=============================================================================
  # Mega Evolution
  # NOTE: These are treated as form changes in Essentials.
  #=============================================================================
  def getMegaForm
    ret = 0
    GameData::Species.each do |data|
      next if data.species != @species || (data.unmega_form != form_simple && data.unmega_form != -2) || data.has_flag?("cantMegaEvolve")
      if data.mega_stone && hasItem?(data.mega_stone)
        ret = data.form
        break
      elsif data.mega_move && hasMove?(data.mega_move)
        ret = data.form
        break
      end
    end
    return ret   # form number, or 0 if no accessible Mega form
  end

  def getUnmegaForm
    return (mega?) ? species_data.unmega_form : -1
  end

  def hasMegaForm?
    megaForm = self.getMegaForm
    return megaForm > 0 && megaForm != form_simple
  end

  def mega?
    return (species_data.mega_stone || species_data.mega_move) ? true : false
  end

  def makeMega
    megaForm = self.getMegaForm
    if megaForm > 0
      @previous_form = self.form
      self.form = megaForm
    end
  end

  def makeUnmega
    unmegaForm = self.getUnmegaForm
    if unmegaForm >= 0
      self.form = unmegaForm
    elsif unmegaForm == -2 && @previous_form && @previous_form >= 0
      self.form = @previous_form  
    end
  end

  def megaName
    formName = species_data.form_name
    return (formName && !formName.empty?) ? formName : _INTL("Mega {1}", species_data.name)
  end

  # 0=default message, 1=Rayquaza message.
  def megaMessage
    megaForm = self.getMegaForm
    message_number = GameData::Species.get_species_form(@species, megaForm)&.mega_message
    return message_number || 0
  end

  #=============================================================================
  # Primal Reversion
  # NOTE: These are treated as form changes in Essentials.
  #=============================================================================
  def hasPrimalForm?
    v = MultipleForms.call("getPrimalForm", self)
    return !v.nil?
  end

  def primal?
    v = MultipleForms.call("getPrimalForm", self)
    return !v.nil? && v == @form
  end

  def makePrimal
    v = MultipleForms.call("getPrimalForm", self)
    self.form = v if !v.nil?
  end

  def makeUnprimal
    v = MultipleForms.call("getUnprimalForm", self)
    if !v.nil?
      self.form = v
    elsif primal?
      self.form = 0
    end
  end
end

