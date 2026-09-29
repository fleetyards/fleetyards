# frozen_string_literal: true

# Ship views used to count page views and now count visits. The daily job only
# rebuilds its last two days, so the rest of the trending window would keep
# summing the old unit alongside the new one. Every day whose events are still
# retained is rebuilt once; older days have nothing left to rebuild from.
class RebuildShipViewsPerVisit < ActiveRecord::Migration[8.1]
  def up
    MetricsJob.new.track_ship_views(since: MetricsJob.cleanup_floor)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
