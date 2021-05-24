class AddFieldsToModelHardpoints < ActiveRecord::Migration[6.1]
  def change
    add_column :model_hardpoints, :name, :string
    add_column :model_hardpoints, :loadout_identifier, :string
    add_column :model_hardpoints, :item_slot, :integer
    add_column :model_hardpoints, :sub_category, :integer
  end
end
