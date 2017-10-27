class AddFieldsToShips < ActiveRecord::Migration[5.1]
  def change
    add_column :ships, :size, :string
    add_column :ships, :scm_speed, :integer, default: 0, null: false
    add_column :ships, :afterburner_speed, :integer, default: 0, null: false
    add_column :ships, :cruise_speed, :integer, default: 0, null: false
    add_column :ships, :min_crew, :integer, default: 0, null: false
    add_column :ships, :max_crew, :integer, default: 0, null: false

    remove_column :ships, :crew, :integer
    remove_column :ships, :powerplant_size, :string
    remove_column :ships, :shield_size, :string

    reversible do
      change_column :ships, :mass, :decimal, precision: 15, scale: 2, default: 0.0, null: false
      change_column :ships, :height, :decimal, precision: 15, scale: 2, default: 0.0, null: false
      change_column :ships, :beam, :decimal, precision: 15, scale: 2, default: 0.0, null: false
      change_column :ships, :length, :decimal, precision: 15, scale: 2, default: 0.0, null: false
      change_column :vehicle_additions, :mass, :decimal, precision: 15, scale: 2, default: 0.0, null: false
      change_column :vehicle_additions, :height, :decimal, precision: 15, scale: 2, default: 0.0, null: false
      change_column :vehicle_additions, :beam, :decimal, precision: 15, scale: 2, default: 0.0, null: false
      change_column :vehicle_additions, :length, :decimal, precision: 15, scale: 2, default: 0.0, null: false
    end

    remove_column :vehicle_additions, :crew, :integer

    add_column :vehicle_additions, :scm_speed, :integer, default: 0, null: false
    add_column :vehicle_additions, :afterburner_speed, :integer, default: 0, null: false
    add_column :vehicle_additions, :cruise_speed, :integer, default: 0, null: false
    add_column :vehicle_additions, :min_crew, :integer, default: 0, null: false
    add_column :vehicle_additions, :max_crew, :integer, default: 0, null: false
  end
end
