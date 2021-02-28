class FixTypoForRefinery < ActiveRecord::Migration[6.0]
  def change
    rename_column :shops, :refinary_terminal, :refinery_terminal
    rename_column :stations, :refinary, :refinery
  end
end
