# frozen_string_literal: true

class AddRsiOrganizationsToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :rsi_organization_sids, :string, array: true, default: [], null: false
    add_column :users, :rsi_organizations_checked_at, :datetime
    # When a read was last tried, whatever RSI answered: the daily job schedules
    # by it, so a citizen RSI cannot answer for does not head every batch.
    add_column :users, :rsi_organizations_attempted_at, :datetime

    # The flags that exist today came from Citizen iD's claim, which named these
    # orgs. Seeding the lists from them keeps every shield up until the first
    # read; the check time stays empty so the daily job reads these users first.
    execute <<~SQL
      UPDATE users
      SET rsi_organization_sids = seeded.sids
      FROM (
        SELECT fleet_memberships.user_id, array_agg(DISTINCT fleets.rsi_sid) AS sids
        FROM fleet_memberships
        JOIN fleets ON fleets.id = fleet_memberships.fleet_id
        WHERE fleet_memberships.verified
          AND fleet_memberships.discarded_at IS NULL
          AND fleets.rsi_sid IS NOT NULL
        GROUP BY fleet_memberships.user_id
      ) AS seeded
      WHERE users.id = seeded.user_id AND users.rsi_handle_verified
    SQL

    # And the flags follow the lists from here on, by the same rule the model
    # applies. That only clears: a flag whose user no longer has a verified
    # handle, like the accounts a duplicate handle was taken from, has no list
    # to stand on.
    execute <<~SQL
      UPDATE fleet_memberships
      SET verified = FALSE, updated_at = NOW()
      FROM users, fleets
      WHERE users.id = fleet_memberships.user_id
        AND fleets.id = fleet_memberships.fleet_id
        AND fleet_memberships.verified
        AND NOT (
          users.rsi_handle_verified
          AND fleets.rsi_sid IS NOT NULL
          AND fleets.rsi_sid = ANY(users.rsi_organization_sids)
        )
    SQL
  end

  def down
    remove_column :users, :rsi_organizations_attempted_at
    remove_column :users, :rsi_organizations_checked_at
    remove_column :users, :rsi_organization_sids
  end
end
