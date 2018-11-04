class AddSlotToEquipment < ActiveRecord::Migration[5.2]
  def change
    add_column :equipment, :slot, :integer
  end
end
