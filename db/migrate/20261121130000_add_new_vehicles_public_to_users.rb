# frozen_string_literal: true

class AddNewVehiclesPublicToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :new_vehicles_public, :boolean, default: true, null: false
  end
end
