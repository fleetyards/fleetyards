class AddEnabledFlags < ActiveRecord::Migration
  def change
    add_column :weapons, :enabled, :boolean, null: false, default: true
    add_column :equipment, :enabled, :boolean, null: false, default: true
    add_column :images, :enabled, :boolean, null: false, default: true
    add_column :manufacturers, :enabled, :boolean, null: false, default: true
  end
end
