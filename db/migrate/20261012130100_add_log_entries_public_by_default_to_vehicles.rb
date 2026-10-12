# frozen_string_literal: true

class AddLogEntriesPublicByDefaultToVehicles < ActiveRecord::Migration[8.1]
  def change
    add_column :vehicles, :log_entries_public_by_default, :boolean, null: false, default: false
  end
end
