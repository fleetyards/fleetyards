class AddInputAndOutputToImports < ActiveRecord::Migration[7.0]
  def change
    add_column :imports, :input, :jsonb
    add_column :imports, :output, :jsonb
    add_column :imports, :user_id, :uuid
  end
end
