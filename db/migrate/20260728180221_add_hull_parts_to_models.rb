class AddHullPartsToModels < ActiveRecord::Migration[8.1]
  def change
    add_column :models, :hull_parts, :jsonb
  end
end
