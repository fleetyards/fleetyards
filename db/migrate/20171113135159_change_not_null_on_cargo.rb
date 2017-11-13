class ChangeNotNullOnCargo < ActiveRecord::Migration[5.1]
  def up
    change_column :models, :cargo, :decimal, precision: 15, scale: 2, default: nil, null: true
    change_column :models, :price, :decimal, precision: 15, scale: 2, default: nil, null: true
    change_column :models, :scm_speed, :decimal, precision: 15, scale: 2, default: nil, null: true
    change_column :models, :afterburner_speed, :decimal, precision: 15, scale: 2, default: nil, null: true
    change_column :models, :cruise_speed, :decimal, precision: 15, scale: 2, default: nil, null: true
    change_column :models, :min_crew, :integer, default: nil, null: true
    change_column :models, :max_crew, :integer, default: nil, null: true
    change_column :models, :pitch_max, :decimal, precision: 15, scale: 2, default: nil, null: true
    change_column :models, :yaw_max, :decimal, precision: 15, scale: 2, default: nil, null: true
    change_column :models, :roll_max, :decimal, precision: 15, scale: 2, default: nil, null: true
    change_column :models, :xaxis_acceleration, :decimal, precision: 15, scale: 2, default: nil, null: true
    change_column :models, :yaxis_acceleration, :decimal, precision: 15, scale: 2, default: nil, null: true
    change_column :models, :zaxis_acceleration, :decimal, precision: 15, scale: 2, default: nil, null: true

    change_column :model_additions, :cargo, :decimal, precision: 15, scale: 2, default: nil, null: true
    change_column :model_additions, :net_cargo, :decimal, precision: 15, scale: 2, default: nil, null: true
    change_column :model_additions, :scm_speed, :decimal, precision: 15, scale: 2, default: nil, null: true
    change_column :model_additions, :afterburner_speed, :decimal, precision: 15, scale: 2, default: nil, null: true
    change_column :model_additions, :cruise_speed, :decimal, precision: 15, scale: 2, default: nil, null: true
    change_column :model_additions, :min_crew, :integer, default: nil, null: true
    change_column :model_additions, :max_crew, :integer, default: nil, null: true
  end

  def down
  end
end
