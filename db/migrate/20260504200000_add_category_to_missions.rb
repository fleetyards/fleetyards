# frozen_string_literal: true

class AddCategoryToMissions < ActiveRecord::Migration[7.2]
  def change
    add_column :missions, :category, :integer, null: false, default: 0
    add_index :missions, [:fleet_id, :category]
  end
end
