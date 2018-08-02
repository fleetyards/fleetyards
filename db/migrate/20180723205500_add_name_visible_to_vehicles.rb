class AddNameVisibleToVehicles < ActiveRecord::Migration[5.2]
  def change
    add_column :vehicles, :name_visible, :boolean, default: false
  end
end
