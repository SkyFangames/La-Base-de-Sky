#===============================================================================
#  Extensions for the `Hash` data types
#===============================================================================
class ::Hash
  #-----------------------------------------------------------------------------
  #  checks if key has a value
  #-----------------------------------------------------------------------------
  def try_key?(*args)
    args.each do |key|
      return false unless key?(key) && value(key)
    end

    true
  end

  def has_key?(*args)
    try_key?(*args)
  end
  #-----------------------------------------------------------------------------
  #  gets value associated with key
  #-----------------------------------------------------------------------------
  def value(key)
    self[key]
  end

  #-----------------------------------------------------------------------------
  #  gets value associated with key (safe method)
  #-----------------------------------------------------------------------------
  def get_key(key)
    return self.has_key?(key) ? self[key] : nil
  end
  #-----------------------------------------------------------------------------
  #  merges and replace current hash
  #-----------------------------------------------------------------------------
  def deep_merge!(hash)
    # failsafe
    return if !hash.is_a?(Hash)
    for key in hash.keys
      if self[key].is_a?(Hash)
        self[key].deep_merge!(hash[key])
      else
        self[key] = hash[key]
      end
    end
  end
  #-----------------------------------------------------------------------------
  #  merges two hashes
  #-----------------------------------------------------------------------------
  def deep_merge(hash)
    h = self.clone
    # failsafe
    return h if !hash.is_a?(Hash)
    for key in hash.keys
      if self[key].is_a?(Hash)
        h.deep_merge!(hash[key])
      else
        h = hash[key]
      end
    end
    return h
  end
  #-----------------------------------------------------------------------------
  #  merges many hashes into self
  #-----------------------------------------------------------------------------
  def merge_many(*hashes)
    tap do |output|
      hashes.each do |hash|
        hash.each do |key, value|
          output[key] = value
        end
      end
    end
  end
  #-----------------------------------------------------------------------------
  def blank?
    keys.empty?
  end

  def present?
    !blank?
  end
end
