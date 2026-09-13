# frozen_string_literal: true

# Opening a fleet's ships, its stats and its roster to the fleets it flies
# alongside, without opening them to the internet.
#
# The same two-boolean spelling as the user side -- see
# `AddFriendVisibilityToUsers` for why a sibling column rather than an enum.
# `allies_fleet_members` has no `public_` twin, because a fleet's roster has
# never been published at all: `Api::V1::Public::FleetStatsController#members`
# answers with a count, not a list. So this is the first column that opens it,
# and it opens it only to an ally.
class AddAllyVisibilityToFleets < ActiveRecord::Migration[8.1]
  def change
    add_column :fleets, :allies_fleet, :boolean, null: false, default: false
    add_column :fleets, :allies_fleet_stats, :boolean, null: false, default: false
    add_column :fleets, :allies_fleet_members, :boolean, null: false, default: false
  end
end
