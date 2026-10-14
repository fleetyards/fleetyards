# frozen_string_literal: true

class AddSyncCcusToImports < ActiveRecord::Migration[8.1]
  def change
    add_column :imports, :sync_ccus, :boolean, default: false, null: false
  end
end
