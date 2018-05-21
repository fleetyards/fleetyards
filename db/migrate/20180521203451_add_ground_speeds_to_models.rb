class AddGroundSpeedsToModels < ActiveRecord::Migration[5.2]
  def change
    add_column :models, :ground_speed, :decimal, precision: 15, scale: 2
    add_column :models, :afterburner_ground_speed, :decimal, precision: 15, scale: 2
  end
end
