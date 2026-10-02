# frozen_string_literal: true

module Rsi
  # An organisation's row in RSI's org directory. The org page leaves out the
  # language and whether the org is recruiting; the directory's search has both.
  #
  # The search matches names and SIDs loosely -- "TEST" finds every org with
  # "test" anywhere in it -- so only the row whose symbol is the SID answers.
  class OrgSearch
    Result = Data.define(:status, :language, :recruiting, :roleplay, :commitment) do
      def self.unavailable(status)
        new(status:, language: nil, recruiting: nil, roleplay: nil, commitment: nil)
      end
    end

    PATH = "/api/orgs/getOrgs"

    def self.fetch(sid, base_url: Rails.configuration.rsi.endpoint)
      new(base_url:).fetch(sid)
    end

    def initialize(base_url:)
      @base_url = base_url
    end

    def fetch(sid)
      response = Typhoeus.post(
        "#{@base_url}#{PATH}",
        body: {search: sid, sort: "", page: 1, pagesize: 12}.to_json,
        headers: {"Content-Type" => "application/json"},
        timeout: 15
      )

      log_block(response)

      return Result.unavailable(:blocked) if response.code == 403
      return Result.unavailable(:failed) unless response.code == 200

      parse(response.body, sid)
    rescue JSON::ParserError
      Result.unavailable(:failed)
    end

    private def parse(body, sid)
      payload = JSON.parse(body)
      return Result.unavailable(:failed) unless payload["success"] == 1

      cell = Nokogiri::HTML.fragment(payload.dig("data", "html").to_s)
        .css(".org-cell")
        .find { |candidate| candidate.at_css(".symbol")&.text&.strip == sid }
      return Result.unavailable(:not_found) if cell.blank?

      info = cell.css(".infoitem").to_h do |item|
        [item.at_css(".label")&.text.to_s.strip.delete_suffix(":"), item.at_css(".value")&.text.to_s.strip]
      end

      Result.new(
        status: :ok,
        language: Languages.code_for(info["Lang"]),
        recruiting: yes_no(info["Recruiting"]),
        roleplay: yes_no(info["Role play"]),
        commitment: OrgAttributes.commitment_for(info["Commitment"])
      )
    end

    private def yes_no(value)
      {"yes" => true, "no" => false}[value.to_s.downcase]
    end

    private def log_block(response)
      url = "#{@base_url}#{PATH}"

      case response.code
      when 403
        RsiRequestLog.find_or_create_by(url:)
      when 200
        RsiRequestLog.find_by(url:, resolved: false)&.update(resolved: true)
      end
    end
  end
end
