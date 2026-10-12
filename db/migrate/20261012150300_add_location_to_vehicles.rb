# frozen_string_literal: true

class AddLocationToVehicles < ActiveRecord::Migration[8.1]
  def change
    add_column :vehicles, :location, :string
    add_reference :vehicles, :location, type: :uuid, foreign_key: {on_delete: :nullify}, index: true
  end
end
