# frozen_string_literal: true

# Which fleet a contribution is *for*. A contribution already says who paid; it
# has never said what the money buys, and the entitlement work needs both.
#
# Nullable because most contributions have no nomination and never will: a
# supporter who does not run a fleet still supports the site, and an unlinked
# row has nobody to make the choice.
class AddFleetToSupporterContributions < ActiveRecord::Migration[8.1]
  def change
    add_reference :supporter_contributions, :fleet,
      type: :uuid,
      null: true,
      index: {where: "fleet_id IS NOT NULL"},
      foreign_key: true
  end
end
