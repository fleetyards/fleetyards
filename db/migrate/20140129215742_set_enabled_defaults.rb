class SetEnabledDefaults < ActiveRecord::Migration
  def up
    change_column :weapons, :enabled, :boolean, null: false, default: false
    change_column :equipment, :enabled, :boolean, null: false, default: false
    change_column :images, :enabled, :boolean, null: false, default: false
    change_column :manufacturers, :enabled, :boolean, null: false, default: false
  end

  def down
    change_column :weapons, :enabled, :boolean, null: false, default: true
    change_column :equipment, :enabled, :boolean, null: false, default: true
    change_column :images, :enabled, :boolean, null: false, default: true
    change_column :manufacturers, :enabled, :boolean, null: false, default: true
  end
end
