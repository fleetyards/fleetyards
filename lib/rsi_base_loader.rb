# frozen_string_literal: true

class RsiBaseLoader
  attr_accessor :base_url

  def initialize(options = {})
    @base_url = options[:base_url] || 'https://robertsspaceindustries.com'
  end

  private def strip_name(name)
    name.gsub(/^\s*(?:AEGIS|Aegis|ANVIL|Anvil|BANU|Banu|DRAKE|Drake|ESPERIA|Esperia|KRUGER|Kruger|MISC|ORIGIN|Origin|RSI|TUMBRIL|Tumbril|VANDUUL|Vanduul|Xi'an)[^a-zA-Z0-9]+/, '')
  end

  private def nil_or_float(value)
    return if value.blank?

    value.to_f
  end

  private def nil_or_int(value)
    return if value.blank?

    value.to_i
  end
end
