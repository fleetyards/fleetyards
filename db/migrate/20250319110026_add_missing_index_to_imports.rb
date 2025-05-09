class AddMissingIndexToImports < ActiveRecord::Migration[7.1]
  def change
    add_index :imports, [:aasm_state, :type], if_not_exists: true
    add_index :imports, :type, if_not_exists: true
    add_index :imports, :aasm_state, if_not_exists: true
  end
end
