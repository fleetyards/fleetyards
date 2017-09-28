class ChangeShipFieldsToNumberPart2 < ActiveRecord::Migration[5.1]
  def change
    add_column :ships, :length, :decimal, precision: 10, scale: 2, default: "0.0", null: false
    add_column :ships, :beam, :decimal, precision: 10, scale: 2, default: "0.0", null: false
    add_column :ships, :height, :decimal, precision: 10, scale: 2, default: "0.0", null: false
    add_column :ships, :mass, :decimal, precision: 10, scale: 2, default: "0.0", null: false
    add_column :ships, :cargo, :integer, default: 0, null: false
    add_column :ships, :crew, :integer, default: 0, null: false

    add_column :vehicle_additions, :beam, :decimal, precision: 10, scale: 2, default: "0.0", null: false
    add_column :vehicle_additions, :length, :decimal, precision: 10, scale: 2, default: "0.0", null: false
    add_column :vehicle_additions, :height, :decimal, precision: 10, scale: 2, default: "0.0", null: false
    add_column :vehicle_additions, :mass, :decimal, precision: 10, scale: 2, default: "0.0", null: false
    add_column :vehicle_additions, :cargo, :integer, default: 0, null: false
    add_column :vehicle_additions, :crew, :integer, default: 0, null: false
  end
end
