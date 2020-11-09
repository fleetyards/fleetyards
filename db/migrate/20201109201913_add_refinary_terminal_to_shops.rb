class AddRefinaryTerminalToShops < ActiveRecord::Migration[6.0]
  def change
    add_column :shops, :refinary_terminal, :boolean
  end
end
