class ReshapeEquipmentForGameFiles < ActiveRecord::Migration[8.1]
  # The table has never been populated -- it was sketched against RSI store data
  # and left empty, which is why the columns are replaced outright rather than
  # migrated. Confirm `Equipment.count.zero?` before this runs anywhere real.
  def up
    add_column :equipment, :sc_key, :string
    add_column :equipment, :sc_ref, :string
    add_column :equipment, :version, :string
    add_column :equipment, :sub_type, :string

    add_index :equipment, :sc_key, unique: true

    # Stored as strings rather than enums so a class CIG adds in a later build
    # loads instead of raising, the way Commodity#commodity_type does.
    %i[equipment_type item_type weapon_class].each do |column|
      remove_column :equipment, column
      add_column :equipment, column, :string
    end

    # After the replacement, not before: dropping a column takes its index with
    # it, so indexing first leaves the table with neither.
    add_index :equipment, :equipment_type
    add_index :equipment, :item_type

    # Leftovers from the store-scraped sketch. Images belong to ActiveStorage
    # now, the way Component#store_image is attached.
    remove_column :equipment, :store_image
    remove_column :equipment, :store_image_height
    remove_column :equipment, :store_image_width
    remove_column :equipment, :extras

    change_column_default :equipment, :hidden, from: true, to: false
  end

  def down
    remove_index :equipment, :sc_key
    remove_index :equipment, :equipment_type
    remove_index :equipment, :item_type

    remove_column :equipment, :sc_key
    remove_column :equipment, :sc_ref
    remove_column :equipment, :version
    remove_column :equipment, :sub_type

    %i[equipment_type item_type weapon_class].each do |column|
      remove_column :equipment, column
      add_column :equipment, column, :integer
    end

    add_column :equipment, :store_image, :string
    add_column :equipment, :store_image_height, :integer
    add_column :equipment, :store_image_width, :integer
    add_column :equipment, :extras, :string

    change_column_default :equipment, :hidden, from: false, to: true
  end
end
