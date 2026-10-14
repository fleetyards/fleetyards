# frozen_string_literal: true

class AddHiddenByUserToVehicles < ActiveRecord::Migration[8.1]
  def change
    add_column :vehicles, :hidden_by_user, :boolean, default: false, null: false
  end
end
