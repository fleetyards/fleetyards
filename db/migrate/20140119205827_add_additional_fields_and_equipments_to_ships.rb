class AddAdditionalFieldsAndEquipmentsToShips < ActiveRecord::Migration
  def change
    add_column :ships, :base, :integer
    add_column :ships, :basename, :string
    add_column :ships, :store_url, :string
    add_column :ships, :max_upgrades, :integer
    add_column :ships, :max_equipment_raw, :text
    add_column :ships, :factory_equipment_raw, :text
    add_column :ships, :weapons_raw, :text
    add_column :ships, :max_class1, :integer
    add_column :ships, :max_class2, :integer
    add_column :ships, :max_class3, :integer
    add_column :ships, :max_class4, :integer
    add_column :ships, :max_class5, :integer
    add_column :ships, :max_class6, :integer
    add_column :ships, :max_class7, :integer
    add_column :ships, :max_class8, :integer
    add_column :ships, :max_powerplant, :integer
    add_column :ships, :max_powerplant_type, :string
    add_column :ships, :max_thrusters, :integer
    add_column :ships, :max_thrusters_type, :string
    add_column :ships, :max_primary_thrusters, :integer
    add_column :ships, :max_primary_thrusters_type, :string
    add_column :ships, :max_shield, :integer
    add_column :ships, :max_shield_type, :string


    create_table :equipment do |t|
      t.string :name
      t.string :equipment_type

      t.timestamps
    end

    create_table :equipment_ships, id: false do |t|
      t.integer :equipment_id
      t.integer :ship_id
    end

    create_table :weapons do |t|
      t.string :name
      t.string :hp_class

      t.timestamps
    end

    create_table :hardpoints do |t|
      t.integer :weapon_id
      t.integer :ship_id
      t.text :description
      t.string :hp_class

      t.timestamps
    end
  end
end
