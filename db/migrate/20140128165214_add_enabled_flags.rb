class AddEnabledFlags < ActiveRecord::Migration
  def change
    add_column :weapons, :enabled, :boolean, null: false, default: false
    add_column :equipment, :enabled, :boolean, null: false, default: false
    add_column :images, :enabled, :boolean, null: false, default: false
    add_column :manufacturers, :enabled, :boolean, null: false, default: false
  end
end
