# frozen_string_literal: true

class AddPersonalInventoryToModels < ActiveRecord::Migration[8.1]
  def change
    add_column :models, :personal_inventory, :decimal, precision: 15, scale: 2
  end
end
