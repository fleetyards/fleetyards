# frozen_string_literal: true

class AddSettledAtToFleetContracts < ActiveRecord::Migration[8.1]
  def change
    add_column :fleet_contracts, :settled_at, :datetime
  end
end
