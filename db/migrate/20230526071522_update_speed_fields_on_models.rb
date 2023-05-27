class UpdateSpeedFieldsOnModels < ActiveRecord::Migration[7.0]
  def change
    remove_column :models, :afterburner_speed, :decimal, precision: 15, scale: 2
    remove_column :models, :cruise_speed, :decimal, precision: 15, scale: 2
    remove_column :models, :xaxis_acceleration, :decimal, precision: 15, scale: 2
    remove_column :models, :yaxis_acceleration, :decimal, precision: 15, scale: 2
    remove_column :models, :zaxis_acceleration, :decimal, precision: 15, scale: 2
    remove_column :models, :rsi_xaxis_acceleration, :decimal, precision: 15, scale: 2
    remove_column :models, :rsi_yaxis_acceleration, :decimal, precision: 15, scale: 2
    remove_column :models, :rsi_zaxis_acceleration, :decimal, precision: 15, scale: 2
    remove_column :models, :speed, :decimal, precision: 15, scale: 2
    remove_column :models, :ground_speed, :decimal, precision: 15, scale: 2
    remove_column :models, :afterburner_ground_speed, :decimal, precision: 15, scale: 2

    add_column :models, :ground_max_speed, :decimal, precision: 15, scale: 2
    add_column :models, :ground_reverse_speed, :decimal, precision: 15, scale: 2
    add_column :models, :ground_acceleration, :decimal, precision: 15, scale: 2
    add_column :models, :ground_decceleration, :decimal, precision: 15, scale: 2
    add_column :models, :scm_speed_acceleration, :decimal, precision: 15, scale: 2
    add_column :models, :scm_speed_decceleration, :decimal, precision: 15, scale: 2
    add_column :models, :max_speed_acceleration, :decimal, precision: 15, scale: 2
    add_column :models, :max_speed_decceleration, :decimal, precision: 15, scale: 2
    add_column :models, :loaners_count, :integer, default: 0, null: false

    rename_column :models, :rsi_afterburner_speed, :rsi_max_speed
    rename_column :models, :pitch_max, :pitch
    rename_column :models, :yaw_max, :yaw
    rename_column :models, :roll_max, :roll
    rename_column :models, :rsi_pitch_max, :rsi_pitch
    rename_column :models, :rsi_yaw_max, :rsi_yaw
    rename_column :models, :rsi_roll_max, :rsi_roll
  end
end
