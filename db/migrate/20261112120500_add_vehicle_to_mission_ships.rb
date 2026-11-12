# frozen_string_literal: true

class AddVehicleToMissionShips < ActiveRecord::Migration[8.1]
  def change
    add_reference :mission_ships, :vehicle, type: :uuid, null: true,
      foreign_key: {on_delete: :nullify}, index: true
  end
end
