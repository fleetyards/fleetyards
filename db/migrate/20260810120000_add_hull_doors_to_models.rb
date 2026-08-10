class AddHullDoorsToModels < ActiveRecord::Migration[8.1]
  def change
    add_column :models, :hull_doors, :jsonb
  end
end
