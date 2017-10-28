class UpdateModelsFields < ActiveRecord::Migration[5.1]
  def change
    add_column :components, :slug, :string

    add_column :models, :pitch_max, :decimal, precision: 15, scale: 2, default: 0.0, null: false
    add_column :models, :yaw_max, :decimal, precision: 15, scale: 2, default: 0.0, null: false
    add_column :models, :roll_max, :decimal, precision: 15, scale: 2, default: 0.0, null: false
    add_column :models, :xaxis_acceleration, :decimal, precision: 15, scale: 2, default: 0.0, null: false
    add_column :models, :yaxis_acceleration, :decimal, precision: 15, scale: 2, default: 0.0, null: false
    add_column :models, :zaxis_acceleration, :decimal, precision: 15, scale: 2, default: 0.0, null: false

    reversible do
      change_column :models, :cargo, :decimal, precision: 15, scale: 2, default: 0.0, null: false
      change_column :models, :cruise_speed, :decimal, precision: 15, scale: 2, default: 0.0, null: false
      change_column :models, :afterburner_speed, :decimal, precision: 15, scale: 2, default: 0.0, null: false
      change_column :models, :scm_speed, :decimal, precision: 15, scale: 2, default: 0.0, null: false
    end
  end
end
