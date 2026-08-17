# frozen_string_literal: true

module Uex
  class CommodityMapper
    Result = Struct.new(:mapped, :updated, :unmatched, :unmapped) do
      def to_s
        "mapped=#{mapped} updated=#{updated} unmatched=#{unmatched.size} unmapped=#{unmapped.size}"
      end
    end

    def initialize(client: Uex::Client.new)
      @client = client
    end

    def run
      rows = require_rows(@client.commodities)
      matcher = Uex::CommodityMatcher.new
      claimed = {}

      rows.each do |row|
        commodity = matcher.match(row)
        next if commodity.blank?

        # Two UEX rows resolving to one commodity would otherwise overwrite each
        # other silently, leaving whichever came last. The second is reported as
        # unmatched so the collision is visible rather than arbitrary.
        if claimed.key?(commodity.id)
          matcher.misses << row
          next
        end

        claimed[commodity.id] = row
      end

      mapped, updated = persist(claimed)

      Result.new(
        mapped:, updated:,
        unmatched: matcher.misses,
        unmapped: Commodity.where(uex_id: nil).order(:name).to_a
      )
    end

    # The matcher hands back records carrying only the columns it matches on, so
    # the writes need the full rows -- fetched once rather than per match.
    private def persist(claimed)
      mapped = 0
      updated = 0

      Commodity.where(id: claimed.keys).find_each do |commodity|
        row = claimed[commodity.id]
        previously_mapped = commodity.uex_id.present?

        commodity.assign_attributes(uex_id: row["id"], uex_code: row["code"].presence)
        next unless commodity.changed?

        commodity.save!
        previously_mapped ? updated += 1 : mapped += 1
      end

      [mapped, updated]
    end

    # UEX answers an empty feed with HTTP 200 and status "ok". Taking that at
    # face value would read as "no commodity is tracked any more" and report
    # every one of ours as unmapped.
    private def require_rows(rows)
      return rows if rows.present?

      raise Uex::Error, "UEX returned no commodities; refusing to map against an empty snapshot"
    end

    # Deliberately free of the run counts: GithubIssueCreator dedupes on a
    # digest of the body, and a count that moves with the feed would open a
    # fresh issue on every run.
    def self.github_issue_body(result)
      lines = ["## Commodities Without a UEX Mapping (#{result.unmapped.size})", ""]
      lines << "These commodities carry no `uex_id`, so no price can be joined to them."
      lines << "If UEX lists an equivalent, add it to `Uex::CommodityMatcher::MAPPINGS`;"
      lines << "several are mission crates and harvestables UEX does not track at all."
      lines << ""

      result.unmapped.each do |commodity|
        lines << "- **#{commodity.name}** — `#{commodity.sc_key}`"
      end

      lines.join("\n")
    end
  end
end
