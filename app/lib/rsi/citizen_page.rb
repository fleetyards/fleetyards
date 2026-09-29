# frozen_string_literal: true

module Rsi
  # A citizen's public dossier on the RSI website. The bio on it is written by
  # the account holder alone, which is what makes it a place to prove who owns
  # the handle. The rest of the page is not: the main org's name, for one, is
  # its officers' to edit.
  class CitizenPage
    Result = Data.define(:status, :handle, :bio)

    # One log entry for every citizen page rather than one per handle: a block
    # is the site refusing us, not something about a particular citizen.
    LOG_URL_PATH = "/citizens"

    def self.fetch(handle, base_url: Rails.configuration.rsi.endpoint)
      new(base_url:).fetch(handle)
    end

    def initialize(base_url:)
      @base_url = base_url
    end

    def fetch(handle)
      response = Typhoeus.get(
        "#{@base_url}/en/citizens/#{ERB::Util.url_encode(handle)}",
        followlocation: true,
        timeout: 15
      )

      log_block(response)

      case response.code
      when 200
        parse(response.body)
      when 404
        Result.new(status: :not_found, handle: nil, bio: nil)
      else
        Result.new(status: :failed, handle: nil, bio: nil)
      end
    end

    private def parse(body)
      document = Nokogiri::HTML(body)

      handle = document.css(".profile .info .entry").find { |entry|
        entry.at_css(".label")&.text&.strip == "Handle name"
      }&.at_css(".value")&.text&.strip

      Result.new(
        status: :ok,
        handle:,
        bio: document.at_css(".entry.bio .value")&.text.to_s
      )
    end

    private def log_block(response)
      url = "#{@base_url}#{LOG_URL_PATH}"

      case response.code
      when 403
        RsiRequestLog.find_or_create_by(url:)
      when 200
        RsiRequestLog.find_by(url:, resolved: false)&.update(resolved: true)
      end
    end
  end
end
