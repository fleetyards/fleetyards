class AddScDataFieldsToModels < ActiveRecord::Migration[7.1]
  def change
    add_column :models, :scm_speed_boosted, :decimal, precision: 15, scale: 2
    add_column :models, :pitch_boosted, :decimal, precision: 15, scale: 2
    add_column :models, :yaw_boosted, :decimal, precision: 15, scale: 2
    add_column :models, :reverse_speed_boosted, :decimal, precision: 15, scale: 2
    add_column :models, :roll_boosted, :decimal, precision: 15, scale: 2
  end
end
