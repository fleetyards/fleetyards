# frozen_string_literal: true

module Rsi
  # An organisation's public page on the RSI website. Everything an org's
  # officers write about it -- the introduction, the history, the manifesto and
  # the charter -- is rendered into this one page, which is what makes it a
  # place to prove who runs the org.
  class OrgPage
    Result = Data.define(:status, :symbol, :text, :primary_activity, :secondary_activity, :commitment) do
      def self.unavailable(status)
        new(status:, symbol: nil, text: nil, primary_activity: nil, secondary_activity: nil, commitment: nil)
      end
    end

    # One log entry for every org page rather than one per SID: a block is the
    # site refusing us, not something about a particular org.
    LOG_URL_PATH = "/orgs"

    def self.fetch(sid, base_url: Rails.configuration.rsi.endpoint)
      new(base_url:).fetch(sid)
    end

    def initialize(base_url:)
      @base_url = base_url
    end

    def fetch(sid)
      response = Typhoeus.get(
        "#{@base_url}/en/orgs/#{ERB::Util.url_encode(sid)}",
        followlocation: true,
        timeout: 15
      )

      log_block(response)

      case response.code
      when 200
        parse(response.body)
      when 404
        Result.unavailable(:not_found)
      when 403
        Result.unavailable(:blocked)
      else
        Result.unavailable(:failed)
      end
    end

    private def parse(body)
      document = Nokogiri::HTML(body)

      Result.new(
        status: :ok,
        symbol: document.at_css("h1 .symbol")&.text&.strip,
        text: document.at_css("body")&.text.to_s,
        primary_activity: activity(document, "primary"),
        secondary_activity: activity(document, "secondary"),
        commitment: OrgAttributes.commitment_for(document.at_css(".heading .tags .commitment")&.text)
      )
    end

    # The focus is drawn as an icon, so its name is only in the image's alt text.
    private def activity(document, rank)
      OrgAttributes.activity_for(document.at_css(".heading .focus .#{rank} img")&.[]("alt"))
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
