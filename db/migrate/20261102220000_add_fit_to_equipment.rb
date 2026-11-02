class AddFitToEquipment < ActiveRecord::Migration[8.1]
  def change
    add_column :equipment, :fit, :jsonb
    add_column :equipment_builds, :fit, :jsonb
  end
end
