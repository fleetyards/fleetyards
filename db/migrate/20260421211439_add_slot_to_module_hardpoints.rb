class AddSlotToModuleHardpoints < ActiveRecord::Migration[8.1]
  def change
    add_column :module_hardpoints, :slot, :string
    add_index :module_hardpoints, [:model_id, :slot]
  end
end
