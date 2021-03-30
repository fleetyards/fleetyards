class AddSpeedsToModels < ActiveRecord::Migration[6.0]
  def change
    add_column :models, :max_speed, :decimal, precision: 15, scale: 2
    add_column :models, :speed, :decimal, precision: 15, scale: 2
  end
end
