# frozen_string_literal: true

class AddSyncEquipmentToImports < ActiveRecord::Migration[8.1]
  def change
    add_column :imports, :sync_equipment, :boolean, null: false, default: true
  end
end
