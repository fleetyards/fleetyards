class AddManufacturerToEquipment < ActiveRecord::Migration[5.2]
  def change
    add_column :equipment, :manufacturer_id, :uuid
    add_index :equipment, :manufacturer_id
  end
end
