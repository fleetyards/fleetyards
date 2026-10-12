# frozen_string_literal: true

class AddPublicLogEntriesCountToVehicles < ActiveRecord::Migration[8.1]
  def change
    add_column :vehicles, :public_log_entries_count, :integer, null: false, default: 0
  end
end
