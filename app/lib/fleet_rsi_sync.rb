# frozen_string_literal: true

# Copies what a verified fleet's RSI org says about itself -- its activities,
# language, commitment, role play and whether it is recruiting -- onto the
# fleet, for the fleet directory to filter by.
#
# RSI is where the org's officers keep these, so the fleet does not ask for
# them a second time. A source that cannot be read leaves its columns as they
# were: an org page RSI fails to serve has not stopped recruiting, and a block
# writes none of them.
class FleetRsiSync
  attr_reader :fleet

  def initialize(fleet)
    @fleet = fleet
  end

  def run
    return :skipped unless fleet.rsi_verified?

    sid = fleet.rsi_sid
    fleet.update_columns(rsi_sync_attempted_at: Time.current) # rubocop:disable Rails/SkipsModelValidations

    page = Rsi::OrgPage.fetch(sid)
    search = Rsi::OrgSearch.fetch(sid)
    return :blocked if [page.status, search.status].include?(:blocked)

    columns = {}

    if page.status == :ok && page.symbol == sid
      columns.merge!(
        primary_activity: page.primary_activity,
        secondary_activity: (page.secondary_activity unless page.secondary_activity == page.primary_activity),
        commitment: page.commitment
      )
    end

    if search.status == :ok
      columns.merge!(language: search.language, recruiting: search.recruiting, roleplay: search.roleplay)
      columns[:commitment] ||= search.commitment
    end

    return :failed if columns.empty?

    write(sid, columns)
  end

  # Under the lock and against the SID it asked about: a sync that outlived a
  # revoke or a new SID describes an org the fleet no longer names.
  private def write(sid, columns)
    Fleet.transaction do
      fleet.lock!

      next :stale unless fleet.rsi_verified? && fleet.rsi_sid == sid

      now = Time.current
      changed = columns.any? { |column, value| fleet[column] != value }

      # rubocop:disable Rails/SkipsModelValidations
      fleet.update_columns(**columns, rsi_synced_at: now, **(changed ? {updated_at: now} : {}))
      # rubocop:enable Rails/SkipsModelValidations

      :synced
    end
  end
end
