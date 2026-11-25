# frozen_string_literal: true

class AddProgressToImports < ActiveRecord::Migration[8.1]
  def change
    add_column :imports, :progress, :jsonb
    add_column :imports, :progressed_at, :datetime
  end
end
