# frozen_string_literal: true

class AddPlaqueStyleToVehicles < ActiveRecord::Migration[8.1]
  def change
    add_column :vehicles, :plaque_style, :string
  end
end
