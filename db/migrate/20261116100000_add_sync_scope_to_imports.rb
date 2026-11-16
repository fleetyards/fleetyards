# frozen_string_literal: true

class AddSyncScopeToImports < ActiveRecord::Migration[8.1]
  def change
    add_column :imports, :sync_scope, :string, default: "full", null: false
  end
end
