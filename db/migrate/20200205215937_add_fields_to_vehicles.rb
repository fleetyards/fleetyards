# frozen_string_literal: true

class AddFieldsToVehicles < ActiveRecord::Migration[6.0]
  def change
    add_column :vehicles, :vehicle_id, :uuid
    add_column :vehicles, :loaner, :boolean, default: false
  end
end
