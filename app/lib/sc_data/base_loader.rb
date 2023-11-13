module ScData
  class BaseLoader
    def s3_base_url
      [
        Rails.configuration.app.s3_endpoint,
        Rails.configuration.app.s3_sc_data_bucket
      ].join("/")
    end

    private def load_from_export(path)
      response = Typhoeus.get("#{s3_base_url}/#{path}")

      return unless response.success?

      begin
        JSON.parse(response.body)
      rescue JSON::ParserError => e
        Sentry.capture_exception(e)
        Rails.logger.error "SC Data could not be parsed: #{response.body}"
        nil
      end
    end
  end
end
