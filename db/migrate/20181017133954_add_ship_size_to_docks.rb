class AddShipSizeToDocks < ActiveRecord::Migration[5.2]
  def change
    add_column :docks, :ship_size, :integer
  end
end
