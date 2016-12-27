class RenameProductionStateToProductionStatusInShips < ActiveRecord::Migration
  def change
    rename_column :ships, :production_state, :production_status
  end
end
