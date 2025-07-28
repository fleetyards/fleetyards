module Rsi
  class BaseLoader
    attr_accessor :base_url, :graphql_client

    def initialize(options = {})
      @base_url = options[:base_url] || Rails.configuration.rsi.endpoint
      @graphql_client = Graphlient::Client.new("#{base_url}/graphql")
    end

    private def fetch_remote(url)
      response = Typhoeus.get(url)

      case response.code
      when 403
        RsiRequestLog.find_or_create_by(url: url.split("?").first)
      when 200
        log_entry = RsiRequestLog.find_by(url: url.split("?").first, resolved: false)
        log_entry.update(resolved: true) if log_entry.present?
      end

      response
    end

    private def fetch_graphql(body)
      response = Typhoeus.post("#{base_url}/graphql", body:, headers: {"Content-Type" => "application/json"})

      case response.code
      when 403
        RsiRequestLog.find_or_create_by(url: "#{base_url}/graphql")
      when 200
        log_entry = RsiRequestLog.find_by(url: "#{base_url}/graphql", resolved: false)
        log_entry.update(resolved: true) if log_entry.present?

        JSON.parse(response.body)
      end

      response
    end

    private def strip_name(name)
      name.gsub(/(?:AEGIS|Aegis|ARGO|Argo|ANVIL|Anvil|BANU|Banu|Crusader|CRUSADER|DRAKE|Drake|ESPERIA|Esperia|KRUGER|Kruger|Kruger Intergalactic|MISC|MIRAI|Mirai|ORIGIN|Origin|RSI|TUMBRIL|Tumbril|VANDUUL|Vanduul|Xi'an|CNOU|Consolidated Outland)/, "").strip
    end

    private def nil_or_decimal(value)
      return if value.blank?

      value.to_d
    end

    private def nil_or_int(value)
      return if value.blank?

      value.to_i
    end
  end
end
