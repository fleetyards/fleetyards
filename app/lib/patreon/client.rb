# frozen_string_literal: true

module Patreon
  class Client
    BASE = "https://www.patreon.com/api/oauth2/v2"
    MAX_PAGES = 50

    MEMBER_FIELDS = %w[
      full_name patron_status currently_entitled_amount_cents
      pledge_relationship_start last_charge_date last_charge_status pledge_amount_cents
    ].join(",")

    def initialize(token: Rails.application.credentials.dig(:patreon, :access_token))
      @token = token
    end

    def members(campaign_id)
      Enumerator.new do |yielder|
        url = "#{BASE}/campaigns/#{campaign_id}/members?#{query}"
        pages = 0
        while url && pages < MAX_PAGES
          payload = get(url)
          Array(payload["data"]).each { |member| yielder << normalize(member, payload["included"]) }
          url = payload.dig("links", "next")
          pages += 1
        end

        # A remaining `url` here means we stopped at the page cap, not at the end
        # of the feed — surface it so members past the cap aren't silently dropped.
        if url
          message = "Patreon members feed exceeded MAX_PAGES (#{MAX_PAGES}); members beyond #{MAX_PAGES * 100} were not synced"
          Rails.logger.warn("[Patreon::Client] #{message}")
          Appsignal.report_error(Patreon::Error.new(message))
        end
      end
    end

    private

    def query
      URI.encode_www_form(
        "include" => "user",
        "fields[member]" => MEMBER_FIELDS,
        "fields[user]" => "vanity",
        "page[count]" => 100
      )
    end

    def get(url)
      response = Typhoeus.get(url, headers: {"Authorization" => "Bearer #{@token}"})
      raise Patreon::Error, "Patreon API error #{response.code}: #{response.body}" unless response.success?

      JSON.parse(response.body)
    rescue JSON::ParserError => e
      raise Patreon::Error, "Patreon API returned invalid JSON: #{e.message}"
    end

    def normalize(member, included)
      attrs = member["attributes"] || {}
      user = find_user(member, included)

      Patreon::Member.new(
        id: member["id"],
        name: attrs["full_name"].presence || user&.dig("attributes", "vanity"),
        status: attrs["patron_status"],
        amount_cents: entitled_or_pledge(attrs),
        pledged_at: parse_date(attrs["pledge_relationship_start"]),
        last_charge_date: parse_date(attrs["last_charge_date"])
      )
    end

    def entitled_or_pledge(attrs)
      attrs["currently_entitled_amount_cents"].to_i.nonzero? || attrs["pledge_amount_cents"].to_i
    end

    def find_user(member, included)
      user_id = member.dig("relationships", "user", "data", "id")
      return nil if user_id.blank?

      Array(included).find { |entry| entry["type"] == "user" && entry["id"] == user_id }
    end

    def parse_date(value)
      return nil if value.blank?

      Date.parse(value)
    rescue ArgumentError
      nil
    end
  end
end
