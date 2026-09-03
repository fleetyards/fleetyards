# frozen_string_literal: true

class AddStatusTimestampsToFleetEvents < ActiveRecord::Migration[8.1]
  def change
    # The AASM block on FleetEvent has always declared `timestamps: true`, but
    # aasm only writes `#{state}_at` where a setter exists -- it checks
    # `respond_to?` and skips silently otherwise -- so every transition the
    # event went through went unrecorded. FleetMembership and Import, the two
    # other state machines here, both carry a column per target state.
    add_column :fleet_events, :open_at, :datetime
    add_column :fleet_events, :locked_at, :datetime
    add_column :fleet_events, :active_at, :datetime
    add_column :fleet_events, :completed_at, :datetime
    add_column :fleet_events, :cancelled_at, :datetime

    # `open_at` moves every time signups are unlocked, which is the right
    # meaning for "open since" and the wrong one for "when was this announced".
    # Lead time needs a stamp that only ever gets set once.
    add_column :fleet_events, :published_at, :datetime
  end
end
