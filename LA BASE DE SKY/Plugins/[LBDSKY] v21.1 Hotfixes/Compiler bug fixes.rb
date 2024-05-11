#===============================================================================
# Made some unhelpful error messages when compiling more helpful.
#===============================================================================
module Compiler
  module_function

  def cast_csv_value(value, schema, enumer = nil)
    case schema.downcase
    when "i"   # Integer
      if !value || !value[/^\-?\d+$/]
        raise _INTL("Campo '{1}' no es un entero.", value) + "\n" + FileLineData.linereport
      end
      return value.to_i
    when "u"   # Positive integer or zero
      if !value || !value[/^\d+$/]
        raise _INTL("Campo '{1}' no es un natural o 0.", value) + "\n" + FileLineData.linereport
      end
      return value.to_i
    when "v"   # Positive integer
      if !value || !value[/^\d+$/]
        raise _INTL("Campo '{1}' no es un natural.", value) + "\n" + FileLineData.linereport
      end
      if value.to_i == 0
        raise _INTL("Campo '{1}' debe ser mayor a 0.", value) + "\n" + FileLineData.linereport
      end
      return value.to_i
    when "x"   # Hexadecimal number
      if !value || !value[/^[A-F0-9]+$/i]
        raise _INTL("Campo '{1}' no es un número hexadecimal.", value) + "\n" + FileLineData.linereport
      end
      return value.hex
    when "f"   # Floating point number
      if !value || !value[/^\-?^\d*\.?\d*$/]
        raise _INTL("Campo '{1}' no es un número.", value) + "\n" + FileLineData.linereport
      end
      return value.to_f
    when "b"   # Boolean
      return true if value && value[/^(?:1|TRUE|YES|Y)$/i]
      return false if value && value[/^(?:0|FALSE|NO|N)$/i]
      raise _INTL("Campo '{1}' no es un valor booleano (true, false, 1, 0).", value) + "\n" + FileLineData.linereport
    when "n"   # Name
      if !value || !value[/^(?![0-9])\w+$/]
        raise _INTL("Campo '{1}' solo debe contener letras, digitos y\nguión bajo y no puede comenzar con un número.", value) + "\n" + FileLineData.linereport
      end
    when "s"   # String
    when "q"   # Unformatted text
    when "m"   # Symbol
      if !value || !value[/^(?![0-9])\w+$/]
        raise _INTL("Campo '{1}' solo debe contener letras, digitos y\nguión bajo y no puede comenzar con un número.", value) + "\n" + FileLineData.linereport
      end
      return value.to_sym
    when "e"   # Enumerable
      return checkEnumField(value, enumer)
    when "y"   # Enumerable or integer
      return value.to_i if value && value[/^\-?\d+$/]
      return checkEnumField(value, enumer)
    end
    return value
  end

  def validate_all_compiled_types
    type_names = []
    GameData::Type.each do |type|
      # Ensure all weaknesses/resistances/immunities are valid types
      type.weaknesses.each do |other_type|
        next if GameData::Type.exists?(other_type)
        raise _INTL("'{1}' no es de un tipo definido (tipo {2}, Debilidad).", other_type.to_s, type.id)
      end
      type.resistances.each do |other_type|
        next if GameData::Type.exists?(other_type)
        raise _INTL("'{1}' no es de un tipo definido (tipo {2}, Resistencias).", other_type.to_s, type.id)
      end
      type.immunities.each do |other_type|
        next if GameData::Type.exists?(other_type)
        raise _INTL("'{1}' no es de un tipo definido (tipo {2}, Inmunidades).", other_type.to_s, type.id)
      end
      # Get type names for translating
      type_names.push(type.real_name)
    end
    MessageTypes.setMessagesAsHash(MessageTypes::TYPE_NAMES, type_names)
  end
end

#===============================================================================
# Fixed being unable to write values to PBS files that were enumerated to
# something other than a number.
# Fixed the Compiler not writing some enumerables correctly when writing PBS
# files.
#===============================================================================
module Compiler
  module_function

  def pbWriteCsvRecord(record, file, schema)
    rec = (record.is_a?(Array)) ? record.flatten : [record]
    start = (["*", "^"].include?(schema[1][0, 1])) ? 1 : 0
    index = -1
    loop do
      (start...schema[1].length).each do |i|
        index += 1
        value = rec[index]
        if schema[1][i, 1][/[A-Z]/]   # Optional
          # Check the rest of the values for non-nil things
          later_value_found = false
          (index...rec.length).each do |j|
            later_value_found = true if !rec[j].nil?
            break if later_value_found
          end
          if !later_value_found
            start = -1
            break
          end
        end
        file.write(",") if index > 0
        next if value.nil?
        case schema[1][i, 1]
        when "e", "E"   # Enumerable
          enumer = schema[2 + i - start]
          case enumer
          when Array
            file.write((value.is_a?(Integer) && !enumer[value].nil?) ? enumer[value] : value)
          when Symbol, String
            if GameData.const_defined?(enumer.to_sym)
              mod = GameData.const_get(enumer.to_sym)
              file.write(mod.get(value).id.to_s)
            else
              mod = Object.const_get(enumer.to_sym)
              file.write(getConstantName(mod, value))
            end
          when Module
            file.write(getConstantName(enumer, value))
          when Hash
            if value.is_a?(String)
              file.write(value)
            else
              enumer.each_key do |key|
                next if enumer[key] != value
                file.write(key)
                break
              end
            end
          end
        when "y", "Y"   # Enumerable or integer
          enumer = schema[2 + i - start]
          case enumer
          when Array
            file.write((value.is_a?(Integer) && !enumer[value].nil?) ? enumer[value] : value)
          when Symbol, String
            if !Kernel.const_defined?(enumer.to_sym) && GameData.const_defined?(enumer.to_sym)
              mod = GameData.const_get(enumer.to_sym)
              if mod.exists?(value)
                file.write(mod.get(value).id.to_s)
              else
                file.write(value.to_s)
              end
            else
              mod = Object.const_get(enumer.to_sym)
              file.write(getConstantNameOrValue(mod, value))
            end
          when Module
            file.write(getConstantNameOrValue(enumer, value))
          when Hash
            if value.is_a?(String)
              file.write(value)
            else
              has_enum = false
              enumer.each_key do |key|
                next if enumer[key] != value
                file.write(key)
                has_enum = true
                break
              end
              file.write(value) if !has_enum
            end
          end
        else
          if value.is_a?(String)
            file.write((schema[1][i, 1].downcase == "q") ? value : csvQuote(value))
          elsif value.is_a?(Symbol)
            file.write(csvQuote(value.to_s))
          elsif value == true
            file.write("true")
          elsif value == false
            file.write("false")
          else
            file.write(value.inspect)
          end
        end
      end
      break if start > 0 && index >= rec.length - 1
      break if start <= 0
    end
    return record
  end
end
