class ChangeShipFieldsToNumberPart1 < ActiveRecord::Migration[5.1]
  def up
    remove_column :ships, :length
    remove_column :ships, :beam
    remove_column :ships, :height
    remove_column :ships, :mass
    remove_column :ships, :cargo
    remove_column :ships, :crew

    remove_column :vehicle_additions, :length
    remove_column :vehicle_additions, :beam
    remove_column :vehicle_additions, :height
    remove_column :vehicle_additions, :mass
    remove_column :vehicle_additions, :cargo
    remove_column :vehicle_additions, :crew
  end

  def down
    add_column :ships, :length, :string
    add_column :ships, :beam, :string
    add_column :ships, :height, :string
    add_column :ships, :mass, :string
    add_column :ships, :cargo, :string
    add_column :ships, :crew, :string

    add_column :vehicle_additions, :length, :string
    add_column :vehicle_additions, :beam, :string
    add_column :vehicle_additions, :height, :string
    add_column :vehicle_additions, :mass, :string
    add_column :vehicle_additions, :cargo, :string
    add_column :vehicle_additions, :crew, :string
  end
end
