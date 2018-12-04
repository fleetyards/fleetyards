class AddHiddenToShops < ActiveRecord::Migration[5.2]
  def change
    add_column :shops, :hidden, :boolean, default: true
    change_column :stations, :hidden, :boolean, default: true
  end
end
