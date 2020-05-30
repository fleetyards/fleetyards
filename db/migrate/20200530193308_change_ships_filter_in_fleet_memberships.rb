class ChangeShipsFilterInFleetMemberships < ActiveRecord::Migration[6.0]
  def change
    change_column_default :fleet_memberships, :ships_filter, from: nil, to: 0
  end
end
