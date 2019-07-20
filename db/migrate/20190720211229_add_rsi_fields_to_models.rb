class AddRsiFieldsToModels < ActiveRecord::Migration[5.2]
  def change
    add_column :models, :rsi_max_crew, :integer
    add_column :models, :rsi_min_crew, :integer
    add_column :models, :rsi_scm_speed, :decimal, precision: 15, scale: 2
    add_column :models, :rsi_afterburner_speed, :decimal, precision: 15, scale: 2
    add_column :models, :rsi_pitch_max, :decimal, precision: 15, scale: 2
    add_column :models, :rsi_yaw_max, :decimal, precision: 15, scale: 2
    add_column :models, :rsi_roll_max, :decimal, precision: 15, scale: 2
    add_column :models, :rsi_xaxis_acceleration, :decimal, precision: 15, scale: 2
    add_column :models, :rsi_yaxis_acceleration, :decimal, precision: 15, scale: 2
    add_column :models, :rsi_zaxis_acceleration, :decimal, precision: 15, scale: 2
    add_column :models, :rsi_description, :text
    add_column :models, :rsi_size, :string
    add_column :models, :rsi_focus, :string
    add_column :models, :rsi_classification, :string
    add_column :models, :rsi_store_url, :string
    add_column :models, :rsi_mass, :decimal, precision: 15, scale: 2, default: '0.0', null: false
  end
end
