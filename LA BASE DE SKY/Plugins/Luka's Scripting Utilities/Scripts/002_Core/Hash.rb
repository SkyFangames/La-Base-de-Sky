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
  #-----------------------------------------------------------------------------
  #  gets value associated with key
  #-----------------------------------------------------------------------------
  def value(key)
    self[key]
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
