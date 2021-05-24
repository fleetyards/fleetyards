# frozen_string_literal: true

module ScData
  class BaseLoader
    attr_accessor :base_url

    def initialize
      self.base_url = 'https://scunpacked.com/api/v2'
    end

    private def fetch_remote(path)
      Typhoeus.get("#{base_url}/#{path}")
    end

    private def parse_json_response(response)
      JSON.parse(response.body)
    rescue JSON::ParserError => e
      Raven.capture_exception(e)
      Rails.logger.error "SC Data could not be parsed: #{response.body}"
      nil
    end
  end
end
