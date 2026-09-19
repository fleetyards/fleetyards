# frozen_string_literal: true

# What a member lets their fleet see of the recipes they hold.
#
# Two positions rather than the three `ships_filter` has: there is no hangar
# group to narrow by, because a marker carries nothing to group on.
#
# Defaulting to sharing, like ships. No row exists until the member marks a
# recipe themselves, so somebody who never touches the feature shares nothing
# whatever the default says -- and a default of `hide` would leave every fleet
# page empty on the day it ships, which reads as broken rather than as private.
class AddBlueprintsFilterToFleetMemberships < ActiveRecord::Migration[8.1]
  def change
    add_column :fleet_memberships, :blueprints_filter, :integer, default: 0, null: false
  end
end
