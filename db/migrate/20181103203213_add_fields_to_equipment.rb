class AddFieldsToEquipment < ActiveRecord::Migration[5.2]
  def change
    add_column :equipment, :item_type, :integer
    add_column :equipment, :size, :string
    add_column :equipment, :grade, :string
    add_column :equipment, :damage_reduction, :integer
    add_column :equipment, :rate_of_fire, :integer
    add_column :equipment, :range, :integer
    add_column :equipment, :extras, :string
    add_column :equipment, :weapon_class, :integer
  end
end
