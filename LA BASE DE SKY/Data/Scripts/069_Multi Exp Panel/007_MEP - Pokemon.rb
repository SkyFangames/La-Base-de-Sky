#===============================================================================
# CREDITOS
# Swdfm
#===============================================================================
class Pokemon
  def exp_fraction_for_panel(mock_exp)
    g_rate     = growth_rate
    mock_level = g_rate.level_from_exp(mock_exp)
    return 100 if mock_level >= GameData::GrowthRate.max_level
    start_exp = g_rate.minimum_exp_for_level(mock_level)
    end_exp   = g_rate.minimum_exp_for_level(mock_level + 1)
    ret       = (mock_exp - start_exp).to_f / (end_exp - start_exp)
    return [mock_level, ret * 100]
  end
end
