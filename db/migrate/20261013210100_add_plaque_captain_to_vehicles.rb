# frozen_string_literal: true

class AddPlaqueCaptainToVehicles < ActiveRecord::Migration[8.1]
  def change
    add_column :vehicles, :plaque_captain, :string
  end
end
