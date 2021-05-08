# frozen_string_literal: true

module Rsi
  class BaseLoader
    attr_accessor :base_url

    def initialize(options = {})
      @base_url = options[:base_url] || Rails.configuration.rsi.endpoint
    end

    private def fetch_remote(url)
      response = Typhoeus.get(url)

      case response.code
      when 403
        RsiRequestLog.find_or_create_by(url: url)
      when 200
        log_entry = RsiRequestLog.find_by(url: url, resolved: false)
        log_entry.update(resolved: true) if log_entry.present?
      end

      response
    end

    private def strip_name(name)
      name.gsub(/(?:AEGIS|Aegis|ARGO|Argo|ANVIL|Anvil|BANU|Banu|Crusader|CRUSADER|DRAKE|Drake|ESPERIA|Esperia|KRUGER|Kruger|Kruger Intergalactic|MISC|ORIGIN|Origin|RSI|TUMBRIL|Tumbril|VANDUUL|Vanduul|Xi'an|CNOU|Consolidated Outland)/, '').strip
    end

    private def nil_or_decimal(value)
      return if value.blank?

      value.to_d
    end

    private def nil_or_int(value)
      return if value.blank?

      value.to_i
    end

    private def prevent_extra_server_requests?
      # rubocop:disable Rails/EnvironmentVariableAccess
      Rails.env.test? || ENV['CI'] || Rails.configuration.rsi.load_from_file
      # rubocop:enable Rails/EnvironmentVariableAccess
    end
  end
end
