# frozen_string_literal: true

module Rsi
  # The orgs a citizen is in, from their public organisations page. The page is
  # RSI's record of the membership: the citizen can hide an org from it but not
  # add one, so once the handle is proved to be the user's, the SIDs on it are
  # the orgs that user is in.
  class CitizenOrganizationsPage
    Result = Data.define(:status, :sids)

    # Only what anybody can see counts, as with Citizen iD's public-orgs claim.
    # A redacted or hidden org keeps its block but not its details.
    VISIBLE = ".box-content.org.visibility-V"

    SID_LABEL = "Spectrum Identification (SID)"

    # The same entry the citizen page logs under: a block is the site refusing
    # us, whichever of a citizen's pages was asked for.
    LOG_URL_PATH = CitizenPage::LOG_URL_PATH

    def self.fetch(handle, base_url: Rails.configuration.rsi.endpoint)
      new(base_url:).fetch(handle)
    end

    def initialize(base_url:)
      @base_url = base_url
    end

    def fetch(handle)
      response = Typhoeus.get(
        "#{@base_url}/en/citizens/#{ERB::Util.url_encode(handle)}/organizations",
        followlocation: true,
        timeout: 15
      )

      log_block(response)

      case response.code
      when 200
        Result.new(status: :ok, sids: parse(response.body))
      when 404
        Result.new(status: :not_found, sids: [])
      when 403
        Result.new(status: :blocked, sids: [])
      else
        Result.new(status: :failed, sids: [])
      end
    end

    private def parse(body)
      Nokogiri::HTML(body).css(VISIBLE).filter_map { |org|
        org.css(".entry").find { |entry| entry.at_css(".label")&.text&.strip == SID_LABEL }
          &.at_css(".value")&.text&.strip.presence
      }.uniq
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
