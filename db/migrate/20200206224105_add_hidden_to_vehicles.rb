class AddHiddenToVehicles < ActiveRecord::Migration[6.0]
  def change
    add_column :vehicles, :hidden, :boolean, default: false
  end
end
