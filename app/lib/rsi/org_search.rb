# frozen_string_literal: true

module Rsi
  # An organisation's row in RSI's org directory. The org page leaves out the
  # language, whether the org is recruiting and how many members it has; the
  # directory's search has all three.
  #
  # The search matches names and SIDs loosely -- "TEST" finds every org with
  # "test" anywhere in it -- so only the row whose symbol is the SID answers.
  # RSI ranks by its own relevance and serves 32 rows a page whatever is
  # asked for, so a short SID's own org can sit pages in: the search walks a
  # few of them before it gives up.
  class OrgSearch
    Result = Data.define(:status, :language, :recruiting, :roleplay, :commitment, :member_count) do
      def self.unavailable(status)
        new(status:, language: nil, recruiting: nil, roleplay: nil, commitment: nil, member_count: nil)
      end
    end

    PATH = "/api/orgs/getOrgs"

    MAX_PAGES = 5

    def self.fetch(sid, base_url: Rails.configuration.rsi.endpoint)
      new(base_url:).fetch(sid)
    end

    def initialize(base_url:)
      @base_url = base_url
    end

    def fetch(sid)
      (1..MAX_PAGES).each do |page|
        cells = fetch_page(sid, page)
        return cells if cells.is_a?(Result)
        break if cells.empty?

        cell = cells.find { |candidate| candidate.at_css(".symbol")&.text&.strip == sid }
        return parse(cell) if cell.present?
      end

      Result.unavailable(:not_found)
    end

    # The page's org cells, or a Result when RSI did not answer with any.
    private def fetch_page(sid, page)
      response = Typhoeus.post(
        "#{@base_url}#{PATH}",
        body: {search: sid, sort: "", page:, pagesize: 32}.to_json,
        headers: {"Content-Type" => "application/json"},
        timeout: 15
      )

      log_block(response)

      return Result.unavailable(:blocked) if response.code == 403
      return Result.unavailable(:failed) unless response.code == 200

      payload = JSON.parse(response.body)
      return Result.unavailable(:failed) unless payload["success"] == 1

      Nokogiri::HTML.fragment(payload.dig("data", "html").to_s).css(".org-cell").to_a
    rescue JSON::ParserError
      Result.unavailable(:failed)
    end

    private def parse(cell)
      info = cell.css(".infoitem").to_h do |item|
        [item.at_css(".label")&.text.to_s.strip.delete_suffix(":"), item.at_css(".value")&.text.to_s.strip]
      end

      Result.new(
        status: :ok,
        language: Languages.code_for(info["Lang"]),
        recruiting: yes_no(info["Recruiting"]),
        roleplay: yes_no(info["Role play"]),
        commitment: OrgAttributes.commitment_for(info["Commitment"]),
        member_count: Integer(info["Members"], exception: false)
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
