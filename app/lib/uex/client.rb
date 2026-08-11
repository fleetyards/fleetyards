# frozen_string_literal: true

module Uex
  class Client
    def initialize(base_url: Rails.configuration.uex.endpoint)
      @base_url = base_url.to_s.chomp("/")
    end

    def vehicles
      get("vehicles")
    end

    def vehicle_purchase_prices
      get("vehicles_purchases_prices_all")
    end

    def vehicle_rental_prices
      get("vehicles_rentals_prices_all")
    end

    def terminals
      get("terminals")
    end

    private def get(path)
      # UEX answers 403 to requests without a User-Agent, so it is not optional.
      response = Typhoeus.get(
        "#{@base_url}/#{path}/",
        headers: {"User-Agent" => user_agent, "Accept" => "application/json"}
      )

      raise Uex::Error, "UEX API error #{response.code} for #{path}" unless response.success?

      payload = JSON.parse(response.body)

      raise Uex::Error, "UEX API returned status #{payload["status"].inspect} for #{path}" if payload["status"] != "ok"

      Array(payload["data"])
    rescue JSON::ParserError => e
      raise Uex::Error, "UEX API returned invalid JSON for #{path}: #{e.message}"
    end

    private def user_agent
      "#{Rails.configuration.app.name} (#{Fleetyards::VERSION}; +https://#{Rails.configuration.app.domain})"
    end
  end
end
