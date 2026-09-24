# frozen_string_literal: true

# The entitlement record: a row is the grant, `ended_at` is the revocation, and
# both are dated, so the history is the table rather than a reconstruction of
# one. Deliberately not a feature flag -- a deploy prunes gate values, a gate
# can only grant, and neither can express a revocation.
class CreateFleetSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :fleet_subscriptions, id: :uuid do |t|
      t.references :fleet, type: :uuid, null: false,
        foreign_key: {on_delete: :cascade}, index: false

      t.date :started_at, null: false
      t.date :ended_at

      # What granted this, not what platform the money came from -- the
      # contribution already answers that, and a comp has no platform at all.
      # Named after `SupporterContribution#linked_via`, which records the rule
      # that linked a row for the same reason.
      t.string :granted_via, null: false, default: "manual"

      # Null is what makes a comp identifiable, and what `Subscriptions::Sync`
      # keys on: it closes only the subscription it seeded. Nullify rather than
      # restrict, so deleting a contribution can never be blocked by this.
      t.references :supporter_contribution, type: :uuid, null: true,
        foreign_key: {on_delete: :nullify},
        index: {where: "supporter_contribution_id IS NOT NULL"}

      t.text :note

      t.timestamps
    end

    # One open subscription per fleet, in the database rather than in a
    # validation: two requests racing both pass a validation and both write.
    add_index :fleet_subscriptions, :fleet_id,
      unique: true,
      where: "ended_at IS NULL",
      name: "index_fleet_subscriptions_on_active_fleet"

    # Every read is "is this fleet subscribed on this date", so the dates ride
    # with the fleet rather than being a separate lookup.
    add_index :fleet_subscriptions, [:fleet_id, :started_at, :ended_at]
  end
end
