class ChangeFieldsOnEquipment < ActiveRecord::Migration[5.2]
  def up
    change_column :equipment, :damage_reduction, :decimal, precision: 15, scale: 2
    change_column :equipment, :rate_of_fire, :decimal, precision: 15, scale: 2
    change_column :equipment, :range, :decimal, precision: 15, scale: 2
  end

  def down
    change_column :equipment, :damage_reduction, :integer
    change_column :equipment, :rate_of_fire, :integer
    change_column :equipment, :range, :integer
  end
end
