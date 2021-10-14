class AddVolumeToEquipment < ActiveRecord::Migration[6.1]
  def change
    add_column :equipment, :volume, :decimal, precision: 15, scale: 2
  end
end
