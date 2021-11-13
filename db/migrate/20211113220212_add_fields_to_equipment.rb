class AddFieldsToEquipment < ActiveRecord::Migration[6.1]
  def change
    add_column :equipment, :temperature_rating, :string
    add_column :equipment, :backpack_compatibility, :integer
    add_column :equipment, :core_compatibility, :integer
  end
end
