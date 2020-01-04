# frozen_string_literal: true

module RSI
  class BaseLoader
    attr_accessor :base_url

    def initialize(options = {})
      @base_url = options[:base_url] || Rails.application.secrets[:rsi_endpoint]
    end

    private def fetch_remote(url)
      response = Typhoeus.get(url)

      AdminMailer.notify_block.deliver_later if response.code == 403

      response
    end

    private def strip_name(name)
      name.gsub(/(?:AEGIS|Aegis|ARGO|Argo|ANVIL|Anvil|BANU|Banu|Crusader|CRUSADER|DRAKE|Drake|ESPERIA|Esperia|KRUGER|Kruger|Kruger Intergalactic|MISC|ORIGIN|Origin|RSI|TUMBRIL|Tumbril|VANDUUL|Vanduul|Xi'an|Consolidated Outland)/, '').strip
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
end
